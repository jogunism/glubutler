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
import 'package:glu_butler/core/theme/app_decorations.dart';
import 'package:glu_butler/services/settings_service.dart';
import 'package:glu_butler/providers/feed_provider.dart';

class FeedItemCard extends StatefulWidget {
  final FeedItem item;

  const FeedItemCard({super.key, required this.item});

  @override
  State<FeedItemCard> createState() => _FeedItemCardState();
}

class _FeedItemCardState extends State<FeedItemCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _bounceController;
  late Animation<Offset> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 120),
      vsync: this,
    );

    _bounceAnimation =
        Tween<Offset>(begin: Offset.zero, end: const Offset(-0.04, 0)).animate(
          CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
        );

    // Register bounce callback with provider if this item is bouncable
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<FeedProvider>();
      if (provider.bouncableItemIds.contains(widget.item.id)) {
        provider.registerBounceCallback(widget.item.id, _performBounce);
      }
    });
  }

  void _performBounce() {
    if (!mounted) return;

    final provider = context.read<FeedProvider>();
    if (!provider.bouncableItemIds.contains(widget.item.id)) return;

    _bounceController.forward().then((_) {
      if (mounted) {
        _bounceController.reverse();
      }
    });
  }

  @override
  void dispose() {
    // Unregister callback - use try-catch to handle cases where context is no longer valid
    try {
      if (mounted) {
        context.read<FeedProvider>().unregisterBounceCallback(widget.item.id);
      }
    } catch (e) {
      // Context may not be available during disposal, ignore
    }
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
    final settings = context.watch<SettingsService>();
    final time = Jiffy.parseFromDateTime(
      widget.item.timestamp,
    ).format(pattern: 'HH:mm');
    final title = _getItemTitle(l10n);

    // Hide source name for steps and water group items
    final sourceName = (widget.item.type == FeedItemType.steps ||
                        widget.item.type == FeedItemType.waterGroup)
        ? null
        : widget.item.sourceName;

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
              color: AppTheme.iconRed,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.delete, color: Colors.white, size: 28),
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
                  child: _buildCardContent(
                    context,
                    theme,
                    l10n,
                    settings,
                    time,
                    title,
                    sourceName,
                    includeMargin: false,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Non-glucose items: no swipe delete
    return _buildCardContent(
      context,
      theme,
      l10n,
      settings,
      time,
      title,
      sourceName,
      includeMargin: true,
    );
  }

  Future<bool?> _showDeleteConfirmation(
    BuildContext context,
    AppLocalizations l10n,
  ) {
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
            style: TextButton.styleFrom(foregroundColor: AppTheme.iconRed),
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
          content: Text(success ? l10n.glucoseDeleted : l10n.deleteFailed),
          backgroundColor: success ? AppTheme.iconGreen : AppTheme.iconRed,
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
    SettingsService settings,
    String time,
    String title,
    String? sourceName, {
    bool includeMargin = true,
  }) {
    final baseDecoration = context.decorations.card;
    final isGlucose = widget.item.type == FeedItemType.glucose;

    // Hide time for steps and water group items
    final shouldShowTime = widget.item.type != FeedItemType.steps &&
                           widget.item.type != FeedItemType.waterGroup;

    // For sleep group, show time range instead of single time
    final isSleepGroup = widget.item.type == FeedItemType.sleepGroup;

    // Non-glucose items: 70% size (reduced padding and spacing)
    final verticalMargin = isGlucose ? 6.0 : 4.0;
    final cardPadding = isGlucose ? 16.0 : 11.0;
    final iconSpacing = isGlucose ? 16.0 : 11.0;
    final titleValueSpacing = isGlucose ? 8.0 : 4.0;

    return Container(
      margin: includeMargin
          ? EdgeInsets.symmetric(horizontal: 16, vertical: verticalMargin)
          : EdgeInsets.zero,
      padding: EdgeInsets.all(cardPadding),
      decoration: includeMargin
          ? baseDecoration.copyWith(borderRadius: BorderRadius.circular(16))
          : baseDecoration,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildIcon(context, theme, settings),
            SizedBox(width: iconSpacing),
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
                          fontSize: isGlucose ? null : 11,
                        ),
                      ),
                      if (sourceName != null) ...[
                        Text(
                          ' · $sourceName',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: context.colors.textSecondary.withValues(
                              alpha: 0.7,
                            ),
                            fontSize: isGlucose ? null : 10,
                          ),
                        ),
                      ],
                    ],
                  ),
                  // Value - below icon bottom
                  Padding(
                    padding: EdgeInsets.only(top: titleValueSpacing),
                    child: _buildValue(context, theme, l10n),
                  ),
                ],
              ),
            ),
            if (shouldShowTime)
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isSleepGroup)
                    _buildSleepTimeRange(theme)
                  else
                    Text(
                      time,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: context.colors.textSecondary,
                        fontSize: isGlucose ? null : 11,
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
        final exerciseType = widget.item.exerciseRecord?.exerciseType ?? 'other';
        return _formatExerciseType(exerciseType, l10n);
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
      case FeedItemType.steps:
        return l10n.steps;
      case FeedItemType.sleepGroup:
        return l10n.sleep;
      case FeedItemType.waterGroup:
        return l10n.waterIntake;
      case FeedItemType.cgmGroup:
        return l10n.bloodGlucose; // CGM groups are handled separately in feed_screen
    }
  }

  Widget _buildValue(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
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
      case FeedItemType.steps:
        return _buildStepsValue(theme, l10n);
      case FeedItemType.sleepGroup:
        return _buildSleepGroupValue(theme);
      case FeedItemType.waterGroup:
        return _buildWaterGroupValue(theme);
      case FeedItemType.cgmGroup:
        return const SizedBox.shrink(); // CGM groups are handled separately
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

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 4,
      runSpacing: 4,
      children: [
        Text(
          displayValue,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          unit,
          style: theme.textTheme.bodySmall?.copyWith(
            color: context.colors.textSecondary,
          ),
        ),
        const SizedBox(width: 4),
        // Show meal context chip (always show, default to fasting if null or empty)
        _buildMealContextChip(
          context,
          (glucose.mealContext == null || glucose.mealContext!.isEmpty)
              ? 'fasting'
              : glucose.mealContext!,
          theme,
          l10n,
        ),
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
            fontSize: 16,
          ),
        ),
        if (exercise.calories != null) ...[
          const SizedBox(width: 8),
          Text(
            '${exercise.calories} kcal',
            style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13),
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
        fontSize: 16,
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
          fontSize: 16,
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
        fontSize: 16,
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
            fontSize: 16,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          insulin.insulinType.displayName,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
            fontSize: 13,
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
        fontSize: 16,
      ),
    );
  }

  Widget _buildStepsValue(ThemeData theme, AppLocalizations l10n) {
    final stepsData = widget.item.stepsData!;
    final steps = stepsData['steps'] as int;
    final distanceKm = stepsData['distanceKm'] as double?;

    // Build the display text
    final stepsText = steps.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
    final distanceText = (distanceKm != null && distanceKm > 0)
        ? ' · ${distanceKm.toStringAsFixed(2)} km'
        : '';

    return Text(
      '$stepsText$distanceText',
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        fontSize: 16,
      ),
    );
  }

  Widget _buildSleepGroupValue(ThemeData theme) {
    final sleepGroup = widget.item.sleepGroup!;

    return Text(
      sleepGroup.formattedDuration,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        fontSize: 16,
      ),
    );
  }

  Widget _buildSleepTimeRange(ThemeData theme) {
    final sleepGroup = widget.item.sleepGroup!;

    // Format time as HH:mm (24-hour format)
    String formatTime(DateTime time) {
      final hour = time.hour.toString().padLeft(2, '0');
      final minute = time.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    }

    final timeRange = '${formatTime(sleepGroup.startTime)} ~ ${formatTime(sleepGroup.endTime)}';

    return Text(
      timeRange,
      style: theme.textTheme.bodySmall?.copyWith(
        color: context.colors.textSecondary,
        fontSize: 11,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildWaterGroupValue(ThemeData theme) {
    final waterGroup = widget.item.waterGroup!;
    return Text(
      waterGroup.formattedAmount(),
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        fontSize: 16,
      ),
    );
  }

  Widget _buildIcon(BuildContext context, ThemeData theme, SettingsService settings) {
    IconData icon;
    Color color;
    Color backgroundColor;
    final isGlucose = widget.item.type == FeedItemType.glucose;

    switch (widget.item.type) {
      case FeedItemType.glucose:
        icon = Icons.water_drop;
        // Always use red for glucose drop icon
        color = AppTheme.iconRed;
        final glucose = widget.item.glucoseRecord;
        if (glucose != null) {
          // Calculate 5-level status for background color
          final glucoseRange = settings.glucoseRange;
          final mgDlValue = glucose.valueIn('mg/dL');
          final status = _getGlucoseStatus(mgDlValue, glucoseRange);
          backgroundColor = _getGlucoseColor(status);
        } else {
          backgroundColor = AppTheme.primaryColor;
        }
      case FeedItemType.exercise:
        final exerciseType = widget.item.exerciseRecord?.exerciseType ?? 'other';
        icon = _getExerciseIcon(exerciseType);
        color = AppTheme.iconOrange;
        backgroundColor = color;
      case FeedItemType.sleep:
        icon = Icons.bedtime;
        color = AppTheme.iconIndigo;
        backgroundColor = color;
      case FeedItemType.meal:
        icon = Icons.restaurant;
        color = AppTheme.iconGreen;
        backgroundColor = color;
      case FeedItemType.water:
        icon = Icons.local_drink;
        color = AppTheme.iconLightBlue;
        backgroundColor = color;
      case FeedItemType.insulin:
        icon = Icons.vaccines;
        color = AppTheme.iconPurple;
        backgroundColor = color;
      case FeedItemType.mindfulness:
        icon = Icons.self_improvement;
        color = AppTheme.iconTeal;
        backgroundColor = color;
      case FeedItemType.steps:
        icon = Icons.directions_walk;
        color = AppTheme.iconGreen;
        backgroundColor = color;
      case FeedItemType.sleepGroup:
        icon = Icons.bedtime;
        color = AppTheme.iconIndigo;
        backgroundColor = color;
      case FeedItemType.waterGroup:
        icon = Icons.local_drink;
        color = AppTheme.iconBlue;
        backgroundColor = color;
      case FeedItemType.cgmGroup:
        icon = Icons.water_drop;
        color = AppTheme.iconRed;
        backgroundColor = AppTheme.primaryColor; // CGM groups handled separately
    }

    // Non-glucose items: 70% size
    final iconSize = isGlucose ? 44.0 : 31.0;
    final iconInnerSize = isGlucose ? 24.0 : 17.0;
    final borderRadius = isGlucose ? 12.0 : 8.0;

    return Container(
      width: iconSize,
      height: iconSize,
      decoration: BoxDecoration(
        color: backgroundColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Icon(icon, color: color, size: iconInnerSize),
    );
  }

  Color _getGlucoseColor(String status) {
    switch (status) {
      case 'veryLow':
        return AppTheme.glucoseVeryLow;
      case 'low':
        return AppTheme.glucoseLow;
      case 'high':
        return AppTheme.glucoseHigh;
      case 'veryHigh':
        return AppTheme.glucoseVeryHigh;
      default:
        return AppTheme.glucoseNormal;
    }
  }

  /// Calculate 5-level glucose status based on target ± 20 range
  String _getGlucoseStatus(double mgDlValue, GlucoseRangeSettings range) {
    // target ± 20 범위를 Normal로 설정
    final normalLow = range.target - 20;
    final normalHigh = range.target + 20;

    // 5단계 분류
    if (mgDlValue < normalLow - 20) {
      return 'veryLow'; // target - 40 미만
    } else if (mgDlValue < normalLow) {
      return 'low'; // target - 40 ~ target - 20
    } else if (mgDlValue <= normalHigh) {
      return 'normal'; // target - 20 ~ target + 20
    } else if (mgDlValue <= normalHigh + 20) {
      return 'high'; // target + 20 ~ target + 40
    } else {
      return 'veryHigh'; // target + 40 초과
    }
  }

  Widget _buildMealContextChip(
    BuildContext context,
    String mealContext,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    String label;
    switch (mealContext) {
      case 'before_meal':
        label = l10n.beforeMeal;
      case 'after_meal':
        label = l10n.afterMeal;
      case 'fasting':
      default:
        label = l10n.fasting;
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

  Widget _buildStatusChip(
    String status,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    Color color;
    String label;

    switch (status) {
      case 'veryLow':
        color = AppTheme.glucoseVeryLow;
        label = l10n.veryLow;
      case 'low':
        color = AppTheme.glucoseLow;
        label = l10n.low;
      case 'high':
        color = AppTheme.glucoseHigh;
        label = l10n.elevated;
      case 'veryHigh':
        color = AppTheme.glucoseVeryHigh;
        label = l10n.veryHigh;
      default:
        color = AppTheme.glucoseNormal;
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

  String _formatExerciseType(String type, AppLocalizations l10n) {
    switch (type) {
      case 'running':
        return l10n.running;
      case 'walking':
        return l10n.walking;
      case 'cycling':
        return l10n.cycling;
      case 'swimming':
        return l10n.swimming;
      case 'yoga':
        return l10n.yoga;
      case 'strength':
        return l10n.strength;
      case 'hiit':
        return l10n.hiit;
      case 'stairs':
        return l10n.stairs;
      case 'dance':
        return l10n.dance;
      case 'functional':
        return l10n.functional;
      case 'core':
        return l10n.core;
      case 'flexibility':
        return l10n.flexibility;
      case 'cardio':
        return l10n.cardio;
      default:
        return l10n.other;
    }
  }

  IconData _getExerciseIcon(String exerciseType) {
    switch (exerciseType) {
      case 'running':
        return Icons.directions_run;
      case 'walking':
        return Icons.directions_walk;
      case 'cycling':
        return Icons.directions_bike;
      case 'swimming':
        return Icons.pool;
      case 'yoga':
        return Icons.self_improvement;
      case 'strength':
        return Icons.fitness_center;
      case 'hiit':
        return Icons.local_fire_department;
      case 'stairs':
        return Icons.stairs;
      case 'dance':
        return Icons.music_note;
      case 'functional':
      case 'core':
        return Icons.fitness_center;
      case 'flexibility':
        return Icons.accessibility_new;
      case 'cardio':
        return Icons.favorite;
      default:
        return Icons.fitness_center;
    }
  }
}
