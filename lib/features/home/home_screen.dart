import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:glu_butler/l10n/app_localizations.dart';
import 'package:glu_butler/core/navigation/main_screen.dart';
import 'package:glu_butler/core/theme/app_theme.dart';
import 'package:glu_butler/core/theme/app_text_styles.dart';
import 'package:glu_butler/core/theme/app_colors.dart';
import 'package:glu_butler/core/theme/app_decorations.dart';
import 'package:glu_butler/core/widgets/large_title_scroll_view.dart';
import 'package:glu_butler/core/widgets/settings_icon_button.dart';

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
  // TODO: Replace with real data from service
  final int _todayScore = 81;
  final List<_GlucoseEntry> _todayEntries = [
    _GlucoseEntry(time: '07:00', value: 95, label: '공복'),
    _GlucoseEntry(time: '09:00', value: 142, label: '아침 식후'),
    _GlucoseEntry(time: '12:30', value: 88, label: '점심 식전'),
    _GlucoseEntry(time: '14:00', value: 156, label: '점심 식후'),
    _GlucoseEntry(time: '18:00', value: 92, label: '저녁 식전'),
    _GlucoseEntry(time: '20:00', value: 138, label: '저녁 식후'),
  ];

  double get _averageGlucose {
    if (_todayEntries.isEmpty) return 0;
    return _todayEntries.map((e) => e.value).reduce((a, b) => a + b) /
        _todayEntries.length;
  }

  double get _minGlucose {
    if (_todayEntries.isEmpty) return 0;
    return _todayEntries.map((e) => e.value).reduce(math.min);
  }

  double get _maxGlucose {
    if (_todayEntries.isEmpty) return 0;
    return _todayEntries.map((e) => e.value).reduce(math.max);
  }

  // 범위별 비율 계산
  Map<String, int> get _rangeDistribution {
    int low = 0, normal = 0, high = 0;
    for (final entry in _todayEntries) {
      if (entry.value < 70) {
        low++;
      } else if (entry.value <= 140) {
        normal++;
      } else {
        high++;
      }
    }
    return {'low': low, 'normal': normal, 'high': high};
  }

  int? _selectedEntryIndex;

  Future<void> _onRefresh() async {
    // TODO: Implement data refresh
    await Future.delayed(const Duration(seconds: 1));
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: context.decorations.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 선택된 항목 정보 표시
          if (_selectedEntryIndex != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    CupertinoIcons.drop_fill,
                    color: AppTheme.getGlucoseColor(
                        _todayEntries[_selectedEntryIndex!].value),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_todayEntries[_selectedEntryIndex!].time} - ${_todayEntries[_selectedEntryIndex!].label}',
                          style: context.textStyles.tileSubtitle,
                        ),
                        Text(
                          '${_todayEntries[_selectedEntryIndex!].value.toInt()} mg/dL',
                          style: context.textStyles.tileTitle.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // 차트
          SizedBox(
            height: 200,
            child: _buildGlucoseChart(context, l10n),
          ),
        ],
      ),
    );
  }

  Widget _buildGlucoseChart(BuildContext context, AppLocalizations l10n) {
    if (_todayEntries.isEmpty) {
      return Center(
        child: Text(
          l10n.noGlucoseToday,
          style: context.textStyles.bodyTextSecondary,
        ),
      );
    }

    final maxValue = _todayEntries.map((e) => e.value).reduce(math.max);
    final chartMax = ((maxValue / 50).ceil() * 50).toDouble() + 20;

    return LayoutBuilder(
      builder: (context, constraints) {
        final barWidth = (constraints.maxWidth - 40) / _todayEntries.length;
        final chartHeight = constraints.maxHeight - 30;

        return Column(
          children: [
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Y축 레이블
                  SizedBox(
                    width: 35,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('${chartMax.toInt()}',
                            style: TextStyle(
                                fontSize: 10, color: context.colors.textSecondary)),
                        Text('${(chartMax / 2).toInt()}',
                            style: TextStyle(
                                fontSize: 10, color: context.colors.textSecondary)),
                        Text('0',
                            style: TextStyle(
                                fontSize: 10, color: context.colors.textSecondary)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 5),
                  // 차트 영역
                  Expanded(
                    child: Stack(
                      children: [
                        // 기준선들
                        ..._buildGuideLines(chartHeight, chartMax),
                        // 막대 그래프
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: _todayEntries.asMap().entries.map((entry) {
                            final index = entry.key;
                            final data = entry.value;
                            final barHeight =
                                (data.value / chartMax) * chartHeight;
                            final isSelected = _selectedEntryIndex == index;

                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedEntryIndex =
                                      isSelected ? null : index;
                                });
                              },
                              child: Container(
                                width: barWidth - 8,
                                height: barHeight,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppTheme.getGlucoseColor(data.value)
                                      : AppTheme.getGlucoseColor(data.value)
                                          .withValues(alpha: 0.6),
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(4),
                                  ),
                                  border: isSelected
                                      ? Border.all(
                                          color: AppTheme.primaryColor,
                                          width: 2,
                                        )
                                      : null,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        // 선 그래프
                        CustomPaint(
                          size: Size(constraints.maxWidth - 40, chartHeight),
                          painter: _LineChartPainter(
                            entries: _todayEntries,
                            maxValue: chartMax,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // X축 레이블
            Padding(
              padding: const EdgeInsets.only(left: 40),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: _todayEntries.map((entry) {
                  return SizedBox(
                    width: barWidth - 8,
                    child: Text(
                      entry.time.substring(0, 5),
                      style: TextStyle(fontSize: 9, color: context.colors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        );
      },
    );
  }

  List<Widget> _buildGuideLines(double height, double maxValue) {
    return [
      // 140 mg/dL 라인 (고혈당 기준)
      if (140 < maxValue)
        Positioned(
          bottom: (140 / maxValue) * height,
          left: 0,
          right: 0,
          child: Container(
            height: 1,
            color: AppTheme.glucoseHigh.withValues(alpha: 0.3),
          ),
        ),
      // 70 mg/dL 라인 (저혈당 기준)
      Positioned(
        bottom: (70 / maxValue) * height,
        left: 0,
        right: 0,
        child: Container(
          height: 1,
          color: AppTheme.glucoseLow.withValues(alpha: 0.3),
        ),
      ),
    ];
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
          Container(
            width: 1,
            height: 60,
            color: context.colors.divider,
          ),
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
          Container(
            width: 1,
            height: 60,
            color: context.colors.divider,
          ),
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
        Text(
          subtitle,
          style: context.textStyles.tileSubtitle,
        ),
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
            Text(
              unit,
              style: TextStyle(
                fontSize: 12,
                color: color,
              ),
            ),
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
          Text(
            l10n.viewReport,
            style: context.textStyles.buttonText,
          ),
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

class _GlucoseEntry {
  final String time;
  final double value;
  final String label;

  _GlucoseEntry({
    required this.time,
    required this.value,
    required this.label,
  });
}

class _LineChartPainter extends CustomPainter {
  final List<_GlucoseEntry> entries;
  final double maxValue;
  final Color color;

  _LineChartPainter({
    required this.entries,
    required this.maxValue,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (entries.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    final barWidth = size.width / entries.length;

    for (int i = 0; i < entries.length; i++) {
      final x = barWidth * i + barWidth / 2;
      final y = size.height - (entries[i].value / maxValue) * size.height;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }

      // 점 그리기
      canvas.drawCircle(Offset(x, y), 4, dotPaint);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
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
