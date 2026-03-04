// lib/features/ai/domain/entities/serve_time_log.dart
class ServeTimeLog {
  final String serviceId;
  final int servedSeconds;
  final DateTime completedAt;

  ServeTimeLog({
    required this.serviceId,
    required this.servedSeconds,
    required this.completedAt,
  });
}
