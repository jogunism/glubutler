import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:glu_butler/core/theme/app_theme.dart';
import 'package:glu_butler/features/onboarding/widgets/onboarding_primary_button.dart';
// import 'package:glu_butler/features/onboarding/widgets/onboarding_skip_button.dart';
import 'package:glu_butler/services/settings_service.dart';
import 'package:glu_butler/services/health_service.dart';

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
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),

          // Title
          Text(
            'Connect Apple Health',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary(context),
              height: 1.2,
              letterSpacing: -0.5,
            ),
          ),

          const SizedBox(height: 12),

          // Description
          Text(
            'Sync blood glucose, insulin, steps, and weight for better insights',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w400,
              color: AppTheme.textSecondary(context),
              height: 1.4,
              letterSpacing: -0.3,
            ),
          ),

          const SizedBox(height: 40),

          // Illustration
          Center(
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.favorite,
                size: 64,
                color: AppTheme.primaryColor,
              ),
            ),
          ),

          const SizedBox(height: 40),

          // Checklist
          _buildChecklistItem('Automatic data sync'),
          const SizedBox(height: 16),
          _buildChecklistItem('Your health data stays private'),

          const Spacer(),

          // Skip button - always visible
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: widget.onNext,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              child: Text(
                'Skip',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textSecondary(context),
                  letterSpacing: -0.3,
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Connect button
          OnboardingPrimaryButton(
            text: 'Connect',
            onPressed: _requestHealthPermission,
            isLoading: _isRequesting,
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildChecklistItem(String text) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check,
            size: 16,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary(context),
              letterSpacing: -0.3,
            ),
          ),
        ),
      ],
    );
  }
}
