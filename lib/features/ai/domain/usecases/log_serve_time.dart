import '../repositories/ai_repository.dart';

class LogServeTime {
  final AiRepository repo;
  const LogServeTime(this.repo);

  Future<void> call({
    required String serviceId,
    required int servedSeconds,
    required DateTime completedAt,
  }) {
    return repo.logServeTime(
      serviceId: serviceId,
      servedSeconds: servedSeconds,
      completedAt: completedAt,
    );
  }
}
