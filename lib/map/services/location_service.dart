// lib/map/services/location_service.dart

import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../map_constants.dart';

class LocationService {
  // Check and request location permissions
  static Future<bool> checkPermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  // Get current user location
  static Future<Position?> getCurrentLocation() async {
    try {
      bool hasPermission = await checkPermissions();
      if (!hasPermission) return null;

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      return null;
    }
  }

  // Check if user is inside campus
  static Future<bool> isInsideCampus() async {
    Position? position = await getCurrentLocation();
    if (position == null) return false;

    double distance = calculateDistance(
      position.latitude,
      position.longitude,
      MapConstants.iutCenter.latitude,
      MapConstants.iutCenter.longitude,
    );

    return distance <= MapConstants.campusRadiusMeters;
  }

  // Calculate distance between two coordinates (in meters)
  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  // Get distance from a specific location
  static Future<double?> getDistanceFromLocation(LatLng target) async {
    Position? position = await getCurrentLocation();
    if (position == null) return null;

    return calculateDistance(
      position.latitude,
      position.longitude,
      target.latitude,
      target.longitude,
    );
  }

  // Stream of position updates
  static Stream<Position> getPositionStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
      ),
    );
  }
}
