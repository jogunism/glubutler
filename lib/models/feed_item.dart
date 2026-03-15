import 'dart:io';
import 'package:glu_butler/models/glucose_record.dart';
import 'package:glu_butler/models/exercise_record.dart';
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

  factory FeedItem.fromMeal(MealRecord record) {
    return FeedItem(
      id: record.id,
      type: FeedItemType.meal,
      timestamp: record.mealTime,
      isFromHealthKit: false,
      data: record,
    );
  }

  GlucoseRecord? get glucoseRecord =>
      type == FeedItemType.glucose ? data as GlucoseRecord : null;

  ExerciseRecord? get exerciseRecord =>
      type == FeedItemType.exercise ? data as ExerciseRecord : null;

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
      case FeedItemType.water:
        return waterRecord?.sourceName;
      case FeedItemType.insulin:
        return insulinRecord?.sourceName;
      case FeedItemType.mindfulness:
        return mindfulnessRecord?.sourceName;
      case FeedItemType.meal:
        return null;
      case FeedItemType.steps:
        return Platform.isIOS ? 'Apple Health' : 'Health Connect';
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
    // Use start of day timestamp to ensure sleep appears last in the day's feed (bottom of list)
    // Since sorting is descending, smallest timestamp appears at bottom
    final date = group.endTime;
    return FeedItem(
      id: group.id,
      type: FeedItemType.sleepGroup,
      timestamp: DateTime(date.year, date.month, date.day, 0, 0, 0),
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
    // CGM 그룹과 다른 아이템 비교 시 중간시간 기준 정렬
    // 최신 시간이 위, 이전 시간이 아래 (내림차순)
    // CGM 중간시간을 기준으로 이벤트가 앞이면 이벤트가 아래, 뒤면 이벤트가 위

    // this가 CGM이고 other가 CGM이 아닌 경우
    if (type == FeedItemType.cgmGroup && other.type != FeedItemType.cgmGroup) {
      final cgm = cgmGroup!;
      final otherTime = other.timestamp;

      // other가 CGM 시간 범위 내에 있는지 확인
      if (!otherTime.isBefore(cgm.startTime) && !otherTime.isAfter(cgm.endTime)) {
        // 중간 시간 계산
        final middleTime = cgm.startTime.add(
          Duration(milliseconds: cgm.endTime.difference(cgm.startTime).inMilliseconds ~/ 2),
        );

        // other가 중간시간보다 앞이면 CGM이 위 (other가 아래)
        if (otherTime.isBefore(middleTime)) {
          return -1; // this(CGM)가 위
        } else {
          return 1; // other가 위
        }
      }
    }

    // other가 CGM이고 this가 CGM이 아닌 경우
    if (other.type == FeedItemType.cgmGroup && type != FeedItemType.cgmGroup) {
      final cgm = other.cgmGroup!;
      final thisTime = timestamp;

      // this가 CGM 시간 범위 내에 있는지 확인
      if (!thisTime.isBefore(cgm.startTime) && !thisTime.isAfter(cgm.endTime)) {
        // 중간 시간 계산
        final middleTime = cgm.startTime.add(
          Duration(milliseconds: cgm.endTime.difference(cgm.startTime).inMilliseconds ~/ 2),
        );

        // this가 중간시간보다 앞이면 CGM이 위 (this가 아래)
        if (thisTime.isBefore(middleTime)) {
          return 1; // other(CGM)가 위
        } else {
          return -1; // this가 위
        }
      }
    }

    // 기본: timestamp 내림차순 (최신이 위)
    return other.timestamp.compareTo(timestamp);
  }
}
