import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';

import 'package:glu_butler/core/constants/app_constants.dart';
import 'package:glu_butler/models/user_profile.dart';
import 'package:glu_butler/models/glucose_range_settings.dart';
import 'package:glu_butler/models/user_identity.dart';
import 'package:glu_butler/services/database_service.dart';
import 'package:glu_butler/services/cloudkit_service.dart';

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
  bool _iCloudSyncEnabled = false;
  bool _hasCompletedOnboarding = false;
  String? _diabetesType;
  double? _fastingGlucoseTarget;
  double _textScale = AppConstants.defaultTextScale;
  bool _isTrialUser = false;

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
  UserIdentity get userIdentity => _userIdentity ?? const UserIdentity();
  bool get iCloudSyncEnabled => _iCloudSyncEnabled;
  bool get hasCompletedOnboarding => _hasCompletedOnboarding;
  String? get diabetesType => _diabetesType;
  double? get fastingGlucoseTarget => _fastingGlucoseTarget;
  double get textScale => _textScale;
  bool get isTrialUser => _isTrialUser;

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
    // 현재 시스템/앱별 언어 감지 (platformDispatcher.locale은 앱별 언어 우선 반영)
    final systemLocale = WidgetsBinding.instance.platformDispatcher.locale;
    final systemLanguage = systemLocale.languageCode;

    // 저장된 언어 확인
    final savedLanguage = _prefs.getString(AppConstants.keyLanguage);

    // 1단계: iCloud에서 언어 가져오기 시도 (다른 기기에서 복원 시)
    String? iCloudLanguage;
    try {
      iCloudLanguage = await CloudKitService.fetchLanguage();
      if (iCloudLanguage != null && iCloudLanguage.isNotEmpty) {
        debugPrint('[SettingsService] Language fetched from iCloud: $iCloudLanguage');
      }
    } catch (e) {
      debugPrint('[SettingsService] Failed to fetch language from iCloud: $e');
    }

    // 2단계: 언어 우선순위 결정
    // 우선순위: 시스템 언어 변경 > 저장된 언어 > iCloud 언어 > 기본 언어

    // 시스템 언어가 변경되었는지 확인 (iOS 설정에서 언어 변경)
    if (savedLanguage != null && savedLanguage != systemLanguage) {
      // 사용자가 iOS 설정에서 언어를 변경한 경우
      if (AppConstants.supportedLanguages.contains(systemLanguage)) {
        _language = systemLanguage;
      } else {
        _language = AppConstants.defaultLanguage;
      }

      // 업데이트된 언어 저장
      await _prefs.setString(AppConstants.keyLanguage, _language);

      // iCloud에도 저장
      try {
        await CloudKitService.saveLanguage(_language);
        debugPrint('[SettingsService] Language changed via iOS settings, synced to iCloud: $_language');
      } catch (e) {
        debugPrint('[SettingsService] Failed to sync language to iCloud: $e');
      }
    } else if (savedLanguage != null) {
      // 저장된 언어가 있고 시스템 언어와 일치하면 그대로 사용
      _language = savedLanguage;
    } else if (iCloudLanguage != null &&
        iCloudLanguage.isNotEmpty &&
        AppConstants.supportedLanguages.contains(iCloudLanguage)) {
      // 저장된 언어가 없으면 iCloud 언어 사용 (다른 기기에서 복원 시)
      _language = iCloudLanguage;

      // 로컬에도 저장
      await _prefs.setString(AppConstants.keyLanguage, _language);
      debugPrint('[SettingsService] Language restored from iCloud: $_language');
    } else {
      // 모든 것이 없으면 시스템 언어 또는 기본 언어 사용
      if (AppConstants.supportedLanguages.contains(systemLanguage)) {
        _language = systemLanguage;
      } else {
        _language = AppConstants.defaultLanguage;
      }

      // 저장
      await _prefs.setString(AppConstants.keyLanguage, _language);

      // iCloud에도 저장
      try {
        await CloudKitService.saveLanguage(_language);
        debugPrint('[SettingsService] Initial language setup, synced to iCloud: $_language');
      } catch (e) {
        debugPrint('[SettingsService] Failed to sync language to iCloud: $e');
      }
    }

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
    // iCloud에서 먼저 확인 (무료 체험 기간 우회 방지)
    DateTime? iCloudServiceStartDate;
    try {
      iCloudServiceStartDate = await CloudKitService.fetchServiceStartDate();
      if (iCloudServiceStartDate != null) {
        debugPrint('[SettingsService] Service start date fetched from iCloud: $iCloudServiceStartDate');
      }
    } catch (e) {
      debugPrint('[SettingsService] Failed to fetch service start date from iCloud: $e');
    }

    final serviceStartDateString = _prefs.getString(AppConstants.keyServiceStartDate);
    DateTime? localServiceStartDate;
    if (serviceStartDateString != null) {
      localServiceStartDate = DateTime.tryParse(serviceStartDateString);
    }

    // 우선순위: 더 오래된 날짜 사용 (먼저 설치한 날짜)
    if (localServiceStartDate != null && iCloudServiceStartDate != null) {
      // 둘 다 있으면 더 오래된 날짜 사용
      _serviceStartDate = localServiceStartDate.isBefore(iCloudServiceStartDate)
          ? localServiceStartDate
          : iCloudServiceStartDate;

      // 로컬이 더 오래되었으면 iCloud 업데이트
      if (localServiceStartDate.isBefore(iCloudServiceStartDate)) {
        try {
          await CloudKitService.saveServiceStartDate(localServiceStartDate);
          debugPrint('[SettingsService] Updated iCloud with older local service start date: $localServiceStartDate');
        } catch (e) {
          debugPrint('[SettingsService] Failed to update iCloud service start date: $e');
        }
      }
      // iCloud가 더 오래되었으면 로컬 업데이트
      else if (iCloudServiceStartDate.isBefore(localServiceStartDate)) {
        await _prefs.setString(
          AppConstants.keyServiceStartDate,
          iCloudServiceStartDate.toIso8601String(),
        );
        debugPrint('[SettingsService] Updated local with older iCloud service start date: $iCloudServiceStartDate');
      }
    } else if (localServiceStartDate != null) {
      // 로컬에만 있으면 iCloud에 업로드
      _serviceStartDate = localServiceStartDate;
      try {
        await CloudKitService.saveServiceStartDate(localServiceStartDate);
        debugPrint('[SettingsService] Service start date uploaded to iCloud: $localServiceStartDate');
      } catch (e) {
        debugPrint('[SettingsService] Failed to upload service start date to iCloud: $e');
      }
    } else if (iCloudServiceStartDate != null) {
      // iCloud에만 있으면 로컬에 저장
      _serviceStartDate = iCloudServiceStartDate;
      await _prefs.setString(
        AppConstants.keyServiceStartDate,
        iCloudServiceStartDate.toIso8601String(),
      );
      debugPrint('[SettingsService] Service start date restored from iCloud: $iCloudServiceStartDate');
    } else {
      // 둘 다 없으면 첫 실행: 현재 날짜를 서비스 시작일로 저장
      final now = DateTime.now();
      _serviceStartDate = DateTime(now.year, now.month, now.day);
      await _prefs.setString(
        AppConstants.keyServiceStartDate,
        _serviceStartDate!.toIso8601String(),
      );

      // iCloud에도 저장
      try {
        await CloudKitService.saveServiceStartDate(_serviceStartDate!);
        debugPrint('[SettingsService] Initial service start date saved to iCloud: $_serviceStartDate');
      } catch (e) {
        debugPrint('[SettingsService] Failed to save initial service start date to iCloud: $e');
      }
    }

    _hapticEnabled = _prefs.getBool(AppConstants.keyHapticEnabled) ?? AppConstants.defaultHapticEnabled;

    _iCloudSyncEnabled = _prefs.getBool(AppConstants.keyICloudSyncEnabled) ?? false;

    // Load onboarding status
    _hasCompletedOnboarding = _prefs.getBool('has_completed_onboarding') ?? false;
    _diabetesType = _prefs.getString('diabetes_type');
    _fastingGlucoseTarget = _prefs.getDouble('fasting_glucose_target');

    // Load text scale
    _textScale = _prefs.getDouble(AppConstants.keyTextScale) ?? AppConstants.defaultTextScale;

    // Load or generate UserIdentity
    final userIdentityJson = _prefs.getString(AppConstants.keyUserIdentity);
    if (userIdentityJson != null) {
      try {
        _userIdentity = UserIdentity.fromJson(jsonDecode(userIdentityJson));
      } catch (e) {
        _userIdentity = null;
      }
    }

    // 첫 실행이거나 로드 실패: 새 UserIdentity 생성
    if (_userIdentity == null) {
      final idfv = await _getIdfv(); // IDFV 가져오기
      _userIdentity = UserIdentity(
        idfv: idfv,
      );
      await _prefs.setString(
        AppConstants.keyUserIdentity,
        jsonEncode(_userIdentity!.toJson()),
      );
    } else {
      // 기존 UserIdentity가 있지만 IDFV가 없는 경우 업데이트
      if (_userIdentity!.idfv == null) {
        final idfv = await _getIdfv();
        if (idfv != null) {
          _userIdentity = _userIdentity!.withIdfv(idfv);
          await _prefs.setString(
            AppConstants.keyUserIdentity,
            jsonEncode(_userIdentity!.toJson()),
          );
        }
      }
    }

    notifyListeners();
  }

  /// iOS IDFV(Identifier For Vendor) 가져오기
  /// 앱 재설치 시에도 유지되는 기기 고유 ID
  Future<String?> _getIdfv() async {
    try {
      if (Platform.isIOS) {
        final deviceInfo = DeviceInfoPlugin();
        final iosInfo = await deviceInfo.iosInfo;
        return iosInfo.identifierForVendor; // IDFV
      }
      return null; // Android는 IDFV가 없음
    } catch (e) {
      return null;
    }
  }

  Future<void> setLanguage(String language) async {
    if (!AppConstants.supportedLanguages.contains(language)) return;
    _language = language;
    await _prefs.setString(AppConstants.keyLanguage, language);

    // iCloud에도 저장 (언어는 iCloud 동기화 설정과 무관하게 항상 저장)
    try {
      await CloudKitService.saveLanguage(language);
      debugPrint('[SettingsService] Language saved to iCloud: $language');
    } catch (e) {
      debugPrint('[SettingsService] Failed to save language to iCloud: $e');
    }

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
    notifyListeners();
  }

  /// iCloud Sync 상태 설정
  Future<void> setICloudSync(bool enabled) async {
    _iCloudSyncEnabled = enabled;
    await _prefs.setBool(AppConstants.keyICloudSyncEnabled, enabled);
    notifyListeners();
  }

  /// Set user name (for onboarding)
  Future<void> setUserName(String name) async {
    _userProfile = _userProfile.copyWith(name: name);
    await _prefs.setString(AppConstants.keyUserProfile, jsonEncode(_userProfile.toJson()));
    notifyListeners();
  }

  /// Set user gender (for onboarding)
  Future<void> setGender(String gender) async {
    _userProfile = _userProfile.copyWith(gender: gender);
    await _prefs.setString(AppConstants.keyUserProfile, jsonEncode(_userProfile.toJson()));
    notifyListeners();
  }

  /// Set user birth date (for onboarding)
  Future<void> setBirthDate(DateTime birthDate) async {
    _userProfile = _userProfile.copyWith(birthday: birthDate);
    await _prefs.setString(AppConstants.keyUserProfile, jsonEncode(_userProfile.toJson()));
    notifyListeners();
  }

  /// Set diabetes type (for onboarding)
  Future<void> setDiabetesType(String type) async {
    _diabetesType = type;
    await _prefs.setString('diabetes_type', type);

    // UserProfile에도 당뇨 타입 저장
    _userProfile = _userProfile.copyWith(diabetesType: type);
    await _prefs.setString(AppConstants.keyUserProfile, jsonEncode(_userProfile.toJson()));

    notifyListeners();
  }

  /// Set fasting glucose target (for onboarding)
  Future<void> setFastingGlucoseTarget(double value) async {
    _fastingGlucoseTarget = value;
    await _prefs.setDouble('fasting_glucose_target', value);
    notifyListeners();
  }

  /// Mark onboarding as completed
  Future<void> setOnboardingComplete() async {
    _hasCompletedOnboarding = true;
    await _prefs.setBool('has_completed_onboarding', true);
    notifyListeners();
  }

  /// Set text scale
  Future<void> setTextScale(double scale) async {
    if (scale != AppConstants.textScaleSmall &&
        scale != AppConstants.textScaleMedium &&
        scale != AppConstants.textScaleLarge) return;
    _textScale = scale;
    await _prefs.setDouble(AppConstants.keyTextScale, scale);
    notifyListeners();
  }

  /// Update trial user status based on service start date
  /// Called from splash screen on app start
  void updateTrialStatus() {
    if (_serviceStartDate == null) {
      _isTrialUser = false;
      return;
    }

    final now = DateTime.now();
    final daysSinceStart = now.difference(_serviceStartDate!).inDays;
    _isTrialUser = daysSinceStart < 7;

    debugPrint('[SettingsService] Trial status updated: $_isTrialUser (days since start: $daysSinceStart)');
  }

}
