/// A single GPS capture, with the metadata needed to judge its quality
/// (section 4 of the V1.1 spec). Every survey record stores the sample
/// that produced its coordinates, so accuracy can be reviewed later.
class GpsSample {
  const GpsSample({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.capturedAt,
    this.altitude,
    this.heading,
  });

  final double latitude;
  final double longitude;

  /// Horizontal accuracy in meters, as reported by the device. Smaller is
  /// better.
  final double accuracy;
  final double? altitude;
  final double? heading;
  final DateTime capturedAt;

  GpsSample copyWith({double? latitude, double? longitude}) {
    return GpsSample(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      accuracy: accuracy,
      capturedAt: capturedAt,
      altitude: altitude,
      heading: heading,
    );
  }

  factory GpsSample.fromMap(Map<String, dynamic> map, {String prefix = ''}) {
    return GpsSample(
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      accuracy: (map['${prefix}accuracy'] as num?)?.toDouble() ?? 999.0,
      altitude: (map['${prefix}altitude'] as num?)?.toDouble(),
      heading: (map['${prefix}heading'] as num?)?.toDouble(),
      capturedAt: DateTime.parse(map['captured_at'] as String),
    );
  }

  Map<String, dynamic> toMap({String prefix = ''}) => {
        'latitude': latitude,
        'longitude': longitude,
        '${prefix}accuracy': accuracy,
        '${prefix}altitude': altitude,
        '${prefix}heading': heading,
        'captured_at': capturedAt.toIso8601String(),
      };
}

/// Accuracy tiers used throughout Survey Mode to decide whether a capture
/// is good enough to save (section 4 of the V1.1 spec). Thresholds are
/// configurable — see [GpsQualityThresholds] — these are just the
/// suggested defaults.
enum GpsQualityLevel {
  excellent,
  good,
  warning,
  poor;

  String get label => switch (this) {
        GpsQualityLevel.excellent => 'Excellent',
        GpsQualityLevel.good => 'Good',
        GpsQualityLevel.warning => 'Warning',
        GpsQualityLevel.poor => 'Poor',
      };
}

class GpsQualityThresholds {
  const GpsQualityThresholds({
    this.excellentMaxMeters = 5.0,
    this.goodMaxMeters = 10.0,
    this.warningMaxMeters = 20.0,
  });

  final double excellentMaxMeters;
  final double goodMaxMeters;
  final double warningMaxMeters;

  GpsQualityLevel classify(double accuracyMeters) {
    if (accuracyMeters <= excellentMaxMeters) return GpsQualityLevel.excellent;
    if (accuracyMeters <= goodMaxMeters) return GpsQualityLevel.good;
    if (accuracyMeters <= warningMaxMeters) return GpsQualityLevel.warning;
    return GpsQualityLevel.poor;
  }

  static const defaults = GpsQualityThresholds();
}
