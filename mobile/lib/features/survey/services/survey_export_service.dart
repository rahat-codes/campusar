import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'package:campusar/core/utilities/geo_utils.dart';
import 'package:campusar/data/models/survey/survey_entrance.dart';
import 'package:campusar/data/models/survey/survey_facility.dart';
import 'package:campusar/data/models/survey/survey_status.dart';
import 'package:campusar/data/repositories/survey_repository.dart';

const _jsonEncoder = JsonEncoder.withIndent('  ');

class ExportResult {
  const ExportResult({required this.directoryPath, required this.filePaths});
  final String directoryPath;
  final List<String> filePaths;
}

/// Exports the raw survey dataset to JSON + GeoJSON (section 20 of the
/// V1.1 spec), and separately converts *verified-only* survey data into
/// the exact schema the production app/backend already consume (section
/// 23: "RAW SURVEY DATA → VALIDATION → HUMAN REVIEW → VERIFIED DATASET →
/// PRODUCTION DATA → Flutter offline dataset"). The two are always
/// written to different files so a raw export can never be mistaken for
/// a production one.
class SurveyExportService {
  const SurveyExportService();

  Future<Directory> _exportDir() async {
    final docs = await getApplicationDocumentsDirectory();
    final stamp = DateTime.now().toIso8601String().replaceAll(RegExp('[:.]'), '-');
    final dir = Directory('${docs.path}/survey_exports/$stamp');
    await dir.create(recursive: true);
    return dir;
  }

  Future<ExportResult> exportRaw(SurveySnapshot snapshot) async {
    final dir = await _exportDir();
    final paths = <String>[];

    Future<void> write(String filename, Object data) async {
      final file = File('${dir.path}/$filename');
      await file.writeAsString(_jsonEncoder.convert(data));
      paths.add(file.path);
    }

    await write('buildings.json', snapshot.buildings.map((b) => b.toJson()).toList());
    await write('entrances.json', snapshot.entrances.map((e) => e.toJson()).toList());
    await write('facilities.json', snapshot.facilities.map((f) => f.toJson()).toList());
    await write('route_nodes.json', snapshot.nodes.map((n) => n.toJson()).toList());
    await write('route_edges.json', snapshot.edges.map((e) => e.toJson()).toList());
    await write('survey_sessions.json', snapshot.sessions.map((s) => s.toJson()).toList());

    await write('tongmyong-campus-dataset.json', {
      '_comment': 'Raw field-survey export — see status field on each '
          'record (raw/reviewed/verified/deprecated). NOT production data '
          'until reviewed — see README "Raw vs verified vs production data".',
      'exportedAt': DateTime.now().toIso8601String(),
      'buildings': snapshot.buildings.map((b) => b.toJson()).toList(),
      'entrances': snapshot.entrances.map((e) => e.toJson()).toList(),
      'facilities': snapshot.facilities.map((f) => f.toJson()).toList(),
      'routeNodes': snapshot.nodes.map((n) => n.toJson()).toList(),
      'routeEdges': snapshot.edges.map((e) => e.toJson()).toList(),
      'surveySessions': snapshot.sessions.map((s) => s.toJson()).toList(),
    });

    await write('tongmyong-campus.geojson', _toGeoJson(snapshot));

    return ExportResult(directoryPath: dir.path, filePaths: paths);
  }

  Map<String, dynamic> _toGeoJson(SurveySnapshot snapshot) {
    final features = <Map<String, dynamic>>[];

    for (final b in snapshot.buildings) {
      features.add(_pointFeature(
        lat: b.latitude,
        lon: b.longitude,
        properties: {'kind': 'building', 'id': b.id, 'name': b.nameEn, 'status': b.status.name},
      ));
    }
    for (final e in snapshot.entrances) {
      features.add(_pointFeature(
        lat: e.latitude,
        lon: e.longitude,
        properties: {'kind': 'entrance', 'id': e.id, 'buildingId': e.buildingId, 'status': e.status.name},
      ));
    }
    for (final f in snapshot.facilities) {
      features.add(_pointFeature(
        lat: f.latitude,
        lon: f.longitude,
        properties: {'kind': 'facility', 'id': f.id, 'type': f.type, 'status': f.status.name},
      ));
    }
    for (final n in snapshot.nodes) {
      features.add(_pointFeature(
        lat: n.latitude,
        lon: n.longitude,
        properties: {'kind': 'route_node', 'id': n.id, 'type': n.type.name, 'status': n.status.name},
      ));
    }

    final nodeById = {for (final n in snapshot.nodes) n.id: n};
    for (final e in snapshot.edges) {
      final from = nodeById[e.fromNode];
      final to = nodeById[e.toNode];
      if (from == null || to == null) continue;
      features.add({
        'type': 'Feature',
        'geometry': {
          'type': 'LineString',
          'coordinates': [
            [from.longitude, from.latitude],
            [to.longitude, to.latitude],
          ],
        },
        'properties': {
          'kind': 'route_edge',
          'id': e.id,
          'distance': e.distance,
          'accessible': e.accessible,
          'status': e.status.name,
        },
      });
    }

    return {'type': 'FeatureCollection', 'features': features};
  }

  Map<String, dynamic> _pointFeature({
    required double lat,
    required double lon,
    required Map<String, dynamic> properties,
  }) {
    return {
      'type': 'Feature',
      'geometry': {
        'type': 'Point',
        'coordinates': [lon, lat],
      },
      'properties': properties,
    };
  }

  // -----------------------------------------------------------------
  // Verified survey data -> production dataset conversion
  // -----------------------------------------------------------------

  /// Converts only [SurveyStatus.verified] records into the exact JSON
  /// shape the production app/backend already read (see
  /// backend/app/data/seed/*.json and mobile/assets/data/*.json). This is
  /// a best-effort automated linking step — a human should still review
  /// the output before replacing the bundled production files (see
  /// README "How to convert verified survey data into production data").
  ///
  /// Buildings are linked to the route graph by finding the nearest
  /// verified route node within [nodeLinkThresholdMeters] as the
  /// building's entrance node, and synthesizing a one-edge "destination"
  /// node at the building's own coordinate — mirroring how the original
  /// sample dataset's buildings were connected to its path graph.
  Future<ExportResult> exportProduction(
    SurveySnapshot snapshot, {
    double nodeLinkThresholdMeters = 25.0,
  }) async {
    final verifiedBuildings = snapshot.buildings.where((b) => b.status == SurveyStatus.verified).toList();
    final verifiedEntrances = snapshot.entrances.where((e) => e.status == SurveyStatus.verified).toList();
    final verifiedFacilities = snapshot.facilities.where((f) => f.status == SurveyStatus.verified).toList();
    final verifiedNodes = snapshot.nodes.where((n) => n.status == SurveyStatus.verified).toList();
    final verifiedEdges = snapshot.edges.where((e) => e.status == SurveyStatus.verified).toList();

    final entrancesByBuilding = <String, List<SurveyEntrance>>{};
    for (final e in verifiedEntrances) {
      entrancesByBuilding.putIfAbsent(e.buildingId, () => []).add(e);
    }
    final facilitiesByBuilding = <String, List<SurveyFacility>>{};
    for (final f in verifiedFacilities) {
      if (f.buildingId != null) {
        facilitiesByBuilding.putIfAbsent(f.buildingId!, () => []).add(f);
      }
    }

    final outputNodes = [
      for (final n in verifiedNodes)
        {
          'id': n.id,
          'latitude': n.latitude,
          'longitude': n.longitude,
          'type': n.type.productionTypeName,
        },
    ];
    final outputEdges = [
      for (final e in verifiedEdges)
        {
          'id': e.id,
          'fromNode': e.fromNode,
          'toNode': e.toNode,
          'distance': e.distance,
          'accessible': e.accessible,
          'indoor': e.indoor,
          'outdoor': e.outdoor,
        },
    ];

    final outputBuildings = <Map<String, dynamic>>[];
    final outputEntrances = <Map<String, dynamic>>[];
    final outputFacilities = <Map<String, dynamic>>[];
    final unlinkedBuildingNames = <String>[];

    for (final b in verifiedBuildings) {
      String? entranceNodeId;
      double bestDistance = double.infinity;
      for (final n in verifiedNodes) {
        final d = GeoUtils.haversineDistanceMeters(b.latitude, b.longitude, n.latitude, n.longitude);
        if (d < bestDistance) {
          bestDistance = d;
          entranceNodeId = n.id;
        }
      }
      if (bestDistance > nodeLinkThresholdMeters) {
        entranceNodeId = null;
        unlinkedBuildingNames.add(b.nameEn);
      }

      String? destinationNodeId;
      if (entranceNodeId != null) {
        destinationNodeId = 'dest_${b.id}';
        outputNodes.add({
          'id': destinationNodeId,
          'latitude': b.latitude,
          'longitude': b.longitude,
          'type': 'destination',
        });
        outputEdges.add({
          'id': 'edge_${b.id}_dest',
          'fromNode': entranceNodeId,
          'toNode': destinationNodeId,
          'distance': bestDistance,
          'accessible': true,
          'indoor': false,
          'outdoor': true,
        });
      }

      final myEntrances = entrancesByBuilding[b.id] ?? const <SurveyEntrance>[];
      final myFacilities = facilitiesByBuilding[b.id] ?? const <SurveyFacility>[];

      for (final e in myEntrances) {
        outputEntrances.add({
          'id': e.id,
          'buildingId': b.id,
          'latitude': e.latitude,
          'longitude': e.longitude,
          'floor': 1,
          'name': (e.name != null && e.name!.isNotEmpty) ? e.name! : 'Main Entrance',
        });
      }
      for (final f in myFacilities) {
        outputFacilities.add({
          'id': f.id,
          'buildingId': b.id,
          'name': (f.name != null && f.name!.isNotEmpty) ? f.name! : f.type,
          'category': f.type,
        });
      }

      outputBuildings.add({
        'id': b.id,
        'campusId': 'tongmyong-main',
        'name': b.nameEn,
        'shortName': (b.nameKo != null && b.nameKo!.isNotEmpty) ? b.nameKo! : b.nameEn,
        'buildingNumber': b.buildingNumber ?? '',
        'latitude': b.latitude,
        'longitude': b.longitude,
        'description': b.description ?? '',
        'image': '',
        'floors': b.floors ?? 1,
        'entrances': myEntrances.map((e) => e.id as String).toList(),
        'facilityIds': myFacilities.map((f) => f.id as String).toList(),
        'accessibility': {
          'wheelchairAccessible': myEntrances.any((e) => e.accessible),
          'hasElevator': myFacilities.any((f) => f.type == 'elevator'),
          'notes': 'Derived from verified survey data.',
        },
        'destinationNodeId': destinationNodeId,
        'entranceNodeId': entranceNodeId,
      });
    }

    final dir = await _exportDir();
    final paths = <String>[];
    Future<void> write(String filename, Object data) async {
      final file = File('${dir.path}/production_$filename');
      await file.writeAsString(_jsonEncoder.convert(data));
      paths.add(file.path);
    }

    await write('buildings.json', {
      'buildings': outputBuildings,
      if (unlinkedBuildingNames.isNotEmpty)
        '_warning': 'Buildings not linked to a route node (none within '
            '${nodeLinkThresholdMeters.round()}m): ${unlinkedBuildingNames.join(", ")}',
    });
    await write('entrances.json', {'entrances': outputEntrances});
    await write('facilities.json', {'facilities': outputFacilities});
    await write('routes.json', {'nodes': outputNodes, 'edges': outputEdges});

    return ExportResult(directoryPath: dir.path, filePaths: paths);
  }
}
