import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';

import 'package:glu_butler/l10n/app_localizations.dart';
import 'package:glu_butler/core/theme/app_theme.dart';
import 'package:glu_butler/core/widgets/large_title_scroll_view.dart';
import 'package:glu_butler/core/widgets/settings_icon_button.dart';
import 'package:glu_butler/core/widgets/modals/report_guide_modal.dart';
import 'package:glu_butler/core/widgets/modals/date_range_picker_modal.dart';
import 'package:glu_butler/features/report/past_reports_screen.dart';
import 'package:glu_butler/providers/report_provider.dart';

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

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  @override
  void initState() {
    super.initState();
    // Provider에서 최신 리포트 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReportProvider>().loadLatestReport();
    });
  }

  Future<void> _generateReport() async {
    final reportProvider = context.read<ReportProvider>();

    // 안내 모달 표시
    final confirmed = await ReportGuideModal.show(context);
    if (!confirmed) return;

    // 날짜 범위 선택 모달 표시
    final dateRange = await DateRangePickerModal.show(context);
    if (dateRange == null) return;

    final startDate = dateRange[0];
    final endDate = dateRange[1];

    // TODO: 실제 사용자 ID와 혈당 데이터 수집
    // 현재는 임시 데이터 사용
    final userId = 'temp_user_id';
    final glucoseData = <String, dynamic>{
      'records': [],
      // 실제 구현 시 DB에서 해당 기간의 혈당 데이터를 가져와야 함
    };

    // Provider를 통해 리포트 생성
    final success = await reportProvider.generateReport(
      startDate: startDate,
      endDate: endDate,
      userId: userId,
      glucoseData: glucoseData,
    );

    if (!success && mounted) {
      // 에러 처리 (Provider의 error 메시지 표시)
      final error = reportProvider.error;
      if (error != null) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('리포트 생성 실패'),
            content: Text(error),
            actions: [
              CupertinoDialogAction(
                child: const Text('확인'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      }
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
        final reportContent = reportProvider.latestReport?.content;
        final isLoading = reportProvider.isLoading;

        return LargeTitleScrollView(
          title: l10n.report,
          trailing: const SettingsIconButton(),
          // 레포트가 없을 때는 스크롤로 탭바 숨김 비활성화
          onScrollDirectionChanged: reportContent != null ? widget.onScrollDirectionChanged : null,
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
                          Icons.leaderboard,
                          size: 80,
                          color: AppTheme.primaryColor,
                        ),
                        const SizedBox(height: 16),
                        Text(l10n.report, style: theme.textTheme.titleLarge),
                        const SizedBox(height: 8),
                        Text(
                          l10n.noReportYet,
                          style: theme.textTheme.bodyMedium,
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
                          onPressed: _generateReport,
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
              // 레포트 있을 때: 기간 + 지난 리포트 버튼 + 내용
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // 기간 + 지난 리포트 보기 버튼
                    _buildReportHeader(l10n, isLoading),
                    const SizedBox(height: 16),
                    // 레포트 내용 (마크다운)
                    _buildReportContent(theme, reportContent),
                  ]),
                ),
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
            onPressed: isLoading ? null : _generateReport,
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
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border.all(color: theme.dividerColor, width: 1),
      ),
      child: Container(
        margin: const EdgeInsets.all(3),
        padding: const EdgeInsets.all(3),
        child: CustomPaint(
          painter: _DashedBorderPainter(
            color: theme.dividerColor.withOpacity(0.4),
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
                h1: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 21,
                ),
                h2: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 19,
                ),
                h3: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
                p: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.6,
                  fontSize: 14,
                ),
                listBullet: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.6,
                  fontSize: 14,
                ),
                strong: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                em: theme.textTheme.bodyMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                  fontSize: 14,
                ),
                a: TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.none,
                  fontSize: 14,
                ),
                tableHead: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                tableBody: theme.textTheme.bodyMedium?.copyWith(fontSize: 14),
                blockSpacing: 11,
                listIndent: 22,
              ),
            ),
          ),
        ),
      ),
    );
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
