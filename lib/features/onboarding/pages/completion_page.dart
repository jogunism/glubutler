import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:glu_butler/core/theme/app_theme.dart';
import 'package:glu_butler/features/onboarding/widgets/onboarding_primary_button.dart';
import 'package:glu_butler/services/settings_service.dart';
import 'package:glu_butler/core/navigation/app_routes.dart';

/// Completion page - Final onboarding screen with optional premium intro
class CompletionPage extends StatefulWidget {
  const CompletionPage({super.key});

  @override
  State<CompletionPage> createState() => _CompletionPageState();
}

class _CompletionPageState extends State<CompletionPage> {
  bool _isCompleting = false;

  Future<void> _completeOnboarding() async {
    setState(() {
      _isCompleting = true;
    });

    try {
      final settings = context.read<SettingsService>();
      await settings.setOnboardingComplete();

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
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Spacer(),

          // Success icon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle,
              size: 64,
              color: AppTheme.primaryColor,
            ),
          ),

          const SizedBox(height: 40),

          // Title
          Text(
            "You're all set!",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary(context),
              height: 1.2,
              letterSpacing: -0.5,
            ),
          ),

          const SizedBox(height: 16),

          // Description
          Text(
            'Start tracking your glucose and managing your diabetes with GluButler',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w400,
              color: AppTheme.textSecondary(context),
              height: 1.4,
              letterSpacing: -0.3,
            ),
          ),

          const SizedBox(height: 40),

          // Premium features (optional)
          _buildPremiumFeature('AI-powered health insights'),
          const SizedBox(height: 12),
          _buildPremiumFeature('Unlimited data sync'),
          const SizedBox(height: 12),
          _buildPremiumFeature('Advanced reports'),

          const Spacer(),

          // Start Free Trial button (if premium available)
          // For now, just show Get Started
          OnboardingPrimaryButton(
            text: 'Get Started',
            onPressed: _completeOnboarding,
            isLoading: _isCompleting,
          ),

          const SizedBox(height: 16),

          // Continue with free version (smaller text)
          // TextButton(
          //   onPressed: _completeOnboarding,
          //   child: Text(
          //     'Continue with Free Version',
          //     style: TextStyle(
          //       fontSize: 15,
          //       fontWeight: FontWeight.w500,
          //       color: AppTheme.textSecondary(context),
          //       letterSpacing: -0.3,
          //     ),
          //   ),
          // ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildPremiumFeature(String text) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.star,
          size: 20,
          color: AppTheme.primaryColor,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppTheme.textPrimary(context),
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }
}
