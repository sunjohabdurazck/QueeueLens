import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/notifications/notification_manager.dart';
import '../../../services/domain/repositories/queue_repository.dart';

/// Queue integrity: inactivity handling.
/// - Warn at 4 minutes of inactivity
/// - Expire at 6 minutes of inactivity
///
/// Requires entry fields:
/// - lastSeenAt (Timestamp)
/// - warnedAt (Timestamp?)  // set once when warning is sent
class ExpireInactiveEntries {
  ExpireInactiveEntries({
    required this.queueRepo,
    NotificationManager? notifier,
  }) : _notifier = notifier ?? NotificationManager.instance;

  final QueueRepository queueRepo;
  final NotificationManager _notifier;

  Future<void> process({
    required String serviceId,
    required String entryId,
    required String serviceName,
    required Timestamp lastSeenAt,
    required String status, // pending / active
    Timestamp? warnedAt,
  }) async {
    final now = DateTime.now();
    final last = lastSeenAt.toDate();
    final inactiveMins = now.difference(last).inMinutes;

    // Warn once at >= 4 mins
    if (inactiveMins >= 4 && warnedAt == null) {
      await _notifier.notifyInactivityWarning(serviceName: serviceName);
      try {
        await queueRepo.markWarned(serviceId, entryId);
      } catch (e) {
        debugPrint('[ExpireInactiveEntries] markWarned failed: $e');
      }
      return;
    }

    // Expire at >= 6 mins
    if (inactiveMins >= 6) {
      await queueRepo.expireEntry(
        serviceId: serviceId,
        entryId: entryId,
        reason: 'inactivity',
      );
      await _notifier.notifyExpired(
        serviceName: serviceName,
        reason: 'inactivity',
      );
    }
  }
}
