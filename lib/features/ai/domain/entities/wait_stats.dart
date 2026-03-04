// lib/features/ai/domain/entities/wait_stats.dart
class WaitStats {
  final List<int> last20Seconds;
  final Map<int, List<int>> hourBucketSeconds;

  WaitStats({required this.last20Seconds, required this.hourBucketSeconds});

  static WaitStats empty() =>
      WaitStats(last20Seconds: [], hourBucketSeconds: {});
}
