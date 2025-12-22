class MindfulnessRecord {
  final String id;
  final DateTime startTime;
  final DateTime endTime;
  final int durationMinutes;
  final String? note;
  final bool isFromHealthKit;
  final String? sourceName;

  MindfulnessRecord({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.durationMinutes,
    this.note,
    this.isFromHealthKit = false,
    this.sourceName,
  });

  MindfulnessRecord copyWith({
    String? id,
    DateTime? startTime,
    DateTime? endTime,
    int? durationMinutes,
    String? note,
    bool? isFromHealthKit,
    String? sourceName,
  }) {
    return MindfulnessRecord(
      id: id ?? this.id,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      note: note ?? this.note,
      isFromHealthKit: isFromHealthKit ?? this.isFromHealthKit,
      sourceName: sourceName ?? this.sourceName,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'durationMinutes': durationMinutes,
      'note': note,
      'isFromHealthKit': isFromHealthKit,
      'sourceName': sourceName,
    };
  }

  factory MindfulnessRecord.fromJson(Map<String, dynamic> json) {
    return MindfulnessRecord(
      id: json['id'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      durationMinutes: json['durationMinutes'] as int,
      note: json['note'] as String?,
      isFromHealthKit: json['isFromHealthKit'] as bool? ?? false,
      sourceName: json['sourceName'] as String?,
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
