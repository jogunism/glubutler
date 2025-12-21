import 'package:flutter/foundation.dart';
import 'package:health/health.dart';
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
import 'package:glu_butler/services/database_service.dart';

/// Enum for health data categories shown in UI
enum HealthDataCategory {
  bloodGlucose,
  insulin,
  workouts,
  sleep,
  weight,
  water,
  menstrualCycle,
  steps,
  mindfulness,
}

class FeedProvider extends ChangeNotifier {
  final HealthService _healthService = HealthService();
  final DatabaseService _databaseService = DatabaseService();
  SettingsService? _settingsService;

  List<FeedItem> _items = [];
  List<FeedItem> get items => _items;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isHealthConnected = false;
  bool get isHealthConnected => _isHealthConnected;

  String? _error;
  String? get error => _error;

  // Permission status for each category (true = granted, false = denied, null = unknown)
  final Map<HealthDataCategory, bool?> _categoryPermissions = {};
  Map<HealthDataCategory, bool?> get categoryPermissions => Map.unmodifiable(_categoryPermissions);

  int? _todaySteps;
  int? get todaySteps => _todaySteps;

  final Map<DateTime, DailyActivityData> _activityByDate = {};
  Map<DateTime, DailyActivityData> get activityByDate => Map.unmodifiable(_activityByDate);

  double? _todayWaterMl;
  double? get todayWaterMl => _todayWaterMl;

  void setSettingsService(SettingsService settingsService) {
    _settingsService = settingsService;
  }

  Future<void> initialize() async {
    // Load connection status from DB first
    final healthConnection = await _databaseService.getHealthConnection();
    _isHealthConnected = healthConnection.isConnected;

    // Verify actual permissions with HealthKit if DB says connected
    if (_isHealthConnected) {
      // Check actual write permission by testing
      await _healthService.checkPermissionStatus();
      final hasWritePermission =
          _healthService.getPermissionStatus(HealthDataType.BLOOD_GLUCOSE);

      if (!hasWritePermission) {
        // Write permission revoked, mark as disconnected
        _isHealthConnected = false;
        await _databaseService.saveHealthConnection(
          healthConnection.copyWith(
            isConnected: false,
            updatedAt: DateTime.now(),
          ),
        );
        await _databaseService.clearHealthPermissions();
        debugPrint('[FeedProvider] Initialize: disconnected - write permission revoked');
      } else {
        // Still connected, sync permissions from HealthService
        await _syncPermissionsFromHealthService();
        debugPrint('[FeedProvider] Initialize: still connected with write permission');
      }
    }

    // Load initial data
    await refreshData();

    notifyListeners();
  }

  Future<bool> connectToHealth() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // requestAuthorization now checks actual write permission internally
      _isHealthConnected = await _healthService.requestAuthorization();

      if (_isHealthConnected) {
        // Save connection status to DB only if write permission was granted
        final syncPeriod = _settingsService?.syncPeriod ?? AppConstants.defaultSyncPeriod;
        await _databaseService.saveHealthConnection(
          HealthConnectionInfo(
            isConnected: true,
            syncPeriodDays: syncPeriod,
            connectedAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        // Update local permission map from HealthService
        await _syncPermissionsFromHealthService();
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

  /// Sync permission status from HealthService to local map and DB
  /// Called after requestAuthorization which already checked permissions
  Future<void> _syncPermissionsFromHealthService() async {
    _categoryPermissions.clear();
    _categoryPermissions[HealthDataCategory.bloodGlucose] =
        _healthService.getPermissionStatus(HealthDataType.BLOOD_GLUCOSE);
    _categoryPermissions[HealthDataCategory.insulin] =
        _healthService.getPermissionStatus(HealthDataType.INSULIN_DELIVERY);
    _categoryPermissions[HealthDataCategory.workouts] =
        _healthService.getPermissionStatus(HealthDataType.WORKOUT);
    _categoryPermissions[HealthDataCategory.steps] =
        _healthService.getPermissionStatus(HealthDataType.STEPS);
    _categoryPermissions[HealthDataCategory.sleep] =
        _healthService.getPermissionStatus(HealthDataType.SLEEP_ASLEEP);
    _categoryPermissions[HealthDataCategory.weight] =
        _healthService.getPermissionStatus(HealthDataType.WEIGHT);
    _categoryPermissions[HealthDataCategory.water] =
        _healthService.getPermissionStatus(HealthDataType.WATER);
    _categoryPermissions[HealthDataCategory.menstrualCycle] =
        _healthService.getPermissionStatus(HealthDataType.MENSTRUATION_FLOW);
    _categoryPermissions[HealthDataCategory.mindfulness] =
        _healthService.getPermissionStatus(HealthDataType.MINDFULNESS);

    debugPrint('[FeedProvider] Synced permissions from HealthService: $_categoryPermissions');

    // Save permissions to DB
    await _savePermissionsToDb();
  }

  /// Update permission status for each health data category
  Future<void> _updatePermissionStatus() async {
    await _healthService.checkPermissionStatus();

    _categoryPermissions.clear();
    _categoryPermissions[HealthDataCategory.bloodGlucose] =
        _healthService.getPermissionStatus(HealthDataType.BLOOD_GLUCOSE);
    _categoryPermissions[HealthDataCategory.insulin] =
        _healthService.getPermissionStatus(HealthDataType.INSULIN_DELIVERY);
    _categoryPermissions[HealthDataCategory.workouts] =
        _healthService.getPermissionStatus(HealthDataType.WORKOUT);
    _categoryPermissions[HealthDataCategory.steps] =
        _healthService.getPermissionStatus(HealthDataType.STEPS);
    _categoryPermissions[HealthDataCategory.sleep] =
        _healthService.getPermissionStatus(HealthDataType.SLEEP_ASLEEP);
    _categoryPermissions[HealthDataCategory.weight] =
        _healthService.getPermissionStatus(HealthDataType.WEIGHT);
    _categoryPermissions[HealthDataCategory.water] =
        _healthService.getPermissionStatus(HealthDataType.WATER);
    _categoryPermissions[HealthDataCategory.menstrualCycle] =
        _healthService.getPermissionStatus(HealthDataType.MENSTRUATION_FLOW);
    _categoryPermissions[HealthDataCategory.mindfulness] =
        _healthService.getPermissionStatus(HealthDataType.MINDFULNESS);

    debugPrint('[FeedProvider] Category permissions: $_categoryPermissions');

    // Save permissions to DB
    await _savePermissionsToDb();
  }

  Future<void> _savePermissionsToDb() async {
    final permissionsToSave = <String, HealthPermissionType>{};

    // Write types (read_write)
    if (_categoryPermissions[HealthDataCategory.bloodGlucose] == true) {
      permissionsToSave[HealthDataCategory.bloodGlucose.name] =
          HealthPermissionType.readWrite;
    }
    if (_categoryPermissions[HealthDataCategory.insulin] == true) {
      permissionsToSave[HealthDataCategory.insulin.name] =
          HealthPermissionType.readWrite;
    }

    // Read-only types
    final readOnlyCategories = [
      HealthDataCategory.workouts,
      HealthDataCategory.sleep,
      HealthDataCategory.weight,
      HealthDataCategory.water,
      HealthDataCategory.menstrualCycle,
      HealthDataCategory.steps,
      HealthDataCategory.mindfulness,
    ];

    for (final category in readOnlyCategories) {
      // For read-only, we can't verify on iOS, so save as readOnly if connected
      if (_isHealthConnected) {
        permissionsToSave[category.name] = HealthPermissionType.readOnly;
      }
    }

    await _databaseService.saveHealthPermissions(permissionsToSave);
    debugPrint('[FeedProvider] Saved ${permissionsToSave.length} permissions to DB');
  }

  /// Refresh permission status (call when returning from Health app settings)
  /// Also updates connection status if write permissions are revoked
  /// Returns: null if no change, true if connected, false if disconnected
  Future<bool?> refreshPermissionStatus() async {
    await _updatePermissionStatus();

    // Check if write permission (blood glucose) is still granted
    final hasWritePermission =
        _categoryPermissions[HealthDataCategory.bloodGlucose] == true;

    bool? statusChanged;

    // If previously connected but now no write permission, mark as disconnected
    if (_isHealthConnected && !hasWritePermission) {
      _isHealthConnected = false;
      await _databaseService.saveHealthConnection(
        HealthConnectionInfo(
          isConnected: false,
          syncPeriodDays:
              _settingsService?.syncPeriod ?? AppConstants.defaultSyncPeriod,
          connectedAt: null,
          updatedAt: DateTime.now(),
        ),
      );
      await _databaseService.clearHealthPermissions();
      statusChanged = false; // Now disconnected
      debugPrint('[FeedProvider] Health disconnected - write permission revoked');

      // Refresh data to remove HealthKit items
      await refreshData();
    }
    // If previously disconnected but now has write permission, mark as connected
    else if (!_isHealthConnected && hasWritePermission) {
      _isHealthConnected = true;
      await _databaseService.saveHealthConnection(
        HealthConnectionInfo(
          isConnected: true,
          syncPeriodDays:
              _settingsService?.syncPeriod ?? AppConstants.defaultSyncPeriod,
          connectedAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      await _savePermissionsToDb();
      statusChanged = true; // Now connected
      debugPrint('[FeedProvider] Health connected - write permission granted');

      // Refresh data to load HealthKit items
      await refreshData();
    }

    notifyListeners();
    return statusChanged;
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

        // Fetch activity (steps + distance) for all dates in the sync period
        final activityData = await _healthService.fetchDailyActivityByDate(
          startDate: startDate,
          endDate: now,
        );
        _activityByDate.clear();
        _activityByDate.addAll(activityData);
      }

      // Add local records from database
      final localGlucose = await _databaseService.getGlucoseRecords(
        startDate: startDate,
        endDate: now,
      );
      allItems.addAll(localGlucose.map(FeedItem.fromGlucose));

      final localMeals = await _databaseService.getMealRecords(
        startDate: startDate,
        endDate: now,
      );
      allItems.addAll(localMeals.map(FeedItem.fromMeal));

      final localExercise = await _databaseService.getExerciseRecords(
        startDate: startDate,
        endDate: now,
      );
      allItems.addAll(localExercise.map(FeedItem.fromExercise));

      final localInsulin = await _databaseService.getInsulinRecords(
        startDate: startDate,
        endDate: now,
      );
      allItems.addAll(localInsulin.map(FeedItem.fromInsulin));

      // Sort by timestamp (newest first)
      allItems.sort();
      _items = allItems;
    } catch (e) {
      _error = e.toString();
      debugPrint('[FeedProvider] Error refreshing data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add local glucose record
  Future<void> addGlucoseRecord(GlucoseRecord record) async {
    await _databaseService.insertGlucose(record);
    _items.add(FeedItem.fromGlucose(record));
    _items.sort();
    notifyListeners();

    // Optionally write to HealthKit
    if (_isHealthConnected) {
      _healthService.writeGlucoseRecord(record);
    }
  }

  // Add local exercise record
  Future<void> addExerciseRecord(ExerciseRecord record) async {
    await _databaseService.insertExercise(record);
    _items.add(FeedItem.fromExercise(record));
    _items.sort();
    notifyListeners();
  }

  // Add local meal record
  Future<void> addMealRecord(MealRecord record) async {
    await _databaseService.insertMeal(record);
    _items.add(FeedItem.fromMeal(record));
    _items.sort();
    notifyListeners();
  }

  // Add local insulin record
  Future<void> addInsulinRecord(InsulinRecord record) async {
    await _databaseService.insertInsulin(record);
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
