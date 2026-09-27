/// Backend API configuration.
///
/// The app is offline-first (see README "Offline architecture") — none of
/// these values are required for the app to function. They are only used
/// by data/remote/api_client.dart for optional background sync when the
/// device has internet access.
class ApiConstants {
  ApiConstants._();

  /// Base URL of the FastAPI backend.
  ///
  /// IMPORTANT — platform-specific localhost during development:
  /// - Android emulator: 'http://10.0.2.2:8000' (NOT 127.0.0.1 — the
  ///   emulator's 127.0.0.1 refers to the emulator itself, not your host
  ///   machine).
  /// - iOS simulator: 'http://127.0.0.1:8000' (simulator shares the host's
  ///   network namespace, so localhost works directly).
  /// - Physical Android/iOS device: use your development machine's LAN IP,
  ///   e.g. 'http://192.168.1.23:8000', and ensure the phone is on the same
  ///   network as the machine running the backend + docker-compose.
  ///
  /// Override at build/run time with:
  ///   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );

  static const String apiV1Prefix = '/api/v1';

  static const Duration requestTimeout = Duration(seconds: 8);
}
