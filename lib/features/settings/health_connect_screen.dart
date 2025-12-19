import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:glu_butler/l10n/app_localizations.dart';
import 'package:glu_butler/core/constants/app_constants.dart';
import 'package:glu_butler/core/theme/app_theme.dart';
import 'package:glu_butler/core/theme/app_decorations.dart';
import 'package:glu_butler/core/theme/app_colors.dart';
import 'package:glu_butler/core/widgets/large_title_scroll_view.dart';
import 'package:glu_butler/core/widgets/top_banner.dart';
import 'package:glu_butler/providers/feed_provider.dart';
import 'package:glu_butler/services/settings_service.dart';

class HealthConnectScreen extends StatelessWidget {
  const HealthConnectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Consumer<FeedProvider>(
      builder: (context, provider, child) {
        return LargeTitleScrollView(
          title: l10n.healthConnect,
          showBackButton: true,
          showLargeTitle: false,
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Hero Section
                  _buildHeroSection(context, l10n),
                  const SizedBox(height: 32),

                  // Data Types Section
                  _buildSectionTitle(context, l10n.syncedData),
                  const SizedBox(height: 12),
                  _buildDataTypesList(context, theme, l10n, provider.isHealthConnected),
                  const SizedBox(height: 32),

                  // Sync Period Section
                  _buildSectionTitle(context, l10n.syncPeriod),
                  const SizedBox(height: 12),
                  _buildSyncPeriodSelector(context, theme, l10n),
                  const SizedBox(height: 32),

                  // Connect/Disconnect Button
                  _buildConnectButton(context, theme, l10n, provider),
                  const SizedBox(height: 24),

                  // Privacy Note
                  _buildPrivacyNote(context, theme, l10n),
                  const SizedBox(height: 32),
                ]),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeroSection(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.iconPink.withValues(alpha: 0.1),
            AppTheme.iconPink.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: context.colors.card,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.iconPink.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Align(
              alignment: Alignment(0.35, -0.35),
              child: Icon(
                CupertinoIcons.heart_fill,
                color: AppTheme.iconPink,
                size: 28,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.appleHealthDescription,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: context.colors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Text(
      title.toUpperCase(),
      style: theme.textTheme.labelSmall?.copyWith(
        fontWeight: FontWeight.w600,
        color: context.colors.textSecondary,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildDataTypesList(BuildContext context, ThemeData theme, AppLocalizations l10n, bool isConnected) {
    final dataTypes = [
      _DataTypeItem(
        icon: CupertinoIcons.drop_fill,
        title: l10n.bloodGlucose,
        color: AppTheme.primaryColor,
      ),
      _DataTypeItem(
        icon: Icons.vaccines,
        title: l10n.insulin,
        color: AppTheme.iconPurple,
      ),
      _DataTypeItem(
        icon: CupertinoIcons.flame_fill,
        title: l10n.workouts,
        color: AppTheme.iconOrange,
      ),
      _DataTypeItem(
        icon: CupertinoIcons.moon_fill,
        title: l10n.sleep,
        color: AppTheme.iconIndigo,
      ),
      _DataTypeItem(
        icon: Icons.monitor_weight,
        title: l10n.weightBody,
        color: AppTheme.iconTeal,
      ),
      _DataTypeItem(
        icon: CupertinoIcons.drop,
        title: l10n.waterIntake,
        color: AppTheme.iconCyan,
      ),
      _DataTypeItem(
        icon: CupertinoIcons.heart,
        title: l10n.menstrualCycle,
        color: AppTheme.iconPink,
      ),
      _DataTypeItem(
        icon: Icons.directions_walk,
        title: l10n.steps,
        color: AppTheme.iconGreen,
      ),
    ];

    return Container(
      decoration: context.decorations.card,
      child: Column(
        children: [
          for (int i = 0; i < dataTypes.length; i++) ...[
            _buildDataTypeRow(context, dataTypes[i], isConnected),
            if (i < dataTypes.length - 1)
              Padding(
                padding: const EdgeInsets.only(left: 52),
                child: Divider(
                  height: 1,
                  color: context.colors.divider,
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildDataTypeRow(
      BuildContext context, _DataTypeItem item, bool isConnected) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(item.icon, color: item.color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              item.title,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Icon(
            isConnected
                ? CupertinoIcons.checkmark_circle_fill
                : CupertinoIcons.circle,
            color: isConnected ? AppTheme.iconGreen : context.colors.iconGrey,
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildSyncPeriodSelector(
      BuildContext context, ThemeData theme, AppLocalizations l10n) {
    final settings = context.watch<SettingsService>();
    final currentPeriod = settings.syncPeriod;

    String getPeriodLabel(int days) {
      switch (days) {
        case AppConstants.syncPeriod1Week:
          return l10n.syncPeriod1Week;
        case AppConstants.syncPeriod2Weeks:
          return l10n.syncPeriod2Weeks;
        case AppConstants.syncPeriod1Month:
          return l10n.syncPeriod1Month;
        case AppConstants.syncPeriod3Months:
          return l10n.syncPeriod3Months;
        default:
          return l10n.syncPeriod1Week;
      }
    }

    return Container(
      decoration: context.decorations.card,
      child: CupertinoButton(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        onPressed: () => _showSyncPeriodPicker(context, l10n, settings),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppTheme.iconBlue.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(7),
              ),
              child: const Icon(
                CupertinoIcons.calendar,
                color: AppTheme.iconBlue,
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l10n.syncPeriod,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Text(
              getPeriodLabel(currentPeriod),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: context.colors.textSecondary,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              CupertinoIcons.chevron_right,
              size: 16,
              color: context.colors.iconGrey,
            ),
          ],
        ),
      ),
    );
  }

  void _showSyncPeriodPicker(
      BuildContext context, AppLocalizations l10n, SettingsService settings) {
    final feedProvider = context.read<FeedProvider>();

    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text(l10n.syncPeriod),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              settings.setSyncPeriod(AppConstants.syncPeriod1Week);
              feedProvider.refreshData();
              Navigator.pop(context);
            },
            child: Text(l10n.syncPeriod1Week),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              settings.setSyncPeriod(AppConstants.syncPeriod2Weeks);
              feedProvider.refreshData();
              Navigator.pop(context);
            },
            child: Text(l10n.syncPeriod2Weeks),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              settings.setSyncPeriod(AppConstants.syncPeriod1Month);
              feedProvider.refreshData();
              Navigator.pop(context);
            },
            child: Text(l10n.syncPeriod1Month),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              settings.setSyncPeriod(AppConstants.syncPeriod3Months);
              feedProvider.refreshData();
              Navigator.pop(context);
            },
            child: Text(l10n.syncPeriod3Months),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
      ),
    );
  }

  Widget _buildConnectButton(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
    FeedProvider provider,
  ) {
    final isConnected = provider.isHealthConnected;
    final isLoading = provider.isLoading;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading
            ? null
            : () async {
                if (isConnected) {
                  // Open Health app to manage permissions
                  await _openHealthApp(context, l10n);
                } else {
                  final success = await provider.connectToHealth();
                  if (context.mounted) {
                    if (success) {
                      TopBanner.show(
                        context,
                        message: l10n.successfullyConnected,
                        isSuccess: true,
                      );
                    } else {
                      TopBanner.show(
                        context,
                        message: l10n.failedToConnect,
                        isSuccess: false,
                      );
                    }
                  }
                }
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: isConnected ? AppTheme.iconPink.withValues(alpha: 0.15) : AppTheme.primaryColor,
          foregroundColor: isConnected ? AppTheme.iconPink : Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        child: isLoading
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: isConnected ? AppTheme.iconPink : Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isConnected ? l10n.connected : l10n.connectAppleHealth,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  if (isConnected) ...[
                    const SizedBox(width: 8),
                    Icon(
                      CupertinoIcons.arrow_up_right,
                      size: 16,
                      color: AppTheme.iconPink,
                    ),
                  ],
                ],
              ),
      ),
    );
  }

  Future<void> _openHealthApp(BuildContext context, AppLocalizations l10n) async {
    // Try to open the Health app directly
    final healthUri = Uri.parse('x-apple-health://');

    if (await canLaunchUrl(healthUri)) {
      await launchUrl(healthUri);
    } else {
      // Fallback: Open iOS Settings app
      final settingsUri = Uri.parse('app-settings:');
      if (await canLaunchUrl(settingsUri)) {
        await launchUrl(settingsUri);
      } else if (context.mounted) {
        TopBanner.show(
          context,
          message: l10n.openHealthApp,
          isSuccess: false,
        );
      }
    }
  }

  Widget _buildPrivacyNote(BuildContext context, ThemeData theme, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: context.decorations.card,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            CupertinoIcons.lock_shield_fill,
            color: context.colors.textSecondary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l10n.privacyNote,
              style: theme.textTheme.bodySmall?.copyWith(
                color: context.colors.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DataTypeItem {
  final IconData icon;
  final String title;
  final Color color;

  _DataTypeItem({
    required this.icon,
    required this.title,
    required this.color,
  });
}
