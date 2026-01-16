import 'package:flutter/material.dart';
import 'dart:async';
import 'package:photo_manager/photo_manager.dart';
import 'package:glu_butler/core/theme/app_theme.dart';
import 'package:glu_butler/features/onboarding/widgets/onboarding_primary_button.dart';
import 'package:glu_butler/l10n/app_localizations.dart';

/// Diary and photo access permission page
class DiaryPermissionPage extends StatefulWidget {
  final VoidCallback onNext;

  const DiaryPermissionPage({
    super.key,
    required this.onNext,
  });

  @override
  State<DiaryPermissionPage> createState() => _DiaryPermissionPageState();
}

class _DiaryPermissionPageState extends State<DiaryPermissionPage> {
  bool _isRequesting = false;
  int _currentImageIndex = 0;
  Timer? _timer;

  final List<String> _screenImages = [
    'assets/images/screen_diary.png',
    'assets/images/screen_feed.png',
  ];

  @override
  void initState() {
    super.initState();
    _startImageCycling();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startImageCycling() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        setState(() {
          _currentImageIndex = (_currentImageIndex + 1) % _screenImages.length;
        });
      }
    });
  }

  Future<void> _requestPhotoAccess() async {
    setState(() {
      _isRequesting = true;
    });

    try {
      await PhotoManager.requestPermissionExtend();

      if (mounted) {
        setState(() {
          _isRequesting = false;
        });

        // Always proceed to next page regardless of permission result
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
    final l10n = AppLocalizations.of(context)!;
    final screenWidth = MediaQuery.of(context).size.width;

    // 화면 크기에 따라 동적으로 조정 (welcome_page와 동일)
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
                l10n.onboardingDiaryTitle,
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
                l10n.onboardingDiarySubtitle,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: AppTheme.textSecondary(context),
                  height: 1.4,
                  letterSpacing: -0.3,
                ),
              ),

              const SizedBox(height: 32),

              // Image - matching health permission page size with animation
              Center(
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
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: Text(
                    l10n.onboardingSkip,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textSecondary(context),
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 0),

              // Photo access button
              OnboardingPrimaryButton(
                text: l10n.onboardingPhotoAccess,
                onPressed: _requestPhotoAccess,
                isLoading: _isRequesting,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
