import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:glu_butler/models/cgm_glucose_group.dart';
import 'package:glu_butler/models/feed_item.dart';
import 'package:glu_butler/models/glucose_range_settings.dart';
import 'package:glu_butler/l10n/app_localizations.dart';
import 'package:glu_butler/core/constants/app_constants.dart';
import 'package:glu_butler/core/theme/app_theme.dart';
import 'package:glu_butler/core/theme/app_colors.dart';
import 'package:glu_butler/core/theme/app_decorations.dart';
import 'package:glu_butler/services/settings_service.dart';

class CgmGroupCard extends StatefulWidget {
  final CgmGlucoseGroup group;
  final List<FeedItem> eventsInRange;

  const CgmGroupCard({
    super.key,
    required this.group,
    this.eventsInRange = const [],
  });

  @override
  State<CgmGroupCard> createState() => _CgmGroupCardState();
}

class _CgmGroupCardState extends State<CgmGroupCard> {
  bool _isExpanded = false;
  int? _touchedBarIndex;
  int? _touchedSpotIndex;
  double? _touchedXValue; // 터치된 X 좌표
  double? _touchedYValue; // 터치된 Y 좌표 (혈당 값)

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
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
        decoration: context.decorations.card.copyWith(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            // Main card content
            Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _buildIcon(theme),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
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
                                    ' · ${group.sourceName}',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: context.colors.textSecondary
                                          .withValues(alpha: 0.7),
                                    ),
                                  ),
                                ],
                                Text(
                                  ' (${group.recordCount}${l10n.times})',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: context.colors.textSecondary
                                        .withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                            // Value row with tag
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: _buildValueWithTag(theme, l10n),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        _formatTimeRange(group),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: context.colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 8,
                  right: 12,
                  child: AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      size: 20,
                      color: context.colors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            // Expanded content (no animation, instant show/hide)
            if (_isExpanded) _buildExpandedContent(theme, l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedContent(ThemeData theme, AppLocalizations l10n) {
    final settings = context.watch<SettingsService>();
    final unit = settings.unit;

    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: context.colors.textSecondary.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: _buildChart(theme, l10n, unit),
      ),
    );
  }

  Widget _buildChart(ThemeData theme, AppLocalizations l10n, String unit) {
    final group = widget.group;
    final settings = context.watch<SettingsService>();
    final glucoseRange = settings.glucoseRange;

    // 6시간 블록의 시작 시간 계산
    final blockStartHour = (group.startTime.hour ~/ 6) * 6;
    final blockStart = DateTime(
      group.startTime.year,
      group.startTime.month,
      group.startTime.day,
      blockStartHour,
    );
    final blockEnd = blockStart.add(const Duration(hours: 6));

    // 모든 혈당 데이터 포인트를 시간 순서대로 정렬
    final sortedRecords = List.from(group.records)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    // 선 그래프 데이터 포인트를 색상별로 그룹화
    final lineSegments = _createColoredLineSegments(
      sortedRecords,
      blockStart,
      glucoseRange,
    );

    // 최소/최대 혈당 값 계산 (차트 범위 설정)
    // 기본값은 70, 데이터 최소값이 더 낮으면 10 단위로 내림
    double minGlucose = 70.0;
    if (group.minValue < 70.0) {
      minGlucose = (group.minValue / 10).floor() * 10.0;
    }
    final maxGlucose = (glucoseRange.veryHigh + 20).toDouble();

    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: 6,
          minY: minGlucose,
          maxY: maxGlucose,
          lineBarsData: lineSegments,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 40,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: context.colors.textSecondary.withValues(alpha: 0.1),
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 2,
                getTitlesWidget: (value, meta) {
                  if (value < 0 || value > 6) return const SizedBox.shrink();
                  final hour = blockStartHour + value.toInt();
                  if (hour > 23) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      hour.toString(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: context.colors.textSecondary,
                      ),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                interval: 40,
                getTitlesWidget: (value, meta) {
                  // 최소값은 표시하지 않음
                  if (value == minGlucose) {
                    return const SizedBox.shrink();
                  }
                  final isMmol = unit == AppConstants.unitMmolL;
                  final displayValue = isMmol
                      ? (value / AppConstants.mgDlToMmolL).toStringAsFixed(1)
                      : value.toInt().toString();
                  return Text(
                    displayValue,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: context.colors.textSecondary,
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineTouchData: LineTouchData(
            enabled: true,
            handleBuiltInTouches: false, // 여러 개 동시 선택 방지
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (touchedSpot) => Colors.black87,
              tooltipRoundedRadius: 8,
              tooltipPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              getTooltipItems: (List<LineBarSpot> touchedSpots) {
                if (touchedSpots.isEmpty) return [];

                // 첫 번째 spot만 사용 (가장 가까운 것)
                final spot = touchedSpots.first;
                final isMmol = unit == AppConstants.unitMmolL;
                final displayValue = isMmol
                    ? (spot.y / AppConstants.mgDlToMmolL).toStringAsFixed(1)
                    : spot.y.toStringAsFixed(0);

                return [
                  LineTooltipItem(
                    '$displayValue $unit',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ];
              },
            ),
            touchCallback: (FlTouchEvent event, LineTouchResponse? response) {
              setState(() {
                if (response?.lineBarSpots?.isNotEmpty ?? false) {
                  final spot = response!.lineBarSpots!.first;
                  _touchedBarIndex = spot.barIndex;
                  _touchedSpotIndex = spot.spotIndex;
                  _touchedXValue = spot.x;
                  _touchedYValue = spot.y;
                } else {
                  _touchedBarIndex = null;
                  _touchedSpotIndex = null;
                  _touchedXValue = null;
                  _touchedYValue = null;
                }
              });
            },
            getTouchLineEnd: (barData, spotIndex) => double.infinity,
            getTouchedSpotIndicator:
                (LineChartBarData barData, List<int> spotIndexes) {
                  if (spotIndexes.isEmpty) return [];

                  return [
                    TouchedSpotIndicatorData(
                      FlLine(
                        color: context.colors.textPrimary.withValues(
                          alpha: 0.8,
                        ),
                        strokeWidth: 2,
                      ),
                      FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 6,
                            color: context.colors.textPrimary,
                            strokeWidth: 2,
                            strokeColor: barData.color ?? Colors.blue,
                          );
                        },
                      ),
                    ),
                  ];
                },
          ),
          showingTooltipIndicators:
              _touchedBarIndex != null && _touchedSpotIndex != null
              ? [
                  ShowingTooltipIndicators([
                    LineBarSpot(
                      lineSegments[_touchedBarIndex!],
                      _touchedBarIndex!,
                      lineSegments[_touchedBarIndex!].spots[_touchedSpotIndex!],
                    ),
                  ]),
                ]
              : [],
          extraLinesData: ExtraLinesData(
            verticalLines: [
              ..._buildEventLines(blockStart, blockEnd),
              if (_touchedXValue != null) _buildTouchLine(),
            ],
          ),
        ),
      ),
    );
  }

  /// 혈당 값에 따라 색상이 다른 선 세그먼트 생성
  List<LineChartBarData> _createColoredLineSegments(
    List<dynamic> sortedRecords,
    DateTime blockStart,
    GlucoseRangeSettings glucoseRange,
  ) {
    final segments = <LineChartBarData>[];

    for (int i = 0; i < sortedRecords.length; i++) {
      final record = sortedRecords[i];
      final hoursSinceStart =
          record.timestamp.difference(blockStart).inMinutes / 60.0;

      // 현재 포인트와 다음 포인트로 세그먼트 생성
      if (i < sortedRecords.length - 1) {
        final nextRecord = sortedRecords[i + 1];
        final nextHoursSinceStart =
            nextRecord.timestamp.difference(blockStart).inMinutes / 60.0;

        // 현재 혈당 값에 따른 색상 결정
        final color = _getLineColor(record.value, glucoseRange);

        segments.add(
          LineChartBarData(
            spots: [
              FlSpot(hoursSinceStart, record.value),
              FlSpot(nextHoursSinceStart, nextRecord.value),
            ],
            isCurved: true,
            curveSmoothness: 0.3,
            color: color,
            barWidth: 3,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
          ),
        );
      }
    }

    return segments;
  }

  /// 혈당 값에 따른 선 색상 결정
  Color _getLineColor(double value, GlucoseRangeSettings glucoseRange) {
    if (value < glucoseRange.veryLow) {
      return AppTheme.iconRed;
    } else if (value < glucoseRange.low) {
      return AppTheme.iconOrange;
    } else if (value <= glucoseRange.high) {
      return AppTheme.glucoseNormal;
    } else if (value <= glucoseRange.veryHigh) {
      return AppTheme.iconOrange;
    } else {
      return AppTheme.iconRed;
    }
  }

  /// 이벤트들을 반투명 세로 라인으로 변환
  List<VerticalLine> _buildEventLines(DateTime blockStart, DateTime blockEnd) {
    final eventLines = <VerticalLine>[];
    final blockStartHour = blockStart.hour;

    for (final event in widget.eventsInRange) {
      if (event.timestamp.isAfter(blockStart) &&
          event.timestamp.isBefore(blockEnd)) {
        // 이벤트의 시간(hour)을 블록 내 인덱스로 변환
        final eventHour = event.timestamp.hour;
        final hourIndex = eventHour - blockStartHour;

        // 분 단위 오프셋 추가 (0.0-1.0 범위)
        final minuteOffset = event.timestamp.minute / 60.0;
        final xPosition = hourIndex + minuteOffset;

        eventLines.add(
          VerticalLine(
            x: xPosition,
            color: _getEventColor(event.type).withValues(alpha: 0.3),
            strokeWidth: 2,
            dashArray: [4, 4],
            label: VerticalLineLabel(
              show: true,
              alignment: Alignment.topCenter,
              labelResolver: (line) => _getEventIcon(event.type),
              style: TextStyle(color: _getEventColor(event.type), fontSize: 16),
            ),
          ),
        );
      }
    }

    return eventLines;
  }

  /// 이벤트 타입에 따른 아이콘 반환
  String _getEventIcon(FeedItemType type) {
    switch (type) {
      case FeedItemType.meal:
        return '🍽️';
      case FeedItemType.exercise:
        return '🏃';
      case FeedItemType.insulin:
        return '💉';
      case FeedItemType.glucose:
        return '🩸';
      default:
        return '•';
    }
  }

  /// 터치된 위치에 세로선 생성
  VerticalLine _buildTouchLine() {
    return VerticalLine(
      x: _touchedXValue!,
      color: context.colors.textPrimary.withValues(alpha: 0.8),
      strokeWidth: 1,
    );
  }

  /// 이벤트 타입에 따른 색상 반환
  Color _getEventColor(FeedItemType type) {
    switch (type) {
      case FeedItemType.meal:
        return AppTheme.iconOrange;
      case FeedItemType.exercise:
        return AppTheme.glucoseNormal;
      case FeedItemType.insulin:
        return AppTheme.iconBlue;
      case FeedItemType.glucose:
        return AppTheme.iconRed;
      default:
        return Colors.grey;
    }
  }

  String _getTitle(AppLocalizations l10n) {
    return l10n.bloodGlucose;
  }

  String _formatTimeRange(CgmGlucoseGroup group) {
    final startTime =
        '${group.startTime.hour.toString().padLeft(2, '0')}:${group.startTime.minute.toString().padLeft(2, '0')}';
    final endTime =
        '${group.endTime.hour.toString().padLeft(2, '0')}:${group.endTime.minute.toString().padLeft(2, '0')}';
    return '$startTime~$endTime';
  }

  Widget _buildValueWithTag(ThemeData theme, AppLocalizations l10n) {
    final group = widget.group;
    final settings = context.watch<SettingsService>();
    final unit = settings.unit;
    final glucoseRange = settings.glucoseRange;
    final status = _getGroupStatus(glucoseRange);

    String tagText;
    Color tagColor;

    switch (status) {
      case 'veryLow':
        tagText = l10n.veryLow;
        tagColor = AppTheme.glucoseVeryLow;
        break;
      case 'low':
        tagText = l10n.low;
        tagColor = AppTheme.glucoseLow;
        break;
      case 'high':
        tagText = l10n.high;
        tagColor = AppTheme.iconOrange;
        break;
      case 'caution':
        tagText = l10n.warning;
        tagColor = AppTheme.iconOrange;
        break;
      case 'veryHigh':
        tagText = l10n.veryHigh;
        tagColor = AppTheme.glucoseVeryHigh;
        break;
      case 'normal':
      default:
        tagText = l10n.normal;
        tagColor = AppTheme.glucoseNormal;
        break;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          group.getRangeString(unit),
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
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: tagColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            tagText,
            style: theme.textTheme.labelSmall?.copyWith(
              color: tagColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  /// 그룹 내 모든 데이터를 분석하여 가장 심각한 상태 반환
  /// 차트 색상 로직과 동일하게 처리
  String _getGroupStatus(GlucoseRangeSettings glucoseRange) {
    final group = widget.group;
    bool hasVeryLow = false;
    bool hasLow = false;
    bool hasCaution = false;
    bool hasVeryHigh = false;

    for (final record in group.records) {
      final value = record.value;

      if (value < glucoseRange.veryLow) {
        hasVeryLow = true;
      } else if (value < glucoseRange.low) {
        hasLow = true;
      } else if (value > glucoseRange.veryHigh) {
        hasVeryHigh = true;
      } else if (value > glucoseRange.high) {
        // high 초과 ~ veryHigh 이하 = 주의
        hasCaution = true;
      }
      // value <= high 이면 정상 범위
    }

    // 우선순위: veryLow > low > veryHigh > caution > normal
    if (hasVeryLow) return 'veryLow';
    if (hasLow) return 'low';
    if (hasVeryHigh) return 'veryHigh';
    if (hasCaution) return 'caution';
    return 'normal';
  }

  Widget _buildIcon(ThemeData theme) {
    final color = _getStatusColor();
    const icon = Icons.show_chart; // 차트 아이콘

    return Container(
      width: 38.5,
      height: 38.5,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10.5),
      ),
      child: Icon(icon, color: color, size: 21),
    );
  }

  Color _getStatusColor() {
    // 메인 빨강색으로 고정
    return AppTheme.iconRed;
  }
}
