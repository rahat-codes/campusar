import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Local SQLite database holding a full offline copy of campus data:
/// campus info, buildings, entrances, facilities, and the pedestrian
/// route graph. This is what makes search, building details, and route
/// calculation work with no internet connection (section 17 of the
/// product spec).
///
/// Schema mirrors the backend's PostgreSQL schema (see
/// backend/app/models/) field-for-field, so syncing later is a
/// straightforward upsert rather than a data transformation.
class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'campusar.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE campus (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            university_name TEXT NOT NULL,
            country TEXT NOT NULL,
            city TEXT NOT NULL,
            latitude REAL NOT NULL,
            longitude REAL NOT NULL,
            map_configuration TEXT NOT NULL,
            version TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE buildings (
            id TEXT PRIMARY KEY,
            campus_id TEXT NOT NULL,
            name TEXT NOT NULL,
            short_name TEXT NOT NULL,
            building_number TEXT NOT NULL,
            latitude REAL NOT NULL,
            longitude REAL NOT NULL,
            description TEXT,
            image TEXT,
            floors INTEGER NOT NULL DEFAULT 1,
            entrance_ids TEXT NOT NULL,
            facility_ids TEXT NOT NULL,
            accessibility TEXT NOT NULL,
            destination_node_id TEXT,
            entrance_node_id TEXT
          )
        ''');
        await db.execute(
          'CREATE INDEX idx_buildings_campus ON buildings(campus_id)',
        );

        await db.execute('''
          CREATE TABLE entrances (
            id TEXT PRIMARY KEY,
            building_id TEXT NOT NULL,
            latitude REAL NOT NULL,
            longitude REAL NOT NULL,
            floor INTEGER NOT NULL DEFAULT 1,
            name TEXT NOT NULL
          )
        ''');
        await db.execute(
          'CREATE INDEX idx_entrances_building ON entrances(building_id)',
        );

        await db.execute('''
          CREATE TABLE facilities (
            id TEXT PRIMARY KEY,
            building_id TEXT NOT NULL,
            name TEXT NOT NULL,
            category TEXT NOT NULL DEFAULT 'general'
          )
        ''');
        await db.execute(
          'CREATE INDEX idx_facilities_building ON facilities(building_id)',
        );

        await db.execute('''
          CREATE TABLE route_nodes (
            id TEXT PRIMARY KEY,
            latitude REAL NOT NULL,
            longitude REAL NOT NULL,
            type TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE route_edges (
            id TEXT PRIMARY KEY,
            from_node TEXT NOT NULL,
            to_node TEXT NOT NULL,
            distance REAL NOT NULL,
            accessible INTEGER NOT NULL DEFAULT 1,
            indoor INTEGER NOT NULL DEFAULT 0,
            outdoor INTEGER NOT NULL DEFAULT 1
          )
        ''');
        await db.execute(
          'CREATE INDEX idx_edges_from ON route_edges(from_node)',
        );
        await db.execute(
          'CREATE INDEX idx_edges_to ON route_edges(to_node)',
        );

        await db.execute('''
          CREATE TABLE campus_meta (
            key TEXT PRIMARY KEY,
            value TEXT
          )
        ''');
      },
    );
  }

  /// True once the bundled/synced dataset has been loaded at least once.
  Future<bool> isSeeded() async {
    final db = await database;
    final result = await db.query('campus', limit: 1);
    return result.isNotEmpty;
  }

  /// Wipes all campus data tables (used before re-seeding from a newer
  /// synced dataset — see repositories/campus_repository.dart).
  Future<void> clearAll() async {
    final db = await database;
    final batch = db.batch();
    for (final table in [
      'facilities',
      'entrances',
      'route_edges',
      'route_nodes',
      'buildings',
      'campus',
    ]) {
      batch.delete(table);
    }
    await batch.commit(noResult: true);
  }
}
