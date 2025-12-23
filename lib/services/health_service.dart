import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:glu_butler/models/glucose_record.dart';
import 'package:glu_butler/models/exercise_record.dart';
import 'package:glu_butler/models/sleep_record.dart';
import 'package:glu_butler/models/weight_record.dart';
import 'package:glu_butler/models/water_record.dart';
import 'package:glu_butler/models/menstruation_record.dart';
import 'package:glu_butler/models/insulin_record.dart';
import 'package:glu_butler/models/mindfulness_record.dart';

// Health data types enum (replaces health package dependency)
enum HealthDataType {
  BLOOD_GLUCOSE,
  INSULIN_DELIVERY,
  WORKOUT,
  STEPS,
  DISTANCE_WALKING_RUNNING,
  ACTIVE_ENERGY_BURNED,
  SLEEP_ASLEEP,
  SLEEP_AWAKE,
  SLEEP_DEEP,
  SLEEP_REM,
  SLEEP_LIGHT,
  WEIGHT,
  BODY_FAT_PERCENTAGE,
  BODY_MASS_INDEX,
  WATER,
  MENSTRUATION_FLOW,
  MINDFULNESS,
}

class DailyActivityData {
  final int steps;
  final double? distanceKm;

  DailyActivityData({
    required this.steps,
    this.distanceKm,
  });
}

class HealthService {
  static final HealthService _instance = HealthService._internal();
  factory HealthService() => _instance;
  HealthService._internal();

  // iOS Native HealthKit channel
  static const MethodChannel _healthKitChannel = MethodChannel('custom_healthkit');

  bool _isAuthorized = false;
  bool get isAuthorized => _isAuthorized;

  // Indicates that user has requested health permissions (even if write was denied)
  // Used to determine if we should attempt to read data
  bool _hasRequestedPermissions = false;
  bool get hasRequestedPermissions => _hasRequestedPermissions;

  /// Set permission request status (called from FeedProvider when restoring from DB)
  void setHasRequestedPermissions(bool value) {
    _hasRequestedPermissions = value;
  }

  // Track individual permission status
  final Map<HealthDataType, bool> _permissionStatus = {};
  Map<HealthDataType, bool> get permissionStatus => Map.unmodifiable(_permissionStatus);

  Future<bool> requestAuthorization() async {
    if (!Platform.isIOS) {
      debugPrint('[HealthService] Platform not supported - iOS only');
      return false;
    }

    try {
      await _healthKitChannel.invokeMethod('requestAuthorization');
      _hasRequestedPermissions = true;

      // Check actual permission status
      await checkPermissionStatus();

      // Consider authorized if we have ANY permission
      _isAuthorized = _permissionStatus.values.any((status) => status == true);

      debugPrint('[HealthService] iOS Native - isAuthorized: $_isAuthorized');
      debugPrint('[HealthService] iOS Native - permissions: $_permissionStatus');

      return _isAuthorized;
    } catch (e) {
      debugPrint('[HealthService] Error requesting authorization: $e');
      return false;
    }
  }

  /// Check permission status for each data type individually
  ///
  /// iOS doesn't expose permission status via hasPermissions() - it always returns null.
  /// So we check WRITE permissions by attempting to write test data,
  /// and assume READ permissions are granted if authorization was requested.
  ///
  /// For READ-only types, we can't reliably check - iOS just returns empty data.
  /// So after requestAuthorization succeeds, we assume READ permissions are granted.
  Future<void> checkPermissionStatus() async {
    if (!Platform.isIOS) {
      debugPrint('[HealthService] checkPermissionStatus: Platform not supported (iOS only)');
      return;
    }

    try {
      // Test blood glucose write permission
      final glucosePermission = await _healthKitChannel.invokeMethod('testBloodGlucoseWritePermission') as bool;
      _permissionStatus[HealthDataType.BLOOD_GLUCOSE] = glucosePermission;

      // Test insulin write permission
      final insulinPermission = await _healthKitChannel.invokeMethod('testInsulinWritePermission') as bool;
      _permissionStatus[HealthDataType.INSULIN_DELIVERY] = insulinPermission;

      // Assume read-only permissions are granted if authorization was requested
      final readOnlyTypes = [
        HealthDataType.WORKOUT,
        HealthDataType.STEPS,
        HealthDataType.SLEEP_ASLEEP,
        HealthDataType.WEIGHT,
        HealthDataType.WATER,
        HealthDataType.MENSTRUATION_FLOW,
        HealthDataType.MINDFULNESS,
      ];

      for (final type in readOnlyTypes) {
        _permissionStatus[type] = _hasRequestedPermissions;
      }
    } catch (e) {
      debugPrint('[HealthService] Error checking permission status: $e');
    }
  }

  // Removed: Android-only helper functions (not used in iOS native implementation)
  // _testWritePermission and _testInsulinWritePermission

  /// Check if a specific data type has permission
  /// Returns true only if explicitly granted, false otherwise
  bool hasPermissionFor(HealthDataType type) {
    return _permissionStatus[type] == true;
  }

  /// Get the permission status for a type
  bool getPermissionStatus(HealthDataType type) {
    return _permissionStatus[type] ?? false;
  }

  Future<bool> hasPermissions() async {
    if (!Platform.isIOS) {
      debugPrint('[HealthService] hasPermissions: Platform not supported (iOS only)');
      return false;
    }

    // iOS permissions are checked via checkPermissionStatus()
    // Return the current authorization status
    return _isAuthorized;
  }

  Future<List<GlucoseRecord>> fetchGlucoseData({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    if (!_hasRequestedPermissions) {
      return [];
    }

    if (Platform.isIOS) {
      // Use native iOS HealthKit to get meal context metadata
      try {
        final Map<String, dynamic> arguments = {
          'type': 'BLOOD_GLUCOSE',
          'startTime': startDate.millisecondsSinceEpoch,
          'endTime': endDate.millisecondsSinceEpoch,
        };

        final List<dynamic> data = await _healthKitChannel.invokeMethod('readHealthData', arguments);

        final records = <GlucoseRecord>[];

        for (final item in data) {
          final map = item as Map<dynamic, dynamic>;

          String? mealContext;

          // Map HealthKit meal time metadata back to our app's mealContext
          if (map['mealTime'] != null) {
            switch (map['mealTime']) {
              case 'preprandial':
                mealContext = 'before_meal';
                break;
              case 'postprandial':
                mealContext = 'after_meal';
                break;
            }
          }

          final sourceName = map['dataSource'] as String?;

          records.add(GlucoseRecord(
            id: 'hk_${(map['startTime'] as num).toInt()}',
            value: (map['value'] as num).toDouble(),
            unit: 'mg/dL',
            timestamp: DateTime.fromMillisecondsSinceEpoch((map['startTime'] as num).toInt()),
            mealContext: mealContext,
            isFromHealthKit: true,
            sourceName: sourceName,
          ));
        }

        // debugPrint('[HealthService] Fetched ${records.length} glucose records from native iOS');
        return records;
      } catch (e) {
        debugPrint('[HealthService] Error fetching glucose data from native iOS: $e');
        return [];
      }
    }

    // Platform not supported
    debugPrint('[HealthService] fetchGlucoseData: Platform not supported (iOS only)');
    return [];
  }

  Future<List<ExerciseRecord>> fetchWorkoutData({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    if (!_hasRequestedPermissions) {
      return [];
    }

    if (Platform.isIOS) {
      // Use native iOS HealthKit
      try {
        final Map<String, dynamic> arguments = {
          'type': 'WORKOUT',
          'startTime': startDate.millisecondsSinceEpoch,
          'endTime': endDate.millisecondsSinceEpoch,
        };

        final List<dynamic> data = await _healthKitChannel.invokeMethod('readHealthData', arguments);
        final records = <ExerciseRecord>[];

        for (final item in data) {
          final map = item as Map<dynamic, dynamic>;
          final durationMinutes = ((map['duration'] as num).toDouble() / 60).round();
          final workoutTypeRaw = map['workoutActivityType'] as int?;
          final exerciseType = _mapWorkoutActivityType(workoutTypeRaw ?? 0);
          final sourceName = map['dataSource'] as String?;
          final calories = (map['totalEnergyBurned'] as num?)?.toInt();
          final startTime = DateTime.fromMillisecondsSinceEpoch((map['startTime'] as num).toInt());

          // Debug log to check workout type mapping with details
          debugPrint('[HealthService] Workout: $sourceName, ${startTime.toString()}, ${durationMinutes}min, ${calories}kcal, raw type: $workoutTypeRaw -> $exerciseType');

          records.add(ExerciseRecord(
            id: 'hk_workout_${(map['startTime'] as num).toInt()}',
            timestamp: startTime,
            exerciseType: exerciseType,
            durationMinutes: durationMinutes,
            calories: calories,
            isFromHealthKit: true,
            sourceName: sourceName,
          ));
        }

        // debugPrint('[HealthService] Fetched ${records.length} workout records from native iOS');
        return records;
      } catch (e) {
        debugPrint('[HealthService] Error fetching workout data from native iOS: $e');
        return [];
      }
    }

    // Platform not supported
    debugPrint('[HealthService] fetchWorkoutData: Platform not supported (iOS only)');
    return [];
  }

  Future<List<SleepRecord>> fetchSleepData({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    if (!_hasRequestedPermissions) {
      return [];
    }

    if (Platform.isIOS) {
      // Use native iOS HealthKit
      try {
        final Map<String, dynamic> arguments = {
          'type': 'SLEEP',
          'startTime': startDate.millisecondsSinceEpoch,
          'endTime': endDate.millisecondsSinceEpoch,
        };

        final List<dynamic> data = await _healthKitChannel.invokeMethod('readHealthData', arguments);
        final records = <SleepRecord>[];

        for (final item in data) {
          final map = item as Map<dynamic, dynamic>;
          final startTime = DateTime.fromMillisecondsSinceEpoch((map['startTime'] as num).toInt());
          final endTime = DateTime.fromMillisecondsSinceEpoch((map['endTime'] as num).toInt());
          final durationMinutes = endTime.difference(startTime).inMinutes;

          records.add(SleepRecord(
            id: 'hk_sleep_${(map['startTime'] as num).toInt()}',
            startTime: startTime,
            endTime: endTime,
            durationMinutes: durationMinutes,
            stage: SleepStage.unknown, // Native doesn't distinguish stages
            isFromHealthKit: true,
            sourceName: map['dataSource'] as String?,
          ));
        }

        return records;
      } catch (e) {
        debugPrint('[HealthService] Error fetching sleep data from native iOS: $e');
        return [];
      }
    }

    // Platform not supported
    debugPrint('[HealthService] fetchSleepData: Platform not supported (iOS only)');
    return [];
  }

  Future<int?> fetchTodaySteps() async {
    if (!_hasRequestedPermissions) return null;

    if (!Platform.isIOS) {
      debugPrint('[HealthService] fetchTodaySteps: Platform not supported (iOS only)');
      return null;
    }

    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);

      final activityData = await fetchDailyActivityByDate(
        startDate: startOfDay,
        endDate: now,
      );

      // Get today's activity
      final todayActivity = activityData[startOfDay];
      return todayActivity?.steps;
    } catch (e) {
      debugPrint('[HealthService] Error fetching today steps: $e');
      return null;
    }
  }

  /// Fetch steps and distance for each day in the given date range
  /// Returns a map of date (normalized to start of day) to DailyActivityData
  Future<Map<DateTime, DailyActivityData>> fetchDailyActivityByDate({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    if (!_hasRequestedPermissions) {
      return {};
    }

    if (!Platform.isIOS) {
      debugPrint('[HealthService] fetchDailyActivityByDate: Platform not supported (iOS only)');
      return {};
    }

    try {
      final arguments = {
        'startTime': startDate.millisecondsSinceEpoch.toDouble(),
        'endTime': endDate.millisecondsSinceEpoch.toDouble(),
      };

      final List<dynamic> data = await _healthKitChannel.invokeMethod('fetchDailyActivity', arguments);

      final Map<DateTime, DailyActivityData> activityByDate = {};

      for (final item in data) {
        final map = item as Map<dynamic, dynamic>;
        final dateStr = map['date'] as String;
        final steps = map['steps'] as int;
        final distanceKm = (map['distanceKm'] as num).toDouble();

        // Parse date string (format: "yyyy-MM-dd")
        final dateParts = dateStr.split('-');
        final year = int.parse(dateParts[0]);
        final month = int.parse(dateParts[1]);
        final day = int.parse(dateParts[2]);
        final date = DateTime(year, month, day);

        activityByDate[date] = DailyActivityData(
          steps: steps,
          distanceKm: distanceKm > 0 ? distanceKm : null,
        );
      }

      return activityByDate;
    } catch (e) {
      debugPrint('[HealthService] Error fetching daily activity: $e');
      return {};
    }
  }

  Future<List<WeightRecord>> fetchWeightData({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    if (!_hasRequestedPermissions) {
      return [];
    }

    if (!Platform.isIOS) {
      debugPrint('[HealthService] fetchWeightData: Platform not supported (iOS only)');
      return [];
    }

    // TODO: Implement native iOS weight fetching if needed
    debugPrint('[HealthService] fetchWeightData: Not implemented for iOS native');
    return [];
  }

  Future<List<WaterRecord>> fetchWaterData({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    if (!_hasRequestedPermissions) {
      return [];
    }

    if (Platform.isIOS) {
      // Use native iOS HealthKit
      try {
        final Map<String, dynamic> arguments = {
          'type': 'WATER',
          'startTime': startDate.millisecondsSinceEpoch,
          'endTime': endDate.millisecondsSinceEpoch,
        };

        final List<dynamic> data = await _healthKitChannel.invokeMethod('readHealthData', arguments);
        final records = <WaterRecord>[];

        for (final item in data) {
          final map = item as Map<dynamic, dynamic>;
          // Native returns water in mL
          records.add(WaterRecord(
            id: 'hk_water_${(map['startTime'] as num).toInt()}',
            timestamp: DateTime.fromMillisecondsSinceEpoch((map['startTime'] as num).toInt()),
            amountMl: (map['value'] as num).toDouble(),
            isFromHealthKit: true,
            sourceName: map['dataSource'] as String?,
          ));
        }

        // debugPrint('[HealthService] Fetched ${records.length} water records from native iOS');
        return records;
      } catch (e) {
        debugPrint('[HealthService] Error fetching water data from native iOS: $e');
        return [];
      }
    }

    // Platform not supported
    debugPrint('[HealthService] fetchWaterData: Platform not supported (iOS only)');
    return [];
  }

  Future<List<MenstruationRecord>> fetchMenstruationData({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    if (!_hasRequestedPermissions) {
      return [];
    }

    if (!Platform.isIOS) {
      debugPrint('[HealthService] fetchMenstruationData: Platform not supported (iOS only)');
      return [];
    }

    // TODO: Implement native iOS menstruation fetching if needed
    debugPrint('[HealthService] fetchMenstruationData: Not implemented for iOS native');
    return [];
  }

  Future<double?> fetchTodayWaterIntake() async {
    if (!_hasRequestedPermissions) return null;

    if (!Platform.isIOS) {
      debugPrint('[HealthService] fetchTodayWaterIntake: Platform not supported (iOS only)');
      return null;
    }

    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);

      final waterRecords = await fetchWaterData(
        startDate: startOfDay,
        endDate: now,
      );

      // Sum all water intake for today
      double total = 0.0;
      for (final record in waterRecords) {
        total += record.amountMl;
      }

      return total > 0 ? total : null;
    } catch (e) {
      debugPrint('[HealthService] Error fetching today water intake: $e');
      return null;
    }
  }

  Future<List<MindfulnessRecord>> fetchMindfulnessData({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    if (!_hasRequestedPermissions) {
      return [];
    }

    if (Platform.isIOS) {
      // Use native iOS HealthKit
      try {
        final Map<String, dynamic> arguments = {
          'type': 'MINDFULNESS',
          'startTime': startDate.millisecondsSinceEpoch,
          'endTime': endDate.millisecondsSinceEpoch,
        };

        final List<dynamic> data = await _healthKitChannel.invokeMethod('readHealthData', arguments);
        final records = <MindfulnessRecord>[];

        for (final item in data) {
          final map = item as Map<dynamic, dynamic>;
          final startTime = DateTime.fromMillisecondsSinceEpoch((map['startTime'] as num).toInt());
          final endTime = DateTime.fromMillisecondsSinceEpoch((map['endTime'] as num).toInt());
          final durationMinutes = endTime.difference(startTime).inMinutes;

          records.add(MindfulnessRecord(
            id: 'hk_mindfulness_${(map['startTime'] as num).toInt()}',
            startTime: startTime,
            endTime: endTime,
            durationMinutes: durationMinutes,
            isFromHealthKit: true,
            sourceName: map['dataSource'] as String?,
          ));
        }

        // debugPrint('[HealthService] Fetched ${records.length} mindfulness records from native iOS');
        return records;
      } catch (e) {
        debugPrint('[HealthService] Error fetching mindfulness data from native iOS: $e');
        return [];
      }
    }

    // Platform not supported
    debugPrint('[HealthService] fetchMindfulnessData: Platform not supported (iOS only)');
    return [];
  }

  Future<bool> writeGlucoseRecord(GlucoseRecord record) async {
    if (!Platform.isIOS) {
      debugPrint('[HealthService] writeGlucoseRecord: Platform not supported (iOS only)');
      return false;
    }

    if (Platform.isIOS) {
      // Use native iOS HealthKit with meal context metadata support
      try {
        final Map<String, dynamic> arguments = {
          'value': record.value,
          'startTime': record.timestamp.millisecondsSinceEpoch,
        };

        // Map mealContext to HealthKit metadata
        // Only preprandial and postprandial are supported by Apple Health
        // Fasting is stored without meal time metadata
        if (record.mealContext != null) {
          switch (record.mealContext) {
            case 'before_meal':
            case 'beforeMeal':
              arguments['mealTime'] = 'preprandial';
              break;
            case 'after_meal':
            case 'afterMeal':
              arguments['mealTime'] = 'postprandial';
              break;
            case 'fasting':
            default:
              // Fasting: no mealTime metadata (not pre/post meal)
              break;
          }
        }

        debugPrint('[HealthService] Writing glucose: value=${record.value}, mealContext=${record.mealContext}, mealTime=${arguments['mealTime']}');

        final success = await _healthKitChannel.invokeMethod('writeBloodGlucose', arguments);
        debugPrint('[HealthService] Native iOS glucose write result: $success');
        return success as bool;
      } catch (e) {
        debugPrint('[HealthService] Error writing glucose to native iOS: $e');
        return false;
      }
    }

    // Platform not supported
    debugPrint('[HealthService] writeGlucoseRecord: Platform not supported (iOS only)');
    return false;
  }

  Future<bool> deleteBloodGlucose(DateTime timestamp) async {
    if (!Platform.isIOS) {
      debugPrint('[HealthService] deleteBloodGlucose: Platform not supported (iOS only)');
      return false;
    }

    try {
      final Map<String, dynamic> arguments = {
        'timestamp': timestamp.millisecondsSinceEpoch,
      };

      debugPrint('[HealthService] Deleting glucose at timestamp: ${timestamp.toIso8601String()}');

      final success = await _healthKitChannel.invokeMethod('deleteBloodGlucose', arguments);
      debugPrint('[HealthService] Native iOS glucose delete result: $success');
      return success as bool;
    } catch (e) {
      debugPrint('[HealthService] Error deleting glucose from native iOS: $e');
      return false;
    }
  }

  Future<bool> writeInsulinRecord(InsulinRecord record) async {
    if (!Platform.isIOS) {
      debugPrint('[HealthService] writeInsulinRecord: Platform not supported (iOS only)');
      return false;
    }

    if (Platform.isIOS) {
      // Use native iOS HealthKit with delivery reason metadata (required)
      try {
        // Map InsulinType to HealthKit delivery reason
        // longActing and intermediate -> basal
        // rapidActing, shortActing, mixed -> bolus
        String deliveryReason;
        switch (record.insulinType) {
          case InsulinType.longActing:
          case InsulinType.intermediate:
            deliveryReason = 'basal';
            break;
          case InsulinType.rapidActing:
          case InsulinType.shortActing:
          case InsulinType.mixed:
            deliveryReason = 'bolus';
            break;
        }

        final Map<String, dynamic> arguments = {
          'value': record.units,
          'startTime': record.timestamp.millisecondsSinceEpoch,
          'reason': deliveryReason,
        };

        final success = await _healthKitChannel.invokeMethod('writeInsulin', arguments);
        debugPrint('[HealthService] Native iOS insulin write result: $success (reason: $deliveryReason)');
        return success as bool;
      } catch (e) {
        debugPrint('[HealthService] Error writing insulin to native iOS: $e');
        return false;
      }
    }

    // Platform not supported
    debugPrint('[HealthService] writeInsulinRecord: Platform not supported (iOS only)');
    return false;
  }

  Future<List<InsulinRecord>> fetchInsulinData({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    if (!_hasRequestedPermissions) {
      return [];
    }

    if (Platform.isIOS) {
      // Use native iOS HealthKit to get delivery reason metadata
      try {
        final Map<String, dynamic> arguments = {
          'type': 'INSULIN_DELIVERY',
          'startTime': startDate.millisecondsSinceEpoch,
          'endTime': endDate.millisecondsSinceEpoch,
        };

        final List<dynamic> data = await _healthKitChannel.invokeMethod('readHealthData', arguments);
        final records = <InsulinRecord>[];

        for (final item in data) {
          final map = item as Map<dynamic, dynamic>;

          // Map HealthKit delivery reason back to InsulinType
          InsulinType insulinType = InsulinType.rapidActing; // Default
          if (map['reason'] != null) {
            switch (map['reason']) {
              case 'basal':
                insulinType = InsulinType.longActing;
                break;
              case 'bolus':
                insulinType = InsulinType.rapidActing;
                break;
            }
          }

          records.add(InsulinRecord(
            id: 'hk_insulin_${(map['startTime'] as num).toInt()}',
            timestamp: DateTime.fromMillisecondsSinceEpoch((map['startTime'] as num).toInt()),
            units: (map['value'] as num).toDouble(),
            insulinType: insulinType,
            isFromHealthKit: true,
            sourceName: map['dataSource'] as String?,
          ));
        }

        // debugPrint('[HealthService] Fetched ${records.length} insulin records from native iOS');
        return records;
      } catch (e) {
        debugPrint('[HealthService] Error fetching insulin data from native iOS: $e');
        return [];
      }
    }

    // Platform not supported
    debugPrint('[HealthService] fetchInsulinData: Platform not supported (iOS only)');
    return [];
  }

  /// Map HKWorkoutActivityType raw value to exercise type string
  /// Reference: https://developer.apple.com/documentation/healthkit/hkworkoutactivitytype
  String _mapWorkoutActivityType(int rawValue) {
    switch (rawValue) {
      case 12: // cycling
        return 'cycling';
      case 13: // running
        return 'running';
      case 16: // dance
        return 'dance';
      case 19: // flexibility
        return 'flexibility';
      case 20: // yoga
        return 'yoga';
      case 24: // functionalStrengthTraining
        return 'functional';
      case 35: // stairs
        return 'stairs';
      case 37: // traditionalStrengthTraining
        return 'strength';
      case 46: // swimming
        return 'swimming';
      case 52: // walking
        return 'walking';
      case 59: // mixedMetabolicCardioTraining
        return 'cardio';
      case 63: // highIntensityIntervalTraining
        return 'hiit';
      case 64: // mixedCardio
        return 'cardio';
      case 65: // handCycling
        return 'hand_cycling';
      case 66: // discSports
        return 'disc_sports';
      case 67: // fitnessGaming
        return 'fitness_gaming';
      case 71: // coreTraining
        return 'core';
      default:
        return 'other';
    }
  }

}
