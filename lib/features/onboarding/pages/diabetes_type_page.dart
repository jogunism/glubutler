import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:glu_butler/core/theme/app_theme.dart';
import 'package:glu_butler/features/onboarding/widgets/onboarding_primary_button.dart';
import 'package:glu_butler/features/onboarding/widgets/onboarding_skip_button.dart';
import 'package:glu_butler/features/onboarding/widgets/onboarding_option_button.dart';
import 'package:glu_butler/features/onboarding/models/diabetes_type.dart';
import 'package:glu_butler/services/settings_service.dart';

/// Diabetes type selection page
class DiabetesTypePage extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onSkip;

  const DiabetesTypePage({
    super.key,
    required this.onNext,
    required this.onSkip,
  });

  @override
  State<DiabetesTypePage> createState() => _DiabetesTypePageState();
}

class _DiabetesTypePageState extends State<DiabetesTypePage> {
  DiabetesType _selectedType = DiabetesType.type2; // Default selection

  @override
  void initState() {
    super.initState();
    // Load existing selection if available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = context.read<SettingsService>();
      if (settings.diabetesType != null) {
        setState(() {
          _selectedType = DiabetesType.fromValue(settings.diabetesType!);
        });
      }
    });
  }

  Future<void> _handleNext() async {
    final settings = context.read<SettingsService>();
    await settings.setDiabetesType(_selectedType.value);
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
            'Which best describes\nyour diabetes type?',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary(context),
              height: 1.2,
              letterSpacing: -0.5,
            ),
          ),

          const SizedBox(height: 32),

          // Options
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: DiabetesType.values.map((type) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: OnboardingOptionButton(
                      text: type.displayName,
                      isSelected: _selectedType == type,
                      onTap: () {
                        setState(() {
                          _selectedType = type;
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          const SizedBox(height: 16),

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
