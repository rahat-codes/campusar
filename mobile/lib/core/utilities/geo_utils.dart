import 'dart:math' as math;

/// Pure geographic calculation functions with no Flutter/platform
/// dependency, so they're trivially unit-testable and kept in lockstep
/// with the backend's app/core/geo.py (same formulas, same constants) —
/// this is what lets the app calculate routes and AR bearings correctly
/// offline, without asking the server.
class GeoUtils {
  GeoUtils._();

  static const double earthRadiusMeters = 6371000.0;

  /// Great-circle distance between two lat/lon points, in meters.
  static double haversineDistanceMeters(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    final phi1 = _toRadians(lat1);
    final phi2 = _toRadians(lat2);
    final dPhi = _toRadians(lat2 - lat1);
    final dLambda = _toRadians(lon2 - lon1);

    final a = math.pow(math.sin(dPhi / 2), 2) +
        math.cos(phi1) * math.cos(phi2) * math.pow(math.sin(dLambda / 2), 2);
    final c = 2 * math.asin(math.sqrt(a));
    return earthRadiusMeters * c;
  }

  /// Initial compass bearing (0-360, 0 = true north) from point 1 to point 2.
  ///
  /// Used by the AR navigation service to compare the direction of the
  /// destination against the device's current heading, so the directional
  /// indicator points the right way (see features/ar/services).
  static double bearingDegrees(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    final phi1 = _toRadians(lat1);
    final phi2 = _toRadians(lat2);
    final dLambda = _toRadians(lon2 - lon1);

    final x = math.sin(dLambda) * math.cos(phi2);
    final y = math.cos(phi1) * math.sin(phi2) -
        math.sin(phi1) * math.cos(phi2) * math.cos(dLambda);
    final theta = math.atan2(x, y);
    return (_toDegrees(theta) + 360) % 360;
  }

  /// Shortest signed angular difference between two bearings, in degrees,
  /// in range [-180, 180]. Positive means `to` is clockwise from `from`.
  static double angleDifferenceDegrees(double from, double to) {
    var diff = (to - from) % 360;
    if (diff > 180) diff -= 360;
    if (diff < -180) diff += 360;
    return diff;
  }

  /// Estimate walking time from distance using an average adult walking
  /// speed. Simple, transparent model — documented rather than hidden —
  /// so it can be tuned per campus later.
  static double estimateWalkingTimeSeconds(
    double distanceMeters, {
    double walkingSpeedMetersPerSecond = 1.3,
  }) {
    if (distanceMeters <= 0) return 0.0;
    return distanceMeters / walkingSpeedMetersPerSecond;
  }

  static double _toRadians(double degrees) => degrees * math.pi / 180.0;
  static double _toDegrees(double radians) => radians * 180.0 / math.pi;
}
