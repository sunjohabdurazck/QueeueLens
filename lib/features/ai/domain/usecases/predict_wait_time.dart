// lib/features/ai/domain/usecases/predict_wait_time.dart
import '../entities/wait_prediction.dart';
import '../repositories/ai_repository.dart';

class PredictWaitTime {
  final AiRepository repo;
  PredictWaitTime(this.repo);

  Future<WaitPrediction> call({
    required String serviceId,
    required int positionInQueue,
    required DateTime now,
    int fallbackServeSeconds = 120,
  }) async {
    final stats = await repo.getWaitStats(serviceId);

    int avg(List<int> xs) => xs.isEmpty
        ? fallbackServeSeconds
        : (xs.reduce((a, b) => a + b) ~/ xs.length);

    final rolling = avg(stats.last20Seconds);
    final bucketList = stats.hourBucketSeconds[now.hour] ?? const <int>[];
    final bucket = avg(bucketList);

    final predictedServe = stats.last20Seconds.isEmpty && bucketList.isEmpty
        ? fallbackServeSeconds
        : ((0.6 * bucket) + (0.4 * rolling)).round();

    // Wait time calculation: only count people ahead in queue
    // If you're position 1, wait should be 0 (you're being served now)
    final ahead = (positionInQueue - 1).clamp(0, 1 << 30);
    final etaSec = ahead * predictedServe;

    final low = (etaSec * 0.85).round();
    final high = (etaSec * 1.15).round();

    int toMin(int s) => (s / 60).ceil();

    return WaitPrediction(
      lowMinutes: toMin(low),
      highMinutes: toMin(high),
      expectedTurnTime: now.add(Duration(seconds: etaSec)),
      averageServeSeconds: predictedServe,
    );
  }
}
