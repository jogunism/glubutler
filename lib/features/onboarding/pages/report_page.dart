import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:glu_butler/core/theme/app_theme.dart';
import 'package:glu_butler/features/onboarding/widgets/onboarding_primary_button.dart';
import 'package:glu_butler/services/settings_service.dart';
import 'package:glu_butler/services/cloudkit_service.dart';
import 'package:glu_butler/services/firestore_service.dart';
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

  // ---------------------------------------------------------------------------
  // Android: Google Sign-In 흐름
  // ---------------------------------------------------------------------------

  Future<void> _enableGoogleSync() async {
    setState(() => _isEnabling = true);

    try {
      final googleSignIn = GoogleSignIn(scopes: ['email']);
      final account = await googleSignIn.signIn();

      if (account == null) {
        // 사용자가 로그인 취소
        if (mounted) {
          setState(() => _isEnabling = false);
          _showErrorAlert(AppLocalizations.of(context)!.googleNotSignedIn);
        }
        return;
      }

      // Firebase Auth에 Google 계정으로 로그인 (Firestore 접근 권한 획득)
      final googleAuth = await account.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);

      final googleId = account.id;

      if (mounted) {
        final settings = context.read<SettingsService>();
        await settings.updateGoogleId(googleId);
        await settings.setGoogleSync(true);

        // 서비스 시작일 Firestore 동기화 (구독 우회 방지)
        await settings.syncServiceStartDateToFirestore();

        // Firestore에서 기존 데이터 다운로드
        debugPrint('[ReportPage] Starting Firestore download...');
        final downloadedDiaries = await FirestoreService.downloadDiaryEntries(googleId);
        debugPrint('[ReportPage] Downloaded $downloadedDiaries diary entries');

        final mealCount = await FirestoreService.downloadMealRecords(googleId);
        debugPrint('[ReportPage] Downloaded $mealCount meal records');

        final reportCount = await FirestoreService.downloadReports(googleId);
        debugPrint('[ReportPage] Downloaded $reportCount reports');

        await AnalyticsService.logICloudEnabled(success: true);

        setState(() => _isEnabling = false);
        widget.onNext();
      }
    } catch (e, st) {
      debugPrint('[ReportPage] _enableGoogleSync error: $e\n$st');
      await AnalyticsService.logICloudEnabled(success: false);
      if (mounted) {
        setState(() => _isEnabling = false);
        _showErrorAlert(AppLocalizations.of(context)!.googleSyncFailed);
      }
    }
  }

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
        debugPrint('[ReportPage] Downloaded $reportCount reports');

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

              // 동기화 안내 메시지 (플랫폼별)
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (Platform.isIOS)
                      const Icon(
                        Icons.cloud,
                        size: 20,
                        color: AppTheme.iconCyan,
                      )
                    else
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.asset(
                          'assets/images/google.png',
                          width: 20,
                          height: 20,
                          fit: BoxFit.cover,
                        ),
                      ),
                    const SizedBox(width: 8),
                    Text(
                      Platform.isIOS
                          ? l10n.onboardingReportICloudRequired
                          : l10n.onboardingReportGoogleRequired,
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
            onPressed: Platform.isIOS ? _enableICloudSync : _enableGoogleSync,
            isLoading: _isEnabling,
          ),
        ),
      ],
    );
  }
}
