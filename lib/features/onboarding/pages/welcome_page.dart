import 'dart:async';
import 'package:flutter/material.dart';
import 'package:glu_butler/core/theme/app_theme.dart';
import 'package:glu_butler/features/onboarding/widgets/onboarding_primary_button.dart';
import 'package:glu_butler/l10n/app_localizations.dart';

/// Welcome page - First onboarding screen
class WelcomePage extends StatefulWidget {
  final VoidCallback onNext;

  const WelcomePage({super.key, required this.onNext});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  int _currentImageIndex = 0;
  Timer? _timer;
  bool _isNavigating = false;
  bool _isReady = false;

  final List<String> _screenImages = [
    'assets/images/screen_1.png',
    'assets/images/screen_2.png',
    'assets/images/screen_3.png',
    'assets/images/screen_4.png',
  ];

  @override
  void initState() {
    super.initState();
    _startImageCycling();

    // Wait for page to render first
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Small delay to ensure smooth transition
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          setState(() {
            _isReady = true;
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startImageCycling() {
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted) {
        setState(() {
          _currentImageIndex = (_currentImageIndex + 1) % _screenImages.length;
        });
      }
    });
  }

  void _handleNext() {
    if (!_isReady) {
      return;
    }

    if (_isNavigating) {
      return;
    }

    setState(() {
      _isNavigating = true;
    });

    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    // 화면 크기에 따라 동적으로 조정
    // 이미지 비율: 1024:1464 = 1:1.43
    final imageWidth = screenWidth * 0.7;
    final imageHeight = imageWidth * 1.43; // 이미지 실제 비율 유지
    final imageOffsetY = -(screenHeight * 0.08);
    // textOffsetY: 이미지 끝에서 위로 올라가는 양 계산 (이미지와 겹치지 않고 바로 아래)
    final textOffsetY = imageOffsetY + 20;
    final titleFontSize = screenHeight * 0.024;
    final appNameFontSize = screenHeight * 0.048;
    final descriptionFontSize = screenHeight * 0.02;

    return Stack(
      children: [
        // Main content
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
          child: Column(
            children: [
              const Spacer(),

              // App demo animation - cycling screenshots
              Transform.translate(
                offset: Offset(0, imageOffsetY),
                child: SizedBox(
                  width: imageWidth,
                  height: imageHeight,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 800),
                    switchInCurve: Curves.easeIn,
                    switchOutCurve: Curves.easeOut,
                    child: Image.asset(
                      _screenImages[_currentImageIndex],
                      key: ValueKey<int>(_currentImageIndex),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),

              Transform.translate(
                offset: Offset(0, textOffsetY),
                child: Column(
                  children: [
                    Text(
                      l10n.onboardingWelcomeTo,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary(context),
                        letterSpacing: -0.3,
                        height: 1.0,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.01),
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'Glu ',
                            style: TextStyle(
                              fontSize: appNameFontSize,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primaryColor,
                              letterSpacing: -0.5,
                              height: 1.0,
                            ),
                          ),
                          TextSpan(
                            text: 'Butler',
                            style: TextStyle(
                              fontSize: appNameFontSize,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary(context),
                              letterSpacing: -0.5,
                              height: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.012),
                    Text(
                      l10n.onboardingWelcomeDescription,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: descriptionFontSize,
                        fontWeight: FontWeight.w400,
                        color: AppTheme.textSecondary(context),
                        height: 1.15,
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
        if (_isReady)
          Positioned(
            left: 24,
            right: 24,
            bottom: 0,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: OnboardingPrimaryButton(
                text: l10n.onboardingLetsBegin,
                onPressed: _handleNext,
                isLoading: _isNavigating,
              ),
            ),
          ),
      ],
    );
  }
}
