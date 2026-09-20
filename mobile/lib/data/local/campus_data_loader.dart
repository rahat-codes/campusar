import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:sqflite/sqflite.dart';

import 'package:campusar/data/local/app_database.dart';

/// Populates the local database from the bundled sample dataset in
/// assets/data/*.json on first launch, so the app has usable offline data
/// immediately after install with no network round-trip required
/// (section 17: "On first launch: Load bundled campus data").
///
/// IMPORTANT — these are the SAME canonical JSON files used to seed the
/// backend's database (see backend/app/data/seed/ and
/// backend/app/database/seed.py), kept in sync from one source of truth.
/// Replace all five files here (and in the backend) with verified
/// Tongmyong University data — see README "How to Replace Campus Data".
class CampusDataLoader {
  const CampusDataLoader();

  Future<void> loadBundledDataIfNeeded({bool force = false}) async {
    final db = AppDatabase.instance;
    if (!force && await db.isSeeded()) return;

    if (force) await db.clearAll();

    final campusJson = await _readAsset('assets/data/campus.json');
    final buildingsJson = await _readAsset('assets/data/buildings.json');
    final entrancesJson = await _readAsset('assets/data/entrances.json');
    final facilitiesJson = await _readAsset('assets/data/facilities.json');
    final routesJson = await _readAsset('assets/data/routes.json');

    final database = await db.database;
    final batch = database.batch();

    batch.insert(
      'campus',
      {
        'id': campusJson['id'],
        'name': campusJson['name'],
        'university_name': campusJson['universityName'],
        'country': campusJson['country'],
        'city': campusJson['city'],
        'latitude': campusJson['latitude'],
        'longitude': campusJson['longitude'],
        'map_configuration': jsonEncode(campusJson['mapConfiguration']),
        'version': campusJson['version'],
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    for (final b in (buildingsJson['buildings'] as List<dynamic>)) {
      final building = b as Map<String, dynamic>;
      batch.insert(
        'buildings',
        {
          'id': building['id'],
          'campus_id': building['campusId'],
          'name': building['name'],
          'short_name': building['shortName'],
          'building_number': building['buildingNumber'],
          'latitude': building['latitude'],
          'longitude': building['longitude'],
          'description': building['description'],
          'image': building['image'],
          'floors': building['floors'],
          'entrance_ids': jsonEncode(building['entrances']),
          'facility_ids': jsonEncode(building['facilityIds']),
          'accessibility': jsonEncode(building['accessibility']),
          'destination_node_id': building['destinationNodeId'],
          'entrance_node_id': building['entranceNodeId'],
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    for (final e in (entrancesJson['entrances'] as List<dynamic>)) {
      final entrance = e as Map<String, dynamic>;
      batch.insert(
        'entrances',
        {
          'id': entrance['id'],
          'building_id': entrance['buildingId'],
          'latitude': entrance['latitude'],
          'longitude': entrance['longitude'],
          'floor': entrance['floor'],
          'name': entrance['name'],
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    for (final f in (facilitiesJson['facilities'] as List<dynamic>)) {
      final facility = f as Map<String, dynamic>;
      batch.insert(
        'facilities',
        {
          'id': facility['id'],
          'building_id': facility['buildingId'],
          'name': facility['name'],
          'category': facility['category'],
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    for (final n in (routesJson['nodes'] as List<dynamic>)) {
      final node = n as Map<String, dynamic>;
      batch.insert(
        'route_nodes',
        {
          'id': node['id'],
          'latitude': node['latitude'],
          'longitude': node['longitude'],
          'type': node['type'],
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    for (final e in (routesJson['edges'] as List<dynamic>)) {
      final edge = e as Map<String, dynamic>;
      batch.insert(
        'route_edges',
        {
          'id': edge['id'],
          'from_node': edge['fromNode'],
          'to_node': edge['toNode'],
          'distance': edge['distance'],
          'accessible': (edge['accessible'] as bool) ? 1 : 0,
          'indoor': (edge['indoor'] as bool) ? 1 : 0,
          'outdoor': (edge['outdoor'] as bool) ? 1 : 0,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  Future<Map<String, dynamic>> _readAsset(String path) async {
    final raw = await rootBundle.loadString(path);
    return jsonDecode(raw) as Map<String, dynamic>;
  }
}
