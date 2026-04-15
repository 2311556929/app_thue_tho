class Technician {
  final String id;
  final String name;
  final String phone;
  final List<String> serviceTypes;
  final double rating;
  final String avatar;
  final double latitude;
  final double longitude;
  final double distance;

  Technician({
    required this.id,
    required this.name,
    required this.phone,
    required this.serviceTypes,
    required this.rating,
    required this.avatar,
    required this.latitude,
    required this.longitude,
    required this.distance,
  });

  factory Technician.fromJson(Map<String, dynamic> json) {
    return Technician(
      id: json['id'],
      name: json['name'],
      phone: json['phone'],
      serviceTypes: List<String>.from(json['serviceTypes']),
      rating: json['rating'].toDouble(),
      avatar: json['avatar'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      distance: json['distance'] ?? 0.0,
    );
  }
}