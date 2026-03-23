import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';

import 'package:glu_butler/l10n/app_localizations.dart';
import 'package:glu_butler/core/constants/app_constants.dart';
import 'package:glu_butler/core/theme/app_theme.dart';
import 'package:glu_butler/core/theme/app_decorations.dart';
import 'package:glu_butler/core/theme/app_colors.dart';
import 'package:glu_butler/core/widgets/large_title_scroll_view.dart';
import 'package:glu_butler/core/widgets/top_banner.dart';
import 'package:glu_butler/providers/feed_provider.dart';
import 'package:glu_butler/services/settings_service.dart';

class HealthConnectScreen extends StatefulWidget {
  const HealthConnectScreen({super.key});

  @override
  State<HealthConnectScreen> createState() => _HealthConnectScreenState();
}

class _HealthConnectScreenState extends State<HealthConnectScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // 화면 첫 진입 시 실제 권한 상태 확인 (새로고침 없이도 최신 상태 반영)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<FeedProvider>();
      _onRefresh(context, provider, AppLocalizations.of(context)!);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Refresh permission status when app comes back to foreground
    // (user might have changed permissions in Health app)
    if (state == AppLifecycleState.resumed) {
      final provider = context.read<FeedProvider>();
      final l10n = AppLocalizations.of(context)!;
      _onRefresh(context, provider, l10n);
    }
  }

  Future<void> _onRefresh(
    BuildContext context,
    FeedProvider provider,
    AppLocalizations l10n,
  ) async {
    final statusChanged = await provider.refreshPermissionStatus();

    if (!context.mounted) return;

    if (statusChanged == true) {
      // Now connected
      TopBanner.show(
        context,
        message: l10n.successfullyConnected,
        isSuccess: true,
      );
    } else if (statusChanged == false) {
      // Now disconnected
      TopBanner.show(
        context,
        message: Platform.isIOS ? l10n.disconnected : l10n.disconnectedHealthConnect,
        isSuccess: false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Consumer<FeedProvider>(
      builder: (context, provider, child) {
        return LargeTitleScrollView(
          title: l10n.healthConnect,
          showBackButton: true,
          showLargeTitle: false, // Hero section has its own title
          fadeInNavTitle: true, // Fade in nav title when hero title scrolls away
          onRefresh: () => _onRefresh(context, provider, l10n),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Hero Section
                  _buildHeroSection(context, l10n),
                  const SizedBox(height: 32),

                  // Data Types Section
                  _buildSectionTitle(context, l10n.syncedData),
                  const SizedBox(height: 12),
                  _buildDataTypesList(context, theme, l10n, provider),
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
    final heroColor = Platform.isAndroid ? AppTheme.iconBlue : AppTheme.iconPink;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            heroColor.withValues(alpha: 0.1),
            heroColor.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon (platform-specific)
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.25),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Platform.isAndroid
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Image.asset(
                      'assets/images/health_connect.png',
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                    ),
                  )
                : Stack(
                    children: [
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Icon(
                          CupertinoIcons.heart_fill,
                          color: AppTheme.iconPink,
                          size: 28,
                        ),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 20),
          // Title
          Text(
            l10n.healthConnect,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 12),
          // Description
          Text(
            Platform.isIOS ? l10n.appleHealthDescription : l10n.healthConnectDescription,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: context.colors.textSecondary,
              height: 1.5,
            ),
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

  Widget _buildDataTypesList(BuildContext context, ThemeData theme, AppLocalizations l10n, FeedProvider provider) {
    final permissions = provider.categoryPermissions;
    final isConnected = provider.isHealthConnected;

    // Write types - can verify permission status
    final writeTypes = [
      _DataTypeItem(
        icon: CupertinoIcons.drop_fill,
        title: l10n.bloodGlucose,
        subtitle: l10n.readWrite,
        color: AppTheme.primaryColor,
        category: HealthDataCategory.bloodGlucose,
        isWriteType: true,
      ),
      // iOS: HealthKit read/write, Android: Google Cloud backup (Health Connect doesn't support insulin)
      _DataTypeItem(
        icon: Icons.vaccines,
        title: l10n.insulin,
        subtitle: Platform.isAndroid ? l10n.cloudBackup : l10n.readWrite,
        color: AppTheme.iconPurple,
        category: HealthDataCategory.insulin,
        isWriteType: !Platform.isAndroid,
      ),
    ];

    // Read-only types - cannot verify permission on iOS
    final readOnlyTypes = [
      _DataTypeItem(
        icon: CupertinoIcons.flame_fill,
        title: l10n.workouts,
        subtitle: l10n.readOnly,
        color: AppTheme.iconOrange,
        category: HealthDataCategory.workouts,
        isWriteType: false,
      ),
      _DataTypeItem(
        icon: CupertinoIcons.moon_fill,
        title: l10n.sleep,
        subtitle: l10n.readOnly,
        color: AppTheme.iconIndigo,
        category: HealthDataCategory.sleep,
        isWriteType: false,
      ),
      _DataTypeItem(
        icon: Icons.monitor_weight,
        title: l10n.weightBody,
        subtitle: l10n.readOnly,
        color: AppTheme.iconTeal,
        category: HealthDataCategory.weight,
        isWriteType: false,
      ),
      _DataTypeItem(
        icon: CupertinoIcons.drop,
        title: l10n.waterIntake,
        subtitle: l10n.readOnly,
        color: AppTheme.iconCyan,
        category: HealthDataCategory.water,
        isWriteType: false,
      ),
      _DataTypeItem(
        icon: CupertinoIcons.heart,
        title: l10n.menstrualCycle,
        subtitle: l10n.readOnly,
        color: AppTheme.iconPink,
        category: HealthDataCategory.menstrualCycle,
        isWriteType: false,
      ),
      _DataTypeItem(
        icon: Icons.directions_walk,
        title: l10n.steps,
        subtitle: l10n.readOnly,
        color: AppTheme.iconGreen,
        category: HealthDataCategory.steps,
        isWriteType: false,
      ),
      _DataTypeItem(
        icon: Icons.directions_run,
        title: l10n.distance,
        subtitle: l10n.readOnly,
        color: AppTheme.iconBlue,
        category: HealthDataCategory.distance,
        isWriteType: false,
      ),
      // Mindfulness not available in Health Connect SDK (MindfulnessSessionRecord absent)
      if (!Platform.isAndroid)
        _DataTypeItem(
          icon: Icons.self_improvement,
          title: l10n.mindfulness,
          subtitle: l10n.readOnly,
          color: AppTheme.iconTeal,
          category: HealthDataCategory.mindfulness,
          isWriteType: false,
        ),
    ];

    return Container(
      decoration: context.decorations.card,
      child: Column(
        children: [
          // Write types with permission check
          for (int i = 0; i < writeTypes.length; i++) ...[
            _buildDataTypeRow(
              context,
              writeTypes[i],
              isConnected: isConnected,
              permissionStatus: permissions[writeTypes[i].category] ?? false,
            ),
            Padding(
              padding: const EdgeInsets.only(left: 52),
              child: Divider(
                height: 1,
                color: context.colors.divider,
              ),
            ),
          ],
          // Read-only types without permission check
          for (int i = 0; i < readOnlyTypes.length; i++) ...[
            _buildDataTypeRow(
              context,
              readOnlyTypes[i],
              isConnected: isConnected,
              permissionStatus: null, // Don't show check for read-only
            ),
            if (i < readOnlyTypes.length - 1)
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
    BuildContext context,
    _DataTypeItem item, {
    required bool isConnected,
    required bool? permissionStatus,
  }) {
    final theme = Theme.of(context);
    // For write types: show check if connected AND has permission
    // For read-only types: permissionStatus is null, don't show check icon
    final showCheck = item.isWriteType;
    final isEnabled = isConnected && permissionStatus == true;

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
            child: Row(
              children: [
                Text(
                  item.title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (item.subtitle != null) ...[
                  const SizedBox(width: 6),
                  Text(
                    item.subtitle!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: context.colors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (showCheck)
            Icon(
              isEnabled
                  ? CupertinoIcons.checkmark_circle_fill
                  : CupertinoIcons.circle,
              color: isEnabled ? AppTheme.iconGreen : context.colors.iconGrey,
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
        case AppConstants.syncPeriod1Month:
          return l10n.syncPeriod1Month;
        case AppConstants.syncPeriod3Months:
          return l10n.syncPeriod3Months;
        case AppConstants.syncPeriod6Months:
          return l10n.syncPeriod6Months;
        case AppConstants.syncPeriod9Months:
          return l10n.syncPeriod9Months;
        case AppConstants.syncPeriod12Months:
          return l10n.syncPeriod12Months;
        default:
          return l10n.syncPeriod1Month;
      }
    }

    // AdaptivePopupMenuButton용 아이템 리스트 생성
    final items = [
      AdaptivePopupMenuItem<int>(
        value: AppConstants.syncPeriod12Months,
        label: l10n.syncPeriod12Months,
        icon: currentPeriod == AppConstants.syncPeriod12Months ? 'checkmark' : null,
      ),
      AdaptivePopupMenuItem<int>(
        value: AppConstants.syncPeriod9Months,
        label: l10n.syncPeriod9Months,
        icon: currentPeriod == AppConstants.syncPeriod9Months ? 'checkmark' : null,
      ),
      AdaptivePopupMenuItem<int>(
        value: AppConstants.syncPeriod6Months,
        label: l10n.syncPeriod6Months,
        icon: currentPeriod == AppConstants.syncPeriod6Months ? 'checkmark' : null,
      ),
      AdaptivePopupMenuItem<int>(
        value: AppConstants.syncPeriod3Months,
        label: l10n.syncPeriod3Months,
        icon: currentPeriod == AppConstants.syncPeriod3Months ? 'checkmark' : null,
      ),
      AdaptivePopupMenuItem<int>(
        value: AppConstants.syncPeriod1Month,
        label: l10n.syncPeriod1Month,
        icon: currentPeriod == AppConstants.syncPeriod1Month ? 'checkmark' : null,
      ),
    ];

    return Container(
      decoration: context.decorations.card,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
            MediaQuery(
              data: MediaQuery.of(context).copyWith(
                platformBrightness: Theme.of(context).brightness,
              ),
              child: AdaptivePopupMenuButton.widget<int>(
                items: items,
                onSelected: (index, item) {
                  if (item.value != null) {
                    settings.setSyncPeriod(item.value!);
                    context.read<FeedProvider>().refreshData();
                  }
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      getPeriodLabel(currentPeriod),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: context.colors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      CupertinoIcons.chevron_down,
                      size: 16,
                      color: context.colors.iconGrey,
                    ),
                  ],
                ),
              ),
            ),
          ],
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
                        message: Platform.isIOS ? l10n.failedToConnect : l10n.failedToConnectHealthConnect,
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
                    isConnected
                        ? l10n.connected
                        : (Platform.isIOS ? l10n.connectAppleHealth : l10n.connectHealthConnect),
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
    if (Platform.isAndroid) {
      try {
        await const MethodChannel('custom_healthkit').invokeMethod('openHealthConnectSettings');
      } catch (_) {}
      return;
    }

    // iOS: Try to open the Health app directly
    final healthUri = Uri.parse('x-apple-health://');
    if (await canLaunchUrl(healthUri)) {
      await launchUrl(healthUri);
    } else {
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
              Platform.isIOS ? l10n.privacyNote : l10n.privacyNoteAndroid,
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
  final String? subtitle;
  final Color color;
  final HealthDataCategory category;
  final bool isWriteType;

  _DataTypeItem({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.color,
    required this.category,
    required this.isWriteType,
  });
}
