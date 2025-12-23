class InsulinRecord {
  final String id;
  final DateTime timestamp;
  final double units;
  final InsulinType insulinType;
  final InsulinDeliveryReason deliveryReason; // bolus or basal (for HealthKit)
  final String? injectionSite; // abdomen, thigh, arm, buttock
  final String? note;
  final bool isFromHealthKit;
  final String? sourceName;

  InsulinRecord({
    required this.id,
    required this.timestamp,
    required this.units,
    required this.insulinType,
    this.deliveryReason = InsulinDeliveryReason.bolus,
    this.injectionSite,
    this.note,
    this.isFromHealthKit = false,
    this.sourceName,
  });

  InsulinRecord copyWith({
    String? id,
    DateTime? timestamp,
    double? units,
    InsulinType? insulinType,
    InsulinDeliveryReason? deliveryReason,
    String? injectionSite,
    String? note,
    bool? isFromHealthKit,
  }) {
    return InsulinRecord(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      units: units ?? this.units,
      insulinType: insulinType ?? this.insulinType,
      deliveryReason: deliveryReason ?? this.deliveryReason,
      injectionSite: injectionSite ?? this.injectionSite,
      note: note ?? this.note,
      isFromHealthKit: isFromHealthKit ?? this.isFromHealthKit,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'units': units,
      'insulinType': insulinType.name,
      'deliveryReason': deliveryReason.name,
      'injectionSite': injectionSite,
      'note': note,
      'isFromHealthKit': isFromHealthKit,
    };
  }

  factory InsulinRecord.fromJson(Map<String, dynamic> json) {
    return InsulinRecord(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      units: (json['units'] as num).toDouble(),
      insulinType: InsulinType.values.firstWhere(
        (e) => e.name == json['insulinType'],
        orElse: () => InsulinType.rapidActing,
      ),
      deliveryReason: InsulinDeliveryReason.values.firstWhere(
        (e) => e.name == json['deliveryReason'],
        orElse: () => InsulinDeliveryReason.bolus,
      ),
      injectionSite: json['injectionSite'] as String?,
      note: json['note'] as String?,
      isFromHealthKit: json['isFromHealthKit'] as bool? ?? false,
    );
  }

  String get formattedUnits => '${units.toStringAsFixed(1)} U';
}

enum InsulinType {
  rapidActing,
  shortActing,
  intermediate,
  longActing,
  mixed,
}

extension InsulinTypeExtension on InsulinType {
  String get displayName {
    switch (this) {
      case InsulinType.rapidActing:
        return 'Rapid-acting';
      case InsulinType.shortActing:
        return 'Short-acting';
      case InsulinType.intermediate:
        return 'Intermediate';
      case InsulinType.longActing:
        return 'Long-acting';
      case InsulinType.mixed:
        return 'Mixed';
    }
  }
}

/// Insulin delivery reason (for HealthKit metadata)
enum InsulinDeliveryReason {
  bolus,  // Meal insulin (rapid/short-acting)
  basal,  // Basal insulin (long-acting)
}

extension InsulinDeliveryReasonExtension on InsulinDeliveryReason {
  String get displayName {
    switch (this) {
      case InsulinDeliveryReason.bolus:
        return 'Bolus';
      case InsulinDeliveryReason.basal:
        return 'Basal';
    }
  }

  String get name {
    switch (this) {
      case InsulinDeliveryReason.bolus:
        return 'bolus';
      case InsulinDeliveryReason.basal:
        return 'basal';
    }
  }
}
