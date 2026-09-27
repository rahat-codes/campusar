import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:campusar/data/repositories/building_repository.dart';
import 'package:campusar/data/repositories/campus_repository.dart';
import 'package:campusar/data/repositories/route_repository.dart';
import 'package:campusar/data/repositories/survey_repository.dart';

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

/// Survey Mode's repository (V1.1 addition). Registered here alongside
/// the others rather than inside features/survey/ so it follows the same
/// "one place for all repositories" convention — Survey Mode otherwise
/// stays entirely self-contained under features/survey/.
final surveyRepositoryProvider = Provider<SurveyRepository>((ref) {
  return SurveyRepository();
});
