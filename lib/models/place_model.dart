// lib/models/place_model.dart

class Place {
  final int id;
  final String name;
  final double latitude;
  final double longitude;
  final String? description;

  Place({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.description,
  });

  factory Place.fromJson(Map<String, dynamic> json) {
    return Place(
      id: json['placeId'],
      name: json['placeName'],
      latitude: json['latitude'].toDouble(),
      longitude: json['longitude'].toDouble(),
      description: json['description'],
    );
  }
}
