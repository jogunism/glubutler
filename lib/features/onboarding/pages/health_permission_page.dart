import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:glu_butler/core/theme/app_theme.dart';
import 'package:glu_butler/core/constants/app_constants.dart';
import 'package:glu_butler/features/onboarding/widgets/onboarding_primary_button.dart';
import 'package:glu_butler/services/settings_service.dart';
import 'package:glu_butler/services/health_service.dart';
import 'package:glu_butler/services/database_service.dart';
import 'package:glu_butler/services/analytics_service.dart';
import 'package:glu_butler/l10n/app_localizations.dart';

/// Apple Health permission page
class HealthPermissionPage extends StatefulWidget {
  final VoidCallback onNext;

  const HealthPermissionPage({
    super.key,
    required this.onNext,
  });

  @override
  State<HealthPermissionPage> createState() => _HealthPermissionPageState();
}

class _HealthPermissionPageState extends State<HealthPermissionPage> {
  bool _isRequesting = false;

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

            // 나이 계산
            final now = DateTime.now();
            final age = now.year - birthDate.year -
                (now.month < birthDate.month ||
                 (now.month == birthDate.month && now.day < birthDate.day) ? 1 : 0);

            // 나이대별 폰트 크기 설정
            double textScale;
            if (age < 40) {
              textScale = AppConstants.textScaleSmall; // 30대까지: 작게 (0.85)
            } else if (age < 50) {
              textScale = AppConstants.textScaleMedium; // 40대: 보통 (1.0)
            } else {
              textScale = AppConstants.textScaleLarge; // 50대 이상: 크게 (1.15)
            }

            await settings.setTextScale(textScale);
            debugPrint('[HealthPermissionPage] Age: $age, Text scale set to: $textScale');
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
    final l10n = AppLocalizations.of(context)!;
    final screenWidth = MediaQuery.of(context).size.width;

    // 화면 크기에 따라 동적으로 조정 (welcome_page와 동일)
    final imageWidth = screenWidth * 0.7;
    final imageHeight = imageWidth * 1.43;

    return Stack(
      children: [
        // Main content
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // Title
              Text(
                l10n.onboardingHealthTitle,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary(context),
                  height: 1.2,
                  letterSpacing: -0.5,
                ),
              ),

              const SizedBox(height: 12),

              // Subtitle
              Text(
                l10n.onboardingHealthSubtitle,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: AppTheme.textSecondary(context),
                  height: 1.4,
                  letterSpacing: -0.3,
                ),
              ),

              const SizedBox(height: 32),

              // Image - matching welcome page position and size
              Center(
                child: SizedBox(
                  width: imageWidth,
                  height: imageHeight,
                  child: Image.asset(
                    'assets/images/screen_apple_health.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              const Spacer(),
            ],
          ),
        ),

        // Button positioned at bottom
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
}
