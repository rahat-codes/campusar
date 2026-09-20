import 'package:campusar/core/errors/app_failure.dart';
import 'package:campusar/core/services/location_service.dart';
import 'package:campusar/core/utilities/result.dart';
import 'package:campusar/data/models/building.dart';
import 'package:campusar/data/models/entrance.dart';
import 'package:campusar/data/models/facility.dart';
import 'package:campusar/data/repositories/building_repository.dart';
import 'package:campusar/data/repositories/providers.dart';
import 'package:campusar/features/buildings/screens/building_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _building = Building(
  id: 'bldg_17',
  campusId: 'tongmyong-main',
  name: 'Building 17 - International & Global Center',
  shortName: 'Global Center',
  buildingNumber: '17',
  latitude: 35.0951,
  longitude: 129.1005,
  description: 'Sample dataset — replace with verified Tongmyong University campus data.',
  image: '',
  floors: 5,
  entranceIds: ['ent_17_main'],
  facilityIds: ['fac_1', 'fac_2'],
  accessibility: AccessibilityInfo(
    wheelchairAccessible: true,
    hasElevator: true,
    notes: 'Sample accessibility info — verify with campus facilities office.',
  ),
  destinationNodeId: 'node_dest_17',
  entranceNodeId: 'node_ent_17',
);

class _FakeBuildingRepository extends BuildingRepository {
  @override
  Future<BuildingDetail?> getBuildingDetail(
    String id, {
    double? userLatitude,
    double? userLongitude,
  }) async {
    if (id != _building.id) return null;
    return const BuildingDetail(
      building: _building,
      entrances: [
        Entrance(
          id: 'ent_17_main',
          buildingId: 'bldg_17',
          latitude: 35.0951,
          longitude: 129.1005,
          floor: 1,
          name: 'Main Entrance',
        ),
      ],
      facilities: [
        Facility(id: 'fac_1', buildingId: 'bldg_17', name: 'Classrooms', category: 'general'),
        Facility(id: 'fac_2', buildingId: 'bldg_17', name: 'Restrooms', category: 'general'),
      ],
      distanceMeters: 210.4,
    );
  }
}

class _FakeLocationService extends LocationService {
  @override
  Future<Result<bool>> requestPermission() async =>
      Result.failure(LocationPermissionDeniedFailure());
}

void main() {
  testWidgets('shows building name, facilities, and navigate/AR buttons',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          buildingRepositoryProvider.overrideWithValue(_FakeBuildingRepository()),
          locationServiceProvider.overrideWithValue(_FakeLocationService()),
        ],
        child: const MaterialApp(
          home: BuildingDetailScreen(buildingId: 'bldg_17'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Building 17 - International & Global Center'), findsOneWidget);
    expect(find.text('Classrooms'), findsOneWidget);
    expect(find.text('Restrooms'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Navigate'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'AR Navigate'), findsOneWidget);
  });

  testWidgets('shows an error view for an unknown building id', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          buildingRepositoryProvider.overrideWithValue(_FakeBuildingRepository()),
          locationServiceProvider.overrideWithValue(_FakeLocationService()),
        ],
        child: const MaterialApp(
          home: BuildingDetailScreen(buildingId: 'does-not-exist'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('That destination is not available right now.'), findsOneWidget);
  });
}
