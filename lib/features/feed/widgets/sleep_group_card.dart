import 'package:flutter/material.dart';
import 'package:glu_butler/models/sleep_group.dart';
import 'package:glu_butler/l10n/app_localizations.dart';
import 'package:glu_butler/core/theme/app_theme.dart';
import 'package:glu_butler/core/theme/app_decorations.dart';

/// Sleep 그룹 카드 위젯
/// 하루의 수면 데이터를 하나로 묶어서 표시
class SleepGroupCard extends StatelessWidget {
  final SleepGroup group;

  const SleepGroupCard({super.key, required this.group});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: context.decorations.card.copyWith(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(11),
        child: Row(
          children: [
            // Icon
            Container(
              width: 31,
              height: 31,
              decoration: BoxDecoration(
                color: AppTheme.iconIndigo.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.bedtime,
                color: AppTheme.iconIndigo,
                size: 17,
              ),
            ),
            const SizedBox(width: 11),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title
                  Text(
                    l10n.sleep,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                      fontSize: 11,
                    ),
                  ),

                  // Duration
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      group.formattedDuration,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Time range
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${_formatTime(group.startTime)} - ${_formatTime(group.endTime)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }
}
