import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import 'package:campusar/core/constants/app_constants.dart';
import 'package:campusar/core/errors/app_failure.dart';
import 'package:campusar/core/services/location_service.dart';
import 'package:campusar/core/utilities/geo_utils.dart';
import 'package:campusar/data/models/building.dart';
import 'package:campusar/data/models/route_graph.dart';
import 'package:campusar/data/repositories/providers.dart';
import 'package:campusar/features/navigation/services/routing_service.dart';

enum NavigationStatus { idle, loading, active, recalculating, arrived, error }

class NavigationState {
  const NavigationState({
    this.status = NavigationStatus.idle,
    this.destination,
    this.routeNodes = const [],
    this.totalDistanceMeters = 0,
    this.remainingDistanceMeters = 0,
    this.estimatedWalkingTimeMinutes = 0,
    this.nextInstruction = '',
    this.failure,
  });

  final NavigationStatus status;
  final Building? destination;
  final List<RouteNode> routeNodes;
  final double totalDistanceMeters;
  final double remainingDistanceMeters;
  final double estimatedWalkingTimeMinutes;
  final String nextInstruction;
  final AppFailure? failure;

  bool get isActive =>
      status == NavigationStatus.active || status == NavigationStatus.recalculating;

  NavigationState copyWith({
    NavigationStatus? status,
    Building? destination,
    List<RouteNode>? routeNodes,
    double? totalDistanceMeters,
    double? remainingDistanceMeters,
    double? estimatedWalkingTimeMinutes,
    String? nextInstruction,
    AppFailure? failure,
  }) {
    return NavigationState(
      status: status ?? this.status,
      destination: destination ?? this.destination,
      routeNodes: routeNodes ?? this.routeNodes,
      totalDistanceMeters: totalDistanceMeters ?? this.totalDistanceMeters,
      remainingDistanceMeters:
          remainingDistanceMeters ?? this.remainingDistanceMeters,
      estimatedWalkingTimeMinutes:
          estimatedWalkingTimeMinutes ?? this.estimatedWalkingTimeMinutes,
      nextInstruction: nextInstruction ?? this.nextInstruction,
      failure: failure,
    );
  }
}

/// Drives the navigation screen: computes an initial route, then tracks the
/// user's live position, updating remaining distance/time. If the user
/// drifts more than [AppConstants.routeDeviationThresholdMeters] away from
/// the route, it recalculates a fresh route from the new position (section
/// 14 of the product spec: "Recalculating route...").
class NavigationController extends StateNotifier<NavigationState> {
  NavigationController(this._ref) : super(const NavigationState());

  final Ref _ref;
  StreamSubscription<Position>? _positionSub;
  RoutingService? _routingService;

  Future<void> startNavigation(Building destination) async {
    state = NavigationState(
      status: NavigationStatus.loading,
      destination: destination,
    );

    if (destination.destinationNodeId == null) {
      state = state.copyWith(
        status: NavigationStatus.error,
        failure: const DestinationUnavailableFailure(),
      );
      return;
    }

    final locationService = _ref.read(locationServiceProvider);
    final positionResult = await locationService.getCurrentPosition();
    if (positionResult.isFailure) {
      state = state.copyWith(
        status: NavigationStatus.error,
        failure: positionResult.failureOrNull,
      );
      return;
    }
    final position = positionResult.dataOrNull!;

    final graphRepo = _ref.read(routeGraphRepositoryProvider);
    final (nodes, edges) = await graphRepo.getGraph();
    _routingService = RoutingService(nodes, edges);

    _computeRoute(
      destination,
      fromLatitude: position.latitude,
      fromLongitude: position.longitude,
    );

    _positionSub?.cancel();
    _positionSub = locationService.watchPosition().listen(_onPositionUpdate);
  }

  void _computeRoute(
    Building destination, {
    required double fromLatitude,
    required double fromLongitude,
  }) {
    try {
      final result = _routingService!.findRoute(
        fromLatitude: fromLatitude,
        fromLongitude: fromLongitude,
        toNodeId: destination.destinationNodeId!,
      );
      state = state.copyWith(
        status: NavigationStatus.active,
        routeNodes: result.nodes,
        totalDistanceMeters: result.totalDistanceMeters,
        remainingDistanceMeters: result.totalDistanceMeters,
        estimatedWalkingTimeMinutes: result.estimatedWalkingTimeMinutes,
        nextInstruction: _instructionFor(result.nodes),
      );
    } on RouteNotFoundException {
      state = state.copyWith(
        status: NavigationStatus.error,
        failure: const RouteNotFoundFailure(),
      );
    }
  }

  void _onPositionUpdate(Position position) {
    final destination = state.destination;
    if (destination == null || !state.isActive) return;

    if (state.routeNodes.isEmpty) return;
    final nearestOnRoute = state.routeNodes
        .map((n) => GeoUtils.haversineDistanceMeters(
              position.latitude,
              position.longitude,
              n.latitude,
              n.longitude,
            ))
        .reduce((a, b) => a < b ? a : b);

    if (nearestOnRoute > AppConstants.routeDeviationThresholdMeters) {
      state = state.copyWith(status: NavigationStatus.recalculating);
      _computeRoute(
        destination,
        fromLatitude: position.latitude,
        fromLongitude: position.longitude,
      );
      return;
    }

    final destinationNode = state.routeNodes.last;
    final remaining = GeoUtils.haversineDistanceMeters(
      position.latitude,
      position.longitude,
      destinationNode.latitude,
      destinationNode.longitude,
    );

    if (remaining <= AppConstants.arrivalThresholdMeters) {
      state = state.copyWith(
        status: NavigationStatus.arrived,
        remainingDistanceMeters: 0,
        nextInstruction: 'You have arrived',
      );
      return;
    }

    state = state.copyWith(
      status: NavigationStatus.active,
      remainingDistanceMeters: remaining,
    );
  }

  String _instructionFor(List<RouteNode> nodes) {
    if (nodes.length <= 1) return 'You have arrived';
    return 'Continue straight';
  }

  void cancelNavigation() {
    _positionSub?.cancel();
    _positionSub = null;
    state = const NavigationState();
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    super.dispose();
  }
}

final navigationControllerProvider =
    StateNotifierProvider<NavigationController, NavigationState>((ref) {
  return NavigationController(ref);
});
