class WaterRecord {
  final String id;
  final DateTime timestamp;
  final double amountMl;
  final String? note;
  final bool isFromHealthKit;
  final String? sourceName;

  WaterRecord({
    required this.id,
    required this.timestamp,
    required this.amountMl,
    this.note,
    this.isFromHealthKit = false,
    this.sourceName,
  });

  WaterRecord copyWith({
    String? id,
    DateTime? timestamp,
    double? amountMl,
    String? note,
    bool? isFromHealthKit,
  }) {
    return WaterRecord(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      amountMl: amountMl ?? this.amountMl,
      note: note ?? this.note,
      isFromHealthKit: isFromHealthKit ?? this.isFromHealthKit,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'amountMl': amountMl,
      'note': note,
      'isFromHealthKit': isFromHealthKit,
    };
  }

  factory WaterRecord.fromJson(Map<String, dynamic> json) {
    return WaterRecord(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      amountMl: (json['amountMl'] as num).toDouble(),
      note: json['note'] as String?,
      isFromHealthKit: json['isFromHealthKit'] as bool? ?? false,
    );
  }

  // Convert to liters
  double get amountL => amountMl / 1000;

  // Convert to oz
  double get amountOz => amountMl * 0.033814;

  String formattedAmount({bool useOz = false}) {
    if (useOz) {
      return '${amountOz.toStringAsFixed(1)} oz';
    }
    if (amountMl >= 1000) {
      return '${amountL.toStringAsFixed(1)} L';
    }
    return '${amountMl.toStringAsFixed(0)} ml';
  }
}
