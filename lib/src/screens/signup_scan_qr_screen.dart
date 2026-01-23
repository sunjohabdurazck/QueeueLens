// signup_scan_qr_screen.dart
import 'package:flutter/material.dart';
import '../constants/colors.dart';
// Import the real QR scanner
import '../features/shared/qr_scanner/presentation/widgets/qr_scanner_screen.dart';
import 'signup_form_screen.dart';

class SignupScanQrScreen extends StatelessWidget {
  const SignupScanQrScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Back to Login'),
                      style: TextButton.styleFrom(
                        foregroundColor: IUTColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Scan Student ID',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: IUTColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Scan the QR code on your student ID card',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: IUTColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 40),
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: IUTColors.cardBg,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 40,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 280,
                          height: 280,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: IUTColors.primary,
                              width: 4,
                              strokeAlign: BorderSide.strokeAlignInside,
                            ),
                          ),
                          child: const Icon(
                            Icons.qr_code_scanner,
                            size: 128,
                            color: IUTColors.primary,
                          ),
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              // Open REAL QR scanner instead of mock
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => QRScannerScreen(
                                    onQRScanned: (qrData) {
                                      // Navigate to signup form with scanned data
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              SignupFormScreen(
                                            scannedStudent: {
                                              'name': qrData.name,
                                              'studentId': qrData.studentID,
                                              'studentID': qrData.studentID,
                                              'department': qrData.department,
                                              'batch':
                                                  _extractBatchFromStudentID(
                                                      qrData.studentID),
                                              'country': qrData.country,
                                            },
                                          ),
                                        ),
                                      );
                                    },
                                    onCancel: () {
                                      Navigator.pop(context);
                                    },
                                    timeout: const Duration(seconds: 60),
                                  ),
                                ),
                              );
                            },
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
                              'Start Scanning',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Make sure the QR code is clearly visible',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: IUTColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Helper to extract batch from student ID (first 2 digits)
  String _extractBatchFromStudentID(String studentID) {
    if (studentID.length >= 2) {
      return '20${studentID.substring(0, 2)}'; // Assuming format like 190041123 → 2019
    }
    return 'Unknown';
  }
}
