// lib/features/queue/application/queue_intelligence_provider.dart
//
// Riverpod wiring for QueueIntelligenceListener.
// Keeps one active listener per app session.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/ai/data/datasources/ai_local_datasource.dart';
import '../../../features/ai/data/repositories/ai_repository_impl.dart';
import '../../../features/services/presentation/providers/queue_providers.dart';
import 'queue_intelligence_listener.dart';

final queueIntelligenceListenerProvider =
    Provider<QueueIntelligenceListener>((ref) {
  final queueRepo = ref.watch(queueRepositoryProvider);
  final aiRepo = AiRepositoryImpl(AiLocalDataSource());

  final listener = QueueIntelligenceListener(
    queueRepo: queueRepo,
    aiRepo: aiRepo,
  );

  // Auto-dispose: stop listener when provider is destroyed
  ref.onDispose(() => listener.stop());

  return listener;
});
