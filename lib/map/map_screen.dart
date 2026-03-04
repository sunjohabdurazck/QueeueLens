// lib/map/map_screen.dart

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'map_controller.dart';
import 'models/place_model.dart';
import 'widgets/campus_map.dart';
import 'widgets/map_search_bar.dart';
import 'map_constants.dart';
import 'services/directions_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late CampusMapController _controller;
  bool _isLoading = true;
  bool _isInsideCampus = false;
  List<PlaceModel> _places = [];
  LatLng? _userLocation;

  RouteResult? _currentRoute;

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    _controller = CampusMapController();

    // Set up callbacks
    _controller.onPlacesUpdated = (places) {
      setState(() => _places = places);
    };

    _controller.onUserLocationUpdated = (location) {
      setState(() => _userLocation = location);
    };

    _controller.onCampusStatusChanged = (isInside) {
      setState(() => _isInsideCampus = isInside);

      // Show snackbar when campus status changes
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isInside
                  ? '✓ You are inside IUT campus'
                  : '✗ You are outside campus - Map disabled',
            ),
            backgroundColor: isInside ? Colors.green : Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    };

    // Route callback
    _controller.onRouteUpdated = (route) {
      setState(() {
        _currentRoute = route;
      });
    };

    await _controller.initialize();
    setState(() => _isLoading = false);
  }

  void _showPlaceDetails(PlaceModel place) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Drag handle
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    children: [
                      // Place details
                      PlaceDetailsSheet(place: place),

                      // Route info section
                      if (place.routeFromUser != null)
                        _buildRouteInfoSection(place),

                      // Get Directions button
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            await _controller.getRouteToPlace(place);
                            if (mounted) {
                              Navigator.pop(context); // Close bottom sheet
                            }
                          },
                          icon: const Icon(Icons.directions_walk),
                          label: const Text('Show Walking Route'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _onPlaceSelected(PlaceModel place) async {
    await _controller.getRouteToPlace(place);
    _showPlaceDetails(place);
  }

  Widget _buildRouteInfoSection(PlaceModel place) {
    final route = place.routeFromUser!;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Route Information',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.directions_walk, color: Colors.blue),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${route.distance} m • ${route.duration} min',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Walking route',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.clear, size: 20),
                onPressed: _clearRoute,
                tooltip: 'Clear route',
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (route.steps.isNotEmpty) ..._buildStepInstructions(route.steps),
        ],
      ),
    );
  }

  List<Widget> _buildStepInstructions(List<RouteStep> steps) {
    return [
      const Text(
        'Turn-by-turn directions:',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
      const SizedBox(height: 8),
      ...steps.take(5).map(
            (step) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      step.instruction,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
    ];
  }

  void _clearRoute() {
    if (mounted) {
      setState(() {
        _currentRoute = null;
      });
    }
    _controller.clearRoute();

    if (_currentRoute != null && Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('IUT Campus Map'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_userLocation != null)
            IconButton(
              icon: const Icon(Icons.my_location),
              onPressed: _controller.moveToUserLocation,
              tooltip: 'My Location',
            ),
          if (_currentRoute != null)
            IconButton(
              icon: const Icon(Icons.clear_all),
              onPressed: _clearRoute,
              tooltip: 'Clear Route',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : !_isInsideCampus
              ? _buildOutsideCampusView()
              : _buildMapView(),
    );
  }

  Widget _buildOutsideCampusView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_off,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'Map Unavailable',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'You must be inside IUT campus to access the map.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () async {
                setState(() => _isLoading = true);
                await _controller.initialize();
                if (mounted) {
                  setState(() => _isLoading = false);
                }
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapView() {
    return Stack(
      children: [
        CampusMap(
          mapController: _controller.mapController,
          places: _places,
          userLocation: _userLocation,
          onMarkerTap: _showPlaceDetails,
          currentRoute: _currentRoute,
          onClearRoute: _clearRoute,
        ),
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: MapSearchBar(
            enabled: _isInsideCampus,
            places: _places,
            onPlaceSelected: _onPlaceSelected,
          ),
        ),
        Positioned(
          bottom: 16,
          right: 16,
          child: _buildLegend(),
        ),
      ],
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Legend',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          _buildLegendItem(PlaceCategory.classroom, 'Classroom'),
          _buildLegendItem(PlaceCategory.administration, 'Admin'),
          _buildLegendItem(PlaceCategory.library, 'Library'),
          _buildLegendItem(PlaceCategory.cafeteria, 'Cafeteria'),
          _buildLegendItem(PlaceCategory.sports, 'Sports'),
        ],
      ),
    );
  }

  Widget _buildLegendItem(PlaceCategory category, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: _getColorForCategory(category),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }

  Color _getColorForCategory(PlaceCategory category) {
    switch (category) {
      case PlaceCategory.classroom:
        return Colors.blue;
      case PlaceCategory.administration:
        return Colors.red;
      case PlaceCategory.library:
        return Colors.purple;
      case PlaceCategory.cafeteria:
        return Colors.orange;
      case PlaceCategory.sports:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

// PlaceDetailsSheet widget
class PlaceDetailsSheet extends StatelessWidget {
  final PlaceModel place;

  const PlaceDetailsSheet({super.key, required this.place});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            place.name,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            place.description ?? 'No description available', // ✅ null-safe
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                _getIconForCategory(place.category),
                color: Colors.blue,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                _getCategoryName(place.category),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getIconForCategory(PlaceCategory category) {
    switch (category) {
      case PlaceCategory.classroom:
        return Icons.school;
      case PlaceCategory.library:
        return Icons.library_books;
      case PlaceCategory.cafeteria:
        return Icons.restaurant;
      case PlaceCategory.administration:
        return Icons.business;
      case PlaceCategory.sports:
        return Icons.sports_soccer;
      default:
        return Icons.place;
    }
  }

  String _getCategoryName(PlaceCategory category) {
    switch (category) {
      case PlaceCategory.classroom:
        return 'Classroom';
      case PlaceCategory.library:
        return 'Library';
      case PlaceCategory.cafeteria:
        return 'Cafeteria';
      case PlaceCategory.administration:
        return 'Administration';
      case PlaceCategory.sports:
        return 'Sports Facility';
      default:
        return 'Other';
    }
  }
}
