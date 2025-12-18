import 'package:flutter/material.dart';

import 'package:glu_butler/l10n/app_localizations.dart';
import 'package:glu_butler/core/theme/app_theme.dart';
import 'package:glu_butler/core/widgets/large_title_scroll_view.dart';
import 'package:glu_butler/core/widgets/settings_icon_button.dart';
import 'package:glu_butler/core/widgets/screen_fab.dart';
import 'package:glu_butler/core/widgets/modals/record_input_modal.dart';

/// 피드 화면 (홈 탭)
///
/// 사용자의 혈당, 식사, 운동 기록을 시간순으로 표시하는 메인 피드 화면입니다.
/// [LargeTitleScrollView]를 사용하여 iOS 스타일 네비게이션을 구현합니다.
///
/// ## 주요 기능
/// - 타임라인 형식의 건강 기록 표시
/// - Pull-to-refresh로 데이터 새로고침
/// - 빈 상태 표시 (기록이 없을 때)
///
/// ## 라우팅
/// - `/feed` - 탭바 인덱스 0
///
/// ## TODO
/// - 실제 데이터 연동
/// - 기록 카드 UI 구현
/// - 날짜별 그룹핑
///
/// ## 관련 파일
/// - [LargeTitleScrollView] - iOS 스타일 스크롤뷰
/// - [MainShell] - 탭바 네비게이션
class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  Future<void> _onRefresh() async {
    // TODO: Implement data refresh
    await Future.delayed(const Duration(seconds: 1));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Stack(
      children: [
        LargeTitleScrollView(
          title: l10n.feed,
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
                        Icons.timeline,
                        size: 80,
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.noRecords,
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.startTracking,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        ScreenFab(
          onPressed: () => RecordInputModal.show(context),
        ),
      ],
    );
  }
}
