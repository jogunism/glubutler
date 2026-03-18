import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:glu_butler/core/theme/app_theme.dart';
import 'package:glu_butler/core/constants/app_constants.dart';
import 'package:glu_butler/features/onboarding/widgets/onboarding_primary_button.dart';
import 'package:glu_butler/services/settings_service.dart';
import 'package:glu_butler/services/health_service.dart';
import 'package:glu_butler/services/database_service.dart';
import 'package:glu_butler/providers/feed_provider.dart';
import 'package:glu_butler/services/analytics_service.dart';
import 'package:glu_butler/l10n/app_localizations.dart';

/// 건강 데이터 권한 페이지
/// iOS: Apple Health (HealthKit) - 성별/생년월일 자동 가져오기
/// Android: Health Connect + 성별/생년월일 직접 입력
class HealthPermissionPage extends StatefulWidget {
  final VoidCallback onNext;

  const HealthPermissionPage({
    super.key,
    required this.onNext,
  });

  @override
  State<HealthPermissionPage> createState() => _HealthPermissionPageState();
}

class _HealthPermissionPageState extends State<HealthPermissionPage>
    with WidgetsBindingObserver {
  bool _isRequesting = false;

  // Android 직접 입력 필드
  String? _selectedGender; // 'male' | 'female' | 'other'
  DateTime? _selectedBirthDate;

  // Android HC 설치 상태: null=체크중, 'available', 'needsUpdate', 'unavailable'
  String? _hcStatus;
  // Play Store로 이동했는지 (복귀 시 재체크용)
  bool _wentToPlayStore = false;

  @override
  void initState() {
    super.initState();
    if (Platform.isAndroid) {
      WidgetsBinding.instance.addObserver(this);
      _checkHcStatus();
    }
  }

  @override
  void dispose() {
    if (Platform.isAndroid) {
      WidgetsBinding.instance.removeObserver(this);
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Play Store에서 설치/업데이트 후 복귀하면 상태 재확인
    if (state == AppLifecycleState.resumed && _wentToPlayStore) {
      _wentToPlayStore = false;
      _checkHcStatus();
    }
  }

  Future<void> _checkHcStatus() async {
    setState(() => _hcStatus = null); // 로딩 중
    final status = await HealthService().checkHealthConnectAvailability();
    if (mounted) {
      setState(() => _hcStatus = status);
    }
  }

  Future<void> _openPlayStore() async {
    _wentToPlayStore = true;
    const url =
        'https://play.google.com/store/apps/details?id=com.google.android.apps.healthdata';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // ---------------------------------------------------------------------------
  // Android: Health Connect 권한 요청 + 직접 입력 저장
  // ---------------------------------------------------------------------------

  Future<void> _requestHealthPermissionAndroid() async {
    setState(() => _isRequesting = true);
    try {
      final feedProvider = context.read<FeedProvider>();
      final granted = await feedProvider.connectToHealth();

      if (mounted) {
        final settings = context.read<SettingsService>();
        await AnalyticsService.logHealthConnected(success: granted);

        if (_selectedGender != null) {
          await settings.setGender(_selectedGender!);
        }
        if (_selectedBirthDate != null) {
          await settings.setBirthDate(_selectedBirthDate!);
          await _applyTextScaleFromBirthDate(settings, _selectedBirthDate!);
          await AnalyticsService.setUserBirthYear(_selectedBirthDate!.year);
        }

        setState(() => _isRequesting = false);

        widget.onNext();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isRequesting = false);
        widget.onNext();
      }
    }
  }

  Future<void> _saveUserInfoAndSkip() async {
    final settings = context.read<SettingsService>();
    if (_selectedGender != null) await settings.setGender(_selectedGender!);
    if (_selectedBirthDate != null) {
      await settings.setBirthDate(_selectedBirthDate!);
      await _applyTextScaleFromBirthDate(settings, _selectedBirthDate!);
      await AnalyticsService.setUserBirthYear(_selectedBirthDate!.year);
    }
    widget.onNext();
  }

  Future<void> _applyTextScaleFromBirthDate(
      SettingsService settings, DateTime birthDate) async {
    final now = DateTime.now();
    final age = now.year -
        birthDate.year -
        (now.month < birthDate.month ||
                (now.month == birthDate.month && now.day < birthDate.day)
            ? 1
            : 0);
    double textScale;
    if (age < 40) {
      textScale = AppConstants.textScaleSmall;
    } else if (age < 50) {
      textScale = AppConstants.textScaleMedium;
    } else {
      textScale = AppConstants.textScaleLarge;
    }
    await settings.setTextScale(textScale);
  }

  Future<void> _pickBirthDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthDate ?? DateTime(1980),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedBirthDate = picked);
    }
  }

  // ---------------------------------------------------------------------------
  // iOS: 기존 HealthKit 권한 요청
  // ---------------------------------------------------------------------------

  Future<void> _requestHealthPermission() async {
    setState(() {
      _isRequesting = true;
    });

    try {
      final healthService = HealthService();

      // HealthKit 권한 요청 및 성별/생년월일 가져오기
      final result = await healthService.requestAuthorizationWithCharacteristics();

      final granted = result['granted'] as bool;
      final biologicalSex = result['biologicalSex'] as String?;
      final dateOfBirth = result['dateOfBirth'] as String?;
      final weightKg = result['weightKg'] as double?;

      if (mounted) {
        final settings = context.read<SettingsService>();
        await settings.setHealthConnected(granted);

        // Log health connection
        await AnalyticsService.logHealthConnected(success: granted);

        // DatabaseService에도 health connection 저장
        if (granted) {
          final databaseService = DatabaseService();
          final now = DateTime.now();
          final healthConnection = HealthConnectionInfo(
            isConnected: true,
            syncPeriodDays: AppConstants.defaultSyncPeriod,
            connectedAt: now,
            updatedAt: now,
          );
          await databaseService.saveHealthConnection(healthConnection);
        }

        // 성별 저장
        if (biologicalSex != null) {
          await settings.setGender(biologicalSex);
        }

        // 체중 저장
        if (weightKg != null) {
          await settings.setWeight(weightKg);
        }

        // 생년월일 저장 및 나이별 폰트 크기 자동 설정
        if (dateOfBirth != null) {
          try {
            final birthDate = DateTime.parse(dateOfBirth);
            await settings.setBirthDate(birthDate);

            final now = DateTime.now();
            final age = now.year -
                birthDate.year -
                (now.month < birthDate.month ||
                        (now.month == birthDate.month &&
                            now.day < birthDate.day)
                    ? 1
                    : 0);

            double textScale;
            if (age < 40) {
              textScale = AppConstants.textScaleSmall;
            } else if (age < 50) {
              textScale = AppConstants.textScaleMedium;
            } else {
              textScale = AppConstants.textScaleLarge;
            }

            await settings.setTextScale(textScale);
            await AnalyticsService.setUserBirthYear(birthDate.year);

            debugPrint(
                '[HealthPermissionPage] Age: $age, Text scale set to: $textScale');
          } catch (e) {
            debugPrint('[HealthPermissionPage] Error parsing birth date: $e');
          }
        }

        setState(() {
          _isRequesting = false;
        });

        widget.onNext();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isRequesting = false;
        });
        widget.onNext();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      return _buildIOS(context);
    } else {
      return _buildAndroid(context);
    }
  }

  // ---------------------------------------------------------------------------
  // iOS UI: Apple Health 이미지 + 권한 요청 버튼
  // ---------------------------------------------------------------------------

  Widget _buildIOS(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final screenWidth = MediaQuery.of(context).size.width;
    final imageWidth = screenWidth * 0.7;
    final imageHeight = imageWidth * 1.43;

    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Text(l10n.onboardingHealthTitle,
                  style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary(context),
                      height: 1.2,
                      letterSpacing: -0.5)),
              const SizedBox(height: 12),
              Text(l10n.onboardingHealthSubtitle,
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: AppTheme.textSecondary(context),
                      height: 1.4,
                      letterSpacing: -0.3)),
              const SizedBox(height: 32),
              Center(
                child: SizedBox(
                  width: imageWidth,
                  height: imageHeight,
                  child: Image.asset('assets/images/screen_apple_health.png',
                      fit: BoxFit.cover),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
        Positioned(
          left: 24,
          right: 24,
          bottom: 24,
          child: OnboardingPrimaryButton(
            text: l10n.onboardingNext,
            onPressed: _requestHealthPermission,
            isLoading: _isRequesting,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Android UI: HC 상태에 따라 분기
  // ---------------------------------------------------------------------------

  Widget _buildAndroid(BuildContext context) {
    final status = _hcStatus;

    // 체크 중
    if (status == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // HC 미설치 또는 업데이트 필요
    if (status == 'unavailable' || status == 'needsUpdate') {
      return _buildHcNotAvailable(context, needsUpdate: status == 'needsUpdate');
    }

    // HC 사용 가능 → 기존 연동 UI
    return _buildHcAvailable(context);
  }

  /// HC 미설치/업데이트 필요 화면
  Widget _buildHcNotAvailable(BuildContext context, {required bool needsUpdate}) {
    final l10n = AppLocalizations.of(context)!;

    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Text(
                l10n.onboardingHealthTitleAndroid,
                style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary(context),
                    height: 1.2,
                    letterSpacing: -0.5),
              ),
              const SizedBox(height: 12),
              Text(
                needsUpdate ? l10n.hcNeedsUpdate : l10n.hcNotInstalled,
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: AppTheme.textSecondary(context),
                    height: 1.4,
                    letterSpacing: -0.3),
              ),
              const SizedBox(height: 32),

              // 성별 선택
              _buildGenderSelector(context, l10n),
              const SizedBox(height: 24),
              // 생년월일 선택
              _buildBirthDateSelector(context, l10n),

              const Spacer(),
            ],
          ),
        ),
        // 하단: 건너뛰기(우측) + 메인 버튼
        Positioned(
          left: 24,
          right: 24,
          bottom: 24,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _saveUserInfoAndSkip,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: Text(
                    l10n.onboardingSkip,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textSecondary(context),
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
              ),
              OnboardingPrimaryButton(
                text: needsUpdate ? l10n.hcUpdateFromPlayStore : l10n.hcInstallFromPlayStore,
                onPressed: _openPlayStore,
                isLoading: false,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// HC 사용 가능 → 성별/생년월일 + 연동 버튼
  Widget _buildHcAvailable(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Text(l10n.onboardingHealthTitleAndroid,
                  style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary(context),
                      height: 1.2,
                      letterSpacing: -0.5)),
              const SizedBox(height: 12),
              Text(l10n.onboardingHealthSubtitleAndroid,
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: AppTheme.textSecondary(context),
                      height: 1.4,
                      letterSpacing: -0.3)),
              const SizedBox(height: 32),

              // 성별 선택
              _buildGenderSelector(context, l10n),
              const SizedBox(height: 24),
              // 생년월일 선택
              _buildBirthDateSelector(context, l10n),

              const Spacer(),
            ],
          ),
        ),
        Positioned(
          left: 24,
          right: 24,
          bottom: 24,
          child: OnboardingPrimaryButton(
            text: l10n.onboardingNext,
            onPressed: _requestHealthPermissionAndroid,
            isLoading: _isRequesting,
          ),
        ),
      ],
    );
  }

  Widget _buildGenderSelector(BuildContext context, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.gender,
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary(context))),
        const SizedBox(height: 8),
        SegmentedButton<String>(
          segments: [
            ButtonSegment(value: 'male', label: Text(l10n.genderMale)),
            ButtonSegment(value: 'female', label: Text(l10n.genderFemale)),
            ButtonSegment(value: 'other', label: Text(l10n.genderOther)),
          ],
          selected: _selectedGender != null ? {_selectedGender!} : {},
          emptySelectionAllowed: true,
          onSelectionChanged: (val) =>
              setState(() => _selectedGender = val.firstOrNull),
        ),
      ],
    );
  }

  Widget _buildBirthDateSelector(BuildContext context, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.birthDate,
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary(context))),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _pickBirthDate,
          icon: const Icon(Icons.calendar_today, size: 18),
          label: Text(
            _selectedBirthDate != null
                ? '${_selectedBirthDate!.year}.${_selectedBirthDate!.month.toString().padLeft(2, '0')}.${_selectedBirthDate!.day.toString().padLeft(2, '0')}'
                : l10n.selectDate,
            style: const TextStyle(fontSize: 15),
          ),
        ),
      ],
    );
  }
}
