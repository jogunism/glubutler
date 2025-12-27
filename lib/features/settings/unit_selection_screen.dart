import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import 'package:glu_butler/l10n/app_localizations.dart';
import 'package:glu_butler/core/constants/app_constants.dart';
import 'package:glu_butler/core/theme/app_theme.dart';
import 'package:glu_butler/core/theme/app_text_styles.dart';
import 'package:glu_butler/core/theme/app_colors.dart';
import 'package:glu_butler/core/theme/app_decorations.dart';
import 'package:glu_butler/services/settings_service.dart';
import 'package:glu_butler/core/widgets/glass_icon.dart';
import 'package:glu_butler/core/widgets/large_title_scroll_view.dart';

/// 혈당 단위 선택 화면
///
/// mg/dL와 mmol/L 중 혈당 측정 단위를 선택합니다.
class UnitSelectionScreen extends StatelessWidget {
  const UnitSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settings = context.watch<SettingsService>();
    final currentUnit = settings.unit;

    return LargeTitleScrollView(
      title: l10n.glucoseUnit,
      showBackButton: true,
      showLargeTitle: false,
      onRefresh: null,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverToBoxAdapter(
            child: Container(
              decoration: context.decorations.card,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildUnitOption(
                    context: context,
                    icon: CupertinoIcons.gauge,
                    iconColor: AppTheme.iconRed,
                    title: l10n.mgdl,
                    subtitle: 'Milligrams per deciliter',
                    value: AppConstants.unitMgDl,
                    currentValue: currentUnit,
                    onTap: () => settings.setUnit(AppConstants.unitMgDl),
                    isFirst: true,
                  ),
                  _buildDivider(context),
                  _buildUnitOption(
                    context: context,
                    icon: CupertinoIcons.gauge,
                    iconColor: AppTheme.iconRed,
                    title: l10n.mmoll,
                    subtitle: 'Millimoles per liter',
                    value: AppConstants.unitMmolL,
                    currentValue: currentUnit,
                    onTap: () => settings.setUnit(AppConstants.unitMmolL),
                    isLast: true,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUnitOption({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    required String value,
    required String currentValue,
    required VoidCallback onTap,
    bool isFirst = false,
    bool isLast = false,
  }) {
    final isSelected = value == currentValue;
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.vertical(
          top: isFirst ? const Radius.circular(12) : Radius.zero,
          bottom: isLast ? const Radius.circular(12) : Radius.zero,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // GlassIcon(
              //   icon: icon,
              //   color: iconColor,
              //   size: 32,
              // ),
              // const SizedBox(width: 14),
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
              if (isSelected)
                Icon(
                  CupertinoIcons.checkmark,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16), // Changed from 62 (no icon)
      child: Divider(
        height: 1,
        color: context.colors.divider,
      ),
    );
  }
}
