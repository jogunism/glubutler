import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import 'package:glu_butler/models/glucose_record.dart';
import 'package:glu_butler/models/meal_record.dart';
import 'package:glu_butler/models/exercise_record.dart';
import 'package:glu_butler/models/insulin_record.dart';
import 'package:glu_butler/models/diary_item.dart';
import 'package:glu_butler/models/diary_file.dart';
import 'package:glu_butler/models/report.dart';

import 'database/database_schema.dart';
import 'database/health_dao.dart';
import 'database/record_dao.dart';
import 'database/report_dao.dart';

// Re-export models for convenience
export 'database/health_dao.dart' show HealthConnectionInfo, HealthPermissionType;

/// Database service - manages database connection and provides access to DAOs
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;
  static const String _databaseName = 'glu_butler.db';

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  // DAOs
  HealthDao? _healthDao;
  RecordDao? _recordDao;
  ReportDao? _reportDao;

  HealthDao get healthDao {
    if (_healthDao == null) {
      throw StateError('DatabaseService not initialized. Call initialize() first.');
    }
    return _healthDao!;
  }

  RecordDao get recordDao {
    if (_recordDao == null) {
      throw StateError('DatabaseService not initialized. Call initialize() first.');
    }
    return _recordDao!;
  }

  ReportDao get reportDao {
    if (_reportDao == null) {
      throw StateError('DatabaseService not initialized. Call initialize() first.');
    }
    return _reportDao!;
  }

  /// Initialize database (call this at app startup)
  Future<void> initialize() async {
    if (_isInitialized) return;

    final db = await _initDatabase();
    _healthDao = HealthDao(db);
    _recordDao = RecordDao(db);
    _reportDao = ReportDao(db);
    _isInitialized = true;
  }

  Future<Database> _initDatabase() async {
    if (_database != null) return _database!;

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _databaseName);

    debugPrint('[DatabaseService] Database path: $path');

    _database = await openDatabase(
      path,
      version: DatabaseSchema.version,
      onCreate: DatabaseSchema.onCreate,
      onUpgrade: DatabaseSchema.onUpgrade,
    );

    return _database!;
  }

  // ============ Convenience Methods (delegates to DAOs) ============

  // Health Connection
  Future<HealthConnectionInfo> getHealthConnection() =>
      healthDao.getHealthConnection();

  Future<void> saveHealthConnection(HealthConnectionInfo info) =>
      healthDao.saveHealthConnection(info);

  Future<void> updateSyncPeriod(int days) =>
      healthDao.updateSyncPeriod(days);

  // Health Permissions
  Future<Map<String, HealthPermissionType>> getHealthPermissions() =>
      healthDao.getHealthPermissions();

  Future<HealthPermissionType?> getHealthPermission(String category) =>
      healthDao.getHealthPermission(category);

  Future<void> saveHealthPermission(String category, HealthPermissionType type) =>
      healthDao.saveHealthPermission(category, type);

  Future<void> saveHealthPermissions(Map<String, HealthPermissionType> permissions) =>
      healthDao.saveHealthPermissions(permissions);

  Future<void> clearHealthPermissions() =>
      healthDao.clearHealthPermissions();

  // Records - delegate to recordDao
  Future<int> insertGlucose(GlucoseRecord record) => recordDao.insertGlucose(record);
  Future<List<GlucoseRecord>> getGlucoseRecords({DateTime? startDate, DateTime? endDate}) =>
      recordDao.getGlucoseRecords(startDate: startDate, endDate: endDate);
  Future<int> deleteGlucose(String id) => recordDao.deleteGlucose(id);
  Future<int> deleteGlucoseByIds(List<String> ids) => recordDao.deleteGlucoseByIds(ids);

  Future<int> insertMeal(MealRecord record) => recordDao.insertMeal(record);
  Future<List<MealRecord>> getMealRecords({DateTime? startDate, DateTime? endDate}) =>
      recordDao.getMealRecords(startDate: startDate, endDate: endDate);
  Future<MealRecord?> getMealByDiaryId(String diaryId) => recordDao.getMealByDiaryId(diaryId);
  Future<int> deleteMeal(String id) => recordDao.deleteMeal(id);

  Future<int> insertExercise(ExerciseRecord record) => recordDao.insertExercise(record);
  Future<List<ExerciseRecord>> getExerciseRecords({DateTime? startDate, DateTime? endDate}) =>
      recordDao.getExerciseRecords(startDate: startDate, endDate: endDate);
  Future<int> deleteExercise(String id) => recordDao.deleteExercise(id);

  Future<int> insertInsulin(InsulinRecord record) => recordDao.insertInsulin(record);
  Future<List<InsulinRecord>> getInsulinRecords({DateTime? startDate, DateTime? endDate}) =>
      recordDao.getInsulinRecords(startDate: startDate, endDate: endDate);
  Future<int> deleteInsulin(String id) => recordDao.deleteInsulin(id);
  Future<int> deleteInsulinByIds(List<String> ids) => recordDao.deleteInsulinByIds(ids);

  // Diary entries
  Future<int> insertDiary(DiaryItem entry) => recordDao.insertDiary(entry);
  Future<List<DiaryItem>> getDiaryEntries({DateTime? startDate, DateTime? endDate}) =>
      recordDao.getDiaryEntries(startDate: startDate, endDate: endDate);
  Future<DiaryItem?> getDiaryItem(String id) => recordDao.getDiaryItem(id);
  Future<int> updateDiary(DiaryItem entry) => recordDao.updateDiary(entry);
  Future<int> deleteDiary(String id) => recordDao.deleteDiary(id);

  // Diary files
  Future<int> insertDiaryFile(DiaryFile file) => recordDao.insertDiaryFile(file);
  Future<List<DiaryFile>> getDiaryFiles(String diaryId) => recordDao.getDiaryFiles(diaryId);
  Future<int> deleteDiaryFile(String id) => recordDao.deleteDiaryFile(id);
  Future<int> deleteDiaryFiles(String diaryId) => recordDao.deleteDiaryFiles(diaryId);

  // Reports
  Future<int> insertReport(Report report) => reportDao.insertReport(report);
  Future<Report?> getLatestReport() => reportDao.getLatestReport();
  Future<List<Report>> getAllReports() => reportDao.getAllReports();
  Future<Report?> getReportById(int id) => reportDao.getReportById(id);
  Future<int> deleteReport(int id) => reportDao.deleteReport(id);

  // ============ Utility Methods ============

  /// Delete all data from all tables
  Future<void> clearAllData() async {
    await recordDao.clearAllRecords();
    await healthDao.clearHealthPermissions();
    debugPrint('[DatabaseService] All data cleared');
  }

  /// Close database connection
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
      _healthDao = null;
      _recordDao = null;
      _reportDao = null;
      _isInitialized = false;
      debugPrint('[DatabaseService] Database closed');
    }
  }

  /// Get database file path (useful for debugging)
  Future<String> getDatabasePath() async {
    final dbPath = await getDatabasesPath();
    return join(dbPath, _databaseName);
  }
}
