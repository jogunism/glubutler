import 'package:flutter/material.dart';
import 'package:glu_butler/core/theme/app_theme.dart';

/// 화면별 플로팅 액션 버튼
///
/// feed, diary 화면에서 우측 하단 탭바 위에 표시되는 [+] 버튼입니다.
///
/// ## 사용법
/// ```dart
/// Stack(
///   children: [
///     // 메인 컨텐츠
///     ScreenFab(onPressed: () => showModal()),
///   ],
/// )
/// ```
class ScreenFab extends StatelessWidget {
  final VoidCallback onPressed;

  const ScreenFab({
    super.key,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 16,
      bottom: 16,
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
        child: IconButton(
          icon: const Icon(Icons.add, color: Colors.white, size: 28),
          onPressed: onPressed,
        ),
      ),
    );
  }
}
