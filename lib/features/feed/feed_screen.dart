import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jiffy/jiffy.dart';

import 'package:glu_butler/l10n/app_localizations.dart';
import 'package:glu_butler/core/theme/app_theme.dart';
import 'package:glu_butler/core/theme/app_colors.dart';
import 'package:glu_butler/core/widgets/large_title_scroll_view.dart';
import 'package:glu_butler/core/widgets/settings_icon_button.dart';
import 'package:glu_butler/providers/feed_provider.dart';
import 'package:glu_butler/models/feed_item.dart';
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
      backgroundColor = AppTheme.iconGreen;
    } else if (result.hasFailures && result.successCount > 0) {
      // Partial success
      message = l10n.syncPartialMessage(result.successCount, result.totalAttempted);
      backgroundColor = AppTheme.iconOrange;
    } else {
      // All failed
      message = l10n.syncFailedMessage;
      backgroundColor = AppTheme.iconRed;
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
        return LargeTitleScrollView(
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
        );
      },
    );
  }

  Widget _buildEmptyState(ThemeData theme, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 80),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.list_alt_outlined,
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

    // Get all dates from feed items
    final allDates = itemsByDate.keys.toList()..sort((a, b) => b.compareTo(a));

    final List<Widget> slivers = [];

    for (final date in allDates) {
      // Get items for this date
      final items = itemsByDate[date] ?? [];

      // Skip if no items for this date
      if (items.isEmpty) continue;

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

      // Render items (already sorted by timestamp)
      if (items.isNotEmpty) {
        slivers.add(
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final item = items[index];
                // Check if this is a CGM group type
                if (item.type == FeedItemType.cgmGroup) {
                  return CgmGroupCard(group: item.cgmGroup!);
                } else {
                  return FeedItemCard(item: item);
                }
              },
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

}
