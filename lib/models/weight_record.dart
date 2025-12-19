class WeightRecord {
  final String id;
  final DateTime timestamp;
  final double weightKg;
  final double? bodyFatPercentage;
  final double? bmi;
  final String? note;
  final bool isFromHealthKit;

  WeightRecord({
    required this.id,
    required this.timestamp,
    required this.weightKg,
    this.bodyFatPercentage,
    this.bmi,
    this.note,
    this.isFromHealthKit = false,
  });

  WeightRecord copyWith({
    String? id,
    DateTime? timestamp,
    double? weightKg,
    double? bodyFatPercentage,
    double? bmi,
    String? note,
    bool? isFromHealthKit,
  }) {
    return WeightRecord(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      weightKg: weightKg ?? this.weightKg,
      bodyFatPercentage: bodyFatPercentage ?? this.bodyFatPercentage,
      bmi: bmi ?? this.bmi,
      note: note ?? this.note,
      isFromHealthKit: isFromHealthKit ?? this.isFromHealthKit,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'weightKg': weightKg,
      'bodyFatPercentage': bodyFatPercentage,
      'bmi': bmi,
      'note': note,
      'isFromHealthKit': isFromHealthKit,
    };
  }

  factory WeightRecord.fromJson(Map<String, dynamic> json) {
    return WeightRecord(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      weightKg: (json['weightKg'] as num).toDouble(),
      bodyFatPercentage: (json['bodyFatPercentage'] as num?)?.toDouble(),
      bmi: (json['bmi'] as num?)?.toDouble(),
      note: json['note'] as String?,
      isFromHealthKit: json['isFromHealthKit'] as bool? ?? false,
    );
  }

  // Convert to pounds
  double get weightLbs => weightKg * 2.20462;

  String formattedWeight({bool useLbs = false}) {
    if (useLbs) {
      return '${weightLbs.toStringAsFixed(1)} lbs';
    }
    return '${weightKg.toStringAsFixed(1)} kg';
  }
}
