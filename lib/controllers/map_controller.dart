// lib/controllers/map_controller.dart

import 'package:flutter/material.dart';
import '../models/place_model.dart';
import '../services/map_service.dart';

class MapController with ChangeNotifier {
  final MapService _mapService = MapService();

  List<Place> _places = [];
  List<Place> get places => _places;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Load places from backend
  Future<void> loadPlaces(String token) async {
    _isLoading = true;
    notifyListeners();
    try {
      final fetchedPlaces = await _mapService.fetchPlaces(token);
      // Debug print to verify correct data load
      debugPrint('Fetched Places Count: ${fetchedPlaces.length}');
      debugPrint('Fetched Places: ${fetchedPlaces.map((p) => p.name).toList()}');
      _places = fetchedPlaces;
    } catch (e) {
      debugPrint('Error fetching places: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Simple search implementation with trimming
  List<Place> searchPlaces(String query) {
    final trimmedQuery = query.trim().toLowerCase();
    final results = _places.where((place) {
      return place.name.toLowerCase().contains(trimmedQuery);
    }).toList();
    
    debugPrint('Local search for "$query": Found ${results.length} results');
    debugPrint('Results: ${results.map((p) => p.name).toList()}');
    
    return results;
  }

  // Search places from backend (for more comprehensive search)
  Future<List<Place>> searchPlacesFromBackend(String query, String token) async {
    try {
      return await _mapService.searchPlaces(query, token);
    } catch (e) {
      debugPrint('Error searching places from backend: $e');
      return [];
    }
  }
}
