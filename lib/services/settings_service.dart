import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:glu_butler/core/constants/app_constants.dart';
import 'package:glu_butler/models/user_profile.dart';
import 'package:glu_butler/services/database_service.dart';

class SettingsService extends ChangeNotifier {
  late SharedPreferences _prefs;
  final DatabaseService _databaseService = DatabaseService();

  String _language = AppConstants.defaultLanguage;
  String _unit = AppConstants.defaultUnit;
  String _themeMode = AppConstants.themeModeSystem;
  UserProfile _userProfile = UserProfile();
  TimeOfDay _notificationTime = const TimeOfDay(hour: 8, minute: 0);
  bool _isHealthConnected = false;
  bool _isPro = false;
  DateTime? _subscriptionDate;
  int _syncPeriod = AppConstants.defaultSyncPeriod;

  String get language => _language;
  String get unit => _unit;
  String get themeMode => _themeMode;
  UserProfile get userProfile => _userProfile;
  TimeOfDay get notificationTime => _notificationTime;
  bool get isHealthConnected => _isHealthConnected;
  bool get isPro => _isPro;
  DateTime? get subscriptionDate => _subscriptionDate;
  int get syncPeriod => _syncPeriod;

  ThemeMode get flutterThemeMode {
    switch (_themeMode) {
      case AppConstants.themeModeLight:
        return ThemeMode.light;
      case AppConstants.themeModeDark:
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Locale get locale => Locale(_language);

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadSettings();
  }

  Future<void> _loadSettings() async {
    _language = _prefs.getString(AppConstants.keyLanguage) ?? AppConstants.defaultLanguage;
    _unit = _prefs.getString(AppConstants.keyUnit) ?? AppConstants.defaultUnit;
    _themeMode = _prefs.getString(AppConstants.keyThemeMode) ?? AppConstants.themeModeSystem;
    _isHealthConnected = _prefs.getBool(AppConstants.keyHealthConnected) ?? false;

    final profileJson = _prefs.getString(AppConstants.keyUserProfile);
    if (profileJson != null) {
      _userProfile = UserProfile.fromJson(jsonDecode(profileJson));
    }

    final notificationTimeString = _prefs.getString(AppConstants.keyNotificationTime);
    if (notificationTimeString != null) {
      final parts = notificationTimeString.split(':');
      _notificationTime = TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    }

    _isPro = _prefs.getBool(AppConstants.keyIsPro) ?? false;
    final subscriptionDateString = _prefs.getString(AppConstants.keySubscriptionDate);
    if (subscriptionDateString != null) {
      _subscriptionDate = DateTime.tryParse(subscriptionDateString);
    }

    _syncPeriod = _prefs.getInt(AppConstants.keySyncPeriod) ?? AppConstants.defaultSyncPeriod;

    notifyListeners();
  }

  Future<void> setLanguage(String language) async {
    if (!AppConstants.supportedLanguages.contains(language)) return;
    _language = language;
    await _prefs.setString(AppConstants.keyLanguage, language);
    notifyListeners();
  }

  Future<void> setUnit(String unit) async {
    if (unit != AppConstants.unitMgDl && unit != AppConstants.unitMmolL) return;
    _unit = unit;
    await _prefs.setString(AppConstants.keyUnit, unit);
    notifyListeners();
  }

  Future<void> setThemeMode(String mode) async {
    if (mode != AppConstants.themeModeSystem &&
        mode != AppConstants.themeModeLight &&
        mode != AppConstants.themeModeDark) return;
    _themeMode = mode;
    await _prefs.setString(AppConstants.keyThemeMode, mode);
    notifyListeners();
  }

  Future<void> setUserProfile(UserProfile profile) async {
    _userProfile = profile;
    await _prefs.setString(AppConstants.keyUserProfile, jsonEncode(profile.toJson()));
    notifyListeners();
  }

  Future<void> setNotificationTime(TimeOfDay time) async {
    _notificationTime = time;
    await _prefs.setString(
      AppConstants.keyNotificationTime,
      '${time.hour}:${time.minute}',
    );
    notifyListeners();
  }

  Future<void> setHealthConnected(bool connected) async {
    _isHealthConnected = connected;
    await _prefs.setBool(AppConstants.keyHealthConnected, connected);
    notifyListeners();
  }

  Future<void> setProStatus(bool isPro) async {
    _isPro = isPro;
    await _prefs.setBool(AppConstants.keyIsPro, isPro);
    if (isPro && _subscriptionDate == null) {
      _subscriptionDate = DateTime.now();
      await _prefs.setString(
        AppConstants.keySubscriptionDate,
        _subscriptionDate!.toIso8601String(),
      );
    } else if (!isPro) {
      _subscriptionDate = null;
      await _prefs.remove(AppConstants.keySubscriptionDate);
    }
    notifyListeners();
  }

  Future<void> setSyncPeriod(int days) async {
    if (days != AppConstants.syncPeriod1Week &&
        days != AppConstants.syncPeriod2Weeks &&
        days != AppConstants.syncPeriod1Month &&
        days != AppConstants.syncPeriod3Months) return;
    _syncPeriod = days;
    await _prefs.setInt(AppConstants.keySyncPeriod, days);

    // Update sync period in database
    await _databaseService.updateSyncPeriod(days);

    notifyListeners();
  }
}
