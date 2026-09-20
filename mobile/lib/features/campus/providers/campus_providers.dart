import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:campusar/core/utilities/result.dart';
import 'package:campusar/data/models/building.dart';
import 'package:campusar/data/models/campus.dart';
import 'package:campusar/data/repositories/providers.dart';

/// The current campus (Tongmyong University by default — see
/// assets/data/campus.json). Wrapped in a [Result] so the map/home screens
/// can show a friendly message if, somehow, no campus data is bundled.
final campusProvider = FutureProvider<Result<Campus>>((ref) async {
  final repo = ref.watch(campusRepositoryProvider);
  return repo.getCampus();
});

/// All buildings on the current campus, used by the map screen and as the
/// backing list for building search.
final allBuildingsProvider = FutureProvider<List<Building>>((ref) async {
  final repo = ref.watch(buildingRepositoryProvider);
  return repo.getAllBuildings();
});

/// Fired once from the app root to opportunistically check for newer
/// campus data when online. Never blocks the UI — see
/// CampusRepository.checkForUpdates.
final campusSyncProvider = FutureProvider<bool>((ref) async {
  final repo = ref.watch(campusRepositoryProvider);
  return repo.checkForUpdates();
});
