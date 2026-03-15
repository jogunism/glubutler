import 'dart:io';
import 'package:flutter/services.dart';

class AppSettingsService {
  static const _iosChannel = MethodChannel('app_settings');
  static const _androidChannel = MethodChannel('com.jogunism.gluButler/locale_settings');

  static Future<void> openAppSettings() async {
    try {
      if (Platform.isAndroid) {
        await _androidChannel.invokeMethod('openLocaleSettings');
      } else {
        await _iosChannel.invokeMethod('openAppSettings');
      }
    } catch (e) {
      // Ignore all errors - don't crash the app
    }
  }
}
