import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import 'package:campusar/core/services/location_service.dart';
import 'package:campusar/core/theme/app_theme.dart';
import 'package:campusar/data/models/building.dart';
import 'package:campusar/features/buildings/screens/building_detail_screen.dart';
import 'package:campusar/features/campus/providers/campus_providers.dart';
import 'package:campusar/features/navigation/providers/navigation_providers.dart';
import 'package:campusar/shared/widgets/building_card.dart';
import 'package:campusar/shared/widgets/error_view.dart';
import 'package:campusar/shared/widgets/loading_view.dart';
import 'package:campusar/core/errors/app_failure.dart';

/// Campus map (section 9 of the product spec). The map layer is isolated
/// to this one screen/widget so the tile provider (OpenStreetMap by
/// default, no Google Maps billing required) can be swapped later without
/// touching any other feature.
class CampusMapScreen extends ConsumerStatefulWidget {
  const CampusMapScreen({super.key});

  @override
  ConsumerState<CampusMapScreen> createState() => _CampusMapScreenState();
}

class _CampusMapScreenState extends ConsumerState<CampusMapScreen> {
  final _mapController = MapController();

  @override
  Widget build(BuildContext context) {
    final campusAsync = ref.watch(campusProvider);
    final buildingsAsync = ref.watch(allBuildingsProvider);
    final positionAsync = ref.watch(currentPositionProvider);
    final navState = ref.watch(navigationControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Campus Map')),
      body: campusAsync.when(
        loading: () => const LoadingView(),
        error: (_, __) => const ErrorView(failure: MapLoadFailure()),
        data: (campusResult) {
          final campus = campusResult.dataOrNull;
          if (campus == null) {
            return const ErrorView(failure: MapLoadFailure());
          }
          final config = campus.mapConfiguration;
          final center = LatLng(campus.latitude, campus.longitude);
          final position = positionAsync.valueOrNull;

          return buildingsAsync.when(
            loading: () => const LoadingView(),
            error: (_, __) => const ErrorView(failure: MapLoadFailure()),
            data: (buildings) {
              return FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: center,
                  initialZoom: config.defaultZoom,
                  minZoom: config.minZoom,
                  maxZoom: config.maxZoom,
                ),
                children: [
                  TileLayer(
                    urlTemplate: config.tileUrlTemplate,
                    userAgentPackageName: 'com.campusar.app',
                  ),
                  if (navState.isActive && navState.routeNodes.length > 1)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: navState.routeNodes
                              .map((n) => LatLng(n.latitude, n.longitude))
                              .toList(),
                          strokeWidth: 4,
                          color: AppTheme.routeAccent,
                        ),
                      ],
                    ),
                  MarkerLayer(
                    markers: [
                      for (final b in buildings)
                        Marker(
                          point: LatLng(b.latitude, b.longitude),
                          width: 40,
                          height: 40,
                          child: GestureDetector(
                            onTap: () => _showBuildingSheet(context, b),
                            child: _BuildingPin(
                              label: b.buildingNumber,
                            ),
                          ),
                        ),
                      if (position != null)
                        Marker(
                          point: LatLng(position.latitude, position.longitude),
                          width: 24,
                          height: 24,
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Theme.of(context).colorScheme.primary,
                              border: Border.all(color: Colors.white, width: 3),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  void _showBuildingSheet(BuildContext context, Building building) {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.all(16),
        child: BuildingCard(
          title: '${building.shortName} · Bldg ${building.buildingNumber}',
          subtitle: building.name,
          onTap: () {
            Navigator.of(sheetContext).pop();
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => BuildingDetailScreen(buildingId: building.id),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _BuildingPin extends StatelessWidget {
  const _BuildingPin({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.primary,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          color: scheme.onPrimary,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
