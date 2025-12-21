import 'package:glu_butler/core/constants/app_constants.dart';

/// 혈당 범위 설정
/// 사용자가 커스터마이징 가능한 5단계 혈당 임계값
/// very low < low < target < high < very high
class GlucoseRangeSettings {
  final double veryLow;
  final double low;
  final double target;
  final double high;
  final double veryHigh;

  const GlucoseRangeSettings({
    this.veryLow = AppConstants.defaultVeryLow,
    this.low = AppConstants.defaultLow,
    this.target = AppConstants.defaultTarget,
    this.high = AppConstants.defaultHigh,
    this.veryHigh = AppConstants.defaultVeryHigh,
  });

  /// 기본 설정
  static const GlucoseRangeSettings defaults = GlucoseRangeSettings();

  /// 정상 범위 오프셋 (target ± 20)
  static const double targetOffset = 20.0;

  /// 정상 범위 하한 (target - 20)
  double get targetLow => target - targetOffset;

  /// 정상 범위 상한 (target + 20)
  double get targetHigh => target + targetOffset;

  /// 값이 target 범위 내인지 확인 (baseline/평소)
  /// target ± 20 범위를 정상으로 간주
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
    if (value <= target) return 'normal';
    if (value <= high) return 'elevated';
    if (value <= veryHigh) return 'high';
    return 'veryHigh';
  }

  GlucoseRangeSettings copyWith({
    double? veryLow,
    double? low,
    double? target,
    double? high,
    double? veryHigh,
  }) {
    return GlucoseRangeSettings(
      veryLow: veryLow ?? this.veryLow,
      low: low ?? this.low,
      target: target ?? this.target,
      high: high ?? this.high,
      veryHigh: veryHigh ?? this.veryHigh,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'veryLow': veryLow,
      'low': low,
      'target': target,
      'high': high,
      'veryHigh': veryHigh,
    };
  }

  factory GlucoseRangeSettings.fromJson(Map<String, dynamic> json) {
    return GlucoseRangeSettings(
      veryLow: (json['veryLow'] as num?)?.toDouble() ?? AppConstants.defaultVeryLow,
      low: (json['low'] as num?)?.toDouble() ?? AppConstants.defaultLow,
      target: (json['target'] as num?)?.toDouble() ?? AppConstants.defaultTarget,
      high: (json['high'] as num?)?.toDouble() ?? AppConstants.defaultHigh,
      veryHigh: (json['veryHigh'] as num?)?.toDouble() ?? AppConstants.defaultVeryHigh,
    );
  }
}
