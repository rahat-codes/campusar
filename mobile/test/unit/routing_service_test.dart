import 'package:campusar/data/models/route_graph.dart';
import 'package:campusar/features/navigation/services/routing_service.dart';
import 'package:flutter_test/flutter_test.dart';

RoutingService _buildSimpleGraph() {
  // A --5m-- B --5m-- C   (straight line, 10m total A->C)
  //          |
  //         10m (inaccessible)
  //          |
  //          D
  final nodes = [
    const RouteNode(id: 'A', latitude: 35.0, longitude: 129.0, type: RouteNodeType.pathway),
    const RouteNode(id: 'B', latitude: 35.00004, longitude: 129.0, type: RouteNodeType.intersection),
    const RouteNode(id: 'C', latitude: 35.00009, longitude: 129.0, type: RouteNodeType.destination),
    const RouteNode(id: 'D', latitude: 35.00004, longitude: 129.0001, type: RouteNodeType.destination),
  ];
  final edges = [
    const RouteEdge(id: 'e1', fromNode: 'A', toNode: 'B', distance: 5.0, accessible: true, indoor: false, outdoor: true),
    const RouteEdge(id: 'e2', fromNode: 'B', toNode: 'C', distance: 5.0, accessible: true, indoor: false, outdoor: true),
    const RouteEdge(id: 'e3', fromNode: 'B', toNode: 'D', distance: 10.0, accessible: false, indoor: false, outdoor: true),
  ];
  return RoutingService(nodes, edges);
}

void main() {
  group('RoutingService.findRoute', () {
    test('finds the shortest path along a simple line', () {
      final service = _buildSimpleGraph();
      final result = service.findRoute(fromLatitude: 35.0, fromLongitude: 129.0, toNodeId: 'C');
      expect(result.nodes.map((n) => n.id).toList(), ['A', 'B', 'C']);
      expect(result.totalDistanceMeters, 10.0);
      expect(result.estimatedWalkingTimeSeconds, greaterThan(0));
    });

    test('snaps the start position to the nearest node', () {
      final service = _buildSimpleGraph();
      final result = service.findRoute(
        fromLatitude: 35.000001,
        fromLongitude: 129.000001,
        toNodeId: 'C',
      );
      expect(result.nodes.first.id, 'A');
      expect(result.nodes.last.id, 'C');
    });

    test('accessibleOnly excludes inaccessible edges', () {
      final service = _buildSimpleGraph();
      expect(
        () => service.findRoute(
          fromLatitude: 35.0,
          fromLongitude: 129.0,
          toNodeId: 'D',
          accessibleOnly: true,
        ),
        throwsA(isA<RouteNotFoundException>()),
      );

      final result = service.findRoute(
        fromLatitude: 35.0,
        fromLongitude: 129.0,
        toNodeId: 'D',
        accessibleOnly: false,
      );
      expect(result.nodes.map((n) => n.id).toList(), ['A', 'B', 'D']);
    });

    test('throws for an unknown destination node', () {
      final service = _buildSimpleGraph();
      expect(
        () => service.findRoute(fromLatitude: 35.0, fromLongitude: 129.0, toNodeId: 'Z'),
        throwsA(isA<RouteNotFoundException>()),
      );
    });
  });
}
