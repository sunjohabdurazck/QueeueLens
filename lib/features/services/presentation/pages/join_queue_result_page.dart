// lib/features/queue/presentation/pages/join_queue_result_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/queue_providers.dart';
import '../../domain/entities/queue_entry.dart';
import '../../../../core/constants/app_strings.dart';
import '../widgets/join_countdown_card.dart';
import 'my_queue_page.dart';
import '../../../services/presentation/providers/services_providers.dart';

class JoinQueueResultPage extends ConsumerStatefulWidget {
  final String serviceId;
  final String serviceName;

  const JoinQueueResultPage({
    super.key,
    required this.serviceId,
    required this.serviceName,
  });

  @override
  ConsumerState<JoinQueueResultPage> createState() =>
      _JoinQueueResultPageState();
}

class _JoinQueueResultPageState extends ConsumerState<JoinQueueResultPage> {
  bool _isJoining = true;
  QueueEntry? _createdEntry;
  String? _error;

  @override
  void initState() {
    super.initState();
    _joinQueue();
  }

  Future<void> _joinQueue() async {
    try {
      final tempUserKeyAsync = await ref.read(tempUserKeyProvider.future);
      final repository = ref.read(queueRepositoryProvider);

      // Check if already in this queue
      final existingEntry = await repository.getUserEntryInService(
        widget.serviceId,
        tempUserKeyAsync,
      );

      if (existingEntry != null) {
        setState(() {
          _error = AppStrings.alreadyInThisQueue;
          _isJoining = false;
        });
        return;
      }

      // Check if already in another queue
      final myEntry = await ref.read(myActiveEntryProvider.future);
      if (myEntry != null) {
        setState(() {
          _error = AppStrings.alreadyInOtherQueue;
          _isJoining = false;
        });
        return;
      }

      // Join queue
      final entry = await repository.joinQueuePending(
        widget.serviceId,
        tempUserKeyAsync,
      );

      setState(() {
        _createdEntry = entry;
        _isJoining = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppStrings.joinedSuccessfully),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isJoining = false;
      });
    }
  }

  Future<void> _handleCheckIn() async {
    if (_createdEntry == null) return;

    try {
      final repository = ref.read(queueRepositoryProvider);
      await repository.checkIn(widget.serviceId, _createdEntry!.id);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MyQueuePage()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Check-in failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.serviceName), elevation: 0),
      body: _isJoining
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red.shade300,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      style: const TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Go Back'),
                    ),
                  ],
                ),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Icon(
                            Icons.done_all,
                            size: 48,
                            color: Colors.green.shade600,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            AppStrings.joinedSuccessfully,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Service: ${widget.serviceName}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_createdEntry != null)
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MyQueuePage(),
                          ),
                        );
                      },
                      child: const Text('Go to My Queue'),
                    ),
                ],
              ),
            ),
    );
  }
}
