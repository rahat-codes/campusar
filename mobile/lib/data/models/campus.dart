class MapConfiguration {
  const MapConfiguration({
    required this.defaultZoom,
    required this.minZoom,
    required this.maxZoom,
    required this.boundsNorthEastLat,
    required this.boundsNorthEastLon,
    required this.boundsSouthWestLat,
    required this.boundsSouthWestLon,
    required this.tileProvider,
    required this.tileUrlTemplate,
  });

  final double defaultZoom;
  final double minZoom;
  final double maxZoom;
  final double boundsNorthEastLat;
  final double boundsNorthEastLon;
  final double boundsSouthWestLat;
  final double boundsSouthWestLon;
  final String tileProvider;
  final String tileUrlTemplate;

  factory MapConfiguration.fromJson(Map<String, dynamic> json) {
    final ne = json['boundsNorthEast'] as Map<String, dynamic>;
    final sw = json['boundsSouthWest'] as Map<String, dynamic>;
    return MapConfiguration(
      defaultZoom: (json['defaultZoom'] as num).toDouble(),
      minZoom: (json['minZoom'] as num).toDouble(),
      maxZoom: (json['maxZoom'] as num).toDouble(),
      boundsNorthEastLat: (ne['latitude'] as num).toDouble(),
      boundsNorthEastLon: (ne['longitude'] as num).toDouble(),
      boundsSouthWestLat: (sw['latitude'] as num).toDouble(),
      boundsSouthWestLon: (sw['longitude'] as num).toDouble(),
      tileProvider: json['tileProvider'] as String,
      tileUrlTemplate: json['tileUrlTemplate'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'defaultZoom': defaultZoom,
        'minZoom': minZoom,
        'maxZoom': maxZoom,
        'boundsNorthEast': {
          'latitude': boundsNorthEastLat,
          'longitude': boundsNorthEastLon,
        },
        'boundsSouthWest': {
          'latitude': boundsSouthWestLat,
          'longitude': boundsSouthWestLon,
        },
        'tileProvider': tileProvider,
        'tileUrlTemplate': tileUrlTemplate,
      };
}

/// Represents one campus (e.g. Tongmyong University's main campus).
///
/// The app is designed to support multiple campuses/universities by
/// replacing the bundled JSON data — never by hardcoding values here.
/// See README "How to add another university".
class Campus {
  const Campus({
    required this.id,
    required this.name,
    required this.universityName,
    required this.country,
    required this.city,
    required this.latitude,
    required this.longitude,
    required this.mapConfiguration,
    required this.version,
  });

  final String id;
  final String name;
  final String universityName;
  final String country;
  final String city;
  final double latitude;
  final double longitude;
  final MapConfiguration mapConfiguration;
  final String version;

  factory Campus.fromJson(Map<String, dynamic> json) => Campus(
        id: json['id'] as String,
        name: json['name'] as String,
        universityName: json['universityName'] as String,
        country: json['country'] as String,
        city: json['city'] as String,
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        mapConfiguration:
            MapConfiguration.fromJson(json['mapConfiguration'] as Map<String, dynamic>),
        version: json['version'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'universityName': universityName,
        'country': country,
        'city': city,
        'latitude': latitude,
        'longitude': longitude,
        'mapConfiguration': mapConfiguration.toJson(),
        'version': version,
      };
}
