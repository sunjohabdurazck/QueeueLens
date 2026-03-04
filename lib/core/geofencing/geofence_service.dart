// lib/core/geofencing/geofence_service.dart
//
// True geofencing engine for QueueLens.
//
// ANDROID: runs as a real background foreground-service (requires flutter_background_service).
//          Works even when screen is off or app is minimised.
// WEB:     runs while app tab is open only (browser limitation).
//          Uses geolocator stream — no background process.
//
// DESIGN RULE: Geofence exit alone does NOT immediately expire.
//   Step 1 → warn user (notification with confirm button)
//   Step 2 → wait grace period (2 min)
//   Step 3 → if still outside AND unconfirmed → expire entry

import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../notifications/notification_manager.dart';

/// Lightweight data blob stored locally so the background isolate
/// (Android) can read it without needing Riverpod or BuildContext.
class GeofenceBlob {
  final String serviceId;
  final String entryId;
  final String serviceName;
  final double serviceLat;
  final double serviceLng;
  final double radiusMeters;

  const GeofenceBlob({
    required this.serviceId,
    required this.entryId,
    required this.serviceName,
    required this.serviceLat,
    required this.serviceLng,
    this.radiusMeters = 100,
  });
}

/// Singleton geofence controller.
class GeofenceService {
  GeofenceService._();
  static final GeofenceService instance = GeofenceService._();

  StreamSubscription<Position>? _positionSub;
  Timer? _graceTimer;
  bool _warningSent = false;
  GeofenceBlob? _activeBlob;

  /// Duration user must remain outside before entry is expired.
  static const Duration _gracePeriod = Duration(minutes: 2);

  /// How far outside the radius triggers a warning.
  static const double _radiusBuffer = 0; // exact radius, no buffer

  // ─── Public API ─────────────────────────────────────────────────────────────

  /// Start geofence monitoring.
  /// Call after user successfully joins queue (joinQueuePending) or checks in.
  Future<void> start(GeofenceBlob blob) async {
    await stop(); // always clean up first

    _activeBlob = blob;
    _warningSent = false;

    await _saveBlob(blob);

    if (kIsWeb) {
      _startWebGeofence(blob);
    } else {
      _startAndroidGeofence(blob);
    }

    debugPrint('[GeofenceService] Started monitoring for ${blob.serviceName}');
  }

  /// Stop all geofence monitoring.
  /// Call when: user leaves queue manually / entry served / expired / user logs out.
  Future<void> stop() async {
    await _positionSub?.cancel();
    _positionSub = null;
    _graceTimer?.cancel();
    _graceTimer = null;
    _warningSent = false;
    _activeBlob = null;
    await _clearBlob();
    debugPrint('[GeofenceService] Stopped.');
  }

  bool get isMonitoring => _activeBlob != null;

  // ─── Web (foreground only) ──────────────────────────────────────────────────

  void _startWebGeofence(GeofenceBlob blob) {
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.low,
      distanceFilter: 20, // only emit if moved 20m — saves CPU
    );

    _positionSub =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (position) => _evaluate(position.latitude, position.longitude, blob),
          onError: (e) => debugPrint('[GeofenceService] Web stream error: $e'),
        );
  }

  // ─── Android (background capable) ──────────────────────────────────────────
  // flutter_background_service runs a foreground service.
  // The service reads the blob from SharedPreferences and calls _evaluate.
  // For simplicity here we wire the same stream — the background service
  // integration is in geofence_background_service.dart.

  void _startAndroidGeofence(GeofenceBlob blob) {
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.low,
      distanceFilter: 20,
    );

    _positionSub =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (position) => _evaluate(position.latitude, position.longitude, blob),
          onError: (e) =>
              debugPrint('[GeofenceService] Android stream error: $e'),
        );
  }

  // ─── Core evaluation logic ──────────────────────────────────────────────────

  Future<void> _evaluate(
    double userLat,
    double userLng,
    GeofenceBlob blob,
  ) async {
    final distance = haversine(
      userLat,
      userLng,
      blob.serviceLat,
      blob.serviceLng,
    );
    final outside = distance > (blob.radiusMeters + _radiusBuffer);

    debugPrint(
      '[GeofenceService] distance=${distance.toStringAsFixed(0)}m '
      'radius=${blob.radiusMeters}m outside=$outside',
    );

    if (outside && !_warningSent) {
      _onExitDetected(blob);
    } else if (!outside) {
      // User came back — cancel grace timer and reset
      final wasWarned = _warningSent;
      _graceTimer?.cancel();
      _graceTimer = null;
      _warningSent = false;

      if (wasWarned) {
        await NotificationManager.instance.showGeofenceReturn(
          serviceName: blob.serviceName,
        );
      }

      debugPrint('[GeofenceService] User returned to service area.');
    }
  }

  void _onExitDetected(GeofenceBlob blob) {
    _warningSent = true;
    _requestConfirmAndStartGrace(blob, reason: 'left_service_area');
  }

  Future<void> _requestConfirmAndStartGrace(
    GeofenceBlob blob, {
    required String reason,
  }) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final entryRef = firestore
          .collection('services')
          .doc(blob.serviceId)
          .collection('entries')
          .doc(blob.entryId);

      final confirmBy = Timestamp.fromDate(DateTime.now().add(_gracePeriod));

      await entryRef.update({
        'needsActiveConfirm': true,
        'confirmBy': confirmBy,
        'confirmReason': reason,
      });

      await NotificationManager.instance.showActiveConfirmRequired(
        serviceId: blob.serviceId,
        entryId: blob.entryId,
        serviceName: blob.serviceName,
        reason: reason,
        minutesToRespond: _gracePeriod.inMinutes,
      );

      // Start grace timer — after period, expire only if still unconfirmed
      _graceTimer?.cancel();
      _graceTimer = Timer(_gracePeriod, () => _expireIfNotConfirmed(blob));
    } catch (e) {
      debugPrint('[GeofenceService] confirm request error: $e');
    }
  }

  Future<void> _expireIfNotConfirmed(GeofenceBlob blob) async {
    debugPrint('[GeofenceService] Grace elapsed — checking confirm state.');

    try {
      final firestore = FirebaseFirestore.instance;
      final entryRef = firestore
          .collection('services')
          .doc(blob.serviceId)
          .collection('entries')
          .doc(blob.entryId);

      final snap = await entryRef.get();
      if (!snap.exists) return;

      final data = snap.data() as Map<String, dynamic>;
      final status = data['status'] as String? ?? '';
      final needsConfirm = (data['needsActiveConfirm'] as bool?) ?? false;
      final confirmByTs = data['confirmBy'] as Timestamp?;

      // If they confirmed, do nothing.
      if (!needsConfirm) {
        debugPrint('[GeofenceService] User confirmed — not expiring.');
        _warningSent = false;
        return;
      }

      // If deadline not passed yet, do nothing.
      if (confirmByTs != null &&
          DateTime.now().isBefore(confirmByTs.toDate())) {
        return;
      }

      // Only expire if still pending/active (staff may have served them)
      if (status == 'pending' || status == 'active') {
        await firestore.runTransaction((tx) async {
          tx.update(entryRef, {
            'status': 'expired',
            'expiredReason': 'no_confirm_active',
            'expiredAt': FieldValue.serverTimestamp(),
          });

          final serviceRef = firestore
              .collection('services')
              .doc(blob.serviceId);

          if (status == 'pending') {
            tx.update(serviceRef, {
              'pendingCount': FieldValue.increment(-1),
              'lastUpdatedAt': FieldValue.serverTimestamp(),
            });
          } else {
            tx.update(serviceRef, {
              'activeCount': FieldValue.increment(-1),
              'lastUpdatedAt': FieldValue.serverTimestamp(),
            });
          }
        });

        // Notify user
        await NotificationManager.instance.showQueueExpired(
          serviceName: blob.serviceName,
        );

        debugPrint('[GeofenceService] Entry expired due to geofence exit.');
      }
    } catch (e) {
      debugPrint('[GeofenceService] Error expiring entry: $e');
    } finally {
      await stop();
    }
  }

  // ─── Persistence (for background service to read) ───────────────────────────

  static const String _prefKey = 'geofence_blob';

  Future<void> _saveBlob(GeofenceBlob blob) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefKey,
      '${blob.serviceId}|${blob.entryId}|${blob.serviceName}'
      '|${blob.serviceLat}|${blob.serviceLng}|${blob.radiusMeters}',
    );
  }

  Future<void> _clearBlob() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKey);
  }

  static Future<GeofenceBlob?> loadBlob() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefKey);
    if (raw == null) return null;
    final parts = raw.split('|');
    if (parts.length < 6) return null;
    return GeofenceBlob(
      serviceId: parts[0],
      entryId: parts[1],
      serviceName: parts[2],
      serviceLat: double.tryParse(parts[3]) ?? 0,
      serviceLng: double.tryParse(parts[4]) ?? 0,
      radiusMeters: double.tryParse(parts[5]) ?? 100,
    );
  }

  // ─── Haversine distance ─────────────────────────────────────────────────────

  static double haversine(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371000.0; // Earth radius in meters
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);
    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(lat1)) * cos(_toRad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return r * c;
  }

  static double _toRad(double deg) => deg * pi / 180;
}
