import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:glu_butler/core/theme/app_theme.dart';

/// 네비게이션바 우측 설정 아이콘 버튼
///
/// 각 화면의 LargeTitleScrollView trailing에 사용됩니다.
/// 탭하면 /settings 화면으로 이동합니다.
///
/// ## 사용법
/// ```dart
/// LargeTitleScrollView(
///   title: '홈',
///   trailing: const SettingsIconButton(),
///   slivers: [...],
/// )
/// ```
class SettingsIconButton extends StatelessWidget {
  const SettingsIconButton({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: const EdgeInsets.all(8),
      onPressed: () => context.push('/settings'),
      child: const Icon(
        CupertinoIcons.gear,
        color: AppTheme.primaryColor,
        size: 24,
      ),
    );
  }
}
