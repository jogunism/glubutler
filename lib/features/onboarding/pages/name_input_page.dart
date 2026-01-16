import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:glu_butler/core/theme/app_theme.dart';
import 'package:glu_butler/features/onboarding/widgets/onboarding_primary_button.dart';
import 'package:glu_butler/features/onboarding/widgets/onboarding_text_field.dart';
import 'package:glu_butler/services/settings_service.dart';
import 'package:glu_butler/l10n/app_localizations.dart';

/// Name input page - Collect user's first name
class NameInputPage extends StatefulWidget {
  final VoidCallback onNext;

  const NameInputPage({
    super.key,
    required this.onNext,
  });

  @override
  State<NameInputPage> createState() => _NameInputPageState();
}

class _NameInputPageState extends State<NameInputPage> {
  final TextEditingController _nameController = TextEditingController();
  bool _hasName = false;

  @override
  void initState() {
    super.initState();
    // Load existing name if available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = context.read<SettingsService>();
      if (settings.userProfile.name != null) {
        _nameController.text = settings.userProfile.name!;
        setState(() {
          _hasName = settings.userProfile.name!.trim().isNotEmpty;
        });
      }
    });

    // Listen to text changes
    _nameController.addListener(() {
      final hasText = _nameController.text.trim().isNotEmpty;
      if (hasText != _hasName) {
        setState(() {
          _hasName = hasText;
        });
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleNext() async {
    // 키보드 내리기
    FocusScope.of(context).unfocus();

    final name = _nameController.text.trim();
    if (name.isNotEmpty) {
      final settings = context.read<SettingsService>();
      await settings.setUserName(name);
    }
    widget.onNext();
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
                l10n.onboardingFirstThingsFirst,
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
                l10n.onboardingWhatsYourFirstName,
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
                hintText: l10n.onboardingTypeYourFirstName,
                controller: _nameController,
                autofocus: false,
                keyboardType: TextInputType.name,
                onSubmitted: (_) => _handleNext(),
              ),

              const Spacer(),
            ],
          ),
        ),

        // Buttons positioned at bottom
        Positioned(
          left: 24,
          right: 24,
          bottom: 0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Skip button - always visible, just moves to next page without saving
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    FocusScope.of(context).unfocus();
                    widget.onNext();
                  },
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
              // Next button
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: OnboardingPrimaryButton(
                  text: l10n.onboardingNext,
                  onPressed: _hasName ? () => _handleNext() : null,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
