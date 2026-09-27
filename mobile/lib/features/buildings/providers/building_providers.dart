import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import 'package:campusar/core/constants/app_constants.dart';
import 'package:campusar/core/services/location_service.dart';
import 'package:campusar/data/models/building.dart';
import 'package:campusar/data/repositories/building_repository.dart';
import 'package:campusar/data/repositories/providers.dart';

/// Current text in the building search field. Search itself runs fully
/// offline against the local database (section 10 of the product spec).
final buildingSearchQueryProvider = StateProvider<String>((ref) => '');

final buildingSearchResultsProvider =
    FutureProvider.autoDispose<List<Building>>((ref) async {
  final query = ref.watch(buildingSearchQueryProvider);
  final repo = ref.watch(buildingRepositoryProvider);
  if (query.trim().isEmpty) {
    return repo.getAllBuildings();
  }
  return repo.search(query);
});

/// Building detail for [buildingId], including entrances/facilities and
/// (when the user's position is known) live distance.
final buildingDetailProvider = FutureProvider.autoDispose
    .family<BuildingDetail?, String>((ref, buildingId) async {
  final repo = ref.watch(buildingRepositoryProvider);
  final position = await ref.watch(currentPositionProvider.future);
  return repo.getBuildingDetail(
    buildingId,
    userLatitude: position?.latitude,
    userLongitude: position?.longitude,
  );
});

/// Nearby buildings for the home screen's "Nearby" section. Resolves to an
/// empty list (not an error) if the user's position isn't available yet —
/// the home screen shows a permission prompt instead in that case.
final nearbyBuildingsProvider =
    FutureProvider.autoDispose<List<BuildingWithDistance>>((ref) async {
  final position = await ref.watch(currentPositionProvider.future);
  if (position == null) return const [];

  final repo = ref.watch(buildingRepositoryProvider);
  return repo.getNearby(
    userLatitude: position.latitude,
    userLongitude: position.longitude,
    radiusMeters: AppConstants.nearbyBuildingsRadiusMeters.toDouble(),
    maxCount: AppConstants.nearbyBuildingsMaxCount,
  );
});

/// Convenience re-export so screens only need one import for "do we have a
/// live position right now".
final userPositionProvider = Provider<AsyncValue<Position?>>((ref) {
  return ref.watch(currentPositionProvider);
});
