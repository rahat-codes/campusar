import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:campusar/core/constants/app_constants.dart';
import 'package:campusar/core/services/location_service.dart';
import 'package:campusar/data/local/app_database.dart';
import 'package:campusar/features/settings/providers/settings_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final campusAsync = ref.watch(settingsCampusProvider);
    final versionAsync = ref.watch(appVersionProvider);
    final positionAsync = ref.watch(currentPositionProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const _SectionHeader('Appearance'),
          RadioListTile<ThemeMode>(
            title: const Text('System default'),
            value: ThemeMode.system,
            groupValue: themeMode,
            onChanged: (v) =>
                ref.read(themeModeProvider.notifier).setThemeMode(v!),
          ),
          RadioListTile<ThemeMode>(
            title: const Text('Light'),
            value: ThemeMode.light,
            groupValue: themeMode,
            onChanged: (v) =>
                ref.read(themeModeProvider.notifier).setThemeMode(v!),
          ),
          RadioListTile<ThemeMode>(
            title: const Text('Dark'),
            value: ThemeMode.dark,
            groupValue: themeMode,
            onChanged: (v) =>
                ref.read(themeModeProvider.notifier).setThemeMode(v!),
          ),
          const Divider(),
          const _SectionHeader('Status'),
          ListTile(
            leading: const Icon(Icons.my_location_rounded),
            title: const Text('Location permission'),
            subtitle: positionAsync.when(
              data: (p) => Text(p != null ? 'Granted' : 'Not available'),
              loading: () => const Text('Checking...'),
              error: (_, __) => const Text('Not granted'),
            ),
          ),
          FutureBuilder<bool>(
            future: AppDatabase.instance.isSeeded(),
            builder: (context, snapshot) => ListTile(
              leading: const Icon(Icons.offline_pin_rounded),
              title: const Text('Offline data status'),
              subtitle: Text(
                snapshot.data == true
                    ? 'Campus data available offline'
                    : 'Not yet downloaded',
              ),
            ),
          ),
          const Divider(),
          const _SectionHeader('Campus'),
          campusAsync.when(
            data: (result) {
              final campus = result.dataOrNull;
              if (campus == null) {
                return const ListTile(title: Text('No campus data loaded'));
              }
              return Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.school_rounded),
                    title: Text(campus.universityName),
                    subtitle: Text('${campus.city}, ${campus.country}'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.dataset_rounded),
                    title: const Text('Data version'),
                    subtitle: Text(campus.version),
                  ),
                ],
              );
            },
            loading: () => const ListTile(title: Text('Loading campus...')),
            error: (_, __) =>
                const ListTile(title: Text('Campus data unavailable')),
          ),
          const Divider(),
          const _SectionHeader('About'),
          ListTile(
            leading: const Icon(Icons.info_outline_rounded),
            title: Text(AppConstants.appName),
            subtitle: Text(AppConstants.appSubtitle),
          ),
          ListTile(
            leading: const Icon(Icons.tag_rounded),
            title: const Text('App version'),
            subtitle: versionAsync.when(
              data: (v) => Text(v),
              loading: () => const Text('...'),
              error: (_, __) => const Text('Unknown'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
