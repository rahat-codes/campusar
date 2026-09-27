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
      version: 3,
      onCreate: (db, version) async {
        await _createProductionTables(db);
        await _createSurveyTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // v1 -> v2: adds the Survey Mode tables only. Production tables
        // (campus/buildings/entrances/facilities/route_nodes/route_edges)
        // and any data already in them are untouched — Survey Mode is
        // strictly additive (see README "Survey Mode").
        if (oldVersion < 2) {
          await _createSurveyTables(db);
        }
        // v2 -> v3: adds buildings.name_ko (V1 spec section 6's building
        // data model includes a Korean name). Nullable, so existing rows
        // are unaffected.
        if (oldVersion < 3) {
          await db.execute('ALTER TABLE buildings ADD COLUMN name_ko TEXT');
        }
      },
    );
  }

  Future<void> _createProductionTables(Database db) async {
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
            name_ko TEXT,
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
  }

  /// Survey Mode tables (section 15 of the V1.1 spec: "Extend the existing
  /// database/repository architecture cleanly" rather than a second
  /// database). Kept entirely separate from the production tables above —
  /// survey data is raw/reviewed/verified field data and must never be
  /// treated as production data automatically (see README "Raw vs
  /// verified vs production data").
  Future<void> _createSurveyTables(Database db) async {
    await db.execute('''
      CREATE TABLE survey_sessions (
        id TEXT PRIMARY KEY,
        surveyor_name TEXT,
        start_time TEXT NOT NULL,
        end_time TEXT,
        device_info TEXT,
        notes TEXT,
        dataset_version TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE survey_buildings (
        id TEXT PRIMARY KEY,
        session_id TEXT NOT NULL,
        building_number TEXT,
        name_en TEXT NOT NULL,
        name_ko TEXT,
        description TEXT,
        floors INTEGER,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        gps_accuracy REAL,
        gps_altitude REAL,
        gps_heading REAL,
        captured_at TEXT NOT NULL,
        photo_path TEXT,
        notes TEXT,
        status TEXT NOT NULL DEFAULT 'raw'
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_survey_buildings_session ON survey_buildings(session_id)',
    );

    await db.execute('''
      CREATE TABLE survey_entrances (
        id TEXT PRIMARY KEY,
        session_id TEXT NOT NULL,
        building_id TEXT NOT NULL,
        name TEXT,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        gps_accuracy REAL,
        gps_altitude REAL,
        gps_heading REAL,
        captured_at TEXT NOT NULL,
        accessible INTEGER NOT NULL DEFAULT 0,
        has_stairs INTEGER NOT NULL DEFAULT 0,
        has_ramp INTEGER NOT NULL DEFAULT 0,
        has_elevator INTEGER NOT NULL DEFAULT 0,
        photo_path TEXT,
        notes TEXT,
        status TEXT NOT NULL DEFAULT 'raw'
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_survey_entrances_building ON survey_entrances(building_id)',
    );

    await db.execute('''
      CREATE TABLE survey_facilities (
        id TEXT PRIMARY KEY,
        session_id TEXT NOT NULL,
        type TEXT NOT NULL,
        name TEXT,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        floor INTEGER,
        building_id TEXT,
        gps_accuracy REAL,
        gps_altitude REAL,
        gps_heading REAL,
        captured_at TEXT NOT NULL,
        accessible INTEGER NOT NULL DEFAULT 0,
        photo_path TEXT,
        notes TEXT,
        status TEXT NOT NULL DEFAULT 'raw'
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_survey_facilities_building ON survey_facilities(building_id)',
    );

    await db.execute('''
      CREATE TABLE survey_route_nodes (
        id TEXT PRIMARY KEY,
        session_id TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        type TEXT NOT NULL DEFAULT 'pathway',
        gps_accuracy REAL,
        captured_at TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'raw'
      )
    ''');

    await db.execute('''
      CREATE TABLE survey_route_edges (
        id TEXT PRIMARY KEY,
        session_id TEXT NOT NULL,
        from_node TEXT NOT NULL,
        to_node TEXT NOT NULL,
        distance REAL NOT NULL,
        accessible INTEGER NOT NULL DEFAULT 1,
        stairs INTEGER NOT NULL DEFAULT 0,
        ramp INTEGER NOT NULL DEFAULT 0,
        indoor INTEGER NOT NULL DEFAULT 0,
        outdoor INTEGER NOT NULL DEFAULT 1,
        surface TEXT,
        status TEXT NOT NULL DEFAULT 'raw'
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_survey_edges_from ON survey_route_edges(from_node)',
    );
    await db.execute(
      'CREATE INDEX idx_survey_edges_to ON survey_route_edges(to_node)',
    );

    // Raw GPS trace samples recorded during "Record Path" — kept
    // separately from the processed/simplified survey_route_nodes above
    // so a surveyor can review the original walked track later (section 8
    // of the V1.1 spec).
    await db.execute('''
      CREATE TABLE survey_raw_samples (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id TEXT NOT NULL,
        recording_id TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        accuracy REAL,
        altitude REAL,
        heading REAL,
        captured_at TEXT NOT NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_survey_raw_samples_recording ON survey_raw_samples(recording_id)',
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
