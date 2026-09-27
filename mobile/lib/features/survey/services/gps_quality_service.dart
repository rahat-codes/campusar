import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import 'package:campusar/core/services/location_service.dart';
import 'package:campusar/core/utilities/result.dart';
import 'package:campusar/core/errors/app_failure.dart';
import 'package:campusar/data/models/survey/gps_sample.dart';

/// Reusable GPS-quality wrapper for Survey Mode (section 4 of the V1.1
/// spec). Deliberately built on top of the existing [LocationService]
/// rather than talking to `geolocator` directly, so V1's location
/// handling (permission flow, typed failures, never-crash guarantees)
/// is reused rather than duplicated.
class GpsQualityService {
  GpsQualityService(this._locationService, {this.thresholds = GpsQualityThresholds.defaults});

  final LocationService _locationService;
  final GpsQualityThresholds thresholds;

  GpsQualityLevel classify(double accuracyMeters) => thresholds.classify(accuracyMeters);

  /// A single capture, converted to a [GpsSample]. Never throws — returns
  /// a typed [Result] like the rest of the app's location handling.
  Future<Result<GpsSample>> captureSample() async {
    final result = await _locationService.getCurrentPosition();
    return result.when(
      success: (position) => Result.success(_toSample(position)),
      failure: (f) => Result.failure(f),
    );
  }

  /// Live accuracy/position stream for on-screen display while the
  /// surveyor moves to find a better GPS fix, or while recording a path.
  Stream<GpsSample> watchSamples() {
    return _locationService.watchPosition(distanceFilterMeters: 0).map(_toSample);
  }

  GpsSample _toSample(Position position) => GpsSample(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        altitude: position.altitude,
        heading: position.heading >= 0 ? position.heading : null,
        capturedAt: position.timestamp,
      );

  /// User-friendly guidance message for a given quality level (section 4:
  /// "GPS accuracy is too low. Move to an open area and wait.").
  String? warningFor(GpsQualityLevel level) {
    if (level == GpsQualityLevel.poor) {
      return 'GPS accuracy is too low. Move to an open area and wait.';
    }
    if (level == GpsQualityLevel.warning) {
      return 'GPS accuracy is borderline — consider waiting for a better fix.';
    }
    return null;
  }
}

final gpsQualityServiceProvider = Provider<GpsQualityService>((ref) {
  return GpsQualityService(ref.watch(locationServiceProvider));
});

/// Live GPS sample stream for Survey Mode screens. Resolves to a typed
/// failure (never throws) if location becomes unavailable mid-survey.
final surveyGpsStreamProvider = StreamProvider.autoDispose<Result<GpsSample>>((ref) async* {
  final service = ref.watch(gpsQualityServiceProvider);
  final permission = await ref.read(locationServiceProvider).requestPermission();
  if (permission.isFailure) {
    yield Result.failure(permission.failureOrNull ?? const LocationUnavailableFailure());
    return;
  }
  yield* service.watchSamples().map((s) => Result<GpsSample>.success(s));
});
