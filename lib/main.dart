import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:jiffy/jiffy.dart';

import 'package:glu_butler/l10n/app_localizations.dart';
import 'package:glu_butler/core/theme/app_theme.dart';
import 'package:glu_butler/core/navigation/app_routes.dart';
import 'package:glu_butler/services/settings_service.dart';
import 'package:glu_butler/services/database_service.dart';
import 'package:glu_butler/providers/feed_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize database first (tables, migrations)
  await DatabaseService().initialize();

  final settingsService = SettingsService();
  await settingsService.init();

  final feedProvider = FeedProvider();
  feedProvider.setSettingsService(settingsService);
  await feedProvider.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settingsService),
        ChangeNotifierProvider.value(value: feedProvider),
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
