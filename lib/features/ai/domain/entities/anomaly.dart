// lib/features/ai/domain/entities/anomaly.dart
enum AnomalyType { spamJoinLeave, highExpireRate, suddenJump, stuckActive }

enum AnomalySeverity { low, medium, high }

class Anomaly {
  final String id; // Add this field
  final AnomalyType type;
  final AnomalySeverity severity;
  final String serviceId;
  final String message;
  final DateTime detectedAt;

  Anomaly({
    required this.id, // Add this parameter
    required this.type,
    required this.severity,
    required this.serviceId,
    required this.message,
    required this.detectedAt,
  });
}
