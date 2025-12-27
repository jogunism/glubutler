import 'package:flutter/material.dart';

import 'package:glu_butler/core/navigation/main_screen.dart';
import 'package:glu_butler/features/splash/splash_screen.dart';
import 'package:glu_butler/features/settings/settings_screen.dart';
import 'package:glu_butler/features/settings/display_settings_screen.dart';
import 'package:glu_butler/features/settings/subscription_screen.dart';
import 'package:glu_butler/features/settings/health_connect_screen.dart';
import 'package:glu_butler/features/settings/glucose_range_screen.dart';
import 'package:glu_butler/features/settings/unit_selection_screen.dart';
import 'package:glu_butler/features/input/input_screen.dart';

/// 앱 라우트 정의 (기본 Navigator 사용)
///
/// GoRouter 대신 기본 Navigator를 사용하여 iOS 상태바 탭 scroll-to-top 지원
class AppRoutes {
  // Route names
  static const String splash = '/splash';
  static const String main = '/main';
  static const String settings = '/settings';
  static const String settingsDisplay = '/settings/display';
  static const String settingsSubscription = '/settings/subscription';
  static const String settingsHealth = '/settings/health';
  static const String settingsGlucoseRange = '/settings/glucose-range';
  static const String settingsUnit = '/settings/unit';
  static const String input = '/input';

  /// Route generator
  static Route<dynamic>? generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(
          builder: (_) => const SplashScreen(),
          settings: settings,
        );

      case main:
        // 스플래시에서 메인으로 전환 시 페이드 효과
        return PageRouteBuilder(
          settings: settings,
          pageBuilder: (_, __, ___) => MainScreen(key: MainScreen.globalKey),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 300),
        );

      case AppRoutes.settings:
        return MaterialPageRoute(
          builder: (_) => const SettingsScreen(),
          settings: settings,
        );

      case settingsDisplay:
        return MaterialPageRoute(
          builder: (_) => const DisplaySettingsScreen(),
          settings: settings,
        );

      case settingsSubscription:
        return MaterialPageRoute(
          builder: (_) => const SubscriptionScreen(),
          settings: settings,
        );

      case settingsHealth:
        return MaterialPageRoute(
          builder: (_) => const HealthConnectScreen(),
          settings: settings,
        );

      case settingsGlucoseRange:
        return MaterialPageRoute(
          builder: (_) => const GlucoseRangeScreen(),
          settings: settings,
        );

      case settingsUnit:
        return MaterialPageRoute(
          builder: (_) => const UnitSelectionScreen(),
          settings: settings,
        );

      case input:
        return MaterialPageRoute(
          builder: (_) => const InputScreen(),
          settings: settings,
        );

      default:
        return MaterialPageRoute(
          builder: (_) => const SplashScreen(),
          settings: settings,
        );
    }
  }

  /// Navigate to main screen (replace all routes)
  static void goToMain(BuildContext context) {
    Navigator.of(context).pushNamedAndRemoveUntil(main, (route) => false);
  }

  /// Navigate to settings (uses root navigator to escape CupertinoTabView)
  static void goToSettings(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pushNamed(settings);
  }

  /// Navigate to display settings
  static void goToDisplaySettings(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pushNamed(settingsDisplay);
  }

  /// Navigate to subscription
  static void goToSubscription(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pushNamed(settingsSubscription);
  }

  /// Navigate to health connect settings
  static void goToHealthConnect(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pushNamed(settingsHealth);
  }

  /// Navigate to glucose range settings
  static void goToGlucoseRange(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pushNamed(settingsGlucoseRange);
  }

  /// Navigate to unit selection
  static void goToUnitSelection(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pushNamed(settingsUnit);
  }

  /// Navigate to input screen
  static void goToInput(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pushNamed(input);
  }
}
