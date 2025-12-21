import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

/// Database schema definition and migration logic
class DatabaseSchema {
  static const int version = 2;

  // Table names
  static const String tableGlucose = 'glucose_records';
  static const String tableMeal = 'meal_records';
  static const String tableExercise = 'exercise_records';
  static const String tableInsulin = 'insulin_records';
  static const String tableHealthConnection = 'health_connection';
  static const String tableHealthPermissions = 'health_permissions';

  /// Create all tables (called on first install)
  static Future<void> onCreate(Database db, int version) async {
    debugPrint('[DatabaseSchema] Creating database tables v$version...');

    await _createGlucoseTable(db);
    await _createMealTable(db);
    await _createExerciseTable(db);
    await _createInsulinTable(db);
    await _createHealthConnectionTable(db);
    await _createHealthPermissionsTable(db);
    await _createIndexes(db);

    debugPrint('[DatabaseSchema] Database tables created successfully');
  }

  /// Handle database migrations
  static Future<void> onUpgrade(
      Database db, int oldVersion, int newVersion) async {
    debugPrint(
        '[DatabaseSchema] Upgrading database from v$oldVersion to v$newVersion');

    if (oldVersion < 2) {
      await _createHealthConnectionTable(db);
      await _createHealthPermissionsTable(db);
    }

    // Add future migrations here:
    // if (oldVersion < 3) { ... }
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
        timestamp TEXT NOT NULL,
        meal_type TEXT NOT NULL,
        description TEXT,
        photo_urls TEXT,
        note TEXT,
        estimated_carbs INTEGER
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

  // ============ Index Creation ============

  static Future<void> _createIndexes(Database db) async {
    await db.execute(
        'CREATE INDEX idx_glucose_timestamp ON $tableGlucose (timestamp)');
    await db.execute(
        'CREATE INDEX idx_meal_timestamp ON $tableMeal (timestamp)');
    await db.execute(
        'CREATE INDEX idx_exercise_timestamp ON $tableExercise (timestamp)');
    await db.execute(
        'CREATE INDEX idx_insulin_timestamp ON $tableInsulin (timestamp)');
  }
}
