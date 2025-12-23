import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

  static final GlobalKey<MainScreenState> globalKey = GlobalKey<MainScreenState>();

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    // 각 탭의 LargeTitleScrollView가 Scaffold를 내장하므로 여기서는 Material 사용
    return Material(
      color: AppTheme.iosBackground(context),
      child: Stack(
        children: [
          // 비활성 탭들 - Offstage로 숨김, 상태 유지
          _buildOffstageTab(0, const HomeScreen()),
          _buildOffstageTab(1, const FeedScreen()),
          _buildOffstageTab(2, const DiaryScreen()),
          _buildOffstageTab(3, const ReportScreen()),

          // 플로팅 탭바 오버레이
          Positioned(
            left: 16,
            right: 16,
            bottom: bottomPadding + 8,
            child: _buildFloatingTabBar(context, l10n, isDark),
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

  Widget _buildFloatingTabBar(
    BuildContext context,
    AppLocalizations l10n,
    bool isDark,
  ) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            color: isDark
                ? Colors.black.withValues(alpha: 0.4)
                : Colors.white.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.15)
                  : Colors.black.withValues(alpha: 0.08),
              width: 0.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildTabItem(
                context: context,
                imagePath: 'assets/images/icon_mini.png',
                label: l10n.home,
                index: 0,
                isImage: true,
              ),
              _buildTabItem(
                context: context,
                icon: Icons.view_agenda_outlined,
                selectedIcon: Icons.view_agenda,
                label: l10n.feed,
                index: 1,
              ),
              _buildTabItem(
                context: context,
                icon: Icons.book_outlined,
                selectedIcon: Icons.book,
                label: l10n.diary,
                index: 2,
              ),
              _buildTabItem(
                context: context,
                icon: Icons.analytics_outlined,
                selectedIcon: Icons.analytics,
                label: l10n.report,
                index: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabItem({
    required BuildContext context,
    IconData? icon,
    IconData? selectedIcon,
    String? imagePath,
    required String label,
    required int index,
    bool isImage = false,
  }) {
    final isSelected = _currentIndex == index;
    final theme = Theme.of(context);
    final color = isSelected
        ? AppTheme.primaryColor
        : theme.colorScheme.onSurface.withValues(alpha: 0.6);

    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (isSelected) {
            // 이미 선택된 탭을 다시 탭하면 scroll to top
            // PrimaryScrollController를 통해 현재 활성 스크롤뷰에 접근
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
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isImage && imagePath != null)
                isSelected
                    ? Image.asset(
                        imagePath,
                        width: 24,
                        height: 24,
                      )
                    : ColorFiltered(
                        colorFilter: ColorFilter.mode(
                          theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          BlendMode.srcIn,
                        ),
                        child: Image.asset(
                          imagePath,
                          width: 24,
                          height: 24,
                        ),
                      )
              else
                Icon(
                  isSelected ? selectedIcon : icon,
                  color: color,
                  size: 24,
                ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
