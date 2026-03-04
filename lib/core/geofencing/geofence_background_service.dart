// lib/core/geofencing/geofence_background_service.dart
//
// Android-only background foreground service for geofencing.
// Uses flutter_background_service to keep geofence alive when app is
// minimised or screen is off.
//
// HOW IT WORKS:
//   1. GeofenceService.start() saves the blob to SharedPreferences.
//   2. GeofenceBackgroundService.startService() launches the foreground service.
//   3. The service reads the blob, streams location, and calls Firestore directly
//      — no BuildContext or Riverpod needed.
//   4. GeofenceService.stop() calls stopService() to kill the service.
//
// NOTE: The foreground service shows a persistent Android notification while
//       active — this is an Android OS requirement, not optional.

import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import 'geofence_service.dart';
import '../notifications/notification_manager.dart';

class GeofenceBackgroundService {
  static const String _stopAction = 'geofence_stop';

  /// Initialize and configure the background service.
  /// Call once from main() BEFORE runApp(), alongside Firebase.initializeApp().
  static Future<void> configure() async {
    if (kIsWeb) return;

    final service = FlutterBackgroundService();

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: _onStart,
        autoStart: false, // we start manually when user joins queue
        isForegroundMode: true,
        notificationChannelId: 'geofence_fg_channel',
        initialNotificationTitle: 'QueueLens',
        initialNotificationContent: 'Monitoring your queue position…',
        foregroundServiceNotificationId: 999,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: _onStart,
      ),
    );
  }

  /// Start the foreground service.
  static Future<void> startService() async {
    if (kIsWeb) return;
    final service = FlutterBackgroundService();
    await service.startService();
  }

  /// Stop the foreground service.
  static Future<void> stopService() async {
    if (kIsWeb) return;
    final service = FlutterBackgroundService();
    service.invoke(_stopAction);
  }

  /// Entry point for the background isolate.
  /// Must be a top-level function (not a class method) for isolate compatibility.
  @pragma('vm:entry-point')
  static void _onStart(ServiceInstance service) async {
    // Initialize Firebase in the background isolate
    await Firebase.initializeApp();
    await NotificationManager.instance.init();

    // Load geofence parameters saved by the main isolate
    final blob = await GeofenceService.loadBlob();
    if (blob == null) {
      debugPrint('[BgGeofence] No blob found — stopping service.');
      service.stopSelf();
      return;
    }

    debugPrint('[BgGeofence] Started for ${blob.serviceName}');

    bool warningSent = false;

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.low,
      distanceFilter: 20,
    );

    final positionSub =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (position) async {
            final distance = GeofenceService.haversine(
              position.latitude,
              position.longitude,
              blob.serviceLat,
              blob.serviceLng,
            );

            final outside = distance > blob.radiusMeters;

            if (outside && !warningSent) {
              warningSent = true;

              // Require confirmation to stay active
              final firestore = FirebaseFirestore.instance;
              final entryRef = firestore
                  .collection('services')
                  .doc(blob.serviceId)
                  .collection('entries')
                  .doc(blob.entryId);

              final confirmBy = Timestamp.fromDate(
                DateTime.now().add(const Duration(minutes: 2)),
              );

              await entryRef.update({
                'needsActiveConfirm': true,
                'confirmBy': confirmBy,
                'confirmReason': 'left_service_area_background',
              });

              await NotificationManager.instance.showActiveConfirmRequired(
                serviceId: blob.serviceId,
                entryId: blob.entryId,
                serviceName: blob.serviceName,
                reason: 'left_service_area_background',
                minutesToRespond: 2,
              );

              // Grace period — wait 2 minutes then expire
              await Future.delayed(const Duration(minutes: 2));

              // Re-check position after grace
              try {
                final latest = await Geolocator.getCurrentPosition(
                  locationSettings: const LocationSettings(
                    accuracy: LocationAccuracy.low,
                  ),
                );
                final newDist = GeofenceService.haversine(
                  latest.latitude,
                  latest.longitude,
                  blob.serviceLat,
                  blob.serviceLng,
                );

                if (newDist > blob.radiusMeters) {
                  // Expire only if still unconfirmed
                  final snap = await entryRef.get();
                  if (!snap.exists) return;
                  final data = snap.data() as Map<String, dynamic>;
                  final needsConfirm =
                      (data['needsActiveConfirm'] as bool?) ?? false;
                  final confirmByTs = data['confirmBy'] as Timestamp?;

                  if (!needsConfirm) {
                    warningSent = false;
                    return;
                  }

                  if (confirmByTs != null &&
                      DateTime.now().isBefore(confirmByTs.toDate())) {
                    return;
                  }

                  await _expireEntryFromBackground(blob);
                } else {
                  warningSent = false; // returned, reset
                }
              } catch (e) {
                debugPrint('[BgGeofence] Grace re-check error: $e');
              }
            } else if (!outside) {
              warningSent = false; // user came back
            }
          },
        );

    // Listen for stop signal from main isolate
    service.on(_stopAction).listen((_) async {
      await positionSub.cancel();
      service.stopSelf();
      debugPrint('[BgGeofence] Stopped by main isolate.');
    });
  }

  static Future<void> _expireEntryFromBackground(GeofenceBlob blob) async {
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

      if (status == 'pending' || status == 'active') {
        await firestore.runTransaction((tx) async {
          tx.update(entryRef, {
            'status': 'expired',
            'expiredReason': 'geofence_exit_background',
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

        await NotificationManager.instance.showQueueExpired(
          serviceName: blob.serviceName,
        );
      }
    } catch (e) {
      debugPrint('[BgGeofence] Error expiring from background: $e');
    }
  }
}

// ─── Expose haversine publicly for background isolate ───────────────────────
// (Added as an extension on GeofenceService to avoid code duplication)
extension GeofenceServicePublic on GeofenceService {
  static double haversine(double lat1, double lon1, double lat2, double lon2) {
    return GeofenceService.haversine(lat1, lon1, lat2, lon2);
  }
}
