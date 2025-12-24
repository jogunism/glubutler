import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cupertino_native_plus/cupertino_native.dart';

import 'package:glu_butler/l10n/app_localizations.dart';
import 'package:glu_butler/core/theme/app_theme.dart';
import 'package:glu_butler/core/widgets/screen_fab.dart';
import 'package:glu_butler/core/widgets/modals/record_input_modal.dart';
import 'package:glu_butler/core/widgets/modals/diary_input_modal.dart';
import 'package:glu_butler/features/home/home_screen.dart';
import 'package:glu_butler/features/feed/feed_screen.dart';
import 'package:glu_butler/features/diary/diary_screen.dart';
import 'package:glu_butler/features/report/report_screen.dart';

/// 메인 화면 - iOS 상태바 탭 scroll-to-top 지원
///
/// 핵심: 현재 활성 탭만 PrimaryScrollController를 가짐
/// - 비활성 탭은 Offstage로 숨기고 PrimaryScrollController 없이 렌더링
/// - 활성 탭만 PrimaryScrollController 제공
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  static final GlobalKey<MainScreenState> globalKey =
      GlobalKey<MainScreenState>();

  static void switchToTab(int index) {
    globalKey.currentState?.switchToTab(index);
  }

  @override
  State<MainScreen> createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  bool _isTabBarVisible = true;

  void switchToTab(int index) {
    if (index >= 0 && index < 4 && index != _currentIndex) {
      HapticFeedback.lightImpact();
      setState(() {
        _currentIndex = index;
      });
    }
  }

  void setTabBarVisibility(bool visible) {
    setState(() {
      _isTabBarVisible = visible;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // FAB should be visible on feed (1) and diary (2) tabs
    final showFab = _currentIndex == 1 || _currentIndex == 2;

    // 각 탭의 LargeTitleScrollView가 Scaffold를 내장하므로 여기서는 Material 사용
    return Material(
      color: AppTheme.iosBackground(context),
      child: Stack(
        children: [
          // 비활성 탭들 - Offstage로 숨김, 상태 유지
          _buildOffstageTab(0, const HomeScreen()),
          _buildOffstageTab(1, const FeedScreen()),
          _buildOffstageTab(2, DiaryScreen(key: DiaryScreen.globalKey)),
          _buildOffstageTab(3, const ReportScreen()),

          // Floating Action Button with animation
          ScreenFab(
            visible: showFab,
            onPressed: () async {
              // 모달을 열기 전에 탭바 숨김
              setTabBarVisibility(false);

              if (_currentIndex == 1) {
                await RecordInputModal.show(context);
              } else if (_currentIndex == 2) {
                final result = await DiaryInputModal.show(context);
                // 일기가 성공적으로 추가되면 DiaryScreen 새로고침
                if (result == true) {
                  DiaryScreen.globalKey.currentState?.loadEntries();
                }
              }

              // 모달이 닫히면 탭바 다시 보임
              setTabBarVisibility(true);
            },
          ),

          // CNTabBar를 Positioned로 배치
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Opacity(
              opacity: _isTabBarVisible ? 1.0 : 0.0,
              child: IgnorePointer(
                ignoring: !_isTabBarVisible,
                child: CNTabBar(
                  tint: AppTheme.primaryColor,
                  items: [
                    CNTabBarItem(
                      label: l10n.home,
                      customIcon: Icons.water_drop_outlined,
                      activeCustomIcon: Icons.water_drop,
                    ),
                    CNTabBarItem(
                      label: l10n.feed,
                      customIcon: Icons.view_agenda_outlined,
                      activeCustomIcon: Icons.view_agenda,
                    ),
                    CNTabBarItem(
                      label: l10n.diary,
                      customIcon: Icons.book_outlined,
                      activeCustomIcon: Icons.book,
                    ),
                    CNTabBarItem(
                      label: l10n.report,
                      customIcon: Icons.bar_chart_outlined,
                      activeCustomIcon: Icons.bar_chart,
                    ),
                  ],
                  currentIndex: _currentIndex,
                  onTap: (index) {
                    if (index == _currentIndex) {
                      // 이미 선택된 탭을 다시 탭하면 scroll to top
                      final controller = PrimaryScrollController.of(context);
                      if (controller.hasClients &&
                          controller.positions.length == 1 &&
                          controller.offset > 0) {
                        HapticFeedback.lightImpact();
                        controller.animateTo(
                          0,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                        );
                      }
                    } else {
                      switchToTab(index);
                    }
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOffstageTab(int index, Widget child) {
    return Offstage(
      offstage: _currentIndex != index,
      child: TickerMode(
        enabled: _currentIndex == index,
        child: child,
      ),
    );
  }
}
