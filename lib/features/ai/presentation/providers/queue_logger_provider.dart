// lib/features/ai/presentation/providers/queue_logger_provider.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/usecases/log_completed_entries.dart';
import 'ai_providers.dart';
import '../../../services/presentation/providers/services_providers.dart';
import '../../../services/domain/entities/service_point.dart'; // Add this import

// This provider watches all queue entries and logs completed ones
final queueLoggerProvider = Provider<QueueLogger>((ref) {
  final repo = ref.read(aiRepositoryProvider);
  return QueueLogger(repo, ref);
});

class QueueLogger {
  final dynamic repo;
  final Ref ref;

  QueueLogger(this.repo, this.ref) {
    _initialize();
  }

  void _initialize() {
    // Watch the services stream
    ref.listen<AsyncValue<List<ServicePoint>>>(servicesStreamProvider, (
      previous,
      next,
    ) {
      next.when(
        data: (services) async {
          for (final service in services) {
            try {
              // Get queue for this service
              // First, check if we have access to queue data
              // For now, just log a debug message
              if (kDebugMode) {
                debugPrint('Would fetch queue for service: ${service.id}');
              }

              // Note: You'll need to implement queue fetching logic
              // If you have a queue repository, you can use it here
              // Example:
              // final queueRepo = ref.read(queueRepositoryProvider);
              // final entries = await queueRepo.getQueueEntries(service.id);
              //
              // if (entries.isNotEmpty) {
              //   final usecase = LogCompletedEntries(repo);
              //   await usecase(entries);
              // }
            } catch (e) {
              if (kDebugMode) {
                debugPrint(
                  'Error fetching queue for service ${service.id}: $e',
                );
              }
            }
          }
        },
        loading: () {
          // Do nothing while loading
        },
        error: (error, stackTrace) {
          if (kDebugMode) {
            debugPrint('Error fetching services: $error');
          }
        },
      );
    });
  }
}
