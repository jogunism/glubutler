import 'package:flutter/foundation.dart';
import 'package:glu_butler/models/glucose_record.dart';
import 'package:glu_butler/models/cgm_glucose_group.dart';
import 'package:glu_butler/models/glucose_range_settings.dart';

/// CGM 데이터 그룹화 서비스
/// 연속혈당측정기 데이터를 감지하고 베이스라인/변동으로 그룹화
///
/// 그룹화 로직:
/// 1. 날짜별로 데이터 분리 (자정 기준)
/// 2. targetLow ~ targetHigh 범위로 표준/변동 구분
///    - targetLow ~ targetHigh 범위: 표준
///    - 그 외 (< targetLow 또는 > targetHigh): 변동
/// 3. 연속된 동일 타입 그룹 병합
/// 4. 잦은 표준↔변동 반복 구간은 변동으로 통합
class CgmGroupingService {
  /// 알려진 CGM 기기 소스명 목록
  static const List<String> knownCgmSources = [
    // Dexcom
    'Dexcom',
    'Dexcom G6',
    'Dexcom G7',
    'Dexcom ONE',
    'Dexcom ONE+',
    // Abbott FreeStyle Libre
    'FreeStyle Libre',
    'FreeStyle Libre 2',
    'FreeStyle Libre 3',
    'Libre',
    'LibreLink',
    // Medtronic
    'Medtronic',
    'Guardian',
    'Guardian Connect',
    'Guardian Sensor',
    'MiniMed',
    // Eversense
    'Eversense',
    // Senseonics
    'Senseonics',
  ];

  /// CGM 데이터 최대 간격 (분) - 알려진 CGM 소스용
  static const int cgmKnownSourceMaxInterval = 20;

  /// CGM 추정 최대 간격 (분) - 미확인 소스용 (더 엄격)
  static const int cgmUnknownSourceMaxInterval = 7;

  /// CGM 그룹으로 판단하는 최소 레코드 수
  static const int minRecordsForCgmGroup = 3;

  /// 잦은 반복으로 판단하는 최소 그룹 레코드 수
  static const int minGroupRecords = 10;

  /// 소스명이 알려진 CGM인지 확인
  static bool isKnownCgmSource(String? sourceName) {
    if (sourceName == null) return false;
    final lowerSource = sourceName.toLowerCase();
    return knownCgmSources.any(
      (known) => lowerSource.contains(known.toLowerCase()),
    );
  }

  /// 혈당 값이 표준 범위인지 확인 (targetLow ~ targetHigh)
  static bool _isBaseline(double value, GlucoseRangeSettings settings) {
    return value >= settings.targetLow && value <= settings.targetHigh;
  }

  /// 혈당 레코드 리스트를 CGM 그룹과 개별 레코드로 분리
  static (List<CgmGlucoseGroup>, List<GlucoseRecord>) groupGlucoseRecords(
    List<GlucoseRecord> records, {
    GlucoseRangeSettings rangeSettings = const GlucoseRangeSettings(),
  }) {
    if (records.isEmpty) {
      return ([], []);
    }

    // 시간순 정렬 (오래된 것부터)
    final sorted = List<GlucoseRecord>.from(records)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final List<CgmGlucoseGroup> cgmGroups = [];
    final List<GlucoseRecord> individualRecords = [];

    // 소스별로 레코드 분리
    final Map<String?, List<GlucoseRecord>> bySource = {};
    for (final record in sorted) {
      bySource.putIfAbsent(record.sourceName, () => []).add(record);
    }

    // 각 소스별로 처리
    for (final entry in bySource.entries) {
      final sourceName = entry.key;
      final sourceRecords = entry.value;
      final isKnownCgm = isKnownCgmSource(sourceName);

      _processSourceRecords(
        sourceRecords,
        isKnownCgm,
        cgmGroups,
        individualRecords,
        rangeSettings,
      );
    }

    // 그룹을 시간순으로 정렬
    cgmGroups.sort((a, b) => a.startTime.compareTo(b.startTime));

    return (cgmGroups, individualRecords);
  }

  /// 특정 소스의 레코드들을 처리
  /// 1단계: 날짜별로 분리 + 시간 간격으로 시퀀스 분리
  static void _processSourceRecords(
    List<GlucoseRecord> records,
    bool isKnownCgm,
    List<CgmGlucoseGroup> cgmGroups,
    List<GlucoseRecord> individualRecords,
    GlucoseRangeSettings rangeSettings,
  ) {
    if (records.isEmpty) return;

    final maxInterval =
        isKnownCgm ? cgmKnownSourceMaxInterval : cgmUnknownSourceMaxInterval;

    // 연속 시퀀스로 분리 (날짜 변경 또는 시간 간격 초과 시)
    List<GlucoseRecord> currentSequence = [];

    for (final record in records) {
      if (currentSequence.isEmpty) {
        currentSequence.add(record);
        continue;
      }

      final lastRecord = currentSequence.last;
      final gap = record.timestamp.difference(lastRecord.timestamp).inMinutes;

      // 날짜가 변경되면 시퀀스 분리 (자정 기준)
      final isDifferentDay = record.timestamp.day != lastRecord.timestamp.day ||
          record.timestamp.month != lastRecord.timestamp.month ||
          record.timestamp.year != lastRecord.timestamp.year;

      if (gap <= maxInterval && gap >= 0 && !isDifferentDay) {
        currentSequence.add(record);
      } else {
        // 시퀀스 종료
        _processSequence(currentSequence, isKnownCgm, cgmGroups, individualRecords, rangeSettings);
        currentSequence = [record];
      }
    }

    // 마지막 시퀀스 처리
    if (currentSequence.isNotEmpty) {
      _processSequence(currentSequence, isKnownCgm, cgmGroups, individualRecords, rangeSettings);
    }
  }

  /// 시퀀스를 CGM 그룹 또는 개별 레코드로 분류
  static void _processSequence(
    List<GlucoseRecord> sequence,
    bool isKnownCgm,
    List<CgmGlucoseGroup> cgmGroups,
    List<GlucoseRecord> individualRecords,
    GlucoseRangeSettings rangeSettings,
  ) {
    final minRecords = isKnownCgm ? 2 : minRecordsForCgmGroup;

    if (sequence.length < minRecords) {
      individualRecords.addAll(sequence);
      return;
    }

    // 2단계: 5가지 수치로 표준/변동 구간 그룹화
    final groups = _splitByRangeSettings(sequence, rangeSettings);
    cgmGroups.addAll(groups);
  }

  /// 2단계: 5가지 수치(low~high)를 기준으로 표준/변동 분할
  /// - low ~ high 범위: 표준 (baseline)
  /// - 그 외: 변동 (fluctuation)
  static List<CgmGlucoseGroup> _splitByRangeSettings(
    List<GlucoseRecord> sequence,
    GlucoseRangeSettings rangeSettings,
  ) {
    if (sequence.isEmpty) return [];

    // 디버그 로깅 (10월 27일만)
    bool hasOct27 = sequence.any((r) => r.timestamp.month == 10 && r.timestamp.day == 27);
    if (hasOct27) {
      debugPrint('[CGM] === 그룹화 시작 ===');
      debugPrint('[CGM] 표준 범위: ${rangeSettings.targetLow} ~ ${rangeSettings.targetHigh}');
      debugPrint('[CGM] 레코드 수: ${sequence.length}');
    }

    if (sequence.length == 1) {
      final isBaseline = _isBaseline(sequence.first.value, rangeSettings);
      return [_createGroup(sequence, isBaseline ? CgmGroupType.baseline : CgmGroupType.fluctuation)];
    }

    // 각 레코드를 표준/변동으로 분류하여 그룹 생성
    final List<CgmGlucoseGroup> groups = [];
    List<GlucoseRecord> currentSegment = [sequence.first];
    bool currentIsBaseline = _isBaseline(sequence.first.value, rangeSettings);

    for (int i = 1; i < sequence.length; i++) {
      final record = sequence[i];
      final isBaseline = _isBaseline(record.value, rangeSettings);

      if (isBaseline == currentIsBaseline) {
        // 같은 타입이면 현재 세그먼트에 추가
        currentSegment.add(record);
      } else {
        // 타입이 바뀌면 현재 세그먼트 저장 후 새 세그먼트 시작
        groups.add(_createGroup(
          currentSegment,
          currentIsBaseline ? CgmGroupType.baseline : CgmGroupType.fluctuation,
        ));
        currentSegment = [record];
        currentIsBaseline = isBaseline;
      }
    }

    // 마지막 세그먼트 처리
    if (currentSegment.isNotEmpty) {
      groups.add(_createGroup(
        currentSegment,
        currentIsBaseline ? CgmGroupType.baseline : CgmGroupType.fluctuation,
      ));
    }

    if (hasOct27) {
      debugPrint('[CGM] 초기 그룹 수: ${groups.length}');
    }

    // 3단계: 연속된 동일 타입 그룹 병합
    final mergedGroups = _mergeSameTypeGroups(groups);

    if (hasOct27) {
      debugPrint('[CGM] 동일 타입 병합 후: ${mergedGroups.length}');
      for (final g in mergedGroups) {
        debugPrint('[CGM]   ${g.groupType}: ${g.recordCount}개, ${g.minValue.toInt()}~${g.maxValue.toInt()}');
      }
    }

    // 4단계: 작은 그룹들을 큰 그룹에 흡수 + 연속 작은 그룹 병합
    final finalGroups = _mergeOscillatingGroups(mergedGroups);

    if (hasOct27) {
      debugPrint('[CGM] === 최종 결과 ===');
      debugPrint('[CGM] 최종 그룹 수: ${finalGroups.length}');
      for (final g in finalGroups) {
        debugPrint('[CGM]   ${g.groupType}: ${g.recordCount}개, ${g.minValue.toInt()}~${g.maxValue.toInt()}');
      }
    }

    return finalGroups;
  }

  /// 3단계: 연속된 같은 타입 그룹 병합
  static List<CgmGlucoseGroup> _mergeSameTypeGroups(List<CgmGlucoseGroup> groups) {
    if (groups.length <= 1) return groups;

    final List<CgmGlucoseGroup> result = [];
    List<GlucoseRecord> currentRecords = List.from(groups.first.records);
    CgmGroupType currentType = groups.first.groupType;

    for (int i = 1; i < groups.length; i++) {
      final group = groups[i];

      if (group.groupType == currentType) {
        currentRecords.addAll(group.records);
      } else {
        result.add(_createGroup(currentRecords, currentType));
        currentRecords = List.from(group.records);
        currentType = group.groupType;
      }
    }

    if (currentRecords.isNotEmpty) {
      result.add(_createGroup(currentRecords, currentType));
    }

    return result;
  }

  /// 4단계: 작은 그룹들을 큰 그룹에 흡수
  /// - 작은 fluctuation(5개 미만)이 큰 baseline 사이에 있으면 앞의 baseline에 흡수
  /// - 연속된 작은 그룹들(minGroupRecords 미만)이 2개 이상이면 fluctuation으로 병합
  static List<CgmGlucoseGroup> _mergeOscillatingGroups(List<CgmGlucoseGroup> groups) {
    if (groups.length <= 1) return groups;

    // 1차: 작은 fluctuation을 인접 큰 baseline에 흡수
    final absorbed = _absorbSmallFluctuations(groups);

    // 2차: 연속된 작은 그룹들을 fluctuation으로 병합
    final merged = _mergeConsecutiveSmallGroups(absorbed);

    // 3차: 같은 타입 그룹 병합
    return _mergeSameTypeGroups(merged);
  }

  /// 작은 fluctuation(5개 미만)을 인접한 큰 baseline에 흡수
  /// baseline(큰) - fluctuation(작은) - baseline(어떤것이든) 패턴에서
  /// fluctuation을 앞의 baseline에 흡수
  static List<CgmGlucoseGroup> _absorbSmallFluctuations(List<CgmGlucoseGroup> groups) {
    if (groups.length <= 2) return groups;

    final List<CgmGlucoseGroup> result = [];
    int i = 0;

    while (i < groups.length) {
      final current = groups[i];

      // 마지막 그룹이거나 그 다음이 없으면 그대로 추가
      if (i >= groups.length - 1) {
        result.add(current);
        i++;
        continue;
      }

      final next = groups[i + 1];

      // 현재가 큰 baseline이고, 다음이 작은 fluctuation(5개 미만)인 경우
      if (current.groupType == CgmGroupType.baseline &&
          current.recordCount >= minGroupRecords &&
          next.groupType == CgmGroupType.fluctuation &&
          next.recordCount < 5) {
        // fluctuation을 baseline에 흡수
        final combinedRecords = [...current.records, ...next.records]
          ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
        result.add(_createGroup(combinedRecords, CgmGroupType.baseline));
        i += 2; // 두 그룹 모두 처리됨
      } else {
        result.add(current);
        i++;
      }
    }

    return result;
  }

  /// 연속된 작은 그룹들(minGroupRecords 미만)이 2개 이상이면 fluctuation으로 병합
  static List<CgmGlucoseGroup> _mergeConsecutiveSmallGroups(List<CgmGlucoseGroup> groups) {
    if (groups.length <= 1) return groups;

    final List<CgmGlucoseGroup> result = [];
    int i = 0;

    while (i < groups.length) {
      final current = groups[i];

      // 현재 그룹이 충분히 크면 그대로 추가
      if (current.recordCount >= minGroupRecords) {
        result.add(current);
        i++;
        continue;
      }

      // 짧은 그룹 시작 - 연속된 짧은 그룹들을 찾음
      List<CgmGlucoseGroup> smallSequence = [current];
      int j = i + 1;

      while (j < groups.length && groups[j].recordCount < minGroupRecords) {
        smallSequence.add(groups[j]);
        j++;
      }

      // 2개 이상의 짧은 그룹이 연속되면 전체를 fluctuation으로 합침
      if (smallSequence.length >= 2) {
        final allRecords = smallSequence
            .expand((g) => g.records)
            .toList()
          ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
        result.add(_createGroup(allRecords, CgmGroupType.fluctuation));
      } else {
        // 1개면 그대로 추가
        result.addAll(smallSequence);
      }

      i = j;
    }

    return result;
  }

  /// CgmGlucoseGroup 생성
  static CgmGlucoseGroup _createGroup(
    List<GlucoseRecord> records,
    CgmGroupType groupType,
  ) {
    final values = records.map((r) => r.value).toList();
    final minVal = values.reduce((a, b) => a < b ? a : b);
    final maxVal = values.reduce((a, b) => a > b ? a : b);
    final avgVal = values.reduce((a, b) => a + b) / values.length;

    return CgmGlucoseGroup(
      id: 'cgm_${records.first.timestamp.millisecondsSinceEpoch}',
      records: records,
      groupType: groupType,
      startTime: records.first.timestamp,
      endTime: records.last.timestamp,
      minValue: minVal,
      maxValue: maxVal,
      avgValue: avgVal,
      unit: records.first.unit,
      sourceName: records.first.sourceName,
    );
  }
}
