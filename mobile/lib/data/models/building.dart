class AccessibilityInfo {
  const AccessibilityInfo({
    required this.wheelchairAccessible,
    required this.hasElevator,
    required this.notes,
  });

  final bool wheelchairAccessible;
  final bool hasElevator;
  final String notes;

  factory AccessibilityInfo.fromJson(Map<String, dynamic> json) {
    return AccessibilityInfo(
      wheelchairAccessible: json['wheelchairAccessible'] as bool? ?? false,
      hasElevator: json['hasElevator'] as bool? ?? false,
      notes: json['notes'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'wheelchairAccessible': wheelchairAccessible,
        'hasElevator': hasElevator,
        'notes': notes,
      };
}

/// A building on campus.
///
/// [destinationNodeId] / [entranceNodeId] point into the routing graph
/// (see RouteNode) so the navigation feature can compute a walking route
/// straight to this building without any extra lookup step.
class Building {
  const Building({
    required this.id,
    required this.campusId,
    required this.name,
    required this.shortName,
    required this.buildingNumber,
    required this.latitude,
    required this.longitude,
    required this.description,
    required this.image,
    required this.floors,
    required this.entranceIds,
    required this.facilityIds,
    required this.accessibility,
    this.destinationNodeId,
    this.entranceNodeId,
  });

  final String id;
  final String campusId;
  final String name;
  final String shortName;
  final String buildingNumber;
  final double latitude;
  final double longitude;
  final String description;
  final String image;
  final int floors;
  final List<String> entranceIds;
  final List<String> facilityIds;
  final AccessibilityInfo accessibility;
  final String? destinationNodeId;
  final String? entranceNodeId;

  factory Building.fromJson(Map<String, dynamic> json) => Building(
        id: json['id'] as String,
        campusId: json['campusId'] as String,
        name: json['name'] as String,
        shortName: json['shortName'] as String,
        buildingNumber: json['buildingNumber'] as String,
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        description: json['description'] as String? ?? '',
        image: json['image'] as String? ?? '',
        floors: (json['floors'] as num?)?.toInt() ?? 1,
        entranceIds: (json['entrances'] as List<dynamic>? ?? [])
            .map((e) => e as String)
            .toList(),
        facilityIds: (json['facilityIds'] as List<dynamic>? ?? [])
            .map((e) => e as String)
            .toList(),
        accessibility:
            AccessibilityInfo.fromJson(json['accessibility'] as Map<String, dynamic>? ?? {}),
        destinationNodeId: json['destinationNodeId'] as String?,
        entranceNodeId: json['entranceNodeId'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'campusId': campusId,
        'name': name,
        'shortName': shortName,
        'buildingNumber': buildingNumber,
        'latitude': latitude,
        'longitude': longitude,
        'description': description,
        'image': image,
        'floors': floors,
        'entrances': entranceIds,
        'facilityIds': facilityIds,
        'accessibility': accessibility.toJson(),
        'destinationNodeId': destinationNodeId,
        'entranceNodeId': entranceNodeId,
      };
}
