import 'package:flutter/foundation.dart';
import 'package:glu_butler/models/diary_item.dart';
import 'package:glu_butler/repositories/diary_repository.dart';
import 'package:glu_butler/services/cloudkit_service.dart';
import 'package:glu_butler/services/settings_service.dart';
import 'package:glu_butler/services/analytics_service.dart';

/// 일기 데이터 관리 Provider
///
/// 일기 엔트리의 CRUD 작업과 상태 관리를 담당합니다.
class DiaryProvider extends ChangeNotifier {
  final DiaryRepository _repository = DiaryRepository();
  SettingsService? _settingsService;

  List<DiaryItem> _entries = [];
  List<DiaryItem> get entries => _entries;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  // Refresh trigger timestamp - updated on each refresh to reset card states
  int _refreshTimestamp = 0;
  int get refreshTimestamp => _refreshTimestamp;

  /// SettingsService 설정 (iCloud 동기화 확인용)
  void setSettingsService(SettingsService settingsService) {
    _settingsService = settingsService;
  }

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
      // Update refresh timestamp to reset card states
      _refreshTimestamp = DateTime.now().millisecondsSinceEpoch;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// iCloud에서 다이어리 동기화 (다운로드 후 UI 업데이트)
  Future<void> syncFromICloud() async {
    if (_settingsService?.iCloudSyncEnabled != true) {
      return;
    }

    try {
      await CloudKitService.downloadDiaryEntries();

      // DB에서 데이터 다시 로드하여 UI 업데이트
      await refreshData();
    } catch (e) {
      // 에러 무시 (백그라운드 동기화 실패는 사용자에게 영향 없음)
    }
  }

  /// 일기 추가
  Future<bool> addEntry(DiaryItem entry) async {
    try {
      await _repository.save(entry);
      await refreshData();

      // iCloud 자동 업로드 (백그라운드)
      _syncToICloudIfEnabled(entry);

      // Log diary created (sampled - once per day)
      await AnalyticsService.logDiaryCreated();

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

      // iCloud 자동 업로드 (백그라운드)
      _syncToICloudIfEnabled(entry);

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

      // iCloud에서도 삭제 (백그라운드)
      _deleteFromICloudIfEnabled(id);

      return true;
    } catch (e) {
      _error = 'Failed to delete diary entry';
      notifyListeners();
      return false;
    }
  }

  /// iCloud에서 삭제 (백그라운드, 에러 무시)
  void _deleteFromICloudIfEnabled(String entryId) {
    if (_settingsService?.iCloudSyncEnabled != true) {
      return;
    }

    CloudKitService.deleteDiaryEntry(entryId).then((_) {
    }).catchError((error) {
      // 에러 무시 (로컬 삭제는 이미 성공했으므로)
    });
  }

  /// iCloud 동기화 (백그라운드, 에러 무시)
  void _syncToICloudIfEnabled(DiaryItem entry) {

    // iCloud Sync가 활성화되어 있는지 확인
    if (_settingsService?.iCloudSyncEnabled != true) {
      return;
    }

    // 백그라운드에서 단일 엔트리 업로드
    CloudKitService.uploadDiaryEntry(entry).then((_) {
    }).catchError((error) {
      // 에러 무시 (로컬 저장은 이미 성공했으므로)
    });
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

  /// API 리포트용 간소화된 일기 데이터 생성
  ///
  /// 일기 데이터를 간단한 포맷으로 변환:
  /// {
  ///   "time": "2024-12-30T18:30",
  ///   "content": "일기 내용",
  ///   "files": [
  ///     {
  ///       "path": "filename.jpg",
  ///       "time": "2024-12-30T18:30",
  ///       "location": "50.1356,8.5067"
  ///     }
  ///   ]
  /// }
  List<Map<String, dynamic>> getSimplifiedReportData({
    required DateTime startDate,
    required DateTime endDate,
  }) {
    final entries = getEntriesInRange(
      startDate: startDate,
      endDate: endDate,
    );

    return entries.map((entry) {
      // 파일 정보 간소화
      final simplifiedFiles = entry.files.map((file) {
        // 파일 경로에서 파일명만 추출
        final fileName = file.filePath.split('/').last;

        // 위도와 경도를 결합
        final location = file.latitude != null && file.longitude != null
            ? '${file.latitude},${file.longitude}'
            : null;

        // capturedAt이 null이면 파일을 제외
        if (file.capturedAt == null) return null;

        return {
          'path': fileName,
          'time': _formatTimeForApi(file.capturedAt!),
          if (location != null) 'location': location,
        };
      }).whereType<Map<String, dynamic>>().toList(); // null 제거

      return {
        'time': _formatTimeForApi(entry.timestamp),
        'content': entry.content,
        'files': simplifiedFiles,
      };
    }).toList();
  }

  /// API용 시간 포맷 (초 단위 제거)
  String _formatTimeForApi(DateTime dateTime) {
    return dateTime.toIso8601String().substring(0, 16); // "2024-12-30T18:30"
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
