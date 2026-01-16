import 'package:flutter/material.dart';
import 'package:glu_butler/core/theme/app_theme.dart';
import 'package:glu_butler/core/widgets/keyboard_dismiss_button.dart';

/// Text input field for onboarding screens with keyboard toolbar
class OnboardingTextField extends StatefulWidget {
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
  State<OnboardingTextField> createState() => _OnboardingTextFieldState();
}

class _OnboardingTextFieldState extends State<OnboardingTextField> {
  final FocusNode _focusNode = FocusNode();
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _removeOverlay();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      _showOverlay();
    } else {
      _removeOverlay();
    }
  }

  void _showOverlay() {
    _removeOverlay();
    _overlayEntry = KeyboardDismissButton.show(context, _focusNode);
  }

  void _removeOverlay() {
    KeyboardDismissButton.hide(_overlayEntry);
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      focusNode: _focusNode,
      keyboardType: widget.keyboardType,
      autofocus: widget.autofocus,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      style: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w500,
        color: AppTheme.textPrimary(context),
        letterSpacing: -0.4,
      ),
      decoration: InputDecoration(
        hintText: widget.hintText,
        hintStyle: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w400,
          color: AppTheme.textSecondary(context),
          letterSpacing: -0.4,
        ),
        filled: true,
        fillColor: AppTheme.iosCard(context),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
      ),
    );
  }
}
