import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:jiffy/jiffy.dart';
import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';

import 'package:glu_butler/l10n/app_localizations.dart';
import 'package:glu_butler/core/theme/app_theme.dart';
import 'package:glu_butler/core/theme/app_colors.dart';
import 'package:glu_butler/core/widgets/large_title_scroll_view.dart';
import 'package:glu_butler/core/widgets/settings_icon_button.dart';
import 'package:glu_butler/core/widgets/tipkit_popover.dart';
import 'package:glu_butler/providers/feed_provider.dart';
import 'package:glu_butler/models/feed_item.dart';
import 'package:glu_butler/models/water_group.dart';
import 'package:glu_butler/features/feed/widgets/feed_item_card.dart';
import 'package:glu_butler/core/widgets/swipeable_card.dart';
import 'package:glu_butler/features/feed/widgets/cgm_group_card.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  // main.dart에서 FeedProvider.initialize()가 이미 데이터를 로드하므로
  // initState에서 refreshData() 호출 불필요

  @override
  void initState() {
    super.initState();
    // Set up migration completion callback for toast messages
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<FeedProvider>();
      provider.onMigrationComplete = _onMigrationComplete;
    });
  }

  @override
  void dispose() {
    // Clean up callback
    context.read<FeedProvider>().onMigrationComplete = null;
    super.dispose();
  }

  void _onMigrationComplete(MigrationResult result) {
    if (!mounted) return;

    // Log migration result without user notification
    if (result.isFullSuccess) {
      debugPrint(
        '[FeedScreen] Migration complete: ${result.successCount} records synced',
      );
    } else if (result.hasFailures && result.successCount > 0) {
      debugPrint(
        '[FeedScreen] Partial migration: ${result.successCount}/${result.totalAttempted} synced',
      );
    } else {
      debugPrint('[FeedScreen] Migration failed');
    }
  }

  Future<void> _onRefresh() async {
    final provider = context.read<FeedProvider>();
    await provider.refreshData();

    // Trigger bounce animation after refresh completes
    Future.delayed(const Duration(milliseconds: 700), () {
      provider.triggerBounce();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Consumer<FeedProvider>(
      builder: (context, provider, child) {
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTapDown: (_) {
            // 화면 어디든 터치하면 열린 카드 닫기
            SwipeableCardState.closeAnyOpenCard();
          },
          child: LargeTitleScrollView(
            title: l10n.feed,
            onRefresh: _onRefresh,
            trailing: const SettingsIconButton(),
            slivers: [
              // Loading indicator
              if (provider.isLoading &&
                  provider.items.isEmpty &&
                  provider.activityByDate.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                )
              // Empty state
              else if (provider.items.isEmpty &&
                  provider.activityByDate.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildEmptyState(theme, l10n),
                )
              // Feed items grouped by date
              else
                ..._buildFeedContent(context, provider, l10n),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(ThemeData theme, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 155),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              PlatformInfo.isIOS26OrHigher()
                  ? CupertinoIcons.rectangle_grid_1x2_fill
                  : CupertinoIcons.square_grid_2x2_fill,
              size: 80,
              color: AppTheme.primaryColor,
            ),
            const SizedBox(height: 16),
            Text(l10n.noRecords, style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              l10n.feedEmptyHint,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: context.colors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildFeedContent(
    BuildContext context,
    FeedProvider provider,
    AppLocalizations l10n,
  ) {
    final theme = Theme.of(context);
    final itemsByDate = provider.itemsByDate;

    // Get all dates from feed items
    final allDates = itemsByDate.keys.toList()..sort((a, b) => b.compareTo(a));

    final List<Widget> slivers = [];

    for (final date in allDates) {
      // Get items for this date
      final items = itemsByDate[date] ?? [];

      // Skip if no items for this date
      if (items.isEmpty) continue;

      // Get steps and water data for this date
      final stepsItem = items.firstWhere(
        (item) => item.type == FeedItemType.steps,
        orElse: () => FeedItem.fromSteps(date: date, steps: 0),
      );
      final waterItem = items.firstWhere(
        (item) => item.type == FeedItemType.waterGroup,
        orElse: () => FeedItem.fromWaterGroup(
          WaterGroup(id: 'empty', date: date, totalAmountMl: 0, records: []),
        ),
      );

      final stepsData = stepsItem.stepsData;
      final steps = stepsData?['steps'] as int? ?? 0;
      final waterGroup = waterItem.waterGroup;
      final waterLiters = (waterGroup?.totalAmountMl ?? 0) / 1000;

      // Get distance for this date from activityByDate
      final activityData = provider.activityByDate[date];
      final distanceKm = activityData?.distanceKm;

      // Check if this date has menstruation data
      final hasMenstruation = provider.menstruationDates.contains(date);

      // Format steps with comma separators
      final stepsText = steps.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},',
      );

      // Date header with activity summary
      slivers.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Text(
                  _formatDateHeader(date),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: context.colors.textSecondary,
                  ),
                ),
                const Spacer(),
                // Activity summary icons - tappable area
                if (steps > 0 || waterLiters > 0 || hasMenstruation)
                  Builder(
                    builder: (iconContext) {
                      final iconKey = GlobalKey();
                      return GestureDetector(
                        key: iconKey,
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          _showActivitySummary(
                            iconContext: iconContext,
                            iconKey: iconKey,
                            l10n: l10n,
                            steps: steps,
                            stepsText: stepsText,
                            distanceKm: distanceKm,
                            waterLiters: waterLiters,
                            hasMenstruation: hasMenstruation,
                          );
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Steps
                            if (steps > 0) ...[
                              Icon(
                                Icons.directions_walk,
                                size: 16,
                                color: AppTheme.iconGreen,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                stepsText,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: context.colors.textSecondary,
                                ),
                              ),
                              const SizedBox(width: 10),
                            ],
                            // Water
                            if (waterLiters > 0) ...[
                              Icon(
                                Icons.local_drink,
                                size: 16,
                                color: AppTheme.iconBlue,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '${waterLiters.toStringAsFixed(1)}L',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: context.colors.textSecondary,
                                ),
                              ),
                            ],
                            // Menstruation
                            if (hasMenstruation) ...[
                              const SizedBox(width: 10),
                              Icon(
                                Icons.local_florist,
                                size: 16,
                                color: Colors.pink[400],
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      );

      // Render items (already sorted by timestamp)
      if (items.isNotEmpty) {
        slivers.add(
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final item = items[index];
              // Skip steps and water group items (shown in header)
              if (item.type == FeedItemType.steps ||
                  item.type == FeedItemType.waterGroup) {
                return const SizedBox.shrink();
              }
              // Check if this is a CGM group type
              if (item.type == FeedItemType.cgmGroup) {
                final cgmGroup = item.cgmGroup!;
                // 6시간 블록 계산
                final blockStartHour = (cgmGroup.startTime.hour ~/ 6) * 6;
                final blockStart = DateTime(
                  cgmGroup.startTime.year,
                  cgmGroup.startTime.month,
                  cgmGroup.startTime.day,
                  blockStartHour,
                );
                final blockEnd = blockStart.add(const Duration(hours: 6));

                // 같은 6시간 블록 내의 이벤트들 찾기
                final eventsInRange = items.where((feedItem) {
                  if (feedItem.type == FeedItemType.cgmGroup ||
                      feedItem.type == FeedItemType.steps ||
                      feedItem.type == FeedItemType.waterGroup ||
                      feedItem.type == FeedItemType.sleepGroup) {
                    return false;
                  }
                  return feedItem.timestamp.isAfter(blockStart) &&
                      feedItem.timestamp.isBefore(blockEnd);
                }).toList();

                return CgmGroupCard(
                  group: cgmGroup,
                  eventsInRange: eventsInRange,
                );
              } else {
                return FeedItemCard(item: item);
              }
            }, childCount: items.length),
          ),
        );
      }
    }

    // Bottom padding for FAB and tab bar
    slivers.add(const SliverToBoxAdapter(child: SizedBox(height: 120)));

    return slivers;
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final l10n = AppLocalizations.of(context)!;

    if (date == today) {
      return l10n.today;
    } else if (date == yesterday) {
      return l10n.yesterday;
    } else {
      // Format date with locale using Jiffy
      // Jiffy locale is set globally in main.dart based on app locale
      final jiffy = Jiffy.parseFromDateTime(date);
      return jiffy.format(pattern: 'EEEE, MMM d');
    }
  }

  void _showActivitySummary({
    required BuildContext iconContext,
    required GlobalKey iconKey,
    required AppLocalizations l10n,
    required int steps,
    required String stepsText,
    required double? distanceKm,
    required double waterLiters,
    required bool hasMenstruation,
  }) {
    final RenderBox? renderBox =
        iconKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    showGeneralDialog(
      context: iconContext,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, animation, secondaryAnimation) {
        return TipKitPopover(
          targetPosition: position,
          targetSize: size,
          l10n: l10n,
          steps: steps,
          stepsText: stepsText,
          distanceKm: distanceKm,
          waterLiters: waterLiters,
          hasMenstruation: hasMenstruation,
          animation: animation,
        );
      },
    );
  }
}
