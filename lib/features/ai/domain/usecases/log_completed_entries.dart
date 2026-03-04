// lib/features/ai/domain/usecases/log_completed_entries.dart
import '../repositories/ai_repository.dart';
import '../../../services/domain/entities/queue_entry.dart';

class LogCompletedEntries {
  final AiRepository repo;

  LogCompletedEntries(this.repo);

  Future<void> call(List<QueueEntry> entries) async {
    for (final entry in entries) {
      // Only log "served" entries (not "completed" as originally written)
      if (entry.status == QueueEntryStatus.served) {
        final alreadyLogged = await repo.wasEntryLogged(entry.id);

        if (!alreadyLogged) {
          // Calculate duration from joinedAt to current time
          // Since we don't have completedAt, use current time as approximation
          final joinedTime = entry.joinedAt.toDate();
          final completedTime = DateTime.now();

          final duration = completedTime.difference(joinedTime).inSeconds;

          // Only log reasonable durations (30 sec to 1 hour)
          if (duration >= 30 && duration <= 3600) {
            await repo.logServeTime(
              serviceId: entry.serviceId,
              servedSeconds: duration,
              completedAt: completedTime,
            );

            await repo.markEntryLogged(entry.id);
          }
        }
      }
    }
  }
}
