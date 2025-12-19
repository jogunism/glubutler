import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:glu_butler/features/home/home_screen.dart';
import 'package:glu_butler/features/feed/feed_screen.dart';
import 'package:glu_butler/features/diary/diary_screen.dart';
import 'package:glu_butler/features/report/report_screen.dart';
import 'package:glu_butler/features/settings/settings_screen.dart';
import 'package:glu_butler/features/input/input_screen.dart';
import 'package:glu_butler/features/settings/display_settings_screen.dart';
import 'package:glu_butler/features/settings/subscription_screen.dart';
import 'package:glu_butler/features/settings/health_connect_screen.dart';
import 'package:glu_butler/features/splash/splash_screen.dart';
import 'package:glu_butler/core/navigation/main_shell.dart';

class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();

  static final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SplashScreen(),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        pageBuilder: (context, state, child) => NoTransitionPage(
          child: MainShell(child: child),
        ),
        routes: [
          GoRoute(
            path: '/home',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HomeScreen(),
            ),
          ),
          GoRoute(
            path: '/feed',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: FeedScreen(),
            ),
          ),
          GoRoute(
            path: '/diary',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: DiaryScreen(),
            ),
          ),
          GoRoute(
            path: '/report',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ReportScreen(),
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/settings',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/input',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const InputScreen(),
      ),
      GoRoute(
        path: '/settings/display',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const DisplaySettingsScreen(),
      ),
      GoRoute(
        path: '/settings/subscription',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SubscriptionScreen(),
      ),
      GoRoute(
        path: '/settings/health',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const HealthConnectScreen(),
      ),
    ],
  );
}
