import 'package:glu_butler/models/sleep_record.dart';
import 'package:glu_butler/models/sleep_group.dart';

/// Sleep 데이터 그룹화 서비스
///
/// In Bed 레코드를 SleepGroup으로 변환합니다.
///
/// 그룹화 로직:
/// 1. 각 In Bed 레코드는 이미 완전한 수면 세션을 나타냄
/// 2. 각 레코드를 endTime 날짜의 피드에 배치
class SleepGroupingService {
  /// 최소 수면 시간 (분) - 이보다 짧으면 표시하지 않음
  static const int minSleepDurationMinutes = 30;

  /// Sleep 레코드를 그룹으로 변환
  ///
  /// [records]: In Bed 레코드 리스트
  /// 반환: (그룹화된 sleep 리스트, 개별 sleep 리스트)
  static (List<SleepGroup>, List<SleepRecord>) groupSleepRecords(
    List<SleepRecord> records,
  ) {
    if (records.isEmpty) {
      return ([], []);
    }

    final List<SleepGroup> groups = [];
    final List<SleepRecord> individuals = [];

    // 각 In Bed 레코드를 그룹으로 변환
    for (final record in records) {
      // endTime의 날짜로 그룹 배치
      final date = DateTime(
        record.endTime.year,
        record.endTime.month,
        record.endTime.day,
      );

      // 최소 수면 시간 확인
      if (record.durationMinutes >= minSleepDurationMinutes) {
        final group = _createSleepGroup(date, [record]);
        groups.add(group);
      } else {
        individuals.add(record);
      }
    }

    // 그룹을 날짜순으로 정렬 (최신 것부터)
    groups.sort((a, b) => b.date.compareTo(a.date));

    return (groups, individuals);
  }

  /// In Bed 레코드로 SleepGroup 생성
  static SleepGroup _createSleepGroup(
    DateTime date,
    List<SleepRecord> records,
  ) {
    final record = records.first;

    // ID 생성 (날짜 + 시작시간)
    final id = 'sleep_group_${date.toIso8601String().split('T')[0]}_${record.startTime.millisecondsSinceEpoch}';

    return SleepGroup(
      id: id,
      date: date,
      startTime: record.startTime,
      endTime: record.endTime,
      totalDurationMinutes: record.durationMinutes,
      records: records,
      sourceName: record.sourceName,
    );
  }
}
