import 'package:flutter/services.dart';

class AppSettingsService {
  static const _channel = MethodChannel('app_settings');

  static Future<void> openAppSettings() async {
    try {
      await _channel.invokeMethod('openAppSettings');
    } catch (e) {
      // Ignore all errors - don't crash the app
    }
  }
}
