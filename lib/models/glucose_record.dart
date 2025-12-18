class GlucoseRecord {
  final String id;
  final double value;
  final String unit;
  final DateTime timestamp;
  final String? mealContext; // before_meal, after_meal, fasting
  final String? note;
  final bool isFromHealthKit;

  GlucoseRecord({
    required this.id,
    required this.value,
    required this.unit,
    required this.timestamp,
    this.mealContext,
    this.note,
    this.isFromHealthKit = false,
  });

  GlucoseRecord copyWith({
    String? id,
    double? value,
    String? unit,
    DateTime? timestamp,
    String? mealContext,
    String? note,
    bool? isFromHealthKit,
  }) {
    return GlucoseRecord(
      id: id ?? this.id,
      value: value ?? this.value,
      unit: unit ?? this.unit,
      timestamp: timestamp ?? this.timestamp,
      mealContext: mealContext ?? this.mealContext,
      note: note ?? this.note,
      isFromHealthKit: isFromHealthKit ?? this.isFromHealthKit,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'value': value,
      'unit': unit,
      'timestamp': timestamp.toIso8601String(),
      'mealContext': mealContext,
      'note': note,
      'isFromHealthKit': isFromHealthKit,
    };
  }

  factory GlucoseRecord.fromJson(Map<String, dynamic> json) {
    return GlucoseRecord(
      id: json['id'] as String,
      value: (json['value'] as num).toDouble(),
      unit: json['unit'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      mealContext: json['mealContext'] as String?,
      note: json['note'] as String?,
      isFromHealthKit: json['isFromHealthKit'] as bool? ?? false,
    );
  }

  // Convert to different unit
  double valueIn(String targetUnit) {
    if (unit == targetUnit) return value;

    const double conversionFactor = 18.0182;

    if (unit == 'mg/dL' && targetUnit == 'mmol/L') {
      return value / conversionFactor;
    } else if (unit == 'mmol/L' && targetUnit == 'mg/dL') {
      return value * conversionFactor;
    }

    return value;
  }

  // Get status based on value (assuming mg/dL)
  String get status {
    final mgDlValue = valueIn('mg/dL');
    if (mgDlValue < 70) return 'low';
    if (mgDlValue <= 140) return 'normal';
    return 'high';
  }
}
