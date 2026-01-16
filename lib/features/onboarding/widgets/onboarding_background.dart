import 'package:flutter/material.dart';
import 'package:glu_butler/core/theme/app_theme.dart';

/// Background widget for onboarding screens
/// Provides consistent cream/ivory background color
class OnboardingBackground extends StatelessWidget {
  final Widget child;

  const OnboardingBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.iosBackground(context),
      child: SafeArea(
        child: child,
      ),
    );
  }
}
