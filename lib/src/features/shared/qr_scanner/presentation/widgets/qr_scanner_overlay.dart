import 'package:flutter/material.dart';

class QRScannerOverlay extends StatelessWidget {
  final double scanAreaSize;
  final String instructionText;

  const QRScannerOverlay({
    super.key,
    this.scanAreaSize = 280,
    this.instructionText = 'Position QR code within the frame',
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Dark overlay with transparent center
        CustomPaint(
          size: Size.infinite,
          painter: _ScannerOverlayPainter(scanAreaSize: scanAreaSize),
        ),
        // Instruction text
        Positioned(
          left: 0,
          right: 0,
          bottom: 120,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: const Color.fromRGBO(0, 0, 0, 0.7), // Fixed deprecated withOpacity
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                instructionText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ScannerOverlayPainter extends CustomPainter {
  final double scanAreaSize;

  _ScannerOverlayPainter({required this.scanAreaSize});

  @override
  void paint(Canvas canvas, Size size) {
    final overlayColor = const Color.fromRGBO(0, 0, 0, 0.6); // Fixed deprecated withOpacity
    
    final paint = Paint()
      ..color = overlayColor
      ..style = PaintingStyle.fill;

    final scanAreaRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: scanAreaSize,
      height: scanAreaSize,
    );

    // Draw dark overlay with hole
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(scanAreaRect, const Radius.circular(16)))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);

    // Draw corner brackets
    final cornerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    const cornerLength = 24.0;
    final corners = [
      // Top-left
      [
        Offset(scanAreaRect.left, scanAreaRect.top + cornerLength),
        Offset(scanAreaRect.left, scanAreaRect.top),
        Offset(scanAreaRect.left + cornerLength, scanAreaRect.top),
      ],
      // Top-right
      [
        Offset(scanAreaRect.right - cornerLength, scanAreaRect.top),
        Offset(scanAreaRect.right, scanAreaRect.top),
        Offset(scanAreaRect.right, scanAreaRect.top + cornerLength),
      ],
      // Bottom-right
      [
        Offset(scanAreaRect.right, scanAreaRect.bottom - cornerLength),
        Offset(scanAreaRect.right, scanAreaRect.bottom),
        Offset(scanAreaRect.right - cornerLength, scanAreaRect.bottom),
      ],
      // Bottom-left
      [
        Offset(scanAreaRect.left + cornerLength, scanAreaRect.bottom),
        Offset(scanAreaRect.left, scanAreaRect.bottom),
        Offset(scanAreaRect.left, scanAreaRect.bottom - cornerLength),
      ],
    ];

    for (final corner in corners) {
      final path = Path()
        ..moveTo(corner[0].dx, corner[0].dy)
        ..lineTo(corner[1].dx, corner[1].dy)
        ..lineTo(corner[2].dx, corner[2].dy);
      canvas.drawPath(path, cornerPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ScannerOverlayPainter oldDelegate) {
    return oldDelegate.scanAreaSize != scanAreaSize;
  }
}