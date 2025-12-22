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
import 'package:glu_butler/providers/feed_provider.dart';

class FeedItemCard extends StatefulWidget {
  final FeedItem item;

  const FeedItemCard({super.key, required this.item});

  @override
  State<FeedItemCard> createState() => _FeedItemCardState();
}

class _FeedItemCardState extends State<FeedItemCard> with SingleTickerProviderStateMixin {
  late AnimationController _bounceController;
  late Animation<Offset> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 120),
      vsync: this,
    );

    // Very short, simple bounce: just a quick nudge left and back
    _bounceAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-0.02, 0),
    ).animate(
      CurvedAnimation(
        parent: _bounceController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  void _onTap() {
    // Only bounce if this is a deletable item (glucose from our app)
    if (widget.item.type == FeedItemType.glucose) {
      _bounceController.forward().then((_) {
        _bounceController.reverse();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final time = Jiffy.parseFromDateTime(widget.item.timestamp).format(pattern: 'HH:mm');
    final title = _getItemTitle(l10n);
    final sourceName = widget.item.sourceName;

    // Only glucose items can be deleted with swipe
    if (widget.item.type == FeedItemType.glucose) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Dismissible(
          key: Key(widget.item.id),
          direction: DismissDirection.endToStart,
          confirmDismiss: (direction) async {
            return await _showDeleteConfirmation(context, l10n);
          },
          onDismissed: (direction) async {
            await _deleteGlucoseItem(context);
          },
          background: Container(
            padding: const EdgeInsets.only(right: 20),
            alignment: Alignment.centerRight,
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.delete,
              color: Colors.white,
              size: 28,
            ),
          ),
          child: SlideTransition(
            position: _bounceAnimation,
            child: GestureDetector(
              onTap: _onTap,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: _buildCardContent(context, theme, l10n, time, title, sourceName, includeMargin: false),
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Non-glucose items: no swipe delete
    return _buildCardContent(context, theme, l10n, time, title, sourceName, includeMargin: true);
  }

  Future<bool?> _showDeleteConfirmation(BuildContext context, AppLocalizations l10n) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.delete),
        content: Text(l10n.deleteGlucoseConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteGlucoseItem(BuildContext context) async {
    final provider = context.read<FeedProvider>();
    final l10n = AppLocalizations.of(context)!;

    final success = await provider.deleteGlucoseRecord(
      widget.item.glucoseRecord!.id,
      widget.item.timestamp,
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? l10n.glucoseDeleted : l10n.deleteFailed,
          ),
          backgroundColor: success ? Colors.green : Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Widget _buildCardContent(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
    String time,
    String title,
    String? sourceName, {
    bool includeMargin = true,
  }) {
    return Container(
      margin: includeMargin ? const EdgeInsets.symmetric(horizontal: 16, vertical: 6) : EdgeInsets.zero,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        // For glucose items (includeMargin=false), don't add borderRadius as it's handled by ClipRRect
        borderRadius: includeMargin ? BorderRadius.circular(16) : null,
        // Only show shadow for non-glucose items (glucose items are in ClipRRect which clips shadows)
        boxShadow: includeMargin ? [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ] : null,
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
    switch (widget.item.type) {
      case FeedItemType.glucose:
        return l10n.bloodGlucose;
      case FeedItemType.exercise:
        return _formatExerciseType(widget.item.exerciseRecord!.exerciseType);
      case FeedItemType.sleep:
        return l10n.sleep;
      case FeedItemType.meal:
        return _formatMealType(widget.item.mealRecord!.mealType);
      case FeedItemType.water:
        return l10n.waterIntake;
      case FeedItemType.insulin:
        return l10n.insulin;
      case FeedItemType.mindfulness:
        return l10n.mindfulness;
    }
  }

  Widget _buildValue(BuildContext context, ThemeData theme, AppLocalizations l10n) {
    switch (widget.item.type) {
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
    final glucose = widget.item.glucoseRecord!;
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
    final exercise = widget.item.exerciseRecord!;
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
    final sleep = widget.item.sleepRecord!;
    return Text(
      sleep.formattedDuration,
      style: theme.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildMealValue(ThemeData theme) {
    final meal = widget.item.mealRecord!;
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
    final water = widget.item.waterRecord!;
    return Text(
      water.formattedAmount(),
      style: theme.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildInsulinValue(ThemeData theme) {
    final insulin = widget.item.insulinRecord!;
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
    final mindfulness = widget.item.mindfulnessRecord!;
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
    Color backgroundColor;

    switch (widget.item.type) {
      case FeedItemType.glucose:
        icon = Icons.water_drop;
        // Always use red for glucose drop icon
        color = Colors.red;
        final glucose = widget.item.glucoseRecord;
        if (glucose != null) {
          // Calculate 5-level status for background color
          final settings = context.watch<SettingsService>();
          final glucoseRange = settings.glucoseRange;
          final mgDlValue = glucose.valueIn('mg/dL');
          final status = _getGlucoseStatus(mgDlValue, glucoseRange);
          backgroundColor = _getGlucoseColor(status);
        } else {
          backgroundColor = AppTheme.primaryColor;
        }
      case FeedItemType.exercise:
        icon = Icons.fitness_center;
        color = Colors.orange;
        backgroundColor = color;
      case FeedItemType.sleep:
        icon = Icons.bedtime;
        color = Colors.indigo;
        backgroundColor = color;
      case FeedItemType.meal:
        icon = Icons.restaurant;
        color = Colors.green;
        backgroundColor = color;
      case FeedItemType.water:
        icon = Icons.local_drink;
        color = Colors.lightBlue;
        backgroundColor = color;
      case FeedItemType.insulin:
        icon = Icons.vaccines;
        color = Colors.purple;
        backgroundColor = color;
      case FeedItemType.mindfulness:
        icon = Icons.self_improvement;
        color = Colors.teal;
        backgroundColor = color;
    }

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: backgroundColor.withValues(alpha: 0.15),
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
