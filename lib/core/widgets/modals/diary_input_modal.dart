import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:uuid/uuid.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'dart:io';

import 'package:glu_butler/l10n/app_localizations.dart';
import 'package:glu_butler/core/theme/app_theme.dart';
import 'package:glu_butler/core/theme/app_text_styles.dart';
import 'package:glu_butler/core/theme/app_colors.dart';
import 'package:glu_butler/core/theme/app_decorations.dart';
import 'package:glu_butler/core/widgets/top_banner.dart';
import 'package:glu_butler/models/diary_entry.dart';
import 'package:glu_butler/models/diary_file.dart';
import 'package:glu_butler/repositories/diary_repository.dart';
import 'package:glu_butler/services/image_service.dart';

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
  final DiaryEntry? entry; // 수정 모드일 때 기존 엔트리

  const DiaryInputModal({super.key, this.entry});

  static Future<bool?> show(BuildContext context, {DiaryEntry? entry}) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useRootNavigator: true,
      isDismissible: false, // Prevent tap outside to close
      enableDrag: false,     // Disable drag completely
      builder: (context) => DiaryInputModal(entry: entry),
      routeSettings: const RouteSettings(name: 'DiaryInputModal'),
    );
  }

  @override
  State<DiaryInputModal> createState() => _DiaryInputModalState();
}

class _DiaryInputModalState extends State<DiaryInputModal> {
  final _contentController = TextEditingController();
  final _contentFocusNode = FocusNode();
  DateTime _selectedDate = DateTime.now();
  final List<File> _selectedImages = [];
  final _imagePicker = ImagePicker();
  final _imageService = ImageService();
  final _diaryRepository = DiaryRepository();
  bool _isSaving = false;
  static const int _maxImages = 5;

  OverlayEntry? _keyboardToolbarOverlay;

  @override
  void initState() {
    super.initState();
    _contentFocusNode.addListener(_onFocusChange);

    // 수정 모드일 경우 기존 데이터 로드
    if (widget.entry != null) {
      _contentController.text = widget.entry!.content;
      _selectedDate = widget.entry!.timestamp;

      // 기존 이미지 파일 로드
      for (final file in widget.entry!.files) {
        _selectedImages.add(File(file.filePath));
      }
    }
  }

  @override
  void dispose() {
    _keyboardToolbarOverlay?.remove();
    _keyboardToolbarOverlay = null;
    _contentFocusNode.removeListener(_onFocusChange);
    _contentFocusNode.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (_contentFocusNode.hasFocus) {
      _showKeyboardToolbar();
    } else {
      _hideKeyboardToolbar();
    }
  }

  void _showKeyboardToolbar() {
    if (_keyboardToolbarOverlay != null) return;

    _keyboardToolbarOverlay = OverlayEntry(
      builder: (context) {
        final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
        final brightness = MediaQuery.of(context).platformBrightness;
        final isDark = brightness == Brightness.dark;

        return Positioned(
          bottom: bottomPadding,
          left: 0,
          right: 0,
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1C1C1E) // iOS 다크모드 키보드 색상
                  : const Color(0xFFD1D5DB), // iOS 라이트모드 키보드 색상
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? const Color(0xFF38383A)
                      : const Color(0xFFB8B8B8),
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  onPressed: () {
                    FocusScope.of(context).unfocus();
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.keyboard,
                        size: 20,
                        color: isDark
                            ? const Color(0xFF98989D)
                            : const Color(0xFF6B7280),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.keyboard_arrow_down,
                        size: 20,
                        color: isDark
                            ? const Color(0xFF98989D)
                            : const Color(0xFF6B7280),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    Overlay.of(context).insert(_keyboardToolbarOverlay!);
  }

  void _hideKeyboardToolbar() {
    _keyboardToolbarOverlay?.remove();
    _keyboardToolbarOverlay = null;
  }

  Future<void> _save() async {
    final content = _contentController.text.trim();

    if (content.isEmpty && _selectedImages.isEmpty) {
      _showError('내용을 입력하거나 사진을 첨부해주세요.');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final isEditMode = widget.entry != null;
      final entryId = isEditMode ? widget.entry!.id : const Uuid().v4();
      final now = DateTime.now();

      // Process images
      final diaryFiles = <DiaryFile>[];
      for (int i = 0; i < _selectedImages.length; i++) {
        final imageFile = _selectedImages[i];

        // 기존 파일인지 새 파일인지 확인
        final existingFile = isEditMode
            ? widget.entry!.files.firstWhere(
                (f) => f.filePath == imageFile.path,
                orElse: () => DiaryFile(
                  id: '',
                  diaryId: '',
                  filePath: '',
                  createdAt: DateTime.now(),
                ),
              )
            : null;

        if (existingFile != null && existingFile.id.isNotEmpty) {
          // 기존 파일 유지
          diaryFiles.add(existingFile);
        } else {
          // 새 파일 처리
          // Extract metadata
          final metadata = await _imageService.extractMetadata(imageFile);

          // Resize image
          final resizedBytes = await _imageService.resizeImage(imageFile);

          // Save to documents
          final fileName = '${entryId}_$i.jpg';
          final savedPath = await _imageService.saveToDocuments(
            resizedBytes,
            fileName,
          );

          // Get file size
          final fileSize = resizedBytes.length;

          // Create DiaryFile
          diaryFiles.add(
            DiaryFile(
              id: const Uuid().v4(),
              diaryId: entryId,
              filePath: savedPath,
              latitude: metadata.latitude,
              longitude: metadata.longitude,
              capturedAt: metadata.capturedAt,
              fileSize: fileSize,
              createdAt: now,
            ),
          );
        }
      }

      // Create or update diary entry
      final entry = DiaryEntry(
        id: entryId,
        content: content,
        timestamp: _selectedDate,
        createdAt: isEditMode ? widget.entry!.createdAt : now,
        files: diaryFiles,
      );

      // Save or update to database
      final success = isEditMode
          ? await _diaryRepository.update(entry)
          : await _diaryRepository.save(entry);

      if (success) {
        if (mounted) {
          final l10n = AppLocalizations.of(context)!;
          Navigator.of(context).pop(true); // Return true to indicate success

          // Show success toast
          TopBanner.show(
            context,
            message: isEditMode ? l10n.diaryUpdated : l10n.diarySaved,
            isSuccess: true,
          );
        }
      } else {
        if (mounted) {
          final l10n = AppLocalizations.of(context)!;
          _showError(l10n.diarySaveFailed);
        }
      }
    } catch (e) {
      debugPrint('[DiaryInputModal] Error saving diary: $e');
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        _showError(l10n.diarySaveFailed);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      // 최대 5장 제한 체크
      if (_selectedImages.length >= _maxImages) {
        _showError('사진은 최대 $_maxImages장까지 첨부할 수 있습니다.');
        return;
      }

      // Request photo library permission - this shows the system dialog
      final PermissionState ps = await PhotoManager.requestPermissionExtend();

      if (ps != PermissionState.authorized && ps != PermissionState.limited) {
        _showPermissionError();
        return;
      }

      // 여러 장 선택 가능
      final pickedFiles = await _imagePicker.pickMultiImage(
        requestFullMetadata: true, // Request full metadata including EXIF
      );

      if (pickedFiles.isNotEmpty) {
        // 선택 가능한 최대 개수 계산
        final remainingSlots = _maxImages - _selectedImages.length;
        final filesToAdd = pickedFiles.take(remainingSlots).toList();

        // 각 파일 형식 검증
        final validFiles = <File>[];
        for (final pickedFile in filesToAdd) {
          final extension = pickedFile.path.toLowerCase();
          if (extension.endsWith('.jpg') ||
              extension.endsWith('.jpeg') ||
              extension.endsWith('.png') ||
              extension.endsWith('.heic')) {
            validFiles.add(File(pickedFile.path));
          }
        }

        if (validFiles.isEmpty) {
          _showError('이미지 파일만 선택할 수 있습니다.');
          return;
        }

        setState(() {
          _selectedImages.addAll(validFiles);
        });

        // 최대 개수 초과 시 알림
        if (pickedFiles.length > remainingSlots) {
          _showError(
            '최대 $_maxImages장까지만 첨부 가능합니다. ${validFiles.length}장이 추가되었습니다.',
          );
        }
      }
    } catch (e) {
      debugPrint('[DiaryInputModal] Error picking image: $e');
      _showError('사진을 불러오는데 실패했습니다.');
    }
  }

  void _showPermissionError() {
    if (!mounted) return;
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('사진 접근 권한 필요'),
        content: const Text(
          '사진을 첨부하려면 사진 라이브러리 접근 권한이 필요합니다.\n\n설정 > Glu Butler에서 사진 접근을 허용해주세요.',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('취소'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('설정으로 이동'),
            onPressed: () async {
              Navigator.of(context).pop();
              // Open iOS app settings
              final Uri url = Uri.parse('app-settings:');
              if (await canLaunchUrl(url)) {
                await launchUrl(url);
              }
            },
          ),
        ],
      ),
    );
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  void _showError(String message) {
    if (!mounted) return;
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('오류'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('확인'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  bool get _hasUnsavedChanges {
    return _contentController.text.trim().isNotEmpty ||
        _selectedImages.isNotEmpty;
  }

  Future<bool> _confirmDiscard(BuildContext context) async {
    if (!_hasUnsavedChanges) {
      return true; // 변경사항 없으면 바로 닫기
    }

    final l10n = AppLocalizations.of(context)!;

    final result = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(l10n.discardDiaryTitle),
        content: Text(l10n.discardDiaryMessage),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(false), // 아니오 - 모달 유지
            child: Text(l10n.no),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(context).pop(true), // 예 - 닫기
            child: Text(l10n.yes),
          ),
        ],
      ),
    );

    return result ?? false; // null이면 false (모달 유지)
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return GestureDetector(
      // Handle tap on dimmed area (barrier)
      behavior: HitTestBehavior.opaque,
      onTap: () async {
        if (!_hasUnsavedChanges) {
          Navigator.of(context).pop();
        } else {
          final shouldClose = await _confirmDiscard(context);
          if (shouldClose && context.mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: GestureDetector(
        // Prevent taps on the modal itself from triggering dismiss
        onTap: () {
          // 키보드 닫기
          FocusScope.of(context).unfocus();
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Flexible spacer to push content to bottom
            Flexible(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () async {
                  if (!_hasUnsavedChanges) {
                    Navigator.of(context).pop();
                  } else {
                    final shouldClose = await _confirmDiscard(context);
                    if (shouldClose && context.mounted) {
                      Navigator.of(context).pop();
                    }
                  }
                },
                child: Container(),
              ),
            ),
            // Actual modal content
            Container(
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
                        onPressed: () async {
                          final shouldClose = await _confirmDiscard(context);
                          if (shouldClose && context.mounted) {
                            Navigator.of(context).pop();
                          }
                        },
                        child: Text(
                          l10n.cancel,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Text(
                        widget.entry != null ? l10n.editDiary : l10n.addDiaryEntry,
                        style: context.textStyles.tileTitle.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: _isSaving ? null : _save,
                        child: _isSaving
                            ? const CupertinoActivityIndicator()
                            : Text(
                                l10n.save,
                                style: TextStyle(
                                  color: _isSaving
                                      ? Colors.grey
                                      : AppTheme.primaryColor,
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
                      focusNode: _contentFocusNode,
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      style: context.textStyles.bodyText,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: l10n.diaryPlaceholder,
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
                    onTap: _isSaving ? null : _pickImage,
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
                            CupertinoIcons.photo,
                            color: Colors.grey[500],
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            l10n.attachPhoto,
                            style: context.textStyles.tileSubtitle,
                          ),
                          if (_selectedImages.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Text(
                              '(${_selectedImages.length})',
                              style: context.textStyles.tileSubtitle.copyWith(
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),

                // 선택된 이미지 목록
                if (_selectedImages.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 50,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: _selectedImages.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.file(
                                  _selectedImages[index],
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              if (!_isSaving)
                                Positioned(
                                  top: 2,
                                  right: 2,
                                  child: GestureDetector(
                                    onTap: () => _removeImage(index),
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: const BoxDecoration(
                                        color: Colors.black54,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        CupertinoIcons.xmark,
                                        color: Colors.white,
                                        size: 12,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],

                const SizedBox(height: 32),
              ],
            ),
          ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDatePicker(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

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
                  child: Text(l10n.cancel),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                CupertinoButton(
                  child: Text(l10n.done),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.dateAndTime,
                initialDateTime: _selectedDate,
                maximumDate: DateTime.now(),
                minuteInterval: 5,
                use24hFormat: true,
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
    // Use locale-aware date formatting
    final dateFormat = DateFormat.yMMMd().add_Hm();
    return dateFormat.format(date);
  }
}
