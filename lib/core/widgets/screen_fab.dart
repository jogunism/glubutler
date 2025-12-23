import 'package:flutter/material.dart';
import 'package:glu_butler/core/theme/app_theme.dart';

/// 화면별 플로팅 액션 버튼
///
/// feed, diary 화면에서 우측 하단 탭바 위에 표시되는 [+] 버튼입니다.
/// 탭 전환 시 바운스 애니메이션과 함께 나타나고 사라집니다.
///
/// ## 사용법
/// ```dart
/// Stack(
///   children: [
///     // 메인 컨텐츠
///     ScreenFab(
///       onPressed: () => showModal(),
///       visible: true,
///     ),
///   ],
/// )
/// ```
class ScreenFab extends StatefulWidget {
  final VoidCallback onPressed;
  final bool visible;

  const ScreenFab({super.key, required this.onPressed, this.visible = true});

  @override
  State<ScreenFab> createState() => _ScreenFabState();
}

class _ScreenFabState extends State<ScreenFab>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    // Slide animation with bounce effect
    _slideAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
      reverseCurve: Curves.easeInBack,
    );

    // Scale animation for extra effect
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.elasticOut,
        reverseCurve: Curves.easeInBack,
      ),
    );

    // Initial state
    if (widget.visible) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(ScreenFab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visible != oldWidget.visible) {
      if (widget.visible) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final slideValue = _slideAnimation.value.clamp(0.0, 1.0);
        final scaleValue = _scaleAnimation.value.clamp(0.0, 1.0);

        // Slide up from below tab bar when appearing
        // Button should slide from behind the tab bar upward (50px from bottom)
        final offsetY = -50 * (1 - slideValue);

        return Positioned(
          right: 22,
          bottom: 92 + offsetY,
          child: Transform.scale(
            scale: scaleValue,
            child: Opacity(
              opacity: slideValue,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: widget.onPressed,
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(Icons.add, color: Colors.white, size: 28),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
