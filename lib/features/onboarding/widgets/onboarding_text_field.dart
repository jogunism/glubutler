import 'package:flutter/material.dart';
import 'package:glu_butler/core/theme/app_theme.dart';

/// Text input field for onboarding screens
class OnboardingTextField extends StatelessWidget {
  final String hintText;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final bool autofocus;
  final Function(String)? onChanged;
  final Function(String)? onSubmitted;

  const OnboardingTextField({
    super.key,
    required this.hintText,
    required this.controller,
    this.keyboardType = TextInputType.text,
    this.autofocus = false,
    this.onChanged,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      autofocus: autofocus,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      style: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w500,
        color: AppTheme.textPrimary(context),
        letterSpacing: -0.4,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w400,
          color: AppTheme.divider(context),
          letterSpacing: -0.4,
        ),
        filled: false,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: AppTheme.divider(context),
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: AppTheme.primaryColor,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
      ),
    );
  }
}
