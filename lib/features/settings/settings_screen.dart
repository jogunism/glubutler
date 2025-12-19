import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:glu_butler/l10n/app_localizations.dart';
import 'package:glu_butler/core/constants/app_constants.dart';
import 'package:glu_butler/core/theme/app_theme.dart';
import 'package:glu_butler/core/theme/app_text_styles.dart';
import 'package:glu_butler/core/theme/app_colors.dart';
import 'package:glu_butler/core/theme/app_decorations.dart';
import 'package:glu_butler/services/settings_service.dart';
import 'package:glu_butler/services/app_settings_service.dart';
import 'package:glu_butler/core/widgets/glass_icon.dart';
import 'package:glu_butler/core/widgets/large_title_scroll_view.dart';
import 'package:glu_butler/providers/feed_provider.dart';

/// 앱 설정 화면
///
/// iOS Settings 앱 스타일의 설정 화면으로, [LargeTitleScrollView]를 사용하여
/// 큰 타이틀이 스크롤과 함께 움직이는 네비게이션 패턴을 구현합니다.
///
/// ## 섹션 구성
/// 1. **구독** - Pro 업그레이드/관리
/// 2. **프로필** - 사용자 이름
/// 3. **설정** - 언어, 혈당 단위, 화면 설정
/// 4. **건강 앱 연동** - Apple Health/Google Fit 연동
///
/// ## 주요 기능
/// - iOS 스타일 그룹화된 설정 타일
/// - [GlassIcon]을 사용한 아이콘 디자인
/// - 구독 상태에 따른 동적 아이콘/텍스트 변경
/// - 시스템 설정 앱 연동 (언어 변경)
///
/// ## 라우팅
/// - `/settings` - 메인 설정 화면
/// - `/settings/subscription` - 구독 관리
/// - `/settings/display` - 화면 설정 (다크모드)
///
/// ## 관련 파일
/// - [SettingsService] - 설정 상태 관리
/// - [LargeTitleScrollView] - iOS 스타일 스크롤뷰
/// - [AppTheme] - 디자인 상수
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final settings = context.watch<SettingsService>();

    return LargeTitleScrollView(
      title: l10n.settings,
      showBackButton: true,
      // 설정 화면은 pull-to-refresh 불필요
      onRefresh: null,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Subscription Section
              _buildSectionTitle(context, l10n.subscription),
              _buildGroupedSection(
                context: context,
                children: [
                  _buildSettingsTile(
                    context: context,
                    icon: settings.isPro
                        ? CupertinoIcons.checkmark_seal_fill
                        : CupertinoIcons.star_fill,
                    iconColor: settings.isPro
                        ? AppTheme.iconGreen
                        : AppTheme.iconOrange,
                    title: l10n.gluButlerPro,
                    subtitle: settings.isPro ? l10n.proPlan : l10n.upgradeToPro,
                    onTap: () => context.push('/settings/subscription'),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Profile Section
              _buildSectionTitle(context, l10n.profile),
              _buildGroupedSection(
                context: context,
                children: [
                  _buildSettingsTile(
                    context: context,
                    icon: CupertinoIcons.person_fill,
                    iconColor: AppTheme.iconBlue,
                    title: l10n.name,
                    subtitle: settings.userProfile.name ?? '-',
                    onTap: () {
                      // TODO: Navigate to profile edit
                    },
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // App Settings Section
              _buildSectionTitle(context, l10n.settings),
              _buildGroupedSection(
                context: context,
                children: [
                  _buildSettingsTile(
                    context: context,
                    icon: CupertinoIcons.globe,
                    iconColor: AppTheme.iconCyan,
                    title: l10n.language,
                    subtitle: l10n.changeInSettings,
                    trailing: Icon(
                      CupertinoIcons.arrow_up_right,
                      size: 16,
                      color: context.colors.iconGrey,
                    ),
                    onTap: () => AppSettingsService.openAppSettings(),
                  ),
                  _buildDivider(context),
                  _buildSettingsTile(
                    context: context,
                    icon: CupertinoIcons.drop_fill,
                    iconColor: AppTheme.iconRed,
                    title: l10n.glucoseUnit,
                    subtitle: settings.unit,
                    onTap: () =>
                        _showUnitActionSheet(context, settings, l10n),
                  ),
                  _buildDivider(context),
                  _buildSettingsTile(
                    context: context,
                    icon: CupertinoIcons.moon_fill,
                    iconColor: AppTheme.iconIndigo,
                    title: l10n.displaySettings,
                    subtitle: _getThemeModeLabel(settings.themeMode, l10n),
                    onTap: () => context.push('/settings/display'),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Sync Section
              _buildSectionTitle(context, l10n.sync),
              _buildGroupedSection(
                context: context,
                children: [
                  Builder(
                    builder: (context) {
                      final feedProvider = context.watch<FeedProvider>();
                      return _buildSettingsTile(
                        context: context,
                        icon: CupertinoIcons.heart_fill,
                        iconColor: AppTheme.iconPink,
                        title: l10n.appleHealth,
                        subtitle: feedProvider.isHealthConnected
                            ? l10n.connected
                            : l10n.notConnected,
                        onTap: () => context.push('/settings/health'),
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Disclaimer
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  l10n.disclaimer,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: context.colors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 32),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: context.textStyles.sectionTitle,
      ),
    );
  }

  Widget _buildGroupedSection({
    required BuildContext context,
    required List<Widget> children,
  }) {
    return Container(
      decoration: context.decorations.card,
      child: Column(children: children),
    );
  }

  Widget _buildSettingsTile({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              GlassIcon(icon: icon, color: iconColor, size: 32),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: context.textStyles.tileTitle,
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: context.textStyles.tileSubtitle,
                      ),
                    ],
                  ],
                ),
              ),
              trailing ??
                  Icon(
                    CupertinoIcons.chevron_right,
                    size: 16,
                    color: context.colors.iconGrey,
                  ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 62),
      child: Divider(
        height: 1,
        color: context.colors.divider,
      ),
    );
  }

  String _getThemeModeLabel(String mode, AppLocalizations l10n) {
    switch (mode) {
      case AppConstants.themeModeLight:
        return l10n.lightMode;
      case AppConstants.themeModeDark:
        return l10n.darkModeOption;
      default:
        return l10n.systemDefault;
    }
  }

  void _showUnitActionSheet(
    BuildContext context,
    SettingsService settings,
    AppLocalizations l10n,
  ) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text(l10n.glucoseUnit),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              settings.setUnit(AppConstants.unitMgDl);
              Navigator.pop(context);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(l10n.mgdl),
                if (settings.unit == AppConstants.unitMgDl) ...[
                  const SizedBox(width: 8),
                  const Icon(CupertinoIcons.checkmark, size: 18),
                ],
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              settings.setUnit(AppConstants.unitMmolL);
              Navigator.pop(context);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(l10n.mmoll),
                if (settings.unit == AppConstants.unitMmolL) ...[
                  const SizedBox(width: 8),
                  const Icon(CupertinoIcons.checkmark, size: 18),
                ],
              ],
            ),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
      ),
    );
  }
}
