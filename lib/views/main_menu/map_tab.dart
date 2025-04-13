import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart' as latlng;
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../controllers/map_controller.dart';
import '../../models/place_model.dart';
import '../../services/map_service.dart';

class SearchSuggestion {
  final String name;
  final String? description;
  final latlng.LatLng location;
  final bool isCustomPlace;

  SearchSuggestion({
    required this.name,
    this.description,
    required this.location,
    this.isCustomPlace = false,
  });
}

class MapTab extends StatefulWidget {
  const MapTab({Key? key}) : super(key: key);

  @override
  State<MapTab> createState() => _MapTabState();
}

class _MapTabState extends State<MapTab> {
  final fm.MapController flutterMapController = fm.MapController();
  latlng.LatLng? _userLocation;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  double _currentZoom = 16.0;
  bool _isSearchFocused = false;
  List<SearchSuggestion> _searchSuggestions = [];
  Timer? _debounce;
  bool _isLoadingSuggestions = false;

  // Reference bounds for search (around Kelaniya area)
  final double _searchLatMin = 6.9;
  final double _searchLatMax = 7.1;
  final double _searchLngMin = 79.8;
  final double _searchLngMax = 80.0;

  @override
  void initState() {
    super.initState();
    _determineUserLocation();
    _searchFocusNode.addListener(_onSearchFocusChange);
    _searchController.addListener(_onSearchChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final token = '';
      await context.read<MapController>().loadPlaces(token);
    });
  }

  @override
  void dispose() {
    _searchFocusNode.removeListener(_onSearchFocusChange);
    _searchFocusNode.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchFocusChange() {
    setState(() {
      _isSearchFocused = _searchFocusNode.hasFocus;
      if (!_isSearchFocused) {
        // Hide suggestions when focus is lost
        _searchSuggestions = [];
      }
    });
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      // Only fetch suggestions if there's text and focus
      if (_searchController.text.isNotEmpty && _isSearchFocused) {
        _fetchSearchSuggestions(_searchController.text);
      } else if (_searchController.text.isEmpty) {
        setState(() {
          _searchSuggestions = [];
        });
      }
    });
  }

  Future<void> _fetchSearchSuggestions(String query) async {
    if (query.length < 2) return;

    setState(() {
      _isLoadingSuggestions = true;
    });

    try {
      // 1. First get suggestions from local custom places
      final mapCtrl = context.read<MapController>();
      final localResults = mapCtrl.searchPlaces(query);

      List<SearchSuggestion> suggestions = localResults.map((place) =>
          SearchSuggestion(
            name: place.name,
            description: place.description,
            location: latlng.LatLng(place.latitude, place.longitude),
            isCustomPlace: true,
          )
      ).toList();

      // 2. Then fetch from Nominatim for other places in the area
      if (query.length >= 3) {  // Only query external API if query is substantial
        final nominatimResults = await _fetchNominatimSuggestions(query);
        suggestions.addAll(nominatimResults);
      }

      setState(() {
        _searchSuggestions = suggestions;
        _isLoadingSuggestions = false;
      });
    } catch (e) {
      debugPrint('Error fetching search suggestions: $e');
      setState(() {
        _isLoadingSuggestions = false;
      });
    }
  }

  Future<List<SearchSuggestion>> _fetchNominatimSuggestions(String query) async {
    // Limit the search to the area around Kelaniya
    final String viewbox = '$_searchLngMin,$_searchLatMin,$_searchLngMax,$_searchLatMax';

    final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
            '?format=json'
            '&q=$query'
            '&viewbox=$viewbox'
            '&bounded=1'
            '&limit=5'
            '&addressdetails=1'
    );

    final response = await http.get(
      uri,
      headers: {'User-Agent': 'KelaniyaMedicalMap/1.0'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> results = json.decode(response.body);

      return results.map((item) {
        final double lat = double.parse(item['lat']);
        final double lon = double.parse(item['lon']);

        // Create a description from address parts
        final Map<String, dynamic> address = item['address'];
        String description = '';

        if (address.containsKey('road')) {
          description += address['road'];
          if (address.containsKey('suburb')) {
            description += ', ${address['suburb']}';
          }
        } else if (address.containsKey('suburb')) {
          description = address['suburb'];
        }

        return SearchSuggestion(
          name: item['display_name'].toString().split(',').first,
          description: description,
          location: latlng.LatLng(lat, lon),
        );
      }).toList();
    }

    return [];
  }

  Future<void> _determineUserLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _userLocation = latlng.LatLng(position.latitude, position.longitude);
      });

      // Move map to user's location when first determined
      if (_userLocation != null) {
        flutterMapController.move(_userLocation!, _currentZoom);
      }
    } catch (e) {
      debugPrint("Error getting current location: $e");
    }
  }

  void _goToUserLocation() {
    if (_userLocation != null) {
      flutterMapController.move(_userLocation!, 18.0);
    } else {
      _determineUserLocation();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Trying to get your location...")),
      );
    }
  }

  void _selectSuggestion(SearchSuggestion suggestion) {
    _searchController.text = suggestion.name;
    flutterMapController.move(suggestion.location, 18.0);

    setState(() {
      _searchSuggestions = [];
    });

    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final mapCtrl = context.watch<MapController>();
    final List<Place> places = mapCtrl.places;

    return Scaffold(
      body: Stack(
        children: [
          _buildMap(places),
          _buildSearchBar(),
          if (_isSearchFocused && _searchSuggestions.isNotEmpty)
            _buildSearchSuggestions(),
          _buildMyLocationButton(),
          if (mapCtrl.isLoading)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }

  Widget _buildMap(List<Place> places) {
    return fm.FlutterMap(
      mapController: flutterMapController,
      options: fm.MapOptions(
        initialCenter: latlng.LatLng(7.028812, 79.926687),
        initialZoom: 16.0,
        onMapEvent: (event) {
          if (event is fm.MapEventMoveEnd) {
            setState(() {
              _currentZoom = flutterMapController.camera.zoom;
            });
          }
        },
        interactionOptions: const fm.InteractionOptions(
          enableMultiFingerGestureRace: true,
        ),
        // Close suggestions when map is tapped
        onTap: (_, __) {
          if (_isSearchFocused) {
            FocusScope.of(context).unfocus();
          }
        },
      ),
      children: [
        fm.TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.kelaniya.medicine.map',
        ),
        fm.MarkerLayer(
          markers: _buildMarkers(places),
        ),
      ],
    );
  }

  List<fm.Marker> _buildMarkers(List<Place> places) {
    List<fm.Marker> markers = [];

    // Add place markers
    for (var place in places) {
      markers.add(_buildPlaceMarker(place));
    }

    // Add user location marker
    if (_userLocation != null) {
      markers.add(_buildUserLocationMarker());
    }

    return markers;
  }

  fm.Marker _buildPlaceMarker(Place place) {
    // Dynamic sizing based on zoom
    final double baseSize = 30;
    final double scaleFactor = _currentZoom > 14 ? 1.0 : (_currentZoom / 14);
    final double actualSize = baseSize * scaleFactor;

    return fm.Marker(
      width: actualSize * 2,
      height: actualSize * 2,
      point: latlng.LatLng(place.latitude, place.longitude),
      child: GestureDetector(
        onTap: () => _showPlaceDetails(place),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_currentZoom > 14) // Only show labels at higher zoom levels
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 2,
                    ),
                  ],
                ),
                child: Text(
                  place.name,
                  style: TextStyle(
                    fontSize: 12 * scaleFactor,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            Container(
              width: actualSize,
              height: actualSize,
              decoration: BoxDecoration(
                color: Colors.grey[700],
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  fm.Marker _buildUserLocationMarker() {
    return fm.Marker(
      width: 22,
      height: 22,
      point: _userLocation!,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.blue[600],
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 16,
      right: 16,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 12),
            Icon(
              Icons.search,
              color: Colors.grey[700],
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                decoration: const InputDecoration(
                  hintText: 'Search places...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 14),
                ),
                onSubmitted: (query) {
                  if (_searchSuggestions.isNotEmpty) {
                    _selectSuggestion(_searchSuggestions.first);
                  } else if (query.isNotEmpty) {
                    _handleSearch(query);
                  }
                },
              ),
            ),
            if (_isLoadingSuggestions)
              Container(
                width: 24,
                height: 24,
                margin: const EdgeInsets.only(right: 8),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[400]!),
                ),
              ),
            if (_searchController.text.isNotEmpty && !_isLoadingSuggestions)
              IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _searchSuggestions = [];
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchSuggestions() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 56,
      left: 16,
      right: 16,
      child: Card(
        elevation: 4,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.4,
          ),
          child: ListView.builder(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            itemCount: _searchSuggestions.length,
            itemBuilder: (context, index) {
              final suggestion = _searchSuggestions[index];
              return ListTile(
                leading: Icon(
                  suggestion.isCustomPlace ? Icons.place : Icons.location_on,
                  color: suggestion.isCustomPlace ? Colors.blue : Colors.grey[700],
                ),
                title: Text(
                  suggestion.name,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: suggestion.description != null && suggestion.description!.isNotEmpty
                    ? Text(
                  suggestion.description!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                )
                    : null,
                onTap: () => _selectSuggestion(suggestion),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMyLocationButton() {
    return Positioned(
      bottom: 32,
      right: 16,
      child: FloatingActionButton(
        backgroundColor: Colors.white,
        foregroundColor: Colors.blue[700],
        elevation: 4,
        onPressed: _goToUserLocation,
        child: const Icon(Icons.my_location, size: 28),
      ),
    );
  }

  Future<void> _handleSearch(String query) async {
    if (query.isEmpty) return;

    final mapCtrl = context.read<MapController>();
    final results = mapCtrl.searchPlaces(query);

    if (results.isNotEmpty) {
      final match = results.first;
      flutterMapController.move(
        latlng.LatLng(match.latitude, match.longitude),
        18.0,
      );
    } else {
      try {
        final location = await fetchCoordinatesForAddress(query);
        if (location != null) {
          flutterMapController.move(location, 18.0);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("No location found for '$query'")),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error searching for location")),
        );
      }
    }

    FocusScope.of(context).unfocus();
  }

  void _showPlaceDetails(Place place) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
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
              place.description ?? 'No description available.',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('CLOSE'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}