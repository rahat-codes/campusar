/// One field-survey outing (section 14 of the V1.1 spec). Every collected
/// record references the session that produced it, so field data can be
/// traced back to who collected it, when, and with what device.
class SurveySession {
  const SurveySession({
    required this.id,
    required this.startTime,
    required this.datasetVersion,
    this.surveyorName,
    this.endTime,
    this.deviceInfo,
    this.notes,
  });

  final String id;
  final String? surveyorName;
  final DateTime startTime;
  final DateTime? endTime;
  final String? deviceInfo;
  final String? notes;
  final String datasetVersion;

  bool get isActive => endTime == null;

  SurveySession copyWith({DateTime? endTime, String? notes}) => SurveySession(
        id: id,
        surveyorName: surveyorName,
        startTime: startTime,
        endTime: endTime ?? this.endTime,
        deviceInfo: deviceInfo,
        notes: notes ?? this.notes,
        datasetVersion: datasetVersion,
      );

  factory SurveySession.fromMap(Map<String, dynamic> map) => SurveySession(
        id: map['id'] as String,
        surveyorName: map['surveyor_name'] as String?,
        startTime: DateTime.parse(map['start_time'] as String),
        endTime: map['end_time'] == null
            ? null
            : DateTime.parse(map['end_time'] as String),
        deviceInfo: map['device_info'] as String?,
        notes: map['notes'] as String?,
        datasetVersion: map['dataset_version'] as String,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'surveyor_name': surveyorName,
        'start_time': startTime.toIso8601String(),
        'end_time': endTime?.toIso8601String(),
        'device_info': deviceInfo,
        'notes': notes,
        'dataset_version': datasetVersion,
      };

  Map<String, dynamic> toJson() => toMap();
}
