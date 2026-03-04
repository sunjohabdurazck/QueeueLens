// lib/map/services/map_data_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';
import '../models/place_model.dart';
import '../map_constants.dart';

class MapDataService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'campus_places';

  // Fetch all places from Firebase
  Future<List<PlaceModel>> fetchPlaces() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection(_collection).get();
      return snapshot.docs
          .map((doc) => PlaceModel.fromMap(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ))
          .toList();
    } catch (e) {
      // If Firebase fails, return default places
      return getDefaultPlaces();
    }
  }

  // Stream of places (real-time updates)
  Stream<List<PlaceModel>> getPlacesStream() {
    return _firestore.collection(_collection).snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => PlaceModel.fromMap(
                    doc.data() as Map<String, dynamic>,
                    doc.id,
                  ))
              .toList(),
        );
  }

  // Search places by name
  Future<List<PlaceModel>> searchPlaces(String query) async {
    try {
      List<PlaceModel> allPlaces = await fetchPlaces();
      return allPlaces
          .where(
              (place) => place.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // Add a new place (admin only)
  Future<void> addPlace(PlaceModel place) async {
    await _firestore.collection(_collection).add(place.toMap());
  }

  // Default places (fallback if Firebase is not set up)
  static List<PlaceModel> getDefaultPlaces() {
    return [
      PlaceModel.fromCategory(
        id: '1',
        name: 'Second Academic Building',
        location: const LatLng(23.94917074398174, 90.37953894638973),
        category: PlaceCategory.classroom,
        buildingCode: 'SAB',
        description: 'Main academic building for CSE, EEE departments',
      ),
      PlaceModel.fromCategory(
        id: '2',
        name: 'Third Academic Building',
        location: const LatLng(23.949160938834662, 90.37733953505189),
        category: PlaceCategory.classroom,
        buildingCode: 'TAB',
        description: 'Academic building for MCE, CEE departments',
      ),
      PlaceModel.fromCategory(
        id: '3',
        name: 'Main Gate',
        location: const LatLng(23.947396000220557, 90.38080494901348),
        category: PlaceCategory.administration,
        description: 'Main entrance to IUT campus',
      ),
      PlaceModel.fromCategory(
        id: '4',
        name: 'Medical Center',
        location: const LatLng(23.948847342350103, 90.37738137384427),
        category: PlaceCategory.other, // or create a medical category
        description: 'Campus health center',
      ),
      PlaceModel.fromCategory(
        id: '5',
        name: 'Cafeteria',
        location: const LatLng(23.948039068381526, 90.3796841866017),
        category: PlaceCategory.cafeteria,
        description: 'Student dining hall',
      ),
      PlaceModel.fromCategory(
        id: '6',
        name: 'Library',
        location: const LatLng(23.94814651513253, 90.37968899664604),
        category: PlaceCategory.library,
        description: 'Central library and study area',
      ),
      PlaceModel.fromCategory(
        id: '7',
        name: 'Administrative Building',
        location: const LatLng(23.94864834931579, 90.3789821346105),
        category: PlaceCategory.administration,
        description: 'Main administration office',
      ),
      PlaceModel.fromCategory(
        id: '8',
        name: 'Admin Building',
        location: const LatLng(23.94806072165071, 90.37928129865955),
        category: PlaceCategory.administration,
        description: 'Registrar and student services',
      ),
    ];
  }
}
