import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jiffy/jiffy.dart';

import 'package:glu_butler/l10n/app_localizations.dart';
import 'package:glu_butler/core/theme/app_theme.dart';
import 'package:glu_butler/core/theme/app_colors.dart';
import 'package:glu_butler/core/theme/app_decorations.dart';
import 'package:glu_butler/core/widgets/large_title_scroll_view.dart';
import 'package:glu_butler/core/widgets/settings_icon_button.dart';
import 'package:glu_butler/core/widgets/screen_fab.dart';
import 'package:glu_butler/core/widgets/modals/record_input_modal.dart';
import 'package:glu_butler/providers/feed_provider.dart';
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
                // Steps summary if connected
                if (provider.isHealthConnected && provider.todaySteps != null)
                  SliverToBoxAdapter(
                    child: _buildStepsSummary(context, provider.todaySteps!),
                  ),

                // Loading indicator
                if (provider.isLoading && provider.items.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  )
                // Empty state
                else if (provider.items.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _buildEmptyState(theme, l10n),
                  )
                // Feed items grouped by date
                else
                  ..._buildFeedContent(context, provider),
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

  Widget _buildStepsSummary(BuildContext context, int steps) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: context.decorations.cardElevated,
      child: Row(
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Today\'s Steps',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: context.colors.textSecondary,
                ),
              ),
              Text(
                _formatNumber(steps),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
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
            const Icon(
              Icons.timeline,
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
    );
  }

  List<Widget> _buildFeedContent(BuildContext context, FeedProvider provider) {
    final theme = Theme.of(context);
    final itemsByDate = provider.itemsByDate;
    final sortedDates = itemsByDate.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    final List<Widget> slivers = [];

    for (final date in sortedDates) {
      final items = itemsByDate[date]!;

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

      // Items for this date
      slivers.add(
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => FeedItemCard(item: items[index]),
            childCount: items.length,
          ),
        ),
      );
    }

    // Bottom padding for FAB
    slivers.add(
      const SliverToBoxAdapter(
        child: SizedBox(height: 100),
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
