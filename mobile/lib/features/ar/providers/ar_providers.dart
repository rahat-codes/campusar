import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:campusar/features/ar/services/ar_navigation_service.dart';

final arNavigationServiceProvider = Provider<ArNavigationService>((ref) {
  return GpsCompassArNavigationService();
});

final arSupportedProvider = FutureProvider.autoDispose<bool>((ref) async {
  final service = ref.watch(arNavigationServiceProvider);
  return service.isSupported();
});

/// Live AR guidance frames (bearing/distance to the destination) for a
/// specific building. Family-keyed by "lat,lon" so switching destinations
/// gets a fresh stream.
final arGuidanceProvider = StreamProvider.autoDispose
    .family<ArGuidanceFrame, ({double latitude, double longitude})>(
        (ref, destination) {
  final service = ref.watch(arNavigationServiceProvider);
  return service.guidanceStream(
    destinationLatitude: destination.latitude,
    destinationLongitude: destination.longitude,
  );
});
