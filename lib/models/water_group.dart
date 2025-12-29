import 'package:glu_butler/models/water_record.dart';

/// Water 레코드 그룹
/// 하루의 수분 섭취량을 하나로 묶어서 표시
class WaterGroup {
  final String id;
  final DateTime date;
  final double totalAmountMl;
  final List<WaterRecord> records;

  WaterGroup({
    required this.id,
    required this.date,
    required this.totalAmountMl,
    required this.records,
  });

  // Convert to liters
  double get totalAmountL => totalAmountMl / 1000;

  // Convert to oz
  double get totalAmountOz => totalAmountMl * 0.033814;

  String formattedAmount({bool useOz = false}) {
    if (useOz) {
      return '${totalAmountOz.toStringAsFixed(1)} oz';
    }
    if (totalAmountMl >= 1000) {
      return '${totalAmountL.toStringAsFixed(1)} L';
    }
    return '${totalAmountMl.toStringAsFixed(0)} ml';
  }

  /// JSON으로 변환 (API 전송용)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'totalAmountMl': totalAmountMl,
      'records': records.map((r) => r.toJson()).toList(),
    };
  }
}
