import 'package:flutter/foundation.dart';

import 'package:glu_butler/models/report.dart';
import 'package:glu_butler/models/user_identity.dart';
import 'package:glu_butler/repositories/report_repository.dart';
import 'package:glu_butler/services/report_api_service.dart';
import 'package:glu_butler/providers/feed_provider.dart';
import 'package:glu_butler/providers/diary_provider.dart';
import 'package:glu_butler/services/settings_service.dart';

/// Provider for report generation and management
///
/// Manages report state and delegates data operations to ReportRepository.
class ReportProvider extends ChangeNotifier {
  late final ReportRepository _reportRepository;

  Report? _latestReport;
  Report? get latestReport => _latestReport;

  Report? _selectedReport;
  Report? get selectedReport => _selectedReport;

  /// 현재 표시 중인 리포트 (선택된 리포트가 있으면 그것을, 없으면 최신 리포트)
  Report? get currentReport => _selectedReport ?? _latestReport;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  /// Constructor that accepts dependencies
  ReportProvider({
    required FeedProvider feedProvider,
    required DiaryProvider diaryProvider,
    required SettingsService settingsService,
  }) {
    _reportRepository = ReportRepository(
      feedProvider: feedProvider,
      diaryProvider: diaryProvider,
      settingsService: settingsService,
    );
  }

  /// Initialize provider by loading the latest report
  Future<void> initialize() async {
    await loadLatestReport();
  }

  /// Load the latest report from database
  Future<void> loadLatestReport() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _latestReport = await _reportRepository.getLatestReport();
    } catch (e) {
      _error = 'Failed to load report: $e';
      debugPrint('[ReportProvider] Error loading latest report: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Generate a new AI report
  ///
  /// Calls API to generate report, saves to DB, then reloads latest report.
  /// Returns true if successful, false otherwise.
  Future<bool> generateReport({
    required DateTime startDate,
    required DateTime endDate,
    required UserIdentity userIdentity,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Generate report via repository (API call + DB save)
      await _reportRepository.generateReport(
        startDate: startDate,
        endDate: endDate,
        userIdentity: userIdentity,
      );

      // Reload latest report to update UI
      await loadLatestReport();

      // Reset to viewing latest report
      _selectedReport = null;

      return true;
    } on ReportApiException catch (e) {
      _error = e.message;
      debugPrint('[ReportProvider] Report generation failed: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Unexpected error: $e';
      debugPrint('[ReportProvider] Unexpected error during report generation: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Get all past reports
  Future<List<Report>> getAllReports() async {
    try {
      return await _reportRepository.getAllReports();
    } catch (e) {
      debugPrint('[ReportProvider] Error fetching all reports: $e');
      return [];
    }
  }

  /// Delete a report
  Future<bool> deleteReport(int id) async {
    try {
      await _reportRepository.deleteReport(id);

      // If deleted report was the selected one, reset to latest
      if (_selectedReport?.id == id) {
        _selectedReport = null;
      }

      // If deleted report was the latest, reload
      if (_latestReport?.id == id) {
        await loadLatestReport();
      }

      return true;
    } catch (e) {
      _error = 'Failed to delete report: $e';
      debugPrint('[ReportProvider] Error deleting report: $e');
      notifyListeners();
      return false;
    }
  }

  /// Select a specific report to view
  void setSelectedReport(Report? report) {
    _selectedReport = report;
    notifyListeners();
  }

  /// Reset to viewing the latest report
  void selectLatestReport() {
    _selectedReport = null;
    notifyListeners();
  }

  /// Check if currently viewing the latest report
  bool get isViewingLatest => _selectedReport == null || _selectedReport?.id == _latestReport?.id;

  /// Clear error message
  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _reportRepository.dispose();
    super.dispose();
  }
}
