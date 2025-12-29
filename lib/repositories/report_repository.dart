import 'package:flutter/foundation.dart';

import 'package:glu_butler/models/report.dart';
import 'package:glu_butler/models/user_identity.dart';
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
  }) : _reportApi = reportApi ?? ReportApiService(),
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

    // SettingsService에서 UserProfile과 언어 설정 가져오기
    final userProfile = _settingsService.userProfile;
    final language = _settingsService.language;

    try {
      // 실제 API 호출
      final reportContent = await _reportApi.generateReport(
        userIdentity: userIdentity,
        userProfile: userProfile,
        language: language,
        startDate: startDate,
        endDate: endDate,
        feedData: feedData,
        diaryData: diaryData,
      );
      // API 호출 성공 시에만 DB에 저장
      final report = Report(
        startDate: startDate,
        endDate: endDate,
        content: reportContent,
      );
      await _databaseService.insertReport(report);

      return report;
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
