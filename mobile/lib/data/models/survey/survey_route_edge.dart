import 'package:campusar/data/models/survey/survey_status.dart';

class SurveyRouteEdge {
  const SurveyRouteEdge({
    required this.id,
    required this.sessionId,
    required this.fromNode,
    required this.toNode,
    required this.distance,
    this.accessible = true,
    this.stairs = false,
    this.ramp = false,
    this.indoor = false,
    this.outdoor = true,
    this.surface,
    this.status = SurveyStatus.raw,
  });

  final String id;
  final String sessionId;
  final String fromNode;
  final String toNode;

  /// Always computed from the two nodes' coordinates (haversine) —
  /// never hand-entered (section 10 of the V1.1 spec: "Do not hardcode
  /// distance").
  final double distance;
  final bool accessible;
  final bool stairs;
  final bool ramp;
  final bool indoor;
  final bool outdoor;
  final String? surface;
  final SurveyStatus status;

  SurveyRouteEdge copyWith({SurveyStatus? status}) => SurveyRouteEdge(
        id: id,
        sessionId: sessionId,
        fromNode: fromNode,
        toNode: toNode,
        distance: distance,
        accessible: accessible,
        stairs: stairs,
        ramp: ramp,
        indoor: indoor,
        outdoor: outdoor,
        surface: surface,
        status: status ?? this.status,
      );

  factory SurveyRouteEdge.fromMap(Map<String, dynamic> map) =>
      SurveyRouteEdge(
        id: map['id'] as String,
        sessionId: map['session_id'] as String,
        fromNode: map['from_node'] as String,
        toNode: map['to_node'] as String,
        distance: (map['distance'] as num).toDouble(),
        accessible: (map['accessible'] as int? ?? 1) == 1,
        stairs: (map['stairs'] as int? ?? 0) == 1,
        ramp: (map['ramp'] as int? ?? 0) == 1,
        indoor: (map['indoor'] as int? ?? 0) == 1,
        outdoor: (map['outdoor'] as int? ?? 1) == 1,
        surface: map['surface'] as String?,
        status: SurveyStatus.fromString(map['status'] as String? ?? 'raw'),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'session_id': sessionId,
        'from_node': fromNode,
        'to_node': toNode,
        'distance': distance,
        'accessible': accessible ? 1 : 0,
        'stairs': stairs ? 1 : 0,
        'ramp': ramp ? 1 : 0,
        'indoor': indoor ? 1 : 0,
        'outdoor': outdoor ? 1 : 0,
        'surface': surface,
        'status': status.name,
      };

  Map<String, dynamic> toJson() => toMap();
}
