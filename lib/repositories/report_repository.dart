import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'package:glu_butler/models/report.dart';
import 'package:glu_butler/services/database_service.dart';
import 'package:glu_butler/services/report_api_service.dart';

/// Repository for report generation and management.
///
/// Handles the logic of generating AI reports via API
/// and reading/writing reports from/to local database.
class ReportRepository {
  final ReportApiService _reportApi;
  final DatabaseService _databaseService;

  ReportRepository({
    ReportApiService? reportApi,
    DatabaseService? databaseService,
  })  : _reportApi = reportApi ?? ReportApiService(),
        _databaseService = databaseService ?? DatabaseService();

  /// Generate a new AI report
  ///
  /// Currently uses mock data from report_template_mock.md.
  /// TODO: Replace with actual AI API call when ready.
  Future<Report> generateReport({
    required DateTime startDate,
    required DateTime endDate,
    required String userId,
    required Map<String, dynamic> glucoseData,
  }) async {
    String reportContent;

    try {
      // TODO: 실제 API 호출로 교체
      // final reportContent = await _reportApi.generateReport(...);

      // 현재는 mock 파일 사용
      reportContent = await _loadMockReport(startDate, endDate);
      debugPrint('[ReportRepository] Using mock report content');
    } catch (e) {
      debugPrint('[ReportRepository] Error loading mock report: $e');
      // Fallback to simple mock
      reportContent = _getSimpleMockReport(startDate, endDate);
    }

    // Create report model
    final report = Report(
      startDate: startDate,
      endDate: endDate,
      content: reportContent,
    );

    // Save to local database
    await _databaseService.insertReport(report);

    debugPrint('[ReportRepository] Report generated and saved to DB');
    return report;
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
