import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:glu_butler/l10n/app_localizations.dart';
import 'package:glu_butler/core/theme/app_theme.dart';

/// 메인 앱 셸 (iOS: Liquid Glass 탭바, Android: Material 3 NavigationBar)
class MainShell extends StatefulWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _getCurrentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    switch (location) {
      case '/home':
        return 0;
      case '/feed':
        return 1;
      case '/diary':
        return 2;
      case '/report':
        return 3;
      default:
        return 0;
    }
  }

  void _onTabTapped(BuildContext context, int index) {
    HapticFeedback.lightImpact();
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/feed');
        break;
      case 2:
        context.go('/diary');
        break;
      case 3:
        context.go('/report');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currentIndex = _getCurrentIndex(context);

    if (Platform.isIOS) {
      return _buildIOSShell(context, l10n, currentIndex);
    } else {
      return _buildAndroidShell(context, l10n, currentIndex);
    }
  }

  /// iOS: 플로팅 Liquid Glass 탭바
  Widget _buildIOSShell(BuildContext context, AppLocalizations l10n, int currentIndex) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: widget.child),
          Positioned(
            left: 16,
            right: 16,
            bottom: bottomPadding + 8,
            child: _buildFloatingTabBar(context, l10n, currentIndex, isDark),
          ),
        ],
      ),
    );
  }

  /// Android: 탭바 (Stack 방식으로 직접 구현)
  Widget _buildAndroidShell(BuildContext context, AppLocalizations l10n, int currentIndex) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final tabBarHeight = 56.0;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            bottom: tabBarHeight + bottomPadding,
            child: widget.child,
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildAndroidTabBar(context, l10n, currentIndex, tabBarHeight, bottomPadding),
          ),
        ],
      ),
    );
  }

  Widget _buildAndroidTabBar(
    BuildContext context,
    AppLocalizations l10n,
    int currentIndex,
    double tabBarHeight,
    double bottomPadding,
  ) {
    final bgColor = AppTheme.iosBackground(context);
    final selectedColor = AppTheme.primaryColor;
    final unselectedColor = AppTheme.textSecondary(context);

    final tabs = [
      (icon: Icons.home_outlined,      selectedIcon: Icons.home,      label: l10n.home,   index: 0, isImage: true),
      (icon: Icons.grid_view_outlined, selectedIcon: Icons.grid_view, label: l10n.feed,   index: 1, isImage: false),
      (icon: Icons.book_outlined,      selectedIcon: Icons.book,      label: l10n.diary,  index: 2, isImage: false),
      (icon: Icons.bar_chart_outlined, selectedIcon: Icons.bar_chart, label: l10n.report, index: 3, isImage: false),
    ];

    return Container(
      color: bgColor,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Divider(
            height: 1,
            thickness: 0.5,
            color: AppTheme.divider(context),
          ),
          SizedBox(
            height: tabBarHeight,
            child: Row(
              children: tabs.map((tab) {
                final isSelected = tab.index == currentIndex;
                final color = isSelected ? selectedColor : unselectedColor;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => _onTabTapped(context, tab.index),
                    behavior: HitTestBehavior.opaque,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (tab.isImage)
                          ColorFiltered(
                            colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
                            child: Image.asset(
                              'assets/images/main_icon.png',
                              width: 24,
                              height: 24,
                            ),
                          )
                        else
                          Icon(
                            isSelected ? tab.selectedIcon : tab.icon,
                            color: color,
                            size: 24,
                          ),
                        const SizedBox(height: 3),
                        Text(
                          tab.label,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          SizedBox(height: bottomPadding),
        ],
      ),
    );
  }

  Widget _buildFloatingTabBar(
    BuildContext context,
    AppLocalizations l10n,
    int currentIndex,
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
                imagePath: 'assets/images/main_icon.png',
                label: l10n.home,
                index: 0,
                currentIndex: currentIndex,
                isImage: true,
              ),
              _buildTabItem(
                context: context,
                icon: Icons.view_agenda_outlined,
                selectedIcon: Icons.view_agenda,
                label: l10n.feed,
                index: 1,
                currentIndex: currentIndex,
              ),
              _buildTabItem(
                context: context,
                icon: Icons.book_outlined,
                selectedIcon: Icons.book,
                label: l10n.diary,
                index: 2,
                currentIndex: currentIndex,
              ),
              _buildTabItem(
                context: context,
                icon: Icons.analytics_outlined,
                selectedIcon: Icons.analytics,
                label: l10n.report,
                index: 3,
                currentIndex: currentIndex,
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
    required int currentIndex,
    bool isImage = false,
  }) {
    final isSelected = index == currentIndex;
    final theme = Theme.of(context);
    final color = isSelected
        ? AppTheme.primaryColor
        : theme.colorScheme.onSurface.withValues(alpha: 0.6);

    return Expanded(
      child: GestureDetector(
        onTap: () => _onTabTapped(context, index),
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
