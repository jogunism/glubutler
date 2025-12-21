import 'package:glu_butler/models/glucose_record.dart';

/// CGM 혈당 그룹 타입
enum CgmGroupType {
  /// 평상시 - 안정적인 혈당 범위 (베이스라인)
  baseline,
  /// 변동 - 상승 후 하강 또는 하강 후 상승을 포함하는 이벤트 구간
  fluctuation,
}

/// CGM(연속혈당측정기) 데이터를 그룹화한 모델
class CgmGlucoseGroup {
  final String id;
  final List<GlucoseRecord> records;
  final CgmGroupType groupType;
  final DateTime startTime;
  final DateTime endTime;
  final double minValue;
  final double maxValue;
  final double avgValue;
  final String unit;
  final String? sourceName;

  CgmGlucoseGroup({
    required this.id,
    required this.records,
    required this.groupType,
    required this.startTime,
    required this.endTime,
    required this.minValue,
    required this.maxValue,
    required this.avgValue,
    required this.unit,
    this.sourceName,
  });

  /// 그룹 내 레코드 개수
  int get recordCount => records.length;

  /// 혈당 범위 문자열 (예: "95~110")
  String get rangeString {
    if (minValue == maxValue) {
      return minValue.toStringAsFixed(0);
    }
    return '${minValue.toStringAsFixed(0)}~${maxValue.toStringAsFixed(0)}';
  }

  /// 혈당 상태 (min/max 기준)
  String get status {
    // mg/dL 기준
    if (minValue < 70) return 'low';
    if (maxValue > 180) return 'high';
    if (maxValue > 140) return 'elevated';
    return 'normal';
  }

  /// 시간 범위 문자열 (예: "08:30~11:55")
  String get timeRangeString {
    final startStr = '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
    final endStr = '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';
    return '$startStr~$endStr';
  }

  /// 그룹 지속 시간 (분)
  int get durationMinutes => endTime.difference(startTime).inMinutes;

  /// 이벤트 타입에 따른 아이콘/라벨용
  bool get isEvent => groupType == CgmGroupType.fluctuation;
  bool get isBaseline => groupType == CgmGroupType.baseline;
}
