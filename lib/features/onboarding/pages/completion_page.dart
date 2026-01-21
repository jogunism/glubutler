import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:glu_butler/core/theme/app_theme.dart';
import 'package:glu_butler/features/onboarding/widgets/onboarding_primary_button.dart';
import 'package:glu_butler/services/settings_service.dart';
import 'package:glu_butler/services/cloudkit_service.dart';
import 'package:glu_butler/services/analytics_service.dart';
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

          debugPrint('[CompletionPage] iCloud available: $isAvailable, signed in: $isSignedIn');

          if (isAvailable && isSignedIn) {
            final reportCount = await CloudKitService.downloadReports();
            final summaryCount = await CloudKitService.downloadReportGuideSummaries();
            debugPrint('[CompletionPage] Downloaded $reportCount reports, $summaryCount summaries from iCloud');
          }
        } catch (e) {
          debugPrint('[CompletionPage] Failed to download reports from iCloud: $e');
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

  /// 약관 동의 안내 텍스트
  Widget _buildTermsNotice(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final baseUrl = dotenv.env['BASE_URL'] ?? 'https://glubutler.com';

    // 텍스트 조합: "앱을 사용하시는 것은 이용약관 및 개인정보처리방침에 동의하는 것으로 간주됩니다."
    final prefix = l10n.onboardingTermsPrefix;
    final termsText = l10n.onboardingTermsOfService;
    final andText = l10n.onboardingTermsAnd;
    final privacyText = l10n.onboardingPrivacyPolicy;
    final suffix = l10n.onboardingTermsSuffix;

    final fullText = '$prefix $termsText $andText $privacyText$suffix';

    // 이용약관과 개인정보처리방침의 시작 인덱스 찾기
    final termsIndex = fullText.indexOf(termsText);
    final privacyIndex = fullText.indexOf(privacyText);

    return GestureDetector(
      onTapDown: (details) {
        // 터치 위치 확인
        final textPainter = TextPainter(
          text: TextSpan(
            text: fullText,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: AppTheme.textSecondary(context),
              height: 1.5,
            ),
          ),
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.center,
        );

        textPainter.layout(maxWidth: MediaQuery.of(context).size.width - 48);

        final position = textPainter.getPositionForOffset(details.localPosition);
        final offset = position.offset;

        // 이용약관 링크 클릭
        if (offset >= termsIndex && offset < termsIndex + termsText.length) {
          _launchURL('$baseUrl/terms');
        }
        // 개인정보처리방침 링크 클릭
        else if (offset >= privacyIndex && offset < privacyIndex + privacyText.length) {
          _launchURL('$baseUrl/privacy');
        }
      },
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: AppTheme.textSecondary(context),
            height: 1.5,
          ),
          children: _buildTermsTextSpans(fullText, termsIndex, privacyIndex, termsText, privacyText, context),
        ),
      ),
    );
  }

  /// 약관 텍스트 스타일링
  List<TextSpan> _buildTermsTextSpans(
    String fullText,
    int termsIndex,
    int privacyIndex,
    String termsText,
    String privacyText,
    BuildContext context,
  ) {
    final spans = <TextSpan>[];
    int lastIndex = 0;

    final linkStyle = TextStyle(
      color: AppTheme.primaryColor,
      fontWeight: FontWeight.w500,
      decoration: TextDecoration.underline,
    );

    // 순서대로 처리
    final indices = <MapEntry<int, String>>[
      MapEntry(termsIndex, termsText),
      MapEntry(privacyIndex, privacyText),
    ]..sort((a, b) => a.key.compareTo(b.key));

    for (final entry in indices) {
      final index = entry.key;
      final text = entry.value;

      // 앞부분 일반 텍스트
      if (index > lastIndex) {
        spans.add(TextSpan(text: fullText.substring(lastIndex, index)));
      }

      // 링크 텍스트
      spans.add(TextSpan(text: text, style: linkStyle));

      lastIndex = index + text.length;
    }

    // 마지막 남은 텍스트
    if (lastIndex < fullText.length) {
      spans.add(TextSpan(text: fullText.substring(lastIndex)));
    }

    return spans;
  }

  /// URL 열기
  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
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
              // Terms notice
              _buildTermsNotice(context),

              const SizedBox(height: 16),

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
