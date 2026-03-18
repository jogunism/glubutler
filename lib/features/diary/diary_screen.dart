import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
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
import 'package:glu_butler/core/widgets/swipeable_card.dart';
import 'package:glu_butler/models/diary_item.dart';
import 'package:glu_butler/models/diary_file.dart';
import 'package:glu_butler/providers/diary_provider.dart';
import 'package:glu_butler/features/diary/diary_image_viewer.dart';

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
  @override
  void initState() {
    super.initState();
  }

  Future<void> loadEntries() async {
    final provider = context.read<DiaryProvider>();
    await provider.refreshData();
  }

  Future<void> _onRefresh() async {
    final provider = context.read<DiaryProvider>();
    await provider.refreshData();
  }

  Future<void> _editEntry(DiaryItem entry) async {
    final result = await DiaryInputModal.show(context, entry: entry);

    if (result == true) {
      final provider = context.read<DiaryProvider>();
      await provider.refreshData();
    }
  }

  Future<void> _deleteEntry(DiaryItem entry) async {
    final l10n = AppLocalizations.of(context)!;

    // Use different message based on whether diary has meal records
    final message = entry.hasMealDetected
        ? l10n.deleteDiaryWithMealConfirmation
        : l10n.deleteDiaryConfirmation;

    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(l10n.deleteDiary),
        content: Text(message),
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

    // 취소를 누른 경우 열려있는 스와이프 카드 닫기
    if (confirmed != true) {
      SwipeableCardState.closeAnyOpenCard();
      return;
    }

    if (mounted) {
      final provider = context.read<DiaryProvider>();
      final success = await provider.deleteEntry(entry.id);

      if (mounted) {
        if (success) {
          TopBanner.show(context, message: l10n.diaryDeleted, isSuccess: true);
        } else {
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
    final diaryProvider = context.watch<DiaryProvider>();
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () {
        // Close any open swipeable card when tapping empty space
        SwipeableCardState.closeAnyOpenCard();
      },
      child: LargeTitleScrollView(
        title: l10n.diary,
        onRefresh: _onRefresh,
        trailing: const SettingsIconButton(),
        slivers: [
          if (diaryProvider.isLoading)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (diaryProvider.entries.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 155),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        CupertinoIcons.book_fill,
                        size: 80,
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(height: 16),
                      Text(l10n.noRecords, style: theme.textTheme.titleLarge),
                      const SizedBox(height: 8),
                      Text(
                        l10n.startTracking,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: context.colors.textSecondary,
                        ),
                      ),
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
                  final entry = diaryProvider.entries[index];
                  return _DiaryItemCard(
                    key: ValueKey(
                      '${entry.id}_${diaryProvider.refreshTimestamp}',
                    ),
                    entry: entry,
                    onEdit: () => _editEntry(entry),
                    onDelete: () => _deleteEntry(entry),
                  );
                }, childCount: diaryProvider.entries.length),
              ),
            ),
        ],
      ),
    );
  }
}

class _DiaryImageWidget extends StatelessWidget {
  final DiaryFile diaryFile;

  const _DiaryImageWidget({required this.diaryFile});

  @override
  Widget build(BuildContext context) {
    final file = File(diaryFile.filePath);

    return FutureBuilder<bool>(
      future: file.exists(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: context.colors.divider,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        final fileExists = snapshot.data ?? false;

        // 로컬 파일이 없지만 downloadUrl이 있으면 네트워크 이미지 사용
        if (!fileExists && diaryFile.downloadUrl != null) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.network(
              diaryFile.downloadUrl!,
              width: 60,
              height: 60,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: context.colors.divider,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(Icons.broken_image, color: context.colors.iconGrey),
              ),
            ),
          );
        }

        if (!fileExists) {
          return Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: context.colors.divider,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(Icons.broken_image, color: context.colors.iconGrey),
          );
        }

        return ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Image.file(
            file,
            width: 60,
            height: 60,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: context.colors.divider,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(Icons.broken_image, color: context.colors.iconGrey),
              );
            },
          ),
        );
      },
    );
  }
}

class _DiaryItemCard extends StatefulWidget {
  final DiaryItem entry;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _DiaryItemCard({
    super.key,
    required this.entry,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_DiaryItemCard> createState() => _DiaryItemCardState();
}

class _DiaryItemCardState extends State<_DiaryItemCard> {
  bool _isExpanded = false;

  String _formatDate(DateTime date) {
    // 로케일에 맞는 날짜 형식 사용
    final dateFormat = DateFormat.yMMMd().add_Hm();
    return dateFormat.format(date);
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

    return SwipeableCard(
      swipeable: true,
      useEdit: true,
      useRemove: true,
      onEdit: widget.onEdit,
      onDelete: widget.onDelete,
      onSwipeStart: () {
        // Collapse expanded content when swiping
        if (_isExpanded) {
          setState(() {
            _isExpanded = false;
          });
        }
      },
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
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
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 300),
                firstCurve: Curves.easeInOutCubic,
                secondCurve: Curves.easeInOutCubic,
                sizeCurve: Curves.easeInOutCubic,
                crossFadeState: _isExpanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                alignment: Alignment.topLeft,
                firstChild: Text(
                  _getPreviewText(widget.entry.content),
                  style: context.textStyles.bodyText,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                secondChild: Text(
                  widget.entry.content,
                  style: context.textStyles.bodyText,
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

            // 식사 감지 안내 메시지
            if (widget.entry.hasMealDetected) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    CupertinoIcons.checkmark_circle_fill,
                    size: 14,
                    color: AppTheme.iconGreen,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    l10n.mealAddedToFeed,
                    style: context.textStyles.tileSubtitle.copyWith(
                      fontSize: 11,
                      color: context.colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],

            // 사진 목록 (모두 표시)
            if (widget.entry.files.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.entry.files.asMap().entries.map((entry) {
                  final index = entry.key;
                  final file = entry.value;
                  return GestureDetector(
                    onTap: () {
                      DiaryImageViewer.show(
                        context,
                        files: widget.entry.files,
                        initialIndex: index,
                      );
                    },
                    child: _DiaryImageWidget(diaryFile: file),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
