import 'package:flutter/cupertino.dart';

import 'package:glu_butler/core/theme/app_theme.dart';
import 'package:glu_butler/core/navigation/app_routes.dart';

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
      padding: const EdgeInsets.only(left: 36, right: 8),
      minimumSize: Size.zero,
      onPressed: () => AppRoutes.goToSettings(context),
      child: const Icon(
        CupertinoIcons.gear,
        color: AppTheme.primaryColor,
        size: 24,
      ),
    );
  }
}
