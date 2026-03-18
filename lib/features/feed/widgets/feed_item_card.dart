import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
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
import 'package:glu_butler/core/widgets/swipeable_card.dart';

class FeedItemCard extends StatelessWidget {
  final FeedItem item;

  const FeedItemCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final settings = context.watch<SettingsService>();
    final feedProvider = context.watch<FeedProvider>();
    final time = Jiffy.parseFromDateTime(
      item.timestamp,
    ).format(pattern: 'HH:mm');
    final title = _getItemTitle(l10n);

    // Hide source name for steps and water group items
    final sourceName =
        (item.type == FeedItemType.steps ||
            item.type == FeedItemType.waterGroup)
        ? null
        : item.sourceName;

    // Glucose and insulin items can be swiped
    final isSwipeable =
        item.type == FeedItemType.glucose || item.type == FeedItemType.insulin;

    // Use item.id as stable key
    return SwipeableCard(
      key: isSwipeable ? ValueKey(item.id) : null,
      swipeable: isSwipeable,
      bounceable: isSwipeable,
      bounceToken: feedProvider.bounceTimestamp,
      onDelete: () => _deleteItem(context),
      child: _buildCardContent(
        context,
        theme,
        l10n,
        settings,
        time,
        title,
        sourceName,
        includeMargin: true,
      ),
    );
  }

  void _deleteItem(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;

    // 아이템 타입에 따라 타이틀과 메시지 결정
    final title = item.type == FeedItemType.glucose
        ? l10n.deleteGlucose
        : l10n.deleteInsulin;
    final message = item.type == FeedItemType.glucose
        ? l10n.deleteGlucoseConfirmation
        : l10n.deleteInsulinConfirmation;

    // 삭제 확인 다이얼로그 표시
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    // 사용자가 취소를 선택한 경우 열려있는 스와이프 카드 닫기
    if (confirmed != true) {
      SwipeableCardState.closeAnyOpenCard();
      return;
    }

    print('[FeedItemCard] Delete button pressed for item: ${item.id}');
    final feedProvider = context.read<FeedProvider>();

    try {
      // 아이템 타입에 따라 삭제
      if (item.type == FeedItemType.glucose) {
        print('[FeedItemCard] Deleting glucose record...');
        final result = await feedProvider.deleteGlucoseRecord(
          item.id,
          item.timestamp,
        );
        print('[FeedItemCard] Delete glucose result: $result');
      } else if (item.type == FeedItemType.insulin) {
        print('[FeedItemCard] Deleting insulin record...');
        final result = await feedProvider.deleteInsulinRecord(
          item.id,
          item.timestamp,
        );
        print('[FeedItemCard] Delete insulin result: $result');
      }
    } catch (e) {
      print('[FeedItemCard] Delete error: $e');
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
        item.type == FeedItemType.glucose || item.type == FeedItemType.insulin;

    // Hide time for steps and water group items
    final shouldShowTime =
        item.type != FeedItemType.steps && item.type != FeedItemType.waterGroup;

    // For sleep group, show time range instead of single time
    final isSleepGroup = item.type == FeedItemType.sleepGroup;

    // Large items (glucose & insulin): full size, others: 70% size
    final verticalMargin = 5.0;
    final cardPadding = isLargeItem ? 16.0 : 11.0;
    final iconSpacing = isLargeItem ? 14.0 : 11.0;
    final titleValueSpacing = isLargeItem ? 0.0 : 4.0;

    return Container(
      margin: includeMargin
          ? EdgeInsets.symmetric(horizontal: 16, vertical: verticalMargin)
          : EdgeInsets.zero,
      padding: EdgeInsets.all(cardPadding),
      decoration: baseDecoration.copyWith(
        borderRadius: BorderRadius.circular(12),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
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
                          fontSize: isLargeItem ? 12.0 : 11.0,
                        ),
                      ),
                      if (sourceName != null) ...[
                        Text(
                          ' · $sourceName',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: context.colors.textSecondary.withValues(
                              alpha: 0.7,
                            ),
                            fontSize: isLargeItem ? 11.0 : 10.0,
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
                    _buildSleepTimeRange(context, theme)
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
    switch (item.type) {
      case FeedItemType.glucose:
        return l10n.bloodGlucose;
      case FeedItemType.exercise:
        return l10n.exercise; // 모든 운동을 "운동"으로 통합
      case FeedItemType.meal:
        return l10n.meal;
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
    switch (item.type) {
      case FeedItemType.glucose:
        return _buildGlucoseValue(context, theme);
      case FeedItemType.exercise:
        return _buildExerciseValue(theme);
      case FeedItemType.meal:
        return _buildMealValue(context, theme);
      case FeedItemType.water:
        return _buildWaterValue(theme);
      case FeedItemType.insulin:
        return _buildInsulinValue(context, theme);
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

  Widget _buildMealValue(BuildContext context, ThemeData theme) {
    final meal = item.mealRecord!;
    final l10n = AppLocalizations.of(context)!;

    // 시간 기반 식사 타입 결정
    final mealTypeKey = meal.getMealTypeKey();
    String mealTypeText;

    switch (mealTypeKey) {
      case 'breakfast':
        mealTypeText = l10n.breakfast;
      case 'lunch':
        mealTypeText = l10n.lunch;
      case 'dinner':
        mealTypeText = l10n.dinner;
      case 'snack':
        mealTypeText = l10n.snack;
      default:
        mealTypeText = l10n.meal;
    }

    final windowMinutes = meal.mealWindowMinutes;
    final windowText = switch (windowMinutes) {
      30 => l10n.mealWindow30min,
      60 => l10n.mealWindow1hour,
      90 => l10n.mealWindow1hour30min,
      120 => l10n.mealWindow2hours,
      _ => '$windowMinutes min',
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          mealTypeText,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          windowText,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }

  Widget _buildWaterValue(ThemeData theme) {
    final water = item.waterRecord!;
    return Text(
      water.formattedAmount(),
      style: theme.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
        fontSize: 16,
      ),
    );
  }

  Widget _buildInsulinValue(BuildContext context, ThemeData theme) {
    final insulin = item.insulinRecord!;
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
    final mindfulness = item.mindfulnessRecord!;
    return Text(
      mindfulness.formattedDuration,
      style: theme.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
        fontSize: 16,
      ),
    );
  }

  Widget _buildStepsValue(ThemeData theme, AppLocalizations l10n) {
    final stepsData = item.stepsData!;
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
      style: theme.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w600,
        fontSize: 16,
      ),
    );
  }

  Widget _buildSleepGroupValue(ThemeData theme) {
    final sleepGroup = item.sleepGroup!;

    return Text(
      sleepGroup.formattedDuration,
      style: theme.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w600,
        fontSize: 16,
      ),
    );
  }

  Widget _buildSleepTimeRange(BuildContext context, ThemeData theme) {
    final sleepGroup = item.sleepGroup!;

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
    final waterGroup = item.waterGroup!;
    return Text(
      waterGroup.formattedAmount(),
      style: theme.textTheme.titleLarge?.copyWith(
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
        item.type == FeedItemType.glucose || item.type == FeedItemType.insulin;

    switch (item.type) {
      case FeedItemType.glucose:
        icon = Icons.water_drop;
        // Always use red for glucose drop icon and background
        color = AppTheme.iconRed;
        backgroundColor = AppTheme.iconRed;
      case FeedItemType.exercise:
        icon = Icons.local_fire_department; // 모든 운동을 불꽃 아이콘으로 통합
        color = AppTheme.iconOrange;
        backgroundColor = color;
      case FeedItemType.meal:
        icon = Icons.restaurant;
        color = Colors.deepPurple[400]!;
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

    // Large items (glucose & insulin): 87.5% size, others: 70% size
    final iconSize = isLargeItem ? 38.5 : 31.0;
    final iconInnerSize = isLargeItem ? 21.0 : 17.0;
    final borderRadius = isLargeItem ? 10.5 : 8.0;

    return Container(
      width: iconSize,
      height: iconSize,
      decoration: BoxDecoration(
        color: backgroundColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      alignment: Alignment.center,
      child: item.type == FeedItemType.exercise
          ? Transform.translate(
              offset: const Offset(0, 2),
              child: Icon(icon, color: color, size: iconInnerSize),
            )
          : Icon(icon, color: color, size: iconInnerSize),
    );
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
      case 'beforeMeal':
        label = l10n.beforeMeal;
      case 'after_meal':
      case 'afterMeal':
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
}
