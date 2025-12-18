import 'package:flutter/material.dart';

/// ThemeExtension for app-wide text styles.
/// Usage: Theme.of(context).extension<AppTextStyles>()!.sectionTitle
class AppTextStyles extends ThemeExtension<AppTextStyles> {
  const AppTextStyles({
    required this.sectionTitle,
    required this.tileTitle,
    required this.tileSubtitle,
    required this.largeTitle,
    required this.bodyText,
    required this.bodyTextSecondary,
    required this.buttonText,
    required this.buttonTextSecondary,
    required this.navBarTitle,
    required this.caption,
    required this.labelSmall,
  });

  /// Section header text (e.g., "GENERAL", "ABOUT")
  /// fontSize: 13, w500, grey color, letterSpacing: 0.5
  final TextStyle sectionTitle;

  /// List tile title text
  /// fontSize: 16, primary text color
  final TextStyle tileTitle;

  /// List tile subtitle text
  /// fontSize: 14, secondary grey color
  final TextStyle tileSubtitle;

  /// Large display title (e.g., "You are Pro!")
  /// fontSize: 28, bold, primary text color
  final TextStyle largeTitle;

  /// Body text for descriptions
  /// fontSize: 16, primary text color
  final TextStyle bodyText;

  /// Secondary body text
  /// fontSize: 16, secondary grey color
  final TextStyle bodyTextSecondary;

  /// Primary button text
  /// fontSize: 18, w600, white color
  final TextStyle buttonText;

  /// Secondary button text
  /// fontSize: 16, w500, primary color
  final TextStyle buttonTextSecondary;

  /// Navigation bar title
  /// fontSize: 17, w600
  final TextStyle navBarTitle;

  /// Caption text for small labels
  /// fontSize: 12, secondary color
  final TextStyle caption;

  /// Very small label text
  /// fontSize: 11, secondary color
  final TextStyle labelSmall;

  /// Light theme text styles (Glu Sight palette)
  static const light = AppTextStyles(
    sectionTitle: TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      color: Color(0xFF8E8E93), // Gray
      letterSpacing: 0.5,
    ),
    tileTitle: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.normal,
      color: Color(0xFF1C1C1E), // Dark Gray
    ),
    tileSubtitle: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.normal,
      color: Color(0xFF8E8E93), // Gray
    ),
    largeTitle: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.bold,
      color: Color(0xFF1C1C1E), // Dark Gray
    ),
    bodyText: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.normal,
      color: Color(0xFF1C1C1E), // Dark Gray
    ),
    bodyTextSecondary: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.normal,
      color: Color(0xFF8E8E93), // Gray
    ),
    buttonText: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: Colors.white,
    ),
    buttonTextSecondary: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      color: Color(0xFFFF6B6B), // Coral/Salmon
    ),
    navBarTitle: TextStyle(
      fontSize: 17,
      fontWeight: FontWeight.w600,
      color: Color(0xFF1C1C1E), // Dark Gray
    ),
    caption: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.normal,
      color: Color(0xFF8E8E93), // Gray
    ),
    labelSmall: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.normal,
      color: Color(0xFF8E8E93), // Gray
    ),
  );

  /// Dark theme text styles (Glu Sight palette)
  static const dark = AppTextStyles(
    sectionTitle: TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      color: Color(0xFF8E8E93), // Gray
      letterSpacing: 0.5,
    ),
    tileTitle: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.normal,
      color: Color(0xFFFFFFFF), // White
    ),
    tileSubtitle: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.normal,
      color: Color(0xFF8E8E93), // Gray
    ),
    largeTitle: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.bold,
      color: Color(0xFFFFFFFF), // White
    ),
    bodyText: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.normal,
      color: Color(0xFFFFFFFF), // White
    ),
    bodyTextSecondary: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.normal,
      color: Color(0xFF8E8E93), // Gray
    ),
    buttonText: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: Colors.white,
    ),
    buttonTextSecondary: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      color: Color(0xFF9B8FE4), // Lavender/Purple
    ),
    navBarTitle: TextStyle(
      fontSize: 17,
      fontWeight: FontWeight.w600,
      color: Color(0xFFFFFFFF), // White
    ),
    caption: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.normal,
      color: Color(0xFF8E8E93), // Gray
    ),
    labelSmall: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.normal,
      color: Color(0xFF8E8E93), // Gray
    ),
  );

  @override
  AppTextStyles copyWith({
    TextStyle? sectionTitle,
    TextStyle? tileTitle,
    TextStyle? tileSubtitle,
    TextStyle? largeTitle,
    TextStyle? bodyText,
    TextStyle? bodyTextSecondary,
    TextStyle? buttonText,
    TextStyle? buttonTextSecondary,
    TextStyle? navBarTitle,
    TextStyle? caption,
    TextStyle? labelSmall,
  }) {
    return AppTextStyles(
      sectionTitle: sectionTitle ?? this.sectionTitle,
      tileTitle: tileTitle ?? this.tileTitle,
      tileSubtitle: tileSubtitle ?? this.tileSubtitle,
      largeTitle: largeTitle ?? this.largeTitle,
      bodyText: bodyText ?? this.bodyText,
      bodyTextSecondary: bodyTextSecondary ?? this.bodyTextSecondary,
      buttonText: buttonText ?? this.buttonText,
      buttonTextSecondary: buttonTextSecondary ?? this.buttonTextSecondary,
      navBarTitle: navBarTitle ?? this.navBarTitle,
      caption: caption ?? this.caption,
      labelSmall: labelSmall ?? this.labelSmall,
    );
  }

  @override
  AppTextStyles lerp(ThemeExtension<AppTextStyles>? other, double t) {
    if (other is! AppTextStyles) {
      return this;
    }
    return AppTextStyles(
      sectionTitle: TextStyle.lerp(sectionTitle, other.sectionTitle, t)!,
      tileTitle: TextStyle.lerp(tileTitle, other.tileTitle, t)!,
      tileSubtitle: TextStyle.lerp(tileSubtitle, other.tileSubtitle, t)!,
      largeTitle: TextStyle.lerp(largeTitle, other.largeTitle, t)!,
      bodyText: TextStyle.lerp(bodyText, other.bodyText, t)!,
      bodyTextSecondary:
          TextStyle.lerp(bodyTextSecondary, other.bodyTextSecondary, t)!,
      buttonText: TextStyle.lerp(buttonText, other.buttonText, t)!,
      buttonTextSecondary:
          TextStyle.lerp(buttonTextSecondary, other.buttonTextSecondary, t)!,
      navBarTitle: TextStyle.lerp(navBarTitle, other.navBarTitle, t)!,
      caption: TextStyle.lerp(caption, other.caption, t)!,
      labelSmall: TextStyle.lerp(labelSmall, other.labelSmall, t)!,
    );
  }
}

/// Extension method for easy access
extension AppTextStylesExtension on BuildContext {
  AppTextStyles get textStyles =>
      Theme.of(this).extension<AppTextStyles>() ?? AppTextStyles.light;
}
