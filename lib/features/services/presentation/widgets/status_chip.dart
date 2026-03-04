// ============================================================================
// 5. UI COMPONENTS - Reusable Widgets
// ============================================================================

// lib/features/services/presentation/widgets/status_chip.dart
import 'package:flutter/material.dart';
import '../../domain/entities/service_point.dart';
import '../../../../core/constants/app_strings.dart';

class StatusChip extends StatelessWidget {
  final ServiceStatus status;
  final bool compact;

  const StatusChip({super.key, required this.status, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final isOpen = status == ServiceStatus.open;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: isOpen ? Colors.green.shade50 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOpen ? Colors.green.shade200 : Colors.grey.shade300,
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: compact ? 6 : 8,
            height: compact ? 6 : 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isOpen ? Colors.green : Colors.grey.shade600,
            ),
          ),
          SizedBox(width: compact ? 4 : 6),
          Text(
            isOpen ? AppStrings.open : AppStrings.closed,
            style: TextStyle(
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.w600,
              color: isOpen ? Colors.green.shade700 : Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}
