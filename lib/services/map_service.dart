// lib/services/map_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/place_model.dart';
import '../core/constants.dart' as Constants;

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
