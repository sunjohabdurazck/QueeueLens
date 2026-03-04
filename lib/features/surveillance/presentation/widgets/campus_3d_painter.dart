import 'dart:math';
import 'package:flutter/material.dart';
import '../../../services/domain/entities/service_point.dart';
import '../../../surveillance/domain/entities/surveillance_camera.dart';

class Campus3DPainter extends CustomPainter {
  final List<ServicePoint> services;
  final List<SurveillanceCamera> cameras;
  final double yaw;
  final double pitch;
  final String? hoveredBuildingId;

  Campus3DPainter({
    required this.services,
    required this.cameras,
    required this.yaw,
    required this.pitch,
    this.hoveredBuildingId,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // Draw sky gradient
    _drawSky(canvas, size);

    // Draw stars
    _drawStars(canvas, size);

    // Draw ground grid
    _drawGround(canvas, size, centerX, centerY);

    // Draw services as buildings with camera indicators
    _drawBuildings(canvas, size, centerX, centerY);
  }

  void _drawSky(Canvas canvas, Size size) {
    final skyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF0d1b2a),
          const Color(0xFF1b263b),
          const Color(0xFF415a77),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), skyPaint);
  }

  void _drawStars(Canvas canvas, Size size) {
    final starPaint = Paint()..color = Colors.white.withOpacity(0.7);
    final random = Random(42);
    for (int i = 0; i < 150; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height * 0.6;
      final radius = random.nextDouble() * 2 + 0.5;
      canvas.drawCircle(Offset(x, y), radius, starPaint);
    }
  }

  void _drawGround(Canvas canvas, Size size, double centerX, double centerY) {
    final gridPaint = Paint()
      ..color = Colors.cyan.withOpacity(0.2)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Draw grid lines
    for (int i = -10; i <= 10; i++) {
      final offset = i * 30.0 - (pitch * 50);

      // Horizontal lines
      canvas.drawLine(
        Offset(0, centerY + offset),
        Offset(size.width, centerY + offset),
        gridPaint,
      );

      // Vertical lines with perspective
      canvas.drawLine(
        Offset(centerX + i * 40, centerY + offset - 100),
        Offset(centerX + i * 40, centerY + offset + 200),
        gridPaint,
      );
    }
  }

  void _drawBuildings(Canvas canvas, Size size, double centerX, double centerY) {
    for (int i = 0; i < services.length; i++) {
      final service = services[i];
      final serviceCameras = cameras.where((c) => c.serviceId == service.id).toList();
      
      final angle = (i / services.length) * 2 * pi;
      final radius = 200.0;

      final x = cos(angle - yaw) * radius;
      final z = sin(angle - yaw) * radius;

      // Simple perspective projection
      final scale = 300 / (300 + z);
      final screenX = centerX + x * scale;
      final screenY = centerY - (pitch * 100) - 50 * scale;

      if (z > -300) {
        _drawBuilding(
          canvas,
          screenX,
          screenY,
          scale,
          service.name,
          service.isOpen,
          service.pendingCount + service.activeCount,
          serviceCameras,
          hoveredBuildingId == service.id,
        );
      }
    }
  }

  void _drawBuilding(
    Canvas canvas,
    double x,
    double y,
    double scale,
    String name,
    bool isOpen,
    int queueCount,
    List<SurveillanceCamera> cameras,
    bool isHovered,
  ) {
    final buildingHeight = 70.0 * scale;
    final buildingWidth = 45.0 * scale;

    // Building shadow
    final shadowPaint = Paint()..color = Colors.black.withOpacity(0.4);
    canvas.drawRect(
      Rect.fromLTWH(
        x - buildingWidth / 2 + 4,
        y + 4,
        buildingWidth,
        buildingHeight,
      ),
      shadowPaint,
    );

    // Building body with hover effect
    final buildingColor = isHovered
        ? Colors.orange.shade600
        : (isOpen ? Colors.blue.shade700 : Colors.grey.shade700);
    
    final buildingPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          buildingColor,
          buildingColor.withOpacity(0.7),
        ],
      ).createShader(
        Rect.fromLTWH(x - buildingWidth / 2, y, buildingWidth, buildingHeight),
      );
    
    canvas.drawRect(
      Rect.fromLTWH(x - buildingWidth / 2, y, buildingWidth, buildingHeight),
      buildingPaint,
    );

    // Building outline with glow if hovered
    final outlinePaint = Paint()
      ..color = isHovered ? Colors.orange : Colors.white.withOpacity(0.6)
      ..strokeWidth = isHovered ? 2.5 : 1.5
      ..style = PaintingStyle.stroke;
    
    if (isHovered) {
      outlinePaint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    }
    
    canvas.drawRect(
      Rect.fromLTWH(x - buildingWidth / 2, y, buildingWidth, buildingHeight),
      outlinePaint,
    );

    // Windows
    _drawWindows(canvas, x, y, buildingWidth, buildingHeight, scale, isOpen);

    // Camera indicators
    if (cameras.isNotEmpty) {
      _drawCameraIndicators(canvas, x, y, scale, cameras);
    }

    // Service name label
    _drawLabel(canvas, x, y + buildingHeight, name, scale, isHovered);

    // Queue indicator
    if (queueCount > 0) {
      _drawQueueIndicator(canvas, x, y + buildingHeight, scale, queueCount);
    }
  }

  void _drawWindows(
    Canvas canvas,
    double x,
    double y,
    double buildingWidth,
    double buildingHeight,
    double scale,
    bool isOpen,
  ) {
    final windowPaint = Paint()
      ..color = isOpen
          ? Colors.yellow.withOpacity(0.9)
          : Colors.grey.withOpacity(0.4);
    
    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < 2; j++) {
        canvas.drawRect(
          Rect.fromLTWH(
            x - buildingWidth / 2 + 10 + j * 16 * scale,
            y + 12 + i * 18 * scale,
            10 * scale,
            10 * scale,
          ),
          windowPaint,
        );
      }
    }
  }

  void _drawCameraIndicators(
    Canvas canvas,
    double buildingX,
    double buildingY,
    double scale,
    List<SurveillanceCamera> cameras,
  ) {
    // Count active cameras
    final activeCameras = cameras.where((c) => c.isActive).length;
    final totalCameras = cameras.length;

    // Draw camera icon on roof
    final cameraPaint = Paint()
      ..color = activeCameras > 0 ? Colors.green : Colors.grey;
    
    // Camera body
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          buildingX - 8 * scale,
          buildingY - 10 * scale,
          16 * scale,
          10 * scale,
        ),
        Radius.circular(2 * scale),
      ),
      cameraPaint,
    );

    // Camera lens
    final lensPaint = Paint()..color = Colors.black;
    canvas.drawCircle(
      Offset(buildingX, buildingY - 5 * scale),
      3 * scale,
      lensPaint,
    );

    // Active indicator (pulsing dot)
    if (activeCameras > 0) {
      final activePaint = Paint()..color = Colors.red;
      canvas.drawCircle(
        Offset(buildingX + 6 * scale, buildingY - 8 * scale),
        2 * scale,
        activePaint,
      );
    }

    // Camera count badge if multiple cameras
    if (totalCameras > 1) {
      final badgePaint = Paint()
        ..color = activeCameras > 0 ? Colors.green : Colors.grey
        ..style = PaintingStyle.fill;

      final badgeX = buildingX + 12 * scale;
      final badgeY = buildingY - 12 * scale;

      canvas.drawCircle(
        Offset(badgeX, badgeY),
        8 * scale,
        badgePaint,
      );

      final textPainter = TextPainter(
        text: TextSpan(
          text: totalCameras.toString(),
          style: TextStyle(
            color: Colors.white,
            fontSize: 9 * scale,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(badgeX - textPainter.width / 2, badgeY - textPainter.height / 2),
      );
    }

    // Draw small camera positions around building
    for (int i = 0; i < min(cameras.length, 3); i++) {
      if (cameras[i].isActive) {
        final offsetX = buildingX - 20 * scale + (i * 20) * scale;
        final offsetY = buildingY + 5 * scale;

        final smallCamPaint = Paint()
          ..color = Colors.blue.withOpacity(0.7)
          ..style = PaintingStyle.fill;

        canvas.drawCircle(
          Offset(offsetX, offsetY),
          5 * scale,
          smallCamPaint,
        );

        // Viewing cone
        final conePaint = Paint()
          ..color = Colors.blue.withOpacity(0.3)
          ..style = PaintingStyle.fill;

        final path = Path()
          ..moveTo(offsetX, offsetY)
          ..lineTo(offsetX - 8 * scale, offsetY + 15 * scale)
          ..lineTo(offsetX + 8 * scale, offsetY + 15 * scale)
          ..close();

        canvas.drawPath(path, conePaint);
      }
    }
  }

  void _drawLabel(
    Canvas canvas,
    double x,
    double y,
    String name,
    double scale,
    bool isHovered,
  ) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: name,
        style: TextStyle(
          color: isHovered ? Colors.orange : Colors.white,
          fontSize: 11 * scale,
          fontWeight: FontWeight.bold,
          shadows: isHovered
              ? [
                  Shadow(
                    color: Colors.orange.withOpacity(0.8),
                    blurRadius: 8,
                  ),
                ]
              : [
                  Shadow(
                    color: Colors.black.withOpacity(0.9),
                    blurRadius: 5,
                  ),
                ],
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(x - textPainter.width / 2, y + 8),
    );
  }

  void _drawQueueIndicator(
    Canvas canvas,
    double x,
    double y,
    double scale,
    int queueCount,
  ) {
    final dotPaint = Paint()..color = Colors.orange;
    final displayCount = min(queueCount, 10);
    
    for (int i = 0; i < displayCount; i++) {
      canvas.drawCircle(
        Offset(
          x - 18 * scale + (i % 5) * 7 * scale,
          y + 25 + (i ~/ 5) * 7 * scale,
        ),
        3 * scale,
        dotPaint,
      );
    }

    // Show "+ more" if queue count exceeds 10
    if (queueCount > 10) {
      final morePainter = TextPainter(
        text: TextSpan(
          text: '+${queueCount - 10}',
          style: TextStyle(
            color: Colors.orange,
            fontSize: 9 * scale,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      morePainter.layout();
      morePainter.paint(
        canvas,
        Offset(x + 10 * scale, y + 27),
      );
    }
  }

  @override
  bool shouldRepaint(Campus3DPainter oldDelegate) {
    return oldDelegate.yaw != yaw ||
        oldDelegate.pitch != pitch ||
        oldDelegate.services.length != services.length ||
        oldDelegate.cameras.length != cameras.length ||
        oldDelegate.hoveredBuildingId != hoveredBuildingId;
  }
}
