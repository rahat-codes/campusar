import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:campusar/core/errors/app_failure.dart';
import 'package:campusar/core/utilities/direction_utils.dart';
import 'package:campusar/data/models/building.dart';
import 'package:campusar/features/ar/providers/ar_providers.dart';
import 'package:campusar/features/ar/services/ar_navigation_service.dart';
import 'package:campusar/shared/widgets/error_view.dart';
import 'package:campusar/shared/widgets/loading_view.dart';

/// AR navigation screen (product spec sections 16-22: "AR is the most
/// important feature after routing").
///
/// IMPORTANT — this uses GPS + compass heading only. It does NOT claim
/// centimeter-accurate outdoor positioning: consumer GPS is typically
/// accurate to ~3-8m and phone compasses can drift, especially indoors or
/// near metal. The directional indicator shows the destination's
/// *approximate* direction, not a precisely anchored AR marker. See
/// features/ar/services/ar_navigation_service.dart for the abstraction
/// that a future ARCore/ARKit/VPS/beacon-based implementation would
/// replace this with, without changing this screen's UI.
///
/// Camera is optional, not required (section 22: "AR should enhance
/// navigation, not make the entire application unusable"). If the camera
/// is denied/unavailable, this screen falls back to
/// [_DirectionOnlyGuidance] — the same distance/direction/arrival logic,
/// just without the live camera background.
class ArNavigationScreen extends ConsumerStatefulWidget {
  const ArNavigationScreen({super.key, required this.building});

  final Building building;

  @override
  ConsumerState<ArNavigationScreen> createState() => _ArNavigationScreenState();
}

class _ArNavigationScreenState extends ConsumerState<ArNavigationScreen> {
  CameraController? _cameraController;
  bool _cameraReady = false;
  bool _cameraUnavailable = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    setState(() => _cameraUnavailable = false);
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (!mounted) return;
        setState(() => _cameraUnavailable = true);
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
    } catch (_) {
      // Camera permission denied, no camera hardware, or any other camera
      // failure: fall back to the non-camera directional screen rather
      // than blocking navigation (section 22 of the product spec).
      if (!mounted) return;
      setState(() => _cameraUnavailable = true);
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final destination = (
      latitude: widget.building.latitude,
      longitude: widget.building.longitude,
    );
    final guidanceAsync = ref.watch(arGuidanceProvider(destination));

    // Camera unavailable/denied: fall back to a plain directional screen
    // (arrow + distance + building name), no camera preview. This still
    // detects arrival and shows direction — only the camera background is
    // missing (section 22).
    if (_cameraUnavailable) {
      return Scaffold(
        appBar: AppBar(title: const Text('Navigation')),
        body: guidanceAsync.when(
          loading: () => const LoadingView(),
          error: (_, __) => const ErrorView(failure: LocationUnavailableFailure()),
          data: (frame) => _DirectionOnlyGuidance(
            building: widget.building,
            frame: frame,
            onRetryCamera: _initCamera,
          ),
        ),
      );
    }

    if (!_cameraReady) {
      return const Scaffold(body: LoadingView(message: 'Starting camera...'));
    }

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

/// Shared "have we arrived, and if not, which way" content, driven purely
/// by an [ArGuidanceFrame] — used both inside the camera overlay
/// ([_ArOverlay]) and the no-camera fallback ([_DirectionOnlyGuidance]),
/// so arrival detection and direction wording never drift between them.
class _GuidanceContent extends StatelessWidget {
  const _GuidanceContent({
    required this.building,
    required this.frame,
    required this.textColor,
    required this.mutedTextColor,
    required this.arrowColor,
  });

  final Building building;
  final ArGuidanceFrame frame;
  final Color textColor;
  final Color mutedTextColor;
  final Color arrowColor;

  @override
  Widget build(BuildContext context) {
    final distance = frame.distanceMeters;
    final arrived = hasArrivedAtDestination(distance);

    if (arrived) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_rounded, size: 64, color: arrowColor),
          const SizedBox(height: 12),
          Text(
            'You have arrived',
            style: TextStyle(color: textColor, fontSize: 22, fontWeight: FontWeight.w700),
          ),
          Text(building.name, style: TextStyle(color: mutedTextColor, fontSize: 15)),
        ],
      );
    }

    final direction = DirectionThresholds.defaults.classify(frame.relativeBearingDegrees);
    final distanceLabel =
        distance < 1000 ? '${distance.round()} m' : '${(distance / 1000).toStringAsFixed(1)} km';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // A single rotating up-arrow correctly represents every case,
        // including a U-turn (relative bearing near +-180 simply points
        // the arrow downward) — no separate icon needed.
        Transform.rotate(
          angle: frame.relativeBearingDegrees * math.pi / 180,
          child: Icon(
            Icons.arrow_upward_rounded,
            size: 72,
            color: arrowColor,
            shadows: const [Shadow(blurRadius: 12, color: Colors.black54)],
          ),
        ),
        const SizedBox(height: 12),
        Text(building.name, style: TextStyle(color: textColor, fontSize: 16)),
        Text(
          distanceLabel,
          style: TextStyle(color: textColor, fontSize: 28, fontWeight: FontWeight.w700),
        ),
        Text(direction.label, style: TextStyle(color: mutedTextColor, fontSize: 14)),
        if (!frame.headingAccuracyKnown) ...[
          const SizedBox(height: 6),
          const Text(
            'Compass reading is unreliable — move to an open area.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.amberAccent, fontSize: 12),
          ),
        ],
      ],
    );
  }
}

class _ArOverlay extends StatelessWidget {
  const _ArOverlay({required this.building, required this.frame});

  final Building building;
  final ArGuidanceFrame frame;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 48),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(16)),
          child: _GuidanceContent(
            building: building,
            frame: frame,
            textColor: Colors.white,
            mutedTextColor: Colors.white70,
            arrowColor: Colors.white,
          ),
        ),
      ),
    );
  }
}

/// Non-camera fallback (section 22 of the product spec): same
/// distance/direction/arrival guidance as [_ArOverlay], laid out on a
/// plain background instead of a camera preview.
class _DirectionOnlyGuidance extends StatelessWidget {
  const _DirectionOnlyGuidance({
    required this.building,
    required this.frame,
    required this.onRetryCamera,
  });

  final Building building;
  final ArGuidanceFrame frame;
  final VoidCallback onRetryCamera;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _GuidanceContent(
              building: building,
              frame: frame,
              textColor: scheme.onSurface,
              mutedTextColor: scheme.onSurfaceVariant,
              arrowColor: scheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'Camera unavailable — showing direction only.',
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
            ),
            const SizedBox(height: 8),
            TextButton(onPressed: onRetryCamera, child: const Text('Try camera again')),
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
