// lib/features/queue/presentation/widgets/queue_position_card.dart
import 'package:flutter/material.dart';
import '../../domain/entities/queue_entry.dart';
import '../../../services/domain/entities/service_point.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/date_time_utils.dart';

class QueuePositionCard extends StatelessWidget {
  final QueueEntry entry;
  final ServicePoint? service;

  const QueuePositionCard({super.key, required this.entry, this.service});

  @override
  Widget build(BuildContext context) {
    final position = entry.position ?? 0;

    // AI Prediction Logic: Only count people ahead in queue
    // If position is 1, peopleAhead = 0 (you're being served now)
    // If position is 2, peopleAhead = 1 (wait for one person)
    // If position is 3, peopleAhead = 2 (wait for two people)
    final peopleAhead = position > 0 ? position - 1 : 0;

    // Calculate estimated wait time using people ahead × average serve time
    final estimatedWait = service != null && peopleAhead > 0
        ? peopleAhead * service!.avgMinsPerPerson
        : 0;

    // Calculate range estimates (±15% like AI prediction)
    final lowEstimate = estimatedWait > 0 ? (estimatedWait * 0.85).round() : 0;
    final highEstimate = estimatedWait > 0 ? (estimatedWait * 1.15).round() : 0;

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
                Icon(
                  entry.isActive ? Icons.check_circle : Icons.access_time,
                  size: 32,
                  color: entry.isActive
                      ? Colors.green.shade600
                      : Colors.orange.shade600,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.isActive ? 'Currently Serving' : 'In Queue',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: entry.isActive
                              ? Colors.green.shade700
                              : Colors.orange.shade700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Status: ${entry.status.displayName}',
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
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildStatBox(
                    label: 'People Ahead',
                    value: peopleAhead.toString(),
                    icon: Icons.people_outline,
                    color: Colors.blue,
                    subtitle: position > 0 ? 'Position #$position' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatBox(
                    label: AppStrings.estimatedWait,
                    value: estimatedWait > 0
                        ? DateTimeUtils.formatTime(estimatedWait)
                        : (position == 1 ? 'Now' : '-'),
                    icon: Icons.schedule,
                    color: Colors.orange,
                    subtitle: estimatedWait > 0
                        ? '${DateTimeUtils.formatTime(lowEstimate)} - ${DateTimeUtils.formatTime(highEstimate)}'
                        : null,
                  ),
                ),
              ],
            ),
            if (position == 1 && entry.isPending) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.green.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "You're next in line! Please wait to be called.",
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatBox({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
