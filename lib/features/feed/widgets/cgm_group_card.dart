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

    // 수동 입력 혈당 이벤트를 점으로 표시하기 위한 데이터
    final manualGlucoseSpots = <FlSpot>[];
    for (final event in widget.eventsInRange) {
      if (event.type == FeedItemType.glucose &&
          event.timestamp.isAfter(blockStart) &&
          event.timestamp.isBefore(blockEnd)) {
        final glucoseRecord = event.glucoseRecord;
        if (glucoseRecord != null) {
          final eventHour = event.timestamp.hour;
          final hourIndex = eventHour - blockStartHour;
          final minuteOffset = event.timestamp.minute / 60.0;
          final xPosition = hourIndex + minuteOffset;
          manualGlucoseSpots.add(FlSpot(xPosition, glucoseRecord.value));
        }
      }
    }

    // 최소/최대 혈당 값 계산 (차트 범위 설정)
    // 기본값은 70, 데이터 최소값이 더 낮으면 10 단위로 내림
    double minGlucose = 70.0;
    if (group.minValue < 70.0) {
      minGlucose = (group.minValue / 10).floor() * 10.0;
    }
    final maxGlucose = (glucoseRange.veryHigh + 20).toDouble();

    return SizedBox(
      height: 200,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              // 수동 혈당 레이블을 먼저 배치 (아래에)
              ..._buildManualGlucoseLabelsPositioned(
                blockStart,
                blockEnd,
                unit,
                minGlucose,
                maxGlucose,
                constraints,
              ),
              // LineChart를 나중에 배치 (위에, tooltip이 레이블 위에 표시됨)
              LineChart(
                LineChartData(
          minX: 0,
          maxX: 6,
          minY: minGlucose,
          maxY: maxGlucose,
          lineBarsData: [
            ...lineSegments,
            // 수동 입력 혈당을 점으로 표시
            if (manualGlucoseSpots.isNotEmpty)
              LineChartBarData(
                spots: manualGlucoseSpots,
                isCurved: false,
                color: Colors.transparent,
                barWidth: 0,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) {
                    return FlDotCirclePainter(
                      radius: 3, // 기본보다 50% 작게
                      color: AppTheme.iconRed, // 메인 빨강색
                      strokeWidth: 0,
                    );
                  },
                ),
                belowBarData: BarAreaData(show: false),
              ),
          ],
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
              getTooltipColor: (touchedSpot) {
                final isDarkMode = Theme.of(context).brightness == Brightness.dark;
                if (isDarkMode) {
                  return context.colors.card.withValues(alpha: 1.0);
                }
                return context.colors.card.withValues(alpha: 0.9);
              },
              tooltipRoundedRadius: 4,
              tooltipPadding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
              tooltipBorder: BorderSide(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey.withValues(alpha: 0.5)
                    : context.colors.divider,
                width: Theme.of(context).brightness == Brightness.dark ? 1.5 : 1.0,
              ),
              getTooltipItems: (List<LineBarSpot> touchedSpots) {
                if (touchedSpots.isEmpty) return [];

                // 첫 번째 spot만 사용 (가장 가까운 것)
                final spot = touchedSpots.first;
                final isMmol = unit == AppConstants.unitMmolL;
                final displayValue = isMmol
                    ? (spot.y / AppConstants.mgDlToMmolL).toStringAsFixed(1)
                    : spot.y.toStringAsFixed(0);

                // X 좌표에서 시간 계산
                final hoursSinceStart = spot.x;
                final totalMinutes = (hoursSinceStart * 60).round();
                final hours = blockStartHour + (totalMinutes ~/ 60);
                final minutes = totalMinutes % 60;
                final timeString = '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';

                // 혈당 값에 따른 색상 결정
                final glucoseColor = _getLineColor(spot.y, glucoseRange);

                return [
                  LineTooltipItem(
                    '$timeString\n',
                    TextStyle(
                      color: context.colors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                    children: [
                      TextSpan(
                        text: '$displayValue $unit',
                        style: TextStyle(
                          color: glucoseColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ];
              },
            ),
            touchCallback: (FlTouchEvent event, LineTouchResponse? response) {
              setState(() {
                if (response?.lineBarSpots?.isNotEmpty ?? false) {
                  final spot = response!.lineBarSpots!.first;

                  // 수동 혈당 점(마지막 barIndex)은 터치 무시
                  // lineSegments 다음에 수동 혈당 LineChartBarData가 추가되므로
                  final totalBars = lineSegments.length + (manualGlucoseSpots.isNotEmpty ? 1 : 0);
                  final isManualGlucoseBar = manualGlucoseSpots.isNotEmpty &&
                                              spot.barIndex == totalBars - 1;

                  if (isManualGlucoseBar) {
                    // 수동 혈당 점은 터치 무시
                    _touchedBarIndex = null;
                    _touchedSpotIndex = null;
                    _touchedXValue = null;
                    _touchedYValue = null;
                  } else {
                    _touchedBarIndex = spot.barIndex;
                    _touchedSpotIndex = spot.spotIndex;
                    _touchedXValue = spot.x;
                    _touchedYValue = spot.y;
                  }
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
              _touchedBarIndex != null &&
              _touchedSpotIndex != null &&
              _touchedBarIndex! < lineSegments.length  // 범위 체크 추가
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
          rangeAnnotations: RangeAnnotations(
            verticalRangeAnnotations: _buildEventRanges(blockStart, blockEnd),
          ),
          extraLinesData: ExtraLinesData(
            verticalLines: [
              ..._buildEventLabels(blockStart, blockEnd, l10n),
              if (_touchedXValue != null) _buildTouchLine(),
            ],
          ),
                ),
              ),
            ],
          );
        },
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

  /// 이벤트들을 배경 영역으로 변환
  List<VerticalRangeAnnotation> _buildEventRanges(
    DateTime blockStart,
    DateTime blockEnd,
  ) {
    final eventRanges = <VerticalRangeAnnotation>[];
    final blockStartHour = blockStart.hour;

    for (final event in widget.eventsInRange) {
      // 수동 혈당은 점으로 표시하므로 배경에서 제외
      if (event.type == FeedItemType.glucose) continue;

      if (event.timestamp.isAfter(blockStart) &&
          event.timestamp.isBefore(blockEnd)) {
        // 이벤트의 시간(hour)을 블록 내 인덱스로 변환
        final eventHour = event.timestamp.hour;
        final hourIndex = eventHour - blockStartHour;

        // 분 단위 오프셋 추가 (0.0-1.0 범위)
        final minuteOffset = event.timestamp.minute / 60.0;
        final xPosition = hourIndex + minuteOffset;

        // 이벤트 지속 시간 계산
        final duration = _getEventDuration(event);
        final halfWidth = (duration / 2) * 0.5; // 양옆으로 퍼지는 범위

        eventRanges.add(
          VerticalRangeAnnotation(
            x1: (xPosition - halfWidth).clamp(0.0, 6.0),
            x2: (xPosition + halfWidth).clamp(0.0, 6.0),
            color: _getEventColor(event.type).withValues(alpha: 0.2),
          ),
        );
      }
    }

    return eventRanges;
  }

  /// 이벤트 레이블만 표시하는 투명한 수직선
  List<VerticalLine> _buildEventLabels(
    DateTime blockStart,
    DateTime blockEnd,
    AppLocalizations l10n,
  ) {
    final eventLabels = <VerticalLine>[];
    final blockStartHour = blockStart.hour;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final labelColor = isDarkMode ? context.colors.textPrimary : Colors.black;

    for (final event in widget.eventsInRange) {
      // 수동 혈당은 점으로 표시하므로 레이블에서 제외
      if (event.type == FeedItemType.glucose) continue;

      if (event.timestamp.isAfter(blockStart) &&
          event.timestamp.isBefore(blockEnd)) {
        // 이벤트의 시간(hour)을 블록 내 인덱스로 변환
        final eventHour = event.timestamp.hour;
        final hourIndex = eventHour - blockStartHour;

        // 분 단위 오프셋 추가 (0.0-1.0 범위)
        final minuteOffset = event.timestamp.minute / 60.0;
        final xPosition = hourIndex + minuteOffset;

        eventLabels.add(
          VerticalLine(
            x: xPosition,
            color: Colors.transparent, // 투명한 선
            strokeWidth: 0,
            label: VerticalLineLabel(
              show: true,
              alignment: Alignment.topCenter,
              padding: const EdgeInsets.only(bottom: 4),
              labelResolver: (line) => ' ${_getEventLabel(event.type, l10n)} ',
              style: TextStyle(
                color: labelColor,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                backgroundColor: context.colors.card.withValues(alpha: 0.8),
              ),
            ),
          ),
        );
      }
    }

    return eventLabels;
  }

  /// 수동 혈당 측정값 레이블을 Positioned로 표시
  List<Widget> _buildManualGlucoseLabelsPositioned(
    DateTime blockStart,
    DateTime blockEnd,
    String unit,
    double minY,
    double maxY,
    BoxConstraints constraints,
  ) {
    final labels = <Widget>[];
    final blockStartHour = blockStart.hour;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final labelColor = isDarkMode ? context.colors.textPrimary : Colors.black;

    // 차트 크기
    final chartHeight = constraints.maxHeight;
    final chartWidth = constraints.maxWidth;

    // 차트 영역 패딩
    const leftPadding = 40.0; // leftTitles reservedSize
    const rightPadding = 10.0;
    const topPadding = 10.0; // 상단 여백
    const bottomPadding = 24.0; // bottomTitles reservedSize

    for (final event in widget.eventsInRange) {
      if (event.type == FeedItemType.glucose &&
          event.timestamp.isAfter(blockStart) &&
          event.timestamp.isBefore(blockEnd)) {
        final glucoseRecord = event.glucoseRecord;
        if (glucoseRecord != null) {
          // 이벤트의 시간(hour)을 블록 내 인덱스로 변환
          final eventHour = event.timestamp.hour;
          final hourIndex = eventHour - blockStartHour;
          final minuteOffset = event.timestamp.minute / 60.0;
          final xPosition = hourIndex + minuteOffset; // 0~6 범위

          // 혈당 값 표시
          final isMmol = unit == AppConstants.unitMmolL;
          final displayValue = isMmol
              ? (glucoseRecord.value / AppConstants.mgDlToMmolL).toStringAsFixed(1)
              : glucoseRecord.value.toStringAsFixed(0);

          // X 좌표 계산: 0~6 범위를 차트 너비로 변환
          final xRatio = xPosition / 6.0;
          final chartAreaWidth = chartWidth - leftPadding - rightPadding;
          final pointX = leftPadding + (xRatio * chartAreaWidth);

          // Y 좌표 계산: minY~maxY 범위를 차트 높이로 변환 (상하 반전)
          final chartAreaHeight = chartHeight - topPadding - bottomPadding;
          final yRatio = (maxY - glucoseRecord.value) / (maxY - minY);
          final pointY = topPadding + (yRatio * chartAreaHeight);

          // 차트 중간을 기준으로 왼쪽/오른쪽 선택
          final isLeftSide = xPosition < 3.0;

          labels.add(
            Positioned(
              top: pointY - 12, // 현재 높이에서 1만큼 아래로
              left: isLeftSide ? pointX - 3 : null, // 점에서 3px 왼쪽으로
              right: isLeftSide ? null : chartWidth - pointX - 3, // 점에서 3px 왼쪽으로
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: context.colors.card.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '$displayValue$unit',
                  style: TextStyle(
                    color: labelColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        }
      }
    }

    return labels;
  }

  /// 이벤트 지속 시간 계산 (시간 단위)
  double _getEventDuration(dynamic event) {
    switch (event.type) {
      case FeedItemType.meal:
        return 0.5; // 식사: 30분
      case FeedItemType.exercise:
        final exerciseData = event.exerciseRecord;
        if (exerciseData != null) {
          return exerciseData.durationMinutes / 60.0;
        }
        return 0.5; // 기본값: 30분
      case FeedItemType.insulin:
      case FeedItemType.glucose:
        return 0.05; // 순간 이벤트: 3분
      default:
        return 0.17; // 기본값: 10분
    }
  }

  /// 이벤트 타입에 따른 텍스트 반환 (국제화)
  String _getEventLabel(FeedItemType type, AppLocalizations l10n) {
    switch (type) {
      case FeedItemType.meal:
        return l10n.meal;
      case FeedItemType.exercise:
        return l10n.exercise;
      case FeedItemType.insulin:
        return l10n.insulin;
      case FeedItemType.glucose:
        return l10n.bloodGlucose;
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
        return Colors.deepPurple[400]!;
      case FeedItemType.exercise:
        return AppTheme.iconOrange;
      case FeedItemType.insulin:
        return AppTheme.iconPurple;
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
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: tagColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            tagText,
            style: TextStyle(
              color: tagColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
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
