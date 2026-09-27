class Facility {
  const Facility({
    required this.id,
    required this.buildingId,
    required this.name,
    required this.category,
  });

  final String id;
  final String buildingId;
  final String name;
  final String category;

  factory Facility.fromJson(Map<String, dynamic> json) => Facility(
        id: json['id'] as String,
        buildingId: json['buildingId'] as String,
        name: json['name'] as String,
        category: json['category'] as String? ?? 'general',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'buildingId': buildingId,
        'name': name,
        'category': category,
      };
}
