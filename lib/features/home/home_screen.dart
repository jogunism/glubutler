import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
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
import 'package:glu_butler/models/feed_item.dart';
import 'package:glu_butler/services/settings_service.dart';
import 'package:glu_butler/services/glucose_score_service.dart';
import 'package:glu_butler/services/health_service.dart';
import 'package:glu_butler/services/analytics_service.dart';
import 'package:glu_butler/providers/feed_provider.dart';

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

  // 차트 터치 상태
  int? _touchedBarIndex;
  final ScrollController _chartScrollController = ScrollController();
  bool _isChartTouching = false;

  // 차트 줌 설정 (60 = 1시간단위/기본, 10 = 최대확대/10분단위)
  double _minutesPerBar = 60.0;
  double _pinchStartMinutesPerBar = 60.0;
  double _pinchStartDistance = 0.0;
  final Map<int, Offset> _activePointers = {};

  // 비교 기간 오버레이
  // (label, startDaysAgo, endDaysAgo) — 선택된 날짜 기준
  static const _comparisonPeriods = [
    ('이번주', 7, 1),
    ('지난주', 14, 8),
    ('3주전', 21, 15),
    ('1달전', 37, 31),
    ('2달전', 67, 61),
    ('3달전', 90, 84),
    ('6개월전', 180, 174),
  ];
  int? _comparisonPeriodIndex;
  List<GlucoseRecord> _comparisonRecords = [];
  bool _isLoadingComparison = false;

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
  @override
  void dispose() {
    _animationController.dispose();
    _chartScrollController.dispose();
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

  /// 차트 탭 시 비교 기간 순환 (없음 → 이번주 → 지난주 → ... → 없음)
  void _cycleComparisonPeriod() {
    final syncPeriod = context.read<SettingsService>().syncPeriod;
    final available = [
      for (int i = 0; i < _comparisonPeriods.length; i++)
        if (_comparisonPeriods[i].$2 <= syncPeriod) i,
    ];
    if (available.isEmpty) return;

    if (_comparisonPeriodIndex == null) {
      setState(() {
        _comparisonPeriodIndex = available.first;
        _comparisonRecords = [];
      });
      _loadComparisonData(available.first);
    } else {
      final pos = available.indexOf(_comparisonPeriodIndex!);
      if (pos == -1 || pos == available.length - 1) {
        setState(() {
          _comparisonPeriodIndex = null;
          _comparisonRecords = [];
        });
      } else {
        final next = available[pos + 1];
        setState(() {
          _comparisonPeriodIndex = next;
          _comparisonRecords = [];
        });
        _loadComparisonData(next);
      }
    }
  }

  /// 비교 기간 데이터 로드
  Future<void> _loadComparisonData(int periodIndex) async {
    final (_, startDaysAgo, endDaysAgo) = _comparisonPeriods[periodIndex];
    setState(() => _isLoadingComparison = true);

    final feedProvider = context.read<FeedProvider>();
    final records = <GlucoseRecord>[];

    for (int daysAgo = endDaysAgo; daysAgo <= startDaysAgo; daysAgo++) {
      final date = _selectedDate.subtract(Duration(days: daysAgo));
      try {
        final dayRecords = await feedProvider.getHomeGraphData(date);
        records.addAll(dayRecords);
      } catch (_) {}
    }

    if (!mounted) return;
    setState(() {
      _comparisonRecords = records;
      _isLoadingComparison = false;
    });
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
      // 수면 종료 시간이 오늘인 것만 포함 (어제 밤 ~ 오늘 아침 수면)
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

      // 해당 날짜의 총 운동 시간 계산 (분 단위)
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
      // 국가별 날짜 형식 (예: "24 Dec 2025", "2025년 12월 24일")
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
        // Log date picker opened
        AnalyticsService.logDatePickerOpened();

        // 모달을 열기 전에 탭바 숨김
        MainScreen.globalKey.currentState?.setTabBarVisibility(false);

        final pickedDate = await DatePickerModal.show(
          context,
          initialDate: _selectedDate,
        );

        // 모달이 닫히면 탭바 다시 보임
        MainScreen.globalKey.currentState?.setTabBarVisibility(true);

        if (pickedDate != null && pickedDate != _selectedDate) {
          // Log date selected
          AnalyticsService.logDateSelected(
            DateFormat('yyyy-MM-dd').format(pickedDate),
          );

          setState(() {
            _selectedDate = pickedDate;
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
    // 현재 선택된 날짜가 오늘이면 _loadTodayData, 아니면 _loadSelectedDateData
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
              _buildChartCard(context, l10n),
              SizedBox(height: 80 + MediaQuery.of(context).padding.bottom), // 탭바 + 기종별 safe area
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildChartCard(BuildContext context, AppLocalizations l10n) {
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
        children: [
          // 타이틀
          Row(
            children: [
              Text(
                l10n.todaysGlucose,
                style: context.textStyles.tileTitle.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                l10n.tapToCompare,
                style: context.textStyles.tileSubtitle.copyWith(
                  fontSize: 11,
                  color: context.colors.textSecondary.withValues(alpha: 0.45),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 차트 (스크롤 가능, 핀치로 확대/축소)
          SizedBox(
            height: 200,
            child: Listener(
              behavior: HitTestBehavior.translucent,
              onPointerDown: (event) {
                _activePointers[event.pointer] = event.localPosition;
                if (_activePointers.length == 2) {
                  final positions = _activePointers.values.toList();
                  _pinchStartDistance = (positions[0] - positions[1]).distance;
                  _pinchStartMinutesPerBar = _minutesPerBar;
                }
              },
              onPointerMove: (event) {
                if (!_activePointers.containsKey(event.pointer)) return;
                _activePointers[event.pointer] = event.localPosition;
                if (_activePointers.length == 2 && _pinchStartDistance > 0) {
                  final positions = _activePointers.values.toList();
                  final currentDistance = (positions[0] - positions[1]).distance;
                  final scale = currentDistance / _pinchStartDistance;
                  final newMinutes = (_pinchStartMinutesPerBar / scale).clamp(10.0, 60.0);
                  if ((newMinutes - _minutesPerBar).abs() > 0.2) {
                    setState(() {
                      _minutesPerBar = newMinutes;
                      _touchedBarIndex = null;
                    });
                  }
                }
              },
              onPointerUp: (event) {
                _activePointers.remove(event.pointer);
                if (_activePointers.length < 2) _pinchStartDistance = 0.0;
              },
              onPointerCancel: (event) {
                _activePointers.remove(event.pointer);
                if (_activePointers.length < 2) _pinchStartDistance = 0.0;
              },
              child: AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return _buildGlucoseChart(context, l10n);
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          // 비교 기간 칩
          _buildComparisonChips(context, l10n),
        ],
      ),
    );
  }

  // 기간별 고유 색상
  static const _periodColors = [
    Color(0xFF4A90D9), // 이번주 - 파랑
    Color(0xFF4CAF50), // 지난주 - 초록
    Color(0xFFFF9800), // 3주전  - 주황
    Color(0xFF9C27B0), // 1달전  - 보라
    Color(0xFF00BCD4), // 2달전  - 청록
    Color(0xFFF44336), // 3달전  - 빨강
    Color(0xFFFF8F00), // 6개월전 - 황금
  ];

  String _getPeriodLabel(int index, AppLocalizations l10n) {
    switch (index) {
      case 0: return l10n.compThisWeek;
      case 1: return l10n.compLastWeek;
      case 2: return l10n.comp3WeeksAgo;
      case 3: return l10n.comp1MonthAgo;
      case 4: return l10n.comp2MonthsAgo;
      case 5: return l10n.comp3MonthsAgo;
      case 6: return l10n.comp6MonthsAgo;
      default: return _comparisonPeriods[index].$1;
    }
  }

  Widget _buildComparisonChips(BuildContext context, AppLocalizations l10n) {
    final settings = context.watch<SettingsService>();
    final syncPeriod = settings.syncPeriod;

    final available = [
      for (int i = 0; i < _comparisonPeriods.length; i++)
        if (_comparisonPeriods[i].$2 <= syncPeriod) i,
    ];

    if (available.isEmpty) return const SizedBox.shrink();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: available.map((i) {
          final label = _getPeriodLabel(i, l10n);
          final color = _periodColors[i];
          final isSelected = _comparisonPeriodIndex == i;
          return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? color
                          : color.withValues(alpha: 0.3),
                    ),
                  ),
                  const SizedBox(width: 4),
                  _isLoadingComparison && isSelected
                      ? SizedBox(
                          width: 32,
                          height: 10,
                          child: LinearProgressIndicator(
                            backgroundColor: Colors.transparent,
                            color: color.withValues(alpha: 0.5),
                            minHeight: 1.5,
                          ),
                        )
                      : Text(
                          label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: isSelected
                                ? color
                                : context.colors.textSecondary
                                    .withValues(alpha: 0.4),
                          ),
                        ),
                ],
              ),
            );
        }).toList(),
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

    // _minutesPerBar에 따라 데이터 그룹화 (10분~60분 단위)
    // 5분 단위로 스냅: 10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60
    final minPerBar = ((_minutesPerBar / 5).round() * 5).clamp(10, 60);
    final totalBars = (24 * 60 / minPerBar).round();
    final timeData = <int, List<double>>{};
    for (final record in _todayRecords) {
      final hour = record.timestamp.hour;
      final minute = record.timestamp.minute;
      final index = (hour * 60 + minute) ~/ minPerBar;
      final value = record.valueIn('mg/dL');
      timeData.putIfAbsent(index, () => []).add(value);
    }

    // 각 구간의 평균값 계산
    final timeAverage = <int, double>{};
    timeData.forEach((index, values) {
      timeAverage[index] = values.reduce((a, b) => a + b) / values.length;
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

    // 해당 날짜의 이벤트 데이터 가져오기 (식사, 운동, 인슐린)
    final feedProvider = context.watch<FeedProvider>();
    final startOfDay = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );
    final endOfDay = startOfDay.add(const Duration(days: 1));
    final eventsInRange = feedProvider.items.where((item) {
      return item.timestamp.isAfter(startOfDay) &&
          item.timestamp.isBefore(endOfDay) &&
          (item.type == FeedItemType.meal ||
              item.type == FeedItemType.exercise ||
              item.type == FeedItemType.insulin);
    }).toList();

    // 화면 너비 계산: 1.5제곱으로 줌 → 막대 슬롯도 같이 커짐
    // 60min: 1x, 30min: 2.8x, 10min: 14.7x
    final screenWidth = MediaQuery.of(context).size.width;
    final availableWidth = screenWidth - 35; // Y축 너비 제외
    final zoomFactor = 60.0 / minPerBar;
    final chartWidth = availableWidth * math.pow(zoomFactor, 1.5);

    // 비교 기간 슬롯별 평균 계산
    final compAverage = <int, double>{};
    if (_comparisonRecords.isNotEmpty) {
      final compTimeData = <int, List<double>>{};
      for (final record in _comparisonRecords) {
        final hour = record.timestamp.hour;
        final minute = record.timestamp.minute;
        final index = (hour * 60 + minute) ~/ minPerBar;
        compTimeData.putIfAbsent(index, () => []).add(record.valueIn('mg/dL'));
      }
      compTimeData.forEach((index, values) {
        compAverage[index] = values.reduce((a, b) => a + b) / values.length;
      });
    }

    // 차트 위젯 생성
    final chartStack = Stack(
      children: [
        // 이벤트 배경 + 터치 라인 레이어 (CustomPaint)
        CustomPaint(
          painter: _EventBackgroundPainter(
            events: eventsInRange,
            chartMinY: chartMinY,
            chartMaxY: chartMaxY,
            getEventColor: _getEventColor,
            getEventLabelColor: _getEventColor,
            getEventLabel: (type) => _getEventLabel(type, l10n),
            getEventDuration: _getEventDuration,
            cardColor: context.colors.card,
            textColor: isDarkMode
                ? context.colors.textPrimary
                : Colors.black,
            touchedBarIndex: _touchedBarIndex,
            touchLineColor: context.colors.textPrimary,
            totalBars: totalBars,
            minutesPerBar: minPerBar.toDouble(),
          ),
          child: Container(),
        ),
        // 차트 레이어
        BarChart(
                    key: ValueKey(minPerBar),
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: chartMaxY,
                      minY: chartMinY,
                      // 평균 혈당 수평선 + 이벤트 배경선 + 이벤트 레이블
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
                              padding: const EdgeInsets.only(
                                right: 8,
                                bottom: 4,
                              ),
                              style: TextStyle(
                                color: averageLineColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                backgroundColor: context.colors.card.withValues(
                                  alpha: 0.8,
                                ),
                              ),
                              labelResolver: (line) =>
                                  ' ${l10n.average} ${averageGlucose.toInt()} ',
                            ),
                          ),
                        ],
                        verticalLines: [],
                      ),
                      barTouchData: BarTouchData(
                        enabled: true,
                        touchCallback: (FlTouchEvent event, barTouchResponse) {
                          setState(() {
                            if (event is FlTapUpEvent) {
                              _touchedBarIndex = null;
                              _isChartTouching = false;
                              // 빈 공간 탭 시 비교 기간 순환
                              if (barTouchResponse?.spot == null) {
                                _cycleComparisonPeriod();
                              }
                            } else if (event is FlPanEndEvent ||
                                event is FlLongPressEnd) {
                              _touchedBarIndex = null;
                              _isChartTouching = false;
                            } else if (barTouchResponse != null &&
                                barTouchResponse.spot != null) {
                              _touchedBarIndex =
                                  barTouchResponse.spot!.touchedBarGroupIndex;
                              _isChartTouching = true;
                            }
                          });
                        },
                        touchTooltipData: BarTouchTooltipData(
                          fitInsideVertically: true,
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
                            final index = group.x.toInt();
                            final value = rod.toY;

                            final totalMinutes = index * minPerBar;
                            final hour = totalMinutes ~/ 60;
                            final minute = totalMinutes % 60;
                            final timeText = '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

                            return BarTooltipItem(
                              '$timeText\n',
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
                                    color: _getGlucoseColorForValue(value, glucoseRange),
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
                              final index = value.toInt();

                              // 항상 3바마다 레이블 → 보이는 영역에 항상 ~8개 유지
                              // 60분/바: 3바 = 3시간, 10분/바: 3바 = 30분
                              if (index % 3 == 0) {
                                final totalMinutes = index * minPerBar;
                                if (totalMinutes >= 1440) return const SizedBox.shrink();
                                final hour = totalMinutes ~/ 60;
                                final minute = totalMinutes % 60;
                                final label = minute == 0
                                    ? hour.toString().padLeft(2, '0')
                                    : '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    label,
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
                        leftTitles: const AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: false,
                          ), // Y축 라벨 숨김 (커스텀 페인터 사용)
                        ),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: (chartMaxY - chartMinY) / 4,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: context.colors.divider.withValues(
                              alpha: 0.3,
                            ),
                            strokeWidth: 1,
                          );
                        },
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: List.generate(totalBars, (index) {
                        final value = timeAverage[index];
                        // 슬롯의 55% 너비, 최소 6px ~ 최대 22px
                        final barWidth = (chartWidth / totalBars * 0.55).clamp(6.0, 22.0);

                        if (value == null) {
                          // 데이터가 없는 구간
                          return BarChartGroupData(
                            x: index,
                            barRods: [
                              BarChartRodData(
                                toY: 0,
                                color: Colors.transparent,
                                width: barWidth,
                              ),
                            ],
                          );
                        }

                        return BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(
                              toY: value * _animation.value,
                              color: _getGlucoseColorForValue(value, glucoseRange),
                              width: barWidth,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4),
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
        // 비교 기간 오버레이 라인
        if (compAverage.isNotEmpty)
          CustomPaint(
            painter: _ComparisonLinePainter(
              compAverage: compAverage,
              chartMinY: chartMinY,
              chartMaxY: chartMaxY,
              totalBars: totalBars,
              color: _HomeScreenState._periodColors[_comparisonPeriodIndex!],
            ),
            child: Container(),
          ),
      ],
    );

    return Row(
      children: [
        // 고정된 Y축 라벨
        SizedBox(
          width: 35,
          child: Column(
            children: [
              Expanded(
                child: CustomPaint(
                  painter: _YAxisPainter(
                    minY: chartMinY,
                    maxY: chartMaxY,
                    textColor: context.colors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 24), // bottomTitles reservedSize
            ],
          ),
        ),
        // 차트 영역 (줌인시 스크롤 가능)
        Expanded(
          child: minPerBar < 60
              ? SingleChildScrollView(
                  controller: _chartScrollController,
                  scrollDirection: Axis.horizontal,
                  physics: _isChartTouching
                      ? const NeverScrollableScrollPhysics()
                      : const AlwaysScrollableScrollPhysics(),
                  child: SizedBox(
                    width: chartWidth,
                    child: chartStack,
                  ),
                )
              : chartStack, // 기본(60분단위): 스크롤 없이
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
      return AppTheme.glucoseHigh; // 주의
    } else {
      return AppTheme.glucoseVeryHigh;
    }
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
                      ? _getGlucoseColorForValue(_averageGlucose, settings.glucoseRange)
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

    // 오늘이 아니면 해당 날짜의 23:59:59 기준으로 점수 계산
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
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              l10n.glucoseStatus,
              style: context.textStyles.tileTitle.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
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
                          painter: _PieChartPainter(
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
                    // 매우높음 - 데이터가 있을 때만 표시
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
                    // 매우낮음 - 데이터가 있을 때만 표시
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
          const SizedBox(height: 12),
          // 점수 정보 버튼
          GestureDetector(
            onTap: () => _showScoreInfoModal(context),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  CupertinoIcons.info_circle,
                  size: 14,
                  color: context.colors.textSecondary.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 4),
                Text(
                  l10n.scoreHint,
                  style: context.textStyles.tileSubtitle.copyWith(
                    fontSize: 11,
                    color: context.colors.textSecondary.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showScoreInfoModal(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    // 모달 열기 전 탭바 숨김
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
                  const SizedBox(width: 60), // 균형 맞추기
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
                            // 권장 측정 횟수를 여기에 포함
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

    // 모달 닫힌 후 탭바 다시 표시
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

  /// 이벤트 지속 시간 계산 (시간 단위)
  double _getEventDuration(FeedItem event) {
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
}

/// Y축 라벨을 그리는 CustomPainter
class _YAxisPainter extends CustomPainter {
  final double minY;
  final double maxY;
  final Color textColor;

  _YAxisPainter({
    required this.minY,
    required this.maxY,
    required this.textColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final interval = (maxY - minY) / 4;

    for (int i = 0; i <= 4; i++) {
      final value = minY + (interval * i);
      // 최소값은 표시하지 않음
      if (i == 0) continue;

      final yPosition = size.height * (1 - (i / 4.0));

      final textSpan = TextSpan(
        text: value.toInt().toString(),
        style: TextStyle(color: textColor, fontSize: 10),
      );

      final textPainter = TextPainter(
        text: textSpan,
        textDirection: ui.TextDirection.ltr,
        textAlign: TextAlign.right,
      );

      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          size.width - textPainter.width - 5,
          yPosition - textPainter.height / 2,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// 이벤트 배경과 터치 라인을 그리는 CustomPainter
class _EventBackgroundPainter extends CustomPainter {
  final List<FeedItem> events;
  final double chartMinY;
  final double chartMaxY;
  final Color Function(FeedItemType) getEventColor;
  final Color Function(FeedItemType) getEventLabelColor;
  final String Function(FeedItemType) getEventLabel;
  final double Function(FeedItem) getEventDuration;
  final Color cardColor;
  final Color textColor;
  final int? touchedBarIndex;
  final Color touchLineColor;
  final int totalBars;
  final double minutesPerBar;

  _EventBackgroundPainter({
    required this.events,
    required this.chartMinY,
    required this.chartMaxY,
    required this.getEventColor,
    required this.getEventLabelColor,
    required this.getEventLabel,
    required this.getEventDuration,
    required this.cardColor,
    required this.textColor,
    required this.touchedBarIndex,
    required this.touchLineColor,
    required this.totalBars,
    required this.minutesPerBar,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final barWidth = size.width / totalBars;

    for (final event in events) {
      if (event.type == FeedItemType.glucose) continue;

      final eventHour = event.timestamp.hour;
      final eventMinute = event.timestamp.minute;
      final eventSecond = event.timestamp.second;

      // 이벤트 지속시간 (시간 단위)
      final duration = getEventDuration(event);

      double eventIndex;
      double durationInBars;
      double halfWidth;

      // 분 단위로 통일된 공식
      eventIndex = (eventHour * 60 + eventMinute + eventSecond / 60.0) / minutesPerBar;
      durationInBars = duration * 60.0 / minutesPerBar;
      halfWidth = (durationInBars / 2) * 0.5;

      // 이벤트 범위 계산
      final x1 = (eventIndex - halfWidth).clamp(0.0, totalBars.toDouble());
      final x2 = (eventIndex + halfWidth).clamp(0.0, totalBars.toDouble());

      // 픽셀 좌표로 변환
      final left = x1 * barWidth;
      final right = x2 * barWidth;

      // 차트 전체 높이를 채우는 사각형 그리기 (bottomTitles 영역 제외)
      final rect = Rect.fromLTRB(
        left,
        0,
        right,
        size.height - 24, // bottomTitles reservedSize 제외
      );

      final paint = Paint()
        ..color = getEventColor(event.type).withValues(alpha: 0.2)
        ..style = PaintingStyle.fill;

      canvas.drawRect(rect, paint);

      // 레이블 텍스트 그리기
      final labelText = ' ${getEventLabel(event.type)} ';
      final textSpan = TextSpan(
        text: labelText,
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          backgroundColor: cardColor.withValues(alpha: 0.8),
        ),
      );

      final textPainter = TextPainter(
        text: textSpan,
        textDirection: ui.TextDirection.ltr,
        textAlign: TextAlign.center,
      );

      textPainter.layout();

      // 레이블을 배경 중앙 상단에 배치
      final centerX = (left + right) / 2;
      final labelX = centerX - (textPainter.width / 2);
      final labelY = 4.0; // 상단에서 4px 아래

      textPainter.paint(canvas, Offset(labelX, labelY));
    }

    // 터치된 바의 수직선 그리기
    if (touchedBarIndex != null) {
      final barWidth = size.width / totalBars;
      final x = touchedBarIndex! * barWidth + (barWidth / 2); // 바의 중앙

      final linePaint = Paint()
        ..color = touchLineColor.withValues(alpha: 0.8)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke;

      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height - 24), // bottomTitles reservedSize 제외
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _EventBackgroundPainter oldDelegate) {
    return oldDelegate.events != events ||
        oldDelegate.chartMinY != chartMinY ||
        oldDelegate.chartMaxY != chartMaxY ||
        oldDelegate.touchedBarIndex != touchedBarIndex ||
        oldDelegate.totalBars != totalBars ||
        oldDelegate.minutesPerBar != minutesPerBar;
  }
}

/// 비교 기간 평균 혈당을 선으로 그리는 CustomPainter
class _ComparisonLinePainter extends CustomPainter {
  final Map<int, double> compAverage;
  final double chartMinY;
  final double chartMaxY;
  final int totalBars;
  final Color color;

  _ComparisonLinePainter({
    required this.compAverage,
    required this.chartMinY,
    required this.chartMaxY,
    required this.totalBars,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final chartHeight = size.height - 24; // bottomTitles 영역 제외
    final barSlotWidth = size.width / totalBars;
    final yRange = chartMaxY - chartMinY;

    final linePaint = Paint()
      ..color = color.withValues(alpha: 0.55)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    final dotPaint = Paint()
      ..color = color.withValues(alpha: 0.45)
      ..style = PaintingStyle.fill;

    final path = Path();
    bool firstPoint = true;

    for (int i = 0; i < totalBars; i++) {
      final value = compAverage[i];
      if (value == null) {
        firstPoint = true;
        continue;
      }
      final x = i * barSlotWidth + barSlotWidth / 2;
      final y = chartHeight * (1 - (value - chartMinY) / yRange);

      if (firstPoint) {
        path.moveTo(x, y);
        firstPoint = false;
      } else {
        path.lineTo(x, y);
      }
      canvas.drawCircle(Offset(x, y), 2.5, dotPaint);
    }
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _ComparisonLinePainter oldDelegate) {
    return oldDelegate.compAverage != compAverage ||
        oldDelegate.totalBars != totalBars ||
        oldDelegate.chartMinY != chartMinY ||
        oldDelegate.chartMaxY != chartMaxY ||
        oldDelegate.color != color;
  }
}

class _PieChartPainter extends CustomPainter {
  final double veryLowRatio;
  final double lowRatio;
  final double normalRatio;
  final double highRatio;
  final double veryHighRatio;
  final Color holeColor;
  final bool hasData;
  final Color emptyColor;
  final double animationValue;

  _PieChartPainter({
    required this.veryLowRatio,
    required this.lowRatio,
    required this.normalRatio,
    required this.highRatio,
    required this.veryHighRatio,
    required this.holeColor,
    required this.hasData,
    required this.emptyColor,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    final innerRadius = radius * 0.6;

    // 데이터가 없으면 회색 원 그리기
    if (!hasData) {
      final greyPaint = Paint()
        ..color = emptyColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, radius, greyPaint);

      // 중앙 구멍 (도넛 차트)
      final holePaint = Paint()
        ..color = holeColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, innerRadius, holePaint);
      return;
    }

    double startAngle = -math.pi / 2;

    void drawRoundedArc(double sweepAngle, Color color) {
      if (sweepAngle <= 0) return;

      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      final path = Path();

      // 바깥쪽 호
      final outerRect = Rect.fromCircle(center: center, radius: radius);
      path.addArc(outerRect, startAngle, sweepAngle);

      // 안쪽 호 (역방향)
      final innerRect = Rect.fromCircle(center: center, radius: innerRadius);
      path.arcTo(innerRect, startAngle + sweepAngle, -sweepAngle, false);
      path.close();

      canvas.drawPath(path, paint);
    }

    // 매우 저혈당
    if (veryLowRatio > 0) {
      final sweepAngle = veryLowRatio * 2 * math.pi * animationValue;
      drawRoundedArc(sweepAngle, AppTheme.glucoseVeryLow);
      startAngle += sweepAngle;
    }

    // 저혈당
    if (lowRatio > 0) {
      final sweepAngle = lowRatio * 2 * math.pi * animationValue;
      drawRoundedArc(sweepAngle, AppTheme.glucoseLow);
      startAngle += sweepAngle;
    }

    // 정상
    if (normalRatio > 0) {
      final sweepAngle = normalRatio * 2 * math.pi * animationValue;
      drawRoundedArc(sweepAngle, AppTheme.glucoseNormal);
      startAngle += sweepAngle;
    }

    // 고혈당
    if (highRatio > 0) {
      final sweepAngle = highRatio * 2 * math.pi * animationValue;
      drawRoundedArc(sweepAngle, AppTheme.glucoseHigh);
      startAngle += sweepAngle;
    }

    // 매우 고혈당
    if (veryHighRatio > 0) {
      final sweepAngle = veryHighRatio * 2 * math.pi * animationValue;
      drawRoundedArc(sweepAngle, AppTheme.glucoseVeryHigh);
    }

    // 중앙 구멍 (도넛 차트)
    final holePaint = Paint()
      ..color = holeColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, innerRadius, holePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
