import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'package:glu_butler/core/theme/app_theme.dart';

/// 검증 기능이 있는 입력 다이얼로그
class InputDialog extends StatefulWidget {
  final String title;
  final String message;
  final String placeholder;
  final String buttonTitle;
  final String? Function(String)? validator;

  const InputDialog({
    super.key,
    required this.title,
    required this.message,
    required this.placeholder,
    required this.buttonTitle,
    this.validator,
  });

  @override
  State<InputDialog> createState() => _InputDialogState();
}

class _InputDialogState extends State<InputDialog> {
  late final TextEditingController _controller;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _validateAndSubmit() {
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
                  CupertinoTextField(
                    controller: _controller,
                    placeholder: widget.placeholder,
                    keyboardType: TextInputType.emailAddress,
                    autofocus: true,
                    autocorrect: false,
                    onSubmitted: (_) => _validateAndSubmit(),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _errorMessage != null
                            ? Colors.red
                            : Colors.grey[300]!,
                        width: 1,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
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
                    child: CupertinoButton(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(8),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      onPressed: _validateAndSubmit,
                      child: Text(
                        widget.buttonTitle,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
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
