// lib/map/widgets/map_search_bar.dart

import 'package:flutter/material.dart';
import '../models/place_model.dart';
import '../map_constants.dart'; // Add this import

class MapSearchBar extends StatefulWidget {
  final bool enabled;
  final List<PlaceModel> places;
  final Function(PlaceModel) onPlaceSelected;

  const MapSearchBar({
    super.key,
    required this.enabled,
    required this.places,
    required this.onPlaceSelected,
  });

  @override
  State<MapSearchBar> createState() => _MapSearchBarState();
}

class _MapSearchBarState extends State<MapSearchBar> {
  final TextEditingController _controller = TextEditingController();
  List<PlaceModel> _filteredPlaces = [];
  bool _showResults = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _filterPlaces(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredPlaces = [];
        _showResults = false;
      });
      return;
    }

    setState(() {
      _filteredPlaces = widget.places
          .where((place) =>
              place.name.toLowerCase().contains(query.toLowerCase()) ||
              (place.buildingCode
                      ?.toLowerCase()
                      .contains(query.toLowerCase()) ??
                  false))
          .toList();
      _showResults = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _controller,
            enabled: widget.enabled,
            onChanged: _filterPlaces,
            decoration: InputDecoration(
              hintText: widget.enabled
                  ? 'Search campus locations...'
                  : 'Search disabled (not on campus)',
              hintStyle: TextStyle(
                color: widget.enabled ? Colors.grey[400] : Colors.grey[300],
              ),
              prefixIcon: Icon(
                Icons.search,
                color: widget.enabled ? Colors.grey[600] : Colors.grey[300],
              ),
              suffixIcon: _controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _controller.clear();
                        _filterPlaces('');
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ),
        if (_showResults && _filteredPlaces.isNotEmpty)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _filteredPlaces.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                color: Colors.grey[200],
              ),
              itemBuilder: (context, index) {
                final place = _filteredPlaces[index];
                return ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Color(place.markerColor).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getIcon(place.category), // ✅ Use category
                      color: Color(place.markerColor),
                      size: 20,
                    ),
                  ),
                  title: Text(
                    place.name,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: place.buildingCode != null
                      ? Text(place.buildingCode!)
                      : null,
                  onTap: () {
                    widget.onPlaceSelected(place);
                    _controller.clear();
                    setState(() {
                      _showResults = false;
                      _filteredPlaces = [];
                    });
                  },
                );
              },
            ),
          ),
      ],
    );
  }

  // ✅ Updated to use PlaceCategory
  IconData _getIcon(PlaceCategory category) {
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
}
