import 'package:campusar/data/local/campus_data_loader.dart';
import 'package:campusar/data/local/local_campus_data_source.dart';
import 'package:campusar/data/models/route_graph.dart';

/// Offline-first access to the pedestrian routing graph. The actual
/// pathfinding (A*) lives in features/navigation/services/routing_service.dart,
/// which is intentionally decoupled from persistence — this repository's
/// only job is handing it nodes/edges.
class RouteGraphRepository {
  RouteGraphRepository({
    LocalCampusDataSource? localDataSource,
    CampusDataLoader? dataLoader,
  })  : _local = localDataSource ?? const LocalCampusDataSource(),
        _loader = dataLoader ?? const CampusDataLoader();

  final LocalCampusDataSource _local;
  final CampusDataLoader _loader;

  Future<(List<RouteNode>, List<RouteEdge>)> getGraph() async {
    await _loader.loadBundledDataIfNeeded();
    final nodes = await _local.getAllRouteNodes();
    final edges = await _local.getAllRouteEdges();
    return (nodes, edges);
  }
}
