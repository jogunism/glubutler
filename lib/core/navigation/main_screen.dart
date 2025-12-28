import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:provider/provider.dart';

import 'package:glu_butler/l10n/app_localizations.dart';
import 'package:glu_butler/core/theme/app_theme.dart';
import 'package:glu_butler/core/widgets/screen_fab.dart';
import 'package:glu_butler/core/widgets/modals/record_input_modal.dart';
import 'package:glu_butler/core/widgets/modals/diary_input_modal.dart';
import 'package:glu_butler/features/home/home_screen.dart';
import 'package:glu_butler/features/feed/feed_screen.dart';
import 'package:glu_butler/features/diary/diary_screen.dart';
import 'package:glu_butler/features/report/report_screen.dart';
import 'package:glu_butler/services/settings_service.dart';

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
      final settings = context.read<SettingsService>();
      if (settings.hapticEnabled) {
        HapticFeedback.lightImpact();
      }
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
          _buildOffstageTab(
            3,
            ReportScreen(
              onScrollDirectionChanged: (scrollingDown) {
                setState(() {
                  _isTabBarVisible = !scrollingDown;
                });
              },
            ),
          ),

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

          // AdaptiveBottomNavigationBar를 Positioned로 배치
          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            left: 0,
            right: 0,
            bottom: _isTabBarVisible ? 0 : -100,
            child: IgnorePointer(
              ignoring: !_isTabBarVisible,
              child: _buildAdaptiveTabBar(l10n),
            ),
          ),

          // AI 배지를 리포트 탭 아이콘 위에 오버레이 (탭바보다 위에 렌더링)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            bottom: _isTabBarVisible ? 60 : -100,
            right: MediaQuery.of(context).size.width / 8,
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: _currentIndex == 3
                      ? Colors.transparent
                      : AppTheme.primaryColor,
                  border: _currentIndex == 3
                      ? Border.all(
                          color: AppTheme.primaryColor,
                          width: 1,
                        )
                      : null,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  'AI',
                  style: TextStyle(
                    color: _currentIndex == 3
                        ? AppTheme.primaryColor
                        : Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    height: 1.0,
                  ),
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
      child: TickerMode(enabled: _currentIndex == index, child: child),
    );
  }

  Widget _buildAdaptiveTabBar(AppLocalizations l10n) {
    final settings = context.watch<SettingsService>();

    void handleTap(int index) {
      if (index == _currentIndex) {
        // 이미 선택된 탭을 다시 탭하면 scroll to top
        final controller = PrimaryScrollController.of(context);
        if (controller.hasClients &&
            controller.positions.length == 1 &&
            controller.offset > 0) {
          if (settings.hapticEnabled) {
            HapticFeedback.lightImpact();
          }
          controller.animateTo(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      } else {
        switchToTab(index);
      }
    }

    // Platform별로 적절한 탭바 반환
    if (PlatformInfo.isIOS26OrHigher()) {
      // iOS 26+: 네이티브 UITabBar with Liquid Glass effect
      // UITabBar는 SF Symbol을 자동으로 filled 변형 처리
      return IOS26NativeTabBar(
        destinations: [
          AdaptiveNavigationDestination(
            icon: 'drop',
            selectedIcon: 'drop.fill',
            label: l10n.home,
          ),
          AdaptiveNavigationDestination(
            icon: 'rectangle.grid.1x2',
            selectedIcon: 'rectangle.grid.1x2.fill',
            label: l10n.feed,
          ),
          AdaptiveNavigationDestination(
            icon: 'book',
            selectedIcon: 'book.fill',
            label: l10n.diary,
          ),
          AdaptiveNavigationDestination(
            icon: 'doc.text',
            selectedIcon: 'doc.text.fill',
            label: l10n.report,
          ),
        ],
        selectedIndex: _currentIndex,
        onTap: handleTap,
        tint: AppTheme.primaryColor,
        minimizeBehavior: TabBarMinimizeBehavior.never,
      );
    } else if (PlatformInfo.isIOS) {
      // iOS <26: CupertinoTabBar
      return CupertinoTabBar(
        backgroundColor: CupertinoColors.systemBackground.resolveFrom(context),
        activeColor: AppTheme.primaryColor,
        inactiveColor: CupertinoColors.inactiveGray,
        currentIndex: _currentIndex,
        onTap: handleTap,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(CupertinoIcons.drop),
            activeIcon: const Icon(CupertinoIcons.drop_fill),
            label: l10n.home,
          ),
          BottomNavigationBarItem(
            icon: const Icon(CupertinoIcons.square_grid_2x2),
            activeIcon: const Icon(CupertinoIcons.square_grid_2x2_fill),
            label: l10n.feed,
          ),
          BottomNavigationBarItem(
            icon: const Icon(CupertinoIcons.book),
            activeIcon: const Icon(CupertinoIcons.book_fill),
            label: l10n.diary,
          ),
          BottomNavigationBarItem(
            icon: const Icon(CupertinoIcons.doc_text),
            activeIcon: const Icon(CupertinoIcons.doc_text_fill),
            label: l10n.report,
          ),
        ],
      );
    } else {
      // Android: NavigationBar
      return NavigationBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        selectedIndex: _currentIndex,
        onDestinationSelected: handleTap,
        destinations: [
          NavigationDestination(
            icon: const Icon(CupertinoIcons.drop),
            selectedIcon: const Icon(CupertinoIcons.drop_fill),
            label: l10n.home,
          ),
          NavigationDestination(
            icon: const Icon(CupertinoIcons.square_grid_2x2),
            selectedIcon: const Icon(CupertinoIcons.square_grid_2x2_fill),
            label: l10n.feed,
          ),
          NavigationDestination(
            icon: const Icon(CupertinoIcons.book),
            selectedIcon: const Icon(CupertinoIcons.book_fill),
            label: l10n.diary,
          ),
          NavigationDestination(
            icon: const Icon(CupertinoIcons.doc_text),
            selectedIcon: const Icon(CupertinoIcons.doc_text_fill),
            label: l10n.report,
          ),
        ],
      );
    }
  }
}
