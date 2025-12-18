import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:glu_butler/l10n/app_localizations.dart';
import 'package:glu_butler/core/theme/app_theme.dart';
import 'package:glu_butler/core/theme/app_text_styles.dart';
import 'package:glu_butler/core/theme/app_colors.dart';
import 'package:glu_butler/core/theme/app_decorations.dart';

/// 일기 입력 모달 팝업
///
/// diary 화면에서 [+] 버튼을 누르면 표시되는 바텀 시트입니다.
/// 일기 제목과 내용을 입력받습니다.
///
/// ## 사용법
/// ```dart
/// DiaryInputModal.show(context);
/// ```
class DiaryInputModal extends StatefulWidget {
  const DiaryInputModal({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useRootNavigator: true,
      builder: (context) => const DiaryInputModal(),
    );
  }

  @override
  State<DiaryInputModal> createState() => _DiaryInputModalState();
}

class _DiaryInputModalState extends State<DiaryInputModal> {
  final _contentController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  final List<String> _attachedFiles = [];

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  void _save() {
    final content = _contentController.text.trim();

    if (content.isEmpty && _attachedFiles.isEmpty) {
      // TODO: Show validation error
      return;
    }

    // TODO: Save to service/database
    debugPrint('Saving diary with ${_attachedFiles.length} files');

    Navigator.of(context).pop();
  }

  void _pickFile() {
    // TODO: Implement file picker (image_picker package)
    debugPrint('Pick file');
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
                    l10n.addDiaryEntry,
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

            // 날짜 선택
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: GestureDetector(
                onTap: () => _showDatePicker(context),
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
                        _formatDate(_selectedDate),
                        style: context.textStyles.tileTitle,
                      ),
                      Icon(
                        CupertinoIcons.calendar,
                        color: Colors.grey[400],
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 내용 입력
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                height: 150,
                decoration: context.decorations.card.copyWith(
                  border: Border.all(
                    color: context.colors.divider,
                    width: 1,
                  ),
                ),
                child: TextField(
                  controller: _contentController,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  style: context.textStyles.bodyText,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: '오늘 하루를 기록해보세요...',
                    hintStyle: context.textStyles.tileSubtitle,
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 파일 업로드
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: GestureDetector(
                onTap: _pickFile,
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
                    children: [
                      Icon(
                        CupertinoIcons.paperclip,
                        color: Colors.grey[500],
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '파일 첨부',
                        style: context.textStyles.tileSubtitle,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _showDatePicker(BuildContext context) {
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
                mode: CupertinoDatePickerMode.date,
                initialDateTime: _selectedDate,
                maximumDate: DateTime.now(),
                onDateTimeChanged: (DateTime newDate) {
                  setState(() {
                    _selectedDate = newDate;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return '오늘';
    } else if (dateOnly == today.subtract(const Duration(days: 1))) {
      return '어제';
    } else {
      return '${date.year}년 ${date.month}월 ${date.day}일';
    }
  }
}
