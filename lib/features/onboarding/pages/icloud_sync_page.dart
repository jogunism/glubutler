import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:glu_butler/core/theme/app_theme.dart';
import 'package:glu_butler/features/onboarding/widgets/onboarding_primary_button.dart';
// import 'package:glu_butler/features/onboarding/widgets/onboarding_skip_button.dart';
import 'package:glu_butler/services/settings_service.dart';
import 'package:glu_butler/services/cloudkit_service.dart';

/// iCloud sync permission page
class ICloudSyncPage extends StatefulWidget {
  final VoidCallback onNext;

  const ICloudSyncPage({
    super.key,
    required this.onNext,
  });

  @override
  State<ICloudSyncPage> createState() => _ICloudSyncPageState();
}

class _ICloudSyncPageState extends State<ICloudSyncPage> {
  bool _isEnabling = false;

  Future<void> _enableICloudSync() async {
    setState(() {
      _isEnabling = true;
    });

    try {
      // Check if iCloud is available
      final isAvailable = await CloudKitService.isAvailable();
      final isSignedIn = await CloudKitService.isUserSignedIn();

      if (!isAvailable || !isSignedIn) {
        if (mounted) {
          setState(() {
            _isEnabling = false;
          });
          // Show error message but continue
          widget.onNext();
        }
        return;
      }

      // Get CloudKit ID
      final cloudKitId = await CloudKitService.getUserRecordID();

      if (mounted) {
        final settings = context.read<SettingsService>();
        await settings.updateCloudKitId(cloudKitId);
        await settings.setICloudSync(true);

        setState(() {
          _isEnabling = false;
        });

        widget.onNext();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isEnabling = false;
        });
        // Continue even if failed
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
            'Enable iCloud Sync',
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
            'Sync your diary entries across devices and keep your data safe',
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
                borderRadius: BorderRadius.circular(60),
              ),
              child: const Icon(
                Icons.cloud,
                size: 64,
                color: AppTheme.primaryColor,
              ),
            ),
          ),

          const SizedBox(height: 40),

          // Important note
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.primaryColor.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Required for AI-powered health reports',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textPrimary(context),
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Benefits
          _buildBenefitItem('Sync across all your devices'),
          const SizedBox(height: 16),
          _buildBenefitItem('Secure cloud backup'),

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

          // Enable button
          OnboardingPrimaryButton(
            text: 'Enable iCloud',
            onPressed: _enableICloudSync,
            isLoading: _isEnabling,
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildBenefitItem(String text) {
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
