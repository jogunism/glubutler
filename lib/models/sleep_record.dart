class SleepRecord {
  final String id;
  final DateTime startTime;
  final DateTime endTime;
  final int durationMinutes;
  final SleepStage? stage;
  final String? note;
  final bool isFromHealthKit;

  SleepRecord({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.durationMinutes,
    this.stage,
    this.note,
    this.isFromHealthKit = false,
  });

  SleepRecord copyWith({
    String? id,
    DateTime? startTime,
    DateTime? endTime,
    int? durationMinutes,
    SleepStage? stage,
    String? note,
    bool? isFromHealthKit,
  }) {
    return SleepRecord(
      id: id ?? this.id,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      stage: stage ?? this.stage,
      note: note ?? this.note,
      isFromHealthKit: isFromHealthKit ?? this.isFromHealthKit,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'durationMinutes': durationMinutes,
      'stage': stage?.name,
      'note': note,
      'isFromHealthKit': isFromHealthKit,
    };
  }

  factory SleepRecord.fromJson(Map<String, dynamic> json) {
    return SleepRecord(
      id: json['id'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      durationMinutes: json['durationMinutes'] as int,
      stage: json['stage'] != null
          ? SleepStage.values.firstWhere(
              (e) => e.name == json['stage'],
              orElse: () => SleepStage.unknown,
            )
          : null,
      note: json['note'] as String?,
      isFromHealthKit: json['isFromHealthKit'] as bool? ?? false,
    );
  }

  String get formattedDuration {
    final hours = durationMinutes ~/ 60;
    final minutes = durationMinutes % 60;
    if (hours > 0 && minutes > 0) {
      return '${hours}h ${minutes}m';
    } else if (hours > 0) {
      return '${hours}h';
    } else {
      return '${minutes}m';
    }
  }
}

enum SleepStage {
  awake,
  rem,
  light,
  deep,
  unknown,
}
