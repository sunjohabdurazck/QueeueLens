// lib/features/queue/presentation/pages/my_queue_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/queue_providers.dart';
import '../../domain/entities/queue_entry.dart';
import '../../../services/presentation/providers/services_providers.dart';
import '../../../../core/constants/app_strings.dart';
import '../widgets/join_countdown_card.dart';
import '../widgets/queue_position_card.dart';
import '../../../../src/screens/home_screen.dart';

class MyQueuePage extends ConsumerWidget {
  const MyQueuePage({super.key});

  Future<void> _handleCheckIn(
    BuildContext context,
    WidgetRef ref,
    QueueEntry entry,
  ) async {
    if (!context.mounted) return;

    // Show loading
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(width: 12),
            Text('Checking in...'),
          ],
        ),
        backgroundColor: Colors.blue,
        duration: Duration(seconds: 5),
      ),
    );

    try {
      final repository = ref.read(queueRepositoryProvider);
      await repository.checkIn(entry.serviceId, entry.id);

      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Checked in successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on FirebaseException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Firestore error: ${e.code} - ${e.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Check-in failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleLeaveQueue(
    BuildContext context,
    WidgetRef ref,
    QueueEntry entry,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.confirmLeave),
        content: const Text(AppStrings.areYouSure),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text(AppStrings.leave),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    if (!context.mounted) return;

    // Show loading
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(width: 12),
            Text('Leaving queue...'),
          ],
        ),
        backgroundColor: Colors.blue,
        duration: Duration(seconds: 5),
      ),
    );

    try {
      debugPrint(
        "MyQueuePage: Leaving queue - entryId: ${entry.id}, status: ${entry.status}",
      );

      final repository = ref.read(queueRepositoryProvider);
      await repository.leaveQueue(entry.serviceId, entry.id, entry.status);

      // Invalidate provider to refresh UI
      ref.invalidate(myActiveEntryProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppStrings.leftSuccessfully),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on FirebaseException catch (e) {
      debugPrint("MyQueuePage: FirebaseException - ${e.code}: ${e.message}");
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Firestore error: ${e.code}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e, stack) {
      debugPrint("MyQueuePage: Error - $e");
      debugPrint("Stack trace: $stack");
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to leave: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Helper method to determine if user can check in
  bool _canUserCheckIn(Map<String, dynamic>? serviceData, QueueEntry entry) {
    if (serviceData == null) return false;

    final activeEntryId = serviceData['activeEntryId'] as String?;
    final headPendingEntryId = serviceData['headPendingEntryId'] as String?;
    final calledEntryId = serviceData['calledEntryId'] as String?;
    final callExpiresAtTs = serviceData['callExpiresAt'] as Timestamp?;
    final callExpiresAt = callExpiresAtTs?.toDate();

    // must be head
    if (headPendingEntryId == null || headPendingEntryId != entry.id) {
      return false;
    }

    // no active user
    if (activeEntryId != null) return false;

    // ✅ must be CALLED and window must still be valid
    if (calledEntryId != entry.id) return false;
    if (callExpiresAt == null || !callExpiresAt.isAfter(DateTime.now())) {
      return false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entryAsync = ref.watch(myActiveEntryProvider);
    final user = FirebaseAuth.instance.currentUser;

    // Check if user is logged in
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text(AppStrings.myQueue), elevation: 0),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_off, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              const Text(
                'Not signed in',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Please sign in to view your queue',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (_) => const HomeScreen(initialIndex: 1),
                    ),
                    (route) => false,
                  );
                },
                child: const Text('Sign In'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.myQueue), elevation: 0),
      body: entryAsync.when(
        data: (entry) {
          if (entry == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppStrings.noActiveQueue,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppStrings.youAreNotInQueue,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (_) => const HomeScreen(initialIndex: 1),
                        ),
                        (route) => false,
                      );
                    },
                    icon: const Icon(Icons.search),
                    label: const Text('Find Services'),
                  ),
                ],
              ),
            );
          }

          // Watch entry with position
          final entryWithPosAsync = ref.watch(
            entryWithPositionProvider('${entry.serviceId}:${entry.id}'),
          );

          return entryWithPosAsync.when(
            data: (entryWithPos) {
              final currentEntry = entryWithPos ?? entry;

              // Watch service data for check-in logic
              final serviceDocAsync = ref.watch(
                serviceDocProvider(entry.serviceId),
              );

              return serviceDocAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => _buildErrorWidget('Service error: $e'),
                data: (serviceDoc) {
                  final serviceData = serviceDoc.data();
                  final canCheckIn = _canUserCheckIn(serviceData, currentEntry);

                  final calledEntryId =
                      serviceData?['calledEntryId'] as String?;
                  final callExpiresAtTs =
                      serviceData?['callExpiresAt'] as Timestamp?;
                  final DateTime? callExpiresAt = callExpiresAtTs?.toDate();

                  final isCalledForMe =
                      (calledEntryId == currentEntry.id) &&
                      callExpiresAtTs != null &&
                      callExpiresAtTs.toDate().isAfter(DateTime.now());

                  // Optional debug:
                  debugPrint('--- CHECKIN DEBUG ---');
                  debugPrint(
                    'entryId=${currentEntry.id} status=${currentEntry.status}',
                  );
                  debugPrint('activeEntryId=${serviceData?['activeEntryId']}');
                  debugPrint(
                    'headPendingEntryId=${serviceData?['headPendingEntryId']}',
                  );
                  debugPrint('calledEntryId=${serviceData?['calledEntryId']}');
                  debugPrint('isCalledForMe=$isCalledForMe');
                  debugPrint('canCheckIn=$canCheckIn');

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // User Info Card
                        Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: Colors.grey.shade200),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Your Queue Status',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _buildInfoRow('Service ID', entry.serviceId),
                                _buildInfoRow('Entry ID', entry.id),
                                _buildInfoRow(
                                  'Status',
                                  _getStatusText(entry.status),
                                ),
                                _buildInfoRow('User UID', user.uid),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Service Info Card
                        Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: Colors.grey.shade200),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: ref
                                .watch(serviceByIdProvider(entry.serviceId))
                                .when(
                                  data: (service) => Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        service?.name ?? 'Loading...',
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (service?.description.isNotEmpty ??
                                          false) ...[
                                        const SizedBox(height: 8),
                                        Text(
                                          service!.description,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  loading: () => const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                  error: (_, __) =>
                                      const Text('Error loading service'),
                                ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Status Card - FIXED TIMER LOGIC
                        if (currentEntry.isPending) ...[
                          if (isCalledForMe)
                            // Show countdown timer ONLY when called by staff
                            JoinCountdownCard(
                              entry: currentEntry,
                              canCheckIn: canCheckIn,
                              callExpiresAt: callExpiresAt,
                              calledEntryId: calledEntryId,
                              onCheckIn: () =>
                                  _handleCheckIn(context, ref, currentEntry),
                              onExpired: () async {
                                final repo = ref.read(queueRepositoryProvider);
                                await repo.expireCalledEntryDelete(
                                  serviceId: currentEntry.serviceId,
                                  reason: 'check_in_timeout',
                                );
                                ref.invalidate(myActiveEntryProvider);
                              },
                            )
                          else
                            // Show position card for regular pending (not called)
                            QueuePositionCard(
                              entry: currentEntry,
                              service: ref
                                  .watch(serviceByIdProvider(entry.serviceId))
                                  .valueOrNull,
                            ),
                        ] else if (currentEntry.isActive) ...[
                          // Show position card for active users
                          QueuePositionCard(
                            entry: currentEntry,
                            service: ref
                                .watch(serviceByIdProvider(entry.serviceId))
                                .valueOrNull,
                          ),
                        ],

                        const SizedBox(height: 24),

                        // Action Buttons
                        Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: Colors.grey.shade200),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                const Text(
                                  'Queue Actions',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Check-in button (shows only when canCheckIn is true)
                                if (currentEntry.isPending && canCheckIn)
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: () => _handleCheckIn(
                                        context,
                                        ref,
                                        currentEntry,
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green[700],
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 16,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            Icons.play_arrow,
                                            color: Colors.white,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            isCalledForMe
                                                ? 'Check In Now'
                                                : 'Check In (Activate)',
                                            style: const TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                const SizedBox(height: 12),

                                // Leave Button
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton(
                                    onPressed: () => _handleLeaveQueue(
                                      context,
                                      ref,
                                      currentEntry,
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.red,
                                      side: const BorderSide(color: Colors.red),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.exit_to_app),
                                        SizedBox(width: 8),
                                        Text(
                                          'Leave Queue',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => _buildErrorWidget(error.toString()),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _buildErrorWidget(error.toString()),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontFamily: 'monospace'),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusText(dynamic status) {
    if (status is QueueEntryStatus) {
      return status.toString().split('.').last.toUpperCase();
    } else if (status is String) {
      return status.toUpperCase();
    }
    return 'UNKNOWN';
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
          const SizedBox(height: 16),
          const Text(
            'Error loading queue',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              error,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

// Keep this provider definition
final serviceDocProvider = StreamProvider.autoDispose
    .family<DocumentSnapshot<Map<String, dynamic>>, String>((ref, serviceId) {
      return FirebaseFirestore.instance
          .collection('services')
          .doc(serviceId)
          .snapshots();
    });
