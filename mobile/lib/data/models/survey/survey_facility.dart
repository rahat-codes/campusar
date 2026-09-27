import 'package:campusar/data/models/survey/survey_status.dart';

/// A facility collected in the field (section 7 of the V1.1 spec).
/// [buildingId] is optional — some facilities (a bus stop, an outdoor ATM)
/// aren't inside any building.
class SurveyFacility {
  const SurveyFacility({
    required this.id,
    required this.sessionId,
    required this.type,
    required this.latitude,
    required this.longitude,
    required this.capturedAt,
    this.name,
    this.floor,
    this.buildingId,
    this.gpsAccuracy,
    this.gpsAltitude,
    this.gpsHeading,
    this.accessible = false,
    this.photoPath,
    this.notes,
    this.status = SurveyStatus.raw,
  });

  final String id;
  final String sessionId;
  final String type;
  final String? name;
  final double latitude;
  final double longitude;
  final int? floor;
  final String? buildingId;
  final double? gpsAccuracy;
  final double? gpsAltitude;
  final double? gpsHeading;
  final DateTime capturedAt;
  final bool accessible;
  final String? photoPath;
  final String? notes;
  final SurveyStatus status;

  SurveyFacility copyWith({String? photoPath, SurveyStatus? status}) {
    return SurveyFacility(
      id: id,
      sessionId: sessionId,
      type: type,
      name: name,
      latitude: latitude,
      longitude: longitude,
      floor: floor,
      buildingId: buildingId,
      gpsAccuracy: gpsAccuracy,
      gpsAltitude: gpsAltitude,
      gpsHeading: gpsHeading,
      capturedAt: capturedAt,
      accessible: accessible,
      photoPath: photoPath ?? this.photoPath,
      notes: notes,
      status: status ?? this.status,
    );
  }

  factory SurveyFacility.fromMap(Map<String, dynamic> map) => SurveyFacility(
        id: map['id'] as String,
        sessionId: map['session_id'] as String,
        type: map['type'] as String,
        name: map['name'] as String?,
        latitude: (map['latitude'] as num).toDouble(),
        longitude: (map['longitude'] as num).toDouble(),
        floor: (map['floor'] as num?)?.toInt(),
        buildingId: map['building_id'] as String?,
        gpsAccuracy: (map['gps_accuracy'] as num?)?.toDouble(),
        gpsAltitude: (map['gps_altitude'] as num?)?.toDouble(),
        gpsHeading: (map['gps_heading'] as num?)?.toDouble(),
        capturedAt: DateTime.parse(map['captured_at'] as String),
        accessible: (map['accessible'] as int? ?? 0) == 1,
        photoPath: map['photo_path'] as String?,
        notes: map['notes'] as String?,
        status: SurveyStatus.fromString(map['status'] as String? ?? 'raw'),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'session_id': sessionId,
        'type': type,
        'name': name,
        'latitude': latitude,
        'longitude': longitude,
        'floor': floor,
        'building_id': buildingId,
        'gps_accuracy': gpsAccuracy,
        'gps_altitude': gpsAltitude,
        'gps_heading': gpsHeading,
        'captured_at': capturedAt.toIso8601String(),
        'accessible': accessible ? 1 : 0,
        'photo_path': photoPath,
        'notes': notes,
        'status': status.name,
      };

  Map<String, dynamic> toJson() => toMap();
}
