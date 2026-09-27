import 'package:campusar/core/errors/app_failure.dart';
import 'package:campusar/core/services/location_service.dart';
import 'package:campusar/core/utilities/result.dart';
import 'package:campusar/data/models/building.dart';
import 'package:campusar/features/navigation/screens/navigation_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';

const _building = Building(
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
  facilityIds: [],
  accessibility: AccessibilityInfo(
    wheelchairAccessible: true,
    hasElevator: true,
    notes: '',
  ),
  destinationNodeId: 'node_dest_17',
  entranceNodeId: 'node_ent_17',
);

/// Fails immediately, with no real Geolocator plugin call, so the
/// navigation screen resolves straight to its error state.
class _FailingLocationService extends LocationService {
  @override
  Future<Result<bool>> requestPermission() async =>
      Result.failure(LocationPermissionDeniedFailure());

  @override
  Future<Result<Position>> getCurrentPosition() async =>
      Result.failure(LocationPermissionDeniedFailure());
}

void main() {
  testWidgets(
      'shows a friendly error (never a raw exception) when location is unavailable',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          locationServiceProvider.overrideWithValue(_FailingLocationService()),
        ],
        child: const MaterialApp(
          home: NavigationScreen(building: _building),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Location access is needed'),
      findsOneWidget,
    );
    expect(find.widgetWithText(FilledButton, 'Try again'), findsOneWidget);

    // Never shows a raw exception type/message.
    expect(find.textContaining('Exception'), findsNothing);
  });

  testWidgets('cancel button pops the screen', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          locationServiceProvider.overrideWithValue(_FailingLocationService()),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const NavigationScreen(building: _building),
                    ),
                  ),
                  child: const Text('Open navigation'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open navigation'));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationScreen), findsOneWidget);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Cancel navigation'));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationScreen), findsNothing);
  });
}
