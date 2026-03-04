// lib/features/ai/data/models/wait_stats_model.dart
class WaitStatsModel {
  final List<int> last20Seconds;
  final Map<int, List<int>> hourBucketSeconds;

  WaitStatsModel({
    required this.last20Seconds,
    required this.hourBucketSeconds,
  });

  Map<String, dynamic> toJson() => {
    "last20Seconds": last20Seconds,
    "hourBucketSeconds": hourBucketSeconds.map(
      (k, v) => MapEntry(k.toString(), v),
    ),
  };

  static WaitStatsModel fromJson(Map<String, dynamic> json) {
    final Map<int, List<int>> buckets = {};
    final jsonBuckets =
        json["hourBucketSeconds"] as Map<String, dynamic>? ?? {};

    for (final entry in jsonBuckets.entries) {
      final hour = int.parse(entry.key);
      final values = (entry.value as List).cast<int>();
      buckets[hour] = values;
    }

    return WaitStatsModel(
      last20Seconds: (json["last20Seconds"] as List?)?.cast<int>() ?? [],
      hourBucketSeconds: buckets,
    );
  }

  static WaitStatsModel empty() =>
      WaitStatsModel(last20Seconds: [], hourBucketSeconds: {});
}
