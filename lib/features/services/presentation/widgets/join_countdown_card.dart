// lib/features/queue/presentation/widgets/join_countdown_card.dart
import 'package:flutter/material.dart';
import 'dart:async';
import '../../domain/entities/queue_entry.dart';
import '../../../../core/constants/app_strings.dart';

class JoinCountdownCard extends StatefulWidget {
  final QueueEntry entry;

  final bool canCheckIn;

  final int? position;
  final int? avgMinsPerPerson;

  final VoidCallback onCheckIn;
  final VoidCallback onExpired;

  final DateTime? callExpiresAt;
  final String? calledEntryId;

  const JoinCountdownCard({
    super.key,
    required this.entry,
    required this.canCheckIn,
    required this.onCheckIn,
    this.position,
    this.avgMinsPerPerson,
    this.callExpiresAt,
    this.calledEntryId,
    required this.onExpired,
  });

  @override
  State<JoinCountdownCard> createState() => _JoinCountdownCardState();
}

class _JoinCountdownCardState extends State<JoinCountdownCard> {
  Timer? _timer;
  Duration _remaining = Duration.zero;
  bool _expiredFired = false;

  @override
  void initState() {
    super.initState();
    _syncTimer();
  }

  bool get _isCalledForMe =>
      widget.calledEntryId != null &&
      widget.calledEntryId == widget.entry.id &&
      widget.callExpiresAt != null;

  @override
  void didUpdateWidget(covariant JoinCountdownCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    final callChanged =
        oldWidget.calledEntryId != widget.calledEntryId ||
        oldWidget.callExpiresAt != widget.callExpiresAt;

    // If a NEW call comes in (or changes), allow expiration callback again
    if (callChanged) {
      _expiredFired = false;
      _updateRemaining();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _syncTimer() {
    // ✅ Only run countdown timer when user is allowed to check in
    if (!widget.canCheckIn) {
      _timer?.cancel();
      _timer = null;
      setState(() => _remaining = Duration.zero);
      return;
    }

    // ✅ If canCheckIn but no deadline, don't show expired (treat as not ready)
    if (widget.entry.checkInBy == null) {
      _timer?.cancel();
      _timer = null;
      setState(() => _remaining = const Duration(seconds: 1));
      return;
    }

    _updateRemaining(); // update immediately

    _timer?.cancel();
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _updateRemaining(),
    );
  }

  void _updateRemaining() {
    Duration remaining = Duration.zero;

    if (_isCalledForMe) {
      final expiresAt = widget.callExpiresAt!;
      final diff = expiresAt.difference(DateTime.now());
      remaining = diff.isNegative ? Duration.zero : diff;
    }

    // Fire expiration once (only when called for me)
    if (_isCalledForMe && !_expiredFired && remaining == Duration.zero) {
      _expiredFired = true;
      widget.onExpired();
    }

    if (mounted) {
      setState(() {
        _remaining = remaining;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // -----------------------------
    // CASE 1: NOT head -> waiting UI
    // -----------------------------
    if (!widget.canCheckIn) {
      final pos = widget.position ?? widget.entry.position ?? 0;
      final minsEach = widget.avgMinsPerPerson;

      int? estMins;
      if (pos > 1 && minsEach != null) {
        estMins = (pos - 1) * minsEach;
      }

      return Card(
        elevation: 0,
        color: Colors.blue.shade50,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.blue.shade200, width: 2),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.groups, size: 32, color: Colors.blue.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Waiting in queue',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'You’ll be able to check in when you are first.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    if (pos > 0)
                      Text(
                        'Your position: $pos',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    else
                      Text(
                        'Calculating your position...',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    const SizedBox(height: 8),
                    if (estMins != null)
                      Text(
                        'Estimated wait: ~${estMins} min',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      )
                    else
                      Text(
                        'Estimated wait: unavailable',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // -----------------------------
    // CASE 2: head -> check-in UI
    // -----------------------------
    final isExpired = _remaining == Duration.zero;
    final minutes = _remaining.inMinutes;
    final seconds = _remaining.inSeconds % 60;

    return Card(
      elevation: 0,
      color: isExpired ? Colors.red.shade50 : Colors.amber.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isExpired ? Colors.red.shade200 : Colors.amber.shade200,
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  Icons.timer,
                  size: 32,
                  color: isExpired
                      ? Colors.red.shade700
                      : Colors.amber.shade700,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.checkInRequired,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isExpired
                              ? Colors.red.shade700
                              : Colors.amber.shade700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isExpired ? 'Expired' : AppStrings.checkInNow,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    AppStrings.timeRemaining,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: isExpired ? Colors.red : Colors.amber.shade700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isExpired ? null : widget.onCheckIn,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  disabledBackgroundColor: Colors.grey.shade300,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle),
                    const SizedBox(width: 8),
                    Text(
                      AppStrings.checkIn,
                      style: const TextStyle(
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
    );
  }
}
