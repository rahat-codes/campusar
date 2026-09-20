import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:campusar/core/errors/app_failure.dart';
import 'package:campusar/data/models/building.dart';
import 'package:campusar/features/ar/providers/ar_providers.dart';
import 'package:campusar/features/ar/services/ar_navigation_service.dart';
import 'package:campusar/shared/widgets/error_view.dart';
import 'package:campusar/shared/widgets/loading_view.dart';

/// AR navigation screen (section 15 of the product spec).
///
/// IMPORTANT — this uses GPS + compass heading only. It does NOT claim
/// centimeter-accurate outdoor positioning: consumer GPS is typically
/// accurate to ~3-8m and phone compasses can drift, especially indoors or
/// near metal. The directional indicator shows the destination's
/// *approximate* direction, not a precisely anchored AR marker. See
/// features/ar/services/ar_navigation_service.dart for the abstraction
/// that a future ARCore/ARKit/VPS/beacon-based implementation would
/// replace this with, without changing this screen's UI.
class ArNavigationScreen extends ConsumerStatefulWidget {
  const ArNavigationScreen({super.key, required this.building});

  final Building building;

  @override
  ConsumerState<ArNavigationScreen> createState() => _ArNavigationScreenState();
}

class _ArNavigationScreenState extends ConsumerState<ArNavigationScreen> {
  CameraController? _cameraController;
  AppFailure? _cameraFailure;
  bool _cameraReady = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _cameraFailure = const ArUnsupportedFailure());
        return;
      }
      final controller = CameraController(
        cameras.first,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await controller.initialize();
      if (!mounted) return;
      setState(() {
        _cameraController = controller;
        _cameraReady = true;
      });
    } on CameraException {
      if (!mounted) return;
      setState(() => _cameraFailure = const CameraPermissionDeniedFailure());
    } catch (_) {
      if (!mounted) return;
      setState(() => _cameraFailure = const ArUnsupportedFailure());
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraFailure != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('AR Navigation')),
        body: ErrorView(failure: _cameraFailure!, onRetry: _initCamera),
      );
    }
    if (!_cameraReady) {
      return const Scaffold(body: LoadingView(message: 'Starting camera...'));
    }

    final destination = (
      latitude: widget.building.latitude,
      longitude: widget.building.longitude,
    );
    final guidanceAsync = ref.watch(arGuidanceProvider(destination));

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          CameraPreview(_cameraController!),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _RoundIconButton(
                    icon: Icons.close_rounded,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
          ),
          guidanceAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
            error: (_, __) => const Center(
              child: ErrorView(failure: LocationUnavailableFailure()),
            ),
            data: (frame) => _ArOverlay(
              building: widget.building,
              frame: frame,
            ),
          ),
        ],
      ),
    );
  }
}

class _ArOverlay extends StatelessWidget {
  const _ArOverlay({required this.building, required this.frame});

  final Building building;
  final ArGuidanceFrame frame;

  @override
  Widget build(BuildContext context) {
    final distance = frame.distanceMeters;
    final relativeBearing = frame.relativeBearingDegrees;
    final headingKnown = frame.headingAccuracyKnown;

    final distanceLabel =
        distance < 1000 ? '${distance.round()} m' : '${(distance / 1000).toStringAsFixed(1)} km';

    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Transform.rotate(
              angle: relativeBearing * math.pi / 180,
              child: const Icon(
                Icons.arrow_upward_rounded,
                size: 72,
                color: Colors.white,
                shadows: [Shadow(blurRadius: 12, color: Colors.black54)],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    building.name,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  Text(
                    distanceLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    relativeBearing.abs() < 20 ? 'Continue straight' : 'Recalculating direction...',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  if (!headingKnown) ...[
                    const SizedBox(height: 6),
                    const Text(
                      'Compass reading is unreliable — move to an open area.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.amberAccent, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: const BoxDecoration(color: Colors.black45, shape: BoxShape.circle),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }
}
