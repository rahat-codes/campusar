import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:campusar/core/constants/app_constants.dart';
import 'package:campusar/core/theme/app_theme.dart';
import 'package:campusar/features/ar/screens/ar_hub_screen.dart';
import 'package:campusar/features/buildings/screens/building_search_screen.dart';
import 'package:campusar/features/campus/screens/campus_map_screen.dart';
import 'package:campusar/features/campus/screens/home_screen.dart';
import 'package:campusar/features/settings/providers/settings_providers.dart';
import 'package:campusar/features/settings/screens/settings_screen.dart';

void main() {
  runApp(const ProviderScope(child: CampusArApp()));
}

class CampusArApp extends ConsumerWidget {
  const CampusArApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: const AppShell(),
    );
  }
}

/// Bottom-navigation shell: Home / Map / Buildings / AR / Settings
/// (section 21 of the product spec's "Primary navigation").
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  static const _screens = [
    HomeScreen(),
    CampusMapScreen(),
    BuildingSearchScreen(),
    ArHubScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map_rounded),
            label: 'Map',
          ),
          NavigationDestination(
            icon: Icon(Icons.apartment_outlined),
            selectedIcon: Icon(Icons.apartment_rounded),
            label: 'Buildings',
          ),
          NavigationDestination(
            icon: Icon(Icons.view_in_ar_outlined),
            selectedIcon: Icon(Icons.view_in_ar_rounded),
            label: 'AR',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
