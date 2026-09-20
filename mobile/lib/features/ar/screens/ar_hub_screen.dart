import 'package:flutter/material.dart';

import 'package:campusar/features/buildings/screens/building_search_screen.dart';

/// Landing content for the "AR" bottom-nav tab. AR guidance always needs a
/// destination, so this screen just prompts the user to pick a building —
/// picking one jumps straight into [ArNavigationScreen] (see
/// features/buildings/screens/building_search_screen.dart, arOnSelect).
class ArHubScreen extends StatelessWidget {
  const ArHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('AR Navigation')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.view_in_ar_rounded,
                  size: 64, color: theme.colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                'Point your camera and follow the arrow',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Choose a building to start AR-guided walking directions.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const BuildingSearchScreen(arOnSelect: true),
                  ),
                ),
                icon: const Icon(Icons.search_rounded),
                label: const Text('Choose destination'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
