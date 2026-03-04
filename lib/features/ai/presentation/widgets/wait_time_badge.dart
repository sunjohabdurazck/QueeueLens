// lib/features/ai/presentation/widgets/wait_time_badge.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/ai_providers.dart';

class WaitTimeBadge extends ConsumerWidget {
  final String serviceId;
  final int position;

  const WaitTimeBadge({
    super.key,
    required this.serviceId,
    required this.position,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (position <= 0) {
      return const Text(
        'Waiting...',
        style: TextStyle(fontSize: 12, color: Colors.grey),
      );
    }

    final params = WaitPredictionParams(
      serviceId: serviceId,
      position: position,
    );

    final predictionAsync = ref.watch(waitPredictionProvider(params));

    return predictionAsync.when(
      data: (prediction) => Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            prediction.rangeDisplay,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.orange,
            ),
          ),
          Text(
            'estimated',
            style: TextStyle(fontSize: 10, color: Colors.grey[600]),
          ),
        ],
      ),
      loading: () => const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      error: (_, __) => Text(
        '~${position * 2} min',
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
    );
  }
}
