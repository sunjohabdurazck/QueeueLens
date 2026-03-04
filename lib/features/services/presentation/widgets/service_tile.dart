// lib/features/services/presentation/widgets/service_tile.dart
import 'package:flutter/material.dart';
import '../../domain/entities/service_point.dart';
import '../../../../core/constants/app_strings.dart';
import 'status_chip.dart';

class ServiceTile extends StatelessWidget {
  final ServicePoint service;
  final VoidCallback onTap;

  const ServiceTile({super.key, required this.service, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      service.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  StatusChip(status: service.status),
                ],
              ),
              if (service.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  service.description,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildInfoChip(
                    icon: Icons.people,
                    label: '${service.activeCount}',
                    subtitle: AppStrings.activeInQueue,
                    color: Colors.blue,
                  ),
                  const SizedBox(width: 12),
                  _buildInfoChip(
                    icon: Icons.schedule,
                    label: '${service.estimatedWaitMinutes}',
                    subtitle: AppStrings.minutes,
                    color: Colors.orange,
                  ),
                  if (service.pendingCount > 0) ...[
                    const SizedBox(width: 12),
                    _buildInfoChip(
                      icon: Icons.hourglass_empty,
                      label: '${service.pendingCount}',
                      subtitle: 'pending',
                      color: Colors.purple,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        // FIXED: Use Color.alphaBlend or withOpacity alternative
        color: color.withAlpha(25), // Equivalent to 0.1 opacity
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
