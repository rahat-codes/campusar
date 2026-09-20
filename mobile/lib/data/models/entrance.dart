class Entrance {
  const Entrance({
    required this.id,
    required this.buildingId,
    required this.latitude,
    required this.longitude,
    required this.floor,
    required this.name,
  });

  final String id;
  final String buildingId;
  final double latitude;
  final double longitude;
  final int floor;
  final String name;

  factory Entrance.fromJson(Map<String, dynamic> json) => Entrance(
        id: json['id'] as String,
        buildingId: json['buildingId'] as String,
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        floor: (json['floor'] as num?)?.toInt() ?? 1,
        name: json['name'] as String? ?? 'Main Entrance',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'buildingId': buildingId,
        'latitude': latitude,
        'longitude': longitude,
        'floor': floor,
        'name': name,
      };
}
