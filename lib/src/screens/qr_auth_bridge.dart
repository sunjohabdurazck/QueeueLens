// lib/src/screens/qr_auth_bridge.dart
import 'package:flutter/material.dart';
import 'signup_form_screen.dart';

import '../features/shared/qr_scanner/presentation/widgets/qr_scanner_screen.dart';

// OR Option B - If you moved QR scanner to a different location:
// import '../widgets/qr_scanner/qr_scanner_screen.dart';
// import '../widgets/qr_scanner/domain/entities/qr_data.dart';

class QRAuthBridge extends StatelessWidget {
  const QRAuthBridge({super.key});

  @override
  Widget build(BuildContext context) {
    return QRScannerScreen(
      onQRScanned: (qrData) {
        // Convert QRData to the Map format expected by SignupFormScreen
        final studentData = {
          'name': qrData.name,
          'studentId': qrData.studentID,
          'department': qrData.department,
          'batch': _extractBatchFromStudentID(qrData.studentID),
          'country': qrData.country,
        };

        // Navigate directly to signup form
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => SignupFormScreen(
              scannedStudent: studentData,
            ),
          ),
        );
      },
      onCancel: () {
        // Go back to login/signup selection
        Navigator.pop(context);
      },
      timeout: const Duration(seconds: 60),
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
