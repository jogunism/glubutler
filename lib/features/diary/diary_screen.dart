import 'package:flutter/material.dart';

import 'package:glu_butler/l10n/app_localizations.dart';
import 'package:glu_butler/core/theme/app_theme.dart';
import 'package:glu_butler/core/widgets/large_title_scroll_view.dart';
import 'package:glu_butler/core/widgets/settings_icon_button.dart';
import 'package:glu_butler/core/widgets/screen_fab.dart';
import 'package:glu_butler/core/widgets/modals/diary_input_modal.dart';

/// 일기 화면
///
/// 날짜별 건강 일기를 작성하고 조회하는 화면입니다.
/// [LargeTitleScrollView]를 사용하여 iOS 스타일 네비게이션을 구현합니다.
///
/// ## 주요 기능
/// - 날짜별 일기 목록 표시
/// - 일기 작성/수정/삭제
/// - Pull-to-refresh로 데이터 새로고침
/// - 빈 상태 표시 (기록이 없을 때)
///
/// ## 라우팅
/// - `/diary` - 탭바 인덱스 1
///
/// ## 관련 파일
/// - [LargeTitleScrollView] - iOS 스타일 스크롤뷰
/// - [MainShell] - 탭바 네비게이션
class DiaryScreen extends StatefulWidget {
  const DiaryScreen({super.key});

  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
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
          title: l10n.diary,
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
                        Icons.book_outlined,
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
          onPressed: () => DiaryInputModal.show(context),
        ),
      ],
    );
  }
}
