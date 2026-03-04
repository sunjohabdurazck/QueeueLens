// lib/core/notifications/notification_manager.dart
//
// Central notification engine for QueueLens.
// ALL notifications go through here — UI never calls the plugin directly.
// Replaces all hardcoded SnackBar/showLocalNotification calls scattered across pages.

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'inbox/notification_inbox_repo.dart';
import 'web_notifier.dart';

/// Notification channel IDs
class _Channels {
  static const String queue = 'queue_channel';
  static const String geofence = 'geofence_channel';
  static const String ai = 'ai_channel';
  static const String staff = 'staff_channel';
}

/// Stable IDs so we can cancel/replace specific notifications
class NotifId {
  static const int joinedQueue = 1;
  static const int turnComingSoon = 2;
  static const int checkedIn = 3;
  static const int served = 4;
  static const int waitIncreased = 5;
  static const int betterServiceNearby = 6;
  static const int inactivityWarning = 7;
  static const int geofenceExit = 8;
  static const int queueExpired = 9;
  static const int staffCallNext = 10;
  static const int activeConfirm = 11;
  static const int geofenceReturn = 12; // Added
}

class NotifActionId {
  static const String confirmActive = 'CONFIRM_ACTIVE';
}

class NotificationManager {
  NotificationManager._();
  static final NotificationManager instance = NotificationManager._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Call once from main() or app widget initState before using any show* method.
  Future<void> init() async {
    if (_initialized) return;

    // Web does not support local notifications — skip silently.
    if (kIsWeb) {
      debugPrint(
        '[NotificationManager] Web platform — local notifications skipped.',
      );
      _initialized = true;
      return;
    }

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Create Android channels
    await _createChannel(
      id: _Channels.queue,
      name: 'Queue Updates',
      description: 'Notifications about your queue position and status.',
      importance: Importance.high,
    );
    await _createChannel(
      id: _Channels.geofence,
      name: 'Location Alerts',
      description: 'Alerts when you leave the service area.',
      importance: Importance.high,
    );
    await _createChannel(
      id: _Channels.ai,
      name: 'Smart Suggestions',
      description: 'AI-powered recommendations and wait time updates.',
      importance: Importance.defaultImportance,
    );
    await _createChannel(
      id: _Channels.staff,
      name: 'Staff Alerts',
      description: 'Notifications from staff (call-next, serve).',
      importance: Importance.max,
    );

    _initialized = true;
    debugPrint('[NotificationManager] Initialized.');
  }

  Future<void> _createChannel({
    required String id,
    required String name,
    required String description,
    Importance importance = Importance.defaultImportance,
  }) async {
    final channel = AndroidNotificationChannel(
      id,
      name,
      description: description,
      importance: importance,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  void _onNotificationTap(NotificationResponse response) {
    debugPrint('[NotificationManager] Tapped: ${response.payload}');

    // Handle action button taps (Android)
    if (response.notificationResponseType ==
            NotificationResponseType.selectedNotificationAction &&
        response.actionId == NotifActionId.confirmActive) {
      final payload = response.payload;
      if (payload == null) return;
      _handleConfirmActive(payload);
      return;
    }

    // Normal notification tap (no action)
    // TODO: route to relevant page based on payload
  }

  Future<void> _handleConfirmActive(String payload) async {
    // payload format: confirm_active|<serviceId>|<entryId>
    try {
      final parts = payload.split('|');
      if (parts.length < 3) return;
      if (parts[0] != 'confirm_active') return;
      final serviceId = parts[1];
      final entryId = parts[2];

      final firestore = FirebaseFirestore.instance;
      final entryRef = firestore
          .collection('services')
          .doc(serviceId)
          .collection('entries')
          .doc(entryId);

      await entryRef.update({
        'needsActiveConfirm': false,
        'confirmBy': FieldValue.delete(),
        'lastConfirmAt': FieldValue.serverTimestamp(),
      });

      // Optional: replace the notification to acknowledge
      await _show(
        id: NotifId.activeConfirm,
        title: '✅ Confirmed',
        body: 'You’re still active in the queue.',
        channelId: _Channels.queue,
        payload: 'confirmed',
      );
    } catch (e) {
      debugPrint('[NotificationManager] Confirm action error: $e');
    }
  }

  // ─── Internal helper ────────────────────────────────────────────────────────

  Future<void> _show({
    required int id,
    required String title,
    required String body,
    String channelId = _Channels.queue,
    String? payload,
    List<AndroidNotificationAction>? androidActions,
  }) async {
    if (!_initialized) await init();

    // On web, just print to console (useful for Chrome testing)
    if (kIsWeb) {
      await WebNotifier.instance.ensurePermission();
      await WebNotifier.instance.show(title: title, body: body);
      return;
    }

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelId,
      importance: Importance.high,
      priority: Priority.high,
      styleInformation: BigTextStyleInformation(body),
      actions: androidActions,
    );

    final details = NotificationDetails(android: androidDetails);
    await _plugin.show(id, title, body, details, payload: payload);
  }

  Future<void> cancel(int id) async {
    if (kIsWeb) return;
    await _plugin.cancel(id);
  }

  // ─── 1. Joined Queue ────────────────────────────────────────────────────────

  Future<void> showJoinedQueue({
    required String serviceName,
    required int lowMin,
    required int highMin,
  }) async {
    await _show(
      id: NotifId.joinedQueue,
      title: '✅ Joined Queue',
      body: 'You joined $serviceName. Estimated wait: $lowMin–$highMin mins.',
      channelId: _Channels.queue,
      payload: 'joined',
    );

    // Log to inbox
    NotificationInboxRepo.instance.add(
      title: 'Joined Queue',
      message:
          'You joined $serviceName. Estimated wait: $lowMin–$highMin mins.',
      type: 'queue',
    );
  }

  // ─── 2. Turn Coming Soon ────────────────────────────────────────────────────

  Future<void> showTurnComingSoon({required int position}) async {
    await _show(
      id: NotifId.turnComingSoon,
      title: '🔔 Almost Your Turn!',
      body:
          'Only $position ${position == 1 ? 'person' : 'people'} ahead of you.',
      channelId: _Channels.queue,
      payload: 'turn_soon',
    );

    // Log to inbox
    NotificationInboxRepo.instance.add(
      title: 'Queue Alert',
      message: 'Your turn is coming soon (Position #$position)',
      type: 'queue',
    );
  }

  // ─── 3. Checked In ──────────────────────────────────────────────────────────

  Future<void> showCheckedIn({required String serviceName}) async {
    await _show(
      id: NotifId.checkedIn,
      title: '🟢 You\'re Being Served',
      body: 'You\'re now active at $serviceName.',
      channelId: _Channels.queue,
      payload: 'checked_in',
    );

    // Log to inbox
    NotificationInboxRepo.instance.add(
      title: 'Checked In',
      message: 'You checked in at $serviceName',
      type: 'queue',
    );
  }

  // ─── 4. Served ──────────────────────────────────────────────────────────────

  Future<void> showServed({required String serviceName}) async {
    await _show(
      id: NotifId.served,
      title: '🎉 Service Complete',
      body: 'You were served at $serviceName. Thank you for using QueueLens!',
      channelId: _Channels.queue,
      payload: 'served',
    );

    // Log to inbox
    NotificationInboxRepo.instance.add(
      title: 'Served',
      message: 'You were served at $serviceName',
      type: 'queue',
    );
  }

  // ─── 5. Wait Time Increased ─────────────────────────────────────────────────

  Future<void> showWaitIncreased({
    required String serviceName,
    required int newWaitMin,
  }) async {
    await _show(
      id: NotifId.waitIncreased,
      title: '⚠️ Wait Time Increased',
      body: 'Wait at $serviceName is now ~$newWaitMin mins.',
      channelId: _Channels.ai,
      payload: 'wait_increased',
    );

    // Log to inbox
    NotificationInboxRepo.instance.add(
      title: 'Wait Increased',
      message: 'Wait time at $serviceName increased to $newWaitMin minutes',
      type: 'queue',
    );
  }

  // ─── 6. Better Service Nearby ───────────────────────────────────────────────

  Future<void> showBetterServiceNearby({
    required String serviceName,
    required int waitMin,
    required int distanceMeters,
  }) async {
    await _show(
      id: NotifId.betterServiceNearby,
      title: '🚀 Faster Option Nearby',
      body:
          '$serviceName has a shorter wait (~$waitMin min), ${distanceMeters}m away.',
      channelId: _Channels.ai,
      payload: 'better_service',
    );

    // Log to inbox
    NotificationInboxRepo.instance.add(
      title: 'Better Service Nearby',
      message:
          '$serviceName has shorter wait ($waitMin min) ${distanceMeters}m away',
      type: 'queue',
    );
  }

  // ─── 7. Inactivity Warning ──────────────────────────────────────────────────

  Future<void> showInactivityWarning({required String serviceName}) async {
    await _show(
      id: NotifId.inactivityWarning,
      title: '⚠️ Still Waiting?',
      body: 'No activity detected. Your place at $serviceName may expire soon.',
      channelId: _Channels.queue,
      payload: 'inactivity',
    );

    // Log to inbox
    NotificationInboxRepo.instance.add(
      title: 'Inactivity Warning',
      message:
          'No activity detected at $serviceName. Your place may expire soon.',
      type: 'queue',
    );
  }

  // ─── Active confirmation required (tap-to-stay) ─────────────────────────────

  Future<void> showActiveConfirmRequired({
    required String serviceId,
    required String entryId,
    required String serviceName,
    required String reason, // e.g. "left_service_area" or "scan_outside"
    int minutesToRespond = 2,
  }) async {
    final payload = 'confirm_active|$serviceId|$entryId';

    await _show(
      id: NotifId.activeConfirm,
      title: '⚠️ Are you still active?',
      body:
          'We detected you may be away from $serviceName. Tap “I’m here” within '
          '$minutesToRespond minutes to stay in the queue.',
      channelId: _Channels.geofence,
      payload: payload,
      androidActions: const [
        AndroidNotificationAction(
          NotifActionId.confirmActive,
          'I’m here',
          showsUserInterface: true,
          cancelNotification: true,
        ),
      ],
    );

    NotificationInboxRepo.instance.add(
      title: 'Active Confirmation',
      message:
          'Confirmation required to stay active in $serviceName (reason: $reason).',
      type: 'system',
    );
  }

  // ─── 8. Geofence Exit Warning ───────────────────────────────────────────────

  Future<void> showGeofenceExitWarning({required String serviceName}) async {
    await _show(
      id: NotifId.geofenceExit,
      title: '📍 You Left the Area',
      body:
          'You moved away from $serviceName. Still waiting? Come back within 2 mins.',
      channelId: _Channels.geofence,
      payload: 'geofence_exit',
    );

    // Log to inbox
    NotificationInboxRepo.instance.add(
      title: 'Location Alert',
      message: 'You left the service area at $serviceName',
      type: 'queue',
    );
  }

  // ─── 9. Geofence Return Notification ────────────────────────────────────────

  Future<void> showGeofenceReturn({required String serviceName}) async {
    await _show(
      id: NotifId.geofenceReturn,
      title: '✅ Back in Service Area',
      body: 'You are back within the service area for $serviceName.',
      channelId: _Channels.geofence,
      payload: 'geofence_return',
    );

    // Log to inbox
    NotificationInboxRepo.instance.add(
      title: 'Location OK',
      message: 'You returned to the service area at $serviceName',
      type: 'queue',
    );
  }

  // ─── 10. Queue Expired ───────────────────────────────────────────────────────

  Future<void> showQueueExpired({required String serviceName}) async {
    await _show(
      id: NotifId.queueExpired,
      title: '⏳ Queue Entry Expired',
      body: 'Your entry at $serviceName expired due to inactivity.',
      channelId: _Channels.queue,
      payload: 'expired',
    );

    // Log to inbox
    NotificationInboxRepo.instance.add(
      title: 'Queue Expired',
      message: 'Your queue entry at $serviceName has expired',
      type: 'queue',
    );
  }

  // ─── 11. Staff Call Next ────────────────────────────────────────────────────

  Future<void> showStaffCallNext({required String serviceName}) async {
    await _show(
      id: NotifId.staffCallNext,
      title: '🔔 Please Come Now',
      body:
          'Staff at $serviceName is calling you. Come to the counter immediately.',
      channelId: _Channels.staff,
      payload: 'call_next',
    );

    // Log to inbox
    NotificationInboxRepo.instance.add(
      title: 'Staff Calling',
      message: 'Staff at $serviceName is calling you to the counter',
      type: 'queue',
    );
  }

  Future<void> notifyInactivityWarning({required String serviceName}) {
    return showInactivityWarning(serviceName: serviceName);
  }

  Future<void> notifyExpired({
    required String serviceName,
    required String reason,
  }) {
    // you can include reason in the notification body if you want
    return showQueueExpired(serviceName: serviceName);
  }
}
