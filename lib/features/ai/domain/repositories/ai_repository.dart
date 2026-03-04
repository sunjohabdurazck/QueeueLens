// lib/features/ai/domain/repositories/ai_repository.dart
import '../entities/wait_stats.dart';

abstract class AiRepository {
  Future<WaitStats> getWaitStats(String serviceId);
  Future<void> logServeTime({
    required String serviceId,
    required int servedSeconds,
    required DateTime completedAt,
  });
  Future<bool> wasEntryLogged(String entryId);
  Future<void> markEntryLogged(String entryId);
}
