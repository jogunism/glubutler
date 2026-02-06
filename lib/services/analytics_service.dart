import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Analytics service for tracking user events
/// Only active in production mode (APP_ENV=production)
class AnalyticsService {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  /// Check if analytics is enabled (production mode only)
  static bool get isEnabled => dotenv.env['APP_ENV'] == 'production';

  /// Initialize analytics
  static Future<void> initialize() async {
    if (!isEnabled) {
      debugPrint('[Analytics] Disabled (not in production mode)');
      return;
    }

    await _analytics.setAnalyticsCollectionEnabled(true);
    debugPrint('[Analytics] Initialized');
  }

  /// Log screen view
  static Future<void> logScreenView(String screenName) async {
    if (!isEnabled) return;

    await _analytics.logScreenView(
      screenName: screenName,
    );
    debugPrint('[Analytics] Screen: $screenName');
  }

  /// Log onboarding completed
  static Future<void> logOnboardingCompleted() async {
    if (!isEnabled) return;

    await _analytics.logEvent(
      name: 'onboarding_completed',
    );
    debugPrint('[Analytics] Onboarding completed');
  }

  /// Log Apple Health connection
  static Future<void> logHealthConnected({required bool success}) async {
    if (!isEnabled) return;

    await _analytics.logEvent(
      name: 'health_connected',
      parameters: {'success': success},
    );
    debugPrint('[Analytics] Health connected: $success');
  }

  /// Log iCloud sync enabled
  static Future<void> logICloudEnabled({required bool success}) async {
    if (!isEnabled) return;

    await _analytics.logEvent(
      name: 'icloud_enabled',
      parameters: {'success': success},
    );
    debugPrint('[Analytics] iCloud enabled: $success');
  }

  /// Log report generation (always tracked - important metric)
  static Future<void> logReportGenerated({required bool success}) async {
    if (!isEnabled) return;

    await _analytics.logEvent(
      name: 'report_generated',
      parameters: {'success': success},
    );
    debugPrint('[Analytics] Report generated: $success');
  }

  /// Log report export via email (always tracked - important metric)
  static Future<void> logReportExported({required bool success}) async {
    if (!isEnabled) return;

    await _analytics.logEvent(
      name: 'report_exported',
      parameters: {'success': success},
    );
    debugPrint('[Analytics] Report exported: $success');
  }

  /// Log subscription started
  static Future<void> logSubscriptionStarted(String plan) async {
    if (!isEnabled) return;

    await _analytics.logEvent(
      name: 'subscription_started',
      parameters: {'plan': plan},
    );
    debugPrint('[Analytics] Subscription started: $plan');
  }

  /// Log subscription cancelled
  static Future<void> logSubscriptionCancelled(String plan) async {
    if (!isEnabled) return;

    await _analytics.logEvent(
      name: 'subscription_cancelled',
      parameters: {'plan': plan},
    );
    debugPrint('[Analytics] Subscription cancelled: $plan');
  }

  /// Log app update
  static Future<void> logAppUpdate(String version) async {
    if (!isEnabled) return;

    await _analytics.logEvent(
      name: 'app_update',
      parameters: {'version': version},
    );
    debugPrint('[Analytics] App updated to: $version');
  }

  /// Log critical error
  static Future<void> logCriticalError(String errorType, String message) async {
    if (!isEnabled) return;

    await _analytics.logEvent(
      name: 'critical_error',
      parameters: {
        'error_type': errorType,
        'message': message.substring(0, message.length > 100 ? 100 : message.length),
      },
    );
    debugPrint('[Analytics] Critical error: $errorType - $message');
  }

  // Sampling tracking (not every action needs to be tracked)

  static DateTime? _lastGlucoseLog;

  /// Log glucose recorded (once per day to avoid spam)
  static Future<void> logGlucoseRecorded() async {
    if (!isEnabled) return;

    final now = DateTime.now();
    if (_lastGlucoseLog == null ||
        now.difference(_lastGlucoseLog!).inHours >= 24) {
      await _analytics.logEvent(name: 'glucose_recorded');
      _lastGlucoseLog = now;
      debugPrint('[Analytics] Glucose recorded (sampled)');
    }
  }

  static DateTime? _lastDiaryLog;

  /// Log diary created (once per day to avoid spam)
  static Future<void> logDiaryCreated() async {
    if (!isEnabled) return;

    final now = DateTime.now();
    if (_lastDiaryLog == null ||
        now.difference(_lastDiaryLog!).inHours >= 24) {
      await _analytics.logEvent(name: 'diary_created');
      _lastDiaryLog = now;
      debugPrint('[Analytics] Diary created (sampled)');
    }
  }

  /// Get Firebase Analytics observer for navigation tracking
  static FirebaseAnalyticsObserver getObserver() {
    return FirebaseAnalyticsObserver(analytics: _analytics);
  }

  // ============================================================================
  // User Action Tracking
  // ============================================================================

  /// Log tab navigation (Home, Diary, Report, Settings)
  static Future<void> logTabNavigation(String tabName) async {
    if (!isEnabled) return;

    await _analytics.logEvent(
      name: 'tab_navigation',
      parameters: {'tab': tabName},
    );
    debugPrint('[Analytics] Tab navigation: $tabName');
  }

  /// Log glucose entry started
  static Future<void> logGlucoseEntryStarted() async {
    if (!isEnabled) return;

    await _analytics.logEvent(name: 'glucose_entry_started');
    debugPrint('[Analytics] Glucose entry started');
  }

  /// Log glucose entry saved
  static Future<void> logGlucoseEntrySaved() async {
    if (!isEnabled) return;

    await _analytics.logEvent(name: 'glucose_entry_saved');
    debugPrint('[Analytics] Glucose entry saved');
  }

  /// Log diary entry started
  static Future<void> logDiaryEntryStarted() async {
    if (!isEnabled) return;

    await _analytics.logEvent(name: 'diary_entry_started');
    debugPrint('[Analytics] Diary entry started');
  }

  /// Log diary entry saved
  static Future<void> logDiaryEntrySaved() async {
    if (!isEnabled) return;

    await _analytics.logEvent(name: 'diary_entry_saved');
    debugPrint('[Analytics] Diary entry saved');
  }

  /// Log diary entry edited
  static Future<void> logDiaryEntryEdited() async {
    if (!isEnabled) return;

    await _analytics.logEvent(name: 'diary_entry_edited');
    debugPrint('[Analytics] Diary entry edited');
  }

  /// Log diary entry deleted
  static Future<void> logDiaryEntryDeleted() async {
    if (!isEnabled) return;

    await _analytics.logEvent(name: 'diary_entry_deleted');
    debugPrint('[Analytics] Diary entry deleted');
  }

  /// Log report generation started
  static Future<void> logReportGenerationStarted() async {
    if (!isEnabled) return;

    await _analytics.logEvent(name: 'report_generation_started');
    debugPrint('[Analytics] Report generation started');
  }

  /// Log report viewed
  static Future<void> logReportViewed() async {
    if (!isEnabled) return;

    await _analytics.logEvent(name: 'report_viewed');
    debugPrint('[Analytics] Report viewed');
  }

  /// Log settings changed
  static Future<void> logSettingChanged(String settingName, String value) async {
    if (!isEnabled) return;

    await _analytics.logEvent(
      name: 'setting_changed',
      parameters: {
        'setting': settingName,
        'value': value,
      },
    );
    debugPrint('[Analytics] Setting changed: $settingName = $value');
  }

  /// Log photo added to diary
  static Future<void> logPhotoAdded() async {
    if (!isEnabled) return;

    await _analytics.logEvent(name: 'photo_added');
    debugPrint('[Analytics] Photo added');
  }

  /// Log meal record added
  static Future<void> logMealRecordAdded() async {
    if (!isEnabled) return;

    await _analytics.logEvent(name: 'meal_record_added');
    debugPrint('[Analytics] Meal record added');
  }

  // ============================================================================
  // Detailed User Actions (Home, Feed, Diary, Report, Settings)
  // ============================================================================

  /// Log date picker opened in Home tab
  static Future<void> logDatePickerOpened() async {
    if (!isEnabled) return;

    await _analytics.logEvent(name: 'date_picker_opened');
    debugPrint('[Analytics] Date picker opened');
  }

  /// Log date selected in Home tab
  static Future<void> logDateSelected(String date) async {
    if (!isEnabled) return;

    await _analytics.logEvent(
      name: 'date_selected',
      parameters: {'date': date},
    );
    debugPrint('[Analytics] Date selected: $date');
  }

  /// Log manual glucose input opened in Feed tab
  static Future<void> logManualGlucoseInputOpened() async {
    if (!isEnabled) return;

    await _analytics.logEvent(name: 'manual_glucose_input_opened');
    debugPrint('[Analytics] Manual glucose input opened');
  }

  /// Log manual glucose saved in Feed tab
  static Future<void> logManualGlucoseSaved() async {
    if (!isEnabled) return;

    await _analytics.logEvent(name: 'manual_glucose_saved');
    debugPrint('[Analytics] Manual glucose saved');
  }

  /// Log insulin input opened in Feed tab
  static Future<void> logInsulinInputOpened() async {
    if (!isEnabled) return;

    await _analytics.logEvent(name: 'insulin_input_opened');
    debugPrint('[Analytics] Insulin input opened');
  }

  /// Log insulin saved in Feed tab
  static Future<void> logInsulinSaved() async {
    if (!isEnabled) return;

    await _analytics.logEvent(name: 'insulin_saved');
    debugPrint('[Analytics] Insulin saved');
  }

  /// Log diary input opened in Diary tab
  static Future<void> logDiaryInputOpened() async {
    if (!isEnabled) return;

    await _analytics.logEvent(name: 'diary_input_opened');
    debugPrint('[Analytics] Diary input opened');
  }

  /// Log diary saved in Diary tab
  static Future<void> logDiarySaved() async {
    if (!isEnabled) return;

    await _analytics.logEvent(name: 'diary_saved');
    debugPrint('[Analytics] Diary saved');
  }

  /// Log diary photo added
  static Future<void> logDiaryPhotoAdded() async {
    if (!isEnabled) return;

    await _analytics.logEvent(name: 'diary_photo_added');
    debugPrint('[Analytics] Diary photo added');
  }

  /// Log diary edited
  static Future<void> logDiaryEdited() async {
    if (!isEnabled) return;

    await _analytics.logEvent(name: 'diary_edited');
    debugPrint('[Analytics] Diary edited');
  }

  /// Log diary deleted
  static Future<void> logDiaryDeleted() async {
    if (!isEnabled) return;

    await _analytics.logEvent(name: 'diary_deleted');
    debugPrint('[Analytics] Diary deleted');
  }

  /// Log report generation button tapped
  static Future<void> logReportGenerationButtonTapped() async {
    if (!isEnabled) return;

    await _analytics.logEvent(name: 'report_generation_button_tapped');
    debugPrint('[Analytics] Report generation button tapped');
  }

  /// Log report info popup opened
  static Future<void> logReportInfoPopupOpened() async {
    if (!isEnabled) return;

    await _analytics.logEvent(name: 'report_info_popup_opened');
    debugPrint('[Analytics] Report info popup opened');
  }

  /// Log past report viewed
  static Future<void> logPastReportViewed(String reportDate) async {
    if (!isEnabled) return;

    await _analytics.logEvent(
      name: 'past_report_viewed',
      parameters: {'report_date': reportDate},
    );
    debugPrint('[Analytics] Past report viewed: $reportDate');
  }

  /// Log settings menu item tapped
  static Future<void> logSettingsMenuTapped(String menuItem) async {
    if (!isEnabled) return;

    await _analytics.logEvent(
      name: 'settings_menu_tapped',
      parameters: {'menu_item': menuItem},
    );
    debugPrint('[Analytics] Settings menu tapped: $menuItem');
  }

  /// Log language changed
  static Future<void> logLanguageChanged(String language) async {
    if (!isEnabled) return;

    await _analytics.logEvent(
      name: 'language_changed',
      parameters: {'language': language},
    );
    debugPrint('[Analytics] Language changed: $language');
  }

  /// Log theme changed
  static Future<void> logThemeChanged(String theme) async {
    if (!isEnabled) return;

    await _analytics.logEvent(
      name: 'theme_changed',
      parameters: {'theme': theme},
    );
    debugPrint('[Analytics] Theme changed: $theme');
  }

  /// Log glucose unit changed
  static Future<void> logGlucoseUnitChanged(String unit) async {
    if (!isEnabled) return;

    await _analytics.logEvent(
      name: 'glucose_unit_changed',
      parameters: {'unit': unit},
    );
    debugPrint('[Analytics] Glucose unit changed: $unit');
  }

  /// Log notification settings changed
  static Future<void> logNotificationSettingsChanged(bool enabled) async {
    if (!isEnabled) return;

    await _analytics.logEvent(
      name: 'notification_settings_changed',
      parameters: {'enabled': enabled},
    );
    debugPrint('[Analytics] Notification settings changed: $enabled');
  }

  // ============================================================================
  // User Properties (국가별, 연령별 집계용)
  // ============================================================================

  /// Set user country (Firebase가 자동 수집하지만 명시적으로 설정 가능)
  static Future<void> setUserCountry(String countryCode) async {
    if (!isEnabled) return;

    await _analytics.setUserProperty(
      name: 'country',
      value: countryCode,
    );
    debugPrint('[Analytics] User country set: $countryCode');
  }

  /// Set user age group (연령대)
  /// 예: "18-24", "25-34", "35-44", "45-54", "55-64", "65+"
  static Future<void> setUserAgeGroup(String ageGroup) async {
    if (!isEnabled) return;

    await _analytics.setUserProperty(
      name: 'age_group',
      value: ageGroup,
    );
    debugPrint('[Analytics] User age group set: $ageGroup');
  }

  /// Set user birth year (출생 연도로 연령 계산 가능)
  static Future<void> setUserBirthYear(int birthYear) async {
    if (!isEnabled) return;

    final age = DateTime.now().year - birthYear;
    final ageGroup = _getAgeGroup(age);

    await _analytics.setUserProperty(
      name: 'birth_year',
      value: birthYear.toString(),
    );
    await _analytics.setUserProperty(
      name: 'age_group',
      value: ageGroup,
    );
    debugPrint('[Analytics] User birth year set: $birthYear (age group: $ageGroup)');
  }

  /// Convert age to age group
  static String _getAgeGroup(int age) {
    if (age < 18) return 'under_18';
    if (age < 25) return '18-24';
    if (age < 35) return '25-34';
    if (age < 45) return '35-44';
    if (age < 55) return '45-54';
    if (age < 65) return '55-64';
    return '65+';
  }

  /// Set user diabetes type
  static Future<void> setUserDiabetesType(String type) async {
    if (!isEnabled) return;

    await _analytics.setUserProperty(
      name: 'diabetes_type',
      value: type,
    );
    debugPrint('[Analytics] User diabetes type set: $type');
  }

  /// Set user subscription status
  static Future<void> setUserSubscriptionStatus(bool isPro) async {
    if (!isEnabled) return;

    await _analytics.setUserProperty(
      name: 'subscription_status',
      value: isPro ? 'pro' : 'free',
    );
    debugPrint('[Analytics] User subscription status set: ${isPro ? 'pro' : 'free'}');
  }

  /// Set user language preference
  static Future<void> setUserLanguage(String languageCode) async {
    if (!isEnabled) return;

    await _analytics.setUserProperty(
      name: 'app_language',
      value: languageCode,
    );
    debugPrint('[Analytics] User language set: $languageCode');
  }
}
