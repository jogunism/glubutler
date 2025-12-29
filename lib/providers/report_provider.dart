import 'package:flutter/foundation.dart';

import 'package:glu_butler/models/report.dart';
import 'package:glu_butler/models/user_identity.dart';
import 'package:glu_butler/repositories/report_repository.dart';
import 'package:glu_butler/services/report_api_service.dart';

/// Provider for report generation and management
///
/// Manages report state and delegates data operations to ReportRepository.
class ReportProvider extends ChangeNotifier {
  final ReportRepository _reportRepository = ReportRepository();

  Report? _latestReport;
  Report? get latestReport => _latestReport;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

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
