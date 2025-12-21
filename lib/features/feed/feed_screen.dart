import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jiffy/jiffy.dart';

import 'package:glu_butler/l10n/app_localizations.dart';
import 'package:glu_butler/core/theme/app_theme.dart';
import 'package:glu_butler/core/theme/app_colors.dart';
import 'package:glu_butler/core/widgets/large_title_scroll_view.dart';
import 'package:glu_butler/core/widgets/settings_icon_button.dart';
import 'package:glu_butler/core/widgets/screen_fab.dart';
import 'package:glu_butler/core/widgets/modals/record_input_modal.dart';
import 'package:glu_butler/providers/feed_provider.dart';
import 'package:glu_butler/services/health_service.dart';
import 'package:glu_butler/features/feed/widgets/feed_item_card.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FeedProvider>().refreshData();
    });
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
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}k';
    }
    return number.toString();
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

    // Combine dates from both feed items and activity data
    final allDates = <DateTime>{
      ...itemsByDate.keys,
      ...provider.activityByDate.keys,
    }.toList()
      ..sort((a, b) => b.compareTo(a));

    final List<Widget> slivers = [];

    for (final date in allDates) {
      final items = itemsByDate[date] ?? [];
      final activityForDate = provider.activityByDate[date];

      // Skip if no items and no activity for this date
      if (items.isEmpty && activityForDate == null) continue;

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

      // Steps summary for this date
      if (provider.isHealthConnected && activityForDate != null) {
        slivers.add(
          SliverToBoxAdapter(
            child: _buildStepsSummary(context, activityForDate, l10n),
          ),
        );
      }

      // Items for this date
      if (items.isNotEmpty) {
        slivers.add(
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => FeedItemCard(item: items[index]),
              childCount: items.length,
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

    if (date == today) {
      return 'Today';
    } else if (date == yesterday) {
      return 'Yesterday';
    } else {
      return Jiffy.parseFromDateTime(date).format(pattern: 'EEEE, MMM d');
    }
  }
}
