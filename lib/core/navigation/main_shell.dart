import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:glu_butler/l10n/app_localizations.dart';
import 'package:glu_butler/core/theme/app_theme.dart';

/// 메인 앱 셸 (iOS 26 스타일 플로팅 Liquid Glass 탭바)
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      body: Stack(
        children: [
          // 메인 콘텐츠
          Positioned.fill(
            child: widget.child,
          ),

          // 플로팅 탭바 (하단 오버레이)
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
                imagePath: 'assets/images/icon_mini.png',
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
