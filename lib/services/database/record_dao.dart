import 'package:sqflite/sqflite.dart';

import 'package:glu_butler/models/glucose_record.dart';
import 'package:glu_butler/models/meal_record.dart';
import 'package:glu_butler/models/exercise_record.dart';
import 'package:glu_butler/models/insulin_record.dart';
import 'package:glu_butler/models/diary_item.dart';
import 'package:glu_butler/models/diary_file.dart';

import 'database_schema.dart';

/// Data Access Object for health records (glucose, meal, exercise, insulin)
class RecordDao {
  final Database db;

  RecordDao(this.db);

  // ============ Glucose Records ============

  Future<int> insertGlucose(GlucoseRecord record) async {
    return await db.insert(
      DatabaseSchema.tableGlucose,
      _glucoseToMap(record),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<GlucoseRecord>> getGlucoseRecords({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    String? where;
    List<dynamic>? whereArgs;

    if (startDate != null && endDate != null) {
      where = 'timestamp >= ? AND timestamp <= ?';
      whereArgs = [startDate.toIso8601String(), endDate.toIso8601String()];
    }

    final maps = await db.query(
      DatabaseSchema.tableGlucose,
      where: where,
      whereArgs: whereArgs,
      orderBy: 'timestamp DESC',
    );

    return maps.map((map) => _mapToGlucose(map)).toList();
  }

  Future<int> deleteGlucose(String id) async {
    return await db.delete(
      DatabaseSchema.tableGlucose,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Batch delete glucose records by IDs (single transaction)
  Future<int> deleteGlucoseByIds(List<String> ids) async {
    if (ids.isEmpty) return 0;

    final placeholders = List.filled(ids.length, '?').join(',');
    return await db.delete(
      DatabaseSchema.tableGlucose,
      where: 'id IN ($placeholders)',
      whereArgs: ids,
    );
  }

  Map<String, dynamic> _glucoseToMap(GlucoseRecord record) {
    return {
      'id': record.id,
      'value': record.value,
      'unit': record.unit,
      'timestamp': record.timestamp.toIso8601String(),
      'meal_context': record.mealContext,
      'note': record.note,
      'is_from_health_kit': record.isFromHealthKit ? 1 : 0,
    };
  }

  GlucoseRecord _mapToGlucose(Map<String, dynamic> map) {
    return GlucoseRecord(
      id: map['id'] as String,
      value: map['value'] as double,
      unit: map['unit'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
      mealContext: map['meal_context'] as String?,
      note: map['note'] as String?,
      isFromHealthKit: (map['is_from_health_kit'] as int) == 1,
    );
  }

  // ============ Meal Records ============

  Future<int> insertMeal(MealRecord record) async {
    return await db.insert(
      DatabaseSchema.tableMeal,
      record.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<MealRecord>> getMealRecords({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    String? where;
    List<dynamic>? whereArgs;

    if (startDate != null && endDate != null) {
      where = 'meal_time >= ? AND meal_time <= ?';
      whereArgs = [startDate.toIso8601String(), endDate.toIso8601String()];
    }

    final maps = await db.query(
      DatabaseSchema.tableMeal,
      where: where,
      whereArgs: whereArgs,
      orderBy: 'meal_time DESC',
    );

    return maps.map((map) => MealRecord.fromMap(map)).toList();
  }

  Future<MealRecord?> getMealByDiaryId(String diaryId) async {
    final maps = await db.query(
      DatabaseSchema.tableMeal,
      where: 'diary_id = ?',
      whereArgs: [diaryId],
    );

    if (maps.isEmpty) return null;
    return MealRecord.fromMap(maps.first);
  }

  Future<int> deleteMeal(String id) async {
    return await db.delete(
      DatabaseSchema.tableMeal,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ============ Exercise Records ============

  Future<int> insertExercise(ExerciseRecord record) async {
    return await db.insert(
      DatabaseSchema.tableExercise,
      _exerciseToMap(record),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<ExerciseRecord>> getExerciseRecords({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    String? where;
    List<dynamic>? whereArgs;

    if (startDate != null && endDate != null) {
      where = 'timestamp >= ? AND timestamp <= ?';
      whereArgs = [startDate.toIso8601String(), endDate.toIso8601String()];
    }

    final maps = await db.query(
      DatabaseSchema.tableExercise,
      where: where,
      whereArgs: whereArgs,
      orderBy: 'timestamp DESC',
    );

    return maps.map((map) => _mapToExercise(map)).toList();
  }

  Future<int> deleteExercise(String id) async {
    return await db.delete(
      DatabaseSchema.tableExercise,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Map<String, dynamic> _exerciseToMap(ExerciseRecord record) {
    return {
      'id': record.id,
      'timestamp': record.timestamp.toIso8601String(),
      'exercise_type': record.exerciseType,
      'duration_minutes': record.durationMinutes,
      'calories': record.calories,
      'steps': record.steps,
      'note': record.note,
      'is_from_health_kit': record.isFromHealthKit ? 1 : 0,
    };
  }

  ExerciseRecord _mapToExercise(Map<String, dynamic> map) {
    return ExerciseRecord(
      id: map['id'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
      exerciseType: map['exercise_type'] as String,
      durationMinutes: map['duration_minutes'] as int,
      calories: map['calories'] as int?,
      steps: map['steps'] as int?,
      note: map['note'] as String?,
      isFromHealthKit: (map['is_from_health_kit'] as int) == 1,
    );
  }

  // ============ Insulin Records ============

  Future<int> insertInsulin(InsulinRecord record) async {
    return await db.insert(
      DatabaseSchema.tableInsulin,
      _insulinToMap(record),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<InsulinRecord>> getInsulinRecords({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    String? where;
    List<dynamic>? whereArgs;

    if (startDate != null && endDate != null) {
      where = 'timestamp >= ? AND timestamp <= ?';
      whereArgs = [startDate.toIso8601String(), endDate.toIso8601String()];
    }

    final maps = await db.query(
      DatabaseSchema.tableInsulin,
      where: where,
      whereArgs: whereArgs,
      orderBy: 'timestamp DESC',
    );

    return maps.map((map) => _mapToInsulin(map)).toList();
  }

  Future<int> deleteInsulin(String id) async {
    return await db.delete(
      DatabaseSchema.tableInsulin,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Batch delete insulin records by IDs (single transaction)
  Future<int> deleteInsulinByIds(List<String> ids) async {
    if (ids.isEmpty) return 0;

    final placeholders = List.filled(ids.length, '?').join(',');
    return await db.delete(
      DatabaseSchema.tableInsulin,
      where: 'id IN ($placeholders)',
      whereArgs: ids,
    );
  }

  Map<String, dynamic> _insulinToMap(InsulinRecord record) {
    return {
      'id': record.id,
      'timestamp': record.timestamp.toIso8601String(),
      'units': record.units,
      'insulin_type': record.insulinType.name,
      'injection_site': record.injectionSite,
      'note': record.note,
      'is_from_health_kit': record.isFromHealthKit ? 1 : 0,
    };
  }

  InsulinRecord _mapToInsulin(Map<String, dynamic> map) {
    return InsulinRecord(
      id: map['id'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
      units: map['units'] as double,
      insulinType: InsulinType.values.firstWhere(
        (e) => e.name == map['insulin_type'],
        orElse: () => InsulinType.rapidActing,
      ),
      injectionSite: map['injection_site'] as String?,
      note: map['note'] as String?,
      isFromHealthKit: (map['is_from_health_kit'] as int) == 1,
    );
  }

  // ============ Diary Records ============

  Future<int> insertDiary(DiaryItem entry) async {
    return await db.insert(
      DatabaseSchema.tableDiary,
      entry.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<DiaryItem>> getDiaryEntries({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    String? where;
    List<dynamic>? whereArgs;

    if (startDate != null && endDate != null) {
      where = 'timestamp >= ? AND timestamp <= ?';
      whereArgs = [startDate.toIso8601String(), endDate.toIso8601String()];
    }

    final maps = await db.query(
      DatabaseSchema.tableDiary,
      where: where,
      whereArgs: whereArgs,
      orderBy: 'timestamp DESC',
    );

    return maps.map((map) => DiaryItem.fromMap(map)).toList();
  }

  Future<DiaryItem?> getDiaryItem(String id) async {
    final maps = await db.query(
      DatabaseSchema.tableDiary,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return DiaryItem.fromMap(maps.first);
  }

  Future<int> updateDiary(DiaryItem entry) async {
    return await db.update(
      DatabaseSchema.tableDiary,
      entry.toMap(),
      where: 'id = ?',
      whereArgs: [entry.id],
    );
  }

  Future<int> deleteDiary(String id) async {
    // Cascade delete will automatically delete related files
    return await db.delete(
      DatabaseSchema.tableDiary,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ============ Diary Files ============

  Future<int> insertDiaryFile(DiaryFile file) async {
    return await db.insert(
      DatabaseSchema.tableDiaryFiles,
      file.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<DiaryFile>> getDiaryFiles(String diaryId) async {
    final maps = await db.query(
      DatabaseSchema.tableDiaryFiles,
      where: 'diary_id = ?',
      whereArgs: [diaryId],
      orderBy: 'created_at ASC',
    );

    return maps.map((map) => DiaryFile.fromMap(map)).toList();
  }

  Future<int> deleteDiaryFile(String id) async {
    return await db.delete(
      DatabaseSchema.tableDiaryFiles,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteDiaryFiles(String diaryId) async {
    return await db.delete(
      DatabaseSchema.tableDiaryFiles,
      where: 'diary_id = ?',
      whereArgs: [diaryId],
    );
  }

  // ============ Utility ============

  /// Clear all record tables
  Future<void> clearAllRecords() async {
    await db.delete(DatabaseSchema.tableGlucose);
    await db.delete(DatabaseSchema.tableMeal);
    await db.delete(DatabaseSchema.tableExercise);
    await db.delete(DatabaseSchema.tableInsulin);
    await db.delete(DatabaseSchema.tableDiary);
    await db.delete(DatabaseSchema.tableDiaryFiles);
  }
}
