import 'package:flutter/material.dart';
import 'dart:io';

import 'package:glu_butler/l10n/app_localizations.dart';
import 'package:glu_butler/core/theme/app_theme.dart';
import 'package:glu_butler/core/theme/app_text_styles.dart';
import 'package:glu_butler/core/theme/app_colors.dart';
import 'package:glu_butler/core/theme/app_decorations.dart';
import 'package:glu_butler/core/widgets/large_title_scroll_view.dart';
import 'package:glu_butler/core/widgets/settings_icon_button.dart';
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
            child: Center(
              child: CircularProgressIndicator(),
            ),
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
                    Text(
                      l10n.noRecords,
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.startTracking,
                      style: theme.textTheme.bodyMedium,
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
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final entry = _entries[index];
                  return _DiaryEntryCard(entry: entry);
                },
                childCount: _entries.length,
              ),
            ),
          ),
      ],
    );
  }
}

class _DiaryEntryCard extends StatelessWidget {
  final DiaryEntry entry;

  const _DiaryEntryCard({required this.entry});

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

  @override
  Widget build(BuildContext context) {
    final photos = entry.files.take(3).toList();
    final remainingPhotos = entry.files.length > 3 ? entry.files.length - 3 : 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: context.decorations.card.copyWith(
        border: Border.all(
          color: context.colors.divider,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 날짜
          Text(
            _formatDate(entry.timestamp),
            style: context.textStyles.tileSubtitle.copyWith(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),

          // 내용 (최대 2줄)
          if (entry.content.isNotEmpty)
            Text(
              _getPreviewText(entry.content),
              style: context.textStyles.bodyText,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

          // 사진 목록
          if (photos.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                ...photos.map((file) => Padding(
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
                              color: Colors.grey[300],
                              child: const Icon(Icons.broken_image),
                            );
                          },
                        ),
                      ),
                    )),
                if (remainingPhotos > 0)
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Text(
                        '+$remainingPhotos',
                        style: context.textStyles.tileTitle.copyWith(
                          color: Colors.grey[700],
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
    );
  }
}
