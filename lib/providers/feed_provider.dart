import 'package:flutter/foundation.dart';
import 'package:glu_butler/core/constants/app_constants.dart';
import 'package:glu_butler/models/feed_item.dart';
import 'package:glu_butler/models/glucose_record.dart';
import 'package:glu_butler/models/exercise_record.dart';
import 'package:glu_butler/models/sleep_record.dart';
import 'package:glu_butler/models/meal_record.dart';
import 'package:glu_butler/models/water_record.dart';
import 'package:glu_butler/models/insulin_record.dart';
import 'package:glu_butler/services/health_service.dart';
import 'package:glu_butler/services/settings_service.dart';

class FeedProvider extends ChangeNotifier {
  final HealthService _healthService = HealthService();
  SettingsService? _settingsService;

  List<FeedItem> _items = [];
  List<FeedItem> get items => _items;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isHealthConnected = false;
  bool get isHealthConnected => _isHealthConnected;

  String? _error;
  String? get error => _error;

  int? _todaySteps;
  int? get todaySteps => _todaySteps;

  double? _todayWaterMl;
  double? get todayWaterMl => _todayWaterMl;

  // Local records (manual input)
  final List<GlucoseRecord> _localGlucoseRecords = [];
  final List<ExerciseRecord> _localExerciseRecords = [];
  final List<SleepRecord> _localSleepRecords = [];
  final List<MealRecord> _localMealRecords = [];
  final List<WaterRecord> _localWaterRecords = [];
  final List<InsulinRecord> _localInsulinRecords = [];

  void setSettingsService(SettingsService settingsService) {
    _settingsService = settingsService;
  }

  Future<void> initialize() async {
    _isHealthConnected = await _healthService.hasPermissions();

    // Add dummy data for design preview
    _loadDummyData();

    notifyListeners();
  }

  void _loadDummyData() {
    final now = DateTime.now();

    // Today's data
    _items.addAll([
      // Glucose from Apple Health (high)
      FeedItem.fromGlucose(GlucoseRecord(
        id: '1',
        value: 148,
        unit: 'mg/dL',
        timestamp: now.subtract(const Duration(hours: 1)),
        isFromHealthKit: true,
      )),
      // Glucose from user (normal)
      FeedItem.fromGlucose(GlucoseRecord(
        id: '2',
        value: 95,
        unit: 'mg/dL',
        timestamp: now.subtract(const Duration(hours: 3)),
        isFromHealthKit: false,
      )),
      // Meal from user
      FeedItem.fromMeal(MealRecord(
        id: '3',
        mealType: 'dinner',
        description: '치킨 샐러드, 현미밥',
        timestamp: now.subtract(const Duration(hours: 2)),
      )),
      // Exercise from Apple Health
      FeedItem.fromExercise(ExerciseRecord(
        id: '4',
        exerciseType: 'running',
        durationMinutes: 32,
        calories: 280,
        timestamp: now.subtract(const Duration(hours: 5)),
        isFromHealthKit: true,
      )),
      // Water from Apple Health
      FeedItem.fromWater(WaterRecord(
        id: '5',
        amountMl: 350,
        timestamp: now.subtract(const Duration(hours: 4)),
        isFromHealthKit: true,
      )),
      // Insulin from user
      FeedItem.fromInsulin(InsulinRecord(
        id: '6',
        timestamp: now.subtract(const Duration(hours: 2, minutes: 30)),
        units: 4.0,
        insulinType: InsulinType.rapidActing,
        isFromHealthKit: false,
      )),
    ]);

    // Yesterday's data
    final yesterday = now.subtract(const Duration(days: 1));
    _items.addAll([
      // Glucose (low)
      FeedItem.fromGlucose(GlucoseRecord(
        id: '7',
        value: 65,
        unit: 'mg/dL',
        timestamp: yesterday.subtract(const Duration(hours: 2)),
        isFromHealthKit: true,
      )),
      // Sleep
      FeedItem.fromSleep(SleepRecord(
        id: '8',
        startTime: yesterday.subtract(const Duration(hours: 8)),
        endTime: yesterday,
        durationMinutes: 480,
        stage: SleepStage.deep,
        isFromHealthKit: true,
      )),
      // Meal
      FeedItem.fromMeal(MealRecord(
        id: '9',
        mealType: 'lunch',
        description: '된장찌개, 불고기',
        timestamp: yesterday.subtract(const Duration(hours: 6)),
      )),
      // Insulin
      FeedItem.fromInsulin(InsulinRecord(
        id: '10',
        timestamp: yesterday.subtract(const Duration(hours: 7)),
        units: 12.0,
        insulinType: InsulinType.longActing,
        isFromHealthKit: false,
      )),
    ]);

    _items.sort();
  }

  Future<bool> connectToHealth() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _isHealthConnected = await _healthService.requestAuthorization();
      if (_isHealthConnected) {
        await refreshData();
      }
      return _isHealthConnected;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final now = DateTime.now();
      final syncDays = _settingsService?.syncPeriod ?? AppConstants.defaultSyncPeriod;
      final startDate = now.subtract(Duration(days: syncDays));

      final List<FeedItem> allItems = [];

      // Fetch from HealthKit if connected
      if (_isHealthConnected) {
        final glucoseRecords = await _healthService.fetchGlucoseData(
          startDate: startDate,
          endDate: now,
        );
        allItems.addAll(glucoseRecords.map(FeedItem.fromGlucose));

        final exerciseRecords = await _healthService.fetchWorkoutData(
          startDate: startDate,
          endDate: now,
        );
        allItems.addAll(exerciseRecords.map(FeedItem.fromExercise));

        final sleepRecords = await _healthService.fetchSleepData(
          startDate: startDate,
          endDate: now,
        );
        allItems.addAll(sleepRecords.map(FeedItem.fromSleep));

        final waterRecords = await _healthService.fetchWaterData(
          startDate: startDate,
          endDate: now,
        );
        allItems.addAll(waterRecords.map(FeedItem.fromWater));

        final insulinRecords = await _healthService.fetchInsulinData(
          startDate: startDate,
          endDate: now,
        );
        allItems.addAll(insulinRecords.map(FeedItem.fromInsulin));

        _todaySteps = await _healthService.fetchTodaySteps();
        _todayWaterMl = await _healthService.fetchTodayWaterIntake();
      }

      // Add local records
      allItems.addAll(_localGlucoseRecords.map(FeedItem.fromGlucose));
      allItems.addAll(_localExerciseRecords.map(FeedItem.fromExercise));
      allItems.addAll(_localSleepRecords.map(FeedItem.fromSleep));
      allItems.addAll(_localMealRecords.map(FeedItem.fromMeal));
      allItems.addAll(_localWaterRecords.map(FeedItem.fromWater));
      allItems.addAll(_localInsulinRecords.map(FeedItem.fromInsulin));

      // Keep dummy data if no real data
      if (allItems.isEmpty) {
        _loadDummyData();
      } else {
        // Sort by timestamp (newest first)
        allItems.sort();
        _items = allItems;
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('[FeedProvider] Error refreshing data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add local glucose record
  void addGlucoseRecord(GlucoseRecord record) {
    _localGlucoseRecords.add(record);
    _items.add(FeedItem.fromGlucose(record));
    _items.sort();
    notifyListeners();

    // Optionally write to HealthKit
    if (_isHealthConnected) {
      _healthService.writeGlucoseRecord(record);
    }
  }

  // Add local exercise record
  void addExerciseRecord(ExerciseRecord record) {
    _localExerciseRecords.add(record);
    _items.add(FeedItem.fromExercise(record));
    _items.sort();
    notifyListeners();
  }

  // Add local sleep record
  void addSleepRecord(SleepRecord record) {
    _localSleepRecords.add(record);
    _items.add(FeedItem.fromSleep(record));
    _items.sort();
    notifyListeners();
  }

  // Add local meal record
  void addMealRecord(MealRecord record) {
    _localMealRecords.add(record);
    _items.add(FeedItem.fromMeal(record));
    _items.sort();
    notifyListeners();
  }

  // Add local insulin record
  void addInsulinRecord(InsulinRecord record) {
    _localInsulinRecords.add(record);
    _items.add(FeedItem.fromInsulin(record));
    _items.sort();
    notifyListeners();

    // Write to HealthKit if connected
    if (_isHealthConnected) {
      _healthService.writeInsulinRecord(record);
    }
  }

  // Get items for a specific date
  List<FeedItem> getItemsForDate(DateTime date) {
    return _items.where((item) {
      return item.timestamp.year == date.year &&
          item.timestamp.month == date.month &&
          item.timestamp.day == date.day;
    }).toList();
  }

  // Get items grouped by date
  Map<DateTime, List<FeedItem>> get itemsByDate {
    final Map<DateTime, List<FeedItem>> grouped = {};
    for (final item in _items) {
      final dateKey = DateTime(
        item.timestamp.year,
        item.timestamp.month,
        item.timestamp.day,
      );
      grouped.putIfAbsent(dateKey, () => []).add(item);
    }
    return grouped;
  }
}
