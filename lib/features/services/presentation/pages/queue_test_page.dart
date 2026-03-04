// lib/features/services/presentation/pages/queue_test_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class QueueTestPage extends StatefulWidget {
  const QueueTestPage({super.key});

  @override
  State<QueueTestPage> createState() => _QueueTestPageState();
}

class _QueueTestPageState extends State<QueueTestPage> {
  static const String serviceId = 'svc_library_print';

  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  bool _loading = false;
  String? _error;

  String? get _entryId {
    final user = _auth.currentUser;
    if (user == null) return null;
    return 'ENTRY_${user.uid}';
  }

  DocumentReference<Map<String, dynamic>> get _serviceRef =>
      _db.collection('services').doc(serviceId);

  DocumentReference<Map<String, dynamic>>? get _entryRef {
    final entryId = _entryId;
    if (entryId == null) return null;
    return _serviceRef.collection('entries').doc(entryId);
  }

  Future<void> joinQueue() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Not logged in. Please sign in first.');

      final entryRef = _entryRef!;
      final entrySnap = await entryRef.get();

      // Check if already in queue
      if (entrySnap.exists) {
        final entryData = entrySnap.data() ?? {};
        final status = (entryData['status'] ?? 'pending').toString();
        throw Exception(
          'You\'re already in the queue (status: $status). '
          'Leave queue first to join again.',
        );
      }

      final now = DateTime.now();
      final checkInBy = Timestamp.fromDate(now.add(const Duration(minutes: 5)));

      // Create entry (pending) - WITHOUT transaction
      await entryRef.set({
        'id': _entryId,
        'serviceId': serviceId,
        'status': 'pending',
        'tempUserKey': user.uid,
        'joinedAt': FieldValue.serverTimestamp(),
        'lastSeenAt': FieldValue.serverTimestamp(),
        'checkInBy': checkInBy,
        'userId': user.uid,
        'checkedInAt': null,
        'userEmail': user.email,
        'userDisplayName': user.displayName,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Try to increment pendingCount - may fail due to rules, that's OK
      try {
        await _serviceRef.update({
          'pendingCount': FieldValue.increment(1),
          'lastUpdatedAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        // If this fails, just log it - the entry was created successfully
        print('Note: Could not update service counter: $e');
      }

      setState(() => _error = null);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> activateNow() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Not logged in.');

      final entryRef = _entryRef!;
      final serviceRef = _serviceRef;

      // First check if user is in queue
      final entrySnap = await entryRef.get();
      if (!entrySnap.exists) {
        throw Exception('Cannot activate: You\'re not in the queue.');
      }

      final entryData = entrySnap.data() ?? {};
      final status = (entryData['status'] ?? 'pending').toString();

      // Check if already active
      if (status == 'active') {
        throw Exception('You\'re already active in the queue.');
      }

      // Check if not pending
      if (status != 'pending') {
        throw Exception('Cannot activate from current status: $status');
      }

      // Get current counters
      final serviceSnap = await serviceRef.get();
      final serviceData = serviceSnap.data() ?? {};
      final pendingCount = (serviceData['pendingCount'] ?? 0) as int;
      final activeCount = (serviceData['activeCount'] ?? 0) as int;

      // Update entry to active
      await entryRef.update({
        'status': 'active',
        'checkedInAt': FieldValue.serverTimestamp(),
        'lastSeenAt': FieldValue.serverTimestamp(),
        'activatedAt': FieldValue.serverTimestamp(),
      });

      // Try to update counters - may fail due to rules
      try {
        await serviceRef.update({
          'pendingCount': pendingCount > 0 ? pendingCount - 1 : 0,
          'activeCount': activeCount + 1,
          'lastUpdatedAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        print('Note: Could not update service counters: $e');
      }

      setState(() => _error = null);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> leaveQueue() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Not logged in.');

      final entryRef = _entryRef!;
      final entrySnap = await entryRef.get();

      // Check if not in queue
      if (!entrySnap.exists) {
        throw Exception('Cannot leave: You\'re not in the queue.');
      }

      final entryData = entrySnap.data() ?? {};
      final status = (entryData['status'] ?? 'pending').toString();

      print("DEBUG: Leaving queue - status: $status");
      print("DEBUG: User UID: ${user.uid}");
      print("DEBUG: Entry tempUserKey: ${entryData['tempUserKey']}");

      // Delete the entry first
      print("DEBUG: Attempting to delete entry...");
      await entryRef.delete();
      print("DEBUG: Entry deleted successfully");

      // Try to update counter based on status
      try {
        final serviceRef = _serviceRef;
        final serviceSnap = await serviceRef.get();
        final serviceData = serviceSnap.data() ?? {};

        print("DEBUG: Current service data:");
        print("  - pendingCount: ${serviceData['pendingCount']}");
        print("  - activeCount: ${serviceData['activeCount']}");

        if (status == 'active') {
          final activeCount = (serviceData['activeCount'] ?? 0) as int;
          final newActive = activeCount > 0 ? activeCount - 1 : 0;
          print("DEBUG: Updating activeCount from $activeCount to $newActive");

          await serviceRef.update({
            'activeCount': newActive,
            'lastUpdatedAt': FieldValue.serverTimestamp(),
          });
          print("DEBUG: Service counter updated successfully");
        } else {
          final pendingCount = (serviceData['pendingCount'] ?? 0) as int;
          final newPending = pendingCount > 0 ? pendingCount - 1 : 0;
          print(
            "DEBUG: Updating pendingCount from $pendingCount to $newPending",
          );

          await serviceRef.update({
            'pendingCount': newPending,
            'lastUpdatedAt': FieldValue.serverTimestamp(),
          });
          print("DEBUG: Service counter updated successfully");
        }
      } catch (e) {
        print('DEBUG: Counter update error: $e');
        print('DEBUG: Error type: ${e.runtimeType}');
        // Don't re-throw - this is allowed to fail
      }

      setState(() => _error = null);
    } catch (e) {
      print("DEBUG: leaveQueue main error: $e");
      print("DEBUG: Error type: ${e.runtimeType}");
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Queue Test')),
        body: const Center(
          child: Text('You are not logged in. Please sign in first.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Queue Test'),
        backgroundColor: Colors.blue[800],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Info Card
            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'User Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow('UID', user.uid),
                    _buildInfoRow('Email', user.email ?? '(none)'),
                    _buildInfoRow('Service ID', serviceId),
                    _buildInfoRow('Entry ID', _entryId ?? '(none)'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Error Display
            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Action Buttons
            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      'Queue Actions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Join Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _loading ? null : joinQueue,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _loading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add, color: Colors.white),
                                  SizedBox(width: 8),
                                  Text(
                                    'Join Queue (Pending +1)',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Adds you to pending queue',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),

                    const SizedBox(height: 20),

                    Row(
                      children: [
                        // Activate Button
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _loading ? null : activateNow,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[700],
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.play_arrow, color: Colors.white),
                                SizedBox(width: 8),
                                Text(
                                  'Activate Now',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Leave Button
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _loading ? null : leaveQueue,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red[700],
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.exit_to_app, color: Colors.white),
                                SizedBox(width: 8),
                                Text(
                                  'Leave Queue',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: const Text(
                            'Pending -1, Active +1',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Expanded(
                          child: const Text(
                            'Remove from queue',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Service Counters
            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Service Counters',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 12),
                    StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                      stream: _serviceRef.snapshots(),
                      builder: (context, snap) {
                        if (snap.hasError) {
                          return Text('Error: ${snap.error}');
                        }
                        if (!snap.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        final doc = snap.data!;
                        final data = doc.data() ?? {};
                        final pending = data['pendingCount'] ?? 0;
                        final active = data['activeCount'] ?? 0;

                        return Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildCounterCircle(
                                  'Pending',
                                  pending,
                                  Colors.orange,
                                ),
                                _buildCounterCircle(
                                  'Active',
                                  active,
                                  Colors.green,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: Text(
                                _formatData(data),
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Your Queue Entry
            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your Queue Entry',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _entryRef == null
                        ? const Center(child: Text('Entry ref is null'))
                        : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                            stream: _entryRef!.snapshots(),
                            builder: (context, snap) {
                              if (snap.hasError) {
                                return Text('Error: ${snap.error}');
                              }
                              if (!snap.hasData) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }

                              final doc = snap.data!;
                              if (!doc.exists) {
                                return const Center(
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.queue,
                                        size: 48,
                                        color: Colors.grey,
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'Not in queue',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }

                              final data = doc.data() ?? {};
                              final status = data['status'] ?? 'unknown';
                              Color statusColor = Colors.grey;

                              if (status == 'pending')
                                statusColor = Colors.orange;
                              if (status == 'active')
                                statusColor = Colors.green;

                              return Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: statusColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: statusColor),
                                    ),
                                    child: Text(
                                      'Status: ${status.toUpperCase()}',
                                      style: TextStyle(
                                        color: statusColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[50],
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.grey[300]!,
                                      ),
                                    ),
                                    child: Text(
                                      _formatData(data),
                                      style: const TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                  ],
                ),
              ),
            ),
          ],
        ),
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
            child: Text(value, style: const TextStyle(fontFamily: 'monospace')),
          ),
        ],
      ),
    );
  }

  Widget _buildCounterCircle(String label, dynamic value, Color color) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
          child: Center(
            child: Text(
              value.toString(),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _formatData(Map<String, dynamic> data) {
    final keys = data.keys.toList()..sort();
    return keys
        .map((key) {
          final value = data[key];
          String displayValue;

          if (value is Timestamp) {
            displayValue = value.toDate().toString();
          } else if (value == null) {
            displayValue = 'null';
          } else {
            displayValue = value.toString();
          }

          return '$key: $displayValue';
        })
        .join('\n');
  }
}
