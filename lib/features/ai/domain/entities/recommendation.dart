// lib/features/ai/domain/entities/recommendation.dart
class ServiceRecommendation {
  final String serviceId;
  final String serviceName;
  final int waitMin;
  final double distanceMeters;
  final bool isOpen;
  final double score;

  ServiceRecommendation({
    required this.serviceId,
    required this.serviceName,
    required this.waitMin,
    required this.distanceMeters,
    required this.isOpen,
    required this.score,
  });
}
