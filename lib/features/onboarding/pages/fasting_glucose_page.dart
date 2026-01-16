import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:glu_butler/core/theme/app_theme.dart';
import 'package:glu_butler/core/constants/app_constants.dart';
import 'package:glu_butler/features/onboarding/widgets/onboarding_primary_button.dart';
// import 'package:glu_butler/features/onboarding/widgets/onboarding_skip_button.dart';
import 'package:glu_butler/features/onboarding/widgets/onboarding_text_field.dart';
import 'package:glu_butler/services/settings_service.dart';
import 'package:glu_butler/l10n/app_localizations.dart';

/// Fasting glucose target page
class FastingGlucosePage extends StatefulWidget {
  final VoidCallback onNext;

  const FastingGlucosePage({
    super.key,
    required this.onNext,
  });

  @override
  State<FastingGlucosePage> createState() => _FastingGlucosePageState();
}

class _FastingGlucosePageState extends State<FastingGlucosePage> {
  final TextEditingController _glucoseController = TextEditingController();
  bool _isMmol = true; // true = mmol/L, false = mg/dL
  bool _hasValue = false;

  @override
  void initState() {
    super.initState();

    // Listen to text changes
    _glucoseController.addListener(() {
      final hasText = _glucoseController.text.trim().isNotEmpty;
      if (hasText != _hasValue) {
        setState(() {
          _hasValue = hasText;
        });
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = context.read<SettingsService>();

      // Set unit - default to mg/dL first
      _isMmol = settings.unit == AppConstants.unitMmolL;

      // Load existing value if available
      if (settings.fastingGlucoseTarget != null) {
        final value = settings.fastingGlucoseTarget!;
        if (_isMmol) {
          _glucoseController.text = (value / AppConstants.mgDlToMmolL).toStringAsFixed(1);
        } else {
          _glucoseController.text = value.toStringAsFixed(0);
        }
      } else {
        // Set default value to 100 mg/dL
        if (_isMmol) {
          _glucoseController.text = '5.6'; // 100 mg/dL = 5.6 mmol/L
        } else {
          _glucoseController.text = '100';
        }
        // Save default value immediately
        settings.setFastingGlucoseTarget(100.0);
      }

      // Update _hasValue based on controller text
      _hasValue = _glucoseController.text.trim().isNotEmpty;
      setState(() {});
    });
  }

  @override
  void dispose() {
    _glucoseController.dispose();
    super.dispose();
  }

  bool _validateValue(double value) {
    if (_isMmol) {
      // mmol/L: 4.4 ~ 11.1 (80 ~ 200 mg/dL)
      return value >= 4.4 && value <= 11.1;
    } else {
      // mg/dL: 80 ~ 200
      return value >= 80 && value <= 200;
    }
  }

  void _showValidationAlert() {
    final l10n = AppLocalizations.of(context)!;
    final minValue = _isMmol ? '4.4' : '80';
    final maxValue = _isMmol ? '11.1' : '200';
    final unit = _isMmol ? 'mmol/L' : 'mg/dL';
    final message = l10n.onboardingFastingGlucoseValidation(
      '$minValue $unit',
      '$maxValue $unit',
    );

    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          content: Text(message),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.confirm),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleNext() async {
    // 키보드 내리기
    FocusScope.of(context).unfocus();

    final valueStr = _glucoseController.text.trim();
    if (valueStr.isNotEmpty) {
      final value = double.tryParse(valueStr);
      if (value != null) {
        // Validate the value
        if (!_validateValue(value)) {
          _showValidationAlert();
          return;
        }

        final settings = context.read<SettingsService>();
        // Always store as mg/dL
        final mgDlValue = _isMmol ? value * AppConstants.mgDlToMmolL : value;

        // Update glucose range with target and calculate other values
        // 매우높음 = target+80, 높음 = target+30, 낮음 = target-30, 매우낮음 = target-40
        final newRange = settings.glucoseRange.copyWith(
          target: mgDlValue,
          low: mgDlValue - 30,
          high: mgDlValue + 30,
          veryLow: mgDlValue - 40,
          veryHigh: mgDlValue + 80,
        );
        await settings.setGlucoseRange(newRange);

        // Save the selected unit
        final unit = _isMmol ? AppConstants.unitMmolL : AppConstants.unitMgDl;
        await settings.setUnit(unit);
      }
    }
    widget.onNext();
  }

  void _toggleUnit() {
    final currentValue = double.tryParse(_glucoseController.text.trim());
    if (currentValue != null) {
      setState(() {
        _isMmol = !_isMmol;
        if (_isMmol) {
          // Convert mg/dL to mmol/L
          _glucoseController.text = (currentValue / AppConstants.mgDlToMmolL).toStringAsFixed(1);
        } else {
          // Convert mmol/L to mg/dL
          _glucoseController.text = (currentValue * AppConstants.mgDlToMmolL).toStringAsFixed(0);
        }
      });
    } else {
      setState(() {
        _isMmol = !_isMmol;
      });
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
                l10n.onboardingFastingGlucoseTitle,
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
                l10n.onboardingFastingGlucoseSubtitle,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w400,
                  color: AppTheme.textSecondary(context),
                  height: 1.4,
                  letterSpacing: -0.3,
                ),
              ),

              const SizedBox(height: 32),

              // Unit toggle
              Row(
                children: [
                  _buildUnitToggle('mg/dL', !_isMmol),
                  const SizedBox(width: 12),
                  _buildUnitToggle('mmol/L', _isMmol),
                ],
              ),

              const SizedBox(height: 24),

              // Glucose input
              OnboardingTextField(
                hintText: _isMmol ? 'e.g., 5.6' : 'e.g., 100',
                controller: _glucoseController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                autofocus: false,
                onSubmitted: (_) => _handleNext(),
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
          child: OnboardingPrimaryButton(
            text: l10n.onboardingNext,
            onPressed: _hasValue ? _handleNext : null,
          ),
        ),
      ],
    );
  }

  Widget _buildUnitToggle(String unit, bool isSelected) {
    return GestureDetector(
      onTap: isSelected ? null : _toggleUnit,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor
              : AppTheme.iosCard(context),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryColor
                : AppTheme.divider(context),
            width: isSelected ? 2 : 1.5,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          unit,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: isSelected
                ? Colors.white
                : AppTheme.textPrimary(context),
            letterSpacing: -0.3,
          ),
        ),
      ),
    );
  }
}
