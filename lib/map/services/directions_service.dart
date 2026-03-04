// lib/map/services/directions_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class DirectionsService {
  // **Option 1: OSRM (Open Source Routing Machine) - 100% FREE**
  static const String osrmBaseUrl = 'https://router.project-osrm.org/route/v1';

  // **Option 2: OpenRouteService - FREE with API key (no billing required)**
  static const String openRouteBaseUrl =
      'https://api.openrouteservice.org/v2/directions';
  static const String openRouteApiKey =
      'eyJvcmciOiI1YjNjZTM1OTc4NTExMTAwMDFjZjYyNDgiLCJpZCI6ImUyOTNjMjQxMzA2YTQ2N2U4NjkyNTAyMzQ0OTZiOWZmIiwiaCI6Im11cm11cjY0In0='; // Get free key at openrouteservice.org

  // **Option 3: GraphHopper - FREE tier (up to 500 requests/day)**
  static const String graphHopperBaseUrl =
      'https://graphhopper.com/api/1/route';
  static const String graphHopperApiKey =
      'YOUR_FREE_GRAPHHOPPER_KEY'; // Get free key at graphhopper.com

  // **Main method: Try multiple free services in order**
  static Future<RouteResult?> getFreeRoute(
    LatLng origin,
    LatLng destination,
    String profile, // 'foot-walking', 'driving-car', 'cycling-regular'
  ) async {
    // Try OpenRouteService first (most reliable)
    final result = await getOpenRouteServiceRoute(origin, destination, profile);
    if (result != null) return result;

    // Fallback to OSRM
    return await getOSRMRoute(origin, destination, profile);
  }

  // **1. OSRM (No API key needed)**
  static Future<RouteResult?> getOSRMRoute(
    LatLng origin,
    LatLng destination,
    String profile, // 'driving', 'walking', 'cycling'
  ) async {
    try {
      // Map profile names from standard to OSRM format
      final osrmProfile = _mapProfileToOSRM(profile);

      final url = Uri.parse(
        '$osrmBaseUrl/$osrmProfile/'
        '${origin.longitude},${origin.latitude};'
        '${destination.longitude},${destination.latitude}'
        '?overview=full&geometries=geojson&steps=true',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _parseOSRMResponse(data);
      }
    } catch (e) {
      print('OSRM route error: $e');
    }
    return null;
  }

  // **2. OpenRouteService (FREE with key, no billing)**
  static Future<RouteResult?> getOpenRouteServiceRoute(
    LatLng origin,
    LatLng destination,
    String profile, // 'foot-walking', 'driving-car', 'cycling-regular'
  ) async {
    try {
      final url = Uri.parse('$openRouteBaseUrl/$profile/geojson');

      final response = await http.post(
        url,
        headers: {
          'Authorization': openRouteApiKey,
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'coordinates': [
            [origin.longitude, origin.latitude],
            [destination.longitude, destination.latitude]
          ],
          'instructions': true,
          'geometry': true,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _parseOpenRouteResponse(data);
      } else {
        print('OpenRouteService error: ${response.statusCode}');
      }
    } catch (e) {
      print('OpenRouteService error: $e');
    }
    return null;
  }

  // **3. GraphHopper (Free tier: 500 requests/day)**
  static Future<RouteResult?> getGraphHopperRoute(
    LatLng origin,
    LatLng destination,
    String profile, // 'foot', 'car', 'bike'
  ) async {
    try {
      final url = Uri.parse(
        '$graphHopperBaseUrl?'
        'point=${origin.latitude},${origin.longitude}&'
        'point=${destination.latitude},${destination.longitude}&'
        'vehicle=$profile&'
        'instructions=true&'
        'key=$graphHopperApiKey&'
        'type=json&'
        'points_encoded=false',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _parseGraphHopperResponse(data);
      }
    } catch (e) {
      print('GraphHopper error: $e');
    }
    return null;
  }

  // **Parse OpenRouteService response**
  static RouteResult? _parseOpenRouteResponse(Map<String, dynamic> data) {
    if (data['features'] == null || data['features'].isEmpty) return null;

    final feature = data['features'][0];
    final properties = feature['properties'];
    final summary = properties['summary'];

    final distance = summary['distance'] as double; // meters
    final duration = summary['duration'] as double; // seconds

    // Parse geometry (coordinates are in [lon, lat] order)
    final geometry = feature['geometry'];
    final coordinates = geometry['coordinates'] as List;

    List<LatLng> polylinePoints = [];
    for (var coord in coordinates) {
      polylinePoints
          .add(LatLng(coord[1], coord[0])); // Convert [lon, lat] to LatLng
    }

    // Parse steps if available
    final steps = <RouteStep>[];
    final segments = properties['segments'];
    if (segments != null && segments.isNotEmpty) {
      final segment = segments[0];
      for (var step in segment['steps']) {
        steps.add(RouteStep(
          instruction: step['instruction'] ?? '',
          distance: step['distance'],
          duration: step['duration'],
        ));
      }
    }

    return RouteResult(
      polyline: polylinePoints,
      distance: distance,
      duration: duration,
      steps: steps,
    );
  }

  // **Parse OSRM response**
  static RouteResult? _parseOSRMResponse(Map<String, dynamic> data) {
    if (data['code'] != 'Ok' || data['routes'] == null) return null;

    final route = data['routes'][0];
    final distance = route['distance'] as double; // meters
    final duration = route['duration'] as double; // seconds
    final geometry = route['geometry'];

    List<LatLng> polylinePoints = [];

    if (geometry['type'] == 'LineString') {
      final coordinates = geometry['coordinates'] as List;
      for (var coord in coordinates) {
        polylinePoints
            .add(LatLng(coord[1], coord[0])); // OSRM returns [lon, lat]
      }
    }

    final steps = <RouteStep>[];
    if (route['legs'] != null && route['legs'].isNotEmpty) {
      final leg = route['legs'][0];
      for (var step in leg['steps']) {
        steps.add(RouteStep(
          instruction: step['maneuver']['instruction'] ?? '',
          distance: step['distance'],
          duration: step['duration'],
        ));
      }
    }

    return RouteResult(
      polyline: polylinePoints,
      distance: distance,
      duration: duration,
      steps: steps,
    );
  }

  // **Parse GraphHopper response**
  static RouteResult? _parseGraphHopperResponse(Map<String, dynamic> data) {
    if (data['paths'] == null || data['paths'].isEmpty) return null;

    final path = data['paths'][0];
    final distance = path['distance'] as double; // meters
    final time = path['time'] as double; // milliseconds
    final duration = time / 1000; // convert to seconds

    // Parse points
    final points = path['points'];
    List<LatLng> polylinePoints = [];

    if (points['type'] == 'LineString') {
      final coordinates = points['coordinates'] as List;
      for (var coord in coordinates) {
        polylinePoints.add(LatLng(coord[1], coord[0])); // [lon, lat] to LatLng
      }
    }

    // Parse instructions
    final steps = <RouteStep>[];
    final instructions = path['instructions'];
    if (instructions != null) {
      for (var instruction in instructions) {
        steps.add(RouteStep(
          instruction: instruction['text'] ?? '',
          distance: instruction['distance'],
          duration: instruction['time'] / 1000, // ms to seconds
        ));
      }
    }

    return RouteResult(
      polyline: polylinePoints,
      distance: distance,
      duration: duration,
      steps: steps,
    );
  }

  // **Helper method to map profile names**
  static String _mapProfileToOSRM(String profile) {
    switch (profile.toLowerCase()) {
      case 'foot-walking':
      case 'foot':
        return 'walking';
      case 'driving-car':
      case 'car':
        return 'driving';
      case 'cycling-regular':
      case 'bike':
        return 'cycling';
      default:
        return 'driving';
    }
  }

  // **Convenience methods**
  static Future<RouteResult?> getWalkingRoute(
    LatLng origin,
    LatLng destination,
  ) async {
    return await getFreeRoute(origin, destination, 'foot-walking');
  }

  static Future<RouteResult?> getDrivingRoute(
    LatLng origin,
    LatLng destination,
  ) async {
    return await getFreeRoute(origin, destination, 'driving-car');
  }

  static Future<RouteResult?> getCyclingRoute(
    LatLng origin,
    LatLng destination,
  ) async {
    return await getFreeRoute(origin, destination, 'cycling-regular');
  }
}

// **Route result model**
class RouteResult {
  final List<LatLng> polyline;
  final double distance; // meters
  final double duration; // seconds
  final List<RouteStep> steps;

  RouteResult({
    required this.polyline,
    required this.distance,
    required this.duration,
    required this.steps,
  });

  // Format distance for display
  String get formattedDistance {
    if (distance < 1000) {
      return '${distance.round()} m';
    } else {
      return '${(distance / 1000).toStringAsFixed(1)} km';
    }
  }

  // Format duration for display
  String get formattedDuration {
    if (duration < 60) {
      return '${duration.round()} sec';
    } else if (duration < 3600) {
      return '${(duration / 60).round()} min';
    } else {
      final hours = (duration / 3600).floor();
      final minutes = ((duration % 3600) / 60).round();
      return '${hours}h ${minutes}m';
    }
  }
}

// **Route step model**
class RouteStep {
  final String instruction;
  final double distance; // meters
  final double duration; // seconds

  RouteStep({
    required this.instruction,
    required this.distance,
    required this.duration,
  });

  String get formattedDistance {
    if (distance < 1000) {
      return '${distance.round()} m';
    } else {
      return '${(distance / 1000).toStringAsFixed(1)} km';
    }
  }
}
