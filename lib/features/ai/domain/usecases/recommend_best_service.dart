// lib/features/ai/domain/usecases/recommend_best_service.dart
import 'dart:math';
import '../entities/recommendation.dart';

class RecommendBestService {
  ServiceRecommendation? call({
    required List<ServiceData> services,
    required double userLat,
    required double userLon,
  }) {
    if (services.isEmpty) return null;

    final scored = services.map((s) {
      final waitScore = _clamp(1 - s.waitMin / 60, 0, 1);
      final distScore = _clamp(1 - s.distanceMeters / 800, 0, 1);
      final openScore = s.isOpen ? 1.0 : 0.0;

      final score = 0.55 * waitScore + 0.35 * distScore + 0.10 * openScore;

      return ServiceRecommendation(
        serviceId: s.serviceId,
        serviceName: s.serviceName,
        waitMin: s.waitMin,
        distanceMeters: s.distanceMeters,
        isOpen: s.isOpen,
        score: score,
      );
    }).toList();

    scored.sort((a, b) => b.score.compareTo(a.score));
    return scored.first;
  }

  double _clamp(double value, double min, double max) {
    if (value < min) return min;
    if (value > max) return max;
    return value;
  }
}

class ServiceData {
  final String serviceId;
  final String serviceName;
  final int waitMin;
  final double distanceMeters;
  final bool isOpen;

  ServiceData({
    required this.serviceId,
    required this.serviceName,
    required this.waitMin,
    required this.distanceMeters,
    required this.isOpen,
  });
}
