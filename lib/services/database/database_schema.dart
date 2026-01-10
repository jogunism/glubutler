import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

/// Database schema definition and migration logic
class DatabaseSchema {
  static const int version = 1;

  // Table names
  static const String tableGlucose = 'glucose_records';
  static const String tableMeal = 'meal_records';
  static const String tableExercise = 'exercise_records';
  static const String tableInsulin = 'insulin_records';
  static const String tableHealthConnection = 'health_connection';
  static const String tableHealthPermissions = 'health_permissions';
  static const String tableDiary = 'diary_entries';
  static const String tableDiaryFiles = 'diary_files';
  static const String tableReports = 'reports';

  /// Create all tables (called on first install)
  static Future<void> onCreate(Database db, int version) async {
    debugPrint('[DatabaseSchema] Creating database tables v$version...');

    await _createGlucoseTable(db);
    await _createMealTable(db);
    await _createExerciseTable(db);
    await _createInsulinTable(db);
    await _createHealthConnectionTable(db);
    await _createHealthPermissionsTable(db);
    await _createDiaryTable(db);
    await _createDiaryFilesTable(db);
    await _createReportsTable(db);
    await _createIndexes(db);

    debugPrint('[DatabaseSchema] Database tables created successfully');
  }

  /// Handle database migrations
  static Future<void> onUpgrade(
      Database db, int oldVersion, int newVersion) async {
    debugPrint(
        '[DatabaseSchema] Upgrading database from v$oldVersion to v$newVersion');

    // No migrations needed - app not yet released
    // Future migrations will go here
  }

  // ============ Table Creation ============

  static Future<void> _createGlucoseTable(Database db) async {
    await db.execute('''
      CREATE TABLE $tableGlucose (
        id TEXT PRIMARY KEY,
        value REAL NOT NULL,
        unit TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        meal_context TEXT,
        note TEXT,
        is_from_health_kit INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  static Future<void> _createMealTable(Database db) async {
    await db.execute('''
      CREATE TABLE $tableMeal (
        id TEXT PRIMARY KEY,
        diary_id TEXT NOT NULL,
        food_name TEXT,
        meal_time TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (diary_id) REFERENCES $tableDiary (id) ON DELETE CASCADE
      )
    ''');
  }

  static Future<void> _createExerciseTable(Database db) async {
    await db.execute('''
      CREATE TABLE $tableExercise (
        id TEXT PRIMARY KEY,
        timestamp TEXT NOT NULL,
        exercise_type TEXT NOT NULL,
        duration_minutes INTEGER NOT NULL,
        calories INTEGER,
        steps INTEGER,
        note TEXT,
        is_from_health_kit INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  static Future<void> _createInsulinTable(Database db) async {
    await db.execute('''
      CREATE TABLE $tableInsulin (
        id TEXT PRIMARY KEY,
        timestamp TEXT NOT NULL,
        units REAL NOT NULL,
        insulin_type TEXT NOT NULL,
        injection_site TEXT,
        note TEXT,
        is_from_health_kit INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  static Future<void> _createHealthConnectionTable(Database db) async {
    await db.execute('''
      CREATE TABLE $tableHealthConnection (
        id INTEGER PRIMARY KEY DEFAULT 1,
        is_connected INTEGER NOT NULL DEFAULT 0,
        sync_period_days INTEGER NOT NULL DEFAULT 7,
        connected_at TEXT,
        updated_at TEXT NOT NULL
      )
    ''');
  }

  static Future<void> _createHealthPermissionsTable(Database db) async {
    await db.execute('''
      CREATE TABLE $tableHealthPermissions (
        category TEXT PRIMARY KEY,
        permission_type TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
  }

  static Future<void> _createDiaryTable(Database db) async {
    await db.execute('''
      CREATE TABLE $tableDiary (
        id TEXT PRIMARY KEY,
        content TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
  }

  static Future<void> _createDiaryFilesTable(Database db) async {
    await db.execute('''
      CREATE TABLE $tableDiaryFiles (
        id TEXT PRIMARY KEY,
        diary_id TEXT NOT NULL,
        file_path TEXT NOT NULL,
        latitude REAL,
        longitude REAL,
        captured_at TEXT,
        file_size INTEGER,
        created_at TEXT NOT NULL,
        FOREIGN KEY (diary_id) REFERENCES $tableDiary (id) ON DELETE CASCADE
      )
    ''');
  }

  static Future<void> _createReportsTable(Database db) async {
    await db.execute('''
      CREATE TABLE $tableReports (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        start_date TEXT NOT NULL,
        end_date TEXT NOT NULL,
        content TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
  }

  // ============ Index Creation ============

  static Future<void> _createIndexes(Database db) async {
    await db.execute(
        'CREATE INDEX idx_glucose_timestamp ON $tableGlucose (timestamp)');
    await db.execute(
        'CREATE INDEX idx_meal_meal_time ON $tableMeal (meal_time)');
    await db.execute(
        'CREATE INDEX idx_meal_diary_id ON $tableMeal (diary_id)');
    await db.execute(
        'CREATE INDEX idx_exercise_timestamp ON $tableExercise (timestamp)');
    await db.execute(
        'CREATE INDEX idx_insulin_timestamp ON $tableInsulin (timestamp)');
    await db.execute(
        'CREATE INDEX idx_diary_timestamp ON $tableDiary (timestamp)');
    await db.execute(
        'CREATE INDEX idx_diary_files_diary_id ON $tableDiaryFiles (diary_id)');
    await db.execute(
        'CREATE INDEX idx_reports_created_at ON $tableReports (created_at)');
  }
}
