import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:campusar/core/errors/app_failure.dart';
import 'package:campusar/features/ar/screens/ar_navigation_screen.dart';
import 'package:campusar/features/buildings/providers/building_providers.dart';
import 'package:campusar/features/navigation/screens/navigation_screen.dart';
import 'package:campusar/shared/widgets/error_view.dart';
import 'package:campusar/shared/widgets/loading_view.dart';

/// Building details (section 11 of the product spec). All sample data here
/// (description, facilities, accessibility notes) is clearly replaceable —
/// see assets/data/buildings.json and README "How to Replace Campus Data".
class BuildingDetailScreen extends ConsumerWidget {
  const BuildingDetailScreen({super.key, required this.buildingId});

  final String buildingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(buildingDetailProvider(buildingId));

    return Scaffold(
      appBar: AppBar(title: const Text('Building details')),
      body: detailAsync.when(
        loading: () => const LoadingView(),
        error: (_, __) => const ErrorView(
          failure: DestinationUnavailableFailure(),
        ),
        data: (detail) {
          if (detail == null) {
            return const ErrorView(failure: DestinationUnavailableFailure());
          }
          final building = detail.building;
          final theme = Theme.of(context);

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                building.name,
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                'Building ${building.buildingNumber} · ${building.floors} floors',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              if (detail.distanceMeters != null) ...[
                const SizedBox(height: 4),
                Text(
                  '${detail.distanceMeters!.round()} m from your location',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.primary),
                ),
              ],
              const SizedBox(height: 16),
              Text(building.description, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 20),
              Text('Facilities', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final f in detail.facilities) Chip(label: Text(f.name)),
                ],
              ),
              const SizedBox(height: 20),
              Text('Accessibility', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              _AccessibilityRow(
                icon: Icons.accessible_rounded,
                label: 'Wheelchair accessible',
                value: building.accessibility.wheelchairAccessible,
              ),
              _AccessibilityRow(
                icon: Icons.elevator_rounded,
                label: 'Elevator',
                value: building.accessibility.hasElevator,
              ),
              if (building.accessibility.notes.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  building.accessibility.notes,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
              const SizedBox(height: 28),
              FilledButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => NavigationScreen(building: building),
                  ),
                ),
                icon: const Icon(Icons.directions_walk_rounded),
                label: const Text('Navigate'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ArNavigationScreen(building: building),
                  ),
                ),
                icon: const Icon(Icons.view_in_ar_rounded),
                label: const Text('AR Navigate'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AccessibilityRow extends StatelessWidget {
  const _AccessibilityRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final bool value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
          Icon(
            value ? Icons.check_circle_rounded : Icons.cancel_rounded,
            size: 18,
            color: value ? theme.colorScheme.primary : theme.colorScheme.outline,
          ),
        ],
      ),
    );
  }
}
