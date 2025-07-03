// lib/services/map_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/place_model.dart';
import '../core/constants.dart' as Constants;
import 'package:latlong2/latlong.dart' as latlng;

// Helper function to call the Nominatim geocoding API,
// limited to a bounding box that covers the University of Kelaniya Faculty of Medicine in Ragama.
Future<latlng.LatLng?> fetchCoordinatesForAddress(String address) async {
  // Define the bounding box around the Faculty of Medicine in Ragama.
  // Format: "west,north,east,south"
  // Adjust these values as needed to cover your precise area.
  const String viewbox = '79.920741,7.033037,79.937586,7.023922';

  final url = 'https://nominatim.openstreetmap.org/search?'
      'q=${Uri.encodeComponent(address)}&format=json&limit=1'
      '&viewbox=$viewbox&bounded=1';

  final response = await http.get(Uri.parse(url));
  if (response.statusCode == 200) {
    final List<dynamic> data = json.decode(response.body);
    if (data.isNotEmpty) {
      final lat = double.parse(data[0]['lat']);
      final lon = double.parse(data[0]['lon']);
      return latlng.LatLng(lat, lon);
    }
  }
  return null; // Return null if nothing is found or if an error occurs
}

class MapService {
  final String baseUrl = Constants.baseUrl; // Uses the alias 'Constants'

  // Fetch custom places from your backend.
  Future<List<Place>> fetchPlaces(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/map'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> placesJson = data['data'];
      return placesJson.map((json) => Place.fromJson(json)).toList();
    } else {
      throw Exception('Failed to fetch places');
    }
  }

  // Search places from your backend
  Future<List<Place>> searchPlaces(String query, String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/map/search?query=${Uri.encodeComponent(query)}'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> placesJson = data['data'];
      return placesJson.map((json) => Place.fromJson(json)).toList();
    } else {
      throw Exception('Failed to search places');
    }
  }
}
