import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart' as latlng;
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../../controllers/map_controller.dart'; // Your custom MapController
import '../../models/place_model.dart';
import '../../services/map_service.dart'; // Provides fetchCoordinatesForAddress

class MapTab extends StatefulWidget {
  const MapTab({Key? key}) : super(key: key);

  @override
  State<MapTab> createState() => _MapTabState();
}

class _MapTabState extends State<MapTab> {
  final fm.MapController flutterMapController = fm.MapController();
  latlng.LatLng? _userLocation;
  final TextEditingController _searchController = TextEditingController();

  // Initialize current zoom to the initial zoom value.
  double _currentZoom = 16.0;

  @override
  void initState() {
    super.initState();
    _determineUserLocation();
    // Load custom places from backend after the widget builds.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final token = ''; // Replace with a valid token if needed.
      await context.read<MapController>().loadPlaces(token);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Determine the user's current location.
  Future<void> _determineUserLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    setState(() {
      _userLocation = latlng.LatLng(position.latitude, position.longitude);
    });
  }

  // Handle search: first check local places; if no match, fallback to Nominatim.
  Future<void> _handleSearch(String query) async {
    debugPrint("Searching for: '$query'");
    final mapCtrl = context.read<MapController>();
    final results = mapCtrl.searchPlaces(query);
    if (results.isNotEmpty) {
      final match = results.first;
      debugPrint("Found local match: ${match.name}");
      flutterMapController.move(
        latlng.LatLng(match.latitude, match.longitude),
        18.0,
      );
    } else {
      debugPrint("No local match; attempting geocoding for '$query'");
      final location = await fetchCoordinatesForAddress(query);
      if (location != null) {
        debugPrint("Nominatim found coordinates: ${location.latitude}, ${location.longitude}");
        flutterMapController.move(location, 18.0);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("No location found for '$query'")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mapCtrl = context.watch<MapController>(); // Custom MapController for state
    final List<Place> places = mapCtrl.places;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelaniya Faculty of Medicine Map'),
      ),
      body: Stack(
        children: [
          _buildMap(places),
          _buildSearchBar(),
          if (mapCtrl.isLoading)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }

  Widget _buildMap(List<Place> places) {
    // Inverse scaling formula: markerSize = constant / _currentZoom.
    // Adjust the constant as needed for visual clarity; here we use 150.
    double markerSize = 150 / _currentZoom;

    return fm.FlutterMap(
      mapController: flutterMapController,
      options: fm.MapOptions(
        initialCenter: latlng.LatLng(7.028812, 79.926687), // Center on your campus area.
        initialZoom: 16.0,
        onMapEvent: (event) {
          if (event is fm.MapEventMoveEnd) {
            final dynamic e = event; // Dynamic cast to access newZoom.
            if (e.newZoom != null) {
              setState(() {
                _currentZoom = e.newZoom;
              });
            }
          }
        },
      ),
      children: [
        fm.TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
        ),
        fm.MarkerLayer(
          markers: [
            // Custom places: display a label (full name) above a gray dot.
            ...places.map((place) => fm.Marker(
              width: markerSize * 3, // Allow wider area for the label.
              height: markerSize * 2, // Extra vertical space for the label.
              point: latlng.LatLng(place.latitude, place.longitude),
              child: GestureDetector(
                onTap: () {
                  _showPlaceDetails(place);
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Text label container: allow full name display.
                    Container(
                      width: markerSize * 3,
                      child: Text(
                        place.name,
                        style: TextStyle(
                          fontSize: markerSize * 0.7, // Scale text size.
                          color: Colors.black,
                        ),
                        textAlign: TextAlign.center,
                        softWrap: true,
                      ),
                    ),
                    SizedBox(
                      width: markerSize,
                      height: markerSize,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.grey,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )),
            // User location marker: displayed as a blue dot.
            if (_userLocation != null)
              fm.Marker(
                width: markerSize,
                height: markerSize,
                point: _userLocation!,
                child: SizedBox(
                  width: markerSize,
                  height: markerSize,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: Card(
        child: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            hintText: 'Search place...',
            border: InputBorder.none,
            contentPadding: EdgeInsets.all(8),
          ),
          onSubmitted: (query) => _handleSearch(query),
        ),
      ),
    );
  }

  void _showPlaceDetails(Place place) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(place.name),
        content: Text(place.description ?? 'No description available.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
