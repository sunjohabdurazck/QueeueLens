import 'package:flutter/material.dart';
import '../constants/colors.dart';

class PasswordStrengthIndicator extends StatelessWidget {
  final String password;

  const PasswordStrengthIndicator({super.key, required this.password});

  int _calculateStrength() {
    int strength = 0;
    if (password.length >= 8) strength++;
    if (RegExp(r'[a-z]').hasMatch(password) &&
        RegExp(r'[A-Z]').hasMatch(password))
      strength++;
    if (RegExp(r'\d').hasMatch(password)) strength++;
    if (RegExp(r'[^a-zA-Z\d]').hasMatch(password)) strength++;
    return strength;
  }

  Color _getStrengthColor(int strength) {
    if (strength == 0) return IUTColors.border;
    if (strength == 1) return IUTColors.error;
    if (strength == 2) return IUTColors.warning;
    if (strength == 3) return const Color(0xFF3B82F6);
    return IUTColors.success;
  }

  String _getStrengthText(int strength) {
    if (strength == 0) return 'No password';
    if (strength == 1) return 'Weak';
    if (strength == 2) return 'Fair';
    if (strength == 3) return 'Good';
    return 'Strong';
  }

  @override
  Widget build(BuildContext context) {
    final strength = _calculateStrength();
    final color = _getStrengthColor(strength);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Row(
          children: List.generate(4, (index) {
            return Expanded(
              child: Container(
                height: 6,
                margin: EdgeInsets.only(right: index < 3 ? 4 : 0),
                decoration: BoxDecoration(
                  color: index < strength ? color : IUTColors.border,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 4),
        Text(
          'Strength: ${_getStrengthText(strength)}',
          style: TextStyle(
            fontSize: 12,
            color: IUTColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
