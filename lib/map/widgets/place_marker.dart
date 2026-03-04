// lib/map/widgets/place_marker.dart

import 'package:flutter/material.dart';
import '../models/place_model.dart';
import '../map_constants.dart';

class PlaceMarkerWidget extends StatelessWidget {
  final PlaceModel place;
  final VoidCallback? onTap;
  final bool isDestination;

  const PlaceMarkerWidget({
    super.key,
    required this.place,
    required this.onTap,
    this.isDestination = false,
  });

  IconData _getIconForCategory(PlaceCategory category) {
    switch (category) {
      case PlaceCategory.classroom:
      case PlaceCategory.sports:
        return Icons.school;
      case PlaceCategory.administration:
        return Icons.business;
      case PlaceCategory.library:
        return Icons.local_library;
      case PlaceCategory.cafeteria:
        return Icons.restaurant;
      default:
        return Icons.location_on;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Marker pin
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Color(place.markerColor),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              _getIconForCategory(place.category), // ✅ category instead of type
              color: Colors.white,
              size: 20,
            ),
          ),
          // Pointer triangle
          CustomPaint(
            size: const Size(10, 8),
            painter: _TrianglePainter(color: Color(place.markerColor)),
          ),
        ],
      ),
    );
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;

  _TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width / 2, size.height)
      ..lineTo(0, 0)
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Bottom sheet to show place details
class PlaceDetailsSheet extends StatelessWidget {
  final PlaceModel place;

  const PlaceDetailsSheet({super.key, required this.place});

  IconData _getIconForCategory(PlaceCategory category) {
    switch (category) {
      case PlaceCategory.classroom:
      case PlaceCategory.sports:
        return Icons.school;
      case PlaceCategory.administration:
        return Icons.business;
      case PlaceCategory.library:
        return Icons.local_library;
      case PlaceCategory.cafeteria:
        return Icons.restaurant;
      default:
        return Icons.location_on;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Place name
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Color(place.markerColor).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getIconForCategory(
                      place.category), // ✅ category instead of type
                  color: Color(place.markerColor),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      place.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (place.buildingCode != null)
                      Text(
                        place.buildingCode!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (place.description != null) ...[
            const SizedBox(height: 16),
            Text(
              place.description!,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ],
          const SizedBox(height: 16),
          // Location coordinates
          Row(
            children: [
              Icon(Icons.place, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                '${place.location.latitude.toStringAsFixed(6)}, ${place.location.longitude.toStringAsFixed(6)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
