import 'package:flutter/material.dart';

/// ThemeExtension for app-wide colors that adapt to light/dark theme.
/// Usage: Theme.of(context).extension<AppColors>()!.background
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.background,
    required this.card,
    required this.tabBar,
    required this.divider,
    required this.textPrimary,
    required this.textSecondary,
    required this.glassBackground,
    required this.glassBorder,
  });

  /// iOS-style background color
  final Color background;

  /// Card/container background color
  final Color card;

  /// Tab bar background color (burgundy tone)
  final Color tabBar;

  /// Divider/separator color
  final Color divider;

  /// Primary text color
  final Color textPrimary;

  /// Secondary/muted text color
  final Color textSecondary;

  /// Glass effect background color
  final Color glassBackground;

  /// Glass effect border color
  final Color glassBorder;

  /// Light theme colors (Glu Sight palette)
  static const light = AppColors(
    background: Color(0xFFF2F2F7), // iOS Default Light
    card: Colors.white, // White card
    tabBar: Color(0xFFF2F2F7), // iOS Default Light
    divider: Color(0xFFE5E5EA), // Light Gray Divider
    textPrimary: Color(0xFF1C1C1E), // Dark Gray
    textSecondary: Color(0xFF8E8E93), // Gray
    glassBackground: Color(0x1A4ECDC4), // Mint/Teal 10%
    glassBorder: Color(0x4D4ECDC4), // Mint/Teal 30%
  );

  /// Dark theme colors (Glu Sight palette)
  static const dark = AppColors(
    background: Color(0xFF1C1C2E), // Dark Navy
    card: Color(0xFF2D2D44), // Lighter Navy
    tabBar: Color(0xFF2D2D44), // Lighter Navy
    divider: Color(0xFF3D3D5C), // Navy Divider
    textPrimary: Color(0xFFFFFFFF), // White
    textSecondary: Color(0xFF8E8E93), // Gray
    glassBackground: Color(0x264ECDC4), // Mint/Teal 15%
    glassBorder: Color(0x664ECDC4), // Mint/Teal 40%
  );

  @override
  AppColors copyWith({
    Color? background,
    Color? card,
    Color? tabBar,
    Color? divider,
    Color? textPrimary,
    Color? textSecondary,
    Color? glassBackground,
    Color? glassBorder,
  }) {
    return AppColors(
      background: background ?? this.background,
      card: card ?? this.card,
      tabBar: tabBar ?? this.tabBar,
      divider: divider ?? this.divider,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      glassBackground: glassBackground ?? this.glassBackground,
      glassBorder: glassBorder ?? this.glassBorder,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) {
      return this;
    }
    return AppColors(
      background: Color.lerp(background, other.background, t)!,
      card: Color.lerp(card, other.card, t)!,
      tabBar: Color.lerp(tabBar, other.tabBar, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      glassBackground: Color.lerp(glassBackground, other.glassBackground, t)!,
      glassBorder: Color.lerp(glassBorder, other.glassBorder, t)!,
    );
  }
}

/// Extension method for easy access
extension AppColorsExtension on BuildContext {
  AppColors get colors =>
      Theme.of(this).extension<AppColors>() ?? AppColors.light;
}
