import 'package:flutter/foundation.dart';
import 'package:glu_butler/core/constants/app_constants.dart';
import 'package:glu_butler/services/health_service.dart';
import 'package:glu_butler/models/feed_item.dart';
import 'package:glu_butler/models/glucose_record.dart';
import 'package:glu_butler/models/exercise_record.dart';
import 'package:glu_butler/models/meal_record.dart';
import 'package:glu_butler/models/insulin_record.dart';
import 'package:glu_butler/models/glucose_range_settings.dart';
import 'package:glu_butler/services/settings_service.dart';
import 'package:glu_butler/services/database_service.dart';
import 'package:glu_butler/services/cgm_grouping_service.dart';
import 'package:glu_butler/services/sleep_grouping_service.dart';
import 'package:glu_butler/services/water_grouping_service.dart';
import 'package:glu_butler/repositories/glucose_repository.dart';
import 'package:glu_butler/repositories/insulin_repository.dart';

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

/// Result of migration operation
class MigrationResult {
  final int totalAttempted;
  final int successCount;
  final int failedCount;

  MigrationResult({
    required this.totalAttempted,
    required this.successCount,
    required this.failedCount,
  });

  bool get hasFailures => failedCount > 0;
  bool get isFullSuccess => failedCount == 0 && successCount > 0;
  bool get hasNoRecords => totalAttempted == 0;
}

class FeedProvider extends ChangeNotifier {
  final HealthService _healthService = HealthService();
  final DatabaseService _databaseService = DatabaseService();
  final GlucoseRepository _glucoseRepository = GlucoseRepository();
  final InsulinRepository _insulinRepository = InsulinRepository();
  SettingsService? _settingsService;

  List<FeedItem> _items = [];
  List<FeedItem> get items => _items;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isHealthConnected = false;
  bool get isHealthConnected => _isHealthConnected;

  /// Whether we have requested health permissions (can read data even if write is denied)
  bool get hasHealthReadAccess => _healthService.hasRequestedPermissions;

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

  // IDs of top 10 deletable glucose items to bounce after refresh
  final Set<String> _bouncableItemIds = {};
  Set<String> get bouncableItemIds => _bouncableItemIds;

  // Map of item ID to bounce callback
  final Map<String, void Function()> _bounceCallbacks = {};

  void registerBounceCallback(String itemId, void Function() callback) {
    _bounceCallbacks[itemId] = callback;
  }

  void unregisterBounceCallback(String itemId) {
    _bounceCallbacks.remove(itemId);
  }

  void triggerBounce() {
    for (final callback in _bounceCallbacks.values) {
      callback();
    }
  }

  void setSettingsService(SettingsService settingsService) {
    _settingsService = settingsService;
  }

  Future<void> initialize() async {
    // Load connection status from DB first
    final healthConnection = await _databaseService.getHealthConnection();
    _isHealthConnected = healthConnection.isConnected;

    // If user has ever connected to Health (connectedAt exists or currently connected),
    // mark as having requested permissions. This allows reading data even if write permission was later revoked.
    final hasEverConnected = healthConnection.connectedAt != null || healthConnection.isConnected;
    if (hasEverConnected) {
      _healthService.setHasRequestedPermissions(true);
    }

    // Verify actual permissions with HealthKit if we have ever connected
    if (hasEverConnected) {
      // Check actual write permission by testing
      await _healthService.checkPermissionStatus();
      final hasWritePermission =
          _healthService.getPermissionStatus(HealthDataType.BLOOD_GLUCOSE);

      if (!hasWritePermission) {
        // Write permission revoked, mark as disconnected (but keep connectedAt for read access)
        _isHealthConnected = false;
        if (healthConnection.isConnected) {
          await _databaseService.saveHealthConnection(
            healthConnection.copyWith(
              isConnected: false,
              updatedAt: DateTime.now(),
            ),
          );
        }
        await _databaseService.clearHealthPermissions();
      } else {
        // Has write permission
        _isHealthConnected = true;
        await _syncPermissionsFromHealthService();
      }
    }

    // Load initial data
    await refreshData();

    // Retry pending migration if connected (fire-and-forget)
    if (_isHealthConnected) {
      _retryPendingMigration();
    }

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

        // Migrate local records to HealthKit (fire-and-forget)
        _migrateLocalToHealthInBackground();

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

    // Save permissions to DB
    await _savePermissionsToDb();
  }

  // Callback for migration completion (set by UI to show toast)
  void Function(MigrationResult result)? onMigrationComplete;

  /// Migrate local glucose/insulin records to HealthKit
  /// Called when HealthKit write permission is granted
  /// Runs in background (fire-and-forget) and calls onMigrationComplete when done
  void _migrateLocalToHealthInBackground() {
    // Fire-and-forget: don't await
    _performMigration().then((result) {
      if (!result.hasNoRecords) {
        onMigrationComplete?.call(result);
      }
      // Refresh data after migration completes
      refreshData();
    });
  }

  /// Perform the actual migration and return result
  Future<MigrationResult> _performMigration() async {
    final (glucoseAttempted, glucoseSuccess) = await _glucoseRepository.migrateLocalToHealth();
    final (insulinAttempted, insulinSuccess) = await _insulinRepository.migrateLocalToHealth();

    final totalAttempted = glucoseAttempted + insulinAttempted;
    final totalSuccess = glucoseSuccess + insulinSuccess;
    final totalFailed = totalAttempted - totalSuccess;

    return MigrationResult(
      totalAttempted: totalAttempted,
      successCount: totalSuccess,
      failedCount: totalFailed,
    );
  }

  /// Check for pending local records and retry migration
  /// Called on app startup when health is connected
  Future<void> _retryPendingMigration() async {
    if (!_isHealthConnected) return;

    final glucoseCount = await _glucoseRepository.getLocalRecordCount();
    final insulinCount = await _insulinRepository.getLocalRecordCount();

    if (glucoseCount == 0 && insulinCount == 0) return;

    _migrateLocalToHealthInBackground();
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
  }

  /// Refresh permission status (call when returning from Health app settings)
  /// Also updates connection status if write permissions are revoked
  /// Returns: null if no change, true if connected, false if disconnected
  Future<bool?> refreshPermissionStatus() async {
    await _updatePermissionStatus();

    // Check if ANY permission (write or read) is granted
    final hasAnyPermission = _categoryPermissions.values.any((status) => status == true);

    bool? statusChanged;

    // If previously connected but now no permissions, mark as disconnected
    if (_isHealthConnected && !hasAnyPermission) {
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

      // Refresh data to remove HealthKit items
      await refreshData();
    }
    // If previously disconnected but now has any permission, mark as connected
    else if (!_isHealthConnected && hasAnyPermission) {
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
      // Small delay to let UI thread breathe
      await Future.delayed(const Duration(milliseconds: 1));

      final now = DateTime.now();
      final syncDays = _settingsService?.syncPeriod ?? AppConstants.defaultSyncPeriod;
      // 오늘 포함 syncDays일 = (syncDays - 1)일 전부터
      // 예: 오늘이 30일, syncDays=7 -> 24일부터 30일까지 (7일간)
      final startDate = now.subtract(Duration(days: syncDays - 1));
      // Allow future dates (up to 1 day ahead) in case user enters future time
      final endDate = now.add(const Duration(days: 1));

      // Use local variables to collect all data first, then update state once at the end
      final List<FeedItem> allItems = [];
      final Map<DateTime, DailyActivityData> newActivityByDate = {};
      int? newTodaySteps;
      double? newTodayWaterMl;

      // Fetch glucose records via repository (handles HealthKit + Local merge)
      final allGlucoseRecords = await _glucoseRepository.fetch(
        startDate: startDate,
        endDate: endDate,
      );

      // Fetch insulin records via repository (handles HealthKit + Local merge)
      final insulinRecords = await _insulinRepository.fetch(
        startDate: startDate,
        endDate: endDate,
      );
      allItems.addAll(insulinRecords.map(FeedItem.fromInsulin));

      // Fetch read-only health data from HealthKit if permissions were requested
      // (This works even if write permission was denied, as long as read permission exists)
      if (_healthService.hasRequestedPermissions) {
        final exerciseRecords = await _healthService.fetchWorkoutData(
          startDate: startDate,
          endDate: now,
        );
        allItems.addAll(exerciseRecords.map(FeedItem.fromExercise));

        final sleepRecords = await _healthService.fetchSleepData(
          startDate: startDate,
          endDate: now,
        );

        // Group sleep records and add to feed items
        // Yield to UI thread between operations
        await Future.delayed(Duration.zero);
        final (groupedSleep, individualSleep) =
            SleepGroupingService.groupSleepRecords(sleepRecords);
        allItems.addAll(groupedSleep.map(FeedItem.fromSleepGroup));

        final waterRecords = await _healthService.fetchWaterData(
          startDate: startDate,
          endDate: now,
        );

        // Group water records by date and add to feed items
        await Future.delayed(Duration.zero);
        final waterGroups = WaterGroupingService.groupWaterRecords(waterRecords);
        allItems.addAll(waterGroups.map(FeedItem.fromWaterGroup));

        final mindfulnessRecords = await _healthService.fetchMindfulnessData(
          startDate: startDate,
          endDate: now,
        );
        allItems.addAll(mindfulnessRecords.map(FeedItem.fromMindfulness));

        newTodaySteps = await _healthService.fetchTodaySteps();
        newTodayWaterMl = await _healthService.fetchTodayWaterIntake();

        // Fetch activity (steps + distance) for all dates in the sync period
        final activityData = await _healthService.fetchDailyActivityByDate(
          startDate: startDate,
          endDate: now,
        );
        newActivityByDate.addAll(activityData);

        // Add steps data to feed items
        for (final entry in activityData.entries) {
          final date = entry.key;
          final activity = entry.value;
          if (activity.steps > 0) {
            allItems.add(FeedItem.fromSteps(
              date: date,
              steps: activity.steps,
              distanceKm: activity.distanceKm,
            ));
          }
        }
      }

      // Add local meal records from database
      final localMeals = await _databaseService.getMealRecords(
        startDate: startDate,
        endDate: endDate,
      );
      allItems.addAll(localMeals.map(FeedItem.fromMeal));

      // Add local exercise records from database
      final localExercise = await _databaseService.getExerciseRecords(
        startDate: startDate,
        endDate: endDate,
      );
      allItems.addAll(localExercise.map(FeedItem.fromExercise));

      // Group glucose records using CGM grouping service
      // Yield to UI thread before heavy processing
      await Future.delayed(Duration.zero);
      final rangeSettings = _settingsService?.glucoseRange ?? const GlucoseRangeSettings();
      final (cgmGroups, individualGlucose) =
          CgmGroupingService.groupGlucoseRecords(allGlucoseRecords, rangeSettings: rangeSettings);

      // Add CGM groups to feed items
      allItems.addAll(cgmGroups.map(FeedItem.fromCgmGroup));

      // Add individual glucose records (non-CGM) to feed items
      allItems.addAll(individualGlucose.map(FeedItem.fromGlucose));

      // Sort by timestamp (newest first)
      // Yield to UI thread before sorting
      await Future.delayed(Duration.zero);
      allItems.sort();

      // Find top 10 deletable glucose and insulin items for bounce animation
      _bouncableItemIds.clear();

      // Find deletable items (glucose and insulin only, NOT CGM groups):
      // 1. Local records (!isFromHealthKit)
      // 2. HealthKit records created by this app (sourceName contains 'Glu Butler')
      final deletableItems = allItems
          .where((item) {
            // Check individual glucose items (NOT CGM groups)
            if (item.type == FeedItemType.glucose && item.glucoseRecord != null) {
              final record = item.glucoseRecord!;
              // Include local records
              if (!record.isFromHealthKit) {
                return true;
              }
              // Include HealthKit records created by this app
              if (record.sourceName != null && record.sourceName!.contains('Glu Butler')) {
                return true;
              }
            }
            // Check insulin items
            if (item.type == FeedItemType.insulin && item.insulinRecord != null) {
              final record = item.insulinRecord!;
              // Include local records
              if (!record.isFromHealthKit) {
                return true;
              }
              // Include HealthKit records created by this app
              if (record.sourceName != null && record.sourceName!.contains('Glu Butler')) {
                return true;
              }
            }
            return false;
          })
          .take(10)
          .map((item) => item.id)
          .toList();
      _bouncableItemIds.addAll(deletableItems);

      // Update all state at once to prevent partial UI updates
      _items = allItems;
      _activityByDate.clear();
      _activityByDate.addAll(newActivityByDate);
      _todaySteps = newTodaySteps;
      _todayWaterMl = newTodayWaterMl;
    } catch (e) {
      _error = e.toString();
      debugPrint('[FeedProvider] Error refreshing data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add glucose record (via repository - handles Health/Local routing)
  Future<bool> addGlucoseRecord(GlucoseRecord record) async {
    final success = await _glucoseRepository.save(record);
    if (success) {
      await refreshData();
    }
    return success;
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

  // Add insulin record (via repository - handles Health/Local routing)
  Future<bool> addInsulinRecord(InsulinRecord record) async {
    final success = await _insulinRepository.save(record);
    if (success) {
      await refreshData();
    }
    return success;
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

  /// 특정 날짜 범위의 피드 아이템 가져오기 (리포트용)
  List<FeedItem> getItemsInRange({
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return _items.where((item) {
      return item.timestamp.isAfter(startDate.subtract(const Duration(days: 1))) &&
          item.timestamp.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();
  }

  /// 리포트 API용 피드 데이터 반환
  ///
  /// [startDate]: 시작 날짜
  /// [endDate]: 종료 날짜
  /// Returns: 선택된 날짜 범위의 피드 아이템 리스트
  List<FeedItem> getReportData({
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return getItemsInRange(
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Delete a glucose record from both local DB and Apple Health
  Future<bool> deleteGlucoseRecord(String id, DateTime timestamp) async {
    try {
      // Delete from local database
      await _databaseService.deleteGlucose(id);

      // Delete from Apple Health if connected
      if (_healthService.hasRequestedPermissions) {
        await _healthService.deleteBloodGlucose(timestamp);
      }

      // Refresh feed data
      await refreshData();

      return true;
    } catch (e) {
      _error = 'Failed to delete glucose record';
      notifyListeners();
      return false;
    }
  }

  /// Delete an insulin record from both local DB and Apple Health
  Future<bool> deleteInsulinRecord(String id, DateTime timestamp) async {
    try {
      // Delete from local database
      await _databaseService.deleteInsulin(id);

      // Delete from Apple Health if connected
      if (_healthService.hasRequestedPermissions) {
        await _healthService.deleteInsulinDelivery(timestamp);
      }

      // Refresh feed data
      await refreshData();

      return true;
    } catch (e) {
      _error = 'Failed to delete insulin record';
      notifyListeners();
      return false;
    }
  }

  /// Home 화면 그래프용 혈당 데이터 가져오기 (특정 날짜)
  ///
  /// [date]: 조회할 날짜
  /// Returns: 해당 날짜의 혈당 기록 리스트
  ///
  /// 캐시된 데이터가 있으면 반환하고, 없으면 Repository에서 직접 가져옴
  Future<List<GlucoseRecord>> getHomeGraphData(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    // 먼저 캐시된 데이터에서 찾기
    final cachedRecords = _items
        .where((item) {
          return item.type == FeedItemType.glucose &&
              item.glucoseRecord != null &&
              item.timestamp.isAfter(startOfDay.subtract(const Duration(seconds: 1))) &&
              item.timestamp.isBefore(endOfDay);
        })
        .map((item) => item.glucoseRecord!)
        .toList();

    // 오늘 또는 syncPeriod 이내 날짜면 캐시 데이터 반환
    final now = DateTime.now();
    final syncDays = _settingsService?.syncPeriod ?? AppConstants.defaultSyncPeriod;
    // 오늘 포함 syncDays일 = (syncDays - 1)일 전부터
    final earliestCachedDate = now.subtract(Duration(days: syncDays - 1));

    if (startOfDay.isAfter(earliestCachedDate) || startOfDay.isAtSameMomentAs(earliestCachedDate)) {
      return cachedRecords;
    }

    // 캐시 범위 밖이면 Repository에서 직접 가져오기
    return await _glucoseRepository.fetch(
      startDate: startOfDay,
      endDate: endOfDay,
    );
  }

  /// API 리포트용 간소화된 데이터 생성
  ///
  /// 모든 FeedItem을 간단한 포맷으로 변환:
  /// {
  ///   "type": "glucose manual|cgm|steps|water|exercise|sleep",
  ///   "time": "2024-12-30T18:30",
  ///   "value": "before_meal 145 mg/dL" // 또는 "avg": "95 mg/dL", "max": "102", "min": "88" (CGM인 경우)
  /// }
  List<Map<String, dynamic>> getSimplifiedReportData({
    required DateTime startDate,
    required DateTime endDate,
  }) {
    final result = <Map<String, dynamic>>[];

    // startDate ~ endDate 범위의 FeedItem 필터링
    final filteredItems = _items.where((item) {
      return item.timestamp.isAfter(startDate.subtract(const Duration(seconds: 1))) &&
          item.timestamp.isBefore(endDate.add(const Duration(seconds: 1)));
    }).toList();

    // timestamp 기준 정렬
    filteredItems.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    for (final item in filteredItems) {
      final timeStr = _formatTimeForApi(item.timestamp);

      switch (item.type) {
        case FeedItemType.glucose:
          final record = item.glucoseRecord;
          if (record == null) continue;

          // CGM 여부 판단: isFromHealthKit이고 연속적인 데이터면 CGM
          // 현재는 단순하게 수동 입력만 manual로 처리
          final isCgm = record.isFromHealthKit;

          if (isCgm) {
            // CGM 데이터는 시간별로 그룹화해야 하므로 일단 개별 데이터로 추가
            // (나중에 시간별 그룹화 로직 추가 가능)
            result.add({
              'type': 'glucose cgm',
              'time': timeStr,
              'value': '${record.value.toStringAsFixed(0)}${record.unit}',
            });
          } else {
            // Manual 데이터
            final mealContext = record.mealContext != null
                ? '${record.mealContext}, '
                : '';
            result.add({
              'type': 'glucose manual',
              'time': timeStr,
              'value': '$mealContext${record.value.toStringAsFixed(0)}${record.unit}',
            });
          }
          break;

        case FeedItemType.steps:
          final stepsMap = item.stepsData;
          if (stepsMap == null) continue;
          final steps = stepsMap['steps'] as int? ?? 0;
          final distanceKm = stepsMap['distanceKm'] as double? ?? 0;
          result.add({
            'type': 'steps',
            'time': timeStr,
            'value': '${steps}steps, ${distanceKm.toStringAsFixed(2)}km',
          });
          break;

        case FeedItemType.waterGroup:
          final waterGroup = item.waterGroup;
          if (waterGroup == null) continue;
          final totalMl = waterGroup.totalAmountMl;
          result.add({
            'type': 'water',
            'time': timeStr,
            'value': '${totalMl.toStringAsFixed(2)}ml',
          });
          break;

        case FeedItemType.exercise:
          final exercise = item.exerciseRecord;
          if (exercise == null) continue;
          final calories = exercise.calories ?? 0;
          final duration = exercise.durationMinutes;
          final exerciseType = exercise.exerciseType;
          result.add({
            'type': 'exercise',
            'time': timeStr,
            'value': '${calories}kcal, ${duration}min ($exerciseType)',
          });
          break;

        case FeedItemType.sleepGroup:
          final sleep = item.sleepGroup;
          if (sleep == null) continue;
          final startTime = _formatTimeForApi(sleep.startTime);
          final endTime = _formatTimeForApi(sleep.endTime);
          final duration = sleep.totalDurationMinutes;
          result.add({
            'type': 'sleep',
            'time': timeStr,
            'value': '$startTime~$endTime, ${duration}min',
          });
          break;

        // 다른 타입들은 무시
        default:
          break;
      }
    }

    return result;
  }

  /// API용 시간 포맷 (초 단위 제거)
  String _formatTimeForApi(DateTime dateTime) {
    return dateTime.toIso8601String().substring(0, 16); // "2024-12-30T18:30"
  }

}
