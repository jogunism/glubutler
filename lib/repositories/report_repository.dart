import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:glu_butler/models/report.dart';
import 'package:glu_butler/models/user_identity.dart';
import 'package:glu_butler/providers/feed_provider.dart';
import 'package:glu_butler/providers/diary_provider.dart';
import 'package:glu_butler/services/database_service.dart';
import 'package:glu_butler/services/report_api_service.dart';
import 'package:glu_butler/services/settings_service.dart';
import 'package:glu_butler/services/cloudkit_service.dart';
import 'package:glu_butler/utils/report_parser.dart';

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
  }) : _reportApi = reportApi ?? ReportApiService(
         baseUrl: dotenv.env['BASE_URL'] ?? 'https://glubutler.app',
       ),
       _databaseService = databaseService ?? DatabaseService(),
       _feedProvider = feedProvider ?? FeedProvider(),
       _diaryProvider = diaryProvider ?? DiaryProvider(),
       _settingsService = settingsService ?? SettingsService();

  /// Generate a new AI report
  ///
  /// Currently uses mock data from report_template_mock.md.
  Future<Report> generateReport({
    required DateTime startDate,
    required DateTime endDate,
    required UserIdentity userIdentity,
    void Function(int sent, int total)? onProgress,
  }) async {
    // FeedProvider에서 간소화된 데이터 가져오기
    final simplifiedFeedData = _feedProvider.getSimplifiedReportData(
      startDate: startDate,
      endDate: endDate,
    );

    // DiaryProvider에서 간소화된 데이터 가져오기
    final simplifiedDiaryData = _diaryProvider.getSimplifiedReportData(
      startDate: startDate,
      endDate: endDate,
    );

    // 일기 이미지 파일 경로 추출
    final diaryEntries = _diaryProvider.getReportData(
      startDate: startDate,
      endDate: endDate,
    );
    final imagePaths = diaryEntries
        .expand((entry) => entry.files)
        .map((file) => file.filePath)
        .toList();

    // SettingsService에서 UserProfile, 언어, 목표 수치 설정 가져오기
    final userProfile = _settingsService.userProfile;
    final language = _settingsService.language;
    final glucoseRange = _settingsService.glucoseRange;

    debugPrint('[ReportRepository] Current language setting: $language');
    debugPrint('[ReportRepository] User profile: ${userProfile.toJson()}');
    debugPrint('[ReportRepository] Glucose range: ${glucoseRange.toJson()}');
    debugPrint('[ReportRepository] Simplified feed data count: ${simplifiedFeedData.length}');
    debugPrint('[ReportRepository] Simplified diary data count: ${simplifiedDiaryData.length}');
    debugPrint('[ReportRepository] Image paths count: ${imagePaths.length}');

    try {
      // 이전 가이드 요약 가져오기 (최대 10개)
      final previousGuideSummaries = await _databaseService.getAllGuideSummaries(limit: 10);
      final previousGuideSummariesJson = previousGuideSummaries
          .map((summary) => summary.toJson())
          .toList();

      // 실제 API 호출
      final reportContent = await _reportApi.generateReport(
        userIdentity: userIdentity,
        userProfile: userProfile,
        language: language,
        glucoseRange: glucoseRange,
        startDate: startDate,
        endDate: endDate,
        simplifiedFeedData: simplifiedFeedData,
        simplifiedDiaryData: simplifiedDiaryData,
        imagePaths: imagePaths,
        previousGuideSummaries: previousGuideSummariesJson,
        onProgress: onProgress,
      );

      // API 호출 성공 시에만 DB에 저장
      final report = Report(
        startDate: startDate,
        endDate: endDate,
        content: reportContent,
      );
      final reportId = await _databaseService.insertReport(report);
      final savedReport = report.copyWith(id: reportId);

      // iCloud에 업로드 (iCloud 동기화가 활성화된 경우)
      if (_settingsService.iCloudSyncEnabled) {
        try {
          await CloudKitService.uploadReport(savedReport);
          debugPrint('[ReportRepository] Report uploaded to iCloud');
        } catch (e) {
          debugPrint('[ReportRepository] Failed to upload report to iCloud: $e');
          // iCloud 업로드 실패해도 로컬 저장은 성공했으므로 계속 진행
        }
      }

      // 리포트에서 가이드 요약 추출 및 저장
      try {
        final reportDate = DateFormat('yyyy-MM-dd').format(endDate);
        final guideSummary = ReportParser.extractGuideSummary(reportContent, reportDate);

        if (guideSummary != null) {
          final summaryId = await _databaseService.insertGuideSummary(guideSummary);
          final savedSummary = guideSummary.copyWith(id: summaryId);
          debugPrint('[ReportRepository] Guide summary extracted and saved');

          // iCloud에 업로드
          if (_settingsService.iCloudSyncEnabled) {
            try {
              await CloudKitService.uploadReportGuideSummary(savedSummary);
              debugPrint('[ReportRepository] Guide summary uploaded to iCloud');
            } catch (e) {
              debugPrint('[ReportRepository] Failed to upload guide summary to iCloud: $e');
            }
          }
        } else {
          debugPrint('[ReportRepository] No guide summary found in report');
        }
      } catch (e) {
        debugPrint('[ReportRepository] Failed to extract/save guide summary: $e');
        // 가이드 요약 저장 실패해도 리포트는 반환
      }

      return savedReport;
    } catch (e) {
      debugPrint('[ReportRepository] API call failed: $e');
      rethrow;
    }
  }

  /// Get the latest report from database
  ///
  /// Returns the most recently created report, or null if no reports exist.
  Future<Report?> getLatestReport() async {
    return await _databaseService.getLatestReport();
  }

  /// Get all reports from database (sorted by creation date, newest first)
  /// This excludes soft-deleted reports (reports with empty content)
  Future<List<Report>> getAllReports() async {
    return await _databaseService.getAllReports();
  }

  /// Get all reports including soft-deleted ones (for date range validation)
  /// Returns all reports regardless of content being empty or not
  Future<List<Report>> getAllReportsIncludingDeleted() async {
    return await _databaseService.getAllReportsIncludingDeleted();
  }

  /// Get a specific report by ID
  Future<Report?> getReportById(int id) async {
    return await _databaseService.getReportById(id);
  }

  /// Delete a report from database
  Future<void> deleteReport(int id) async {
    await _databaseService.deleteReport(id);
    debugPrint('[ReportRepository] Report deleted: $id');

    // iCloud에서도 삭제 (iCloud 동기화가 활성화된 경우)
    if (_settingsService.iCloudSyncEnabled) {
      try {
        await CloudKitService.deleteReport(id);
        debugPrint('[ReportRepository] Report deleted from iCloud');
      } catch (e) {
        debugPrint('[ReportRepository] Failed to delete report from iCloud: $e');
        // iCloud 삭제 실패해도 로컬 삭제는 성공했으므로 무시
      }
    }
  }

  /// Delete all reports from database (개발용)
  ///
  /// ⚠️ Hard delete - DB에서 완전히 삭제하고 iCloud에서도 삭제
  Future<int> deleteAllReports() async {
    // 로컬 DB에서 hard delete
    final deletedCount = await _databaseService.deleteAllReports();
    debugPrint('[ReportRepository] All reports hard deleted from DB: $deletedCount');

    // iCloud에서도 모두 삭제 (iCloud 동기화가 활성화된 경우)
    if (_settingsService.iCloudSyncEnabled) {
      try {
        await CloudKitService.deleteAllReports();
        debugPrint('[ReportRepository] All reports deleted from iCloud');
      } catch (e) {
        debugPrint('[ReportRepository] Failed to delete all reports from iCloud: $e');
        // iCloud 삭제 실패해도 로컬 삭제는 성공했으므로 무시
      }
    }

    // 가이드 요약도 모두 삭제
    final deletedSummaries = await _databaseService.reportDao.deleteAllGuideSummaries();
    debugPrint('[ReportRepository] All guide summaries deleted: $deletedSummaries');

    return deletedCount;
  }

  /// Clean up resources
  void dispose() {
    _reportApi.dispose();
  }
}
