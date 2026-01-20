import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'package:glu_butler/core/theme/app_theme.dart';
import 'package:glu_butler/core/theme/app_text_styles.dart';
import 'package:glu_butler/core/theme/app_colors.dart';
import 'package:glu_butler/core/theme/app_decorations.dart';
import 'package:glu_butler/core/widgets/keyboard_dismiss_button.dart';

/// 검증 기능이 있는 입력 다이얼로그
class InputDialog extends StatefulWidget {
  final String title;
  final String message;
  final String placeholder;
  final String buttonTitle;
  final String? Function(String)? validator;
  final ValueChanged<String>? onChanged;
  final Future<String?> Function(String)? onSubmit;
  final bool isButtonEnabled;
  final bool isLoading;

  const InputDialog({
    super.key,
    required this.title,
    required this.message,
    required this.placeholder,
    required this.buttonTitle,
    this.validator,
    this.onChanged,
    this.onSubmit,
    this.isButtonEnabled = true,
    this.isLoading = false,
  });

  @override
  State<InputDialog> createState() => _InputDialogState();
}

class _InputDialogState extends State<InputDialog> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  String? _errorMessage;
  bool _isLoading = false;
  OverlayEntry? _keyboardToolbarOverlay;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _keyboardToolbarOverlay?.remove();
    _keyboardToolbarOverlay = null;
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      _showKeyboardToolbar();
    } else {
      _hideKeyboardToolbar();
    }
  }

  void _showKeyboardToolbar() {
    if (_keyboardToolbarOverlay != null) return;
    _keyboardToolbarOverlay = KeyboardDismissButton.show(context, _focusNode);
  }

  void _hideKeyboardToolbar() {
    KeyboardDismissButton.hide(_keyboardToolbarOverlay);
    _keyboardToolbarOverlay = null;
  }

  Future<void> _validateAndSubmit() async {
    if (!widget.isButtonEnabled || widget.isLoading || _isLoading) return;

    final input = _controller.text.trim();

    // validator가 있으면 실행
    if (widget.validator != null) {
      final error = widget.validator!(input);
      if (error != null) {
        setState(() {
          _errorMessage = error;
        });
        return;
      }
    }

    // onSubmit 콜백이 있으면 실행 (비동기)
    if (widget.onSubmit != null) {
      setState(() {
        _isLoading = true;
      });

      final error = await widget.onSubmit!(input);

      if (!mounted) return;

      if (error != null) {
        setState(() {
          _isLoading = false;
          _errorMessage = error;
        });
        return;
      }

      // onSubmit이 성공하면 dialog는 onSubmit 내부에서 닫음
      return;
    }

    // onSubmit이 없으면 바로 닫기
    Navigator.pop(context, input);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 320,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 헤더
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 16),
              decoration: const BoxDecoration(
                // border: Border(
                //   bottom: BorderSide(color: Color(0xFFE0E0E0), width: 1),
                // ),
              ),
              child: Stack(
                children: [
                  // 타이틀 (정중앙)
                  Center(
                    child: Text(
                      widget.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  // X 버튼 (왼쪽)
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    child: CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => Navigator.pop(context),
                      child: const Icon(
                        CupertinoIcons.xmark,
                        size: 18,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 내용
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.message,
                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 48,
                    child: CupertinoTextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      placeholder: widget.placeholder,
                      keyboardType: TextInputType.emailAddress,
                      autofocus: true,
                      autocorrect: false,
                      enabled: !widget.isLoading && !_isLoading,
                      onChanged: widget.onChanged,
                      onSubmitted: (_) => _validateAndSubmit(),
                      style: context.textStyles.bodyText,
                      placeholderStyle: context.textStyles.bodyText.copyWith(
                        color: context.colors.textSecondary,
                      ),
                      decoration: context.decorations.card.copyWith(
                        border: Border.all(
                          color: _errorMessage != null
                              ? context.colors.error
                              : context.colors.divider,
                          width: 1,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _errorMessage!,
                      style: const TextStyle(fontSize: 12, color: Colors.red),
                    ),
                  ],
                  const SizedBox(height: 20),
                  // 확인 버튼
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: CupertinoButton(
                      color: (widget.isButtonEnabled && !widget.isLoading && !_isLoading)
                          ? AppTheme.primaryColor
                          : Colors.grey[300],
                      borderRadius: BorderRadius.circular(12),
                      padding: EdgeInsets.zero,
                      onPressed: (widget.isButtonEnabled && !widget.isLoading && !_isLoading) ? _validateAndSubmit : null,
                      child: (widget.isLoading || _isLoading)
                          ? SizedBox(
                              width: 24,
                              height: 24,
                              child: CupertinoActivityIndicator(
                                color: (widget.isButtonEnabled && !widget.isLoading && !_isLoading)
                                    ? Colors.white
                                    : Colors.grey[700],
                              ),
                            )
                          : Text(
                              widget.buttonTitle,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: widget.isButtonEnabled
                                    ? Colors.white
                                    : Colors.grey[700],
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
