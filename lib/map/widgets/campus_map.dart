// lib/map/widgets/campus_map.dart

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/place_model.dart';
import '../map_constants.dart';
import 'place_marker.dart';
import '../services/directions_service.dart';

class CampusMap extends StatelessWidget {
  final MapController mapController;
  final List<PlaceModel> places;
  final LatLng? userLocation;
  final Function(PlaceModel) onMarkerTap;
  final RouteResult? currentRoute;
  final Function()? onClearRoute;

  const CampusMap({
    super.key,
    required this.mapController,
    required this.places,
    this.userLocation,
    required this.onMarkerTap,
    this.currentRoute,
    this.onClearRoute,
  });

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCenter: MapConstants.iutCenter,
        initialZoom: MapConstants.defaultZoom,
        minZoom: MapConstants.minZoom,
        maxZoom: MapConstants.maxZoom,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
        onTap: (tapPosition, point) {
          // Clear route when tapping on empty map area
          if (currentRoute != null && onClearRoute != null) {
            onClearRoute!();
          }
        },
      ),
      children: [
        // OpenStreetMap tile layer
        TileLayer(
          urlTemplate: MapConstants.tileUrl,
          userAgentPackageName: MapConstants.userAgent,
          maxZoom: MapConstants.maxZoom,
        ),

        // Campus boundary circle
        CircleLayer(
          circles: [
            CircleMarker(
              point: MapConstants.iutCenter,
              radius: MapConstants.campusRadiusMeters,
              useRadiusInMeter: true,
              color: Colors.blue.withOpacity(0.1),
              borderColor: Colors.blue.withOpacity(0.3),
              borderStrokeWidth: 2,
            ),
          ],
        ),

        // Route polyline (if available)
        if (currentRoute != null && currentRoute!.polyline.isNotEmpty)
          PolylineLayer(
            polylines: [
              Polyline(
                points: currentRoute!.polyline,
                color: Colors.blue.withOpacity(0.8),
                strokeWidth: 4,
                borderColor: Colors.white.withOpacity(0.5),
                borderStrokeWidth: 2,
                // isDotted parameter removed as it's not supported in current version
              ),
            ],
          ),

        // Start marker (user location)
        if (currentRoute != null && userLocation != null)
          MarkerLayer(
            markers: [
              Marker(
                point: userLocation!,
                width: 30,
                height: 30,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.person_pin_circle,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),

        // Destination marker (end of route)
        if (currentRoute != null && currentRoute!.polyline.isNotEmpty)
          MarkerLayer(
            markers: [
              Marker(
                point: currentRoute!.polyline.last,
                width: 40,
                height: 40,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: const Icon(
                    Icons.location_pin,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ],
          ),

        // User location marker (when no route)
        if (userLocation != null && currentRoute == null)
          MarkerLayer(
            markers: [
              Marker(
                point: userLocation!,
                width: 40,
                height: 40,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.my_location,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),

        // Place markers
        MarkerLayer(
          markers: places.map((place) {
            return Marker(
              point: place.location,
              width: 40,
              height: 50,
              child: PlaceMarkerWidget(
                place: place,
                onTap: () => onMarkerTap(place),
                // Check if this place is the destination of the current route
                isDestination:
                    currentRoute != null &&
                    currentRoute!.polyline.isNotEmpty &&
                    place.location == currentRoute!.polyline.last,
              ),
            );
          }).toList(),
        ),

        // Route info overlay (if route exists)
        if (currentRoute != null)
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: RouteInfoCard(route: currentRoute!, onClear: onClearRoute),
          ),
      ],
    );
  }
}

// New widget for displaying route information
class RouteInfoCard extends StatelessWidget {
  final RouteResult route;
  final Function()? onClear;

  const RouteInfoCard({super.key, required this.route, this.onClear});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Walking Route',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: onClear,
                  tooltip: 'Clear route',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.directions_walk, size: 20),
                const SizedBox(width: 8),
                Text(
                  route.formattedDistance,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(width: 16),
                const Icon(Icons.access_time, size: 20),
                const SizedBox(width: 8),
                Text(
                  route.formattedDuration,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
