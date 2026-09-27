/// Base class for all handled application failures.
///
/// Every screen catches exceptions and converts them into one of these
/// before showing anything to the user (section 23 of the product spec:
/// "Never show raw exceptions to users"). [message] is always a
/// user-friendly string safe to display directly.
sealed class AppFailure {
  const AppFailure(this.message);
  final String message;
}

class LocationPermissionDeniedFailure extends AppFailure {
  const LocationPermissionDeniedFailure()
      : super(
          'Location access is needed to show your position and calculate '
          'routes. You can still browse the campus and buildings without it.',
        );
}

class LocationServiceDisabledFailure extends AppFailure {
  const LocationServiceDisabledFailure()
      : super(
          'Location services are turned off on this device. Turn on GPS to '
          'see your position on the map and get walking directions.',
        );
}

class LocationUnavailableFailure extends AppFailure {
  const LocationUnavailableFailure()
      : super(
          "We couldn't get an accurate location right now. Try moving "
          'to an open area and checking again.',
        );
}

class NoInternetFailure extends AppFailure {
  const NoInternetFailure()
      : super(
          "You're offline — showing saved campus data. Some information "
          'may not be up to date.',
        );
}

class RouteNotFoundFailure extends AppFailure {
  const RouteNotFoundFailure()
      : super(
          "We couldn't find a walking route to that destination. It may be "
          'temporarily unreachable in the campus path network.',
        );
}

class DestinationUnavailableFailure extends AppFailure {
  const DestinationUnavailableFailure()
      : super('That destination is not available right now.');
}

class MapLoadFailure extends AppFailure {
  const MapLoadFailure()
      : super('The campus map could not be loaded. Please try again.');
}

class ArUnsupportedFailure extends AppFailure {
  const ArUnsupportedFailure()
      : super(
          'AR navigation is not supported on this device. Use the regular '
          'navigation screen instead.',
        );
}

class CameraPermissionDeniedFailure extends AppFailure {
  const CameraPermissionDeniedFailure()
      : super(
          'Camera access is needed for AR navigation. You can still use '
          'the regular map-based navigation without it.',
        );
}

class CampusDataFailure extends AppFailure {
  const CampusDataFailure([String? detail])
      : super(detail ?? 'Campus data could not be loaded.');
}

class UnknownFailure extends AppFailure {
  const UnknownFailure()
      : super('Something went wrong. Please try again.');
}
