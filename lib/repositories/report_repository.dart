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
import 'package:glu_butler/services/firestore_service.dart';
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

    // 비교 기간별 데이터 조립 (홈탭 차트 기준: endDate 기준 상대 날짜)
    // (label, startDaysAgo, endDaysAgo)
    const comparisonPeriods = [
      ('this_week', 7, 1),
      ('last_week', 14, 8),
      ('3_weeks_ago', 21, 15),
      ('1_month_ago', 37, 31),
      ('2_months_ago', 67, 61),
      ('3_months_ago', 90, 84),
      ('6_months_ago', 180, 174),
    ];
    final previousData = <String, dynamic>{};
    for (final (label, startDaysAgo, endDaysAgo) in comparisonPeriods) {
      final periodStart = endDate.subtract(Duration(days: startDaysAgo));
      final periodEnd = endDate.subtract(Duration(days: endDaysAgo));
      final periodFeedData = _feedProvider.getSimplifiedReportData(
        startDate: periodStart,
        endDate: periodEnd,
      );
      if (periodFeedData.isNotEmpty) {
        previousData[label] = periodFeedData;
      }
    }

    try {
      // 이전 가이드 요약 가져오기 - reports 테이블에서 직접 조회
      final allReports = await _databaseService.getAllReports();
      final previousGuideSummariesJson = allReports
          .where((r) => r.improvements != null || r.needsImprovement != null)
          .take(10)
          .map((r) => {
            'reportDate': DateFormat('yyyy-MM-dd').format(r.endDate),
            'improvements': r.improvements ?? '',
            'needsImprovement': r.needsImprovement ?? '',
          })
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
        previousData: previousData.isNotEmpty ? previousData : null,
        onProgress: onProgress,
      );

      // 리포트에서 가이드 요약 추출
      final guideSummary = ReportParser.extractGuideSummary(reportContent);

      // API 호출 성공 시에만 DB에 저장 (improvements/needsImprovement 포함)
      final report = Report(
        startDate: startDate,
        endDate: endDate,
        content: reportContent,
        improvements: guideSummary?.improvements,
        needsImprovement: guideSummary?.needsImprovement,
      );
      final reportId = await _databaseService.insertReport(report);
      final savedReport = report.copyWith(id: reportId);

      // 플랫폼별 클라우드 업로드
      // iOS: iCloud (CloudKit)
      if (userIdentity.cloudKitId != null && _settingsService.iCloudSyncEnabled) {
        try {
          await CloudKitService.uploadReport(savedReport);
          debugPrint('[ReportRepository] Report uploaded to iCloud');
        } catch (e) {
          debugPrint('[ReportRepository] Failed to upload report to iCloud: $e');
          // iCloud 업로드 실패해도 로컬 저장은 성공했으므로 계속 진행
        }
      }

      // Android: Firestore
      if (userIdentity.googleId != null) {
        try {
          await FirestoreService.uploadReport(userIdentity.googleId!, savedReport);
          debugPrint('[ReportRepository] Report uploaded to Firestore');
        } catch (e) {
          debugPrint('[ReportRepository] Failed to upload report to Firestore: $e');
          // Firestore 업로드 실패해도 로컬 저장은 성공했으므로 계속 진행
        }
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

  /// Delete a report from database (soft delete)
  Future<void> deleteReport(int id) async {
    await _databaseService.deleteReport(id);
    debugPrint('[ReportRepository] Report deleted: $id');

    final userIdentity = _settingsService.userIdentity;

    // iCloud에서도 삭제 (iOS, iCloud 동기화가 활성화된 경우)
    if (userIdentity.cloudKitId != null && _settingsService.iCloudSyncEnabled) {
      try {
        await CloudKitService.deleteReport(id);
        debugPrint('[ReportRepository] Report deleted from iCloud');
      } catch (e) {
        debugPrint('[ReportRepository] Failed to delete report from iCloud: $e');
        // iCloud 삭제 실패해도 로컬 삭제는 성공했으므로 무시
      }
    }

    // Firestore에서도 삭제 (Android)
    if (userIdentity.googleId != null) {
      try {
        await FirestoreService.deleteReport(userIdentity.googleId!, id);
        debugPrint('[ReportRepository] Report deleted from Firestore');
      } catch (e) {
        debugPrint('[ReportRepository] Failed to delete report from Firestore: $e');
        // Firestore 삭제 실패해도 로컬 삭제는 성공했으므로 무시
      }
    }
  }

  /// Hard delete a report from database (개발용)
  ///
  /// 로컬 DB에서만 레코드를 완전히 삭제합니다.
  /// ⚠️ 개발/테스트 용도로만 사용 (iCloud, DynamoDB는 수동 관리)
  Future<void> hardDeleteReport(int id) async {
    await _databaseService.hardDeleteReport(id);
    debugPrint('[ReportRepository] Report hard deleted from local DB: $id');
  }

  /// Delete all reports from database (개발용)
  ///
  /// ⚠️ Hard delete - DB에서 완전히 삭제하고 클라우드에서도 삭제
  Future<int> deleteAllReports() async {
    // 로컬 DB에서 hard delete
    final deletedCount = await _databaseService.deleteAllReports();
    debugPrint('[ReportRepository] All reports hard deleted from DB: $deletedCount');

    final userIdentity = _settingsService.userIdentity;

    // iCloud에서도 모두 삭제 (iOS, iCloud 동기화가 활성화된 경우)
    if (userIdentity.cloudKitId != null && _settingsService.iCloudSyncEnabled) {
      try {
        await CloudKitService.deleteAllReports();
        debugPrint('[ReportRepository] All reports deleted from iCloud');
      } catch (e) {
        debugPrint('[ReportRepository] Failed to delete all reports from iCloud: $e');
        // iCloud 삭제 실패해도 로컬 삭제는 성공했으므로 무시
      }
    }

    // Firestore에서도 모두 삭제 (Android)
    if (userIdentity.googleId != null) {
      try {
        await FirestoreService.deleteAllReports(userIdentity.googleId!);
        debugPrint('[ReportRepository] All reports deleted from Firestore');
      } catch (e) {
        debugPrint('[ReportRepository] Failed to delete all reports from Firestore: $e');
        // Firestore 삭제 실패해도 로컬 삭제는 성공했으므로 무시
      }
    }

    return deletedCount;
  }

  /// Clean up resources
  void dispose() {
    _reportApi.dispose();
  }
}
