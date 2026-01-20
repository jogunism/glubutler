import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:glu_butler/l10n/app_localizations.dart';
import 'package:glu_butler/core/theme/app_theme.dart';
import 'package:glu_butler/core/theme/app_colors.dart';
import 'package:glu_butler/core/widgets/large_title_scroll_view.dart';
import 'package:glu_butler/core/widgets/settings_icon_button.dart';
import 'package:glu_butler/core/widgets/water_drop_loading.dart';
import 'package:glu_butler/core/widgets/modals/report_guide_modal.dart';
import 'package:glu_butler/core/widgets/modals/date_range_picker_modal.dart';
import 'package:glu_butler/core/widgets/top_banner.dart';
import 'package:glu_butler/features/report/past_reports_screen.dart';
import 'package:glu_butler/providers/report_provider.dart';
import 'package:glu_butler/services/settings_service.dart';
import 'package:glu_butler/services/report_api_service.dart';
import 'package:glu_butler/widgets/common/input_dialog.dart';

/// 리포트 화면
///
/// 혈당 데이터의 통계 및 분석 리포트를 표시하는 화면입니다.
/// [LargeTitleScrollView]를 사용하여 iOS 스타일 네비게이션을 구현합니다.
///
/// ## 주요 기능
/// - 일간/주간 혈당 통계
/// - 평균 혈당, 변동성 분석
/// - AI 인사이트 (Pro 기능)
/// - 혈당 점수 표시
/// - Pull-to-refresh로 데이터 새로고침
///
/// ## 라우팅
/// - `/report` - 탭바 인덱스 2
///
/// ## Pro 기능
/// - 고급 분석 및 리포트
/// - AI 기반 인사이트
/// - 데이터 내보내기
///
/// ## 관련 파일
/// - [LargeTitleScrollView] - iOS 스타일 스크롤뷰
/// - [MainShell] - 탭바 네비게이션
/// - [SettingsService] - Pro 구독 상태 확인
class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key, this.onScrollDirectionChanged});

  final void Function(bool scrollingDown)? onScrollDirectionChanged;

  static final GlobalKey<_ReportScreenState> globalKey =
      GlobalKey<_ReportScreenState>();

  static void triggerReportGeneration() {
    globalKey.currentState?.generateReport();
  }

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  bool _showInfoIcon = false;

  @override
  void initState() {
    super.initState();
    // Provider에서 최신 리포트 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReportProvider>().loadLatestReport();
      _checkInfoIconVisibility();
    });
  }

  Future<void> _checkInfoIconVisibility() async {
    final prefs = await SharedPreferences.getInstance();
    final hideGuide = prefs.getBool('hide_report_guide') ?? false;
    if (mounted) {
      setState(() {
        _showInfoIcon = hideGuide;
      });
    }
  }

  Future<void> _showInfoModal() async {
    await ReportGuideModal.show(context, infoMode: true);
  }

  Future<void> _deleteAllReports() async {
    if (!mounted) return;

    // 삭제 확인 다이얼로그
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        content: const Text('모두삭제'),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    debugPrint('[ReportScreen] Hard deleting all reports from DB and iCloud...');

    final reportProvider = context.read<ReportProvider>();

    // DB와 iCloud에서 완전히 삭제 (hard delete)
    final deletedCount = await reportProvider.deleteAllReports();

    debugPrint('[ReportScreen] Successfully hard deleted $deletedCount reports from DB and iCloud');
  }

  Widget _buildTitleTrailingButtons() {
    final isDevMode = dotenv.env['APP_ENV'] == 'development';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Development mode: 삭제 버튼
        if (isDevMode)
          CupertinoButton(
            padding: const EdgeInsets.only(
              bottom: 10,
              left: 0,
              right: 8,
            ),
            minimumSize: Size.zero,
            onPressed: _deleteAllReports,
            child: const Icon(
              CupertinoIcons.trash,
              size: 22,
              color: Colors.red,
            ),
          ),
        // 정보 버튼
        CupertinoButton(
          padding: EdgeInsets.only(
            bottom: 10,
            left: isDevMode ? 0 : 44,
            right: 0,
          ),
          minimumSize: Size.zero,
          onPressed: _showInfoModal,
          child: const Icon(
            CupertinoIcons.info_circle,
            size: 24,
            color: AppTheme.primaryColor,
          ),
        ),
      ],
    );
  }

  Future<void> generateReport() async {
    final reportProvider = context.read<ReportProvider>();
    final settingsService = context.read<SettingsService>();
    final l10n = AppLocalizations.of(context)!;

    // iCloud 연동 확인
    if (!settingsService.iCloudSyncEnabled) {
      if (!mounted) return;
      await showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: Text(l10n.reportRequiresICloud),
          content: Text(l10n.reportRequiresICloudMessage),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.confirm),
            ),
          ],
        ),
      );
      return;
    }

    // 안내 모달 표시
    if (!mounted) return;
    final confirmed = await ReportGuideModal.show(context);
    if (!confirmed) return;

    // 안내 모달 닫힌 후 info 아이콘 상태 업데이트
    await _checkInfoIconVisibility();

    // 날짜 범위 선택 모달 표시
    if (!mounted) return;
    final dateRange = await DateRangePickerModal.show(context);
    if (dateRange == null) return;

    final startDate = dateRange[0];
    final endDate = dateRange[1];

    // SettingsService에서 UserIdentity 가져오기 (async gap 전에 미리 가져옴)
    final userIdentity = settingsService.userIdentity;

    // Provider를 통해 리포트 생성
    // FeedProvider와 DiaryProvider는 ReportRepository에서 자동으로 가져옴
    final success = await reportProvider.generateReport(
      startDate: startDate,
      endDate: endDate,
      userIdentity: userIdentity,
    );

    if (!mounted) return;

    // TopBanner로 성공/실패 알림 표시
    TopBanner.show(
      context,
      message: success
          ? l10n.reportCreationSuccess
          : _getErrorMessage(reportProvider, l10n),
      isSuccess: success,
    );
  }

  /// 에러 코드를 보고 국제화된 에러 메시지를 반환
  String _getErrorMessage(ReportProvider provider, AppLocalizations l10n) {
    final errorCode = provider.errorCode;
    final serverMessage = provider.serverMessage;

    if (errorCode == null) {
      return l10n.apiErrorUnknown;
    }

    switch (errorCode) {
      case ApiErrorCode.network:
        return l10n.apiErrorNetwork;
      case ApiErrorCode.connectionTimeout:
        return l10n.apiErrorConnectionTimeout;
      case ApiErrorCode.receiveTimeout:
        return l10n.apiErrorReceiveTimeout;
      case ApiErrorCode.rateLimit:
        return l10n.apiErrorRateLimit;
      case ApiErrorCode.server:
        return l10n.apiErrorServer;
      case ApiErrorCode.networkConnection:
        return l10n.apiErrorNetworkConnection;
      case ApiErrorCode.unknown:
        return l10n.apiErrorUnknown;
      case ApiErrorCode.cancelled:
        return l10n.apiErrorCancelled;
      case ApiErrorCode.reportFailed:
        return l10n.apiErrorReportFailed(serverMessage ?? 'Unknown error');
    }
  }

  void _viewPastReports() {
    Navigator.of(
      context,
    ).push(CupertinoPageRoute(builder: (context) => const PastReportsScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Consumer<ReportProvider>(
      builder: (context, reportProvider, child) {
        final currentReport = reportProvider.currentReport;
        final reportContent = currentReport?.content;
        final isLoading = reportProvider.isLoading;
        final uploadProgress = reportProvider.uploadProgress;

        return Stack(
          children: [
            LargeTitleScrollView(
              title: l10n.report,
              titleTrailing: _showInfoIcon
                  ? _buildTitleTrailingButtons()
                  : null,
              trailing: const SettingsIconButton(),
              // 레포트가 없을 때는 스크롤로 탭바 숨김 비활성화
              onScrollDirectionChanged: reportContent != null
                  ? widget.onScrollDirectionChanged
                  : null,
              slivers: [
                if (reportContent == null)
                  // 레포트 없을 때: 빈 화면 + 생성 버튼
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 80),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              CupertinoIcons.doc_text_fill,
                              size: 80,
                              color: AppTheme.primaryColor,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              l10n.noReportTitle,
                              style: theme.textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l10n.noReportYet,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: context.colors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 32),
                            // 레포트 생성 버튼
                            CupertinoButton(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 12,
                              ),
                              color: AppTheme.primaryColor,
                              borderRadius: BorderRadius.circular(12),
                              onPressed: generateReport,
                              child: Text(
                                l10n.generateReport,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  // 레포트 있을 때: 기간 + 지난 리포트 버튼 + 내용 + Export 버튼
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // 기간 + 지난 리포트 보기 버튼
                        _buildReportHeader(l10n, isLoading),
                        const SizedBox(height: 16),
                        // 레포트 내용 (마크다운)
                        _buildReportContent(theme, reportContent),
                        const SizedBox(height: 16),
                        // Export 버튼
                        _buildExportButton(l10n),
                      ]),
                    ),
                  ),
              ],
            ),
            // 로딩 오버레이
            if (isLoading)
              WaterDropLoadingOverlay(
                progress: uploadProgress,
                message: l10n.generatingReport,
              ),
          ],
        );
      },
    );
  }

  Widget _buildReportHeader(AppLocalizations l10n, bool isLoading) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 신규 리포트 생성 버튼
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            minSize: 0,
            color: AppTheme.primaryColor,
            borderRadius: BorderRadius.circular(8),
            onPressed: isLoading ? null : generateReport,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isLoading)
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CupertinoActivityIndicator(radius: 7),
                  )
                else
                  const Icon(
                    CupertinoIcons.add_circled_solid,
                    size: 16,
                    color: Colors.white,
                  ),
                const SizedBox(width: 6),
                Text(
                  l10n.newReport,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          // 지난 리포트 보기 버튼
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            minSize: 0,
            onPressed: _viewPastReports,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.viewPastReports,
                  style: const TextStyle(
                    color: AppTheme.primaryColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  CupertinoIcons.chevron_right,
                  size: 14,
                  color: AppTheme.primaryColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportContent(ThemeData theme, String content) {
    // 리포트 영역은 항상 라이트 모드 색상 사용
    const backgroundColor = Colors.white;
    const textColor = Colors.black87;
    const borderColor = Color(0xFFCCCCCC);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Container(
        margin: const EdgeInsets.all(3),
        padding: const EdgeInsets.all(3),
        child: CustomPaint(
          painter: _DashedBorderPainter(
            color: borderColor,
            strokeWidth: 1,
            dashWidth: 4,
            dashSpace: 3,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: MarkdownBody(
              data: content,
              softLineBreak: true,
              styleSheet: MarkdownStyleSheet(
                h1: const TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 21,
                ),
                h2: const TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 19,
                ),
                h3: const TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
                p: const TextStyle(color: textColor, height: 1.6, fontSize: 14),
                listBullet: const TextStyle(
                  color: textColor,
                  height: 1.6,
                  fontSize: 14,
                ),
                strong: const TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                em: const TextStyle(
                  color: textColor,
                  fontStyle: FontStyle.italic,
                  fontSize: 14,
                ),
                a: const TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.none,
                  fontSize: 14,
                ),
                tableHead: const TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                tableBody: const TextStyle(color: textColor, fontSize: 14),
                blockSpacing: 11,
                listIndent: 22,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExportButton(AppLocalizations l10n) {
    const backgroundColor = Colors.white;
    const borderColor = Color(0xFFCCCCCC);

    return GestureDetector(
      onTap: _showEmailInputDialog,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Container(
          margin: const EdgeInsets.all(3),
          padding: const EdgeInsets.all(3),
          child: CustomPaint(
            painter: _DashedBorderPainter(
              color: borderColor,
              strokeWidth: 1,
              dashWidth: 4,
              dashSpace: 3,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    CupertinoIcons.mail,
                    size: 20,
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l10n.exportReport,
                    style: const TextStyle(
                      color: AppTheme.primaryColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showEmailInputDialog() async {
    final l10n = AppLocalizations.of(context)!;
    bool isButtonEnabled = false;
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

    final email = await showDialog<String>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.85),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return InputDialog(
            title: l10n.exportReportTitle,
            message: l10n.exportReportMessage,
            placeholder: 'your.id@email.com',
            buttonTitle: l10n.send,
            isButtonEnabled: isButtonEnabled,
            onChanged: (value) {
              final trimmedValue = value.trim();
              final isValid = trimmedValue.isNotEmpty && emailRegex.hasMatch(trimmedValue);

              if (isValid != isButtonEnabled) {
                setState(() {
                  isButtonEnabled = isValid;
                });
              }
            },
            validator: (input) {
              if (input.isEmpty) {
                return '이메일을 입력해 주세요';
              }

              if (!emailRegex.hasMatch(input)) {
                return '올바른 이메일 형식이 아닙니다';
              }

              return null; // 검증 성공
            },
          );
        },
      ),
    );

    if (email == null || email.isEmpty || !mounted) return;

    final reportProvider = context.read<ReportProvider>();
    final settingsService = context.read<SettingsService>();

    // 현재 리포트 내용 가져오기
    final reportContent = reportProvider.currentReport?.content;
    if (reportContent == null || reportContent.isEmpty) {
      if (!mounted) return;
      TopBanner.show(
        context,
        message: '전송할 리포트가 없습니다',
        isSuccess: false,
      );
      return;
    }

    // 현재 언어 가져오기
    final lang = settingsService.language;

    // 사용자 식별 정보 가져오기
    final userIdentity = settingsService.userIdentity;

    // /export API 호출
    try {
      debugPrint('[ReportScreen] Exporting report to email: $email, lang: $lang');

      final apiService = ReportApiService();
      final success = await apiService.exportReport(
        userIdentity: userIdentity,
        email: email,
        lang: lang,
        report: reportContent,
      );

      if (!mounted) return;

      TopBanner.show(
        context,
        message: success ? l10n.exportSuccess : '리포트 전송에 실패했습니다',
        isSuccess: success,
      );
    } on ReportApiException catch (e) {
      debugPrint('[ReportScreen] Export failed: ${e.errorCode}');

      if (!mounted) return;

      TopBanner.show(
        context,
        message: _getErrorMessage(reportProvider, l10n),
        isSuccess: false,
      );
    } catch (e) {
      debugPrint('[ReportScreen] Unexpected error during export: $e');

      if (!mounted) return;

      TopBanner.show(
        context,
        message: '리포트 전송 중 오류가 발생했습니다',
        isSuccess: false,
      );
    }
  }
}

/// 점선 테두리를 그리는 CustomPainter
class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashSpace;

  _DashedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.dashWidth,
    required this.dashSpace,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path();

    // Top border
    double startX = 0;
    while (startX < size.width) {
      path.moveTo(startX, 0);
      path.lineTo(startX + dashWidth, 0);
      startX += dashWidth + dashSpace;
    }

    // Right border
    double startY = 0;
    while (startY < size.height) {
      path.moveTo(size.width, startY);
      path.lineTo(size.width, startY + dashWidth);
      startY += dashWidth + dashSpace;
    }

    // Bottom border
    startX = size.width;
    while (startX > 0) {
      path.moveTo(startX, size.height);
      path.lineTo(startX - dashWidth, size.height);
      startX -= dashWidth + dashSpace;
    }

    // Left border
    startY = size.height;
    while (startY > 0) {
      path.moveTo(0, startY);
      path.lineTo(0, startY - dashWidth);
      startY -= dashWidth + dashSpace;
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
