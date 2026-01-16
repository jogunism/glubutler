import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:glu_butler/core/theme/app_theme.dart';
import 'package:glu_butler/core/constants/app_constants.dart';
import 'package:glu_butler/features/onboarding/widgets/onboarding_primary_button.dart';
// import 'package:glu_butler/features/onboarding/widgets/onboarding_skip_button.dart';
import 'package:glu_butler/features/onboarding/widgets/onboarding_text_field.dart';
import 'package:glu_butler/services/settings_service.dart';

/// Fasting glucose target page
class FastingGlucosePage extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onSkip;

  const FastingGlucosePage({
    super.key,
    required this.onNext,
    required this.onSkip,
  });

  @override
  State<FastingGlucosePage> createState() => _FastingGlucosePageState();
}

class _FastingGlucosePageState extends State<FastingGlucosePage> {
  final TextEditingController _glucoseController = TextEditingController();
  bool _isMmol = true; // true = mmol/L, false = mg/dL

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = context.read<SettingsService>();

      // Set unit based on current setting
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
        // Set default value
        if (_isMmol) {
          _glucoseController.text = '5.6'; // 100 mg/dL = 5.6 mmol/L
        } else {
          _glucoseController.text = '100';
        }
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _glucoseController.dispose();
    super.dispose();
  }

  Future<void> _handleNext() async {
    final valueStr = _glucoseController.text.trim();
    if (valueStr.isNotEmpty) {
      final value = double.tryParse(valueStr);
      if (value != null) {
        final settings = context.read<SettingsService>();
        // Always store as mg/dL
        final mgDlValue = _isMmol ? value * AppConstants.mgDlToMmolL : value;
        await settings.setFastingGlucoseTarget(mgDlValue);
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
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),

          // Title
          Text(
            "What's your fasting\nglucose target?",
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
            'This helps us personalize your experience',
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
              _buildUnitToggle('mmol/L', _isMmol),
              const SizedBox(width: 12),
              _buildUnitToggle('mg/dL', !_isMmol),
            ],
          ),

          const SizedBox(height: 24),

          // Glucose input
          OnboardingTextField(
            hintText: _isMmol ? 'e.g., 5.6' : 'e.g., 100',
            controller: _glucoseController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            autofocus: true,
            onSubmitted: (_) => _handleNext(),
          ),

          const Spacer(),

          // Next button
          OnboardingPrimaryButton(
            text: 'Next',
            onPressed: _handleNext,
          ),

          const SizedBox(height: 8),

          // Skip button - TODO: 나중에 "다음"과 다른 동작 구현 시 주석 해제
          // Align(
          //   alignment: Alignment.centerRight,
          //   child: OnboardingSkipButton(onPressed: widget.onSkip),
          // ),

          const SizedBox(height: 16),
        ],
      ),
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
              : Colors.white,
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
