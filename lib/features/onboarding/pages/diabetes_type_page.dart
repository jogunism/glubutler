import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:glu_butler/core/theme/app_theme.dart';
import 'package:glu_butler/features/onboarding/widgets/onboarding_primary_button.dart';
import 'package:glu_butler/features/onboarding/widgets/onboarding_option_button.dart';
import 'package:glu_butler/features/onboarding/models/diabetes_type.dart';
import 'package:glu_butler/services/settings_service.dart';
import 'package:glu_butler/l10n/app_localizations.dart';

/// Diabetes type selection page
class DiabetesTypePage extends StatefulWidget {
  final VoidCallback onNext;

  const DiabetesTypePage({
    super.key,
    required this.onNext,
  });

  @override
  State<DiabetesTypePage> createState() => _DiabetesTypePageState();
}

class _DiabetesTypePageState extends State<DiabetesTypePage> {
  DiabetesType? _selectedType; // No default selection

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
    if (_selectedType != null) {
      final settings = context.read<SettingsService>();
      await settings.setDiabetesType(_selectedType!.value);
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
                l10n.onboardingDiabetesTypeTitle,
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
                          text: _getDiabetesTypeLabel(type, l10n),
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
              // Next button - disabled when no selection
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: OnboardingPrimaryButton(
                  text: l10n.onboardingNext,
                  onPressed: _selectedType != null ? () => _handleNext() : null,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getDiabetesTypeLabel(DiabetesType type, AppLocalizations l10n) {
    switch (type) {
      case DiabetesType.unknown:
        return l10n.diabetesTypeUnknown;
      case DiabetesType.prediabetes:
        return l10n.preDiabetes;
      case DiabetesType.type1:
        return l10n.type1;
      case DiabetesType.type2:
        return l10n.type2;
      case DiabetesType.lada:
        return l10n.lada;
      case DiabetesType.mody:
        return l10n.mody;
    }
  }
}
