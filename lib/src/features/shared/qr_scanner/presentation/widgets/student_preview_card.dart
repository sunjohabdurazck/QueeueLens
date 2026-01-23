import 'package:flutter/material.dart';
import '../../domain/entities/qr_data.dart';

class StudentPreviewCard extends StatelessWidget {
  final QRData studentData;
  final VoidCallback? onEdit;
  final VoidCallback? onRetry;
  final VoidCallback? onConfirm;

  const StudentPreviewCard({
    Key? key,
    required this.studentData,
    this.onEdit,
    this.onRetry,
    this.onConfirm,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person,
                    size: 32,
                    color: Colors.blue.shade700,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        studentData.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ID: ${studentData.studentID}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            _InfoRow(
              icon: Icons.school,
              label: 'Department',
              value: studentData.department,
            ),
            const SizedBox(height: 16),
            _InfoRow(
              icon: Icons.flag,
              label: 'Country',
              value: studentData.country,
            ),
            if (onEdit != null || onRetry != null || onConfirm != null) ...[
              const SizedBox(height: 24),
              Row(
                children: [
                  if (onRetry != null)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onRetry,
                        icon: const Icon(Icons.qr_code_scanner),
                        label: const Text('Retry'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  if (onRetry != null && onConfirm != null)
                    const SizedBox(width: 12),
                  if (onConfirm != null)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onConfirm,
                        icon: const Icon(Icons.check),
                        label: const Text('Confirm'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}