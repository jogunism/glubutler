import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:glu_butler/l10n/app_localizations.dart';
import 'package:glu_butler/core/navigation/main_screen.dart';
import 'package:glu_butler/core/theme/app_theme.dart';
import 'package:glu_butler/core/theme/app_text_styles.dart';
import 'package:glu_butler/core/theme/app_colors.dart';
import 'package:glu_butler/core/widgets/large_title_scroll_view.dart';
import 'package:glu_butler/core/widgets/settings_icon_button.dart';
import 'package:glu_butler/core/widgets/modals/date_picker_modal.dart';
import 'package:glu_butler/models/glucose_record.dart';
import 'package:glu_butler/models/glucose_range_settings.dart';
import 'package:glu_butler/services/settings_service.dart';
import 'package:glu_butler/services/glucose_score_service.dart';
import 'package:glu_butler/services/health_service.dart';
import 'package:glu_butler/services/analytics_service.dart';
import 'package:glu_butler/providers/feed_provider.dart';
import 'package:glu_butler/features/home/painters/chart_painters.dart';
import 'package:glu_butler/features/home/widgets/glucose_chart_card.dart';

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

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final _healthService = HealthService();

  List<GlucoseRecord> _todayRecords = [];
  DateTime _selectedDate = DateTime.now();

  // 건강 앱 데이터
  double? _sleepHours;
  int? _exerciseMinutes;

  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _loadTodayData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadTodayData() async {
    _animationController.reset();

    try {
      // FeedProvider에서 혈당 데이터 가져오기
      final feedProvider = context.read<FeedProvider>();
      final records = await feedProvider.getHomeGraphData(_selectedDate);

      // 건강 앱 데이터 로드
      final startOfDay = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
      );
      final endOfDay = startOfDay.add(const Duration(days: 1));
      await _loadHealthData(startOfDay, endOfDay);

      setState(() {
        _todayRecords = records;
      });
      _animationController.forward();
    } catch (e) {
      debugPrint('[HomeScreen] Error loading today data: $e');
    }
  }

  Future<void> _loadSelectedDateData() async {
    _animationController.reset();

    try {
      final startOfDay = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
      );
      final endOfDay = startOfDay.add(const Duration(days: 1));

      // 건강 앱 연동 기간 체크
      final settings = context.read<SettingsService>();
      final syncPeriod = settings.syncPeriod;
      final now = DateTime.now();
      final earliestDate = now.subtract(Duration(days: syncPeriod));

      // 선택한 날짜가 연동 기간 밖이면 빈 데이터 반환
      if (startOfDay.isBefore(earliestDate)) {
        setState(() {
          _todayRecords = [];
          _sleepHours = null;
          _exerciseMinutes = null;
        });
        _animationController.forward();
        return;
      }

      // FeedProvider에서 혈당 데이터 가져오기
      final feedProvider = context.read<FeedProvider>();
      final records = await feedProvider.getHomeGraphData(_selectedDate);

      // 건강 앱 데이터 로드
      await _loadHealthData(startOfDay, endOfDay);

      setState(() {
        _todayRecords = records;
      });
      _animationController.forward();
    } catch (e) {
      debugPrint('[HomeScreen] Error loading selected date data: $e');
    }
  }

  bool get _isToday {
    final now = DateTime.now();
    return _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;
  }

  /// 건강 앱 데이터 로드 (수면, 운동)
  Future<void> _loadHealthData(DateTime startOfDay, DateTime endOfDay) async {
    try {
      // 수면 데이터 가져오기 - 전날 저녁부터 검색 (수면은 보통 전날 밤부터 시작)
      final sleepStartDate = startOfDay.subtract(const Duration(hours: 12));
      final sleepRecords = await _healthService.fetchSleepData(
        startDate: sleepStartDate,
        endDate: endOfDay,
      );

      // 해당 날짜의 총 수면 시간 계산 (시간 단위)
      if (sleepRecords.isNotEmpty) {
        final todaySleepRecords = sleepRecords.where((record) {
          final endDay = DateTime(
            record.endTime.year,
            record.endTime.month,
            record.endTime.day,
          );
          final targetDay = DateTime(
            startOfDay.year,
            startOfDay.month,
            startOfDay.day,
          );
          return endDay == targetDay;
        }).toList();

        if (todaySleepRecords.isNotEmpty) {
          final totalSleepMinutes = todaySleepRecords.fold<int>(
            0,
            (sum, record) => sum + record.durationMinutes,
          );
          _sleepHours = totalSleepMinutes / 60.0;
        } else {
          _sleepHours = null;
        }
      } else {
        _sleepHours = null;
      }

      // 운동 데이터 가져오기
      final workoutRecords = await _healthService.fetchWorkoutData(
        startDate: startOfDay,
        endDate: endOfDay,
      );

      if (workoutRecords.isNotEmpty) {
        _exerciseMinutes = workoutRecords.fold<int>(
          0,
          (sum, record) => sum + record.durationMinutes,
        );
      } else {
        _exerciseMinutes = null;
      }
    } catch (e) {
      _sleepHours = null;
      _exerciseMinutes = null;
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
      return DateFormat.yMMMd(
        Localizations.localeOf(context).toString(),
      ).format(_selectedDate);
    }
  }

  Widget _buildDateButton(BuildContext context) {
    return CupertinoButton(
      padding: const EdgeInsets.only(bottom: 10, left: 44, right: 0),
      minimumSize: Size.zero,
      onPressed: () async {
        AnalyticsService.logDatePickerOpened();

        MainScreen.globalKey.currentState?.setTabBarVisibility(false);

        final pickedDate = await DatePickerModal.show(
          context,
          initialDate: _selectedDate,
        );

        MainScreen.globalKey.currentState?.setTabBarVisibility(true);

        if (pickedDate != null && pickedDate != _selectedDate) {
          AnalyticsService.logDateSelected(
            DateFormat('yyyy-MM-dd').format(pickedDate),
          );

          final now = DateTime.now();
          final isToday = pickedDate.year == now.year &&
              pickedDate.month == now.month &&
              pickedDate.day == now.day;
          setState(() {
            _selectedDate = pickedDate;
            if (!isToday) {
              // 비교 기간은 차트 카드 내부에서 관리되므로 날짜만 업데이트
            }
          });
          _loadSelectedDateData();
        }
      },
      child: const Icon(
        Icons.calendar_today,
        size: 24,
        color: AppTheme.primaryColor,
      ),
    );
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

  // 범위별 비율 계산 (5단계) - 사용자 설정 기반
  Map<String, int> get _rangeDistribution {
    final settings = context.watch<SettingsService>();
    final glucoseRange = settings.glucoseRange;

    int veryLow = 0, low = 0, normal = 0, high = 0, veryHigh = 0;
    for (final record in _todayRecords) {
      final value = record.valueIn('mg/dL');
      if (value < glucoseRange.veryLow) {
        veryLow++;
      } else if (value < glucoseRange.low) {
        low++;
      } else if (value <= glucoseRange.targetHigh) {
        normal++;
      } else if (value <= glucoseRange.veryHigh) {
        high++;
      } else {
        veryHigh++;
      }
    }
    return {
      'veryLow': veryLow,
      'low': low,
      'normal': normal,
      'high': high,
      'veryHigh': veryHigh,
    };
  }

  Future<void> _onRefresh() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );

    if (selected == today) {
      await _loadTodayData();
    } else {
      await _loadSelectedDateData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return LargeTitleScrollView(
      title: _formatSelectedDate(),
      onRefresh: _onRefresh,
      trailing: const SettingsIconButton(),
      titleTrailing: _buildDateButton(context),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // 일일 통계 (평균, 최저, 최고)
              _buildStatsCard(context, l10n),
              const SizedBox(height: 16),

              // 범위 분포 파이 차트
              _buildDistributionCard(context, l10n),
              const SizedBox(height: 16),

              // 시간대별 혈당 차트
              GlucoseChartCard(
                records: _todayRecords,
                isToday: _isToday,
                selectedDate: _selectedDate,
                animation: _animation,
              ),
              SizedBox(
                height: Platform.isAndroid
                    ? 56 + MediaQuery.of(context).padding.bottom + 16
                    : 80 + MediaQuery.of(context).padding.bottom,
              ),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsCard(BuildContext context, AppLocalizations l10n) {
    final settings = context.watch<SettingsService>();
    final hasData = _todayRecords.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.card,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  context,
                  label: l10n.normal,
                  value: hasData ? '${_averageGlucose.toInt()}' : '-',
                  unit: settings.unit,
                  subtitle: l10n.average,
                  color: hasData
                      ? _getGlucoseColorForValue(
                          _averageGlucose,
                          settings.glucoseRange,
                        )
                      : context.colors.textSecondary.withValues(alpha: 0.5),
                  hasData: hasData,
                ),
              ),
              Container(width: 1, height: 60, color: context.colors.divider),
              Expanded(
                child: _buildStatItem(
                  context,
                  label: l10n.low,
                  value: hasData ? '${_minGlucose.toInt()}' : '-',
                  unit: settings.unit,
                  subtitle: l10n.lowest,
                  color: hasData
                      ? (Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.grey[800]!)
                      : context.colors.textSecondary.withValues(alpha: 0.5),
                  hasData: hasData,
                ),
              ),
              Container(width: 1, height: 60, color: context.colors.divider),
              Expanded(
                child: _buildStatItem(
                  context,
                  label: l10n.high,
                  value: hasData ? '${_maxGlucose.toInt()}' : '-',
                  unit: settings.unit,
                  subtitle: l10n.highest,
                  color: hasData
                      ? (Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.grey[800]!)
                      : context.colors.textSecondary.withValues(alpha: 0.5),
                  hasData: hasData,
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
    required bool hasData,
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
            if (hasData) ...[
              const SizedBox(width: 2),
              Text(unit, style: TextStyle(fontSize: 12, color: color)),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildDistributionCard(BuildContext context, AppLocalizations l10n) {
    final settings = context.watch<SettingsService>();
    final dist = _rangeDistribution;
    final total =
        dist['veryLow']! +
        dist['low']! +
        dist['normal']! +
        dist['high']! +
        dist['veryHigh']!;
    final hasData = total > 0;

    // 점수 계산 - 과거 날짜는 해당 날의 마지막 시점 기준
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedDay = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );
    final isToday = selectedDay == today;

    final scoreCalculationTime = isToday
        ? now
        : DateTime(
            _selectedDate.year,
            _selectedDate.month,
            _selectedDate.day,
            23,
            59,
            59,
          );

    final score = hasData
        ? GlucoseScoreService.calculateScore(
            records: _todayRecords,
            glucoseRange: settings.glucoseRange,
            currentTime: scoreCalculationTime,
            sleepHours: _sleepHours,
            exerciseMinutes: _exerciseMinutes,
          )
        : 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.card,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 타이틀
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                l10n.glucoseStatus,
                style: context.textStyles.tileTitle.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              GestureDetector(
                onTap: () => _showScoreInfoModal(context),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Icon(
                    CupertinoIcons.info_circle,
                    size: 16,
                    color: context.colors.textSecondary.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // 파이 차트
              SizedBox(
                width: 100,
                height: 100,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: _animation,
                      builder: (context, child) {
                        return CustomPaint(
                          size: const Size(100, 100),
                          painter: PieChartPainter(
                            veryLowRatio: hasData
                                ? dist['veryLow']! / total
                                : 0,
                            lowRatio: hasData ? dist['low']! / total : 0,
                            normalRatio: hasData ? dist['normal']! / total : 0,
                            highRatio: hasData ? dist['high']! / total : 0,
                            veryHighRatio: hasData
                                ? dist['veryHigh']! / total
                                : 0,
                            holeColor: context.colors.card,
                            hasData: hasData,
                            emptyColor: context.colors.textSecondary.withValues(
                              alpha: 0.5,
                            ),
                            animationValue: hasData ? _animation.value : 1.0,
                          ),
                        );
                      },
                    ),
                    // 중앙 점수 표시
                    Text(
                      hasData ? score.toString() : '-',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: hasData
                            ? (Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white
                                  : Colors.black)
                            : context.colors.textSecondary.withValues(
                                alpha: 0.5,
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              // 범례 (매우높음, 높음, 보통, 낮음, 매우낮음 순)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (dist['veryHigh']! > 0) ...[
                      _buildLegendItem(
                        context,
                        color: AppTheme.glucoseVeryHigh,
                        label: l10n.veryHigh,
                        value: '${dist['veryHigh']}${l10n.times}',
                        percentage: hasData
                            ? '${(dist['veryHigh']! / total * 100).toInt()}%'
                            : '0%',
                      ),
                      const SizedBox(height: 8),
                    ],
                    _buildLegendItem(
                      context,
                      color: AppTheme.glucoseHigh,
                      label: l10n.high,
                      value: '${dist['high']}${l10n.times}',
                      percentage: hasData
                          ? '${(dist['high']! / total * 100).toInt()}%'
                          : '0%',
                    ),
                    const SizedBox(height: 8),
                    _buildLegendItem(
                      context,
                      color: AppTheme.glucoseNormal,
                      label: l10n.normal,
                      value: '${dist['normal']}${l10n.times}',
                      percentage: hasData
                          ? '${(dist['normal']! / total * 100).toInt()}%'
                          : '0%',
                    ),
                    const SizedBox(height: 8),
                    _buildLegendItem(
                      context,
                      color: AppTheme.glucoseLow,
                      label: l10n.low,
                      value: '${dist['low']}${l10n.times}',
                      percentage: hasData
                          ? '${(dist['low']! / total * 100).toInt()}%'
                          : '0%',
                    ),
                    if (dist['veryLow']! > 0) ...[
                      const SizedBox(height: 8),
                      _buildLegendItem(
                        context,
                        color: AppTheme.glucoseVeryLow,
                        label: l10n.veryLow,
                        value: '${dist['veryLow']}${l10n.times}',
                        percentage: hasData
                            ? '${(dist['veryLow']! / total * 100).toInt()}%'
                            : '0%',
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showScoreInfoModal(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    MainScreen.globalKey.currentState?.setTabBarVisibility(false);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      useRootNavigator: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: context.colors.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.only(bottom: bottomPadding + 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 드래그 핸들
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // 헤더
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      l10n.close,
                      style: TextStyle(color: Colors.grey[600], fontSize: 16),
                    ),
                  ),
                  Text(
                    l10n.scoreInfoTitle,
                    style: context.textStyles.tileTitle.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 60),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 컨텐츠
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 혈당 관리 품질
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '• ',
                        style: context.textStyles.tileTitle.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 20,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.scoreInfoQuality,
                              style: context.textStyles.tileTitle.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              l10n.scoreInfoQualityDesc,
                              style: context.textStyles.tileSubtitle.copyWith(
                                color: context.colors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // 측정 일관성
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '• ',
                        style: context.textStyles.tileTitle.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 20,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.scoreInfoConsistency,
                              style: context.textStyles.tileTitle.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              l10n.scoreInfoConsistencyDesc,
                              style: context.textStyles.tileSubtitle.copyWith(
                                color: context.colors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              l10n.scoreInfoRecommendation,
                              style: context.textStyles.tileSubtitle.copyWith(
                                fontWeight: FontWeight.w600,
                                color: context.colors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildRecommendationItem(
                              context,
                              l10n.scoreInfoMorning,
                            ),
                            _buildRecommendationItem(
                              context,
                              l10n.scoreInfoLunch,
                            ),
                            _buildRecommendationItem(
                              context,
                              l10n.scoreInfoDinner,
                            ),
                            _buildRecommendationItem(
                              context,
                              l10n.scoreInfoBedtime,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // 생활습관 (건강 앱 연동시)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '• ',
                        style: context.textStyles.tileTitle.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 20,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.scoreInfoLifestyle,
                              style: context.textStyles.tileTitle.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              l10n.scoreInfoLifestyleDesc,
                              style: context.textStyles.tileSubtitle.copyWith(
                                color: context.colors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // 개인정보 안내
                  Text(
                    l10n.scoreInfoPrivacy,
                    style: context.textStyles.tileSubtitle.copyWith(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppTheme.accentRedColorDarkMode
                          : AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );

    MainScreen.globalKey.currentState?.setTabBarVisibility(true);
  }

  Widget _buildRecommendationItem(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: context.textStyles.tileSubtitle.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: context.textStyles.tileSubtitle.copyWith(
                color: context.colors.textSecondary,
              ),
            ),
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

  /// 혈당 값에 따른 색상 반환 (settings 기준)
  Color _getGlucoseColorForValue(double value, [GlucoseRangeSettings? range]) {
    final r = range ?? GlucoseRangeSettings.defaults;
    if (value < r.veryLow) {
      return AppTheme.glucoseVeryLow;
    } else if (value < r.low) {
      return AppTheme.glucoseLow;
    } else if (value <= r.targetHigh) {
      return AppTheme.glucoseNormal;
    } else if (value <= r.veryHigh) {
      return AppTheme.glucoseHigh;
    } else {
      return AppTheme.glucoseVeryHigh;
    }
  }
}
