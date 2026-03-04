// lib/features/queue/application/queue_intelligence_listener.dart
//
// THE BRAIN of QueueLens.
// Single place that coordinates ALL queue intelligence:
//   - Subscribes to the user's active entry stream
//   - Runs heartbeat timer
//   - Evaluates position thresholds (turn-soon)
//   - Detects wait-time increases
//   - Starts/stops geofence
//   - Triggers better-service recommendation checks
//
// USAGE: Create one instance per authenticated session and call start().
// Dispose by calling stop() when user logs out.

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/notifications/notification_manager.dart';
import '../../../core/geofencing/geofence_service.dart';
import '../../services/domain/entities/queue_entry.dart';
import '../../services/domain/repositories/queue_repository.dart';
import '../../ai/domain/usecases/predict_wait_time.dart';
import '../../ai/domain/usecases/recommend_best_service.dart';
import '../../ai/domain/repositories/ai_repository.dart';
import '../../ai/domain/entities/wait_prediction.dart';
import '../../ai/domain/entities/recommendation.dart';
import '../../ai/core/geo.dart';

// Service coordinates (IUT) - aligned with MapDataService.getDefaultPlaces()
// Mapping assumption:
// - registrar -> "Admin Building" (Registrar & student services)
// - accounts  -> "Administrative Building" (main admin office)
// - library_print -> Library (print services typically near/inside library)
const _serviceCoords = <String, Map<String, double>>{
  'svc_registrar': {
    'lat': 23.94806072165071,
    'lng': 90.37928129865955,
  }, // Admin Building
  'svc_accounts': {
    'lat': 23.94864834931579,
    'lng': 90.37898213461050,
  }, // Administrative Building
  'svc_medical': {
    'lat': 23.948847342350103,
    'lng': 90.37738137384427,
  }, // Medical Center
  'svc_cafeteria': {
    'lat': 23.948039068381526,
    'lng': 90.37968418660170,
  }, // Cafeteria
  'svc_library': {
    'lat': 23.94814651513253,
    'lng': 90.37968899664604,
  }, // Library
  'svc_library_print': {
    'lat': 23.94814651513253,
    'lng': 90.37968899664604,
  }, // Library
};

class QueueIntelligenceListener {
  final QueueRepository queueRepo;
  final AiRepository aiRepo;

  QueueIntelligenceListener({required this.queueRepo, required this.aiRepo});

  // ─── State ───────────────────────────────────────────────────────────────────

  StreamSubscription<QueueEntry?>? _entrySub;
  Timer? _heartbeatTimer;
  Timer? _inactivityTimer;

  QueueEntry? _lastEntry;
  WaitPrediction? _lastPrediction;
  bool _turnSoonNotified = false;
  bool _inactivityWarned = false;
  bool _betterServiceNotified = false;
  DateTime? _lastBetterServiceCheck;

  static const Duration _heartbeatInterval = Duration(minutes: 2);
  static const Duration _inactivityThreshold = Duration(minutes: 5);
  static const Duration _inactivityGrace = Duration(minutes: 1);
  static const int _turnSoonThreshold = 2; // notify when position <= this

  // ─── Public API ──────────────────────────────────────────────────────────────

  /// Start listening. Call after user authentication is confirmed.
  void start(String tempUserKey) {
    debugPrint('[QueueIntelligence] Starting for $tempUserKey');

    _entrySub = queueRepo
        .watchMyActiveEntry(tempUserKey)
        .listen(
          (entry) => _onEntryChanged(entry),
          onError: (e) => debugPrint('[QueueIntelligence] Stream error: $e'),
        );
  }

  /// Stop all listeners, timers, and geofence. Call on logout.
  Future<void> stop() async {
    await _entrySub?.cancel();
    _entrySub = null;
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _inactivityTimer?.cancel();
    _inactivityTimer = null;
    await GeofenceService.instance.stop();
    _lastEntry = null;
    _lastPrediction = null;
    _turnSoonNotified = false;
    _inactivityWarned = false;
    _betterServiceNotified = false;
    _lastBetterServiceCheck = null;
    debugPrint('[QueueIntelligence] Stopped.');
  }

  // ─── Entry change handler ────────────────────────────────────────────────────

  Future<void> _onEntryChanged(QueueEntry? entry) async {
    final prev = _lastEntry;
    _lastEntry = entry;

    // ── Entry disappeared (served / expired by someone else) ──
    if (entry == null) {
      _stopHeartbeat();
      await GeofenceService.instance.stop();
      return;
    }

    // ── Brand new entry (just joined) — works across multiple sessions ──
    final isNewSession = prev == null || prev.id != entry.id;
    if (isNewSession && entry.isPending) {
      await _onJoined(entry);
    }

    // ── Transition: pending → active (checked in) ──
    if (prev != null &&
        prev.status == QueueEntryStatus.pending &&
        entry.status == QueueEntryStatus.active) {
      await _onCheckedIn(entry);
    }

    // ── Entry marked served ──
    if (entry.status == QueueEntryStatus.served) {
      await _onServed(entry);
      return;
    }

    // ── Entry expired ──
    if (entry.status == QueueEntryStatus.expired) {
      await GeofenceService.instance.stop();
      _stopHeartbeat();
      return;
    }

    // ── Ongoing: check position + wait time + better service each update ──
    if (entry.isPending || entry.isActive) {
      await _checkTurnSoon(entry);
      await _checkWaitTimeIncrease(entry);
      await _checkBetterServiceNearby(entry);
    }
  }

  // ─── Event handlers ──────────────────────────────────────────────────────────

  Future<void> _onJoined(QueueEntry entry) async {
    debugPrint('[QueueIntelligence] User joined queue.');

    // Reset flags for new session
    _turnSoonNotified = false;
    _inactivityWarned = false;
    _betterServiceNotified = false;
    _lastBetterServiceCheck = null;

    // Predict wait time
    final position = await queueRepo.calculatePosition(
      entry.serviceId,
      entry.id,
    );
    final prediction = await _predict(entry.serviceId, position);

    // Notify
    await NotificationManager.instance.showJoinedQueue(
      serviceName: entry.serviceId, // replace with service name if available
      lowMin: prediction.lowMinutes,
      highMin: prediction.highMinutes,
    );

    _lastPrediction = prediction;

    // Start heartbeat
    _startHeartbeat(entry);

    // Start inactivity watchdog
    _startInactivityWatchdog();

    // Start geofence (if coords available)
    await _maybeStartGeofence(entry);
  }

  Future<void> _onCheckedIn(QueueEntry entry) async {
    debugPrint('[QueueIntelligence] User checked in.');
    await NotificationManager.instance.showCheckedIn(
      serviceName: entry.serviceId,
    );
    // Continue heartbeat and geofence (both still relevant while active)
  }

  Future<void> _onServed(QueueEntry entry) async {
    debugPrint('[QueueIntelligence] User served.');
    await NotificationManager.instance.showServed(serviceName: entry.serviceId);
    _stopHeartbeat();
    await GeofenceService.instance.stop();
  }

  // ─── Position check (turn-soon) ──────────────────────────────────────────────

  Future<void> _checkTurnSoon(QueueEntry entry) async {
    if (_turnSoonNotified) return;

    try {
      final position = await queueRepo.calculatePosition(
        entry.serviceId,
        entry.id,
      );
      if (position > 0 && position <= _turnSoonThreshold) {
        _turnSoonNotified = true;
        await NotificationManager.instance.showTurnComingSoon(
          position: position,
        );
      }
    } catch (e) {
      debugPrint('[QueueIntelligence] Position check error: $e');
    }
  }

  // ─── Wait time increase check ────────────────────────────────────────────────

  Future<void> _checkWaitTimeIncrease(QueueEntry entry) async {
    if (_lastPrediction == null) return;

    try {
      final position = await queueRepo.calculatePosition(
        entry.serviceId,
        entry.id,
      );
      final newPrediction = await _predict(entry.serviceId, position);

      final prev = _lastPrediction!;
      final prevHigh = prev.highMinutes;
      final newHigh = newPrediction.highMinutes;

      // Guard divide-by-zero / baseline resets (e.g., prev wait becomes 0)
      if (prevHigh <= 0) {
        _lastPrediction = newPrediction;
        return;
      }

      final increaseRatio = newHigh / prevHigh;

      if (increaseRatio >= 1.3) {
        // >30% increase
        await NotificationManager.instance.showWaitIncreased(
          serviceName: entry.serviceId,
          newWaitMin: newPrediction.highMinutes,
        );
        _lastPrediction = newPrediction; // update baseline
      } else if (newPrediction.highMinutes != prev.highMinutes) {
        _lastPrediction = newPrediction; // still update baseline silently
      }
    } catch (e) {
      debugPrint('[QueueIntelligence] Wait check error: $e');
    }
  }

  // ─── Heartbeat ───────────────────────────────────────────────────────────────

  void _startHeartbeat(QueueEntry entry) {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(
      _heartbeatInterval,
      (_) => _sendHeartbeat(entry),
    );
  }

  Future<void> _sendHeartbeat(QueueEntry entry) async {
    try {
      await queueRepo.updateHeartbeat(entry.serviceId, entry.id);
      debugPrint('[QueueIntelligence] Heartbeat sent.');
    } catch (e) {
      debugPrint('[QueueIntelligence] Heartbeat error: $e');
    }
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  // ─── Inactivity watchdog ─────────────────────────────────────────────────────

  void _startInactivityWatchdog() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _checkInactivity(),
    );
  }

  Future<void> _checkInactivity() async {
    final entry = _lastEntry;
    if (entry == null) return;
    if (!entry.isPending && !entry.isActive) return;
    if (entry.lastSeenAt == null) return;

    final lastSeen = entry.lastSeenAt!.toDate();
    final sinceLastSeen = DateTime.now().difference(lastSeen);

    if (sinceLastSeen >= _inactivityThreshold && !_inactivityWarned) {
      _inactivityWarned = true;

      await NotificationManager.instance.showInactivityWarning(
        serviceName: entry.serviceId,
      );

      // After grace period, expire if still inactive
      Timer(_inactivityGrace, () async {
        final latest = _lastEntry;
        if (latest == null) return;
        await _maybeExpireInactive(latest);
      });
    }
  }

  Future<void> _maybeExpireInactive(QueueEntry entry) async {
    // Re-read from Firestore to check current lastSeenAt
    try {
      final firestore = FirebaseFirestore.instance;
      final doc = await firestore
          .collection('services')
          .doc(entry.serviceId)
          .collection('entries')
          .doc(entry.id)
          .get();

      if (!doc.exists) return;

      final data = doc.data() as Map<String, dynamic>;
      final status = data['status'] as String? ?? '';
      final lastSeenTs = data['lastSeenAt'] as Timestamp?;

      if (status != 'pending' && status != 'active') return;

      final lastSeen = lastSeenTs?.toDate() ?? DateTime.now();
      final sinceLastSeen = DateTime.now().difference(lastSeen);

      if (sinceLastSeen >= _inactivityThreshold + _inactivityGrace) {
        await firestore.runTransaction((tx) async {
          tx.update(doc.reference, {
            'status': 'expired',
            'expiredReason': 'inactivity',
          });

          final serviceRef = firestore
              .collection('services')
              .doc(entry.serviceId);
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
          serviceName: entry.serviceId,
        );

        debugPrint('[QueueIntelligence] Entry expired due to inactivity.');
        await stop();
      }
    } catch (e) {
      debugPrint('[QueueIntelligence] Inactivity expire error: $e');
    }
  }

  // ─── Better service recommendation ──────────────────────────────────────────

  Future<void> _checkBetterServiceNearby(QueueEntry entry) async {
    if (_betterServiceNotified) return;

    // Throttle checks (every 3 minutes max)
    final now = DateTime.now();
    if (_lastBetterServiceCheck != null &&
        now.difference(_lastBetterServiceCheck!) < const Duration(minutes: 3)) {
      return;
    }
    _lastBetterServiceCheck = now;

    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
      );

      final firestore = FirebaseFirestore.instance;
      final servicesSnap = await firestore.collection('services').get();
      if (servicesSnap.docs.isEmpty) return;

      int _safeInt(dynamic v) => (v is int) ? v : int.tryParse('$v') ?? 0;

      final services = <ServiceData>[];

      for (final doc in servicesSnap.docs) {
        final id = doc.id;
        if (id == entry.serviceId) continue;

        final data = doc.data();
        final name = (data['name'] as String?) ?? id;
        final statusStr = (data['status'] as String?) ?? 'OPEN';
        final isOpen = statusStr.toUpperCase() == 'OPEN';

        final coords = _serviceCoords[id];
        if (coords == null) continue;

        final dist = GeoUtils.haversineDistance(
          pos.latitude,
          pos.longitude,
          coords['lat']!,
          coords['lng']!,
        );

        final active = _safeInt(data['activeCount']);
        final pending = _safeInt(data['pendingCount']);
        final avgMins = _safeInt(data['avgMinsPerPerson']);
        final waitMin = (active + pending) * (avgMins <= 0 ? 1 : avgMins);

        services.add(
          ServiceData(
            serviceId: id,
            serviceName: name,
            waitMin: waitMin,
            distanceMeters: dist,
            isOpen: isOpen,
          ),
        );
      }

      if (services.isEmpty) return;

      final currentDoc = await firestore
          .collection('services')
          .doc(entry.serviceId)
          .get();
      final currentData =
          currentDoc.data() as Map<String, dynamic>? ?? <String, dynamic>{};
      final currentActive = _safeInt(currentData['activeCount']);
      final currentPending = _safeInt(currentData['pendingCount']);
      final currentAvg = _safeInt(currentData['avgMinsPerPerson']);
      final currentWaitMin =
          (currentActive + currentPending) * (currentAvg <= 0 ? 1 : currentAvg);

      final recommender = RecommendBestService();
      final rec = recommender(
        services: services,
        userLat: pos.latitude,
        userLon: pos.longitude,
      );

      if (rec == null) return;

      // Only notify if significantly better than current service
      if (currentWaitMin > 0 && rec.waitMin >= (currentWaitMin * 0.7).round()) {
        return;
      }

      _betterServiceNotified = true;
      await NotificationManager.instance.showBetterServiceNearby(
        serviceName: rec.serviceName,
        waitMin: rec.waitMin,
        distanceMeters: rec.distanceMeters.round(),
      );
    } catch (e) {
      debugPrint('[QueueIntelligence] Better service check error: $e');
    }
  }

  // ─── Geofence ────────────────────────────────────────────────────────────────

  Future<void> _maybeStartGeofence(QueueEntry entry) async {
    final coords = _serviceCoords[entry.serviceId];
    if (coords == null) {
      debugPrint(
        '[QueueIntelligence] No coordinates for ${entry.serviceId} — geofence skipped.',
      );
      return;
    }

    await GeofenceService.instance.start(
      GeofenceBlob(
        serviceId: entry.serviceId,
        entryId: entry.id,
        serviceName: entry.serviceId, // replace with service name
        serviceLat: coords['lat']!,
        serviceLng: coords['lng']!,
        radiusMeters: 100,
      ),
    );
  }

  // ─── AI helper ───────────────────────────────────────────────────────────────

  Future<WaitPrediction> _predict(String serviceId, int position) async {
    final usecase = PredictWaitTime(aiRepo);
    return usecase(
      serviceId: serviceId,
      positionInQueue: position,
      now: DateTime.now(),
    );
  }
}
