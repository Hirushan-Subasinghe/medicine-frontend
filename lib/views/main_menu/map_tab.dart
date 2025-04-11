import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart' as latlng;
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../../controllers/map_controller.dart';  // Your custom map controller
import '../../models/place_model.dart';

class MapTab extends StatefulWidget {
  const MapTab({Key? key}) : super(key: key);

  @override
  State<MapTab> createState() => _MapTabState();
}

class _MapTabState extends State<MapTab> {
  final fm.MapController flutterMapController = fm.MapController();
  latlng.LatLng? _userLocation;

  @override
  void initState() {
    super.initState();
    _determineUserLocation();
    // Load custom places from the backend after the widget builds.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = ''; // Retrieve your auth token if needed.
      context.read<MapController>().loadPlaces(token);
    });
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

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    setState(() {
      _userLocation = latlng.LatLng(position.latitude, position.longitude);
    });
  }

  @override
  Widget build(BuildContext context) {
    final mapCtrl = context.watch<MapController>(); // Your custom controller for map state
    final List<Place> places = mapCtrl.places;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelaniya Faculty of Medicine Map'),
      ),
      body: Stack(
        children: [
          _buildMap(places),
          _buildSearchBar(mapCtrl),
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
        initialCenter: latlng.LatLng(7.028812, 79.926687), // Approximate center for Faculty of Medicine
        initialZoom: 16.0,
      ),
      children: [
        fm.TileLayer(
          urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
          subdomains: const ['a', 'b', 'c'],
        ),
        fm.MarkerLayer(
          markers: [
            // Markers for each custom place fetched from the backend.
            ...places.map((place) => fm.Marker(
              width: 80.0,
              height: 80.0,
              point: latlng.LatLng(place.latitude, place.longitude),
              child: GestureDetector(
                onTap: () {
                  _showPlaceDetails(place);
                },
                child: const Icon(
                  Icons.location_on,
                  color: Colors.red,
                  size: 40,
                ),
              ),
            )),
            // Marker for user location, if available.
            if (_userLocation != null)
              fm.Marker(
                width: 80.0,
                height: 80.0,
                point: _userLocation!,
                child: const Icon(
                  Icons.my_location,
                  color: Colors.blue,
                  size: 35,
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchBar(MapController mapCtrl) {
    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: Card(
        child: TextField(
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            hintText: 'Search place...',
            border: InputBorder.none,
            contentPadding: EdgeInsets.all(8),
          ),
          onChanged: (query) {
            final results = mapCtrl.searchPlaces(query);
            if (results.isNotEmpty) {
              final match = results.first;
              flutterMapController.move(
                latlng.LatLng(match.latitude, match.longitude),
                18.0,
              );
            }
          },
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
