import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:glu_butler/core/theme/app_theme.dart';
import 'package:glu_butler/features/onboarding/widgets/onboarding_primary_button.dart';
import 'package:glu_butler/services/settings_service.dart';
import 'package:glu_butler/services/health_service.dart';
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
      final granted = await healthService.requestAuthorization();

      if (mounted) {
        final settings = context.read<SettingsService>();
        await settings.setHealthConnected(granted);

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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Skip button
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: widget.onNext,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: Text(
                    l10n.onboardingSkip,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textSecondary(context),
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 0),

              // Connect button
              OnboardingPrimaryButton(
                text: l10n.onboardingHealthConnect,
                onPressed: _requestHealthPermission,
                isLoading: _isRequesting,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
