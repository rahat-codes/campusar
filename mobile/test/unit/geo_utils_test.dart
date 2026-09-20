import 'package:campusar/core/utilities/geo_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GeoUtils.haversineDistanceMeters', () {
    test('is zero for the same point', () {
      final d = GeoUtils.haversineDistanceMeters(35.0952, 129.1004, 35.0952, 129.1004);
      expect(d, 0);
    });

    test('one degree of latitude is ~111km', () {
      final d = GeoUtils.haversineDistanceMeters(0, 0, 1, 0);
      expect(d, closeTo(111195, 1200));
    });
  });

  group('GeoUtils.bearingDegrees', () {
    test('due north is ~0 degrees', () {
      final b = GeoUtils.bearingDegrees(35.0, 129.0, 35.001, 129.0);
      expect(b, closeTo(0, 1));
    });

    test('due east is ~90 degrees', () {
      final b = GeoUtils.bearingDegrees(35.0, 129.0, 35.0, 129.001);
      expect(b, closeTo(90, 1));
    });

    test('due south is ~180 degrees', () {
      final b = GeoUtils.bearingDegrees(35.001, 129.0, 35.0, 129.0);
      expect(b, closeTo(180, 1));
    });
  });

  group('GeoUtils.angleDifferenceDegrees', () {
    test('returns 0 for identical bearings', () {
      expect(GeoUtils.angleDifferenceDegrees(90, 90), 0);
    });

    test('wraps correctly across the 0/360 boundary', () {
      expect(GeoUtils.angleDifferenceDegrees(350, 10), closeTo(20, 0.001));
      expect(GeoUtils.angleDifferenceDegrees(10, 350), closeTo(-20, 0.001));
    });

    test('is within -180..180', () {
      final diff = GeoUtils.angleDifferenceDegrees(0, 179);
      expect(diff, closeTo(179, 0.001));
    });
  });

  group('GeoUtils.estimateWalkingTimeSeconds', () {
    test('computes distance / speed', () {
      expect(
        GeoUtils.estimateWalkingTimeSeconds(130, walkingSpeedMetersPerSecond: 1.3),
        closeTo(100, 0.001),
      );
    });

    test('is zero for zero distance', () {
      expect(GeoUtils.estimateWalkingTimeSeconds(0), 0);
    });
  });
}
