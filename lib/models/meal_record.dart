/// 식사 기록 모델
///
/// 일기 항목에서 음식 사진이 감지되면 자동으로 생성됩니다.
/// diary_id를 통해 일기와 1:1 관계를 가집니다.
class MealRecord {
  final String id;
  final String diaryId;
  final String? foodName;
  final DateTime mealTime;
  final DateTime createdAt;

  MealRecord({
    required this.id,
    required this.diaryId,
    this.foodName,
    required this.mealTime,
    required this.createdAt,
  });

  MealRecord copyWith({
    String? id,
    String? diaryId,
    String? foodName,
    DateTime? mealTime,
    DateTime? createdAt,
  }) {
    return MealRecord(
      id: id ?? this.id,
      diaryId: diaryId ?? this.diaryId,
      foodName: foodName ?? this.foodName,
      mealTime: mealTime ?? this.mealTime,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// SQLite 맵으로 변환
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'diary_id': diaryId,
      'food_name': foodName,
      'meal_time': mealTime.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// SQLite 맵으로부터 생성
  factory MealRecord.fromMap(Map<String, dynamic> map) {
    return MealRecord(
      id: map['id'] as String,
      diaryId: map['diary_id'] as String,
      foodName: map['food_name'] as String?,
      mealTime: DateTime.parse(map['meal_time'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
