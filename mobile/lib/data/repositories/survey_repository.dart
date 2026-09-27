import 'package:sqflite/sqflite.dart';

import 'package:campusar/core/utilities/geo_utils.dart';
import 'package:campusar/data/local/app_database.dart';
import 'package:campusar/data/models/survey/gps_sample.dart';
import 'package:campusar/data/models/survey/survey_building.dart';
import 'package:campusar/data/models/survey/survey_entrance.dart';
import 'package:campusar/data/models/survey/survey_facility.dart';
import 'package:campusar/data/models/survey/survey_raw_sample.dart';
import 'package:campusar/data/models/survey/survey_route_edge.dart';
import 'package:campusar/data/models/survey/survey_route_node.dart';
import 'package:campusar/data/models/survey/survey_session.dart';
import 'package:campusar/data/models/survey/survey_status.dart';
import 'package:campusar/features/survey/services/path_processing_service.dart';
import 'package:campusar/features/survey/utils/survey_id_generator.dart';

/// A full in-memory snapshot of the survey dataset, for validation and
/// export (sections 18 and 20 of the V1.1 spec).
class SurveySnapshot {
  const SurveySnapshot({
    required this.sessions,
    required this.buildings,
    required this.entrances,
    required this.facilities,
    required this.nodes,
    required this.edges,
  });

  final List<SurveySession> sessions;
  final List<SurveyBuilding> buildings;
  final List<SurveyEntrance> entrances;
  final List<SurveyFacility> facilities;
  final List<SurveyRouteNode> nodes;
  final List<SurveyRouteEdge> edges;
}

/// Data access layer for Survey Mode. Extends the existing SQLite
/// database (see data/local/app_database.dart) rather than creating a
/// second storage system (section 15 of the V1.1 spec).
class SurveyRepository {
  Future<Database> get _db => AppDatabase.instance.database;

  static const double defaultNodeSnapThresholdMeters = 3.0;

  // ---------------------------------------------------------------------
  // Sessions
  // ---------------------------------------------------------------------

  Future<SurveySession> startSession({
    String? surveyorName,
    String? deviceInfo,
    required String datasetVersion,
  }) async {
    final db = await _db;
    final session = SurveySession(
      id: SurveyIdGenerator.generate('session'),
      surveyorName: surveyorName,
      startTime: DateTime.now(),
      deviceInfo: deviceInfo,
      datasetVersion: datasetVersion,
    );
    await db.insert('survey_sessions', session.toMap());
    return session;
  }

  Future<SurveySession?> getActiveSession() async {
    final db = await _db;
    final rows = await db.query(
      'survey_sessions',
      where: 'end_time IS NULL',
      orderBy: 'start_time DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return SurveySession.fromMap(rows.first);
  }

  Future<void> endSession(String sessionId, {String? notes}) async {
    final db = await _db;
    await db.update(
      'survey_sessions',
      {
        'end_time': DateTime.now().toIso8601String(),
        if (notes != null) 'notes': notes,
      },
      where: 'id = ?',
      whereArgs: [sessionId],
    );
  }

  Future<List<SurveySession>> listSessions() async {
    final db = await _db;
    final rows = await db.query('survey_sessions', orderBy: 'start_time DESC');
    return rows.map(SurveySession.fromMap).toList();
  }

  // ---------------------------------------------------------------------
  // Buildings
  // ---------------------------------------------------------------------

  Future<SurveyBuilding> insertBuilding(SurveyBuilding building) async {
    final db = await _db;
    await db.insert('survey_buildings', building.toMap());
    return building;
  }

  Future<void> updateBuilding(SurveyBuilding building) async {
    final db = await _db;
    await db.update(
      'survey_buildings',
      building.toMap(),
      where: 'id = ?',
      whereArgs: [building.id],
    );
  }

  Future<List<SurveyBuilding>> listBuildings({SurveyStatus? status}) async {
    final db = await _db;
    final rows = await db.query(
      'survey_buildings',
      where: status != null ? 'status = ?' : null,
      whereArgs: status != null ? [status.name] : null,
      orderBy: 'captured_at DESC',
    );
    return rows.map(SurveyBuilding.fromMap).toList();
  }

  Future<SurveyBuilding?> getBuilding(String id) async {
    final db = await _db;
    final rows = await db.query('survey_buildings', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return SurveyBuilding.fromMap(rows.first);
  }

  Future<void> setBuildingStatus(String id, SurveyStatus status) async {
    final db = await _db;
    await db.update('survey_buildings', {'status': status.name}, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteBuilding(String id) async {
    final db = await _db;
    await db.delete('survey_buildings', where: 'id = ?', whereArgs: [id]);
  }

  // ---------------------------------------------------------------------
  // Entrances
  // ---------------------------------------------------------------------

  Future<SurveyEntrance> insertEntrance(SurveyEntrance entrance) async {
    final db = await _db;
    await db.insert('survey_entrances', entrance.toMap());
    return entrance;
  }

  Future<List<SurveyEntrance>> listEntrancesForBuilding(String buildingId) async {
    final db = await _db;
    final rows = await db.query(
      'survey_entrances',
      where: 'building_id = ?',
      whereArgs: [buildingId],
      orderBy: 'captured_at DESC',
    );
    return rows.map(SurveyEntrance.fromMap).toList();
  }

  Future<List<SurveyEntrance>> listAllEntrances() async {
    final db = await _db;
    final rows = await db.query('survey_entrances', orderBy: 'captured_at DESC');
    return rows.map(SurveyEntrance.fromMap).toList();
  }

  Future<void> setEntranceStatus(String id, SurveyStatus status) async {
    final db = await _db;
    await db.update('survey_entrances', {'status': status.name}, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteEntrance(String id) async {
    final db = await _db;
    await db.delete('survey_entrances', where: 'id = ?', whereArgs: [id]);
  }

  // ---------------------------------------------------------------------
  // Facilities
  // ---------------------------------------------------------------------

  Future<SurveyFacility> insertFacility(SurveyFacility facility) async {
    final db = await _db;
    await db.insert('survey_facilities', facility.toMap());
    return facility;
  }

  Future<List<SurveyFacility>> listFacilities({String? buildingId}) async {
    final db = await _db;
    final rows = await db.query(
      'survey_facilities',
      where: buildingId != null ? 'building_id = ?' : null,
      whereArgs: buildingId != null ? [buildingId] : null,
      orderBy: 'captured_at DESC',
    );
    return rows.map(SurveyFacility.fromMap).toList();
  }

  Future<void> setFacilityStatus(String id, SurveyStatus status) async {
    final db = await _db;
    await db.update('survey_facilities', {'status': status.name}, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteFacility(String id) async {
    final db = await _db;
    await db.delete('survey_facilities', where: 'id = ?', whereArgs: [id]);
  }

  // ---------------------------------------------------------------------
  // Route nodes / edges (manual + path-recording driven)
  // ---------------------------------------------------------------------

  Future<List<SurveyRouteNode>> listNodes() async {
    final db = await _db;
    final rows = await db.query('survey_route_nodes');
    return rows.map(SurveyRouteNode.fromMap).toList();
  }

  Future<List<SurveyRouteEdge>> listEdges() async {
    final db = await _db;
    final rows = await db.query('survey_route_edges');
    return rows.map(SurveyRouteEdge.fromMap).toList();
  }

  Future<void> setNodeType(String id, SurveyNodeType type) async {
    final db = await _db;
    await db.update('survey_route_nodes', {'type': type.name}, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> setNodeStatus(String id, SurveyStatus status) async {
    final db = await _db;
    await db.update('survey_route_nodes', {'status': status.name}, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> setEdgeStatus(String id, SurveyStatus status) async {
    final db = await _db;
    await db.update('survey_route_edges', {'status': status.name}, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteNode(String id) async {
    final db = await _db;
    await db.delete('survey_route_nodes', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteEdge(String id) async {
    final db = await _db;
    await db.delete('survey_route_edges', where: 'id = ?', whereArgs: [id]);
  }

  /// Manually add a single point of interest (section 9: "Allow the
  /// surveyor to manually mark important points") without going through
  /// path recording — still snapped against existing nodes so it joins
  /// the graph if it coincides with one.
  Future<SurveyRouteNode> addManualNode({
    required String sessionId,
    required GpsSample sample,
    required SurveyNodeType type,
  }) async {
    final nodeId = await _findOrCreateNode(
      sessionId: sessionId,
      sample: sample,
      preferredType: type,
      snapThresholdMeters: defaultNodeSnapThresholdMeters,
    );
    final node = (await listNodes()).firstWhere((n) => n.id == nodeId);
    return node;
  }

  // ---------------------------------------------------------------------
  // Path recording
  // ---------------------------------------------------------------------

  Future<void> insertRawSamples(
    String sessionId,
    String recordingId,
    List<GpsSample> samples,
  ) async {
    if (samples.isEmpty) return;
    final db = await _db;
    final batch = db.batch();
    for (final s in samples) {
      batch.insert(
        'survey_raw_samples',
        SurveyRawSample(
          sessionId: sessionId,
          recordingId: recordingId,
          latitude: s.latitude,
          longitude: s.longitude,
          accuracy: s.accuracy,
          altitude: s.altitude,
          heading: s.heading,
          capturedAt: s.capturedAt,
        ).toMap(),
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<SurveyRawSample>> listRawSamples(String recordingId) async {
    final db = await _db;
    final rows = await db.query(
      'survey_raw_samples',
      where: 'recording_id = ?',
      whereArgs: [recordingId],
      orderBy: 'captured_at ASC',
    );
    return rows.map(SurveyRawSample.fromMap).toList();
  }

  /// Persists a processed path: raw samples are stored for later review,
  /// then each simplified point is snapped onto an existing node (within
  /// [snapThresholdMeters]) or inserted as a new one, and sequential
  /// edges are created between them with a haversine-computed distance
  /// (never hardcoded — section 10). Snapping onto a shared node across
  /// multiple recordings is what lets separately-recorded paths meet at
  /// an intersection (section 11) without any special-case UI.
  Future<({List<SurveyRouteNode> nodes, List<SurveyRouteEdge> edges})> saveProcessedPath({
    required String sessionId,
    required String recordingId,
    required List<GpsSample> rawSamples,
    required ProcessedPath processed,
    double snapThresholdMeters = defaultNodeSnapThresholdMeters,
  }) async {
    await insertRawSamples(sessionId, recordingId, rawSamples);

    final nodeIds = <String>[];
    for (var i = 0; i < processed.points.length; i++) {
      final isEndpoint = i == 0 || i == processed.points.length - 1;
      final id = await _findOrCreateNode(
        sessionId: sessionId,
        sample: processed.points[i],
        preferredType: SurveyNodeType.pathway,
        snapThresholdMeters: snapThresholdMeters,
        promoteToIntersectionIfSnapped: isEndpoint,
      );
      nodeIds.add(id);
    }

    final allNodes = await listNodes();
    final nodeById = {for (final n in allNodes) n.id: n};

    final createdEdges = <SurveyRouteEdge>[];
    final db = await _db;
    final batch = db.batch();
    for (var i = 0; i < nodeIds.length - 1; i++) {
      final fromId = nodeIds[i];
      final toId = nodeIds[i + 1];
      if (fromId == toId) continue; // both ends snapped to the same node
      final from = nodeById[fromId]!;
      final to = nodeById[toId]!;
      final distance = GeoUtils.haversineDistanceMeters(
        from.latitude,
        from.longitude,
        to.latitude,
        to.longitude,
      );
      final edge = SurveyRouteEdge(
        id: SurveyIdGenerator.generate('edge'),
        sessionId: sessionId,
        fromNode: fromId,
        toNode: toId,
        distance: distance,
      );
      createdEdges.add(edge);
      batch.insert('survey_route_edges', edge.toMap());
    }
    await batch.commit(noResult: true);

    await _recomputeIntersections();

    final finalNodes = await listNodes();
    final createdNodeSet = nodeIds.toSet();
    return (
      nodes: finalNodes.where((n) => createdNodeSet.contains(n.id)).toList(),
      edges: createdEdges,
    );
  }

  /// Finds an existing node within [snapThresholdMeters] of [sample], or
  /// inserts a new one. If [promoteToIntersectionIfSnapped] and an
  /// existing plain `pathway` node was matched, promotes it to
  /// `intersection` immediately (two recordings meeting at their
  /// endpoints is the clearest intersection signal); interior-point
  /// matches are left for [_recomputeIntersections] to classify by
  /// degree.
  Future<String> _findOrCreateNode({
    required String sessionId,
    required GpsSample sample,
    required SurveyNodeType preferredType,
    required double snapThresholdMeters,
    bool promoteToIntersectionIfSnapped = false,
  }) async {
    final existing = await listNodes();
    SurveyRouteNode? nearest;
    double nearestDistance = double.infinity;
    for (final node in existing) {
      final d = GeoUtils.haversineDistanceMeters(
        node.latitude,
        node.longitude,
        sample.latitude,
        sample.longitude,
      );
      if (d < nearestDistance) {
        nearestDistance = d;
        nearest = node;
      }
    }

    if (nearest != null && nearestDistance <= snapThresholdMeters) {
      if (promoteToIntersectionIfSnapped && nearest.type == SurveyNodeType.pathway) {
        await setNodeType(nearest.id, SurveyNodeType.intersection);
      }
      return nearest.id;
    }

    final node = SurveyRouteNode(
      id: SurveyIdGenerator.generate('node'),
      sessionId: sessionId,
      latitude: sample.latitude,
      longitude: sample.longitude,
      type: preferredType,
      gpsAccuracy: sample.accuracy,
      capturedAt: sample.capturedAt,
    );
    final db = await _db;
    await db.insert('survey_route_nodes', node.toMap());
    return node.id;
  }

  /// Any plain `pathway` node touched by 3+ edges is, by definition, a
  /// fork in the path network — promote it to `intersection` (section 11:
  /// "The final graph must support A* routing", which needs junctions
  /// correctly typed so the routing engine's graph traversal treats them
  /// as branch points).
  Future<void> _recomputeIntersections() async {
    final edges = await listEdges();
    final degree = <String, int>{};
    for (final e in edges) {
      degree[e.fromNode] = (degree[e.fromNode] ?? 0) + 1;
      degree[e.toNode] = (degree[e.toNode] ?? 0) + 1;
    }
    final nodes = await listNodes();
    for (final node in nodes) {
      if (node.type == SurveyNodeType.pathway && (degree[node.id] ?? 0) >= 3) {
        await setNodeType(node.id, SurveyNodeType.intersection);
      }
    }
  }

  // ---------------------------------------------------------------------
  // Counts / snapshot
  // ---------------------------------------------------------------------

  Future<SurveyCounts> getCounts() async {
    final db = await _db;
    Future<int> count(String table) async {
      final result = await db.rawQuery('SELECT COUNT(*) as c FROM $table');
      return Sqflite.firstIntValue(result) ?? 0;
    }

    return SurveyCounts(
      buildings: await count('survey_buildings'),
      entrances: await count('survey_entrances'),
      facilities: await count('survey_facilities'),
      nodes: await count('survey_route_nodes'),
      edges: await count('survey_route_edges'),
    );
  }

  Future<SurveySnapshot> getSnapshot() async {
    return SurveySnapshot(
      sessions: await listSessions(),
      buildings: await listBuildings(),
      entrances: await listAllEntrances(),
      facilities: await listFacilities(),
      nodes: await listNodes(),
      edges: await listEdges(),
    );
  }

  // ---------------------------------------------------------------------
  // Import (section 21) — duplicate IDs are skipped, never overwritten,
  // unless the caller explicitly opts in.
  // ---------------------------------------------------------------------

  Future<ImportSummary> importSnapshot(
    SurveySnapshot snapshot, {
    bool overwrite = false,
  }) async {
    final db = await _db;
    var imported = 0;
    var skipped = 0;

    Future<void> upsert(String table, Map<String, dynamic> map, String id) async {
      final existing = await db.query(table, where: 'id = ?', whereArgs: [id], limit: 1);
      if (existing.isNotEmpty && !overwrite) {
        skipped++;
        return;
      }
      if (existing.isNotEmpty) {
        await db.update(table, map, where: 'id = ?', whereArgs: [id]);
      } else {
        await db.insert(table, map);
      }
      imported++;
    }

    for (final s in snapshot.sessions) {
      await upsert('survey_sessions', s.toMap(), s.id);
    }
    for (final b in snapshot.buildings) {
      await upsert('survey_buildings', b.toMap(), b.id);
    }
    for (final e in snapshot.entrances) {
      await upsert('survey_entrances', e.toMap(), e.id);
    }
    for (final f in snapshot.facilities) {
      await upsert('survey_facilities', f.toMap(), f.id);
    }
    for (final n in snapshot.nodes) {
      await upsert('survey_route_nodes', n.toMap(), n.id);
    }
    for (final e in snapshot.edges) {
      await upsert('survey_route_edges', e.toMap(), e.id);
    }

    return ImportSummary(imported: imported, skippedDuplicates: skipped);
  }
}

class ImportSummary {
  const ImportSummary({required this.imported, required this.skippedDuplicates});
  final int imported;
  final int skippedDuplicates;
}
