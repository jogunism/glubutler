import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'package:glu_butler/core/constants/app_constants.dart';
import 'package:glu_butler/models/user_profile.dart';
import 'package:glu_butler/models/glucose_range_settings.dart';
import 'package:glu_butler/models/user_identity.dart';
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
  GlucoseRangeSettings _glucoseRange = const GlucoseRangeSettings();
  DateTime? _serviceStartDate;
  bool _hapticEnabled = AppConstants.defaultHapticEnabled;
  UserIdentity? _userIdentity;

  String get language => _language;
  String get unit => _unit;
  String get themeMode => _themeMode;
  UserProfile get userProfile => _userProfile;
  TimeOfDay get notificationTime => _notificationTime;
  bool get isHealthConnected => _isHealthConnected;
  bool get isPro => _isPro;
  DateTime? get subscriptionDate => _subscriptionDate;
  int get syncPeriod => _syncPeriod;
  GlucoseRangeSettings get glucoseRange => _glucoseRange;
  DateTime? get serviceStartDate => _serviceStartDate;
  bool get hapticEnabled => _hapticEnabled;
  UserIdentity get userIdentity => _userIdentity ?? UserIdentity(deviceId: 'unknown');

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

    // Load glucose range settings (5단계)
    _glucoseRange = GlucoseRangeSettings(
      veryLow: _prefs.getDouble(AppConstants.keyGlucoseVeryLow) ?? AppConstants.defaultVeryLow,
      low: _prefs.getDouble(AppConstants.keyGlucoseLow) ?? AppConstants.defaultLow,
      target: _prefs.getDouble(AppConstants.keyGlucoseTarget) ?? AppConstants.defaultTarget,
      high: _prefs.getDouble(AppConstants.keyGlucoseHigh) ?? AppConstants.defaultHigh,
      veryHigh: _prefs.getDouble(AppConstants.keyGlucoseVeryHigh) ?? AppConstants.defaultVeryHigh,
    );

    // Load or initialize service start date
    final serviceStartDateString = _prefs.getString(AppConstants.keyServiceStartDate);
    if (serviceStartDateString != null) {
      _serviceStartDate = DateTime.tryParse(serviceStartDateString);
    } else {
      // 첫 실행: 현재 날짜를 서비스 시작일로 저장
      final now = DateTime.now();
      _serviceStartDate = DateTime(now.year, now.month, now.day);
      await _prefs.setString(
        AppConstants.keyServiceStartDate,
        _serviceStartDate!.toIso8601String(),
      );
      debugPrint('[SettingsService] Service start date initialized: $_serviceStartDate');
    }

    _hapticEnabled = _prefs.getBool(AppConstants.keyHapticEnabled) ?? AppConstants.defaultHapticEnabled;

    // Load or generate UserIdentity
    final userIdentityJson = _prefs.getString(AppConstants.keyUserIdentity);
    if (userIdentityJson != null) {
      try {
        _userIdentity = UserIdentity.fromJson(jsonDecode(userIdentityJson));
        debugPrint('[SettingsService] UserIdentity loaded: $_userIdentity');
      } catch (e) {
        debugPrint('[SettingsService] Error loading UserIdentity: $e');
        _userIdentity = null;
      }
    }

    // 첫 실행이거나 로드 실패: 새 UserIdentity 생성
    if (_userIdentity == null) {
      final deviceId = const Uuid().v7(); // UUIDv7 생성
      _userIdentity = UserIdentity(deviceId: deviceId);
      await _prefs.setString(
        AppConstants.keyUserIdentity,
        jsonEncode(_userIdentity!.toJson()),
      );
      debugPrint('[SettingsService] UserIdentity created: $_userIdentity');
    }

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

  Future<void> setGlucoseRange(GlucoseRangeSettings range) async {
    _glucoseRange = range;
    await _prefs.setDouble(AppConstants.keyGlucoseVeryLow, range.veryLow);
    await _prefs.setDouble(AppConstants.keyGlucoseLow, range.low);
    await _prefs.setDouble(AppConstants.keyGlucoseTarget, range.target);
    await _prefs.setDouble(AppConstants.keyGlucoseHigh, range.high);
    await _prefs.setDouble(AppConstants.keyGlucoseVeryHigh, range.veryHigh);
    notifyListeners();
  }

  Future<void> updateUserProfile(UserProfile profile) async {
    _userProfile = profile;
    await _prefs.setString(
      AppConstants.keyUserProfile,
      jsonEncode(profile.toJson()),
    );
    notifyListeners();
  }

  Future<void> setHapticEnabled(bool enabled) async {
    // 켤 때만 햅틱 피드백 제공
    if (enabled) {
      HapticFeedback.lightImpact(); // "툭" when turning on
    }
    _hapticEnabled = enabled;
    await _prefs.setBool(AppConstants.keyHapticEnabled, enabled);
    notifyListeners();
  }

  /// CloudKit User ID 업데이트
  ///
  /// iCloud 연동 시 호출
  Future<void> updateCloudKitId(String cloudKitId) async {
    if (_userIdentity == null) return;

    _userIdentity = _userIdentity!.withCloudKitId(cloudKitId);
    await _prefs.setString(
      AppConstants.keyUserIdentity,
      jsonEncode(_userIdentity!.toJson()),
    );
    debugPrint('[SettingsService] CloudKit ID updated: $cloudKitId');
    notifyListeners();
  }

  /// Receipt Transaction ID 업데이트
  ///
  /// 유료 구독 시 호출
  Future<void> updateReceiptId(String receiptId) async {
    if (_userIdentity == null) return;

    _userIdentity = _userIdentity!.withReceiptId(receiptId);
    await _prefs.setString(
      AppConstants.keyUserIdentity,
      jsonEncode(_userIdentity!.toJson()),
    );
    debugPrint('[SettingsService] Receipt ID updated: $receiptId');
    notifyListeners();
  }
}
