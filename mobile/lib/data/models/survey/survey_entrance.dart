import 'package:campusar/data/models/survey/survey_status.dart';

/// A building entrance collected in the field (section 6 of the V1.1
/// spec). A building can have many entrances; each references its parent
/// [SurveyBuilding.id] via [buildingId].
class SurveyEntrance {
  const SurveyEntrance({
    required this.id,
    required this.sessionId,
    required this.buildingId,
    required this.latitude,
    required this.longitude,
    required this.capturedAt,
    this.name,
    this.gpsAccuracy,
    this.gpsAltitude,
    this.gpsHeading,
    this.accessible = false,
    this.hasStairs = false,
    this.hasRamp = false,
    this.hasElevator = false,
    this.photoPath,
    this.notes,
    this.status = SurveyStatus.raw,
  });

  final String id;
  final String sessionId;
  final String buildingId;
  final String? name;
  final double latitude;
  final double longitude;
  final double? gpsAccuracy;
  final double? gpsAltitude;
  final double? gpsHeading;
  final DateTime capturedAt;
  final bool accessible;
  final bool hasStairs;
  final bool hasRamp;
  final bool hasElevator;
  final String? photoPath;
  final String? notes;
  final SurveyStatus status;

  SurveyEntrance copyWith({String? photoPath, SurveyStatus? status}) {
    return SurveyEntrance(
      id: id,
      sessionId: sessionId,
      buildingId: buildingId,
      name: name,
      latitude: latitude,
      longitude: longitude,
      gpsAccuracy: gpsAccuracy,
      gpsAltitude: gpsAltitude,
      gpsHeading: gpsHeading,
      capturedAt: capturedAt,
      accessible: accessible,
      hasStairs: hasStairs,
      hasRamp: hasRamp,
      hasElevator: hasElevator,
      photoPath: photoPath ?? this.photoPath,
      notes: notes,
      status: status ?? this.status,
    );
  }

  factory SurveyEntrance.fromMap(Map<String, dynamic> map) => SurveyEntrance(
        id: map['id'] as String,
        sessionId: map['session_id'] as String,
        buildingId: map['building_id'] as String,
        name: map['name'] as String?,
        latitude: (map['latitude'] as num).toDouble(),
        longitude: (map['longitude'] as num).toDouble(),
        gpsAccuracy: (map['gps_accuracy'] as num?)?.toDouble(),
        gpsAltitude: (map['gps_altitude'] as num?)?.toDouble(),
        gpsHeading: (map['gps_heading'] as num?)?.toDouble(),
        capturedAt: DateTime.parse(map['captured_at'] as String),
        accessible: (map['accessible'] as int? ?? 0) == 1,
        hasStairs: (map['has_stairs'] as int? ?? 0) == 1,
        hasRamp: (map['has_ramp'] as int? ?? 0) == 1,
        hasElevator: (map['has_elevator'] as int? ?? 0) == 1,
        photoPath: map['photo_path'] as String?,
        notes: map['notes'] as String?,
        status: SurveyStatus.fromString(map['status'] as String? ?? 'raw'),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'session_id': sessionId,
        'building_id': buildingId,
        'name': name,
        'latitude': latitude,
        'longitude': longitude,
        'gps_accuracy': gpsAccuracy,
        'gps_altitude': gpsAltitude,
        'gps_heading': gpsHeading,
        'captured_at': capturedAt.toIso8601String(),
        'accessible': accessible ? 1 : 0,
        'has_stairs': hasStairs ? 1 : 0,
        'has_ramp': hasRamp ? 1 : 0,
        'has_elevator': hasElevator ? 1 : 0,
        'photo_path': photoPath,
        'notes': notes,
        'status': status.name,
      };

  Map<String, dynamic> toJson() => toMap();
}
