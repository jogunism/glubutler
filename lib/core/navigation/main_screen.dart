import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cupertino_native_plus/cupertino_native.dart';

import 'package:glu_butler/l10n/app_localizations.dart';
import 'package:glu_butler/core/theme/app_theme.dart';
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

  void switchToTab(int index) {
    if (index >= 0 && index < 4 && index != _currentIndex) {
      HapticFeedback.lightImpact();
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppTheme.iosBackground(context),
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          HomeScreen(),
          FeedScreen(),
          DiaryScreen(),
          ReportScreen(),
        ],
      ),
      bottomNavigationBar: SafeArea(
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
              customIcon: Icons.list_alt_outlined,
              activeCustomIcon: Icons.list_alt,
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
    );
  }
}
