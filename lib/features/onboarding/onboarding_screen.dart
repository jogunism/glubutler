import 'package:flutter/material.dart';
import 'package:glu_butler/core/theme/app_theme.dart';
import 'package:glu_butler/features/onboarding/widgets/onboarding_page_indicator.dart';
import 'package:glu_butler/features/onboarding/pages/welcome_page.dart';
import 'package:glu_butler/features/onboarding/pages/name_input_page.dart';
import 'package:glu_butler/features/onboarding/pages/diabetes_type_page.dart';
import 'package:glu_butler/features/onboarding/pages/fasting_glucose_page.dart';
import 'package:glu_butler/features/onboarding/pages/health_permission_page.dart';
import 'package:glu_butler/features/onboarding/pages/icloud_sync_page.dart';
import 'package:glu_butler/features/onboarding/pages/notification_page.dart';
import 'package:glu_butler/features/onboarding/pages/completion_page.dart';

/// Main onboarding screen with PageView
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Total 8 pages
  static const int _totalPages = 8;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _skipToEnd() {
    _pageController.animateToPage(
      _totalPages - 1,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.iosBackground(context),
      body: Column(
        children: [
          // Main content with SafeArea
          Expanded(
            child: SafeArea(
              bottom: false, // Don't apply SafeArea to bottom
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                children: [
                  WelcomePage(onNext: _nextPage),
                  NameInputPage(onNext: _nextPage, onSkip: _skipToEnd),
                  DiabetesTypePage(onNext: _nextPage, onSkip: _skipToEnd),
                  FastingGlucosePage(onNext: _nextPage, onSkip: _skipToEnd),
                  HealthPermissionPage(onNext: _nextPage, onSkip: _skipToEnd),
                  ICloudSyncPage(onNext: _nextPage, onSkip: _skipToEnd),
                  NotificationPage(onNext: _nextPage, onSkip: _skipToEnd),
                  const CompletionPage(),
                ],
              ),
            ),
          ),

          // Page indicator at the bottom
          Padding(
            padding: const EdgeInsets.only(bottom: 36),
            child: OnboardingPageIndicator(
              currentPage: _currentPage,
              totalPages: _totalPages,
            ),
          ),
        ],
      ),
    );
  }
}
