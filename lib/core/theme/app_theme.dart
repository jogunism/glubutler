import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_decorations.dart';
import 'app_text_styles.dart';

class AppTheme {
  AppTheme._();

  // ==========================================================================
  // Brand Colors (Glu Sight palette)
  // ==========================================================================
  static const Color primaryColor = Color(0xFFC1121F); // Flag Red
  static const Color secondaryColor = Color(0xFF2D3748); // Dark Slate (from logo "Butler")
  static const Color accentColor = Color(0xFFFF6B6B); // Coral/Salmon (Light mode)
  static const Color accentColorDark = Color(0xFF9B8FE4); // Lavender/Purple (Dark mode)

  // ==========================================================================
  // Blood Glucose Status Colors (5 levels)
  // ==========================================================================
  static const Color glucoseVeryLow = Colors.purple; // Very Low (<target-40)
  static const Color glucoseLow = Colors.blue; // Low (target-40 to target-20)
  static const Color glucoseNormal = Color(0xFF4CAF50); // Green (target±20)
  static const Color glucoseHigh = Color(0xFFF9A825); // Yellow/Amber (target+20 to target+40)
  static const Color glucoseVeryHigh = Colors.red; // Very High (>target+40)

  // ==========================================================================
  // iOS Style Background Colors
  // ==========================================================================
  static const Color iosBackgroundLight = Color(0xFFF2F2F7); // iOS Default Light
  static const Color iosBackgroundDark = Color(0xFF1C1C2E); // Dark Navy
  static const Color iosCardLight = Colors.white;
  static const Color iosCardDark = Color(0xFF3A3A55); // Brighter Navy (increased from 2D2D44)

  // Tab Bar Colors
  static const Color tabBarLight = Color(0xFFF2F2F7); // iOS Default Light
  static const Color tabBarDark = Color(0xFF2D2D44); // Lighter Navy

  // Legacy Background Colors
  static const Color backgroundLight = Color(0xFFF5F5F5);
  static const Color backgroundDark = Color(0xFF121212);

  // ==========================================================================
  // Text Colors
  // ==========================================================================
  static const Color textPrimaryLight = Color(0xFF1C1C1E); // Dark Gray
  static const Color textSecondaryLight = Color(0xFF8E8E93); // Gray
  static const Color textPrimaryDark = Color(0xFFFFFFFF); // White
  static const Color textSecondaryDark = Color(0xFF8E8E93); // Gray

  // ==========================================================================
  // Icon Colors (for Settings, Features, etc.)
  // ==========================================================================
  static const Color iconOrange = Colors.orange;
  static const Color iconGreen = Colors.green;
  static const Color iconBlue = Colors.blue;
  static const Color iconPurple = Colors.purple;
  static const Color iconPink = Colors.pink;
  static const Color iconCyan = Colors.cyan;
  static const Color iconRed = Colors.red;
  static const Color iconIndigo = Colors.indigo;
  static const Color iconAmber = Colors.amber;
  static const Color iconTeal = Colors.teal;
  static const Color iconLightBlue = Colors.lightBlue;

  // ==========================================================================
  // Subscription Badge Gradients
  // ==========================================================================
  static List<Color> get proGradient => [
        Colors.amber.shade400,
        Colors.orange.shade600,
      ];

  static List<Color> get proActiveGradient => [
        Colors.green.shade400,
        Colors.teal.shade600,
      ];

  // ==========================================================================
  // Divider Colors
  // ==========================================================================
  static Color get dividerLight => Colors.grey.shade200;
  static Color get dividerDark => Colors.grey.shade800;

  // ==========================================================================
  // Shadow Colors
  // ==========================================================================
  static Color get shadowOrange => Colors.orange.withValues(alpha: 0.4);
  static Color get shadowGreen => Colors.green.withValues(alpha: 0.4);
  static Color get shadowPrimary => primaryColor.withValues(alpha: 0.3);

  // ==========================================================================
  // Glass Effect Colors
  // ==========================================================================
  static Color get glassBackgroundLight =>
      const Color(0xFFA31545).withValues(alpha: 0.05); // Burgundy
  static Color get glassBackgroundDark =>
      const Color(0xFF9B8FE4).withValues(alpha: 0.1); // Lavender
  static Color get glassBorderLight =>
      const Color(0xFFA31545).withValues(alpha: 0.15); // Burgundy
  static Color get glassBorderDark =>
      const Color(0xFF9B8FE4).withValues(alpha: 0.2); // Lavender

  // Minimum touch target size for accessibility (48pt)
  static const double minTouchTarget = 48.0;

  // Font sizes for elderly users
  static const double fontSizeSmall = 14.0;
  static const double fontSizeMedium = 16.0;
  static const double fontSizeLarge = 18.0;
  static const double fontSizeXLarge = 22.0;
  static const double fontSizeTitle = 28.0;

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: backgroundLight,
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: fontSizeXLarge,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: fontSizeTitle,
        fontWeight: FontWeight.bold,
        color: textPrimaryLight,
      ),
      titleLarge: TextStyle(
        fontSize: fontSizeXLarge,
        fontWeight: FontWeight.w600,
        color: textPrimaryLight,
      ),
      bodyLarge: TextStyle(
        fontSize: fontSizeLarge,
        color: textPrimaryLight,
      ),
      bodyMedium: TextStyle(
        fontSize: fontSizeMedium,
        color: textPrimaryLight,
      ),
      bodySmall: TextStyle(
        fontSize: fontSizeSmall,
        color: textSecondaryLight,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(minTouchTarget, minTouchTarget),
        textStyle: const TextStyle(
          fontSize: fontSizeMedium,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      sizeConstraints: BoxConstraints.tightFor(
        width: 64,
        height: 64,
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: primaryColor,
      unselectedItemColor: textSecondaryLight,
      selectedLabelStyle: TextStyle(fontSize: fontSizeSmall),
      unselectedLabelStyle: TextStyle(fontSize: fontSizeSmall),
      type: BottomNavigationBarType.fixed,
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
    ),
    extensions: <ThemeExtension<dynamic>>[
      AppTextStyles.light,
      AppColors.light,
      AppDecorations.light,
    ],
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: backgroundDark,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.grey.shade900,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: const TextStyle(
        fontSize: fontSizeXLarge,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: fontSizeTitle,
        fontWeight: FontWeight.bold,
        color: textPrimaryDark,
      ),
      titleLarge: TextStyle(
        fontSize: fontSizeXLarge,
        fontWeight: FontWeight.w600,
        color: textPrimaryDark,
      ),
      bodyLarge: TextStyle(
        fontSize: fontSizeLarge,
        color: textPrimaryDark,
      ),
      bodyMedium: TextStyle(
        fontSize: fontSizeMedium,
        color: textPrimaryDark,
      ),
      bodySmall: TextStyle(
        fontSize: fontSizeSmall,
        color: textSecondaryDark,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(minTouchTarget, minTouchTarget),
        textStyle: const TextStyle(
          fontSize: fontSizeMedium,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      sizeConstraints: BoxConstraints.tightFor(
        width: 64,
        height: 64,
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: Colors.grey.shade900,
      selectedItemColor: primaryColor,
      unselectedItemColor: textSecondaryDark,
      selectedLabelStyle: const TextStyle(fontSize: fontSizeSmall),
      unselectedLabelStyle: const TextStyle(fontSize: fontSizeSmall),
      type: BottomNavigationBarType.fixed,
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      color: iosCardDark, // Use brighter navy color instead of grey.shade900
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.grey.shade800,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade700),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
    ),
    extensions: <ThemeExtension<dynamic>>[
      AppTextStyles.dark,
      AppColors.dark,
      AppDecorations.dark,
    ],
  );

  // ==========================================================================
  // Helper Methods
  // ==========================================================================

  /// Get glucose status color based on value
  static Color getGlucoseColor(double glucoseValue) {
    if (glucoseValue < 70) {
      return glucoseLow;
    } else if (glucoseValue <= 140) {
      return glucoseNormal;
    } else {
      return glucoseHigh;
    }
  }

  /// Get iOS style background color based on theme
  static Color iosBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? iosBackgroundDark
        : iosBackgroundLight;
  }

  /// Get iOS style card color based on theme
  static Color iosCard(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? iosCardDark
        : iosCardLight;
  }

  /// Get tab bar color based on theme
  static Color tabBar(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? tabBarDark
        : tabBarLight;
  }

  /// Get divider color based on theme
  static Color divider(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? dividerDark
        : dividerLight;
  }

  /// Get primary text color based on theme
  static Color textPrimary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? textPrimaryDark
        : textPrimaryLight;
  }

  /// Get glass background color based on theme
  static Color glassBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? glassBackgroundDark
        : glassBackgroundLight;
  }

  /// Get glass border color based on theme
  static Color glassBorder(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? glassBorderDark
        : glassBorderLight;
  }

  /// Get accent color based on theme (for icons, buttons, links)
  static Color accent(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? accentColorDark
        : accentColor;
  }
}
