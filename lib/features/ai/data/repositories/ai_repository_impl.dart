// lib/features/ai/data/repositories/ai_repository_impl.dart
import '../../domain/entities/wait_stats.dart';
import '../../domain/repositories/ai_repository.dart';
import '../datasources/ai_local_datasource.dart';
import '../models/wait_stats_model.dart';

class AiRepositoryImpl implements AiRepository {
  final AiLocalDataSource local;

  AiRepositoryImpl(this.local);

  @override
  Future<WaitStats> getWaitStats(String serviceId) async {
    final json = await local.getStatsJson(serviceId);
    if (json == null) return WaitStats.empty();

    final model = WaitStatsModel.fromJson(json);
    return WaitStats(
      last20Seconds: model.last20Seconds,
      hourBucketSeconds: model.hourBucketSeconds,
    );
  }

  @override
  Future<void> logServeTime({
    required String serviceId,
    required int servedSeconds,
    required DateTime completedAt,
  }) async {
    final current = await getWaitStats(serviceId);

    final updatedLast20 = [...current.last20Seconds, servedSeconds];
    while (updatedLast20.length > 20) {
      updatedLast20.removeAt(0);
    }

    final buckets = <int, List<int>>{};
    buckets.addAll(current.hourBucketSeconds);

    final hour = completedAt.hour;
    final bucketList = [...(buckets[hour] ?? <int>[]), servedSeconds];

    // prevent huge memory growth
    if (bucketList.length > 60) {
      bucketList.removeRange(0, bucketList.length - 60);
    }

    buckets[hour] = bucketList;

    final model = WaitStatsModel(
      last20Seconds: updatedLast20,
      hourBucketSeconds: buckets,
    );

    await local.saveStatsJson(serviceId, model.toJson());
  }

  @override
  Future<bool> wasEntryLogged(String entryId) async {
    return await local.wasEntryLogged(entryId);
  }

  @override
  Future<void> markEntryLogged(String entryId) async {
    await local.markEntryLogged(entryId);
  }
}
