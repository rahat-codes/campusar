import 'package:campusar/shared/widgets/building_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('BuildingCard shows title, subtitle, and distance', (tester) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BuildingCard(
            title: 'Global Center',
            subtitle: 'Building 17 - International & Global Center',
            distanceMeters: 180,
            onTap: () => tapped = true,
          ),
        ),
      ),
    );

    expect(find.text('Global Center'), findsOneWidget);
    expect(find.text('Building 17 - International & Global Center'), findsOneWidget);
    expect(find.text('180 m'), findsOneWidget);

    await tester.tap(find.byType(BuildingCard));
    expect(tapped, isTrue);
  });

  testWidgets('BuildingCard formats distances over 1km in kilometers', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: BuildingCard(
            title: 'Dormitory A',
            subtitle: 'Building 20',
            distanceMeters: 1450,
          ),
        ),
      ),
    );

    expect(find.text('1.5 km'), findsOneWidget);
  });

  testWidgets('BuildingCard omits distance label when null', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: BuildingCard(title: 'Library', subtitle: 'Building 10'),
        ),
      ),
    );

    expect(find.textContaining(' m'), findsNothing);
    expect(find.textContaining(' km'), findsNothing);
  });
}
