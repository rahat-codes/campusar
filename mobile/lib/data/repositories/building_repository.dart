import 'package:campusar/core/utilities/geo_utils.dart';
import 'package:campusar/data/local/campus_data_loader.dart';
import 'package:campusar/data/local/local_campus_data_source.dart';
import 'package:campusar/data/models/building.dart';
import 'package:campusar/data/models/entrance.dart';
import 'package:campusar/data/models/facility.dart';

/// A building with its distance from the user resolved, for nearby/sorted
/// lists. Distance is null when the user's position isn't known yet.
class BuildingWithDistance {
  const BuildingWithDistance(this.building, this.distanceMeters);
  final Building building;
  final double? distanceMeters;
}

class BuildingDetail {
  const BuildingDetail({
    required this.building,
    required this.entrances,
    required this.facilities,
    this.distanceMeters,
  });

  final Building building;
  final List<Entrance> entrances;
  final List<Facility> facilities;
  final double? distanceMeters;
}

/// Offline-first building repository — every method reads from the local
/// SQLite database, which is always populated (bundled data on first
/// launch, see CampusDataLoader). Search works fully offline
/// (section 10 of the product spec).
class BuildingRepository {
  BuildingRepository({
    LocalCampusDataSource? localDataSource,
    CampusDataLoader? dataLoader,
  })  : _local = localDataSource ?? const LocalCampusDataSource(),
        _loader = dataLoader ?? const CampusDataLoader();

  final LocalCampusDataSource _local;
  final CampusDataLoader _loader;

  Future<void> _ensureReady() => _loader.loadBundledDataIfNeeded();

  Future<List<Building>> getAllBuildings() async {
    await _ensureReady();
    return _local.getAllBuildings();
  }

  Future<List<Building>> search(String query) async {
    await _ensureReady();
    return _local.searchBuildings(query);
  }

  Future<BuildingDetail?> getBuildingDetail(
    String id, {
    double? userLatitude,
    double? userLongitude,
  }) async {
    await _ensureReady();
    final building = await _local.getBuilding(id);
    if (building == null) return null;

    final entrances = await _local.getEntrancesFor(id);
    final facilities = await _local.getFacilitiesFor(id);

    double? distance;
    if (userLatitude != null && userLongitude != null) {
      distance = GeoUtils.haversineDistanceMeters(
        userLatitude,
        userLongitude,
        building.latitude,
        building.longitude,
      );
    }

    return BuildingDetail(
      building: building,
      entrances: entrances,
      facilities: facilities,
      distanceMeters: distance,
    );
  }

  /// Buildings within [radiusMeters] of the user, nearest first, capped at
  /// [maxCount] — used by the home screen's "Nearby" section.
  Future<List<BuildingWithDistance>> getNearby({
    required double userLatitude,
    required double userLongitude,
    required double radiusMeters,
    required int maxCount,
  }) async {
    await _ensureReady();
    final buildings = await _local.getAllBuildings();

    final withDistance = buildings
        .map((b) => BuildingWithDistance(
              b,
              GeoUtils.haversineDistanceMeters(
                userLatitude,
                userLongitude,
                b.latitude,
                b.longitude,
              ),
            ))
        .where((bd) => bd.distanceMeters! <= radiusMeters)
        .toList()
      ..sort((a, b) => a.distanceMeters!.compareTo(b.distanceMeters!));

    return withDistance.take(maxCount).toList();
  }
}
