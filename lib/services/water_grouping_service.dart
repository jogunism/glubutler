import 'package:glu_butler/models/water_record.dart';
import 'package:glu_butler/models/water_group.dart';

/// Water 데이터 그룹화 서비스
///
/// 하루의 수분 섭취량을 날짜별로 집계합니다.
class WaterGroupingService {
  /// Water 레코드를 날짜별로 그룹화하고 총량 계산
  ///
  /// [records]: 그룹화할 water 레코드 리스트
  /// 반환: 날짜별 water 그룹 리스트
  static List<WaterGroup> groupWaterRecords(List<WaterRecord> records) {
    if (records.isEmpty) {
      return [];
    }

    // 날짜별로 그룹화 (timestamp의 날짜 기준)
    final Map<DateTime, List<WaterRecord>> byDate = {};
    for (final record in records) {
      // timestamp의 날짜를 키로 사용 (시간은 0으로)
      final date = DateTime(
        record.timestamp.year,
        record.timestamp.month,
        record.timestamp.day,
      );
      byDate.putIfAbsent(date, () => []).add(record);
    }

    final List<WaterGroup> groups = [];

    // 각 날짜별로 총량 계산
    for (final entry in byDate.entries) {
      final date = entry.key;
      final dateRecords = entry.value;

      // 총량 계산
      final totalAmount = dateRecords.fold<double>(
        0,
        (sum, record) => sum + record.amountMl,
      );

      // ID 생성 (날짜)
      final id = 'water_group_${date.toIso8601String().split('T')[0]}';

      groups.add(WaterGroup(
        id: id,
        date: date,
        totalAmountMl: totalAmount,
        records: dateRecords,
      ));
    }

    // 그룹을 날짜순으로 정렬 (최신 것부터)
    groups.sort((a, b) => b.date.compareTo(a.date));

    return groups;
  }
}
