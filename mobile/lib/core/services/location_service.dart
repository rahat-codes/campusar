import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import 'package:campusar/core/errors/app_failure.dart';
import 'package:campusar/core/utilities/geo_utils.dart';
import 'package:campusar/core/utilities/result.dart';

/// Abstraction over device location so the rest of the app never talks to
/// `geolocator` directly (section 12 of the product spec). Handles permission
/// denial, disabled GPS, and low/no accuracy without ever throwing — every
/// public method returns a [Result], and the app never crashes because
/// location is unavailable.
class LocationService {
  /// Requests location permission if not already granted.
  ///
  /// Returns [Result.success] with `true` if permission is granted,
  /// or a typed [AppFailure] describing why it wasn't.
  Future<Result<bool>> requestPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Result.failure(LocationServiceDisabledFailure());
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return Result.failure(LocationPermissionDeniedFailure());
    }

    return Result.success(true);
  }

  /// Gets a single current position. Returns a typed failure rather than
  /// throwing if permission isn't granted, GPS is off, or a fix can't be
  /// obtained within a reasonable time.
  Future<Result<Position>> getCurrentPosition() async {
    final permissionResult = await requestPermission();
    if (permissionResult.isFailure) {
      return Result.failure(permissionResult.failureOrNull!);
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      return Result.success(position);
    } catch (_) {
      return Result.failure(LocationUnavailableFailure());
    }
  }

  /// Continuous position updates, e.g. for live navigation. Emits nothing
  /// (silently) if permission is later revoked — the UI should keep
  /// showing the last-known position with a "location unavailable" note
  /// rather than crash.
  Stream<Position> watchPosition({int distanceFilterMeters = 2}) {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: distanceFilterMeters,
      ),
    );
  }

  double distanceBetweenMeters(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return GeoUtils.haversineDistanceMeters(lat1, lon1, lat2, lon2);
  }

  double bearingDegrees(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return GeoUtils.bearingDegrees(lat1, lon1, lat2, lon2);
  }
}

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

/// Latest known position, or null while unavailable/denied. Screens should
/// treat null as "show fallback UI", never as an error state to surface
/// loudly.
final currentPositionProvider = StreamProvider<Position?>((ref) async* {
  final service = ref.watch(locationServiceProvider);
  final permission = await service.requestPermission();
  if (permission.isFailure) {
    yield null;
    return;
  }
  yield* service.watchPosition().map((p) => p as Position?);
});
