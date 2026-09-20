/// General application constants that are NOT specific to any one campus.
/// Campus-specific values (name, coordinates, buildings) live in
/// assets/data/*.json — see data/local/campus_data_loader.dart — and must
/// never be hardcoded here. This keeps the app portable to other
/// universities by replacing data, not code (see README "How to add
/// another university").
class AppConstants {
  AppConstants._();

  static const String appName = 'CampusAR';
  static const String appSubtitle = 'Tongmyong University Campus Navigator';

  /// Average adult walking speed in meters/second, used to estimate
  /// walking time from a calculated route distance. Mirrors the backend's
  /// app/core/geo.py so on-device (offline) and server-calculated routes
  /// produce consistent estimates.
  static const double averageWalkingSpeedMetersPerSecond = 1.3;

  /// If the user's GPS position drifts further than this from the active
  /// route's nearest point, navigation triggers a "Recalculating route..."
  /// state (see features/navigation).
  static const double routeDeviationThresholdMeters = 25.0;

  /// Distance below which we say "You have arrived" instead of a distance.
  static const double arrivalThresholdMeters = 8.0;

  static const int nearbyBuildingsRadiusMeters = 400;
  static const int nearbyBuildingsMaxCount = 6;
}
