import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:health/health.dart';
import 'package:glu_butler/models/glucose_record.dart';
import 'package:glu_butler/models/exercise_record.dart';
import 'package:glu_butler/models/sleep_record.dart';
import 'package:glu_butler/models/weight_record.dart';
import 'package:glu_butler/models/water_record.dart';
import 'package:glu_butler/models/menstruation_record.dart';
import 'package:glu_butler/models/insulin_record.dart';
import 'package:glu_butler/models/mindfulness_record.dart';

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

  static const List<HealthDataType> _readTypes = [
    HealthDataType.BLOOD_GLUCOSE,
    HealthDataType.INSULIN_DELIVERY,
    HealthDataType.WORKOUT,
    HealthDataType.STEPS,
    HealthDataType.DISTANCE_WALKING_RUNNING,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.SLEEP_AWAKE,
    HealthDataType.SLEEP_DEEP,
    HealthDataType.SLEEP_REM,
    HealthDataType.SLEEP_LIGHT,
    // Weight & Body
    HealthDataType.WEIGHT,
    HealthDataType.BODY_FAT_PERCENTAGE,
    HealthDataType.BODY_MASS_INDEX,
    // Water
    HealthDataType.WATER,
    // Menstruation
    HealthDataType.MENSTRUATION_FLOW,
    // Mindfulness
    HealthDataType.MINDFULNESS,
  ];

  static const List<HealthDataType> _writeTypes = [
    HealthDataType.BLOOD_GLUCOSE,
    HealthDataType.INSULIN_DELIVERY,
  ];

  Future<bool> requestAuthorization() async {
    if (!Platform.isIOS && !Platform.isAndroid) {
      debugPrint('[HealthService] Platform not supported');
      return false;
    }

    try {
      final health = Health();

      // Configure health package
      await health.configure();

      // Combine read and write types, with appropriate permissions
      final allTypes = <HealthDataType>[];
      final permissions = <HealthDataAccess>[];

      for (final type in _readTypes) {
        allTypes.add(type);
        // If type is also in writeTypes, request READ_WRITE, otherwise just READ
        if (_writeTypes.contains(type)) {
          permissions.add(HealthDataAccess.READ_WRITE);
        } else {
          permissions.add(HealthDataAccess.READ);
        }
      }

      // Request authorization
      // Note: On iOS, this returns true if the dialog was shown, NOT if user granted permission
      await health.requestAuthorization(
        allTypes,
        permissions: permissions,
      );

      // Mark that permissions have been requested (even if denied)
      // This allows us to attempt reading data
      _hasRequestedPermissions = true;

      // Check actual permission status by testing write access
      // This is the only reliable way to verify permissions on iOS
      await checkPermissionStatus();

      // Consider authorized only if we have write permission for blood glucose
      // (our primary data type that we need to write)
      _isAuthorized = _permissionStatus[HealthDataType.BLOOD_GLUCOSE] == true;

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
    if (!Platform.isIOS && !Platform.isAndroid) return;

    try {
      final health = Health();
      await health.configure();

      // For WRITE types, test by attempting to write
      // Note: Insulin requires HKMetadataKeyInsulinDeliveryReason metadata,
      // so we only test blood glucose and assume insulin has same permission

      // Test BLOOD_GLUCOSE write permission
      final glucosePermission = await _testWritePermission(
        health,
        HealthDataType.BLOOD_GLUCOSE,
        1.0, // dummy value
        HealthDataUnit.MILLIGRAM_PER_DECILITER,
      );
      _permissionStatus[HealthDataType.BLOOD_GLUCOSE] = glucosePermission;
      // Assume insulin has same permission as glucose (both are requested together)
      _permissionStatus[HealthDataType.INSULIN_DELIVERY] = glucosePermission;

      // For READ-only types, if blood glucose write permission is granted,
      // assume READ permissions are also granted (we can't verify READ on iOS).
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
        // Assume granted if blood glucose write permission was granted
        _permissionStatus[type] = glucosePermission;
      }

      // Update _isAuthorized based on blood glucose permission
      _isAuthorized = glucosePermission;
    } catch (e) {
      debugPrint('[HealthService] Error checking permission status: $e');
    }
  }

  /// Test write permission by attempting to write and immediately delete
  Future<bool> _testWritePermission(
    Health health,
    HealthDataType type,
    double testValue,
    HealthDataUnit unit,
  ) async {
    try {
      // Use a timestamp far in the past to avoid interfering with real data
      final testTime = DateTime(2000, 1, 1, 0, 0, 0);

      final success = await health.writeHealthData(
        value: testValue,
        type: type,
        startTime: testTime,
        endTime: testTime,
        unit: unit,
      );

      if (success) {
        // Try to delete the test data
        await health.delete(
          type: type,
          startTime: testTime,
          endTime: testTime.add(const Duration(seconds: 1)),
        );
      }

      return success;
    } catch (e) {
      debugPrint('[HealthService] Write permission test failed for $type: $e');
      return false;
    }
  }

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
    if (!Platform.isIOS && !Platform.isAndroid) return false;

    try {
      final health = Health();
      await health.configure();

      final hasPermissions = await health.hasPermissions(
        _readTypes,
        permissions: _readTypes.map((_) => HealthDataAccess.READ).toList(),
      );

      _isAuthorized = hasPermissions ?? false;
      return _isAuthorized;
    } catch (e) {
      debugPrint('[HealthService] Error checking permissions: $e');
      return false;
    }
  }

  Future<List<GlucoseRecord>> fetchGlucoseData({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    if (!_hasRequestedPermissions) {
      return [];
    }

    try {
      final health = Health();
      await health.configure();

      final dataPoints = await health.getHealthDataFromTypes(
        types: [HealthDataType.BLOOD_GLUCOSE],
        startTime: startDate,
        endTime: endDate,
      );

      final records = <GlucoseRecord>[];

      for (final point in dataPoints) {
        if (point.value is NumericHealthValue) {
          final numericValue = point.value as NumericHealthValue;
          records.add(GlucoseRecord(
            id: 'hk_${point.dateFrom.millisecondsSinceEpoch}',
            value: numericValue.numericValue.toDouble(),
            unit: 'mg/dL',
            timestamp: point.dateFrom,
            isFromHealthKit: true,
            sourceName: point.sourceName,
          ));
        }
      }

      // debugPrint('[HealthService] Fetched ${records.length} glucose records');
      return records;
    } catch (e) {
      debugPrint('[HealthService] Error fetching glucose data: $e');
      return [];
    }
  }

  Future<List<ExerciseRecord>> fetchWorkoutData({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    if (!_hasRequestedPermissions) {
      return [];
    }

    try {
      final health = Health();
      await health.configure();

      final dataPoints = await health.getHealthDataFromTypes(
        types: [HealthDataType.WORKOUT],
        startTime: startDate,
        endTime: endDate,
      );

      final records = <ExerciseRecord>[];

      for (final point in dataPoints) {
        if (point.value is WorkoutHealthValue) {
          final workoutValue = point.value as WorkoutHealthValue;
          final durationMinutes =
              point.dateTo.difference(point.dateFrom).inMinutes;

          records.add(ExerciseRecord(
            id: 'hk_workout_${point.dateFrom.millisecondsSinceEpoch}',
            timestamp: point.dateFrom,
            exerciseType: _mapWorkoutType(workoutValue.workoutActivityType),
            durationMinutes: durationMinutes,
            calories: workoutValue.totalEnergyBurned?.toInt(),
            isFromHealthKit: true,
            sourceName: point.sourceName,
          ));
        }
      }

      // debugPrint('[HealthService] Fetched ${records.length} workout records');
      return records;
    } catch (e) {
      debugPrint('[HealthService] Error fetching workout data: $e');
      return [];
    }
  }

  Future<List<SleepRecord>> fetchSleepData({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    if (!_hasRequestedPermissions) {
      return [];
    }

    try {
      final health = Health();
      await health.configure();

      final sleepTypes = [
        HealthDataType.SLEEP_ASLEEP,
        HealthDataType.SLEEP_AWAKE,
        HealthDataType.SLEEP_DEEP,
        HealthDataType.SLEEP_REM,
        HealthDataType.SLEEP_LIGHT,
      ];

      final dataPoints = await health.getHealthDataFromTypes(
        types: sleepTypes,
        startTime: startDate,
        endTime: endDate,
      );

      final records = <SleepRecord>[];

      for (final point in dataPoints) {
        final durationMinutes =
            point.dateTo.difference(point.dateFrom).inMinutes;

        records.add(SleepRecord(
          id: 'hk_sleep_${point.dateFrom.millisecondsSinceEpoch}',
          startTime: point.dateFrom,
          endTime: point.dateTo,
          durationMinutes: durationMinutes,
          stage: _mapSleepStage(point.type),
          isFromHealthKit: true,
          sourceName: point.sourceName,
        ));
      }

      // debugPrint('[HealthService] Fetched ${records.length} sleep records');
      return records;
    } catch (e) {
      debugPrint('[HealthService] Error fetching sleep data: $e');
      return [];
    }
  }

  Future<int?> fetchTodaySteps() async {
    if (!_hasRequestedPermissions) return null;

    try {
      final health = Health();
      await health.configure();

      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);

      final steps = await health.getTotalStepsInInterval(startOfDay, now);
      // debugPrint('[HealthService] Today steps: $steps');
      return steps;
    } catch (e) {
      debugPrint('[HealthService] Error fetching steps: $e');
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

    try {
      final health = Health();
      await health.configure();

      final Map<DateTime, DailyActivityData> activityByDate = {};

      // Fetch all distance data for the range
      final Map<DateTime, double> distanceByDate = {};
      try {
        final distancePoints = await health.getHealthDataFromTypes(
          types: [HealthDataType.DISTANCE_WALKING_RUNNING],
          startTime: startDate,
          endTime: endDate,
        );

        // iPhone and Apple Watch report overlapping distance data
        // Use only the primary source (prefer iPhone, as it's more consistently available)
        // Group by date and source, then pick one source per day

        // First, group all points by date
        final Map<DateTime, Map<String, double>> distanceByDateAndSource = {};
        for (final point in distancePoints) {
          final date = DateTime(point.dateFrom.year, point.dateFrom.month, point.dateFrom.day);
          final source = point.sourceName;
          final value = (point.value as NumericHealthValue).numericValue.toDouble();

          distanceByDateAndSource.putIfAbsent(date, () => {});
          distanceByDateAndSource[date]![source] = (distanceByDateAndSource[date]![source] ?? 0) + value;
        }

        // For each date, pick the source with the most distance (usually the most accurate)
        for (final entry in distanceByDateAndSource.entries) {
          final date = entry.key;
          final sourceDistances = entry.value;

          // Find the source with the maximum distance for this day
          String? bestSource;
          double maxDistance = 0;
          for (final sourceEntry in sourceDistances.entries) {
            if (sourceEntry.value > maxDistance) {
              maxDistance = sourceEntry.value;
              bestSource = sourceEntry.key;
            }
          }

          if (bestSource != null) {
            distanceByDate[date] = maxDistance;
          }
        }
      } catch (e) {
        debugPrint('[HealthService] Could not fetch distance data: $e');
      }

      // Iterate through each day in the range for steps
      // startDate and endDate are already local time (from DateTime.now())
      DateTime current = DateTime(startDate.year, startDate.month, startDate.day);
      final end = DateTime(endDate.year, endDate.month, endDate.day);

      // Calculate total days to iterate (avoid DST issues with Duration)
      final totalDays = end.difference(current).inDays + 1;

      for (int i = 0; i < totalDays; i++) {
        // Create date by adding days to start date (avoids DST issues)
        final date = DateTime(current.year, current.month, current.day + i);
        final dayStart = DateTime(date.year, date.month, date.day, 0, 0, 0);
        final dayEnd = DateTime(date.year, date.month, date.day, 23, 59, 59, 999);

        final steps = await health.getTotalStepsInInterval(dayStart, dayEnd);

        // Find distance for this date by comparing year/month/day
        double? distanceMeters;
        for (final entry in distanceByDate.entries) {
          if (entry.key.year == date.year &&
              entry.key.month == date.month &&
              entry.key.day == date.day) {
            distanceMeters = entry.value;
            break;
          }
        }

        // Add activity if we have either steps or distance
        final dateKey = DateTime(date.year, date.month, date.day);
        if ((steps != null && steps > 0) || distanceMeters != null) {
          activityByDate[dateKey] = DailyActivityData(
            steps: steps ?? 0,
            distanceKm: distanceMeters != null ? distanceMeters / 1000 : null,
          );
        }
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

    try {
      final health = Health();
      await health.configure();

      final weightPoints = await health.getHealthDataFromTypes(
        types: [HealthDataType.WEIGHT],
        startTime: startDate,
        endTime: endDate,
      );

      final bodyFatPoints = await health.getHealthDataFromTypes(
        types: [HealthDataType.BODY_FAT_PERCENTAGE],
        startTime: startDate,
        endTime: endDate,
      );

      final bmiPoints = await health.getHealthDataFromTypes(
        types: [HealthDataType.BODY_MASS_INDEX],
        startTime: startDate,
        endTime: endDate,
      );

      final records = <WeightRecord>[];

      for (final point in weightPoints) {
        if (point.value is NumericHealthValue) {
          final numericValue = point.value as NumericHealthValue;

          // Find matching body fat and BMI for same timestamp
          double? bodyFat;
          double? bmi;

          for (final bf in bodyFatPoints) {
            if (bf.dateFrom.difference(point.dateFrom).inMinutes.abs() < 5) {
              if (bf.value is NumericHealthValue) {
                bodyFat = (bf.value as NumericHealthValue).numericValue.toDouble();
              }
              break;
            }
          }

          for (final b in bmiPoints) {
            if (b.dateFrom.difference(point.dateFrom).inMinutes.abs() < 5) {
              if (b.value is NumericHealthValue) {
                bmi = (b.value as NumericHealthValue).numericValue.toDouble();
              }
              break;
            }
          }

          records.add(WeightRecord(
            id: 'hk_weight_${point.dateFrom.millisecondsSinceEpoch}',
            timestamp: point.dateFrom,
            weightKg: numericValue.numericValue.toDouble(),
            bodyFatPercentage: bodyFat,
            bmi: bmi,
            isFromHealthKit: true,
          ));
        }
      }

      // debugPrint('[HealthService] Fetched ${records.length} weight records');
      return records;
    } catch (e) {
      debugPrint('[HealthService] Error fetching weight data: $e');
      return [];
    }
  }

  Future<List<WaterRecord>> fetchWaterData({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    if (!_hasRequestedPermissions) {
      return [];
    }

    try {
      final health = Health();
      await health.configure();

      final dataPoints = await health.getHealthDataFromTypes(
        types: [HealthDataType.WATER],
        startTime: startDate,
        endTime: endDate,
      );

      final records = <WaterRecord>[];

      for (final point in dataPoints) {
        if (point.value is NumericHealthValue) {
          final numericValue = point.value as NumericHealthValue;
          // HealthKit stores water in liters, convert to ml
          records.add(WaterRecord(
            id: 'hk_water_${point.dateFrom.millisecondsSinceEpoch}',
            timestamp: point.dateFrom,
            amountMl: numericValue.numericValue.toDouble() * 1000,
            isFromHealthKit: true,
            sourceName: point.sourceName,
          ));
        }
      }

      // debugPrint('[HealthService] Fetched ${records.length} water records');
      return records;
    } catch (e) {
      debugPrint('[HealthService] Error fetching water data: $e');
      return [];
    }
  }

  Future<List<MenstruationRecord>> fetchMenstruationData({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    if (!_hasRequestedPermissions) {
      return [];
    }

    try {
      final health = Health();
      await health.configure();

      final dataPoints = await health.getHealthDataFromTypes(
        types: [HealthDataType.MENSTRUATION_FLOW],
        startTime: startDate,
        endTime: endDate,
      );

      final records = <MenstruationRecord>[];

      for (final point in dataPoints) {
        if (point.value is NumericHealthValue) {
          final numericValue = point.value as NumericHealthValue;
          records.add(MenstruationRecord(
            id: 'hk_menstruation_${point.dateFrom.millisecondsSinceEpoch}',
            date: point.dateFrom,
            flow: _mapMenstruationFlow(numericValue.numericValue.toInt()),
            isFromHealthKit: true,
          ));
        }
      }

      // debugPrint('[HealthService] Fetched ${records.length} menstruation records');
      return records;
    } catch (e) {
      debugPrint('[HealthService] Error fetching menstruation data: $e');
      return [];
    }
  }

  Future<double?> fetchTodayWaterIntake() async {
    if (!_hasRequestedPermissions) return null;

    try {
      final health = Health();
      await health.configure();

      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);

      final dataPoints = await health.getHealthDataFromTypes(
        types: [HealthDataType.WATER],
        startTime: startOfDay,
        endTime: now,
      );

      double totalMl = 0;
      for (final point in dataPoints) {
        if (point.value is NumericHealthValue) {
          final numericValue = point.value as NumericHealthValue;
          totalMl += numericValue.numericValue.toDouble() * 1000;
        }
      }

      // debugPrint('[HealthService] Today water intake: ${totalMl}ml');
      return totalMl;
    } catch (e) {
      debugPrint('[HealthService] Error fetching today water: $e');
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

    try {
      final health = Health();
      await health.configure();

      final dataPoints = await health.getHealthDataFromTypes(
        types: [HealthDataType.MINDFULNESS],
        startTime: startDate,
        endTime: endDate,
      );

      final records = <MindfulnessRecord>[];

      for (final point in dataPoints) {
        final durationMinutes =
            point.dateTo.difference(point.dateFrom).inMinutes;

        records.add(MindfulnessRecord(
          id: 'hk_mindfulness_${point.dateFrom.millisecondsSinceEpoch}',
          startTime: point.dateFrom,
          endTime: point.dateTo,
          durationMinutes: durationMinutes,
          isFromHealthKit: true,
          sourceName: point.sourceName,
        ));
      }

      return records;
    } catch (e) {
      debugPrint('[HealthService] Error fetching mindfulness data: $e');
      return [];
    }
  }

  MenstruationFlow _mapMenstruationFlow(int value) {
    // HealthKit menstruation flow values
    switch (value) {
      case 1:
        return MenstruationFlow.unspecified;
      case 2:
        return MenstruationFlow.light;
      case 3:
        return MenstruationFlow.medium;
      case 4:
        return MenstruationFlow.heavy;
      case 5:
        return MenstruationFlow.none;
      default:
        return MenstruationFlow.unspecified;
    }
  }

  Future<bool> writeGlucoseRecord(GlucoseRecord record) async {
    if (!Platform.isIOS && !Platform.isAndroid) return false;

    try {
      final health = Health();
      await health.configure();

      final success = await health.writeHealthData(
        value: record.value,
        type: HealthDataType.BLOOD_GLUCOSE,
        startTime: record.timestamp,
        endTime: record.timestamp,
        unit: HealthDataUnit.MILLIGRAM_PER_DECILITER,
        recordingMethod: RecordingMethod.manual,
        clientRecordId: record.id,
      );

      debugPrint('[HealthService] Write glucose result: $success');
      return success;
    } catch (e) {
      debugPrint('[HealthService] Error writing glucose: $e');
      return false;
    }
  }

  Future<bool> writeInsulinRecord(InsulinRecord record) async {
    if (!Platform.isIOS && !Platform.isAndroid) return false;

    try {
      final health = Health();
      await health.configure();

      final success = await health.writeHealthData(
        value: record.units,
        type: HealthDataType.INSULIN_DELIVERY,
        startTime: record.timestamp,
        endTime: record.timestamp,
        unit: HealthDataUnit.INTERNATIONAL_UNIT,
        recordingMethod: RecordingMethod.manual,
        clientRecordId: record.id,
      );

      debugPrint('[HealthService] Write insulin result: $success');
      return success;
    } catch (e) {
      debugPrint('[HealthService] Error writing insulin: $e');
      return false;
    }
  }

  Future<List<InsulinRecord>> fetchInsulinData({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    if (!_hasRequestedPermissions) {
      return [];
    }

    try {
      final health = Health();
      await health.configure();

      final dataPoints = await health.getHealthDataFromTypes(
        types: [HealthDataType.INSULIN_DELIVERY],
        startTime: startDate,
        endTime: endDate,
      );

      final records = <InsulinRecord>[];

      for (final point in dataPoints) {
        if (point.value is NumericHealthValue) {
          final numericValue = point.value as NumericHealthValue;
          records.add(InsulinRecord(
            id: 'hk_insulin_${point.dateFrom.millisecondsSinceEpoch}',
            timestamp: point.dateFrom,
            units: numericValue.numericValue.toDouble(),
            insulinType: InsulinType.rapidActing, // Default, HealthKit doesn't distinguish
            isFromHealthKit: true,
          ));
        }
      }

      // debugPrint('[HealthService] Fetched ${records.length} insulin records');
      return records;
    } catch (e) {
      debugPrint('[HealthService] Error fetching insulin data: $e');
      return [];
    }
  }

  String _mapWorkoutType(HealthWorkoutActivityType type) {
    switch (type) {
      case HealthWorkoutActivityType.RUNNING:
        return 'running';
      case HealthWorkoutActivityType.WALKING:
        return 'walking';
      case HealthWorkoutActivityType.BIKING:
        return 'cycling';
      case HealthWorkoutActivityType.SWIMMING:
        return 'swimming';
      case HealthWorkoutActivityType.YOGA:
        return 'yoga';
      case HealthWorkoutActivityType.STRENGTH_TRAINING:
        return 'strength';
      case HealthWorkoutActivityType.HIGH_INTENSITY_INTERVAL_TRAINING:
        return 'hiit';
      default:
        return 'other';
    }
  }

  SleepStage _mapSleepStage(HealthDataType type) {
    switch (type) {
      case HealthDataType.SLEEP_AWAKE:
        return SleepStage.awake;
      case HealthDataType.SLEEP_REM:
        return SleepStage.rem;
      case HealthDataType.SLEEP_LIGHT:
        return SleepStage.light;
      case HealthDataType.SLEEP_DEEP:
        return SleepStage.deep;
      default:
        return SleepStage.unknown;
    }
  }
}
