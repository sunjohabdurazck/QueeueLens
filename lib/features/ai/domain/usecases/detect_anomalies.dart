// lib/features/ai/domain/usecases/detect_anomalies.dart
import 'dart:math'; // Keep this import if you need Random
import '../entities/anomaly.dart';

class DetectAnomalies {
  const DetectAnomalies();

  List<Anomaly> call({
    required String serviceId,
    required int joinLeaveCount5Min,
    required double expiredRatio1Hr,
    required int suddenJumpDelta,
    required int activeTooLongCount,
  }) {
    final now = DateTime.now();
    final out = <Anomaly>[];
    final random = Random();

    if (joinLeaveCount5Min >= 4) {
      out.add(
        Anomaly(
          id: 'spam_${now.millisecondsSinceEpoch}_${random.nextInt(1000)}',
          type: AnomalyType.spamJoinLeave,
          serviceId: serviceId,
          message: 'High join/leave activity detected.',
          severity: AnomalySeverity.medium,
          detectedAt: now,
        ),
      );
    }

    if (expiredRatio1Hr >= 0.25) {
      out.add(
        Anomaly(
          id: 'expire_${now.millisecondsSinceEpoch}_${random.nextInt(1000)}',
          type: AnomalyType.highExpireRate,
          serviceId: serviceId,
          message: 'Many expired entries detected.',
          severity: AnomalySeverity.medium,
          detectedAt: now,
        ),
      );
    }

    if (suddenJumpDelta >= 15) {
      out.add(
        Anomaly(
          id: 'jump_${now.millisecondsSinceEpoch}_${random.nextInt(1000)}',
          type: AnomalyType.suddenJump,
          serviceId: serviceId,
          message: 'Queue size jumped suddenly.',
          severity: AnomalySeverity.high,
          detectedAt: now,
        ),
      );
    }

    if (activeTooLongCount >= 1) {
      out.add(
        Anomaly(
          id: 'stuck_${now.millisecondsSinceEpoch}_${random.nextInt(1000)}',
          type: AnomalyType.stuckActive,
          serviceId: serviceId,
          message: 'Some active entries are taking too long.',
          severity: AnomalySeverity.high,
          detectedAt: now,
        ),
      );
    }

    return out;
  }
}
