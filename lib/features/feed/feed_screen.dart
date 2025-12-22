import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jiffy/jiffy.dart';
import 'package:intl/intl.dart';

import 'package:glu_butler/l10n/app_localizations.dart';
import 'package:glu_butler/core/theme/app_theme.dart';
import 'package:glu_butler/core/theme/app_colors.dart';
import 'package:glu_butler/core/widgets/large_title_scroll_view.dart';
import 'package:glu_butler/core/widgets/settings_icon_button.dart';
import 'package:glu_butler/core/widgets/screen_fab.dart';
import 'package:glu_butler/core/widgets/modals/record_input_modal.dart';
import 'package:glu_butler/providers/feed_provider.dart';
import 'package:glu_butler/services/health_service.dart';
import 'package:glu_butler/models/cgm_glucose_group.dart';
import 'package:glu_butler/features/feed/widgets/feed_item_card.dart';
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

    final l10n = AppLocalizations.of(context)!;
    final String message;
    final Color backgroundColor;

    if (result.isFullSuccess) {
      // All records synced successfully
      message = l10n.syncCompleteMessage(result.successCount);
      backgroundColor = Colors.green;
    } else if (result.hasFailures && result.successCount > 0) {
      // Partial success
      message = l10n.syncPartialMessage(result.successCount, result.totalAttempted);
      backgroundColor = Colors.orange;
    } else {
      // All failed
      message = l10n.syncFailedMessage;
      backgroundColor = Colors.red;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _onRefresh() async {
    await context.read<FeedProvider>().refreshData();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Consumer<FeedProvider>(
      builder: (context, provider, child) {
        return Stack(
          children: [
            LargeTitleScrollView(
              title: l10n.feed,
              onRefresh: _onRefresh,
              trailing: const SettingsIconButton(),
              slivers: [
                  // Loading indicator
                if (provider.isLoading && provider.items.isEmpty && provider.activityByDate.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  )
                // Empty state
                else if (provider.items.isEmpty && provider.activityByDate.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _buildEmptyState(theme, l10n),
                  )
                // Feed items grouped by date
                else
                  ..._buildFeedContent(context, provider, l10n),
              ],
            ),
            ScreenFab(
              onPressed: () => RecordInputModal.show(context),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStepsSummary(BuildContext context, DailyActivityData activity, AppLocalizations l10n) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.iconGreen.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.directions_walk,
                color: AppTheme.iconGreen,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        l10n.steps,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: context.colors.textSecondary,
                        ),
                      ),
                      Text(
                        ' · Health',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: context.colors.textSecondary.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        Text(
                          _formatNumber(activity.steps),
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (activity.distanceKm != null) ...[
                          const SizedBox(width: 12),
                          Text(
                            '${activity.distanceKm!.toStringAsFixed(1)} km',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: context.colors.textSecondary,
                            ),
                          ),
                        ],
                      ],
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

  String _formatNumber(int number) {
    final locale = Localizations.localeOf(context).toString();
    return NumberFormat.decimalPattern(locale).format(number);
  }

  Widget _buildEmptyState(ThemeData theme, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 80),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.view_agenda_outlined,
              size: 80,
              color: context.colors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.noRecords,
              style: theme.textTheme.titleLarge,
            ),
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

  List<Widget> _buildFeedContent(BuildContext context, FeedProvider provider, AppLocalizations l10n) {
    final theme = Theme.of(context);
    final itemsByDate = provider.itemsByDate;
    final cgmGroupsByDate = provider.cgmGroupsByDate;

    // Combine dates from feed items, activity data, and CGM groups
    // Normalize all dates to midnight to ensure proper deduplication
    final allDatesSet = <DateTime>{};
    for (final date in itemsByDate.keys) {
      allDatesSet.add(DateTime(date.year, date.month, date.day));
    }
    for (final date in provider.activityByDate.keys) {
      allDatesSet.add(DateTime(date.year, date.month, date.day));
    }
    for (final date in cgmGroupsByDate.keys) {
      allDatesSet.add(DateTime(date.year, date.month, date.day));
    }
    final allDates = allDatesSet.toList()..sort((a, b) => b.compareTo(a));

    final List<Widget> slivers = [];

    for (final date in allDates) {
      // Find items/groups/activity matching this date (comparing year, month, day only)
      final items = itemsByDate.entries
          .where((e) => e.key.year == date.year && e.key.month == date.month && e.key.day == date.day)
          .expand((e) => e.value)
          .toList();
      final cgmGroups = cgmGroupsByDate.entries
          .where((e) => e.key.year == date.year && e.key.month == date.month && e.key.day == date.day)
          .expand((e) => e.value)
          .toList();
      final activityEntry = provider.activityByDate.entries
          .where((e) => e.key.year == date.year && e.key.month == date.month && e.key.day == date.day)
          .firstOrNull;
      final activityForDate = activityEntry?.value;

      // Skip if no items, no CGM groups, and no activity for this date
      if (items.isEmpty && cgmGroups.isEmpty && activityForDate == null) continue;

      // Date header
      slivers.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              _formatDateHeader(date),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: context.colors.textSecondary,
              ),
            ),
          ),
        ),
      );

      // Steps summary for this date (show if we have read access and data exists)
      if (provider.hasHealthReadAccess && activityForDate != null) {
        slivers.add(
          SliverToBoxAdapter(
            child: _buildStepsSummary(context, activityForDate, l10n),
          ),
        );
      }

      // Build combined list of CGM groups and feed items, sorted by time
      final combinedItems = _buildCombinedItems(items, cgmGroups);

      // Render combined items
      if (combinedItems.isNotEmpty) {
        slivers.add(
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final item = combinedItems[index];
                if (item is CgmGlucoseGroup) {
                  return CgmGroupCard(group: item);
                } else {
                  return FeedItemCard(item: item);
                }
              },
              childCount: combinedItems.length,
            ),
          ),
        );
      }
    }

    // Bottom padding for FAB and tab bar
    slivers.add(
      const SliverToBoxAdapter(
        child: SizedBox(height: 120),
      ),
    );

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

  /// Combine feed items and CGM groups, sorted by time (newest first)
  List<dynamic> _buildCombinedItems(List items, List<CgmGlucoseGroup> cgmGroups) {
    final List<dynamic> combined = [];

    // Add feed items with their timestamps
    for (final item in items) {
      combined.add(item);
    }

    // Add CGM groups with their start times
    for (final group in cgmGroups) {
      combined.add(group);
    }

    // Sort by timestamp (newest first)
    combined.sort((a, b) {
      final DateTime timeA;
      final DateTime timeB;

      if (a is CgmGlucoseGroup) {
        timeA = a.startTime;
      } else {
        timeA = a.timestamp;
      }

      if (b is CgmGlucoseGroup) {
        timeB = b.startTime;
      } else {
        timeB = b.timestamp;
      }

      return timeB.compareTo(timeA);
    });

    return combined;
  }
}
