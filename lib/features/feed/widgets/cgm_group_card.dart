import 'package:flutter/material.dart';
import 'package:jiffy/jiffy.dart';
import 'package:glu_butler/models/cgm_glucose_group.dart';
import 'package:glu_butler/models/glucose_record.dart';
import 'package:glu_butler/l10n/app_localizations.dart';
import 'package:glu_butler/core/theme/app_theme.dart';
import 'package:glu_butler/core/theme/app_colors.dart';

class CgmGroupCard extends StatefulWidget {
  final CgmGlucoseGroup group;

  const CgmGroupCard({super.key, required this.group});

  @override
  State<CgmGroupCard> createState() => _CgmGroupCardState();
}

class _CgmGroupCardState extends State<CgmGroupCard>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final group = widget.group;

    return GestureDetector(
      onTap: _toggleExpanded,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
        child: Column(
          children: [
            // Main card content
            Padding(
              padding: const EdgeInsets.all(16),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildIcon(theme),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Title row
                          Row(
                            children: [
                              Text(
                                _getTitle(l10n),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: context.colors.textSecondary,
                                ),
                              ),
                              if (group.sourceName != null) ...[
                                Text(
                                  ' ${group.sourceName} (${group.recordCount}회)',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: context.colors.textSecondary
                                        .withValues(alpha: 0.7),
                                  ),
                                ),
                              ] else ...[
                                Text(
                                  ' (${group.recordCount}회)',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: context.colors.textSecondary
                                        .withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          // Value row
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: _buildValue(theme),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        AnimatedRotation(
                          turns: _isExpanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            Icons.keyboard_arrow_down,
                            size: 20,
                            color: context.colors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          group.timeRangeString,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: context.colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Expanded content
            SizeTransition(
              sizeFactor: _expandAnimation,
              child: _buildExpandedContent(theme, l10n),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedContent(ThemeData theme, AppLocalizations l10n) {
    final group = widget.group;
    // Sort records by time (newest first)
    final sortedRecords = List<GlucoseRecord>.from(group.records)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: context.colors.textSecondary.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Column(
        children: [
          for (int i = 0; i < sortedRecords.length; i++)
            _buildRecordRow(sortedRecords[i], theme, i == sortedRecords.length - 1),
        ],
      ),
    );
  }

  Widget _buildRecordRow(GlucoseRecord record, ThemeData theme, bool isLast) {
    final time = Jiffy.parseFromDateTime(record.timestamp).format(pattern: 'HH:mm');
    final color = _getGlucoseColor(record.status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(
                  color: context.colors.textSecondary.withValues(alpha: 0.05),
                ),
              ),
      ),
      child: Row(
        children: [
          // Indent with line indicator
          SizedBox(
            width: 44,
            child: Row(
              children: [
                const SizedBox(width: 20),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Value
          Text(
            '${record.value.toStringAsFixed(0)} ${record.unit}',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          // Status indicator
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const Spacer(),
          // Time
          Text(
            time,
            style: theme.textTheme.bodySmall?.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Color _getGlucoseColor(String status) {
    switch (status) {
      case 'low':
        return Colors.orange;
      case 'high':
        return Colors.red;
      default:
        return AppTheme.primaryColor;
    }
  }

  String _getTitle(AppLocalizations l10n) {
    final group = widget.group;
    switch (group.groupType) {
      case CgmGroupType.fluctuation:
        return '${l10n.bloodGlucose} ~';
      case CgmGroupType.baseline:
        return l10n.bloodGlucose;
    }
  }

  Widget _buildValue(ThemeData theme) {
    final group = widget.group;
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Text(
          '${group.rangeString} ${group.unit}',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 8),
        _buildGroupTypeChip(theme, l10n),
      ],
    );
  }

  Widget _buildIcon(ThemeData theme) {
    final group = widget.group;
    final color = _getStatusColor();
    IconData icon;

    switch (group.groupType) {
      case CgmGroupType.fluctuation:
        icon = Icons.trending_up;
      case CgmGroupType.baseline:
        icon = Icons.trending_flat;
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

  Color _getStatusColor() {
    final group = widget.group;
    // groupType 기준으로 색상 결정 (fluctuation: 주황색, baseline: 녹색)
    return group.groupType == CgmGroupType.fluctuation
        ? Colors.orange
        : AppTheme.primaryColor;
  }

  Widget _buildGroupTypeChip(ThemeData theme, AppLocalizations l10n) {
    final group = widget.group;
    final isFluctuation = group.groupType == CgmGroupType.fluctuation;
    final color = isFluctuation ? Colors.orange : AppTheme.primaryColor;
    final label = isFluctuation ? l10n.cgmFluctuation : l10n.cgmBaseline;

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
