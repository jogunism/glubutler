class ExerciseRecord {
  final String id;
  final DateTime timestamp;
  final String exerciseType;
  final int durationMinutes;
  final int? calories;
  final int? steps;
  final String? note;
  final bool isFromHealthKit;
  final String? sourceName;

  ExerciseRecord({
    required this.id,
    required this.timestamp,
    required this.exerciseType,
    required this.durationMinutes,
    this.calories,
    this.steps,
    this.note,
    this.isFromHealthKit = false,
    this.sourceName,
  });

  ExerciseRecord copyWith({
    String? id,
    DateTime? timestamp,
    String? exerciseType,
    int? durationMinutes,
    int? calories,
    int? steps,
    String? note,
    bool? isFromHealthKit,
  }) {
    return ExerciseRecord(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      exerciseType: exerciseType ?? this.exerciseType,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      calories: calories ?? this.calories,
      steps: steps ?? this.steps,
      note: note ?? this.note,
      isFromHealthKit: isFromHealthKit ?? this.isFromHealthKit,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'exerciseType': exerciseType,
      'durationMinutes': durationMinutes,
      'calories': calories,
      'steps': steps,
      'note': note,
      'isFromHealthKit': isFromHealthKit,
    };
  }

  factory ExerciseRecord.fromJson(Map<String, dynamic> json) {
    return ExerciseRecord(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      exerciseType: json['exerciseType'] as String,
      durationMinutes: json['durationMinutes'] as int,
      calories: json['calories'] as int?,
      steps: json['steps'] as int?,
      note: json['note'] as String?,
      isFromHealthKit: json['isFromHealthKit'] as bool? ?? false,
    );
  }
}
