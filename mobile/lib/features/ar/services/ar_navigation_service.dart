import 'dart:async';

import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';

import 'package:campusar/core/errors/app_failure.dart';
import 'package:campusar/core/utilities/geo_utils.dart';
import 'package:campusar/core/utilities/result.dart';

/// A single frame of AR navigation guidance: where the destination is
/// relative to the device, and how far away it is.
class ArGuidanceFrame {
  const ArGuidanceFrame({
    required this.destinationBearingDegrees,
    required this.deviceHeadingDegrees,
    required this.relativeBearingDegrees,
    required this.distanceMeters,
    required this.headingAccuracyKnown,
  });

  /// True compass bearing from the user to the destination (0-360).
  final double destinationBearingDegrees;

  /// Device's current compass heading (0-360).
  final double deviceHeadingDegrees;

  /// Signed angle (-180..180) the user needs to turn: negative = turn
  /// left, positive = turn right, ~0 = destination is straight ahead.
  /// This is what drives the directional arrow's rotation.
  final double relativeBearingDegrees;

  final double distanceMeters;

  /// Whether the compass reading this frame is based on is considered
  /// reliable. When false, the UI should show a "point your phone
  /// forward / move to an open area" hint rather than trusting the arrow.
  final bool headingAccuracyKnown;
}

/// Abstraction over AR navigation guidance.
///
/// V1 implementation ("GPS + compass AR"): combines the device's GPS
/// position and magnetometer-based compass heading to compute a relative
/// bearing to the destination, then overlays a directional indicator on
/// the live camera feed. This is deliberately NOT presented as precise
/// positioning — outdoor GPS is typically accurate to only ~3-8m and
/// consumer compasses can drift, especially indoors or near metal/magnets.
///
/// This interface is the seam for future, more accurate implementations:
///   - ARCore Geospatial API / ARKit Geo-anchors (VPS-based positioning)
///   - Visual anchors placed at building entrances
///   - QR-code markers at fixed campus locations
///   - BLE beacons for indoor micro-positioning
/// A future implementation can satisfy this same interface (or an
/// extended one) and swap in without changing the AR screen's UI code.
abstract class ArNavigationService {
  /// Whether this device can plausibly support the AR navigation screen
  /// (has a magnetometer for compass heading). Does not guarantee
  /// ARCore/ARKit availability — see [ArUnsupportedFailure] usage in the
  /// screen for the graceful fallback message.
  Future<bool> isSupported();

  Future<Result<bool>> requestCameraPermission();

  /// Stream of guidance frames, recomputed whenever position or heading
  /// updates. Never throws; if a reading temporarily fails, the previous
  /// frame's values are held rather than gaps appearing.
  Stream<ArGuidanceFrame> guidanceStream({
    required double destinationLatitude,
    required double destinationLongitude,
  });
}

/// GPS + compass implementation — the "maximum reliable functionality
/// available" for V1 per the product spec (section 15). Camera permission
/// itself is requested by the AR screen via the `camera` plugin directly
/// (kept out of this service so it stays testable without a real camera).
class GpsCompassArNavigationService implements ArNavigationService {
  GpsCompassArNavigationService();

  @override
  Future<bool> isSupported() async {
    // FlutterCompass.events is null on devices with no magnetometer.
    return FlutterCompass.events != null;
  }

  @override
  Future<Result<bool>> requestCameraPermission() async {
    // Actual camera permission handshake happens through the `camera`
    // plugin's availableCameras()/CameraController.initialize() in the AR
    // screen, which surfaces a CameraException on denial; the screen maps
    // that to CameraPermissionDeniedFailure. This method exists so the
    // service interface is self-contained for a future implementation
    // that manages its own camera/AR session lifecycle.
    return Result.success(true);
  }

  @override
  Stream<ArGuidanceFrame> guidanceStream({
    required double destinationLatitude,
    required double destinationLongitude,
  }) {
    final controller = StreamController<ArGuidanceFrame>.broadcast();

    double? lastLat;
    double? lastLon;
    double? lastHeading;
    bool headingKnown = false;

    void emit() {
      if (lastLat == null || lastLon == null) return;
      final bearing = GeoUtils.bearingDegrees(
        lastLat!,
        lastLon!,
        destinationLatitude,
        destinationLongitude,
      );
      final distance = GeoUtils.haversineDistanceMeters(
        lastLat!,
        lastLon!,
        destinationLatitude,
        destinationLongitude,
      );
      final heading = lastHeading ?? 0;
      controller.add(
        ArGuidanceFrame(
          destinationBearingDegrees: bearing,
          deviceHeadingDegrees: heading,
          relativeBearingDegrees:
              GeoUtils.angleDifferenceDegrees(heading, bearing),
          distanceMeters: distance,
          headingAccuracyKnown: headingKnown,
        ),
      );
    }

    final positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 1,
      ),
    ).listen((position) {
      lastLat = position.latitude;
      lastLon = position.longitude;
      emit();
    });

    final compassSub = FlutterCompass.events?.listen((event) {
      if (event.heading == null) {
        headingKnown = false;
        return;
      }
      lastHeading = event.heading;
      headingKnown = true;
      emit();
    });

    controller.onCancel = () {
      positionSub.cancel();
      compassSub?.cancel();
    };

    return controller.stream;
  }
}
