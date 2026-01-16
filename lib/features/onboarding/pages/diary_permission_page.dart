import 'package:flutter/material.dart';
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
                  fontSize: 17,
                  fontWeight: FontWeight.w400,
                  color: AppTheme.textSecondary(context),
                  height: 1.4,
                  letterSpacing: -0.3,
                ),
              ),

              const SizedBox(height: 32),

              // Image - matching health permission page layout
              Center(
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.8,
                  child: Image.asset(
                    'assets/images/screen_diary.png',
                    fit: BoxFit.contain,
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
