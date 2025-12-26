import 'package:glu_butler/models/glucose_record.dart';
import 'package:glu_butler/models/glucose_range_settings.dart';

/// 혈당 관리 점수 계산 서비스
///
/// 총 100점 만점으로 다음 요소를 평가:
/// - 기본: 혈당 품질(50점) + 측정 일관성(50점)
/// - 건강 앱 연동시: 혈당 품질(40점) + 측정 일관성(30점) + 생활습관(30점)
class GlucoseScoreService {
  /// 혈당 관리 점수 계산
  ///
  /// [records]: 해당 날짜의 혈당 측정 기록
  /// [glucoseRange]: 목표 혈당 범위
  /// [currentTime]: 현재 시간 (테스트용, null이면 DateTime.now() 사용)
  /// [sleepHours]: 수면 시간 (건강 앱 연동시)
  /// [exerciseMinutes]: 운동 시간 (분, 건강 앱 연동시)
  static int calculateScore({
    required List<GlucoseRecord> records,
    required GlucoseRangeSettings glucoseRange,
    DateTime? currentTime,
    double? sleepHours,
    int? exerciseMinutes,
  }) {
    if (records.isEmpty) return 0;

    final now = currentTime ?? DateTime.now();
    final hasHealthData = sleepHours != null || exerciseMinutes != null;

    if (hasHealthData) {
      // 건강 앱 연동시: 40 + 30 + 30 = 100
      final qualityScore = _calculateQualityScore(records, glucoseRange, 40);
      final consistencyScore = _calculateConsistencyScore(records, now, 30);
      final lifestyleScore = _calculateLifestyleScore(
        sleepHours: sleepHours,
        exerciseMinutes: exerciseMinutes,
        maxScore: 30,
        currentTime: now,
      );

      return qualityScore + consistencyScore + lifestyleScore;
    } else {
      // 기본: 50 + 50 = 100
      final qualityScore = _calculateQualityScore(records, glucoseRange, 50);
      final consistencyScore = _calculateConsistencyScore(records, now, 50);

      return qualityScore + consistencyScore;
    }
  }

  /// 혈당 품질 점수 계산
  ///
  /// 각 측정값이 목표 범위에 얼마나 가까운지 평가
  /// - 목표 범위 내: 100%
  /// - 목표 ±20 이내: 80%
  /// - 경고 범위: 50%
  /// - 위험 범위: 20%
  static int _calculateQualityScore(
    List<GlucoseRecord> records,
    GlucoseRangeSettings glucoseRange,
    int maxScore,
  ) {
    double totalScore = 0;

    for (final record in records) {
      final value = record.valueIn('mg/dL');
      final score = _getValueScore(value, glucoseRange);
      totalScore += score;
    }

    final avgScore = totalScore / records.length;
    return (avgScore * maxScore).round();
  }

  /// 개별 측정값의 점수 (0.0 ~ 1.0)
  static double _getValueScore(double value, GlucoseRangeSettings range) {
    // 목표 범위 내 (target ±20)
    if (value >= range.targetLow && value <= range.targetHigh) {
      return 1.0;
    }

    // 경고 범위 (low ~ high)
    if (value >= range.low && value <= range.high) {
      return 0.7;
    }

    // 위험 범위 (veryLow ~ veryHigh)
    if (value >= range.veryLow && value <= range.veryHigh) {
      return 0.4;
    }

    // 매우 위험 범위
    return 0.1;
  }

  /// 측정 일관성 점수 계산
  ///
  /// 현재 시간 기준으로 기대되는 측정 횟수 대비 실제 측정 횟수
  /// - 오전 9시 이전: 최소 1회 (공복)
  /// - 오후 2시 이전: 최소 3회 (공복 + 아침 식전/식후)
  /// - 오후 7시 이전: 최소 5회 (+ 점심 식전/식후)
  /// - 오후 10시 이후: 최소 6회 (+ 저녁 식전/식후 + 자기전)
  static int _calculateConsistencyScore(
    List<GlucoseRecord> records,
    DateTime currentTime,
    int maxScore,
  ) {
    final hour = currentTime.hour;
    final actualCount = records.length;

    int expectedCount;
    if (hour < 9) {
      expectedCount = 1; // 공복
    } else if (hour < 14) {
      expectedCount = 3; // 공복 + 아침 식전/식후
    } else if (hour < 19) {
      expectedCount = 5; // + 점심 식전/식후
    } else {
      expectedCount = 6; // + 저녁 식전/식후 + 자기전
    }

    // 기대치 이상 측정하면 만점
    final ratio = (actualCount / expectedCount).clamp(0.0, 1.0);
    return (ratio * maxScore).round();
  }

  /// 생활습관 점수 계산 (건강 앱 연동시)
  ///
  /// - 오후 10시 이전: 수면만으로 maxScore 만점
  /// - 오후 10시 이후: 수면 + 운동 각각 maxScore의 50%씩
  static int _calculateLifestyleScore({
    double? sleepHours,
    int? exerciseMinutes,
    required int maxScore,
    required DateTime currentTime,
  }) {
    int score = 0;
    final isAfter10PM = currentTime.hour >= 22;

    // 수면 점수
    if (sleepHours != null) {
      double sleepScore;
      if (sleepHours >= 7 && sleepHours <= 8) {
        sleepScore = 1.0; // 만점
      } else if (sleepHours >= 6 && sleepHours <= 9) {
        sleepScore = 0.8; // 80%
      } else if (sleepHours >= 5 && sleepHours <= 10) {
        sleepScore = 0.5; // 50%
      } else {
        sleepScore = 0.2; // 20%
      }

      // 10시 이전: 수면만으로 전체 점수, 10시 이후: 절반만
      final sleepMaxScore = isAfter10PM ? maxScore / 2 : maxScore.toDouble();
      final sleepPoints = (sleepScore * sleepMaxScore).round();
      score += sleepPoints;
    }

    // 운동 점수 - 오후 10시 이후에만 계산
    if (exerciseMinutes != null && isAfter10PM) {
      double exerciseScore;
      if (exerciseMinutes >= 30) {
        exerciseScore = 1.0; // 만점
      } else if (exerciseMinutes >= 20) {
        exerciseScore = 0.7; // 70%
      } else if (exerciseMinutes >= 10) {
        exerciseScore = 0.4; // 40%
      } else {
        exerciseScore = 0.1; // 10%
      }
      final exercisePoints = (exerciseScore * maxScore / 2).round();
      score += exercisePoints;
    }

    return score;
  }

  /// 점수에 따른 등급 메시지 키 반환
  static String getScoreGradeKey(int score) {
    if (score >= 90) return 'excellentScore';
    if (score >= 80) return 'greatScore';
    if (score >= 70) return 'goodScore';
    if (score >= 60) return 'fairScore';
    return 'needsAttention';
  }
}
