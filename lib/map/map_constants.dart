// lib/map/map_constants.dart

import 'package:latlong2/latlong.dart';

class MapConstants {
  // IUT Campus Center (approximate center of campus)
  static const LatLng iutCenter = LatLng(23.9485, 90.3790);

  // Campus boundary radius in meters (adjust based on actual campus size)
  // Approximately 500 meters covers most of IUT campus
  static const double campusRadiusMeters = 500.0;

  // Map zoom levels
  static const double defaultZoom = 16.5;
  static const double minZoom = 15.0;
  static const double maxZoom = 19.0;

  // OpenStreetMap tile URL (completely free)
  static const String tileUrl =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  // User agent for OpenStreetMap (required by OSM policy)
  static const String userAgent = 'QueueLens IUT Campus Map';

  // Location update settings
  static const int locationUpdateIntervalMs = 5000; // 5 seconds

  // Custom LatLngBounds class since it might not exist in latlong2
  static final LatLngBounds campusBounds = LatLngBounds(
    const LatLng(23.9460, 90.3760), // Southwest corner
    const LatLng(23.9510, 90.3820), // Northeast corner
  );
}

// Custom LatLngBounds class
class LatLngBounds {
  final LatLng southwest;
  final LatLng northeast;

  const LatLngBounds(this.southwest, this.northeast);

  // Check if a point is within bounds
  bool contains(LatLng point) {
    return point.latitude >= southwest.latitude &&
        point.latitude <= northeast.latitude &&
        point.longitude >= southwest.longitude &&
        point.longitude <= northeast.longitude;
  }

  // Get center point of bounds
  LatLng get center {
    return LatLng(
      (southwest.latitude + northeast.latitude) / 2,
      (southwest.longitude + northeast.longitude) / 2,
    );
  }

  // Get bounds for flutter_map if needed
  Map<String, dynamic> toMapBounds() {
    return {
      'southWest': [southwest.latitude, southwest.longitude],
      'northEast': [northeast.latitude, northeast.longitude],
    };
  }
}

// Place types for different campus locations
enum PlaceType {
  academic,
  administrative,
  medical,
  dining,
  library,
  entrance,
  other,
}

// Color coding for different place types
class PlaceColors {
  static const Map<PlaceType, int> colors = {
    PlaceType.academic: 0xFF2196F3, // Blue
    PlaceType.administrative: 0xFF9C27B0, // Purple
    PlaceType.medical: 0xFFE91E63, // Pink/Red
    PlaceType.dining: 0xFFFF9800, // Orange
    PlaceType.library: 0xFF4CAF50, // Green
    PlaceType.entrance: 0xFF607D8B, // Blue Grey
    PlaceType.other: 0xFF757575, // Grey
  };
}
