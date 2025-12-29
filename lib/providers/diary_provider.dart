import 'package:flutter/foundation.dart';
import 'package:glu_butler/models/diary_item.dart';
import 'package:glu_butler/repositories/diary_repository.dart';

/// 일기 데이터 관리 Provider
///
/// 일기 엔트리의 CRUD 작업과 상태 관리를 담당합니다.
class DiaryProvider extends ChangeNotifier {
  final DiaryRepository _repository = DiaryRepository();

  List<DiaryItem> _entries = [];
  List<DiaryItem> get entries => _entries;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  /// 초기화 및 데이터 로드
  Future<void> initialize() async {
    await refreshData();
  }

  /// 데이터 새로고침
  Future<void> refreshData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _entries = await _repository.fetch();
    } catch (e) {
      _error = e.toString();
      debugPrint('[DiaryProvider] Error loading entries: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 일기 추가
  Future<bool> addEntry(DiaryItem entry) async {
    try {
      await _repository.save(entry);
      await refreshData();
      return true;
    } catch (e) {
      _error = 'Failed to add diary entry';
      notifyListeners();
      return false;
    }
  }

  /// 일기 수정
  Future<bool> updateEntry(DiaryItem entry) async {
    try {
      await _repository.update(entry);
      await refreshData();
      return true;
    } catch (e) {
      _error = 'Failed to update diary entry';
      notifyListeners();
      return false;
    }
  }

  /// 일기 삭제
  Future<bool> deleteEntry(String id) async {
    try {
      await _repository.delete(id);
      await refreshData();
      return true;
    } catch (e) {
      _error = 'Failed to delete diary entry';
      notifyListeners();
      return false;
    }
  }

  /// 특정 날짜 범위의 일기 가져오기 (리포트용)
  List<DiaryItem> getEntriesInRange({
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return _entries.where((entry) {
      return entry.timestamp.isAfter(startDate.subtract(const Duration(days: 1))) &&
          entry.timestamp.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();
  }

  /// 리포트 API용 일기 데이터 반환
  ///
  /// [startDate]: 시작 날짜
  /// [endDate]: 종료 날짜
  /// Returns: 선택된 날짜 범위의 일기 리스트
  List<DiaryItem> getReportData({
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return getEntriesInRange(
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// 특정 날짜의 일기 가져오기
  List<DiaryItem> getEntriesForDate(DateTime date) {
    return _entries.where((entry) {
      return entry.timestamp.year == date.year &&
          entry.timestamp.month == date.month &&
          entry.timestamp.day == date.day;
    }).toList();
  }

  /// 날짜별로 그룹핑된 일기
  Map<DateTime, List<DiaryItem>> get entriesByDate {
    final Map<DateTime, List<DiaryItem>> grouped = {};
    for (final entry in _entries) {
      final dateKey = DateTime(
        entry.timestamp.year,
        entry.timestamp.month,
        entry.timestamp.day,
      );
      grouped.putIfAbsent(dateKey, () => []).add(entry);
    }
    return grouped;
  }
}
