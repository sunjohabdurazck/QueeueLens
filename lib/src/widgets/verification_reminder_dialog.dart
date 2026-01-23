import 'package:flutter/material.dart';
import '../constants/colors.dart';

class VerificationReminderDialog extends StatelessWidget {
  final String email;
  final VoidCallback onClose;

  const VerificationReminderDialog({
    super.key,
    required this.email,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFDBEAFE),
                borderRadius: BorderRadius.circular(32),
              ),
              child: const Icon(
                Icons.mail_outline,
                size: 32,
                color: IUTColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Verify Your Email',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: IUTColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 14,
                  color: IUTColors.textSecondary,
                  height: 1.5,
                ),
                children: [
                  const TextSpan(text: "We've sent a verification link to "),
                  TextSpan(
                    text: email,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: IUTColors.textPrimary,
                    ),
                  ),
                  const TextSpan(
                    text:
                        '. Please check your inbox and click the link to activate your account.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onClose,
                style: ElevatedButton.styleFrom(
                  backgroundColor: IUTColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Got It!',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
