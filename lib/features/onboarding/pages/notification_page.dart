import 'package:flutter/material.dart';
import 'package:glu_butler/core/theme/app_theme.dart';
import 'package:glu_butler/features/onboarding/widgets/onboarding_primary_button.dart';
import 'package:glu_butler/l10n/app_localizations.dart';

/// Notification permission page
class NotificationPage extends StatefulWidget {
  final VoidCallback onNext;

  const NotificationPage({
    super.key,
    required this.onNext,
  });

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  bool _isRequesting = false;

  Future<void> _requestNotificationPermission() async {
    setState(() {
      _isRequesting = true;
    });

    try {
      // TODO: Implement actual notification permission request
      // For now, just delay and continue
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        setState(() {
          _isRequesting = false;
        });
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
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // Title
              Text(
                l10n.onboardingNotificationTitle,
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
                l10n.onboardingNotificationSubtitle,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: AppTheme.textSecondary(context),
                  height: 1.4,
                  letterSpacing: -0.3,
                ),
              ),

              const SizedBox(height: 32),

              // Illustration
              Center(
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(80),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Envelope
                      Container(
                        width: 80,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppTheme.primaryColor,
                            width: 2,
                          ),
                        ),
                      ),
                      // Badge
                      Positioned(
                        top: 45,
                        right: 45,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: const BoxDecoration(
                            color: AppTheme.primaryColor,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.notifications,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
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

              // Enable button
              OnboardingPrimaryButton(
                text: l10n.onboardingNotificationEnable,
                onPressed: _requestNotificationPermission,
                isLoading: _isRequesting,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
