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
      _places = fetchedPlaces;
    } catch (e) {
      debugPrint('Error fetching places: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Simple search implementation
  List<Place> searchPlaces(String query) {
    return _places
        .where((place) =>
        place.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }
}
