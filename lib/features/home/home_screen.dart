import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';

import 'package:glu_butler/l10n/app_localizations.dart';
import 'package:glu_butler/core/navigation/main_screen.dart';
import 'package:glu_butler/core/theme/app_theme.dart';
import 'package:glu_butler/core/theme/app_text_styles.dart';
import 'package:glu_butler/core/theme/app_colors.dart';
import 'package:glu_butler/core/theme/app_decorations.dart';
import 'package:glu_butler/core/widgets/large_title_scroll_view.dart';
import 'package:glu_butler/core/widgets/settings_icon_button.dart';
import 'package:glu_butler/core/widgets/modals/date_picker_modal.dart';
import 'package:glu_butler/repositories/glucose_repository.dart';
import 'package:glu_butler/models/glucose_record.dart';
import 'package:glu_butler/services/settings_service.dart';

/// 홈 대시보드 화면
///
/// 사용자의 오늘 혈당 현황을 한눈에 보여주는 대시보드입니다.
///
/// ## 구성 요소
/// - 오늘의 혈당 점수 (0-100점)
/// - 시간대별 혈당 차트 (막대 + 선 그래프)
/// - 일일 통계 (평균, 최저, 최고)
/// - 혈당 범위 분포 파이 차트
/// - 리포트 보기 버튼
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _glucoseRepository = GlucoseRepository();

  List<GlucoseRecord> _todayRecords = [];
  bool _isLoading = true;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadTodayData();
  }

  Future<void> _loadTodayData() async {
    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      // GlucoseRepository.fetch() automatically handles:
      // - Fetches from local DB
      // - If HealthKit permissions exist, also fetches from HealthKit and merges
      final records = await _glucoseRepository.fetch(
        startDate: startOfDay,
        endDate: endOfDay,
      );

      setState(() {
        _todayRecords = records;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('[HomeScreen] Error loading data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadSelectedDateData() async {
    setState(() => _isLoading = true);

    try {
      final startOfDay = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
      );
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final records = await _glucoseRepository.fetch(
        startDate: startOfDay,
        endDate: endOfDay,
      );

      setState(() {
        _todayRecords = records;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('[HomeScreen] Error loading data: $e');
      setState(() => _isLoading = false);
    }
  }

  String _formatSelectedDate() {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );

    if (selected == today) {
      return l10n.today;
    } else if (selected == today.subtract(const Duration(days: 1))) {
      return l10n.yesterday;
    } else {
      return '${_selectedDate.month}/${_selectedDate.day}';
    }
  }

  int get _todayScore {
    if (_todayRecords.isEmpty) return 0;

    int inRange = 0;
    for (final record in _todayRecords) {
      final value = record.valueIn('mg/dL');
      if (value >= 80 && value <= 160) {
        inRange++;
      }
    }

    return ((inRange / _todayRecords.length) * 100).round();
  }

  double get _averageGlucose {
    if (_todayRecords.isEmpty) return 0;
    final values = _todayRecords.map((e) => e.valueIn('mg/dL')).toList();
    return values.reduce((a, b) => a + b) / values.length;
  }

  double get _minGlucose {
    if (_todayRecords.isEmpty) return 0;
    return _todayRecords.map((e) => e.valueIn('mg/dL')).reduce(math.min);
  }

  double get _maxGlucose {
    if (_todayRecords.isEmpty) return 0;
    return _todayRecords.map((e) => e.valueIn('mg/dL')).reduce(math.max);
  }

  // 범위별 비율 계산
  Map<String, int> get _rangeDistribution {
    int low = 0, normal = 0, high = 0;
    for (final record in _todayRecords) {
      final value = record.valueIn('mg/dL');
      if (value < 70) {
        low++;
      } else if (value <= 140) {
        normal++;
      } else {
        high++;
      }
    }
    return {'low': low, 'normal': normal, 'high': high};
  }

  Future<void> _onRefresh() async {
    await _loadTodayData();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return LargeTitleScrollView(
      title: l10n.today,
      onRefresh: _onRefresh,
      trailing: const SettingsIconButton(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // 오늘의 점수
              _buildScoreCard(context, l10n),
              const SizedBox(height: 16),

              // 시간대별 혈당 차트
              _buildChartCard(context, l10n),
              const SizedBox(height: 16),

              // 일일 통계
              _buildStatsCard(context, l10n),
              const SizedBox(height: 16),

              // 범위 분포 파이 차트
              _buildDistributionCard(context, l10n),
              const SizedBox(height: 16),

              // 리포트 보기 버튼
              _buildReportButton(context, l10n),
              const SizedBox(height: 100), // 플로팅 탭바 높이만큼 여백
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildScoreCard(BuildContext context, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: context.decorations.card,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            l10n.yourToday,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w500,
              color: context.colors.textPrimary,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '$_todayScore',
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            l10n.points,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w500,
              color: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard(BuildContext context, AppLocalizations l10n) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final dateButtonColor = isDarkMode
        ? context.colors.textPrimary
        : AppTheme.primaryColor;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: context.decorations.card,
      child: Column(
        children: [
          // 타이틀과 날짜 선택 버튼
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.todaysGlucose,
                style: context.textStyles.tileTitle.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              GestureDetector(
                onTap: () async {
                  // 모달을 열기 전에 탭바 숨김
                  MainScreen.globalKey.currentState?.setTabBarVisibility(false);

                  final pickedDate = await DatePickerModal.show(
                    context,
                    initialDate: _selectedDate,
                  );

                  // 모달이 닫히면 탭바 다시 보임
                  MainScreen.globalKey.currentState?.setTabBarVisibility(true);

                  if (pickedDate != null && pickedDate != _selectedDate) {
                    setState(() {
                      _selectedDate = pickedDate;
                    });
                    _loadSelectedDateData();
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: dateButtonColor.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: dateButtonColor.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: dateButtonColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _formatSelectedDate(),
                        style: context.textStyles.caption.copyWith(
                          color: dateButtonColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 차트
          SizedBox(height: 200, child: _buildGlucoseChart(context, l10n)),
        ],
      ),
    );
  }

  Widget _buildGlucoseChart(BuildContext context, AppLocalizations l10n) {
    if (_todayRecords.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.insert_chart_outlined,
              size: 48,
              color: context.colors.textSecondary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.noData,
              style: context.textStyles.tileTitle.copyWith(
                color: context.colors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    // 시간별로 데이터 그룹화 (0~23시)
    final hourlyData = <int, List<double>>{};
    for (final record in _todayRecords) {
      final hour = record.timestamp.hour;
      final value = record.valueIn('mg/dL');
      hourlyData.putIfAbsent(hour, () => []).add(value);
    }

    // 각 시간대의 평균값 계산
    final hourlyAverage = <int, double>{};
    hourlyData.forEach((hour, values) {
      hourlyAverage[hour] = values.reduce((a, b) => a + b) / values.length;
    });

    // 설정에서 목표 혈당 범위 가져오기
    final settings = context.watch<SettingsService>();
    final glucoseRange = settings.glucoseRange;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final averageLineColor = isDarkMode
        ? context.colors.textPrimary
        : Colors.black;

    // Y축 범위 계산: 실제 데이터와 설정값 중 더 큰 범위 사용
    final maxValue = _todayRecords
        .map((e) => e.valueIn('mg/dL'))
        .reduce(math.max);
    final minValue = _todayRecords
        .map((e) => e.valueIn('mg/dL'))
        .reduce(math.min);

    final chartMaxY = math.max(glucoseRange.veryHigh, maxValue + 20).toDouble();
    final chartMinY = math.min(glucoseRange.veryLow, minValue - 20).toDouble();

    // 하루 전체 평균 혈당
    final averageGlucose = _averageGlucose;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: chartMaxY,
        minY: chartMinY,
        // 평균 혈당 수평선 추가
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            HorizontalLine(
              y: averageGlucose,
              color: averageLineColor.withValues(alpha: 0.4),
              strokeWidth: 2,
              dashArray: [8, 4], // 점선 패턴
              label: HorizontalLineLabel(
                show: true,
                alignment: Alignment.topRight,
                padding: const EdgeInsets.only(right: 8, bottom: 4),
                style: TextStyle(
                  color: averageLineColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
                labelResolver: (line) => '${l10n.average} ${averageGlucose.toInt()}',
              ),
            ),
          ],
        ),
        // 목표 범위 배경색
        rangeAnnotations: RangeAnnotations(
          horizontalRangeAnnotations: [
            HorizontalRangeAnnotation(
              y1: glucoseRange.targetLow,
              y2: glucoseRange.targetHigh,
              color: Colors.green.withValues(alpha: 0.08),
            ),
          ],
        ),
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            tooltipPadding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
            getTooltipColor: (group) {
              if (isDarkMode) {
                return context.colors.card.withValues(alpha: 1.0);
              }
              return context.colors.card.withValues(alpha: 0.9);
            },
            tooltipBorder: BorderSide(
              color: isDarkMode
                  ? Colors.grey.withValues(alpha: 0.5)
                  : context.colors.divider,
              width: isDarkMode ? 1.5 : 1.0,
            ),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final hour = group.x.toInt();
              final value = rod.toY;
              return BarTooltipItem(
                '${hour.toString().padLeft(2, '0')}:00\n',
                TextStyle(
                  color: context.colors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
                children: [
                  TextSpan(
                    text: '${value.toInt()} ${settings.unit}',
                    style: TextStyle(
                      color: _getGlucoseColorForValue(value),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final hour = value.toInt();
                // 0, 6, 12, 18, 24시만 표시
                if (hour % 6 == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      hour.toString().padLeft(2, '0'),
                      style: TextStyle(
                        color: context.colors.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
              reservedSize: 24,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: TextStyle(
                    color: context.colors.textSecondary,
                    fontSize: 10,
                  ),
                );
              },
              reservedSize: 35,
              interval: (chartMaxY - chartMinY) / 4,
            ),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: (chartMaxY - chartMinY) / 4,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: context.colors.divider.withValues(alpha: 0.3),
              strokeWidth: 1,
            );
          },
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(24, (hour) {
          final value = hourlyAverage[hour];
          if (value == null) {
            // 데이터가 없는 시간대
            return BarChartGroupData(
              x: hour,
              barRods: [
                BarChartRodData(toY: 0, color: Colors.transparent, width: 8),
              ],
            );
          }

          return BarChartGroupData(
            x: hour,
            barRods: [
              BarChartRodData(
                toY: value,
                color: _getGlucoseColorForValue(value),
                width: 8,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(4),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  /// 혈당 값에 따른 색상 반환 (6단계)
  Color _getGlucoseColorForValue(double value) {
    const defaultTarget = 100.0;
    final targetHigh = defaultTarget + 20; // 120

    if (value < 60) {
      return AppTheme.glucoseVeryLow;
    } else if (value < 80) {
      return AppTheme.glucoseLow;
    } else if (value <= targetHigh) {
      return AppTheme.glucoseNormal;
    } else if (value < 160) {
      return AppTheme.glucoseHigh; // 주의 (warning)
    } else if (value < 180) {
      return AppTheme.glucoseHigh; // 높음 (high)
    } else {
      return AppTheme.glucoseVeryHigh;
    }
  }

  Widget _buildStatsCard(BuildContext context, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: context.decorations.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  context,
                  label: l10n.normal,
                  value: '${_averageGlucose.toInt()}',
                  unit: 'mg/dL',
                  subtitle: l10n.average,
                  color: AppTheme.getGlucoseColor(_averageGlucose),
                ),
              ),
              Container(width: 1, height: 60, color: context.colors.divider),
              Expanded(
                child: _buildStatItem(
                  context,
                  label: l10n.low,
                  value: '${_minGlucose.toInt()}',
                  unit: 'mg/dL',
                  subtitle: l10n.lowest,
                  color: AppTheme.getGlucoseColor(_minGlucose),
                ),
              ),
              Container(width: 1, height: 60, color: context.colors.divider),
              Expanded(
                child: _buildStatItem(
                  context,
                  label: l10n.high,
                  value: '${_maxGlucose.toInt()}',
                  unit: 'mg/dL',
                  subtitle: l10n.highest,
                  color: AppTheme.getGlucoseColor(_maxGlucose),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required String label,
    required String value,
    required String unit,
    required String subtitle,
    required Color color,
  }) {
    return Column(
      children: [
        Text(subtitle, style: context.textStyles.tileSubtitle),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(width: 2),
            Text(unit, style: TextStyle(fontSize: 12, color: color)),
          ],
        ),
      ],
    );
  }

  Widget _buildDistributionCard(BuildContext context, AppLocalizations l10n) {
    final dist = _rangeDistribution;
    final total = dist['low']! + dist['normal']! + dist['high']!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: context.decorations.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // 파이 차트
              SizedBox(
                width: 100,
                height: 100,
                child: CustomPaint(
                  painter: _PieChartPainter(
                    lowRatio: total > 0 ? dist['low']! / total : 0,
                    normalRatio: total > 0 ? dist['normal']! / total : 0,
                    highRatio: total > 0 ? dist['high']! / total : 0,
                    holeColor: context.colors.card,
                  ),
                ),
              ),
              const SizedBox(width: 24),
              // 범례
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLegendItem(
                      context,
                      color: AppTheme.glucoseLow,
                      label: l10n.low,
                      value: '${dist['low']}${l10n.times}',
                      percentage: total > 0
                          ? '${(dist['low']! / total * 100).toInt()}%'
                          : '0%',
                    ),
                    const SizedBox(height: 8),
                    _buildLegendItem(
                      context,
                      color: AppTheme.glucoseNormal,
                      label: l10n.normal,
                      value: '${dist['normal']}${l10n.times}',
                      percentage: total > 0
                          ? '${(dist['normal']! / total * 100).toInt()}%'
                          : '0%',
                    ),
                    const SizedBox(height: 8),
                    _buildLegendItem(
                      context,
                      color: AppTheme.glucoseHigh,
                      label: l10n.high,
                      value: '${dist['high']}${l10n.times}',
                      percentage: total > 0
                          ? '${(dist['high']! / total * 100).toInt()}%'
                          : '0%',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(
    BuildContext context, {
    required Color color,
    required String label,
    required String value,
    required String percentage,
  }) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        Text(label, style: context.textStyles.tileSubtitle),
        const Spacer(),
        Text(value, style: context.textStyles.tileTitle),
        const SizedBox(width: 8),
        SizedBox(
          width: 35,
          child: Text(
            percentage,
            style: context.textStyles.tileSubtitle,
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildReportButton(BuildContext context, AppLocalizations l10n) {
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(vertical: 14),
      color: AppTheme.primaryColor,
      borderRadius: BorderRadius.circular(12),
      onPressed: () => MainScreen.switchToTab(3), // Report tab
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(l10n.viewReport, style: context.textStyles.buttonText),
          const SizedBox(width: 8),
          const Icon(
            CupertinoIcons.chevron_right,
            color: Colors.white,
            size: 18,
          ),
        ],
      ),
    );
  }
}

class _PieChartPainter extends CustomPainter {
  final double lowRatio;
  final double normalRatio;
  final double highRatio;
  final Color holeColor;

  _PieChartPainter({
    required this.lowRatio,
    required this.normalRatio,
    required this.highRatio,
    required this.holeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    double startAngle = -math.pi / 2;

    // 저혈당
    if (lowRatio > 0) {
      final sweepAngle = lowRatio * 2 * math.pi;
      final paint = Paint()
        ..color = AppTheme.glucoseLow
        ..style = PaintingStyle.fill;
      canvas.drawArc(rect, startAngle, sweepAngle, true, paint);
      startAngle += sweepAngle;
    }

    // 정상
    if (normalRatio > 0) {
      final sweepAngle = normalRatio * 2 * math.pi;
      final paint = Paint()
        ..color = AppTheme.glucoseNormal
        ..style = PaintingStyle.fill;
      canvas.drawArc(rect, startAngle, sweepAngle, true, paint);
      startAngle += sweepAngle;
    }

    // 고혈당
    if (highRatio > 0) {
      final sweepAngle = highRatio * 2 * math.pi;
      final paint = Paint()
        ..color = AppTheme.glucoseHigh
        ..style = PaintingStyle.fill;
      canvas.drawArc(rect, startAngle, sweepAngle, true, paint);
    }

    // 중앙 구멍 (도넛 차트)
    final holePaint = Paint()
      ..color = holeColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.6, holePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
