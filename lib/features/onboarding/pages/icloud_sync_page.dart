import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:glu_butler/core/theme/app_theme.dart';
import 'package:glu_butler/features/onboarding/widgets/onboarding_primary_button.dart';
import 'package:glu_butler/services/settings_service.dart';
import 'package:glu_butler/services/cloudkit_service.dart';
import 'package:glu_butler/l10n/app_localizations.dart';

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

  void _showErrorAlert(String reason) {
    final l10n = AppLocalizations.of(context)!;
    final message = '$reason. ${l10n.iCloudSyncRetryMessage}';

    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          content: Text(message),
          actions: [
            CupertinoDialogAction(
              onPressed: () {
                Navigator.of(context).pop();
                widget.onNext();
              },
              child: Text(l10n.confirm),
            ),
          ],
        );
      },
    );
  }

  Future<void> _enableICloudSync() async {
    setState(() {
      _isEnabling = true;
    });

    try {
      // Check if iCloud is available
      final isAvailable = await CloudKitService.isAvailable();
      final isSignedIn = await CloudKitService.isUserSignedIn();

      if (!isAvailable) {
        if (mounted) {
          setState(() {
            _isEnabling = false;
          });
          _showErrorAlert(AppLocalizations.of(context)!.iCloudNotAvailable);
        }
        return;
      }

      if (!isSignedIn) {
        if (mounted) {
          setState(() {
            _isEnabling = false;
          });
          _showErrorAlert(AppLocalizations.of(context)!.iCloudNotSignedIn);
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
        _showErrorAlert(AppLocalizations.of(context)!.iCloudSyncFailed);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Stack(
      children: [
        // Main content
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // Title
              Text(
                l10n.onboardingICloudTitle,
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
                l10n.onboardingICloudSubtitle,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w400,
                  color: AppTheme.textSecondary(context),
                  height: 1.4,
                  letterSpacing: -0.3,
                ),
              ),

              const SizedBox(height: 32),

              // iCloud Icon
              Center(
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.cloud,
                    size: 64,
                    color: AppTheme.iconCyan,
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
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  child: Text(
                    l10n.onboardingSkip,
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
                text: l10n.onboardingICloudEnable,
                onPressed: _enableICloudSync,
                isLoading: _isEnabling,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
