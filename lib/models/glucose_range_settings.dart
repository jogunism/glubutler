import 'package:glu_butler/core/constants/app_constants.dart';

/// 혈당 범위 설정
/// 사용자가 커스터마이징 가능한 혈당 임계값들
class GlucoseRangeSettings {
  final double veryLow;
  final double low;
  final double targetLow;
  final double targetHigh;
  final double high;
  final double veryHigh;

  const GlucoseRangeSettings({
    this.veryLow = AppConstants.defaultVeryLow,
    this.low = AppConstants.defaultLow,
    this.targetLow = AppConstants.defaultTargetLow,
    this.targetHigh = AppConstants.defaultTargetHigh,
    this.high = AppConstants.defaultHigh,
    this.veryHigh = AppConstants.defaultVeryHigh,
  });

  /// 기본 설정
  static const GlucoseRangeSettings defaults = GlucoseRangeSettings();

  /// 값이 target 범위 내인지 확인 (baseline/평소)
  bool isInTargetRange(double value) {
    return value >= targetLow && value <= targetHigh;
  }

  /// 값이 target 범위 밖인지 확인 (fluctuation/변동)
  bool isOutOfTargetRange(double value) {
    return value < targetLow || value > targetHigh;
  }

  /// 혈당 상태 문자열 반환
  String getStatus(double value) {
    if (value < veryLow) return 'veryLow';
    if (value < low) return 'low';
    if (value <= targetHigh) return 'normal';
    if (value <= high) return 'elevated';
    if (value <= veryHigh) return 'high';
    return 'veryHigh';
  }

  GlucoseRangeSettings copyWith({
    double? veryLow,
    double? low,
    double? targetLow,
    double? targetHigh,
    double? high,
    double? veryHigh,
  }) {
    return GlucoseRangeSettings(
      veryLow: veryLow ?? this.veryLow,
      low: low ?? this.low,
      targetLow: targetLow ?? this.targetLow,
      targetHigh: targetHigh ?? this.targetHigh,
      high: high ?? this.high,
      veryHigh: veryHigh ?? this.veryHigh,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'veryLow': veryLow,
      'low': low,
      'targetLow': targetLow,
      'targetHigh': targetHigh,
      'high': high,
      'veryHigh': veryHigh,
    };
  }

  factory GlucoseRangeSettings.fromJson(Map<String, dynamic> json) {
    return GlucoseRangeSettings(
      veryLow: (json['veryLow'] as num?)?.toDouble() ?? AppConstants.defaultVeryLow,
      low: (json['low'] as num?)?.toDouble() ?? AppConstants.defaultLow,
      targetLow: (json['targetLow'] as num?)?.toDouble() ?? AppConstants.defaultTargetLow,
      targetHigh: (json['targetHigh'] as num?)?.toDouble() ?? AppConstants.defaultTargetHigh,
      high: (json['high'] as num?)?.toDouble() ?? AppConstants.defaultHigh,
      veryHigh: (json['veryHigh'] as num?)?.toDouble() ?? AppConstants.defaultVeryHigh,
    );
  }
}
