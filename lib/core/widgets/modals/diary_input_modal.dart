import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:uuid/uuid.dart';
import 'package:app_settings/app_settings.dart';
import 'package:intl/intl.dart';
import 'dart:io';

import 'package:glu_butler/l10n/app_localizations.dart';
import 'package:glu_butler/core/theme/app_theme.dart';
import 'package:glu_butler/core/theme/app_text_styles.dart';
import 'package:glu_butler/core/theme/app_colors.dart';
import 'package:glu_butler/core/theme/app_decorations.dart';
import 'package:glu_butler/core/widgets/top_banner.dart';
import 'package:glu_butler/models/diary_item.dart';
import 'package:glu_butler/models/diary_file.dart';
import 'package:glu_butler/repositories/meal_repository.dart';
import 'package:glu_butler/models/meal_record.dart';
import 'package:glu_butler/services/image_service.dart';
import 'package:glu_butler/services/vision_service.dart';
import 'package:glu_butler/services/database_service.dart';
import 'package:glu_butler/services/cloudkit_service.dart';
import 'package:glu_butler/services/firestore_service.dart';
import 'package:glu_butler/services/settings_service.dart';
import 'package:glu_butler/services/analytics_service.dart';
import 'package:glu_butler/providers/diary_provider.dart';
import 'package:glu_butler/providers/feed_provider.dart';
import 'package:glu_butler/core/widgets/keyboard_dismiss_button.dart';
import 'package:provider/provider.dart';
import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';

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
  final DiaryItem? entry; // 수정 모드일 때 기존 엔트리

  const DiaryInputModal({super.key, this.entry});

  static Future<bool?> show(BuildContext context, {DiaryItem? entry}) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useRootNavigator: true,

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
  final _visionService = VisionService();
  final _mealRepository = MealRepository();
  final _databaseService = DatabaseService();
  bool _isSaving = false;
  bool _addMealToFeed = false;
  int _mealWindowMinutes = 30; // 30, 60, 90, 120
  static const int _maxImages = 5;

  // 초기 상태 저장 (변경사항 감지용)
  late String _initialContent;
  late List<String> _initialImagePaths;

  OverlayEntry? _keyboardToolbarOverlay;

  @override
  void initState() {
    super.initState();
    _contentFocusNode.addListener(_onFocusChange);

    // Log diary input opened
    AnalyticsService.logDiaryInputOpened();

    // 수정 모드일 경우 기존 데이터 로드
    if (widget.entry != null) {
      _contentController.text = widget.entry!.content;
      _selectedDate = widget.entry!.timestamp;
      _addMealToFeed = widget.entry!.hasMealDetected;

      // 기존 이미지 파일 로드 (상대 경로를 절대 경로로 해결 후 추가)
      _loadExistingImages(widget.entry!.files);
      return; // _initialImagePaths는 _loadExistingImages 완료 후 설정
    }

    // 초기 상태 저장
    _initialContent = _contentController.text;
    _initialImagePaths = _selectedImages.map((f) => f.path).toList();
  }

  Future<void> _loadExistingImages(List<DiaryFile> files) async {
    final resolved = <File>[];
    for (final file in files) {
      final fullPath = await ImageService.resolveFullPath(file.filePath);
      resolved.add(File(fullPath));
    }
    if (!mounted) return;
    setState(() {
      _selectedImages.addAll(resolved);
      _initialContent = _contentController.text;
      _initialImagePaths = _selectedImages.map((f) => f.path).toList();
    });
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
    _keyboardToolbarOverlay = KeyboardDismissButton.show(
      context,
      _contentFocusNode,
    );
  }

  void _hideKeyboardToolbar() {
    KeyboardDismissButton.hide(_keyboardToolbarOverlay);
    _keyboardToolbarOverlay = null;
  }

  Future<void> _save() async {
    final content = _contentController.text.trim();
    final l10n = AppLocalizations.of(context)!;

    if (content.isEmpty && _selectedImages.isEmpty) {
      _showError(l10n.diaryContentRequired);
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

      // 사진을 촬영 시간 순서로 정렬 (먼저 찍힌 사진이 앞에)
      diaryFiles.sort((a, b) {
        final aTime = a.capturedAt ?? a.createdAt;
        final bTime = b.capturedAt ?? b.createdAt;
        return aTime.compareTo(bTime);
      });

      // Create or update diary entry
      final entry = DiaryItem(
        id: entryId,
        content: content,
        timestamp: _selectedDate,
        createdAt: isEditMode ? widget.entry!.createdAt : now,
        files: diaryFiles,
        hasMealDetected: _addMealToFeed,
      );

      // Save or update to database via DiaryProvider (handles iCloud sync)
      if (!mounted) return;
      final diaryProvider = context.read<DiaryProvider>();
      final success = isEditMode
          ? await diaryProvider.updateEntry(entry)
          : await diaryProvider.addEntry(entry);

      if (success) {
        // Log diary saved or edited
        if (isEditMode) {
          AnalyticsService.logDiaryEdited();
        } else {
          AnalyticsService.logDiarySaved();
        }

        debugPrint('[DiaryInputModal] _addMealToFeed=$_addMealToFeed, date=${entry.timestamp}');
        // 체크박스 상태에 따라 meal 레코드 생성/재생성
        if (_addMealToFeed) {
          if (isEditMode) {
            // 수정 모드: 기존 meal 삭제 후 재생성
            final deletedCount = await _databaseService.deleteMealsByDiaryId(
              entry.id,
            );
            debugPrint(
              '[DiaryInputModal] Deleted $deletedCount existing meal records for diary ${entry.id}',
            );
            _deleteMealsFromICloudIfEnabled(entry.id);
          }
          await _createMealRecordIfNeeded(
            entry,
            mealWindowMinutes: _mealWindowMinutes,
          );
        } else if (isEditMode) {
          // 수정 모드에서 체크 해제된 경우: 기존 meal 삭제
          final deletedCount = await _databaseService.deleteMealsByDiaryId(
            entry.id,
          );
          debugPrint(
            '[DiaryInputModal] Deleted $deletedCount meal records (unchecked) for diary ${entry.id}',
          );
          _deleteMealsFromICloudIfEnabled(entry.id);
        }

        if (mounted) {
          final l10n = AppLocalizations.of(context)!;
          // Refresh feed so meal records saved for any date are immediately visible
          debugPrint('[DiaryInputModal] Triggering FeedProvider.refreshData()');
          context.read<FeedProvider>().refreshData();
          Navigator.of(context).pop(true);

          String message = isEditMode ? l10n.diaryUpdated : l10n.diarySaved;
          if (_addMealToFeed) {
            message += '\n${l10n.mealAddedToFeed}';
          }

          TopBanner.show(context, message: message, isSuccess: true);
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

      // 선택 가능한 최대 개수 계산
      final remainingSlots = _maxImages - _selectedImages.length;

      if (remainingSlots <= 0) {
        final l10n = AppLocalizations.of(context)!;
        _showError(l10n.maxImagesReached(0, _maxImages));
        return;
      }

      // 여러 장 선택 가능 (최대 remainingSlots까지만)
      final pickedFiles = await _imagePicker.pickMultiImage(
        requestFullMetadata: true,
        limit: remainingSlots, // 최대 선택 개수 제한
      );

      if (pickedFiles.isNotEmpty) {
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
          final l10n = AppLocalizations.of(context)!;
          _showError(l10n.onlyImageFiles);
          return;
        }

        setState(() {
          _selectedImages.addAll(validFiles);
        });

        // Log photo added
        AnalyticsService.logDiaryPhotoAdded();

        // Vision Framework로 음식 사진 분석
        _analyzeFoodPhotos(validFiles);

        // 최대 개수 초과 시 알림
        if (pickedFiles.length > remainingSlots) {
          final l10n = AppLocalizations.of(context)!;
          _showError(l10n.maxImagesReached(validFiles.length, _maxImages));
        }
      }
    } catch (e) {
      debugPrint('[DiaryInputModal] Error picking image: $e');
      final l10n = AppLocalizations.of(context)!;
      _showError(l10n.imageLoadFailed);
    }
  }

  /// 업로드된 사진들을 분석하여 음식 감지 시 체크박스 자동 체크
  Future<void> _analyzeFoodPhotos(List<File> newImages) async {
    if (newImages.isEmpty) return;

    try {
      for (final imageFile in newImages) {
        final result = await _visionService.analyzeFoodPhoto(imageFile.path);
        if (result.isFood) {
          debugPrint(
            '[DiaryInputModal] Food detected: ${result.foodDescription}',
          );
          if (mounted) {
            setState(() {
              _addMealToFeed = true;
            });
          }
          break;
        }
      }
    } catch (e) {
      debugPrint('[DiaryInputModal] Error analyzing food photos: $e');
    }
  }

  void _showPermissionError() {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(l10n.photoPermissionRequired),
        content: Text(l10n.photoPermissionMessage),
        actions: [
          CupertinoDialogAction(
            child: Text(l10n.cancel),
            onPressed: () => Navigator.of(context).pop(),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: Text(l10n.goToSettings),
            onPressed: () async {
              Navigator.of(context).pop();
              await AppSettings.openAppSettings();
            },
          ),
        ],
      ),
    );
  }

  /// meal 레코드 생성 (체크박스가 체크된 경우 호출)
  /// 음식 사진이 있으면 촬영 시간 기준으로 그룹화, 없으면 일기 시간으로 단일 레코드 생성
  Future<void> _createMealRecordIfNeeded(
    DiaryItem entry, {
    int mealWindowMinutes = 30,
  }) async {
    try {
      // 1. 음식 사진 감지 및 수집
      final List<_FoodPhoto> foodPhotos = [];
      for (final file in entry.files) {
        final result = await _visionService.analyzeFoodPhoto(file.filePath);
        if (result.isFood) {
          foodPhotos.add(
            _FoodPhoto(
              file: file,
              foodName: result.foodDescription,
              captureTime: file.capturedAt ?? entry.timestamp,
            ),
          );
        }
      }

      // 2. 그룹화
      final List<List<_FoodPhoto>> mealGroups;
      if (foodPhotos.isNotEmpty) {
        foodPhotos.sort((a, b) => a.captureTime.compareTo(b.captureTime));
        mealGroups = [];
        List<_FoodPhoto> currentGroup = [foodPhotos.first];
        for (int i = 1; i < foodPhotos.length; i++) {
          final timeDiff = foodPhotos[i].captureTime.difference(
            currentGroup.first.captureTime,
          );
          if (timeDiff.inMinutes <= mealWindowMinutes) {
            currentGroup.add(foodPhotos[i]);
          } else {
            mealGroups.add(currentGroup);
            currentGroup = [foodPhotos[i]];
          }
        }
        mealGroups.add(currentGroup);
      } else {
        // 음식 사진 없음: 사용자가 수동으로 체크 → 일기 시간으로 단일 레코드
        mealGroups = [[]];
      }

      // 3. 각 그룹마다 meal 레코드 생성 (중복 체크)
      final now = DateTime.now();
      int createdCount = 0;

      debugPrint('[DiaryInputModal] mealGroups=${mealGroups.length}, foodPhotos=${foodPhotos.length}');
      for (final group in mealGroups) {
        final mealTime = group.isNotEmpty
            ? group.first.captureTime
            : entry.timestamp;

        debugPrint('[DiaryInputModal] Checking meal at $mealTime');
        final hasDuplicate = await _databaseService.hasMealInTimeRange(
          mealTime,
        );
        if (hasDuplicate) {
          debugPrint('[DiaryInputModal] Skipped duplicate meal at $mealTime');
          continue;
        }

        final foodNames = group
            .where((p) => p.foodName.isNotEmpty)
            .map((p) => p.foodName)
            .toSet()
            .join(', ');

        final mealRecord = MealRecord(
          id: const Uuid().v4(),
          diaryId: entry.id,
          foodName: foodNames.isNotEmpty ? foodNames : null,
          mealTime: mealTime,
          createdAt: now,
          mealWindowMinutes: mealWindowMinutes,
        );

        final success = await _mealRepository.save(mealRecord);
        if (success) {
          createdCount++;
          _syncMealToICloudIfEnabled(mealRecord);
        }
      }

      debugPrint(
        '[DiaryInputModal] Created $createdCount meal records (window: ${mealWindowMinutes}min)',
      );
    } catch (e) {
      debugPrint('[DiaryInputModal] Error creating meal records: $e');
    }
  }

  /// 클라우드에 식사 기록 업로드 (백그라운드, 에러 무시)
  void _syncMealToICloudIfEnabled(MealRecord meal) {
    final settings = context.read<SettingsService>();
    if (!settings.isCloudSyncEnabled) return;

    if (Platform.isIOS) {
      CloudKitService.uploadMealRecord(meal).catchError((_) {});
    } else {
      final googleId = settings.userIdentity.googleId;
      if (googleId == null || googleId.isEmpty) return;
      FirestoreService.uploadMealRecord(googleId, meal).catchError((_) {});
    }
  }

  /// 클라우드에서 다이어리 관련 식사 기록 삭제 (백그라운드, 에러 무시)
  void _deleteMealsFromICloudIfEnabled(String diaryId) {
    final settings = context.read<SettingsService>();
    if (!settings.isCloudSyncEnabled) return;

    if (Platform.isIOS) {
      CloudKitService.deleteMealRecordsByDiaryId(diaryId).catchError((_) {});
    } else {
      final googleId = settings.userIdentity.googleId;
      if (googleId == null || googleId.isEmpty) return;
      FirestoreService.deleteMealRecordsByDiaryId(googleId, diaryId).catchError((_) {});
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  void _showError(String message) {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: Text(l10n.confirm),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  bool get _hasUnsavedChanges {
    // 현재 상태
    final currentContent = _contentController.text.trim();
    final currentImagePaths = _selectedImages.map((f) => f.path).toList();

    // 내용이 변경되었는지 확인
    final contentChanged = currentContent != _initialContent;

    // 이미지가 변경되었는지 확인 (순서 상관없이 비교)
    final imagesChanged =
        currentImagePaths.length != _initialImagePaths.length ||
        !currentImagePaths.every((path) => _initialImagePaths.contains(path));

    return contentChanged || imagesChanged;
  }

  Future<bool> _confirmDiscard(BuildContext context) async {
    if (!_hasUnsavedChanges) {
      return true; // 변경사항 없으면 바로 닫기
    }

    final l10n = AppLocalizations.of(context)!;

    final result = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
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
        child: LayoutBuilder(
          builder: (context, constraints) => Column(
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
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: constraints.maxHeight),
              child: Container(
              decoration: BoxDecoration(
                color: context.colors.card,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(bottom: bottomPadding),
                  child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 드래그 핸들
                    Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.dividerLight,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),

                    // 취소/저장 버튼
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          CupertinoButton(
                            padding: EdgeInsets.zero,
                            onPressed: () async {
                              final shouldClose = await _confirmDiscard(
                                context,
                              );
                              if (shouldClose && context.mounted) {
                                Navigator.of(context).pop();
                              }
                            },
                            child: Text(
                              l10n.cancel,
                              style: const TextStyle(
                                color: AppTheme.textSecondaryLight,
                                fontSize: 16,
                              ),
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
                                          ? AppTheme.textSecondaryLight
                                          : AppTheme.primaryColor,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),

                    // 타이틀
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Center(
                        child: Text(
                          widget.entry != null
                              ? l10n.editDiary
                              : l10n.addDiaryItem,
                          style: context.textStyles.tileTitle.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

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
                              const Icon(
                                CupertinoIcons.calendar,
                                color: AppTheme.textSecondaryLight,
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
                              const Icon(
                                CupertinoIcons.photo,
                                color: AppTheme.textSecondaryLight,
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
                                  style: context.textStyles.tileSubtitle
                                      .copyWith(color: AppTheme.primaryColor),
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
                                          decoration: BoxDecoration(
                                            color: Colors.black.withValues(
                                              alpha: 0.54,
                                            ),
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

                    const SizedBox(height: 12),

                    // 피드에 식사 추가 체크박스
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () =>
                                setState(() => _addMealToFeed = !_addMealToFeed),
                            behavior: HitTestBehavior.opaque,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _addMealToFeed
                                      ? CupertinoIcons.checkmark_square_fill
                                      : CupertinoIcons.square,
                                  color: _addMealToFeed
                                      ? AppTheme.primaryColor
                                      : AppTheme.textSecondaryLight,
                                  size: 22,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  l10n.diaryAddMealToFeed,
                                  style: context.textStyles.tileTitle.copyWith(
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          if (_addMealToFeed)
                            Listener(
                              onPointerDown: (_) => _contentFocusNode.unfocus(),
                              child: MediaQuery(
                                  data: MediaQuery.of(context).copyWith(
                                    platformBrightness: Theme.of(
                                      context,
                                    ).brightness,
                                  ),
                                  child: AdaptivePopupMenuButton.widget<int>(
                                    items: [
                                      AdaptivePopupMenuItem<int>(
                                        value: 30,
                                        label: l10n.mealWindow30min,
                                        icon: _mealWindowMinutes == 30
                                            ? 'checkmark'
                                            : null,
                                      ),
                                      AdaptivePopupMenuItem<int>(
                                        value: 60,
                                        label: l10n.mealWindow1hour,
                                        icon: _mealWindowMinutes == 60
                                            ? 'checkmark'
                                            : null,
                                      ),
                                      AdaptivePopupMenuItem<int>(
                                        value: 90,
                                        label: l10n.mealWindow1hour30min,
                                        icon: _mealWindowMinutes == 90
                                            ? 'checkmark'
                                            : null,
                                      ),
                                      AdaptivePopupMenuItem<int>(
                                        value: 120,
                                        label: l10n.mealWindow2hours,
                                        icon: _mealWindowMinutes == 120
                                            ? 'checkmark'
                                            : null,
                                      ),
                                    ],
                                    onSelected: (index, item) {
                                      if (item.value != null) {
                                        setState(
                                          () =>
                                              _mealWindowMinutes = item.value!,
                                        );
                                      }
                                    },
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          _mealWindowLabel(l10n),
                                          style: context.textStyles.tileSubtitle
                                              .copyWith(
                                                color: AppTheme.primaryColor,
                                              ),
                                        ),
                                        const SizedBox(width: 4),
                                        const Icon(
                                          CupertinoIcons.chevron_down,
                                          size: 14,
                                          color: AppTheme.primaryColor,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 24),
                  ],
                ),
                ),
              ),
            ),
            ),
          ],
          ),
        ),
      ),
    );
  }

  String _mealWindowLabel(AppLocalizations l10n) {
    switch (_mealWindowMinutes) {
      case 30:
        return l10n.mealWindow30min;
      case 60:
        return l10n.mealWindow1hour;
      case 90:
        return l10n.mealWindow1hour30min;
      case 120:
        return l10n.mealWindow2hours;
      default:
        return l10n.mealWindow30min;
    }
  }

  void _showDatePicker(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // 키보드가 다시 올라오지 않도록 포커스 해제
    _contentFocusNode.unfocus();

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

/// 음식 사진 정보를 담는 헬퍼 클래스
class _FoodPhoto {
  final DiaryFile file;
  final String foodName;
  final DateTime captureTime;

  _FoodPhoto({
    required this.file,
    required this.foodName,
    required this.captureTime,
  });
}
