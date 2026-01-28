import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:glu_butler/core/theme/app_theme.dart';
import 'package:glu_butler/features/onboarding/widgets/onboarding_primary_button.dart';
import 'package:glu_butler/services/settings_service.dart';
import 'package:glu_butler/services/cloudkit_service.dart';
import 'package:glu_butler/services/analytics_service.dart';
import 'package:glu_butler/l10n/app_localizations.dart';

/// Report and iCloud sync page
class ReportPage extends StatefulWidget {
  final VoidCallback onNext;

  const ReportPage({
    super.key,
    required this.onNext,
  });

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
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

        // Sync service start date to iCloud
        await settings.syncServiceStartDateToICloud();

        // Download diary entries, meals, and reports from iCloud
        debugPrint('[ReportPage] Starting iCloud download...');
        final downloadedDiaries = await CloudKitService.downloadDiaryEntries();
        debugPrint('[ReportPage] Downloaded $downloadedDiaries diary entries');

        final mealCount = await CloudKitService.downloadMealRecords();
        debugPrint('[ReportPage] Downloaded $mealCount meal records');

        final reportCount = await CloudKitService.downloadReports();
        final summaryCount = await CloudKitService.downloadReportGuideSummaries();
        debugPrint('[ReportPage] Downloaded $reportCount reports, $summaryCount summaries');

        // Log iCloud enabled
        await AnalyticsService.logICloudEnabled(success: true);

        setState(() {
          _isEnabling = false;
        });

        widget.onNext();
      }
    } catch (e) {
      // Log iCloud failed
      await AnalyticsService.logICloudEnabled(success: false);

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
    final screenWidth = MediaQuery.of(context).size.width;

    // Match health permission page image size
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
                l10n.onboardingReportTitle,
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
                l10n.onboardingReportSubtitle,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: AppTheme.textSecondary(context),
                  height: 1.4,
                  letterSpacing: -0.3,
                ),
              ),

              const SizedBox(height: 32),

              // Report screenshot
              Center(
                child: SizedBox(
                  width: imageWidth,
                  height: imageHeight,
                  child: Image.asset(
                    'assets/images/screen_report.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // iCloud sync required message
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.cloud,
                      size: 20,
                      color: AppTheme.iconCyan,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l10n.onboardingReportICloudRequired,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textSecondary(context),
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
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
            onPressed: _enableICloudSync,
            isLoading: _isEnabling,
          ),
        ),
      ],
    );
  }
}
