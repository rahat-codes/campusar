/// A single raw GPS point recorded while walking a path, before any
/// filtering/simplification (section 8 of the V1.1 spec). Kept forever,
/// separately from the processed [SurveyRouteNode]s a recording produces,
/// so the original track can be reviewed later.
class SurveyRawSample {
  const SurveyRawSample({
    this.id,
    required this.sessionId,
    required this.recordingId,
    required this.latitude,
    required this.longitude,
    required this.capturedAt,
    this.accuracy,
    this.altitude,
    this.heading,
  });

  final int? id;
  final String sessionId;
  final String recordingId;
  final double latitude;
  final double longitude;
  final double? accuracy;
  final double? altitude;
  final double? heading;
  final DateTime capturedAt;

  factory SurveyRawSample.fromMap(Map<String, dynamic> map) =>
      SurveyRawSample(
        id: map['id'] as int?,
        sessionId: map['session_id'] as String,
        recordingId: map['recording_id'] as String,
        latitude: (map['latitude'] as num).toDouble(),
        longitude: (map['longitude'] as num).toDouble(),
        accuracy: (map['accuracy'] as num?)?.toDouble(),
        altitude: (map['altitude'] as num?)?.toDouble(),
        heading: (map['heading'] as num?)?.toDouble(),
        capturedAt: DateTime.parse(map['captured_at'] as String),
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'session_id': sessionId,
        'recording_id': recordingId,
        'latitude': latitude,
        'longitude': longitude,
        'accuracy': accuracy,
        'altitude': altitude,
        'heading': heading,
        'captured_at': capturedAt.toIso8601String(),
      };
}

/// Aggregate counts for the Survey Home dashboard (section 3) and
/// Progress screen (section 17) — always computed live from the
/// database, never hardcoded.
class SurveyCounts {
  const SurveyCounts({
    required this.buildings,
    required this.entrances,
    required this.facilities,
    required this.nodes,
    required this.edges,
  });

  final int buildings;
  final int entrances;
  final int facilities;
  final int nodes;
  final int edges;
}
