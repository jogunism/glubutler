import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import 'package:glu_butler/l10n/app_localizations.dart';
import 'package:glu_butler/core/constants/app_constants.dart';
import 'package:glu_butler/core/theme/app_theme.dart';
import 'package:glu_butler/core/theme/app_colors.dart';
import 'package:glu_butler/core/theme/app_decorations.dart';
import 'package:glu_butler/services/settings_service.dart';
import 'package:glu_butler/core/widgets/large_title_scroll_view.dart';

/// 목표 혈당 범위 설정 화면
///
/// 5단계 혈당 임계값을 설정합니다:
/// - Very High (매우 높음): 180 mg/dL
/// - High (높음): 160 mg/dL
/// - Target (목표): 100 mg/dL
/// - Low (낮음): 80 mg/dL
/// - Very Low (매우 낮음): 60 mg/dL
class GlucoseRangeScreen extends StatefulWidget {
  const GlucoseRangeScreen({super.key});

  @override
  State<GlucoseRangeScreen> createState() => _GlucoseRangeScreenState();
}

class _GlucoseRangeScreenState extends State<GlucoseRangeScreen> {
  /// 조절 단위 (mg/dL 기준)
  static const double _stepMgDl = 5.0;

  String _formatValue(double valueMgDl, String unit) {
    if (unit == AppConstants.unitMmolL) {
      return (valueMgDl / AppConstants.mgDlToMmolL).toStringAsFixed(1);
    }
    return valueMgDl.toStringAsFixed(0);
  }

  void _updateValue({
    required String field,
    required bool increment,
  }) {
    final settings = context.read<SettingsService>();
    final range = settings.glucoseRange;
    final step = increment ? _stepMgDl : -_stepMgDl;

    double newValue;
    switch (field) {
      case 'veryHigh':
        newValue = (range.veryHigh + step).clamp(50.0, 400.0);
        settings.setGlucoseRange(range.copyWith(veryHigh: newValue));
        break;
      case 'high':
        newValue = (range.high + step).clamp(50.0, 400.0);
        settings.setGlucoseRange(range.copyWith(high: newValue));
        break;
      case 'target':
        newValue = (range.target + step).clamp(50.0, 400.0);
        settings.setGlucoseRange(range.copyWith(target: newValue));
        break;
      case 'low':
        newValue = (range.low + step).clamp(50.0, 400.0);
        settings.setGlucoseRange(range.copyWith(low: newValue));
        break;
      case 'veryLow':
        newValue = (range.veryLow + step).clamp(50.0, 400.0);
        settings.setGlucoseRange(range.copyWith(veryLow: newValue));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final settings = context.watch<SettingsService>();
    final unit = settings.unit;
    final range = settings.glucoseRange;

    return LargeTitleScrollView(
      title: l10n.targetGlucoseRange,
      showBackButton: true,
      showLargeTitle: false,
      onRefresh: null,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Hero Section
              _buildHeroSection(context, theme, l10n),
              const SizedBox(height: 32),

              // Range Settings
              Container(
                decoration: context.decorations.card,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildRangeRow(
                      context: context,
                      theme: theme,
                      label: l10n.veryHigh,
                      color: Colors.red,
                      value: range.veryHigh,
                      unit: unit,
                      field: 'veryHigh',
                    ),
                    _buildDivider(context),
                    _buildRangeRow(
                      context: context,
                      theme: theme,
                      label: l10n.elevated,
                      color: AppTheme.iconOrange,
                      value: range.high,
                      unit: unit,
                      field: 'high',
                    ),
                    _buildDivider(context),
                    _buildRangeRow(
                      context: context,
                      theme: theme,
                      label: l10n.target,
                      color: AppTheme.iconGreen,
                      value: range.target,
                      unit: unit,
                      field: 'target',
                    ),
                    _buildDivider(context),
                    _buildRangeRow(
                      context: context,
                      theme: theme,
                      label: l10n.low,
                      color: AppTheme.iconBlue,
                      value: range.low,
                      unit: unit,
                      field: 'low',
                    ),
                    _buildDivider(context),
                    _buildRangeRow(
                      context: context,
                      theme: theme,
                      label: l10n.veryLow,
                      color: AppTheme.iconPurple,
                      value: range.veryLow,
                      unit: unit,
                      field: 'veryLow',
                    ),
                  ],
                ),
              ),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroSection(BuildContext context, ThemeData theme, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.iconOrange.withValues(alpha: 0.1),
            AppTheme.iconOrange.withValues(alpha: 0.05),
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
                  color: AppTheme.iconOrange.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              CupertinoIcons.chart_bar_fill,
              color: AppTheme.iconOrange,
              size: 32,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.targetGlucoseRangeDescription,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: context.colors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRangeRow({
    required BuildContext context,
    required ThemeData theme,
    required String label,
    required Color color,
    required double value,
    required String unit,
    required String field,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          // Color indicator (28x28 rounded square like HealthConnectScreen)
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Center(
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Label
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          // Value display
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: _formatValue(value, unit),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textPrimary(context),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                TextSpan(
                  text: ' $unit',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: context.colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // +/- Stepper
          Container(
            decoration: BoxDecoration(
              color: context.colors.textSecondary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Minus button
                GestureDetector(
                  onTap: () => _updateValue(field: field, increment: false),
                  child: Container(
                    width: 36,
                    height: 32,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        bottomLeft: Radius.circular(8),
                      ),
                    ),
                    child: Icon(
                      CupertinoIcons.minus,
                      size: 16,
                      color: context.colors.textSecondary,
                    ),
                  ),
                ),
                // Divider
                Container(
                  width: 1,
                  height: 20,
                  color: context.colors.divider,
                ),
                // Plus button
                GestureDetector(
                  onTap: () => _updateValue(field: field, increment: true),
                  child: Container(
                    width: 36,
                    height: 32,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(8),
                        bottomRight: Radius.circular(8),
                      ),
                    ),
                    child: Icon(
                      CupertinoIcons.plus,
                      size: 16,
                      color: context.colors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 52),
      child: Divider(
        height: 1,
        color: context.colors.divider,
      ),
    );
  }
}
