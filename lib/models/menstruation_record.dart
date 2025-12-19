class MenstruationRecord {
  final String id;
  final DateTime date;
  final MenstruationFlow flow;
  final String? note;
  final bool isFromHealthKit;

  MenstruationRecord({
    required this.id,
    required this.date,
    required this.flow,
    this.note,
    this.isFromHealthKit = false,
  });

  MenstruationRecord copyWith({
    String? id,
    DateTime? date,
    MenstruationFlow? flow,
    String? note,
    bool? isFromHealthKit,
  }) {
    return MenstruationRecord(
      id: id ?? this.id,
      date: date ?? this.date,
      flow: flow ?? this.flow,
      note: note ?? this.note,
      isFromHealthKit: isFromHealthKit ?? this.isFromHealthKit,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'flow': flow.name,
      'note': note,
      'isFromHealthKit': isFromHealthKit,
    };
  }

  factory MenstruationRecord.fromJson(Map<String, dynamic> json) {
    return MenstruationRecord(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      flow: MenstruationFlow.values.firstWhere(
        (e) => e.name == json['flow'],
        orElse: () => MenstruationFlow.unspecified,
      ),
      note: json['note'] as String?,
      isFromHealthKit: json['isFromHealthKit'] as bool? ?? false,
    );
  }
}

enum MenstruationFlow {
  unspecified,
  none,
  light,
  medium,
  heavy,
}

extension MenstruationFlowExtension on MenstruationFlow {
  String get displayName {
    switch (this) {
      case MenstruationFlow.none:
        return 'None';
      case MenstruationFlow.light:
        return 'Light';
      case MenstruationFlow.medium:
        return 'Medium';
      case MenstruationFlow.heavy:
        return 'Heavy';
      case MenstruationFlow.unspecified:
        return 'Unspecified';
    }
  }
}
