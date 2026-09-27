import 'package:campusar/data/models/survey/survey_status.dart';

/// Node types for surveyed path data (section 9 of the V1.1 spec) — a
/// superset of the production [RouteNodeType]: adds stairs/ramp/landmark,
/// which the surveyor can mark manually while walking. `intersection` is
/// also set automatically when [SurveyRepository] snaps a new path's
/// endpoint onto an existing node (see PathProcessingService).
enum SurveyNodeType {
  pathway,
  intersection,
  entrance,
  destination,
  stairs,
  ramp,
  landmark;

  static SurveyNodeType fromString(String value) {
    return SurveyNodeType.values.firstWhere(
      (t) => t.name == value,
      orElse: () => SurveyNodeType.pathway,
    );
  }

  /// Maps down to the 4 types the production routing engine understands
  /// (see data/models/route_graph.dart RouteNodeType) — stairs/ramp/landmark
  /// are surveyor-only annotations that become plain `pathway` nodes when
  /// exported to production, since the routing engine doesn't yet reason
  /// about them (see README "Known limitations").
  String get productionTypeName => switch (this) {
        SurveyNodeType.pathway ||
        SurveyNodeType.stairs ||
        SurveyNodeType.ramp ||
        SurveyNodeType.landmark =>
          'pathway',
        SurveyNodeType.intersection => 'intersection',
        SurveyNodeType.entrance => 'entrance',
        SurveyNodeType.destination => 'destination',
      };
}

class SurveyRouteNode {
  const SurveyRouteNode({
    required this.id,
    required this.sessionId,
    required this.latitude,
    required this.longitude,
    required this.capturedAt,
    this.type = SurveyNodeType.pathway,
    this.gpsAccuracy,
    this.status = SurveyStatus.raw,
  });

  final String id;
  final String sessionId;
  final double latitude;
  final double longitude;
  final SurveyNodeType type;
  final double? gpsAccuracy;
  final DateTime capturedAt;
  final SurveyStatus status;

  SurveyRouteNode copyWith({SurveyNodeType? type, SurveyStatus? status}) {
    return SurveyRouteNode(
      id: id,
      sessionId: sessionId,
      latitude: latitude,
      longitude: longitude,
      capturedAt: capturedAt,
      type: type ?? this.type,
      gpsAccuracy: gpsAccuracy,
      status: status ?? this.status,
    );
  }

  factory SurveyRouteNode.fromMap(Map<String, dynamic> map) =>
      SurveyRouteNode(
        id: map['id'] as String,
        sessionId: map['session_id'] as String,
        latitude: (map['latitude'] as num).toDouble(),
        longitude: (map['longitude'] as num).toDouble(),
        type: SurveyNodeType.fromString(map['type'] as String? ?? 'pathway'),
        gpsAccuracy: (map['gps_accuracy'] as num?)?.toDouble(),
        capturedAt: DateTime.parse(map['captured_at'] as String),
        status: SurveyStatus.fromString(map['status'] as String? ?? 'raw'),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'session_id': sessionId,
        'latitude': latitude,
        'longitude': longitude,
        'type': type.name,
        'gps_accuracy': gpsAccuracy,
        'captured_at': capturedAt.toIso8601String(),
        'status': status.name,
      };

  Map<String, dynamic> toJson() => toMap();
}
