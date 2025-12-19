import 'package:glu_butler/models/glucose_record.dart';
import 'package:glu_butler/models/exercise_record.dart';
import 'package:glu_butler/models/sleep_record.dart';
import 'package:glu_butler/models/meal_record.dart';
import 'package:glu_butler/models/water_record.dart';
import 'package:glu_butler/models/insulin_record.dart';

/// Feed에 표시되는 항목 타입
/// - glucose: 혈당 (Apple Health + 사용자)
/// - meal: 식사 (사용자)
/// - exercise: 운동 (Apple Health)
/// - sleep: 수면 (Apple Health)
/// - water: 수분섭취 (Apple Health)
/// - insulin: 인슐린 (Apple Health? + 사용자)
enum FeedItemType {
  glucose,
  meal,
  exercise,
  sleep,
  water,
  insulin,
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

  @override
  int compareTo(FeedItem other) {
    // Sort by timestamp descending (newest first)
    return other.timestamp.compareTo(timestamp);
  }
}
