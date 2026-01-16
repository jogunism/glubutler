import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:glu_butler/core/theme/app_theme.dart';
import 'package:glu_butler/features/onboarding/widgets/onboarding_primary_button.dart';
import 'package:glu_butler/features/onboarding/widgets/onboarding_skip_button.dart';
import 'package:glu_butler/features/onboarding/widgets/onboarding_text_field.dart';
import 'package:glu_butler/services/settings_service.dart';

/// Name input page - Collect user's first name
class NameInputPage extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onSkip;

  const NameInputPage({
    super.key,
    required this.onNext,
    required this.onSkip,
  });

  @override
  State<NameInputPage> createState() => _NameInputPageState();
}

class _NameInputPageState extends State<NameInputPage> {
  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load existing name if available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = context.read<SettingsService>();
      if (settings.userProfile.name != null) {
        _nameController.text = settings.userProfile.name!;
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleNext() async {
    final name = _nameController.text.trim();
    if (name.isNotEmpty) {
      final settings = context.read<SettingsService>();
      await settings.setUserName(name);
    }
    widget.onNext();
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
            'First Things First',
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
            "What's your first name?",
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w400,
              color: AppTheme.textSecondary(context),
              height: 1.4,
              letterSpacing: -0.3,
            ),
          ),

          const SizedBox(height: 32),

          // Name input field
          OnboardingTextField(
            hintText: 'Type your first name here',
            controller: _nameController,
            autofocus: true,
            keyboardType: TextInputType.name,
            onSubmitted: (_) => _handleNext(),
          ),

          const Spacer(),

          // Next button
          OnboardingPrimaryButton(
            text: 'Next',
            onPressed: _handleNext,
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
}
