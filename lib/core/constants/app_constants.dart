class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'Glu Butler';
  static const String appVersion = '1.0.0';

  // Blood Glucose Units
  static const String unitMgDl = 'mg/dL';
  static const String unitMmolL = 'mmol/L';

  // Conversion factor: 1 mmol/L = 18.0182 mg/dL
  static const double mgDlToMmolL = 18.0182;

  // Blood Glucose Ranges (mg/dL) - Default thresholds
  static const double defaultVeryLow = 54.0;
  static const double defaultLow = 70.0;
  static const double defaultTargetLow = 80.0;
  static const double defaultTargetHigh = 120.0;
  static const double defaultHigh = 160.0;
  static const double defaultVeryHigh = 180.0;

  // Legacy values for compatibility
  static const double lowGlucose = 70.0;
  static const double normalGlucoseMin = 70.0;
  static const double normalGlucoseMax = 140.0;
  static const double highGlucose = 180.0;

  // Diabetes Types
  static const String diabetesType1 = 'type1';
  static const String diabetesType2 = 'type2';
  static const String diabetesTypeNone = 'none';

  // Supported Languages
  static const List<String> supportedLanguages = [
    'en', // English (default)
    'ko', // Korean
    'ja', // Japanese
    'zh', // Chinese
    'de', // German
    'es', // Spanish
    'fr', // French
    'it', // Italian
  ];

  // Default Values
  static const String defaultLanguage = 'en';
  static const String defaultUnit = unitMgDl;

  // Theme Modes
  static const String themeModeSystem = 'system';
  static const String themeModeLight = 'light';
  static const String themeModeDark = 'dark';

  // Sync Period (days)
  static const int syncPeriod1Week = 7;
  static const int syncPeriod2Weeks = 14;
  static const int syncPeriod1Month = 30;
  static const int syncPeriod3Months = 90;
  static const int defaultSyncPeriod = syncPeriod1Week;

  // Storage Keys
  static const String keyLanguage = 'language';
  static const String keyUnit = 'unit';
  static const String keyThemeMode = 'theme_mode';
  static const String keyUserProfile = 'user_profile';
  static const String keyNotificationTime = 'notification_time';
  static const String keyHealthConnected = 'health_connected';
  static const String keyIsPro = 'is_pro';
  static const String keySubscriptionDate = 'subscription_date';
  static const String keySyncPeriod = 'sync_period';

  // Glucose Range Keys
  static const String keyGlucoseVeryLow = 'glucose_very_low';
  static const String keyGlucoseLow = 'glucose_low';
  static const String keyGlucoseTargetLow = 'glucose_target_low';
  static const String keyGlucoseTargetHigh = 'glucose_target_high';
  static const String keyGlucoseHigh = 'glucose_high';
  static const String keyGlucoseVeryHigh = 'glucose_very_high';
}
