import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'package:glu_butler/l10n/app_localizations.dart';
import 'package:glu_butler/core/widgets/large_title_scroll_view.dart';

/// 지난 리포트 목록 화면
///
/// 이전에 생성된 혈당 리포트 목록을 보여주는 화면입니다.
class PastReportsScreen extends StatelessWidget {
  const PastReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return LargeTitleScrollView(
      title: l10n.viewPastReports,
      showBackButton: true,
      showLargeTitle: false,
      onRefresh: null,
      slivers: [
        // 빈 상태
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
        ),
      ],
    );
  }
}
