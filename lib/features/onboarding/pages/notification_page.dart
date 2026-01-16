import 'package:flutter/material.dart';
import 'package:glu_butler/core/theme/app_theme.dart';
import 'package:glu_butler/features/onboarding/widgets/onboarding_primary_button.dart';
import 'package:glu_butler/features/onboarding/widgets/onboarding_skip_button.dart';

/// Notification permission page
class NotificationPage extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onSkip;

  const NotificationPage({
    super.key,
    required this.onNext,
    required this.onSkip,
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
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),

          // Title
          Text(
            'Turn on reminders',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary(context),
              height: 1.2,
              letterSpacing: -0.5,
            ),
          ),

          const SizedBox(height: 12),

          // Description
          Text(
            'Get daily reminders for logging glucose and meals',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w400,
              color: AppTheme.textSecondary(context),
              height: 1.4,
              letterSpacing: -0.3,
            ),
          ),

          const SizedBox(height: 40),

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

          const SizedBox(height: 40),

          // Benefits
          _buildBenefitItem('Daily glucose logging reminders'),
          const SizedBox(height: 16),
          _buildBenefitItem('Meal logging notifications'),
          const SizedBox(height: 16),
          _buildBenefitItem('Stay consistent with tracking'),

          const Spacer(),

          // Enable button
          OnboardingPrimaryButton(
            text: 'Enable Notifications',
            onPressed: _requestNotificationPermission,
            isLoading: _isRequesting,
          ),

          const SizedBox(height: 8),

          // Skip button
          Align(
            alignment: Alignment.centerRight,
            child: OnboardingSkipButton(onPressed: widget.onSkip),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildBenefitItem(String text) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check,
            size: 16,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary(context),
              letterSpacing: -0.3,
            ),
          ),
        ),
      ],
    );
  }
}
