// lib/services/map_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/place_model.dart';
import '../core/constants.dart' as Constants;
import 'package:latlong2/latlong.dart' as latlng;

Future<latlng.LatLng?> fetchCoordinatesForAddress(String address) async {
  final url = 'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(address)}&format=json&limit=1';
  final response = await http.get(Uri.parse(url));
  if (response.statusCode == 200) {
    final List<dynamic> data = json.decode(response.body);
    if (data.isNotEmpty) {
      final lat = double.parse(data[0]['lat']);
      final lon = double.parse(data[0]['lon']);
      return latlng.LatLng(lat, lon);
    }
  }
  return null; // Return null if nothing found or error occurred
}

class MapService {
  final String baseUrl = Constants.baseUrl; // Now using the alias 'Constants'

  Future<List<Place>> fetchPlaces(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/map'),
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
}
