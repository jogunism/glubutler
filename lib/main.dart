import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:jiffy/jiffy.dart';
import 'package:cupertino_native_plus/cupertino_native.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:glu_butler/l10n/app_localizations.dart';
import 'package:glu_butler/core/theme/app_theme.dart';
import 'package:glu_butler/core/navigation/app_routes.dart';
import 'package:glu_butler/services/settings_service.dart';
import 'package:glu_butler/services/database_service.dart';
import 'package:glu_butler/services/cloudkit_service.dart';
import 'package:glu_butler/providers/feed_provider.dart';
import 'package:glu_butler/providers/report_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load .env file (for API keys)
  await dotenv.load(fileName: ".env");

  // Lock orientation to portrait mode
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize platform version for cupertino_native_plus
  await PlatformVersion.initialize();

  // Initialize database first (tables, migrations)
  await DatabaseService().initialize();

  final settingsService = SettingsService();
  await settingsService.init();

  // TODO: CloudKit 동기화 - Apple Developer Program($99/년) 가입 후 활성화
  // CloudKit requires a paid Apple Developer account to work
  // final cloudKitService = CloudKitService();
  // await cloudKitService.syncOnStartup();

  final feedProvider = FeedProvider();
  feedProvider.setSettingsService(settingsService);
  await feedProvider.initialize();

  final reportProvider = ReportProvider();
  await reportProvider.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settingsService),
        ChangeNotifierProvider.value(value: feedProvider),
        ChangeNotifierProvider.value(value: reportProvider),
      ],
      child: const GluButlerApp(),
    ),
  );
}

class GluButlerApp extends StatelessWidget {
  const GluButlerApp({super.key});

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

          // Localization - uses iOS per-app language settings
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'),
            Locale('ko'),
            Locale('ja'),
            Locale('zh'),
            Locale('de'),
            Locale('es'),
            Locale('fr'),
            Locale('it'),
          ],

          // Navigation - basic Navigator instead of GoRouter
          initialRoute: AppRoutes.splash,
          onGenerateRoute: AppRoutes.generateRoute,

          // Set up locale change callback
          builder: (context, child) {
            // Initialize Jiffy locale based on current locale
            final locale = Localizations.localeOf(context);
            _setJiffyLocale(locale.languageCode);
            return child!;
          },
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
  }
}
