import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:glu_butler/l10n/app_localizations.dart';
import 'package:glu_butler/core/theme/app_theme.dart';
import 'package:glu_butler/core/theme/app_text_styles.dart';
import 'package:glu_butler/core/theme/app_colors.dart';
import 'package:glu_butler/core/theme/app_decorations.dart';
import 'package:glu_butler/core/widgets/glass_icon.dart';
import 'package:glu_butler/core/widgets/large_title_scroll_view.dart';
import 'package:glu_butler/services/settings_service.dart';

/// 구독 관리 화면
///
/// Pro 구독 상태에 따라 다른 UI를 표시합니다:
/// - **미구독 사용자**: Pro 기능 소개, 가격 옵션, 구매/복원 버튼
/// - **구독 사용자**: 구독 정보(시작일, 플랜), 활성화된 기능 목록, 구독 관리 버튼
///
/// ## 주요 기능
/// - Pro 배지 (미구독: 오렌지 별, 구독: 녹색 체크마크)
/// - 기능 목록 (AI 인사이트, 고급 분석, 데이터 내보내기, 우선 지원)
/// - 월간/연간 구독 옵션
/// - 구매 복원 기능
///
/// ## 사용 예시
/// ```dart
/// context.push('/settings/subscription');
/// ```
///
/// ## 관련 파일
/// - [SettingsService] - 구독 상태 관리
/// - [AppTheme] - 디자인 상수 (proGradient, proActiveGradient 등)
class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final settings = context.watch<SettingsService>();
    final isPro = settings.isPro;

    return Scaffold(
      backgroundColor: context.colors.background,
      body: Stack(
        children: [
          // 메인 컨텐츠 - LargeTitleScrollView 사용
          LargeTitleScrollView(
            title: l10n.subscription,
            showBackButton: true,
            showLargeTitle: false, // Hero section has its own title
            fadeInNavTitle: true, // Fade in nav title when hero title scrolls away
            onRefresh: null,
            slivers: [
              SliverPadding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  bottom: isPro ? 16 : 100,
                ),
                sliver: SliverToBoxAdapter(
                  child: isPro
                      ? _buildProUserContent(context, settings, l10n, theme)
                      : _buildNonProUserContent(context, l10n, theme),
                ),
              ),
            ],
          ),

          // 하단 버튼 (미구독자만 표시)
          if (!isPro)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                color: context.colors.background,
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: CupertinoButton(
                        color: AppTheme.primaryColor,
                        borderRadius: BorderRadius.circular(14),
                        onPressed: () => _showSubscriptionAlert(context),
                        child: Text(
                          l10n.upgradeToPro,
                          style: context.textStyles.buttonText,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 구독 사용자용 컨텐츠
  Widget _buildProUserContent(
    BuildContext context,
    SettingsService settings,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    final subscriptionDate = settings.subscriptionDate;
    final dateFormat = DateFormat.yMMMd(l10n.localeName);

    return Column(
      children: [
        // Hero Section
        _buildHeroSection(context, l10n, theme, isActive: true),
        const SizedBox(height: 32),

        // Subscription info
        _buildCard(
          context: context,
          children: [
            _buildInfoItem(
              context: context,
              icon: CupertinoIcons.calendar,
              iconColor: AppTheme.iconBlue,
              title: l10n.subscriptionStartDate,
              value: subscriptionDate != null
                  ? dateFormat.format(subscriptionDate)
                  : '-',
            ),
            _buildDivider(context),
            _buildInfoItem(
              context: context,
              icon: CupertinoIcons.star_fill,
              iconColor: AppTheme.iconAmber,
              title: l10n.subscriptionPlan,
              value: l10n.yearlyPlan,
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Active features
        _buildCard(
          context: context,
          children: [
            _buildFeatureItem(
              context: context,
              icon: CupertinoIcons.lightbulb_fill,
              iconColor: AppTheme.iconPurple,
              title: l10n.proFeature1,
            ),
            _buildDivider(context),
            _buildFeatureItem(
              context: context,
              icon: CupertinoIcons.chart_bar_fill,
              iconColor: AppTheme.iconBlue,
              title: l10n.proFeature2,
            ),
            _buildDivider(context),
            _buildFeatureItem(
              context: context,
              icon: CupertinoIcons.arrow_down_doc_fill,
              iconColor: AppTheme.iconGreen,
              title: l10n.proFeature3,
            ),
            _buildDivider(context),
            _buildFeatureItem(
              context: context,
              icon: CupertinoIcons.chat_bubble_2_fill,
              iconColor: AppTheme.iconOrange,
              title: l10n.proFeature4,
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Manage subscription
        CupertinoButton(
          onPressed: () => _showManageSubscriptionAlert(context),
          child: Text(
            l10n.manageSubscription,
            style: TextStyle(
              color: theme.colorScheme.primary,
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  /// 미구독 사용자용 컨텐츠
  Widget _buildNonProUserContent(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    return Column(
      children: [
        // Hero Section
        _buildHeroSection(context, l10n, theme, isActive: false),
        const SizedBox(height: 32),

        // Features list
        _buildCard(
          context: context,
          children: [
            _buildFeatureItem(
              context: context,
              icon: CupertinoIcons.lightbulb_fill,
              iconColor: AppTheme.iconPurple,
              title: l10n.proFeature1,
            ),
            _buildDivider(context),
            _buildFeatureItem(
              context: context,
              icon: CupertinoIcons.chart_bar_fill,
              iconColor: AppTheme.iconBlue,
              title: l10n.proFeature2,
            ),
            _buildDivider(context),
            _buildFeatureItem(
              context: context,
              icon: CupertinoIcons.arrow_down_doc_fill,
              iconColor: AppTheme.iconGreen,
              title: l10n.proFeature3,
            ),
            _buildDivider(context),
            _buildFeatureItem(
              context: context,
              icon: CupertinoIcons.chat_bubble_2_fill,
              iconColor: AppTheme.iconOrange,
              title: l10n.proFeature4,
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Pricing options
        _buildPricingOption(
          context: context,
          title: l10n.subscribeMonthly,
          price: l10n.monthlyPrice,
          isSelected: false,
          onTap: () => _showSubscriptionAlert(context),
        ),
        const SizedBox(height: 12),
        _buildPricingOption(
          context: context,
          title: l10n.subscribeYearly,
          price: l10n.yearlyPrice,
          isSelected: true,
          isBestValue: true,
          onTap: () => _showSubscriptionAlert(context),
        ),
        const SizedBox(height: 24),

        // Restore purchases
        CupertinoButton(
          onPressed: () => _showRestoreAlert(context),
          child: Text(
            l10n.restorePurchases,
            style: TextStyle(
              color: theme.colorScheme.primary,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================================================
  // UI Components
  // ==========================================================================

  Widget _buildHeroSection(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme, {
    required bool isActive,
  }) {
    return SizedBox(
      width: double.infinity,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isActive
                ? [
                    AppTheme.iconGreen.withValues(alpha: 0.1),
                    AppTheme.iconGreen.withValues(alpha: 0.05),
                  ]
                : [
                    AppTheme.iconOrange.withValues(alpha: 0.1),
                    AppTheme.iconOrange.withValues(alpha: 0.05),
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isActive ? AppTheme.proActiveGradient : AppTheme.proGradient,
                ),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: isActive ? AppTheme.shadowGreen : AppTheme.shadowOrange,
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  isActive ? CupertinoIcons.checkmark_seal_fill : CupertinoIcons.star_fill,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Title
            Text(
              isActive ? l10n.youArePro : l10n.subscription,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
            const SizedBox(height: 12),
            // Description
            Text(
              isActive ? l10n.proThankYou : l10n.proDescription,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: context.colors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({
    required BuildContext context,
    required List<Widget> children,
  }) {
    return Container(
      decoration: context.decorations.card,
      child: Column(children: children),
    );
  }

  Widget _buildInfoItem({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GlassIcon(icon: icon, color: iconColor, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: context.textStyles.tileTitle,
            ),
          ),
          Text(
            value,
            style: context.textStyles.tileSubtitle,
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GlassIcon(icon: icon, color: iconColor, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: context.textStyles.tileTitle,
            ),
          ),
          const Icon(
            CupertinoIcons.checkmark_circle_fill,
            color: AppTheme.iconGreen,
            size: 22,
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 58),
      child: Divider(
        height: 1,
        color: context.colors.divider,
      ),
    );
  }

  Widget _buildPricingOption({
    required BuildContext context,
    required String title,
    required String price,
    required bool isSelected,
    bool isBestValue = false,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: context.decorations.card.copyWith(
          border: isSelected
              ? Border.all(color: theme.colorScheme.primary, width: 2)
              : null,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: context.textStyles.tileTitle.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (isBestValue) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.iconGreen,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Best Value',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Text(
              price,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // Dialogs
  // ==========================================================================

  void _showSubscriptionAlert(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(l10n.subscription),
        content: const Text('Payment functionality is not yet implemented.'),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showRestoreAlert(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(l10n.restorePurchases),
        content: const Text('Restore functionality is not yet implemented.'),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showManageSubscriptionAlert(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(l10n.manageSubscription),
        content: const Text('Subscription management will open in the App Store.'),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
