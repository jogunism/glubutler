/// 식사 기록 모델
///
/// 일기 항목에서 음식 사진이 감지되면 자동으로 생성됩니다.
/// 일기와 독립적으로 존재하며, 같은 시간대의 음식 사진들을 그룹화하여 생성됩니다.
class MealRecord {
  final String id;
  final String? foodName;
  final DateTime mealTime;
  final DateTime createdAt;

  MealRecord({
    required this.id,
    this.foodName,
    required this.mealTime,
    required this.createdAt,
  });

  MealRecord copyWith({
    String? id,
    String? foodName,
    DateTime? mealTime,
    DateTime? createdAt,
  }) {
    return MealRecord(
      id: id ?? this.id,
      foodName: foodName ?? this.foodName,
      mealTime: mealTime ?? this.mealTime,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// SQLite 맵으로 변환
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'food_name': foodName,
      'meal_time': mealTime.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// SQLite 맵으로부터 생성
  factory MealRecord.fromMap(Map<String, dynamic> map) {
    return MealRecord(
      id: map['id'] as String,
      foodName: map['food_name'] as String?,
      mealTime: DateTime.parse(map['meal_time'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// 식사 시간을 기반으로 식사 타입 반환
  ///
  /// - 06:00-10:00 → 아침
  /// - 11:00-14:00 → 점심
  /// - 17:00-20:00 → 저녁
  /// - 그 외 → 간식
  String getMealTypeKey() {
    final hour = mealTime.hour;

    if (hour >= 6 && hour < 10) {
      return 'breakfast'; // 아침
    } else if (hour >= 11 && hour < 14) {
      return 'lunch'; // 점심
    } else if (hour >= 17 && hour < 20) {
      return 'dinner'; // 저녁
    } else {
      return 'snack'; // 간식
    }
  }
}
