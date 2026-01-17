import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import 'package:glu_butler/l10n/app_localizations.dart';
import 'package:glu_butler/core/theme/app_theme.dart';
import 'package:glu_butler/core/theme/app_decorations.dart';
import 'package:glu_butler/core/widgets/large_title_scroll_view.dart';
import 'package:glu_butler/core/widgets/swipeable_card.dart';
import 'package:glu_butler/models/report.dart';
import 'package:glu_butler/providers/report_provider.dart';

/// 지난 리포트 목록 화면
///
/// 이전에 생성된 혈당 리포트 목록을 보여주는 화면입니다.
class PastReportsScreen extends StatefulWidget {
  const PastReportsScreen({super.key});

  @override
  State<PastReportsScreen> createState() => _PastReportsScreenState();
}

class _PastReportsScreenState extends State<PastReportsScreen> {
  List<Report> _reports = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() => _isLoading = true);
    final reportProvider = context.read<ReportProvider>();
    final reports = await reportProvider.getAllReports();
    setState(() {
      _reports = reports;
      _isLoading = false;
    });
  }

  Future<void> _deleteReport(Report report) async {
    if (!mounted || report.id == null) return;

    final l10n = AppLocalizations.of(context)!;

    // 삭제 확인 다이얼로그
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(l10n.deleteReport),
        content: Text(l10n.reportWillBeDeleted(
          report.getPeriodString(monthLabel: l10n.monthSuffix, dayLabel: l10n.daySuffix),
        )),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    // 취소를 누른 경우 열려있는 스와이프 카드 닫기
    if (confirmed != true) {
      SwipeableCardState.closeAnyOpenCard();
      return;
    }

    if (!mounted) return;

    final reportProvider = context.read<ReportProvider>();
    final success = await reportProvider.deleteReport(report.id!);
    if (success && mounted) {
      await _loadReports();
    }
  }

  void _viewReport(Report report) {
    // Set the selected report and navigate back to report screen
    context.read<ReportProvider>().setSelectedReport(report);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return LargeTitleScrollView(
      title: l10n.pastReports,
      showBackButton: true,
      showLargeTitle: true,
      onRefresh: _loadReports,
      slivers: [
        if (_isLoading)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: CupertinoActivityIndicator()),
          )
        else if (_reports.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.doc_text,
                    size: 80,
                    color: theme.colorScheme.secondary.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.noReportYet,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.secondary.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(0, 8, 0, 100),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final report = _reports[index];
                  return _ReportListItem(
                    report: report,
                    onTap: () => _viewReport(report),
                    onDelete: () => _deleteReport(report),
                  );
                },
                childCount: _reports.length,
              ),
            ),
          ),
      ],
    );
  }
}

/// 리포트 목록 아이템
class _ReportListItem extends StatelessWidget {
  final Report report;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ReportListItem({
    required this.report,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final baseDecoration = context.decorations.card;

    return Consumer<ReportProvider>(
      builder: (context, reportProvider, child) {
        final isSelected = reportProvider.currentReport?.id == report.id;

        return SwipeableCard(
          swipeable: true,
          useRemove: true,
          useEdit: false,
          onDelete: onDelete,
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: baseDecoration.copyWith(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // 아이콘 영역 (선택된 경우만 리포트 아이콘 표시)
                        SizedBox(
                          width: 32,
                          height: 32,
                          child: isSelected
                              ? Container(
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    CupertinoIcons.doc_text_fill,
                                    color: AppTheme.primaryColor,
                                    size: 16,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        // 기간 및 날짜
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                l10n.report,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.secondary.withValues(alpha: 0.7),
                                ),
                              ),
                              Text(
                                report.getPeriodString(monthLabel: l10n.monthSuffix, dayLabel: l10n.daySuffix),
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // 생성 날짜 (항상 표시)
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _formatCreatedAt(report.createdAt, l10n),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.secondary.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatCreatedAt(DateTime date, AppLocalizations l10n) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return l10n.today;
    } else if (diff.inDays == 1) {
      return l10n.yesterday;
    } else if (diff.inDays < 7) {
      return l10n.daysAgo(diff.inDays);
    } else {
      return '${date.year}.${date.month}.${date.day}';
    }
  }
}
