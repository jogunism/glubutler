import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:glu_butler/core/theme/app_theme.dart';
import 'package:glu_butler/features/onboarding/widgets/onboarding_page_indicator.dart';
import 'package:glu_butler/features/onboarding/pages/welcome_page.dart';
import 'package:glu_butler/features/onboarding/pages/name_input_page.dart';
import 'package:glu_butler/features/onboarding/pages/diabetes_type_page.dart';
import 'package:glu_butler/features/onboarding/pages/fasting_glucose_page.dart';
import 'package:glu_butler/features/onboarding/pages/diary_permission_page.dart';
import 'package:glu_butler/features/onboarding/pages/health_permission_page.dart';
import 'package:glu_butler/features/onboarding/pages/report_page.dart';
import 'package:glu_butler/features/onboarding/pages/notification_page.dart';
import 'package:glu_butler/features/onboarding/pages/subscription_page.dart';
import 'package:glu_butler/features/onboarding/pages/completion_page.dart';

/// Show onboarding mode
/// Read from .env file: SHOW_ONBOARDING=true to always show onboarding with swipe enabled
/// If not set or false, onboarding is shown only once and swipe is disabled
bool get kShowOnboarding => dotenv.env['SHOW_ONBOARDING'] == 'true';

/// Main onboarding screen with PageView
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isAnimating = false;

  // Total 10 pages
  static const int _totalPages = 10;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    // Prevent multiple calls during animation
    if (_isAnimating) {
      return;
    }

    if (_currentPage < _totalPages - 1) {
      _isAnimating = true;

      _pageController
          .nextPage(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          )
          .then((_) {
            _isAnimating = false;
          });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Android 뒤로가기 버튼으로 온보딩 이탈 방지
      child: MediaQuery(
      // 온보딩 화면은 항상 "작게" 텍스트 크기(0.85) 사용
      data: MediaQuery.of(context).copyWith(
        textScaler: const TextScaler.linear(0.85),
      ),
      child: Scaffold(
        backgroundColor: AppTheme.iosBackground(context),
        body: Column(
          children: [
            // Main content with SafeArea
            Expanded(
              child: SafeArea(
                bottom: false, // Don't apply SafeArea to bottom
                child: PageView(
                controller: _pageController,
                physics: kShowOnboarding
                    ? null
                    : const NeverScrollableScrollPhysics(), // Enable swipe when SHOW_ONBOARDING=true
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                children: [
                  WelcomePage(onNext: _nextPage),
                  NameInputPage(onNext: _nextPage),
                  DiabetesTypePage(onNext: _nextPage),
                  FastingGlucosePage(onNext: _nextPage),
                  DiaryPermissionPage(onNext: _nextPage),
                  HealthPermissionPage(onNext: _nextPage),
                  ReportPage(onNext: _nextPage),
                  NotificationPage(onNext: _nextPage),
                  SubscriptionPage(onNext: _nextPage),
                  const CompletionPage(),
                ],
              ),
            ),
          ),

          // Page indicator at the bottom
          Padding(
            padding: const EdgeInsets.only(bottom: 28, top: 3),
            child: OnboardingPageIndicator(
              currentPage: _currentPage,
              totalPages: _totalPages,
            ),
          ),
        ],
      ),
      ),
      ),
    );
  }
}
