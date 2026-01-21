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
}
