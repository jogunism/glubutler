import 'package:glu_butler/models/glucose_record.dart';
import 'package:glu_butler/models/cgm_glucose_group.dart';
import 'package:glu_butler/models/glucose_range_settings.dart';

/// CGM 데이터 그룹화 서비스
/// 연속혈당측정기 데이터를 6시간 블록 단위로 그룹화
///
/// 그룹화 로직:
/// - 하루를 4개의 6시간 블록으로 분할:
///   00:00-05:59, 06:00-11:59, 12:00-17:59, 18:00-23:59
/// - 각 블록 내의 모든 CGM 데이터를 하나의 그룹으로 통합
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

  /// Manual entry app sources that should NOT be grouped as CGM
  /// These are apps where users manually enter glucose readings
  static const List<String> manualEntrySources = [
    'Glu Butler',
    'glubutler',   // Android package name: com.jogunism.gluButler
    'Glu Sight',
    'Health2Sync',
  ];

  /// CGM 그룹으로 판단하는 최소 레코드 수 (6시간 블록 내)
  static const int minRecordsForCgmGroup = 3;

  /// 소스명이 알려진 CGM인지 확인
  static bool isKnownCgmSource(String? sourceName) {
    if (sourceName == null) return false;
    final lowerSource = sourceName.toLowerCase();
    return knownCgmSources.any(
      (known) => lowerSource.contains(known.toLowerCase()),
    );
  }

  /// 소스명이 수동 입력 앱인지 확인
  static bool isManualEntrySource(String? sourceName) {
    if (sourceName == null) return false;
    final lowerSource = sourceName.toLowerCase();
    return manualEntrySources.any(
      (manual) => lowerSource.contains(manual.toLowerCase()),
    );
  }

  /// 주어진 시간이 속하는 6시간 블록의 시작 시간을 반환
  /// 블록: 00:00-05:59, 06:00-11:59, 12:00-17:59, 18:00-23:59
  static DateTime _getBlockStartTime(DateTime timestamp) {
    final hour = timestamp.hour;
    final blockStartHour = (hour ~/ 6) * 6; // 0, 6, 12, 18
    return DateTime(
      timestamp.year,
      timestamp.month,
      timestamp.day,
      blockStartHour,
    );
  }

  /// 혈당 레코드 리스트를 CGM 그룹과 개별 레코드로 분리
  /// CGM 데이터는 6시간 블록 단위로 그룹화
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

    // CGM 데이터와 수동 입력 데이터 분리
    final cgmRecords = <GlucoseRecord>[];
    for (final record in sorted) {
      if (!record.isFromHealthKit || isManualEntrySource(record.sourceName)) {
        // 수동 입력(로컬 DB)은 개별 레코드로 처리
        individualRecords.add(record);
      } else {
        // CGM 데이터
        cgmRecords.add(record);
      }
    }

    // CGM 데이터를 6시간 블록으로 그룹화
    if (cgmRecords.isNotEmpty) {
      final blockGroups = _groupIntoSixHourBlocks(cgmRecords);
      cgmGroups.addAll(blockGroups);
    }

    return (cgmGroups, individualRecords);
  }

  /// CGM 레코드를 6시간 블록으로 그룹화
  static List<CgmGlucoseGroup> _groupIntoSixHourBlocks(
    List<GlucoseRecord> records,
  ) {
    if (records.isEmpty) return [];

    // 블록별로 레코드 분류
    final Map<DateTime, List<GlucoseRecord>> blockMap = {};

    for (final record in records) {
      final blockStart = _getBlockStartTime(record.timestamp);
      blockMap.putIfAbsent(blockStart, () => []).add(record);
    }

    // 각 블록을 CgmGlucoseGroup으로 변환
    final groups = <CgmGlucoseGroup>[];
    for (final entry in blockMap.entries) {
      final blockRecords = entry.value;

      // 최소 레코드 수 확인
      if (blockRecords.length < minRecordsForCgmGroup) {
        continue; // 너무 적은 레코드는 그룹화하지 않음
      }

      // 시간순 정렬
      blockRecords.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      // 통계 계산
      final values = blockRecords.map((r) => r.value).toList();
      final minVal = values.reduce((a, b) => a < b ? a : b);
      final maxVal = values.reduce((a, b) => a > b ? a : b);
      final avgVal = values.reduce((a, b) => a + b) / values.length;

      // 6시간 블록 그룹 생성
      final group = CgmGlucoseGroup(
        id: 'cgm_block_${entry.key.millisecondsSinceEpoch}',
        records: blockRecords,
        groupType: CgmGroupType.baseline, // 6시간 블록은 모두 baseline으로 처리
        startTime: blockRecords.first.timestamp,
        endTime: blockRecords.last.timestamp,
        minValue: minVal,
        maxValue: maxVal,
        avgValue: avgVal,
        unit: blockRecords.first.unit,
        sourceName: blockRecords.first.sourceName,
      );

      groups.add(group);
    }

    // 시간순 정렬
    groups.sort((a, b) => a.startTime.compareTo(b.startTime));

    return groups;
  }
}
