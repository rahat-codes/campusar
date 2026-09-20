import 'package:campusar/core/constants/app_constants.dart';
import 'package:campusar/core/utilities/geo_utils.dart';
import 'package:campusar/data/models/route_graph.dart';

class RouteNotFoundException implements Exception {
  RouteNotFoundException(this.message);
  final String message;
  @override
  String toString() => message;
}

class RouteCalculationResult {
  const RouteCalculationResult({
    required this.nodes,
    required this.totalDistanceMeters,
    required this.estimatedWalkingTimeSeconds,
  });

  final List<RouteNode> nodes;
  final double totalDistanceMeters;
  final double estimatedWalkingTimeSeconds;

  double get estimatedWalkingTimeMinutes => estimatedWalkingTimeSeconds / 60;
}

class _Adjacency {
  const _Adjacency(this.neighborId, this.edge);
  final String neighborId;
  final RouteEdge edge;
}

/// Runs A* over the campus pedestrian graph, entirely on-device, so
/// routing works with no network connection (section 13 / 17 of the
/// product spec). This mirrors backend/app/services/routing_service.py's
/// algorithm and edge-weighting exactly, so an offline route and a
/// server-calculated one for the same start/end agree.
class RoutingService {
  RoutingService(List<RouteNode> nodes, List<RouteEdge> edges) {
    for (final n in nodes) {
      _nodes[n.id] = n;
      _adjacency.putIfAbsent(n.id, () => []);
    }
    for (final e in edges) {
      // Pedestrian edges are bidirectional.
      _adjacency.putIfAbsent(e.fromNode, () => []).add(_Adjacency(e.toNode, e));
      _adjacency.putIfAbsent(e.toNode, () => []).add(_Adjacency(e.fromNode, e));
    }
  }

  final Map<String, RouteNode> _nodes = {};
  final Map<String, List<_Adjacency>> _adjacency = {};

  String nearestNode(double latitude, double longitude) {
    if (_nodes.isEmpty) {
      throw RouteNotFoundException('Routing graph is empty.');
    }
    String? bestId;
    double bestDistance = double.infinity;
    for (final node in _nodes.values) {
      final d = GeoUtils.haversineDistanceMeters(
        latitude,
        longitude,
        node.latitude,
        node.longitude,
      );
      if (d < bestDistance) {
        bestDistance = d;
        bestId = node.id;
      }
    }
    return bestId!;
  }

  RouteCalculationResult findRoute({
    required double fromLatitude,
    required double fromLongitude,
    required String toNodeId,
    bool accessibleOnly = false,
    double walkingSpeedMetersPerSecond =
        AppConstants.averageWalkingSpeedMetersPerSecond,
  }) {
    if (!_nodes.containsKey(toNodeId)) {
      throw RouteNotFoundException("Destination node '$toNodeId' not found.");
    }
    final startId = nearestNode(fromLatitude, fromLongitude);
    final nodeIds = _aStar(startId, toNodeId, accessibleOnly);
    final totalDistance = _pathDistance(nodeIds);

    return RouteCalculationResult(
      nodes: nodeIds.map((id) => _nodes[id]!).toList(),
      totalDistanceMeters: double.parse(totalDistance.toStringAsFixed(1)),
      estimatedWalkingTimeSeconds: double.parse(
        GeoUtils.estimateWalkingTimeSeconds(
          totalDistance,
          walkingSpeedMetersPerSecond: walkingSpeedMetersPerSecond,
        ).toStringAsFixed(1),
      ),
    );
  }

  double _heuristic(String nodeId, String goalId) {
    final a = _nodes[nodeId]!;
    final b = _nodes[goalId]!;
    return GeoUtils.haversineDistanceMeters(
      a.latitude,
      a.longitude,
      b.latitude,
      b.longitude,
    );
  }

  List<String> _aStar(String startId, String goalId, bool accessibleOnly) {
    final openHeap = HeapPriorityQueue<_ScoredNode>();
    openHeap.add(_ScoredNode(0, startId));

    final cameFrom = <String, String>{};
    final gScore = <String, double>{startId: 0};
    final visited = <String>{};

    while (openHeap.isNotEmpty) {
      final current = openHeap.removeFirst().nodeId;
      if (current == goalId) {
        return _reconstructPath(cameFrom, current);
      }
      if (visited.contains(current)) continue;
      visited.add(current);

      for (final adj in _adjacency[current] ?? const <_Adjacency>[]) {
        if (accessibleOnly && !adj.edge.accessible) continue;
        final tentativeG = gScore[current]! + adj.edge.distance;
        if (tentativeG < (gScore[adj.neighborId] ?? double.infinity)) {
          cameFrom[adj.neighborId] = current;
          gScore[adj.neighborId] = tentativeG;
          final fScore = tentativeG + _heuristic(adj.neighborId, goalId);
          openHeap.add(_ScoredNode(fScore, adj.neighborId));
        }
      }
    }

    throw RouteNotFoundException(
      "No route found between '$startId' and '$goalId'"
      '${accessibleOnly ? " using only accessible paths." : "."}',
    );
  }

  List<String> _reconstructPath(Map<String, String> cameFrom, String current) {
    final path = <String>[current];
    var node = current;
    while (cameFrom.containsKey(node)) {
      node = cameFrom[node]!;
      path.add(node);
    }
    return path.reversed.toList();
  }

  double _pathDistance(List<String> nodeIds) {
    double total = 0;
    for (var i = 0; i < nodeIds.length - 1; i++) {
      final a = nodeIds[i];
      final b = nodeIds[i + 1];
      final edge = (_adjacency[a] ?? const <_Adjacency>[])
          .firstWhere((adj) => adj.neighborId == b);
      total += edge.edge.distance;
    }
    return total;
  }
}

class _ScoredNode implements Comparable<_ScoredNode> {
  const _ScoredNode(this.score, this.nodeId);
  final double score;
  final String nodeId;

  @override
  int compareTo(_ScoredNode other) => score.compareTo(other.score);
}

/// Minimal binary-heap priority queue (avoids pulling in an extra package
/// just for A*'s open set).
class HeapPriorityQueue<T extends Comparable<T>> {
  final List<T> _heap = [];

  bool get isNotEmpty => _heap.isNotEmpty;

  void add(T value) {
    _heap.add(value);
    _bubbleUp(_heap.length - 1);
  }

  T removeFirst() {
    final result = _heap.first;
    final last = _heap.removeLast();
    if (_heap.isNotEmpty) {
      _heap[0] = last;
      _bubbleDown(0);
    }
    return result;
  }

  void _bubbleUp(int index) {
    while (index > 0) {
      final parent = (index - 1) ~/ 2;
      if (_heap[index].compareTo(_heap[parent]) >= 0) break;
      _swap(index, parent);
      index = parent;
    }
  }

  void _bubbleDown(int index) {
    final length = _heap.length;
    while (true) {
      final left = 2 * index + 1;
      final right = 2 * index + 2;
      var smallest = index;
      if (left < length && _heap[left].compareTo(_heap[smallest]) < 0) {
        smallest = left;
      }
      if (right < length && _heap[right].compareTo(_heap[smallest]) < 0) {
        smallest = right;
      }
      if (smallest == index) break;
      _swap(index, smallest);
      index = smallest;
    }
  }

  void _swap(int i, int j) {
    final tmp = _heap[i];
    _heap[i] = _heap[j];
    _heap[j] = tmp;
  }
}
