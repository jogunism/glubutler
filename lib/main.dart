import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'package:glu_butler/l10n/app_localizations.dart';
import 'package:glu_butler/core/theme/app_theme.dart';
import 'package:glu_butler/core/navigation/app_router.dart';
import 'package:glu_butler/services/settings_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final settingsService = SettingsService();
  await settingsService.init();

  runApp(
    ChangeNotifierProvider.value(
      value: settingsService,
      child: const GluButlerApp(),
    ),
  );
}

class GluButlerApp extends StatelessWidget {
  const GluButlerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();

    return MaterialApp.router(
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

      // Router
      routerConfig: AppRouter.router,
    );
  }
}
