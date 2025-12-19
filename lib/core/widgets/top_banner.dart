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

    return toastification.show(
      context: context,
      type: isSuccess ? ToastificationType.success : ToastificationType.error,
      style: ToastificationStyle.flat,
      title: Text(
        message,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
      ),
      alignment: Alignment.topCenter,
      autoCloseDuration: duration ?? const Duration(seconds: 3),
      animationDuration: const Duration(milliseconds: 300),
      animationBuilder: (context, animation, alignment, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -1),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.elasticOut,
            reverseCurve: Curves.easeInCubic,
          )),
          child: child,
        );
      },
      icon: Icon(
        isSuccess
            ? CupertinoIcons.checkmark_circle_fill
            : CupertinoIcons.xmark_circle_fill,
        color: isSuccess ? colors.success : colors.error,
        size: 22,
      ),
      primaryColor: isSuccess ? colors.success : colors.error,
      backgroundColor: colors.card,
      foregroundColor: colors.textPrimary,
      borderRadius: BorderRadius.circular(14),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF000000).withValues(alpha: 0.1),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ],
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      showProgressBar: false,
      closeButton: const ToastCloseButton(showType: CloseButtonShowType.none),
      closeOnClick: true,
      dragToClose: true,
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
