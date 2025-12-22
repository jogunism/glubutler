import 'package:flutter/material.dart';
import 'package:jiffy/jiffy.dart';
import 'package:provider/provider.dart';
import 'package:glu_butler/models/feed_item.dart';
import 'package:glu_butler/models/insulin_record.dart';
import 'package:glu_butler/models/glucose_range_settings.dart';
import 'package:glu_butler/l10n/app_localizations.dart';
import 'package:glu_butler/core/constants/app_constants.dart';
import 'package:glu_butler/core/theme/app_theme.dart';
import 'package:glu_butler/core/theme/app_colors.dart';
import 'package:glu_butler/services/settings_service.dart';

class FeedItemCard extends StatelessWidget {
  final FeedItem item;

  const FeedItemCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final time = Jiffy.parseFromDateTime(item.timestamp).format(pattern: 'HH:mm');
    final title = _getItemTitle(l10n);
    final sourceName = item.sourceName;

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
            _buildIcon(context, theme),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Title row - aligned with icon top
                  Row(
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: context.colors.textSecondary,
                        ),
                      ),
                      if (sourceName != null) ...[
                        Text(
                          ' · $sourceName',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: context.colors.textSecondary.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ],
                  ),
                  // Value - below icon bottom
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: _buildValue(context, theme, l10n),
                  ),
                ],
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  time,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: context.colors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getItemTitle(AppLocalizations l10n) {
    switch (item.type) {
      case FeedItemType.glucose:
        return l10n.bloodGlucose;
      case FeedItemType.exercise:
        return _formatExerciseType(item.exerciseRecord!.exerciseType);
      case FeedItemType.sleep:
        return 'Sleep';
      case FeedItemType.meal:
        return _formatMealType(item.mealRecord!.mealType);
      case FeedItemType.water:
        return 'Water';
      case FeedItemType.insulin:
        return l10n.insulin;
      case FeedItemType.mindfulness:
        return 'Mindfulness';
    }
  }

  Widget _buildValue(BuildContext context, ThemeData theme, AppLocalizations l10n) {
    switch (item.type) {
      case FeedItemType.glucose:
        return _buildGlucoseValue(context, theme);
      case FeedItemType.exercise:
        return _buildExerciseValue(theme);
      case FeedItemType.sleep:
        return _buildSleepValue(theme);
      case FeedItemType.meal:
        return _buildMealValue(theme);
      case FeedItemType.water:
        return _buildWaterValue(theme);
      case FeedItemType.insulin:
        return _buildInsulinValue(theme);
      case FeedItemType.mindfulness:
        return _buildMindfulnessValue(theme);
    }
  }

  Widget _buildGlucoseValue(BuildContext context, ThemeData theme) {
    final glucose = item.glucoseRecord!;
    final settings = context.watch<SettingsService>();
    final unit = settings.unit;
    final l10n = AppLocalizations.of(context)!;

    // 단위 변환
    final isMmol = unit == AppConstants.unitMmolL;
    final displayValue = isMmol
        ? (glucose.value / AppConstants.mgDlToMmolL).toStringAsFixed(1)
        : glucose.value.toStringAsFixed(0);

    // Calculate 5-level status based on glucose range settings
    final glucoseRange = settings.glucoseRange;
    final mgDlValue = glucose.valueIn('mg/dL');
    final status = _getGlucoseStatus(mgDlValue, glucoseRange);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          displayValue,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          unit,
          style: theme.textTheme.bodySmall?.copyWith(
            color: context.colors.textSecondary,
          ),
        ),
        const SizedBox(width: 8),
        // Show meal context chip (always show, default to fasting if null or empty)
        _buildMealContextChip(
          context,
          (glucose.mealContext == null || glucose.mealContext!.isEmpty)
            ? 'fasting'
            : glucose.mealContext!,
          theme,
          l10n,
        ),
        const SizedBox(width: 4),
        // Then show status chip
        _buildStatusChip(status, theme, l10n),
      ],
    );
  }

  Widget _buildExerciseValue(ThemeData theme) {
    final exercise = item.exerciseRecord!;
    return Row(
      children: [
        Text(
          '${exercise.durationMinutes} min',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        if (exercise.calories != null) ...[
          const SizedBox(width: 12),
          Text(
            '${exercise.calories} kcal',
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ],
    );
  }

  Widget _buildSleepValue(ThemeData theme) {
    final sleep = item.sleepRecord!;
    return Text(
      sleep.formattedDuration,
      style: theme.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildMealValue(ThemeData theme) {
    final meal = item.mealRecord!;
    if (meal.description != null) {
      return Text(
        meal.description!,
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildWaterValue(ThemeData theme) {
    final water = item.waterRecord!;
    return Text(
      water.formattedAmount(),
      style: theme.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildInsulinValue(ThemeData theme) {
    final insulin = item.insulinRecord!;
    return Row(
      children: [
        Text(
          insulin.formattedUnits,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          insulin.insulinType.displayName,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildMindfulnessValue(ThemeData theme) {
    final mindfulness = item.mindfulnessRecord!;
    return Text(
      mindfulness.formattedDuration,
      style: theme.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildIcon(BuildContext context, ThemeData theme) {
    IconData icon;
    Color color;

    switch (item.type) {
      case FeedItemType.glucose:
        icon = Icons.water_drop;
        final glucose = item.glucoseRecord;
        if (glucose != null) {
          // Calculate 5-level status for icon color
          final settings = context.watch<SettingsService>();
          final glucoseRange = settings.glucoseRange;
          final mgDlValue = glucose.valueIn('mg/dL');
          final status = _getGlucoseStatus(mgDlValue, glucoseRange);
          color = _getGlucoseColor(status);
        } else {
          color = AppTheme.primaryColor;
        }
      case FeedItemType.exercise:
        icon = Icons.fitness_center;
        color = Colors.orange;
      case FeedItemType.sleep:
        icon = Icons.bedtime;
        color = Colors.indigo;
      case FeedItemType.meal:
        icon = Icons.restaurant;
        color = Colors.green;
      case FeedItemType.water:
        icon = Icons.local_drink;
        color = Colors.lightBlue;
      case FeedItemType.insulin:
        icon = Icons.vaccines;
        color = Colors.purple;
      case FeedItemType.mindfulness:
        icon = Icons.self_improvement;
        color = Colors.teal;
    }

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }

  Color _getGlucoseColor(String status) {
    switch (status) {
      case 'veryLow':
        return Colors.purple;
      case 'low':
        return Colors.blue;
      case 'high':
        return Colors.yellow.shade700;
      case 'veryHigh':
        return Colors.red;
      default:
        return AppTheme.glucoseNormal;  // Green color for normal range
    }
  }

  /// Calculate 5-level glucose status based on target ± 20 range
  String _getGlucoseStatus(double mgDlValue, GlucoseRangeSettings range) {
    // target ± 20 범위를 Normal로 설정
    final normalLow = range.target - 20;
    final normalHigh = range.target + 20;

    // 5단계 분류
    if (mgDlValue < normalLow - 20) {
      return 'veryLow';  // target - 40 미만
    } else if (mgDlValue < normalLow) {
      return 'low';  // target - 40 ~ target - 20
    } else if (mgDlValue <= normalHigh) {
      return 'normal';  // target - 20 ~ target + 20
    } else if (mgDlValue <= normalHigh + 20) {
      return 'high';  // target + 20 ~ target + 40
    } else {
      return 'veryHigh';  // target + 40 초과
    }
  }

  Widget _buildMealContextChip(BuildContext context, String mealContext, ThemeData theme, AppLocalizations l10n) {
    String label;
    switch (mealContext) {
      case 'before_meal':
        label = l10n.beforeMeal;
      case 'after_meal':
        label = l10n.afterMeal;
      case 'fasting':
        label = l10n.fasting;
      default:
        label = l10n.unspecified;
    }

    final color = context.colors.textSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status, ThemeData theme, AppLocalizations l10n) {
    Color color;
    String label;

    switch (status) {
      case 'veryLow':
        color = Colors.purple;
        label = l10n.veryLow;
      case 'low':
        color = Colors.blue;
        label = l10n.low;
      case 'high':
        color = Colors.yellow.shade700;
        label = l10n.elevated;
      case 'veryHigh':
        color = Colors.red;
        label = l10n.veryHigh;
      default:
        color = AppTheme.glucoseNormal;  // Green color for normal range
        label = l10n.normal;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _formatExerciseType(String type) {
    switch (type) {
      case 'running':
        return 'Running';
      case 'walking':
        return 'Walking';
      case 'cycling':
        return 'Cycling';
      case 'swimming':
        return 'Swimming';
      case 'yoga':
        return 'Yoga';
      case 'strength':
        return 'Strength Training';
      case 'hiit':
        return 'HIIT';
      default:
        return 'Workout';
    }
  }

  String _formatMealType(String type) {
    switch (type) {
      case 'breakfast':
        return 'Breakfast';
      case 'lunch':
        return 'Lunch';
      case 'dinner':
        return 'Dinner';
      case 'snack':
        return 'Snack';
      default:
        return 'Meal';
    }
  }

}
