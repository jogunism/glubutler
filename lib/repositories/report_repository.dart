import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'package:glu_butler/models/report.dart';
import 'package:glu_butler/models/user_identity.dart';
import 'package:glu_butler/models/user_profile.dart';
import 'package:glu_butler/providers/feed_provider.dart';
import 'package:glu_butler/providers/diary_provider.dart';
import 'package:glu_butler/services/database_service.dart';
import 'package:glu_butler/services/report_api_service.dart';
import 'package:glu_butler/services/settings_service.dart';

/// Repository for report generation and management.
///
/// Handles the logic of generating AI reports via API
/// and reading/writing reports from/to local database.
class ReportRepository {
  final ReportApiService _reportApi;
  final DatabaseService _databaseService;
  final FeedProvider _feedProvider;
  final DiaryProvider _diaryProvider;
  final SettingsService _settingsService;

  ReportRepository({
    ReportApiService? reportApi,
    DatabaseService? databaseService,
    FeedProvider? feedProvider,
    DiaryProvider? diaryProvider,
    SettingsService? settingsService,
  })  : _reportApi = reportApi ?? ReportApiService(),
        _databaseService = databaseService ?? DatabaseService(),
        _feedProvider = feedProvider ?? FeedProvider(),
        _diaryProvider = diaryProvider ?? DiaryProvider(),
        _settingsService = settingsService ?? SettingsService();

  /// Generate a new AI report
  ///
  /// Currently uses mock data from report_template_mock.md.
  /// TODO: Replace with actual AI API call when ready.
  Future<Report> generateReport({
    required DateTime startDate,
    required DateTime endDate,
    required UserIdentity userIdentity,
  }) async {
    // FeedProvider와 DiaryProvider에서 날짜 범위의 데이터 가져오기
    final feedData = _feedProvider.getReportData(
      startDate: startDate,
      endDate: endDate,
    );
    final diaryData = _diaryProvider.getReportData(
      startDate: startDate,
      endDate: endDate,
    );

    // SettingsService에서 UserProfile 가져오기
    final userProfile = _settingsService.userProfile;

    debugPrint('[ReportRepository] Feed data count: ${feedData.length}');
    debugPrint('[ReportRepository] Diary data count: ${diaryData.length}');
    debugPrint('[ReportRepository] User profile: ${userProfile.name}, Age: ${userProfile.age}, Type: ${userProfile.diabetesType}');

    try {
      // 실제 API 호출
      final reportContent = await _reportApi.generateReport(
        userIdentity: userIdentity,
        userProfile: userProfile,
        startDate: startDate,
        endDate: endDate,
        feedData: feedData,
        diaryData: diaryData,
      );
      debugPrint('[ReportRepository] Report generated via API');

      // API 호출 성공 시에만 DB에 저장
      final report = Report(
        startDate: startDate,
        endDate: endDate,
        content: reportContent,
      );
      await _databaseService.insertReport(report);
      debugPrint('[ReportRepository] Report saved to DB');

      return report;
    } catch (e) {
      debugPrint('[ReportRepository] API call failed: $e');
      debugPrint('[ReportRepository] Falling back to mock report (not saved to DB)');

      // API 실패 시 Mock으로 폴백 (DB에 저장하지 않음)
      String mockContent;
      try {
        mockContent = await _loadMockReport(startDate, endDate);
        debugPrint('[ReportRepository] Using mock report from file');
      } catch (mockError) {
        debugPrint('[ReportRepository] Mock file load failed: $mockError');
        mockContent = _getSimpleMockReport(startDate, endDate);
        debugPrint('[ReportRepository] Using simple mock report');
      }

      // Mock 리포트는 DB에 저장하지 않고 반환만
      return Report(
        startDate: startDate,
        endDate: endDate,
        content: mockContent,
      );
    }
  }

  /// Load mock report from asset file
  Future<String> _loadMockReport(DateTime startDate, DateTime endDate) async {
    final mockContent = await rootBundle.loadString(
      'lib/features/report/report_template_mock.md',
    );

    // Replace $periodString with actual date range
    final periodString =
        '${startDate.month}월 ${startDate.day}일 - ${endDate.month}월 ${endDate.day}일';
    return mockContent.replaceAll('\$periodString', periodString);
  }

  /// Fallback simple mock report
  String _getSimpleMockReport(DateTime startDate, DateTime endDate) {
    final periodString =
        '${startDate.month}월 ${startDate.day}일 - ${endDate.month}월 ${endDate.day}일';

    return '''
# 혈당 관리 리포트
**기간: $periodString**

## 📋 Mock 리포트

이 리포트는 Mock 데이터입니다.
실제 API 연동 후 혈당 데이터를 기반으로 한 AI 분석 결과가 표시됩니다.

### 구현 예정 기능
- 혈당 주요 지표 분석
- 지난주 대비 개선 사항
- 생활습관 분석 (수면, 운동, 식습관)
- 개선 가이드 제공

&nbsp;

*이 리포트는 정상 혈당 회복을 위한 AI 분석 자료이며, 전문의의 진료를 대체하지 않습니다. 구체적인 치료 계획은 담당 의사와 상담하시기 바랍니다.*
''';
  }

  /// Get the latest report from database
  ///
  /// Returns the most recently created report, or null if no reports exist.
  Future<Report?> getLatestReport() async {
    return await _databaseService.getLatestReport();
  }

  /// Get all reports from database (sorted by creation date, newest first)
  Future<List<Report>> getAllReports() async {
    return await _databaseService.getAllReports();
  }

  /// Get a specific report by ID
  Future<Report?> getReportById(int id) async {
    return await _databaseService.getReportById(id);
  }

  /// Delete a report from database
  Future<void> deleteReport(int id) async {
    await _databaseService.deleteReport(id);
    debugPrint('[ReportRepository] Report deleted: $id');
  }

  /// Clean up resources
  void dispose() {
    _reportApi.dispose();
  }
}
