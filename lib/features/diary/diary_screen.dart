import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'dart:io';

import 'package:glu_butler/l10n/app_localizations.dart';
import 'package:glu_butler/core/theme/app_theme.dart';
import 'package:glu_butler/core/theme/app_text_styles.dart';
import 'package:glu_butler/core/theme/app_colors.dart';
import 'package:glu_butler/core/theme/app_decorations.dart';
import 'package:glu_butler/core/widgets/large_title_scroll_view.dart';
import 'package:glu_butler/core/widgets/settings_icon_button.dart';
import 'package:glu_butler/core/widgets/top_banner.dart';
import 'package:glu_butler/core/widgets/modals/diary_input_modal.dart';
import 'package:glu_butler/models/diary_entry.dart';
import 'package:glu_butler/repositories/diary_repository.dart';

/// 일기 화면
///
/// 날짜별 건강 일기를 작성하고 조회하는 화면입니다.
/// [LargeTitleScrollView]를 사용하여 iOS 스타일 네비게이션을 구현합니다.
///
/// ## 주요 기능
/// - 날짜별 일기 목록 표시
/// - 일기 작성/수정/삭제
/// - Pull-to-refresh로 데이터 새로고침
/// - 빈 상태 표시 (기록이 없을 때)
///
/// ## 라우팅
/// - `/diary` - 탭바 인덱스 1
///
/// ## 관련 파일
/// - [LargeTitleScrollView] - iOS 스타일 스크롤뷰
/// - [MainShell] - 탭바 네비게이션
class DiaryScreen extends StatefulWidget {
  const DiaryScreen({super.key});

  static final GlobalKey<DiaryScreenState> globalKey =
      GlobalKey<DiaryScreenState>();

  @override
  State<DiaryScreen> createState() => DiaryScreenState();
}

class DiaryScreenState extends State<DiaryScreen> {
  final _diaryRepository = DiaryRepository();
  List<DiaryEntry> _entries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  Future<void> loadEntries() async {
    await _loadEntries();
  }

  Future<void> _loadEntries() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final entries = await _diaryRepository.fetch();
      if (mounted) {
        setState(() {
          _entries = entries;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[DiaryScreen] Error loading entries: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _onRefresh() async {
    await _loadEntries();
  }

  Future<void> _editEntry(DiaryEntry entry) async {
    final result = await DiaryInputModal.show(context, entry: entry);

    if (result == true) {
      await _loadEntries();
    }
  }

  Future<void> _deleteEntry(DiaryEntry entry) async {
    final l10n = AppLocalizations.of(context)!;

    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(l10n.deleteDiary),
        content: Text(l10n.deleteDiaryConfirmation),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _diaryRepository.delete(entry.id);

        if (mounted) {
          TopBanner.show(context, message: l10n.diaryDeleted, isSuccess: true);
          await _loadEntries();
        }
      } catch (e) {
        debugPrint('[DiaryScreen] Error deleting entry: $e');
        if (mounted) {
          TopBanner.show(
            context,
            message: l10n.diaryDeleteFailed,
            isSuccess: false,
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return LargeTitleScrollView(
      title: l10n.diary,
      onRefresh: _onRefresh,
      trailing: const SettingsIconButton(),
      slivers: [
        if (_isLoading)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_entries.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 80),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.book_outlined,
                      size: 80,
                      color: AppTheme.primaryColor,
                    ),
                    const SizedBox(height: 16),
                    Text(l10n.noRecords, style: theme.textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text(l10n.startTracking, style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.only(bottom: 80),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final entry = _entries[index];
                return _DiaryEntryCard(
                  entry: entry,
                  onEdit: () => _editEntry(entry),
                  onDelete: () => _deleteEntry(entry),
                );
              }, childCount: _entries.length),
            ),
          ),
      ],
    );
  }
}

class _DiaryEntryCard extends StatefulWidget {
  final DiaryEntry entry;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _DiaryEntryCard({
    required this.entry,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_DiaryEntryCard> createState() => _DiaryEntryCardState();
}

class _DiaryEntryCardState extends State<_DiaryEntryCard>
    with TickerProviderStateMixin {
  bool _isExpanded = false;
  bool _shouldOpenSlidable = false;
  late final SlidableController _slidableController;

  @override
  void initState() {
    super.initState();
    _slidableController = SlidableController(this);
  }

  @override
  void dispose() {
    _slidableController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _getPreviewText(String content) {
    // 최대 2줄까지만 표시
    final lines = content.split('\n');
    if (lines.length > 2) {
      return '${lines[0]}\n${lines[1]}...';
    }
    // 긴 한 줄도 잘라내기
    if (content.length > 100) {
      return '${content.substring(0, 100)}...';
    }
    return content;
  }

  bool _needsExpansion(String content) {
    final lines = content.split('\n');
    return lines.length > 2 || content.length > 100;
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final photos = widget.entry.files.take(3).toList();
    final remainingPhotos = widget.entry.files.length > 3
        ? widget.entry.files.length - 3
        : 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: GestureDetector(
          onHorizontalDragEnd: (details) async {
            // 왼쪽 스와이프 감지 (velocity가 음수)
            if (details.primaryVelocity != null &&
                details.primaryVelocity! < -500) {
              if (_isExpanded) {
                // 펼쳐진 상태면 먼저 줄이기
                setState(() {
                  _isExpanded = false;
                  _shouldOpenSlidable = true;
                });

                // 애니메이션 완료 대기 (300ms)
                await Future.delayed(const Duration(milliseconds: 300));

                if (mounted && _shouldOpenSlidable) {
                  // Slidable 자동 열기
                  _slidableController.openEndActionPane();
                  setState(() {
                    _shouldOpenSlidable = false;
                  });
                }
              }
            }
          },
          child: Slidable(
            key: Key(widget.entry.id),
            controller: _slidableController,
            enabled: !_isExpanded,
            endActionPane: ActionPane(
              motion: const ScrollMotion(),
              extentRatio: 0.35,
              children: [
                CustomSlidableAction(
                  onPressed: (context) => widget.onEdit(),
                  backgroundColor: CupertinoColors.systemBlue,
                  foregroundColor: CupertinoColors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: const Icon(CupertinoIcons.pencil, size: 24),
                ),
                CustomSlidableAction(
                  onPressed: (context) => widget.onDelete(),
                  backgroundColor: CupertinoColors.systemRed,
                  foregroundColor: CupertinoColors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: const Icon(CupertinoIcons.delete, size: 24),
                ),
              ],
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: context.decorations.card.copyWith(
                border: Border.all(color: context.colors.divider, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 날짜
                  Text(
                    _formatDate(widget.entry.timestamp),
                    style: context.textStyles.tileSubtitle.copyWith(
                      fontSize: 12,
                      color: context.colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // 내용
                  if (widget.entry.content.isNotEmpty) ...[
                    AnimatedSize(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOutCubic,
                      alignment: Alignment.topCenter,
                      child: Text(
                        _isExpanded
                            ? widget.entry.content
                            : _getPreviewText(widget.entry.content),
                        style: context.textStyles.bodyText,
                        maxLines: _isExpanded ? null : 2,
                        overflow: _isExpanded ? null : TextOverflow.ellipsis,
                      ),
                    ),
                    // 더보기/줄이기 버튼
                    if (_needsExpansion(widget.entry.content))
                      GestureDetector(
                        onTap: _toggleExpanded,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            _isExpanded ? l10n.showLess : l10n.showMore,
                            style: context.textStyles.tileSubtitle.copyWith(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],

                  // 사진 목록
                  if (photos.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        ...photos.map(
                          (file) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Image.file(
                                File(file.filePath),
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 60,
                                    height: 60,
                                    color: context.colors.divider,
                                    child: Icon(
                                      Icons.broken_image,
                                      color: context.colors.iconGrey,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                        if (remainingPhotos > 0)
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: context.colors.divider,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Center(
                              child: Text(
                                '+$remainingPhotos',
                                style: context.textStyles.tileTitle.copyWith(
                                  color: context.colors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
