import 'package:flutter/material.dart';

import 'package:glu_butler/core/theme/app_theme.dart';

/// 화면별 플로팅 액션 버튼
///
/// home, feed, diary 화면에서 우측 하단에 표시되는 [+] 버튼입니다.
/// 글래스 효과와 그림자를 적용한 iOS 스타일 버튼입니다.
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
    // 플로팅 탭바 높이(64) + 하단 여백(8) + SafeArea + 추가 여백
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final fabBottom = 64 + bottomPadding + 8 + 16;

    return Positioned(
      right: 16,
      bottom: fabBottom,
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppTheme.shadowPrimary,
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.primaryColor,
            ),
            child: const Icon(
              Icons.add,
              size: 32,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
