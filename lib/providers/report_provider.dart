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

  /// 리포트 생성 진행률 (0.0 ~ 1.0)
  double _uploadProgress = 0.0;
  double get uploadProgress => _uploadProgress;

  /// 타이머로 진행률을 증가시키기 위한 변수
  bool _isGenerating = false;

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
    _uploadProgress = 0.0;
    _isGenerating = true;
    notifyListeners();

    // 60% → 95%: 3-5초, 95% → 99%: 5-10초 (더 느리게)
    _startProgressTimer();

    try {
      // Generate report via repository (API call + DB save)
      await _reportRepository.generateReport(
        startDate: startDate,
        endDate: endDate,
        userIdentity: userIdentity,
        onProgress: (sent, total) {
          if (!_isGenerating) return;
          // 업로드 진행률은 60%까지만 표시
          _uploadProgress = (sent / total) * 0.6;
          notifyListeners();
        },
      );

      // 서버 응답 받음 - 타이머 중단하고 즉시 100%로 설정
      _isGenerating = false;
      _uploadProgress = 1.0;
      notifyListeners();

      // 0.5초 대기 (100% 애니메이션 완료 대기)
      await Future.delayed(const Duration(milliseconds: 500));

      // 로딩 오버레이 먼저 닫기 (toast가 보이도록)
      _isLoading = false;
      _uploadProgress = 0.0;
      notifyListeners();

      // Reload latest report to update UI
      try {
        _latestReport = await _reportRepository.getLatestReport();
        notifyListeners();
      } catch (e) {
        debugPrint('[ReportProvider] Error loading latest report: $e');
      }

      // Reset to viewing latest report
      _selectedReport = null;

      return true;
    } on ReportApiException catch (e) {
      _error = e.message;
      debugPrint('[ReportProvider] Report generation failed: $e');

      // 타이머 중단하고 실패 시에도 100%로 채운 후 0.5초 대기
      _isGenerating = false;
      _uploadProgress = 1.0;
      notifyListeners();
      await Future.delayed(const Duration(milliseconds: 500));

      // 로딩 오버레이 먼저 닫기 (toast가 보이도록)
      _isLoading = false;
      _uploadProgress = 0.0;
      notifyListeners();

      return false;
    } catch (e) {
      _error = 'Unexpected error: $e';
      debugPrint('[ReportProvider] Unexpected error during report generation: $e');

      // 타이머 중단하고 실패 시에도 100%로 채운 후 0.5초 대기
      _isGenerating = false;
      _uploadProgress = 1.0;
      notifyListeners();
      await Future.delayed(const Duration(milliseconds: 500));

      // 로딩 오버레이 먼저 닫기 (toast가 보이도록)
      _isLoading = false;
      _uploadProgress = 0.0;
      notifyListeners();

      return false;
    }
  }

  /// 60% 이후 진행률을 천천히 99%까지 증가시키는 타이머
  /// 60% → 95%: 3-5초 (빠르게)
  /// 95% → 99%: 5-10초 (느리게)
  void _startProgressTimer() {
    // 첫 번째 단계: 60% → 95% (3-5초)
    final phase1Duration = 3000 + (DateTime.now().millisecondsSinceEpoch % 2000); // 3-5초
    final phase1Start = 0.6;
    final phase1Target = 0.95;
    final phase1Increment = (phase1Target - phase1Start) / (phase1Duration / 100);

    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 100));
      if (!_isGenerating) return false; // 타이머 중단

      if (_uploadProgress < phase1Target) {
        _uploadProgress = (_uploadProgress + phase1Increment).clamp(0.0, phase1Target);
        notifyListeners();
        return true;
      }

      // 첫 번째 단계 완료, 두 번째 단계 시작
      _startPhase2Timer();
      return false;
    });
  }

  /// 95% → 99%로 천천히 증가 (5-10초)
  void _startPhase2Timer() {
    final phase2Duration = 5000 + (DateTime.now().millisecondsSinceEpoch % 5000); // 5-10초
    final phase2Start = 0.95;
    final phase2Target = 0.99;
    final phase2Increment = (phase2Target - phase2Start) / (phase2Duration / 100);

    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 100));
      if (!_isGenerating) return false; // 타이머 중단

      if (_uploadProgress < phase2Target) {
        _uploadProgress = (_uploadProgress + phase2Increment).clamp(0.0, phase2Target);
        notifyListeners();
        return true;
      }
      return false;
    });
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
