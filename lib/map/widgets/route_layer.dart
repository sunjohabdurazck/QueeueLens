// lib/map/widgets/route_layer.dart

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class RouteLayer extends StatelessWidget {
  final List<LatLng> routePoints;
  final Color routeColor;
  final double routeWidth;

  const RouteLayer({
    super.key,
    required this.routePoints,
    this.routeColor = Colors.blue,
    this.routeWidth = 4.0,
  });

  @override
  Widget build(BuildContext context) {
    if (routePoints.length < 2) return const SizedBox.shrink();

    return PolylineLayer(
      polylines: [
        Polyline(
          points: routePoints,
          color: routeColor,
          strokeWidth: routeWidth,
        ),
      ],
    );
  }
}

// Start and end markers
class RouteMarkers extends StatelessWidget {
  final LatLng startPoint;
  final LatLng endPoint;
  final String? startLabel;
  final String? endLabel;

  const RouteMarkers({
    super.key,
    required this.startPoint,
    required this.endPoint,
    this.startLabel,
    this.endLabel,
  });

  @override
  Widget build(BuildContext context) {
    return MarkerLayer(
      markers: [
        // Start marker (user location)
        Marker(
          point: startPoint,
          width: 40,
          height: 40,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
            ),
            child: const Icon(
              Icons.person_pin_circle,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
        // End marker (destination)
        Marker(
          point: endPoint,
          width: 50,
          height: 50,
          child: Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: const Icon(
                  Icons.location_pin,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              if (endLabel != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Text(
                    endLabel!,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
