import 'package:flutter/foundation.dart';

import 'package:glu_butler/models/meal_record.dart';
import 'package:glu_butler/services/database_service.dart';

/// Repository for meal records.
///
/// Handles reading/writing meal data to local database.
/// Meals are always stored locally (not in HealthKit).
class MealRepository {
  final DatabaseService _databaseService;

  MealRepository({
    DatabaseService? databaseService,
  }) : _databaseService = databaseService ?? DatabaseService();

  /// Save a meal record.
  ///
  /// Returns true if save was successful.
  Future<bool> save(MealRecord record) async {
    try {
      await _databaseService.insertMeal(record);
      return true;
    } catch (e) {
      debugPrint('[MealRepository] Failed to save meal: $e');
      return false;
    }
  }

  /// Fetch meal records within a date range.
  ///
  /// Returns list sorted by meal_time (newest first).
  Future<List<MealRecord>> fetch({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return await _databaseService.getMealRecords(
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Fetch a meal record by diary ID.
  ///
  /// Returns null if no meal exists for the given diary.
  Future<MealRecord?> fetchByDiaryId(String diaryId) async {
    return await _databaseService.getMealByDiaryId(diaryId);
  }

  /// Delete a meal record by ID.
  Future<void> delete(String id) async {
    await _databaseService.deleteMeal(id);
  }
}
