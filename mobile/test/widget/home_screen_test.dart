import 'package:campusar/core/errors/app_failure.dart';
import 'package:campusar/core/services/location_service.dart';
import 'package:campusar/core/utilities/result.dart';
import 'package:campusar/data/models/campus.dart';
import 'package:campusar/data/repositories/campus_repository.dart';
import 'package:campusar/data/repositories/providers.dart';
import 'package:campusar/features/campus/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _campus = Campus(
  id: 'tongmyong-main',
  name: 'Tongmyong University',
  universityName: 'Tongmyong University',
  country: 'South Korea',
  city: 'Busan',
  latitude: 35.0952,
  longitude: 129.1004,
  mapConfiguration: MapConfiguration(
    defaultZoom: 17,
    minZoom: 15,
    maxZoom: 20,
    boundsNorthEastLat: 35.1005,
    boundsNorthEastLon: 129.1060,
    boundsSouthWestLat: 35.0900,
    boundsSouthWestLon: 129.0950,
    tileProvider: 'osm',
    tileUrlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
  ),
  version: '1.0.0',
);

class _FakeCampusRepository extends CampusRepository {
  @override
  Future<Result<Campus>> getCampus() async => Result.success(_campus);
}

/// Reports location as permanently unavailable so the home screen shows
/// its "turn on location" prompt instead of calling any real plugin.
class _FakeLocationService extends LocationService {
  @override
  Future<Result<bool>> requestPermission() async =>
      Result.failure(LocationPermissionDeniedFailure());
}

void main() {
  testWidgets('shows app name, subtitle, search prompt, and quick actions',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          campusRepositoryProvider.overrideWithValue(_FakeCampusRepository()),
          locationServiceProvider.overrideWithValue(_FakeLocationService()),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('CampusAR'), findsOneWidget);
    expect(find.text('Tongmyong University'), findsOneWidget);
    expect(find.text('Where do you want to go?'), findsOneWidget);

    expect(find.text('Campus Map'), findsOneWidget);
    expect(find.text('Buildings'), findsOneWidget);
    expect(find.text('Navigate'), findsOneWidget);
    expect(find.text('AR Mode'), findsOneWidget);

    // No location permission -> nearby section shows a prompt, not a crash.
    expect(find.text('Turn on location to see buildings near you.'), findsOneWidget);
  });

  testWidgets('tapping the search field opens building search', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          campusRepositoryProvider.overrideWithValue(_FakeCampusRepository()),
          locationServiceProvider.overrideWithValue(_FakeLocationService()),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Where do you want to go?'));
    await tester.pumpAndSettle();

    expect(find.text('Where do you want to go?'), findsNothing);
    expect(find.byType(TextField), findsOneWidget); // search screen's field
  });
}
