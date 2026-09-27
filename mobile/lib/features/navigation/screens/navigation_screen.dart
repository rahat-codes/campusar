import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:campusar/data/models/building.dart';
import 'package:campusar/features/navigation/providers/navigation_providers.dart';
import 'package:campusar/shared/widgets/error_view.dart';

/// Live turn-by-turn-style navigation (section 14 of the product spec).
/// Distance/time are computed by the on-device A* routing engine, not
/// hardcoded, and update as the user moves. If the user strays off the
/// route, this screen shows "Recalculating route..." and a fresh route is
/// computed automatically.
class NavigationScreen extends ConsumerStatefulWidget {
  const NavigationScreen({super.key, required this.building});

  final Building building;

  @override
  ConsumerState<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends ConsumerState<NavigationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(navigationControllerProvider.notifier).startNavigation(widget.building);
    });
  }

  @override
  void dispose() {
    ref.read(navigationControllerProvider.notifier).cancelNavigation();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(navigationControllerProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text('Navigate to ${widget.building.shortName}')),
      body: switch (state.status) {
        NavigationStatus.idle ||
        NavigationStatus.loading =>
          const Center(child: CircularProgressIndicator()),
        NavigationStatus.error => Center(
            child: ErrorView(
              failure: state.failure!,
              onRetry: () => ref
                  .read(navigationControllerProvider.notifier)
                  .startNavigation(widget.building),
            ),
          ),
        NavigationStatus.active ||
        NavigationStatus.recalculating ||
        NavigationStatus.arrived =>
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (state.status == NavigationStatus.recalculating) ...[
                  const CircularProgressIndicator(),
                  const SizedBox(height: 12),
                  Text('Recalculating route...', style: theme.textTheme.titleMedium),
                ] else if (state.status == NavigationStatus.arrived) ...[
                  Icon(Icons.check_circle_rounded,
                      size: 64, color: theme.colorScheme.primary),
                  const SizedBox(height: 12),
                  Text('You have arrived', style: theme.textTheme.headlineSmall),
                  Text(widget.building.name, style: theme.textTheme.bodyMedium),
                ] else ...[
                  Text(
                    '${state.remainingDistanceMeters.round()} m remaining',
                    style: theme.textTheme.headlineMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '≈ ${state.estimatedWalkingTimeMinutes.round()} min walk',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(Icons.straight_rounded,
                              color: theme.colorScheme.primary),
                          const SizedBox(width: 12),
                          Text(state.nextInstruction,
                              style: theme.textTheme.titleMedium),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                OutlinedButton.icon(
                  onPressed: () {
                    ref.read(navigationControllerProvider.notifier).cancelNavigation();
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.close_rounded),
                  label: const Text('Cancel navigation'),
                ),
              ],
            ),
          ),
      },
    );
  }
}
