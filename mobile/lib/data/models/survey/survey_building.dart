import 'package:campusar/data/models/survey/gps_sample.dart';
import 'package:campusar/data/models/survey/survey_status.dart';

/// A building collected in the field (section 5 of the V1.1 spec). This
/// is intentionally a separate model/table from the production
/// [Building] — it only becomes production data via the export +
/// human-review pipeline (see README "How to convert verified survey
/// data into production data").
class SurveyBuilding {
  const SurveyBuilding({
    required this.id,
    required this.sessionId,
    required this.nameEn,
    required this.latitude,
    required this.longitude,
    required this.capturedAt,
    this.buildingNumber,
    this.nameKo,
    this.description,
    this.floors,
    this.gpsAccuracy,
    this.gpsAltitude,
    this.gpsHeading,
    this.photoPath,
    this.notes,
    this.status = SurveyStatus.raw,
  });

  final String id;
  final String sessionId;
  final String? buildingNumber;
  final String nameEn;
  final String? nameKo;
  final String? description;
  final int? floors;
  final double latitude;
  final double longitude;
  final double? gpsAccuracy;
  final double? gpsAltitude;
  final double? gpsHeading;
  final DateTime capturedAt;
  final String? photoPath;
  final String? notes;
  final SurveyStatus status;

  SurveyBuilding copyWith({
    double? latitude,
    double? longitude,
    String? photoPath,
    String? notes,
    SurveyStatus? status,
  }) {
    return SurveyBuilding(
      id: id,
      sessionId: sessionId,
      buildingNumber: buildingNumber,
      nameEn: nameEn,
      nameKo: nameKo,
      description: description,
      floors: floors,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      gpsAccuracy: gpsAccuracy,
      gpsAltitude: gpsAltitude,
      gpsHeading: gpsHeading,
      capturedAt: capturedAt,
      photoPath: photoPath ?? this.photoPath,
      notes: notes ?? this.notes,
      status: status ?? this.status,
    );
  }

  factory SurveyBuilding.fromMap(Map<String, dynamic> map) => SurveyBuilding(
        id: map['id'] as String,
        sessionId: map['session_id'] as String,
        buildingNumber: map['building_number'] as String?,
        nameEn: map['name_en'] as String,
        nameKo: map['name_ko'] as String?,
        description: map['description'] as String?,
        floors: (map['floors'] as num?)?.toInt(),
        latitude: (map['latitude'] as num).toDouble(),
        longitude: (map['longitude'] as num).toDouble(),
        gpsAccuracy: (map['gps_accuracy'] as num?)?.toDouble(),
        gpsAltitude: (map['gps_altitude'] as num?)?.toDouble(),
        gpsHeading: (map['gps_heading'] as num?)?.toDouble(),
        capturedAt: DateTime.parse(map['captured_at'] as String),
        photoPath: map['photo_path'] as String?,
        notes: map['notes'] as String?,
        status: SurveyStatus.fromString(map['status'] as String? ?? 'raw'),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'session_id': sessionId,
        'building_number': buildingNumber,
        'name_en': nameEn,
        'name_ko': nameKo,
        'description': description,
        'floors': floors,
        'latitude': latitude,
        'longitude': longitude,
        'gps_accuracy': gpsAccuracy,
        'gps_altitude': gpsAltitude,
        'gps_heading': gpsHeading,
        'captured_at': capturedAt.toIso8601String(),
        'photo_path': photoPath,
        'notes': notes,
        'status': status.name,
      };

  Map<String, dynamic> toJson() => toMap();

  static GpsSample gpsSampleOf(SurveyBuilding b) => GpsSample(
        latitude: b.latitude,
        longitude: b.longitude,
        accuracy: b.gpsAccuracy ?? 999.0,
        altitude: b.gpsAltitude,
        heading: b.gpsHeading,
        capturedAt: b.capturedAt,
      );
}
