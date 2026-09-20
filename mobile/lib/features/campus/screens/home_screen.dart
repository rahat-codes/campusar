import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:campusar/core/constants/app_constants.dart';
import 'package:campusar/core/services/location_service.dart';
import 'package:campusar/features/buildings/providers/building_providers.dart';
import 'package:campusar/features/buildings/screens/building_detail_screen.dart';
import 'package:campusar/features/buildings/screens/building_search_screen.dart';
import 'package:campusar/features/campus/providers/campus_providers.dart';
import 'package:campusar/features/campus/screens/campus_map_screen.dart';
import 'package:campusar/shared/widgets/building_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final campusAsync = ref.watch(campusProvider);

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppConstants.appName,
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  campusAsync.when(
                    data: (result) => Text(
                      result.dataOrNull?.universityName ??
                          AppConstants.appSubtitle,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    loading: () => Text(AppConstants.appSubtitle),
                    error: (_, __) => Text(AppConstants.appSubtitle),
                  ),
                  const SizedBox(height: 20),
                  _SearchField(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const BuildingSearchScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const _QuickActions(),
                  const SizedBox(height: 24),
                  Text(
                    'Nearby',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          const _NearbySection(),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(Icons.search_rounded,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(width: 12),
            Text(
              'Where do you want to go?',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    final actions = [
      (
        icon: Icons.map_rounded,
        label: 'Campus Map',
        onTap: (BuildContext c) => Navigator.of(c).push(
          MaterialPageRoute(builder: (_) => const CampusMapScreen()),
        ),
      ),
      (
        icon: Icons.apartment_rounded,
        label: 'Buildings',
        onTap: (BuildContext c) => Navigator.of(c).push(
          MaterialPageRoute(builder: (_) => const BuildingSearchScreen()),
        ),
      ),
      (
        icon: Icons.directions_walk_rounded,
        label: 'Navigate',
        onTap: (BuildContext c) => Navigator.of(c).push(
          MaterialPageRoute(
            builder: (_) => const BuildingSearchScreen(navigateOnSelect: true),
          ),
        ),
      ),
      (
        icon: Icons.view_in_ar_rounded,
        label: 'AR Mode',
        onTap: (BuildContext c) => Navigator.of(c).push(
          MaterialPageRoute(
            builder: (_) => const BuildingSearchScreen(arOnSelect: true),
          ),
        ),
      ),
    ];

    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: [
        for (final a in actions)
          _QuickActionTile(icon: a.icon, label: a.label, onTap: () => a.onTap(context)),
      ],
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: scheme.onPrimaryContainer),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}

class _NearbySection extends ConsumerWidget {
  const _NearbySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final positionAsync = ref.watch(currentPositionProvider);

    return positionAsync.when(
      loading: () => const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (_, __) => const _NearbyPermissionPrompt(),
      data: (position) {
        if (position == null) return const _NearbyPermissionPrompt();

        final nearbyAsync = ref.watch(nearbyBuildingsProvider);
        return nearbyAsync.when(
          loading: () => const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
          error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
          data: (nearby) {
            if (nearby.isEmpty) {
              return const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Text('No buildings within range yet.'),
                ),
              );
            }
            return SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList.separated(
                itemCount: nearby.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final item = nearby[i];
                  return BuildingCard(
                    title: item.building.shortName,
                    subtitle: item.building.name,
                    distanceMeters: item.distanceMeters,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            BuildingDetailScreen(buildingId: item.building.id),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}

class _NearbyPermissionPrompt extends StatelessWidget {
  const _NearbyPermissionPrompt();

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.location_off_rounded,
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Turn on location to see buildings near you.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
