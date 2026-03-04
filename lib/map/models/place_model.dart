// lib/map/models/place_model.dart

import 'package:latlong2/latlong.dart';
import '../services/directions_service.dart';

// IMPORTANT: RouteResult should be imported from wherever you defined it
// e.g.:
// import 'package:your_app/map/services/directions_service.dart';

enum PlaceCategory {
  classroom,
  administration,
  library,
  cafeteria,
  sports,
  other
}

// Keep existing PlaceType enum if you still need it
enum PlaceType {
  academic,
  administrative,
  medical,
  dining,
  library,
  entrance,
  other
}

class PlaceModel {
  final String id;
  final String name;
  final LatLng location;

  final PlaceType type; // Keep for backward compatibility
  final PlaceCategory category; // New field

  final String? description;
  final String? buildingCode;

  RouteResult? routeFromUser;

  PlaceModel({
    required this.id,
    required this.name,
    required this.location,
    required this.type,
    required this.category,
    this.description,
    this.buildingCode,
  });

  /// Constructor that accepts only category and infers type
  factory PlaceModel.fromCategory({
    required String id,
    required String name,
    required LatLng location,
    required PlaceCategory category,
    String? description,
    String? buildingCode,
  }) {
    final type = _categoryToType(category);
    return PlaceModel(
      id: id,
      name: name,
      location: location,
      type: type,
      category: category,
      description: description,
      buildingCode: buildingCode,
    );
  }

  void updateRouteFromUser(RouteResult? route) {
    routeFromUser = route;
  }

  String? get distanceToUser => routeFromUser?.formattedDistance;
  String? get durationToUser => routeFromUser?.formattedDuration;

  /// Convert from Firestore document
  factory PlaceModel.fromMap(Map<String, dynamic> map, String id) {
    // Prefer new "category", fallback to legacy keys
    final rawCategory = (map['category'] ?? map['type'])?.toString();

    final category = PlaceCategory.values.firstWhere(
      (e) => e.name == rawCategory,
      orElse: () => PlaceCategory.other,
    );

    // Keep "type" for old data; if missing/unmatched, infer from category
    final rawType = map['type']?.toString();
    final type = PlaceType.values.firstWhere(
      (e) => e.name == rawType,
      orElse: () => _categoryToType(category),
    );

    return PlaceModel(
      id: id,
      name: map['name'] ?? '',
      location: LatLng(
        (map['latitude'] ?? 0.0).toDouble(),
        (map['longitude'] ?? 0.0).toDouble(),
      ),
      type: type,
      category: category,
      description: map['description'],
      buildingCode: map['buildingCode'],
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'latitude': location.latitude,
      'longitude': location.longitude,
      'category': category.name, // new canonical field
      'type': type.name, // keep for compatibility if you still use it elsewhere
      'description': description,
      'buildingCode': buildingCode,
    };
  }

  /// Get color based on category
  int get markerColor {
    switch (category) {
      case PlaceCategory.classroom:
        return 0xFF2196F3; // Blue
      case PlaceCategory.administration:
        return 0xFFF44336; // Red
      case PlaceCategory.library:
        return 0xFF9C27B0; // Purple
      case PlaceCategory.cafeteria:
        return 0xFFFF9800; // Orange
      case PlaceCategory.sports:
        return 0xFF4CAF50; // Green
      default:
        return 0xFF757575; // Grey
    }
  }

  /// Helper method to convert category to type
  static PlaceType _categoryToType(PlaceCategory category) {
    switch (category) {
      case PlaceCategory.classroom:
      case PlaceCategory.sports:
        return PlaceType.academic;
      case PlaceCategory.administration:
        return PlaceType.administrative;
      case PlaceCategory.library:
        return PlaceType.library;
      case PlaceCategory.cafeteria:
        return PlaceType.dining;
      default:
        return PlaceType.other;
    }
  }
}
