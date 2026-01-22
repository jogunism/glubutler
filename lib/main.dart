import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:jiffy/jiffy.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'package:glu_butler/l10n/app_localizations.dart';
import 'package:glu_butler/core/theme/app_theme.dart';
import 'package:glu_butler/core/navigation/app_routes.dart';
import 'package:glu_butler/services/settings_service.dart';
import 'package:glu_butler/services/database_service.dart';
import 'package:glu_butler/services/notification_service.dart';
import 'package:glu_butler/services/analytics_service.dart';
import 'package:glu_butler/services/subscription_service.dart';
import 'package:glu_butler/providers/feed_provider.dart';
import 'package:glu_butler/providers/report_provider.dart';
import 'package:glu_butler/providers/diary_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load .env file (for API keys)
  await dotenv.load(fileName: ".env");

  // Initialize Firebase (production only)
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await AnalyticsService.initialize();
  } catch (e) {
    debugPrint('[Firebase] Initialization failed: $e');
  }

  // Initialize RevenueCat (subscription service)
  await SubscriptionService.initialize();

  // Lock orientation to portrait mode
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize database first (tables, migrations)
  await DatabaseService().initialize();

  final settingsService = SettingsService();
  await settingsService.init();

  // Initialize notification service (권한 요청은 온보딩에서 처리)
  final notificationService = NotificationService();
  await notificationService.initialize();

  // 만료된 알림 정리
  await notificationService.cleanupExpiredNotifications();

  // 리포트 알림 조건부 스케줄링
  await notificationService.scheduleReportReminderIfNeeded();

  final feedProvider = FeedProvider();
  feedProvider.setSettingsService(settingsService);
  await feedProvider.initialize();

  final diaryProvider = DiaryProvider();
  diaryProvider.setSettingsService(settingsService);
  await diaryProvider.initialize();

  final reportProvider = ReportProvider(
    feedProvider: feedProvider,
    diaryProvider: diaryProvider,
    settingsService: settingsService,
  );
  await reportProvider.initialize();

  // iCloud 동기화 (백그라운드, DiaryProvider를 통해 UI 업데이트)
  if (settingsService.iCloudSyncEnabled) {
    diaryProvider.syncFromICloud();
  }

  // Always start with splash screen - it will handle routing to onboarding or main
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settingsService),
        ChangeNotifierProvider.value(value: feedProvider),
        ChangeNotifierProvider.value(value: reportProvider),
        ChangeNotifierProvider.value(value: diaryProvider),
      ],
      child: const GluButlerApp(initialRoute: AppRoutes.splash),
    ),
  );
}

class GluButlerApp extends StatelessWidget {
  final String initialRoute;

  const GluButlerApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsService>(
      builder: (context, settings, child) {
        return MaterialApp(
          title: 'Glu Butler',
          debugShowCheckedModeBanner: false,

          // Theme
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: settings.flutterThemeMode,

          // Text scaling
          builder: (context, child) {
            // Initialize Jiffy locale based on current locale
            final locale = Localizations.localeOf(context);
            _setJiffyLocale(locale.languageCode);

            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(settings.textScale),
              ),
              child: child!,
            );
          },

          // Localization - uses iOS per-app language settings
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'), // Default fallback
            Locale('ko'),
            Locale('ja'),
            Locale('zh'),
            Locale('de'),
            Locale('es'),
            Locale('fr'),
            Locale('it'),
          ],
          // Fallback to English when user locale is not supported
          localeResolutionCallback: (locale, supportedLocales) {
            // User's locale (e.g., 'hi' for Hindi)
            if (locale != null) {
              for (var supportedLocale in supportedLocales) {
                if (supportedLocale.languageCode == locale.languageCode) {
                  return supportedLocale;
                }
              }
            }
            // Fallback to English
            return const Locale('en');
          },

          // Navigation - basic Navigator instead of GoRouter
          initialRoute: initialRoute,
          onGenerateRoute: AppRoutes.generateRoute,
        );
      },
    );
  }

  void _setJiffyLocale(String languageCode) {
    // Map Flutter locale codes to Jiffy locale codes
    // Jiffy uses underscore format like 'zh_cn', 'ko', 'ja', etc.
    String jiffyLocale;
    switch (languageCode) {
      case 'zh':
        jiffyLocale = 'zh_cn';
        break;
      case 'ko':
        jiffyLocale = 'ko';
        break;
      case 'ja':
        jiffyLocale = 'ja';
        break;
      case 'de':
        jiffyLocale = 'de';
        break;
      case 'es':
        jiffyLocale = 'es';
        break;
      case 'fr':
        jiffyLocale = 'fr';
        break;
      case 'it':
        jiffyLocale = 'it';
        break;
      default:
        jiffyLocale = 'en_us';
    }

    // Set Jiffy locale asynchronously (fire and forget since builder is not async)
    Jiffy.setLocale(jiffyLocale);

    // Save locale to SharedPreferences for notification service
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString('locale', languageCode);
    });
  }
}
