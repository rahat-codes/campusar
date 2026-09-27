import 'package:campusar/core/utilities/direction_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DirectionThresholds.classify', () {
    const t = DirectionThresholds.defaults;

    test('near-zero relative bearing is straight', () {
      expect(t.classify(0), RelativeDirection.straight);
      expect(t.classify(10), RelativeDirection.straight);
      expect(t.classify(-10), RelativeDirection.straight);
    });

    test('moderate positive bearing is slightly right, negative is slightly left', () {
      expect(t.classify(30), RelativeDirection.slightlyRight);
      expect(t.classify(-30), RelativeDirection.slightlyLeft);
    });

    test('large positive bearing is right, negative is left', () {
      expect(t.classify(90), RelativeDirection.right);
      expect(t.classify(-90), RelativeDirection.left);
    });

    test('bearing near 180 in either direction is a U-turn', () {
      expect(t.classify(170), RelativeDirection.uTurn);
      expect(t.classify(-170), RelativeDirection.uTurn);
      expect(t.classify(180), RelativeDirection.uTurn);
    });

    test('custom thresholds change the buckets', () {
      const custom = DirectionThresholds(
        straightMaxDegrees: 5,
        slightMaxDegrees: 20,
        uTurnMinDegrees: 160,
      );
      expect(custom.classify(10), RelativeDirection.slightlyRight);
      expect(custom.classify(3), RelativeDirection.straight);
    });
  });

  group('hasArrivedAtDestination', () {
    test('is true at or below the threshold', () {
      expect(hasArrivedAtDestination(5, thresholdMeters: 8), isTrue);
      expect(hasArrivedAtDestination(8, thresholdMeters: 8), isTrue);
    });

    test('is false above the threshold', () {
      expect(hasArrivedAtDestination(9, thresholdMeters: 8), isFalse);
    });

    test('uses AppConstants.arrivalThresholdMeters by default', () {
      expect(hasArrivedAtDestination(3), isTrue);
      expect(hasArrivedAtDestination(500), isFalse);
    });
  });
}
