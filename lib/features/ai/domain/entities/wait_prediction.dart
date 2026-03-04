// lib/features/ai/domain/entities/wait_prediction.dart
class WaitPrediction {
  final int lowMinutes;
  final int highMinutes;
  final DateTime expectedTurnTime;
  final int averageServeSeconds;

  WaitPrediction({
    required this.lowMinutes,
    required this.highMinutes,
    required this.expectedTurnTime,
    required this.averageServeSeconds,
  });

  String get rangeDisplay => '$lowMinutes–$highMinutes min';
}
