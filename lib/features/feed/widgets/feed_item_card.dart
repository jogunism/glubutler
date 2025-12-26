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
import 'package:glu_butler/core/widgets/top_banner.dart';
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
  void didUpdateWidget(FeedItemCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If the item ID changed, update bounce callback registration
    if (oldWidget.item.id != widget.item.id) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        final provider = context.read<FeedProvider>();

        // Unregister old callback
        provider.unregisterBounceCallback(oldWidget.item.id);

        // Register new callback if this item is bouncable
        if (provider.bouncableItemIds.contains(widget.item.id)) {
          provider.registerBounceCallback(widget.item.id, _performBounce);
        }
      });
    }
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
    // Only bounce if this is a deletable item (glucose or insulin from our app)
    final isDeletable =
        widget.item.type == FeedItemType.glucose ||
        widget.item.type == FeedItemType.insulin;
    if (isDeletable) {
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
    final sourceName =
        (widget.item.type == FeedItemType.steps ||
            widget.item.type == FeedItemType.waterGroup)
        ? null
        : widget.item.sourceName;

    // Glucose and insulin items can be deleted with swipe
    final isDeletable =
        widget.item.type == FeedItemType.glucose ||
        widget.item.type == FeedItemType.insulin;

    if (isDeletable) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Dismissible(
          key: Key(widget.item.id),
          direction: DismissDirection.endToStart,
          confirmDismiss: (direction) async {
            return await _showDeleteConfirmation(context, l10n);
          },
          onDismissed: (direction) async {
            if (widget.item.type == FeedItemType.glucose) {
              await _deleteGlucoseItem(context);
            } else if (widget.item.type == FeedItemType.insulin) {
              await _deleteInsulinItem(context);
            }
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
      if (success) {
        TopBanner.success(context, message: l10n.glucoseDeleted);
      } else {
        TopBanner.error(context, message: l10n.deleteFailed);
      }
    }
  }

  Future<void> _deleteInsulinItem(BuildContext context) async {
    final provider = context.read<FeedProvider>();
    final l10n = AppLocalizations.of(context)!;

    final success = await provider.deleteInsulinRecord(
      widget.item.insulinRecord!.id,
      widget.item.timestamp,
    );

    if (context.mounted) {
      if (success) {
        TopBanner.success(context, message: l10n.insulinDeleted);
      } else {
        TopBanner.error(context, message: l10n.deleteFailed);
      }
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
    // Large size for glucose and insulin, smaller for others
    final isLargeItem =
        widget.item.type == FeedItemType.glucose ||
        widget.item.type == FeedItemType.insulin;

    // Hide time for steps and water group items
    final shouldShowTime =
        widget.item.type != FeedItemType.steps &&
        widget.item.type != FeedItemType.waterGroup;

    // For sleep group, show time range instead of single time
    final isSleepGroup = widget.item.type == FeedItemType.sleepGroup;

    // Large items (glucose & insulin): full size, others: 70% size
    final verticalMargin = isLargeItem ? 6.0 : 4.0;
    final cardPadding = isLargeItem ? 16.0 : 11.0;
    final iconSpacing = isLargeItem ? 16.0 : 11.0;
    final titleValueSpacing = isLargeItem ? 0.0 : 4.0;

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
          crossAxisAlignment: isLargeItem
              ? CrossAxisAlignment.start
              : CrossAxisAlignment.center,
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
                          fontSize: isLargeItem ? null : 11,
                        ),
                      ),
                      if (sourceName != null) ...[
                        Text(
                          ' · $sourceName',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: context.colors.textSecondary.withValues(
                              alpha: 0.7,
                            ),
                            fontSize: isLargeItem ? null : 10,
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
                        fontSize: isLargeItem ? null : 11,
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
        return l10n.exercise; // 모든 운동을 "운동"으로 통합
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
        return l10n
            .bloodGlucose; // CGM groups are handled separately in feed_screen
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
    final l10n = AppLocalizations.of(context)!;

    // Get localized insulin type name (only rapidActing and longActing are used in UI)
    String getLocalizedInsulinType(InsulinType type) {
      switch (type) {
        case InsulinType.rapidActing:
          return l10n.rapidActing;
        case InsulinType.longActing:
          return l10n.longActing;
        default:
          // Fallback for types not supported in UI (shortActing, intermediate, mixed)
          return type.displayName;
      }
    }

    final color = context.colors.textSecondary;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          insulin.units.toStringAsFixed(1),
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          l10n.units,
          style: theme.textTheme.bodySmall?.copyWith(
            color: context.colors.textSecondary,
          ),
        ),
        const SizedBox(width: 8),
        // Insulin type chip (similar to meal context chip for glucose)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            getLocalizedInsulinType(insulin.insulinType),
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
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
    final stepsText = steps.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
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

    final timeRange =
        '${formatTime(sleepGroup.startTime)} ~ ${formatTime(sleepGroup.endTime)}';

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

  Widget _buildIcon(
    BuildContext context,
    ThemeData theme,
    SettingsService settings,
  ) {
    IconData icon;
    Color color;
    Color backgroundColor;
    // Large size for glucose and insulin
    final isLargeItem =
        widget.item.type == FeedItemType.glucose ||
        widget.item.type == FeedItemType.insulin;

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
        icon = Icons.local_fire_department; // 모든 운동을 불꽃 아이콘으로 통합
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
        backgroundColor =
            AppTheme.primaryColor; // CGM groups handled separately
    }

    // Large items (glucose & insulin): full size, others: 70% size
    final iconSize = isLargeItem ? 44.0 : 31.0;
    final iconInnerSize = isLargeItem ? 24.0 : 17.0;
    final borderRadius = isLargeItem ? 12.0 : 8.0;

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
      case 'warning':
        return AppTheme.glucoseHigh; // 주의 - 주황색
      case 'high':
        return AppTheme.glucoseHigh; // 높음 - 주황색
      case 'veryHigh':
        return AppTheme.glucoseVeryHigh;
      default:
        return AppTheme.glucoseNormal;
    }
  }

  /// Calculate 5-level glucose status based on target ± 20 range
  String _getGlucoseStatus(double mgDlValue, GlucoseRangeSettings range) {
    // 6단계 분류:
    // veryLow: < range.veryLow (60)
    // low: range.veryLow ~ range.low (60 ~ 80)
    // normal: range.low ~ targetHigh (80 ~ 120, target ± 20)
    // warning: targetHigh ~ range.high (120 ~ 160)
    // high: range.high ~ range.veryHigh (160 ~ 180)
    // veryHigh: >= range.veryHigh (180+)

    final targetHigh = range.target + 20; // 120 (목표 100 기준)

    if (mgDlValue < range.veryLow) {
      return 'veryLow'; // < 60
    } else if (mgDlValue < range.low) {
      return 'low'; // 60 ~ 80
    } else if (mgDlValue <= targetHigh) {
      return 'normal'; // 80 ~ 120
    } else if (mgDlValue < range.high) {
      return 'warning'; // 120 ~ 160 (주의)
    } else if (mgDlValue < range.veryHigh) {
      return 'high'; // 160 ~ 180 (높음)
    } else {
      return 'veryHigh'; // >= 180 (매우 높음)
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
      case 'warning':
        color = AppTheme.glucoseHigh;
        label = l10n.warning; // 주의
      case 'high':
        color = AppTheme.glucoseHigh;
        label = l10n.high; // 높음
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
}
