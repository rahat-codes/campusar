import 'dart:convert';

import 'package:campusar/data/local/app_database.dart';
import 'package:campusar/data/models/building.dart';
import 'package:campusar/data/models/campus.dart';
import 'package:campusar/data/models/entrance.dart';
import 'package:campusar/data/models/facility.dart';
import 'package:campusar/data/models/route_graph.dart';

/// Reads typed domain models back out of the local SQLite database.
/// This is the ONLY place that knows the SQL schema/column names — the
/// rest of the app (repositories, providers, screens) only ever sees
/// Campus/Building/Entrance/Facility/RouteNode/RouteEdge objects.
class LocalCampusDataSource {
  const LocalCampusDataSource();

  Future<Campus?> getCampus() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('campus', limit: 1);
    if (rows.isEmpty) return null;
    return _campusFromRow(rows.first);
  }

  Future<List<Building>> getAllBuildings({String? campusId}) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'buildings',
      where: campusId != null ? 'campus_id = ?' : null,
      whereArgs: campusId != null ? [campusId] : null,
      orderBy: 'building_number',
    );
    return rows.map(_buildingFromRow).toList();
  }

  Future<Building?> getBuilding(String id) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('buildings', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return _buildingFromRow(rows.first);
  }

  /// Offline search across name, short name, building number, and
  /// facility name (section 10 of the product spec). Direct
  /// name/number/short-name matches are returned before facility matches.
  Future<List<Building>> searchBuildings(String query) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return getAllBuildings();

    final db = await AppDatabase.instance.database;
    final like = '%$q%';

    final directRows = await db.query(
      'buildings',
      where: 'LOWER(name) LIKE ? OR LOWER(short_name) LIKE ? OR LOWER(building_number) LIKE ?',
      whereArgs: [like, like, like],
      orderBy: 'building_number',
    );
    final direct = directRows.map(_buildingFromRow).toList();
    final matchedIds = direct.map((b) => b.id).toSet();

    final facilityBuildingIds = await db.rawQuery(
      'SELECT DISTINCT building_id FROM facilities WHERE LOWER(name) LIKE ?',
      [like],
    );
    final extraIds = facilityBuildingIds
        .map((row) => row['building_id'] as String)
        .where((id) => !matchedIds.contains(id))
        .toList();

    final extra = <Building>[];
    for (final id in extraIds) {
      final building = await getBuilding(id);
      if (building != null) extra.add(building);
    }

    return [...direct, ...extra];
  }

  Future<List<Entrance>> getEntrancesFor(String buildingId) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'entrances',
      where: 'building_id = ?',
      whereArgs: [buildingId],
    );
    return rows.map((r) => Entrance.fromJson(_entranceRowToJson(r))).toList();
  }

  Future<List<Facility>> getFacilitiesFor(String buildingId) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'facilities',
      where: 'building_id = ?',
      whereArgs: [buildingId],
    );
    return rows.map((r) => Facility.fromJson(_facilityRowToJson(r))).toList();
  }

  Future<List<RouteNode>> getAllRouteNodes() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('route_nodes');
    return rows.map((r) => RouteNode.fromJson(_nodeRowToJson(r))).toList();
  }

  Future<List<RouteEdge>> getAllRouteEdges() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('route_edges');
    return rows.map((r) => RouteEdge.fromJson(_edgeRowToJson(r))).toList();
  }

  // --- row <-> json mapping helpers ---

  Campus _campusFromRow(Map<String, dynamic> row) {
    return Campus.fromJson({
      'id': row['id'],
      'name': row['name'],
      'universityName': row['university_name'],
      'country': row['country'],
      'city': row['city'],
      'latitude': row['latitude'],
      'longitude': row['longitude'],
      'mapConfiguration': jsonDecode(row['map_configuration'] as String),
      'version': row['version'],
    });
  }

  Building _buildingFromRow(Map<String, dynamic> row) {
    return Building.fromJson({
      'id': row['id'],
      'campusId': row['campus_id'],
      'name': row['name'],
      'shortName': row['short_name'],
      'buildingNumber': row['building_number'],
      'latitude': row['latitude'],
      'longitude': row['longitude'],
      'description': row['description'],
      'image': row['image'],
      'floors': row['floors'],
      'entrances': jsonDecode(row['entrance_ids'] as String),
      'facilityIds': jsonDecode(row['facility_ids'] as String),
      'accessibility': jsonDecode(row['accessibility'] as String),
      'destinationNodeId': row['destination_node_id'],
      'entranceNodeId': row['entrance_node_id'],
    });
  }

  Map<String, dynamic> _entranceRowToJson(Map<String, dynamic> row) => {
        'id': row['id'],
        'buildingId': row['building_id'],
        'latitude': row['latitude'],
        'longitude': row['longitude'],
        'floor': row['floor'],
        'name': row['name'],
      };

  Map<String, dynamic> _facilityRowToJson(Map<String, dynamic> row) => {
        'id': row['id'],
        'buildingId': row['building_id'],
        'name': row['name'],
        'category': row['category'],
      };

  Map<String, dynamic> _nodeRowToJson(Map<String, dynamic> row) => {
        'id': row['id'],
        'latitude': row['latitude'],
        'longitude': row['longitude'],
        'type': row['type'],
      };

  Map<String, dynamic> _edgeRowToJson(Map<String, dynamic> row) => {
        'id': row['id'],
        'fromNode': row['from_node'],
        'toNode': row['to_node'],
        'distance': row['distance'],
        'accessible': (row['accessible'] as int) == 1,
        'indoor': (row['indoor'] as int) == 1,
        'outdoor': (row['outdoor'] as int) == 1,
      };
}
