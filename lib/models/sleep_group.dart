import 'package:glu_butler/models/sleep_record.dart';

/// Sleep 레코드 그룹
/// 하루의 수면 데이터를 하나로 묶어서 표시
class SleepGroup {
  final String id;
  final DateTime date; // 수면이 종료된 날짜 기준
  final DateTime startTime;
  final DateTime endTime;
  final int totalDurationMinutes;
  final List<SleepRecord> records;
  final String? sourceName;

  SleepGroup({
    required this.id,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.totalDurationMinutes,
    required this.records,
    this.sourceName,
  });

  String get formattedDuration {
    final hours = totalDurationMinutes ~/ 60;
    final minutes = totalDurationMinutes % 60;
    if (hours > 0 && minutes > 0) {
      return '${hours}h ${minutes}m';
    } else if (hours > 0) {
      return '${hours}h';
    } else {
      return '${minutes}m';
    }
  }

  /// 수면 단계별 시간 계산
  Map<SleepStage, int> get stageDurations {
    final Map<SleepStage, int> durations = {};
    for (final record in records) {
      final stage = record.stage ?? SleepStage.unknown;
      durations[stage] = (durations[stage] ?? 0) + record.durationMinutes;
    }
    return durations;
  }

  /// REM 수면 비율 (%)
  double? get remPercentage {
    final remDuration = stageDurations[SleepStage.rem];
    if (remDuration == null || totalDurationMinutes == 0) return null;
    return (remDuration / totalDurationMinutes * 100);
  }

  /// 깊은 수면 비율 (%)
  double? get deepPercentage {
    final deepDuration = stageDurations[SleepStage.deep];
    if (deepDuration == null || totalDurationMinutes == 0) return null;
    return (deepDuration / totalDurationMinutes * 100);
  }

  /// JSON으로 변환 (API 전송용)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'totalDurationMinutes': totalDurationMinutes,
      'records': records.map((r) => r.toJson()).toList(),
      'sourceName': sourceName,
    };
  }
}
