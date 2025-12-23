import 'package:glu_butler/models/glucose_record.dart';
import 'package:glu_butler/models/exercise_record.dart';
import 'package:glu_butler/models/sleep_record.dart';
import 'package:glu_butler/models/meal_record.dart';
import 'package:glu_butler/models/water_record.dart';
import 'package:glu_butler/models/insulin_record.dart';
import 'package:glu_butler/models/mindfulness_record.dart';
import 'package:glu_butler/models/sleep_group.dart';
import 'package:glu_butler/models/water_group.dart';
import 'package:glu_butler/models/cgm_glucose_group.dart';

/// Feed에 표시되는 항목 타입
/// - glucose: 혈당 (Apple Health + 사용자)
/// - meal: 식사 (사용자)
/// - exercise: 운동 (Apple Health)
/// - sleep: 수면 (Apple Health)
/// - water: 수분섭취 (Apple Health)
/// - insulin: 인슐린 (Apple Health? + 사용자)
/// - steps: 일일 걸음수 그룹
/// - sleepGroup: 일일 수면 그룹
/// - waterGroup: 일일 수분 그룹
/// - cgmGroup: CGM 혈당 그룹 (연속 혈당 측정 데이터)
enum FeedItemType {
  glucose,
  meal,
  exercise,
  sleep,
  water,
  insulin,
  mindfulness,
  steps,
  sleepGroup,
  waterGroup,
  cgmGroup,
}

class FeedItem implements Comparable<FeedItem> {
  final String id;
  final FeedItemType type;
  final DateTime timestamp;
  final bool isFromHealthKit;
  final dynamic data;

  FeedItem({
    required this.id,
    required this.type,
    required this.timestamp,
    required this.isFromHealthKit,
    required this.data,
  });

  factory FeedItem.fromGlucose(GlucoseRecord record) {
    return FeedItem(
      id: record.id,
      type: FeedItemType.glucose,
      timestamp: record.timestamp,
      isFromHealthKit: record.isFromHealthKit,
      data: record,
    );
  }

  factory FeedItem.fromExercise(ExerciseRecord record) {
    return FeedItem(
      id: record.id,
      type: FeedItemType.exercise,
      timestamp: record.timestamp,
      isFromHealthKit: record.isFromHealthKit,
      data: record,
    );
  }

  factory FeedItem.fromSleep(SleepRecord record) {
    return FeedItem(
      id: record.id,
      type: FeedItemType.sleep,
      timestamp: record.endTime,
      isFromHealthKit: record.isFromHealthKit,
      data: record,
    );
  }

  factory FeedItem.fromMeal(MealRecord record) {
    return FeedItem(
      id: record.id,
      type: FeedItemType.meal,
      timestamp: record.timestamp,
      isFromHealthKit: false,
      data: record,
    );
  }

  GlucoseRecord? get glucoseRecord =>
      type == FeedItemType.glucose ? data as GlucoseRecord : null;

  ExerciseRecord? get exerciseRecord =>
      type == FeedItemType.exercise ? data as ExerciseRecord : null;

  SleepRecord? get sleepRecord =>
      type == FeedItemType.sleep ? data as SleepRecord : null;

  MealRecord? get mealRecord =>
      type == FeedItemType.meal ? data as MealRecord : null;

  WaterRecord? get waterRecord =>
      type == FeedItemType.water ? data as WaterRecord : null;

  InsulinRecord? get insulinRecord =>
      type == FeedItemType.insulin ? data as InsulinRecord : null;

  MindfulnessRecord? get mindfulnessRecord =>
      type == FeedItemType.mindfulness ? data as MindfulnessRecord : null;

  String? get sourceName {
    switch (type) {
      case FeedItemType.glucose:
        return glucoseRecord?.sourceName;
      case FeedItemType.exercise:
        return exerciseRecord?.sourceName;
      case FeedItemType.sleep:
        return sleepRecord?.sourceName;
      case FeedItemType.water:
        return waterRecord?.sourceName;
      case FeedItemType.insulin:
        return insulinRecord?.sourceName;
      case FeedItemType.mindfulness:
        return mindfulnessRecord?.sourceName;
      case FeedItemType.meal:
        return null;
      case FeedItemType.steps:
        return 'Apple Health';
      case FeedItemType.sleepGroup:
        return sleepGroup?.sourceName;
      case FeedItemType.waterGroup:
        return null;
      case FeedItemType.cgmGroup:
        return cgmGroup?.sourceName;
    }
  }

  factory FeedItem.fromWater(WaterRecord record) {
    return FeedItem(
      id: record.id,
      type: FeedItemType.water,
      timestamp: record.timestamp,
      isFromHealthKit: record.isFromHealthKit,
      data: record,
    );
  }

  factory FeedItem.fromInsulin(InsulinRecord record) {
    return FeedItem(
      id: record.id,
      type: FeedItemType.insulin,
      timestamp: record.timestamp,
      isFromHealthKit: record.isFromHealthKit,
      data: record,
    );
  }

  factory FeedItem.fromMindfulness(MindfulnessRecord record) {
    return FeedItem(
      id: record.id,
      type: FeedItemType.mindfulness,
      timestamp: record.endTime,
      isFromHealthKit: record.isFromHealthKit,
      data: record,
    );
  }

  factory FeedItem.fromSteps({
    required DateTime date,
    required int steps,
    double? distanceKm,
  }) {
    return FeedItem(
      id: 'steps_${date.year}_${date.month}_${date.day}',
      type: FeedItemType.steps,
      timestamp: DateTime(date.year, date.month, date.day, 23, 59, 59),
      isFromHealthKit: true,
      data: {
        'steps': steps,
        'distanceKm': distanceKm,
        'date': date,
      },
    );
  }

  factory FeedItem.fromSleepGroup(SleepGroup group) {
    return FeedItem(
      id: group.id,
      type: FeedItemType.sleepGroup,
      timestamp: group.endTime,
      isFromHealthKit: true,
      data: group,
    );
  }

  factory FeedItem.fromWaterGroup(WaterGroup group) {
    return FeedItem(
      id: group.id,
      type: FeedItemType.waterGroup,
      timestamp: DateTime(group.date.year, group.date.month, group.date.day, 23, 59, 58),
      isFromHealthKit: true,
      data: group,
    );
  }

  factory FeedItem.fromCgmGroup(CgmGlucoseGroup group) {
    return FeedItem(
      id: group.id,
      type: FeedItemType.cgmGroup,
      timestamp: group.startTime,
      isFromHealthKit: true,
      data: group,
    );
  }

  // Getters for group types
  Map<String, dynamic>? get stepsData =>
      type == FeedItemType.steps ? data as Map<String, dynamic> : null;

  SleepGroup? get sleepGroup =>
      type == FeedItemType.sleepGroup ? data as SleepGroup : null;

  WaterGroup? get waterGroup =>
      type == FeedItemType.waterGroup ? data as WaterGroup : null;

  CgmGlucoseGroup? get cgmGroup =>
      type == FeedItemType.cgmGroup ? data as CgmGlucoseGroup : null;

  @override
  int compareTo(FeedItem other) {
    // Sort by timestamp descending (newest first)
    return other.timestamp.compareTo(timestamp);
  }
}
