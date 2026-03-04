// lib/features/queue/domain/repositories/queue_repository.dart

import '../entities/queue_entry.dart';

abstract class QueueRepository {
  /// Join queue as pending
  Future<QueueEntry> joinQueuePending(String serviceId, String tempUserKey);

  /// Check in (pending → active)
  Future<void> checkIn(String serviceId, String entryId);

  /// Leave queue
  Future<void> leaveQueue(
    String serviceId,
    String entryId,
    QueueEntryStatus currentStatus,
  );

  Future<void> expireCalledEntryDelete({
    required String serviceId,
    required String reason,
  });

  /// Watch user's active entry (across all services)
  Stream<QueueEntry?> watchMyActiveEntry(String tempUserKey);

  /// Watch specific entry
  Stream<QueueEntry?> watchEntry(String serviceId, String entryId);

  /// Get user's entry in specific service
  Future<QueueEntry?> getUserEntryInService(
    String serviceId,
    String tempUserKey,
  );

  /// Heartbeat update
  Future<void> updateHeartbeat(String serviceId, String entryId);

  /// Cleanup expired entries
  Future<void> cleanupExpiredEntries(String serviceId);

  /// Calculate position for entry
  Future<int> calculatePosition(String serviceId, String entryId);

  /// Sets warnedAt on an entry (used for inactivity warning).
  Future<void> markWarned(String serviceId, String entryId);

  /// Expires an entry and updates service counters transactionally.
  Future<void> expireEntry({
    required String serviceId,
    required String entryId,
    required String reason,
  });
}
