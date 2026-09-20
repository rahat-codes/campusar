import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:campusar/data/repositories/building_repository.dart';
import 'package:campusar/data/repositories/campus_repository.dart';
import 'package:campusar/data/repositories/route_repository.dart';

/// Centralized repository providers. Kept in `data/` (rather than inside
/// a feature folder) because campus/buildings/navigation/ar all depend on
/// these same repositories — this avoids a feature-to-feature import.
final campusRepositoryProvider = Provider<CampusRepository>((ref) {
  return CampusRepository();
});

final buildingRepositoryProvider = Provider<BuildingRepository>((ref) {
  return BuildingRepository();
});

final routeGraphRepositoryProvider = Provider<RouteGraphRepository>((ref) {
  return RouteGraphRepository();
});
