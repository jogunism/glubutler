import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:glu_butler/l10n/app_localizations.dart';
import 'package:glu_butler/core/theme/app_theme.dart';
import 'package:glu_butler/core/theme/app_text_styles.dart';
import 'package:glu_butler/core/theme/app_colors.dart';
import 'package:glu_butler/core/theme/app_decorations.dart';

/// 혈당 입력 모달 팝업
///
/// home, feed 화면에서 [+] 버튼을 누르면 표시되는 바텀 시트입니다.
/// 혈당 수치와 측정 시점(식전/식후/공복)을 입력받습니다.
///
/// ## 사용법
/// ```dart
/// GlucoseInputModal.show(context);
/// ```
class GlucoseInputModal extends StatefulWidget {
  const GlucoseInputModal({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useRootNavigator: true,
      builder: (context) => const GlucoseInputModal(),
    );
  }

  @override
  State<GlucoseInputModal> createState() => _GlucoseInputModalState();
}

class _GlucoseInputModalState extends State<GlucoseInputModal> {
  final _glucoseController = TextEditingController();
  String _selectedTiming = 'fasting'; // fasting, beforeMeal, afterMeal
  DateTime _selectedTime = DateTime.now();

  @override
  void dispose() {
    _glucoseController.dispose();
    super.dispose();
  }

  void _save() {
    final glucoseValue = double.tryParse(_glucoseController.text);
    if (glucoseValue == null || glucoseValue <= 0) {
      // TODO: Show validation error
      return;
    }

    // TODO: Save to service/database
    debugPrint('Saving glucose: $glucoseValue mg/dL, timing: $_selectedTiming');

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: context.colors.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 드래그 핸들
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // 헤더
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      l10n.cancel,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Text(
                    l10n.addGlucose,
                    style: context.textStyles.tileTitle.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: _save,
                    child: Text(
                      l10n.save,
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 혈당 수치 입력
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.bloodGlucose,
                    style: context.textStyles.tileSubtitle,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: context.decorations.card.copyWith(
                      border: Border.all(
                        color: context.colors.divider,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _glucoseController,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d*\.?\d*')),
                            ],
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: '0',
                              hintStyle: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 20,
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 16),
                          child: Text(
                            l10n.mgdl,
                            style: context.textStyles.bodyTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 측정 시점 선택
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '측정 시점',
                    style: context.textStyles.tileSubtitle,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildTimingChip(
                        context,
                        label: l10n.fasting,
                        value: 'fasting',
                      ),
                      const SizedBox(width: 8),
                      _buildTimingChip(
                        context,
                        label: l10n.beforeMeal,
                        value: 'beforeMeal',
                      ),
                      const SizedBox(width: 8),
                      _buildTimingChip(
                        context,
                        label: l10n.afterMeal,
                        value: 'afterMeal',
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 시간 선택
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '측정 시간',
                    style: context.textStyles.tileSubtitle,
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _showTimePicker(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: context.decorations.card.copyWith(
                        border: Border.all(
                          color: context.colors.divider,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatTime(_selectedTime),
                            style: context.textStyles.tileTitle,
                          ),
                          Icon(
                            CupertinoIcons.time,
                            color: Colors.grey[400],
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildTimingChip(
    BuildContext context, {
    required String label,
    required String value,
  }) {
    final isSelected = _selectedTiming == value;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          setState(() {
            _selectedTiming = value;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primaryColor.withValues(alpha: 0.15)
                : context.colors.card,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppTheme.primaryColor : context.colors.divider,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected
                  ? AppTheme.primaryColor
                  : context.textStyles.tileTitle.color,
            ),
          ),
        ),
      ),
    );
  }

  void _showTimePicker(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 280,
        color: context.colors.card,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(
                  child: const Text('취소'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                CupertinoButton(
                  child: const Text('완료'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.time,
                initialDateTime: _selectedTime,
                use24hFormat: true,
                onDateTimeChanged: (DateTime newTime) {
                  setState(() {
                    _selectedTime = newTime;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
