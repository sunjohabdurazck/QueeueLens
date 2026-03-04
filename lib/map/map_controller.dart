// lib/map/map_controller.dart

import 'dart:async';
import 'package:flutter/material.dart'; // Add this import
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'models/place_model.dart';
import 'services/location_service.dart';
import 'services/map_data_service.dart';
import 'services/directions_service.dart';
import 'models/place_model.dart' hide RouteResult; // or show specific ones
import 'services/directions_service.dart';

class CampusMapController {
  final MapController mapController = MapController();
  final MapDataService _dataService = MapDataService();

  // State
  List<PlaceModel> _places = [];
  LatLng? _userLocation;
  bool _isInsideCampus = false;
  StreamSubscription<Position>? _positionSubscription;
  PlaceModel? _selectedPlaceWithRoute; // Moved up with other fields

  // Getters
  List<PlaceModel> get places => _places;
  LatLng? get userLocation => _userLocation;
  bool get isInsideCampus => _isInsideCampus;

  // Callbacks
  Function(List<PlaceModel>)? onPlacesUpdated;
  Function(LatLng?)? onUserLocationUpdated;
  Function(bool)? onCampusStatusChanged;
  Function(RouteResult?)? onRouteUpdated; // Made nullable

  // Initialize
  Future<void> initialize() async {
    // Load places
    await _loadPlaces();

    // Check location permissions and campus status
    await _updateLocation();

    // Start listening to location updates
    _startLocationUpdates();
  }

  // Load places from Firebase or default
  Future<void> _loadPlaces() async {
    _places = await _dataService.fetchPlaces();
    onPlacesUpdated?.call(_places);
  }

  // Update user location and campus status
  Future<void> _updateLocation() async {
    Position? position = await LocationService.getCurrentLocation();

    if (position != null) {
      _userLocation = LatLng(position.latitude, position.longitude);
      onUserLocationUpdated?.call(_userLocation);

      // Check if inside campus
      bool wasInsideCampus = _isInsideCampus;
      _isInsideCampus = await LocationService.isInsideCampus();

      if (wasInsideCampus != _isInsideCampus) {
        onCampusStatusChanged?.call(_isInsideCampus);
      }
    }
  }

  // Start real-time location updates
  void _startLocationUpdates() {
    _positionSubscription = LocationService.getPositionStream().listen(
      (position) {
        _userLocation = LatLng(position.latitude, position.longitude);
        onUserLocationUpdated?.call(_userLocation);

        // Recalculate campus status
        _checkCampusStatus();
      },
    );
  }

  // Check if user is inside campus
  Future<void> _checkCampusStatus() async {
    bool wasInsideCampus = _isInsideCampus;
    _isInsideCampus = await LocationService.isInsideCampus();

    if (wasInsideCampus != _isInsideCampus) {
      onCampusStatusChanged?.call(_isInsideCampus);
    }
  }

  // Move camera to a specific location
  void moveToLocation(LatLng location, {double zoom = 18.0}) {
    mapController.move(location, zoom);
  }

  // Move camera to user location
  void moveToUserLocation() {
    if (_userLocation != null) {
      moveToLocation(_userLocation!);
    }
  }

  // Search places
  Future<List<PlaceModel>> searchPlaces(String query) async {
    return _dataService.searchPlaces(query);
  }

  // Get route to place
  Future<void> getRouteToPlace(PlaceModel place) async {
    if (_userLocation == null) return;

    try {
      final route = await DirectionsService.getWalkingRoute(
        _userLocation!,
        place.location,
      );

      if (route != null) {
        place.updateRouteFromUser(route);
        _selectedPlaceWithRoute = place;

        // Notify listeners
        onRouteUpdated?.call(route); // Fixed: was _onRouteUpdated

        // Move camera to show entire route
        _focusOnRoute(route.polyline);
      }
    } catch (e) {
      // Use proper logging instead of print
      debugPrint('Error getting route: $e');
    }
  }

  // Helper method to focus on route
  void _focusOnRoute(List<LatLng> routePoints) {
    if (routePoints.isEmpty) return;

    // Calculate bounds of route
    double minLat = routePoints[0].latitude;
    double maxLat = routePoints[0].latitude;
    double minLng = routePoints[0].longitude;
    double maxLng = routePoints[0].longitude;

    for (var point in routePoints) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    // Add padding
    const padding = 0.001;
    final bounds = LatLngBounds(
      LatLng(minLat - padding, minLng - padding),
      LatLng(maxLat + padding, maxLng + padding),
    );

    // Updated for FlutterMap v6
    mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(50), // Now properly defined
      ),
    );
  }

  // Clear route
  void clearRoute() {
    if (_selectedPlaceWithRoute != null) {
      _selectedPlaceWithRoute!.updateRouteFromUser(null);
      _selectedPlaceWithRoute = null;
    }
    onRouteUpdated?.call(null); // Now accepts null
  }

  // Cleanup
  void dispose() {
    _positionSubscription?.cancel();
    mapController.dispose();
  }
}
