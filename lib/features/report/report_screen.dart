import 'package:flutter/material.dart';

import 'package:glu_butler/l10n/app_localizations.dart';
import 'package:glu_butler/core/theme/app_theme.dart';
import 'package:glu_butler/core/widgets/large_title_scroll_view.dart';
import 'package:glu_butler/core/widgets/settings_icon_button.dart';

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
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  Future<void> _onRefresh() async {
    // TODO: Implement data refresh
    await Future.delayed(const Duration(seconds: 1));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return LargeTitleScrollView(
      title: l10n.report,
      onRefresh: _onRefresh,
      trailing: const SettingsIconButton(),
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 80),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.bar_chart_outlined,
                    size: 80,
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.dailyReport,
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.noRecords,
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
