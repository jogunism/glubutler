import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:glu_butler/core/theme/app_theme.dart';
import 'package:glu_butler/features/onboarding/widgets/onboarding_primary_button.dart';
import 'package:glu_butler/services/settings_service.dart';
import 'package:glu_butler/services/cloudkit_service.dart';
import 'package:glu_butler/services/analytics_service.dart';
// import 'package:glu_butler/services/meal_migration_service.dart';
import 'package:glu_butler/providers/feed_provider.dart';
import 'package:glu_butler/providers/diary_provider.dart';
import 'package:glu_butler/providers/report_provider.dart';
import 'package:glu_butler/core/navigation/app_routes.dart';
import 'package:glu_butler/l10n/app_localizations.dart';

/// Completion page - Final onboarding screen
class CompletionPage extends StatefulWidget {
  const CompletionPage({super.key});

  @override
  State<CompletionPage> createState() => _CompletionPageState();
}

class _CompletionPageState extends State<CompletionPage> {
  bool _isCompleting = false;

  @override
  void initState() {
    super.initState();
    // CompletionPage가 로드될 때 미리 모든 Provider 초기화
    _initializeProviders();
  }

  Future<void> _initializeProviders() async {
    try {
      final settings = context.read<SettingsService>();

      // FeedProvider를 refresh하여 health connection 상태 업데이트
      if (mounted) {
        final feedProvider = context.read<FeedProvider>();
        await feedProvider.initialize();
      }

      // DiaryProvider iCloud 동기화
      if (mounted) {
        final diaryProvider = context.read<DiaryProvider>();
        await diaryProvider.syncFromICloud();
      }

      // iCloud에서 리포트 다운로드 (iCloud 동기화가 활성화된 경우)
      if (settings.iCloudSyncEnabled && mounted) {
        try {
          final isAvailable = await CloudKitService.isAvailable();
          final isSignedIn = await CloudKitService.isUserSignedIn();

          debugPrint(
            '[CompletionPage] iCloud available: $isAvailable, signed in: $isSignedIn',
          );

          if (isAvailable && isSignedIn) {
            final mealCount = await CloudKitService.downloadMealRecords();
            final reportCount = await CloudKitService.downloadReports();
            final summaryCount =
                await CloudKitService.downloadReportGuideSummaries();
            debugPrint(
              '[CompletionPage] Downloaded $mealCount meals, $reportCount reports, $summaryCount summaries from iCloud',
            );

            // 기존 diary에서 meal_records 마이그레이션 (사진 촬영 시간 기준)
            // debugPrint('[CompletionPage] Starting meal_records migration...');
            // final migratedCount =
            //     await MealMigrationService.migrateMealRecordsFromDiaries(
            //   uploadToICloud: true,
            // );
            // debugPrint(
            //   '[CompletionPage] meal_records migration complete: $migratedCount records created',
            // );
          }
        } catch (e) {
          debugPrint(
            '[CompletionPage] Failed to download reports from iCloud: $e',
          );
          // iCloud 동기화 실패해도 계속 진행
        }
      }

      // ReportProvider 초기화 (로컬 DB에서 최신 리포트 로드)
      if (mounted) {
        final reportProvider = context.read<ReportProvider>();
        await reportProvider.initialize();
      }
    } catch (e) {
      // 에러 무시 - 사용자가 계속 진행할 수 있도록
    }
  }

  Future<void> _completeOnboarding() async {
    setState(() {
      _isCompleting = true;
    });

    try {
      final settings = context.read<SettingsService>();
      await settings.setOnboardingComplete();

      // Log onboarding completion
      await AnalyticsService.logOnboardingCompleted();

      if (mounted) {
        // Navigate to main screen
        Navigator.of(context).pushReplacementNamed(AppRoutes.main);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCompleting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Stack(
      children: [
        // Main content
        Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App icon
                Image.asset(
                  'assets/images/main_icon.png',
                  width: 160,
                  height: 160,
                ),

                const SizedBox(height: 40),

                // Title
                Text(
                  l10n.onboardingCompletionTitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary(context),
                    height: 1.2,
                    letterSpacing: -0.5,
                  ),
                ),

                const SizedBox(height: 16),

                // Description
                Text(
                  l10n.onboardingCompletionSubtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: AppTheme.textSecondary(context),
                    height: 1.4,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Terms notice and button at bottom
        Positioned(
          left: 24,
          right: 24,
          bottom: 24,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Get started button
              OnboardingPrimaryButton(
                text: l10n.onboardingGetStarted,
                onPressed: _completeOnboarding,
                isLoading: _isCompleting,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
