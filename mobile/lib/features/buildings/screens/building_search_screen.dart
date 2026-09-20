import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:campusar/features/ar/screens/ar_navigation_screen.dart';
import 'package:campusar/features/buildings/providers/building_providers.dart';
import 'package:campusar/features/buildings/screens/building_detail_screen.dart';
import 'package:campusar/features/navigation/screens/navigation_screen.dart';
import 'package:campusar/shared/widgets/building_card.dart';
import 'package:campusar/shared/widgets/error_view.dart';
import 'package:campusar/shared/widgets/loading_view.dart';
import 'package:campusar/core/errors/app_failure.dart';

/// Building search (section 10 of the product spec): by name, short name,
/// building number, or facility — e.g. "17" finds Building 17, "library"
/// finds the Central Library. Works fully offline.
///
/// When [navigateOnSelect] or [arOnSelect] is set (reached via the home
/// screen's "Navigate" / "AR Mode" quick actions), picking a result jumps
/// straight into that flow instead of the building detail screen.
class BuildingSearchScreen extends ConsumerStatefulWidget {
  const BuildingSearchScreen({
    super.key,
    this.navigateOnSelect = false,
    this.arOnSelect = false,
  });

  final bool navigateOnSelect;
  final bool arOnSelect;

  @override
  ConsumerState<BuildingSearchScreen> createState() =>
      _BuildingSearchScreenState();
}

class _BuildingSearchScreenState extends ConsumerState<BuildingSearchScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final resultsAsync = ref.watch(buildingSearchResultsProvider);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: !widget.navigateOnSelect && !widget.arOnSelect,
          decoration: const InputDecoration(
            hintText: 'Search by name, number, or facility',
            border: InputBorder.none,
          ),
          onChanged: (value) =>
              ref.read(buildingSearchQueryProvider.notifier).state = value,
        ),
      ),
      body: resultsAsync.when(
        loading: () => const LoadingView(),
        error: (_, __) =>
            const ErrorView(failure: CampusDataFailure('Search failed.')),
        data: (buildings) {
          if (buildings.isEmpty) {
            return const Center(child: Text('No buildings found.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: buildings.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final b = buildings[i];
              return BuildingCard(
                title: '${b.shortName} · Bldg ${b.buildingNumber}',
                subtitle: b.name,
                onTap: () {
                  if (widget.arOnSelect) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => ArNavigationScreen(building: b),
                      ),
                    );
                  } else if (widget.navigateOnSelect) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => NavigationScreen(building: b),
                      ),
                    );
                  } else {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => BuildingDetailScreen(buildingId: b.id),
                      ),
                    );
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}
