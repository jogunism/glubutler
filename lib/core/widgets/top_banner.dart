import 'package:flutter/cupertino.dart';
import 'package:toastification/toastification.dart';

import 'package:glu_butler/core/theme/app_colors.dart';

/// iOS 스타일 상단 알림 토스트
///
/// iPhone 잠금화면 알림처럼 둥근 박스가 바운스 애니메이션과 함께 나타납니다.
///
/// 사용법:
/// ```dart
/// TopBanner.show(
///   context,
///   message: '저장되었습니다',
///   isSuccess: true,
/// );
/// ```
class TopBanner {
  TopBanner._();

  /// 상단 토스트 알림을 표시합니다
  static ToastificationItem show(
    BuildContext context, {
    required String message,
    required bool isSuccess,
    Duration? duration,
  }) {
    final colors = context.colors;
    // Detect dark mode by checking if card color is not white (dark theme uses navy)
    final isDarkMode = colors.card != const Color(0xFFFFFFFF);

    const horizontalMargin = 16.0;
    final screenWidth = MediaQuery.of(context).size.width;

    return toastification.showCustom(
      context: context,
      alignment: Alignment.topCenter,
      autoCloseDuration: duration ?? const Duration(seconds: 3),
      animationDuration: const Duration(milliseconds: 300),
      animationBuilder: (context, animation, alignment, child) {
        // Slide animation with fade out on dismiss
        final slideAnimation = Tween<Offset>(
          begin: const Offset(0, -1),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.elasticOut,
          reverseCurve: Curves.easeInCubic,
        ));

        // Fade animation - only fade out on dismiss (reverse)
        final fadeAnimation = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeOut,
          reverseCurve: Curves.easeIn,
        ));

        return SlideTransition(
          position: slideAnimation,
          child: FadeTransition(
            opacity: fadeAnimation,
            child: child,
          ),
        );
      },
      builder: (context, holder) {
        return Center(
          child: GestureDetector(
            onTap: () => toastification.dismiss(holder),
            onVerticalDragEnd: (details) {
              if (details.primaryVelocity != null &&
                  details.primaryVelocity! < 0) {
                toastification.dismiss(holder);
              }
            },
            child: Container(
              width: screenWidth - (horizontalMargin * 2),
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: colors.card,
                borderRadius: BorderRadius.circular(12),
                border: isDarkMode
                    ? Border.all(color: const Color(0xFF5C5C7A), width: 0.75)
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF000000).withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    isSuccess
                        ? CupertinoIcons.checkmark_circle_fill
                        : CupertinoIcons.xmark_circle_fill,
                    color: isSuccess ? colors.success : colors.error,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      message,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// 성공 알림을 표시합니다
  static ToastificationItem success(
    BuildContext context, {
    required String message,
    Duration? duration,
  }) {
    return show(context, message: message, isSuccess: true, duration: duration);
  }

  /// 에러 알림을 표시합니다
  static ToastificationItem error(
    BuildContext context, {
    required String message,
    Duration? duration,
  }) {
    return show(context, message: message, isSuccess: false, duration: duration);
  }
}
