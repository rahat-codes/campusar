import 'package:campusar/core/errors/app_failure.dart';
import 'package:campusar/core/services/location_service.dart';
import 'package:campusar/core/utilities/result.dart';
import 'package:campusar/data/models/building.dart';
import 'package:campusar/data/models/entrance.dart';
import 'package:campusar/data/models/facility.dart';
import 'package:campusar/data/repositories/building_repository.dart';
import 'package:campusar/data/repositories/providers.dart';
import 'package:campusar/features/buildings/screens/building_detail_screen.dart';
import 'package:campusar/features/buildings/screens/building_search_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _accessibility = AccessibilityInfo(
  wheelchairAccessible: true,
  hasElevator: true,
  notes: 'Sample data',
);

final _buildings = [
  const Building(
    id: 'bldg_17',
    campusId: 'tongmyong-main',
    name: 'Building 17 - International & Global Center',
    shortName: 'Global Center',
    buildingNumber: '17',
    latitude: 35.0951,
    longitude: 129.1005,
    description: 'Sample building',
    image: '',
    floors: 5,
    entranceIds: ['ent_17_main'],
    facilityIds: ['fac_lib'],
    accessibility: _accessibility,
    destinationNodeId: 'node_dest_17',
    entranceNodeId: 'node_ent_17',
  ),
  const Building(
    id: 'bldg_10',
    campusId: 'tongmyong-main',
    name: 'Building 10 - Central Library',
    shortName: 'Central Library',
    buildingNumber: '10',
    latitude: 35.0949,
    longitude: 129.1001,
    description: 'Sample library',
    image: '',
    floors: 4,
    entranceIds: ['ent_10_main'],
    facilityIds: ['fac_reading'],
    accessibility: _accessibility,
    destinationNodeId: 'node_dest_10',
    entranceNodeId: 'node_ent_10',
  ),
];

/// A repository that serves fixed in-memory data instead of touching
/// sqflite, so this test never needs a platform channel.
class _FakeBuildingRepository extends BuildingRepository {
  @override
  Future<List<Building>> getAllBuildings() async => _buildings;

  @override
  Future<List<Building>> search(String query) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return _buildings;
    return _buildings
        .where((b) =>
            b.name.toLowerCase().contains(q) ||
            b.shortName.toLowerCase().contains(q) ||
            b.buildingNumber.toLowerCase().contains(q))
        .toList();
  }

  @override
  Future<BuildingDetail?> getBuildingDetail(
    String id, {
    double? userLatitude,
    double? userLongitude,
  }) async {
    final matches = _buildings.where((b) => b.id == id);
    if (matches.isEmpty) return null;
    final building = matches.first;
    return BuildingDetail(
      building: building,
      entrances: const [
        Entrance(
          id: 'ent_1',
          buildingId: 'bldg_17',
          latitude: 35.0951,
          longitude: 129.1005,
          floor: 1,
          name: 'Main Entrance',
        ),
      ],
      facilities: const [
        Facility(id: 'fac_1', buildingId: 'bldg_17', name: 'Classrooms', category: 'general'),
      ],
      distanceMeters: null,
    );
  }
}

/// Avoids any real Geolocator plugin channel call — reports permission as
/// denied immediately so `currentPositionProvider` resolves to null.
class _FakeLocationService extends LocationService {
  @override
  Future<Result<bool>> requestPermission() async =>
      Result.failure(LocationPermissionDeniedFailure());
}

void main() {
  testWidgets('shows all buildings by default and filters as the user types',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          buildingRepositoryProvider.overrideWithValue(_FakeBuildingRepository()),
        ],
        child: const MaterialApp(home: BuildingSearchScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Global Center'), findsOneWidget);
    expect(find.textContaining('Central Library'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '17');
    await tester.pumpAndSettle();

    expect(find.textContaining('Global Center'), findsOneWidget);
    expect(find.textContaining('Central Library'), findsNothing);
  });

  testWidgets('tapping a result navigates to building details', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          buildingRepositoryProvider.overrideWithValue(_FakeBuildingRepository()),
          locationServiceProvider.overrideWithValue(_FakeLocationService()),
        ],
        child: const MaterialApp(home: BuildingSearchScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('Global Center').first);
    await tester.pumpAndSettle();

    expect(find.byType(BuildingDetailScreen), findsOneWidget);
  });
}
