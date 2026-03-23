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
import 'package:glu_butler/models/glucose_record.dart';
import 'package:glu_butler/models/glucose_range_settings.dart';
import 'package:glu_butler/models/feed_item.dart';
import 'package:glu_butler/services/settings_service.dart';
import 'package:glu_butler/providers/feed_provider.dart';
import 'package:glu_butler/features/home/painters/chart_painters.dart';

/// 홈 화면 혈당 추이 차트 카드
///
/// 핀치 줌, 단일 터치 패닝, 비교 기간 오버레이를 포함합니다.
class GlucoseChartCard extends StatefulWidget {
  const GlucoseChartCard({
    super.key,
    required this.records,
    required this.isToday,
    required this.selectedDate,
    required this.animation,
  });

  final List<GlucoseRecord> records;
  final bool isToday;
  final DateTime selectedDate;
  final Animation<double> animation;

  @override
  State<GlucoseChartCard> createState() => _GlucoseChartCardState();
}

class _GlucoseChartCardState extends State<GlucoseChartCard> {
  // 차트 터치 상태
  int? _touchedBarIndex;

  // Y축 캐시 — 줌인/줌아웃 시에만 재계산 (탭·스크롤 모두 고정)
  double _cachedMinutesPerBar = -1.0; // sentinel: 최초 계산 유도
  List<GlucoseRecord>? _cachedYRecords;
  double _displayMaxY = 300.0;
  double _displayMinY = 50.0;

  // Y축 범위 사전 계산용 비교 데이터 (표시 X, Y범위만)
  List<GlucoseRecord> _preloadedCompRecords = [];
  bool _yRangeIncludesComp = false;

  // 차트 줌 설정 (60 = 1시간단위/기본, 10 = 최대확대/10분단위)
  double _minutesPerBar = 60.0;
  double _pinchStartMinutesPerBar = 60.0;
  double _pinchStartDistance = 0.0;
  double _pinchCenterX = 0.0;           // 핀치 중점 X (뷰포트 기준)
  double _pinchStartScrollOffset = 0.0; // 핀치 시작 시 스크롤 오프셋
  double _chartAvailableWidth = 300.0;  // 차트 너비 (Y축 제외)
  double _chartScrollOffset = 0.0;      // Transform.translate 기반 스크롤 오프셋
  bool _isPinching = false;             // 핀치 중 단일 터치 패닝 차단
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
  final List<GlobalKey> _chipKeys = List.generate(7, (_) => GlobalKey());
  final GlobalKey _chipsRowKey = GlobalKey();
  final ScrollController _chipsScrollController = ScrollController();

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

  @override
  void initState() {
    super.initState();
    // Y축 범위 사전 계산: 첫 번째 비교 기간 데이터를 백그라운드로 로드
    if (widget.isToday) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _preloadCompForYRange());
    }
  }

  @override
  void dispose() {
    _chipsScrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(GlucoseChartCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 날짜가 바뀌면 스크롤/줌/Y축 프리로드 리셋
    if (oldWidget.selectedDate != widget.selectedDate) {
      setState(() {
        _chartScrollOffset = 0.0;
        _preloadedCompRecords = [];
        _yRangeIncludesComp = false;
      });
      if (widget.isToday) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _preloadCompForYRange());
      }
    }
  }

  /// Y축 범위 사전 계산용 비교 데이터 로드 (표시 X, Y범위만 계산)
  Future<void> _preloadCompForYRange() async {
    if (!mounted || !widget.isToday) return;
    final syncPeriod = context.read<SettingsService>().syncPeriod;
    final available = [
      for (int i = 0; i < _comparisonPeriods.length; i++)
        if (_comparisonPeriods[i].$2 <= syncPeriod) i,
    ];
    if (available.isEmpty) return;

    final (_, startDaysAgo, endDaysAgo) = _comparisonPeriods[available.first];
    final feedProvider = context.read<FeedProvider>();
    final records = <GlucoseRecord>[];
    for (int d = endDaysAgo; d <= startDaysAgo; d++) {
      final date = widget.selectedDate.subtract(Duration(days: d));
      try {
        records.addAll(await feedProvider.getHomeGraphData(date));
      } catch (_) {}
    }
    if (!mounted) return;
    // 유저가 아직 탭 전일 때만 Y축 재계산 트리거
    if (_comparisonPeriodIndex == null) {
      setState(() {
        _preloadedCompRecords = records;
        _yRangeIncludesComp = false; // 재계산 유도
      });
    } else {
      _preloadedCompRecords = records;
    }
  }

  /// 핀치 종료: 고정된 막대 수 해제, _isPinching 리셋
  void _endPinch() {
    setState(() {
      _isPinching = false;
      // 절반 이상 줌아웃된 경우 기본값(24시간 전체)으로 스냅
      if (_minutesPerBar > 48.0) {
        _minutesPerBar = 60.0;
        _chartScrollOffset = 0.0;
      } else {
        // 스크롤이 현재 줌의 최대치를 초과하지 않도록 클램프
        final zf = math.pow(60.0 / _minutesPerBar, 1.5);
        final maxScroll = math.max(0.0, _chartAvailableWidth * (zf - 1));
        _chartScrollOffset = _chartScrollOffset.clamp(0.0, maxScroll);
      }
    });
  }

  /// 차트 탭 시 비교 기간 순환 (없음 → 이번주 → 지난주 → ... → 없음)
  void _cycleComparisonPeriod() {
    if (!widget.isToday) return;
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
      _scrollToChip(available.first);
      _loadComparisonData(available.first);
    } else {
      final pos = available.indexOf(_comparisonPeriodIndex!);
      if (pos == -1 || pos == available.length - 1) {
        setState(() {
          _comparisonPeriodIndex = null;
          _comparisonRecords = [];
          _isLoadingComparison = false;
        });
        if (_chipsScrollController.hasClients) {
          _chipsScrollController.jumpTo(0);
        }
      } else {
        final next = available[pos + 1];
        setState(() {
          _comparisonPeriodIndex = next;
          _comparisonRecords = [];
        });
        _scrollToChip(next);
        _loadComparisonData(next);
      }
    }
  }

  void _scrollToChip(int periodIndex) {
    final syncPeriod = context.read<SettingsService>().syncPeriod;
    final available = [
      for (int i = 0; i < _comparisonPeriods.length; i++)
        if (_comparisonPeriods[i].$2 <= syncPeriod) i,
    ];
    final isLast = available.isNotEmpty && available.last == periodIndex;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_chipsScrollController.hasClients) return;
      if (_comparisonPeriodIndex != periodIndex) return;
      if (isLast) {
        _chipsScrollController.animateTo(
          _chipsScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
        return;
      }
      final chipBox =
          _chipKeys[periodIndex].currentContext?.findRenderObject() as RenderBox?;
      final rowBox =
          _chipsRowKey.currentContext?.findRenderObject() as RenderBox?;
      if (chipBox == null || rowBox == null) return;
      final chipInRow = rowBox.globalToLocal(chipBox.localToGlobal(Offset.zero));
      final chipCenter = chipInRow.dx + chipBox.size.width / 2;
      final viewport = _chipsScrollController.position.viewportDimension;
      final target = (chipCenter - viewport / 2).clamp(
        0.0,
        _chipsScrollController.position.maxScrollExtent,
      );
      _chipsScrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  /// 비교 기간 데이터 로드
  Future<void> _loadComparisonData(int periodIndex) async {
    final (_, startDaysAgo, endDaysAgo) = _comparisonPeriods[periodIndex];
    setState(() => _isLoadingComparison = true);

    final feedProvider = context.read<FeedProvider>();
    final records = <GlucoseRecord>[];

    for (int daysAgo = endDaysAgo; daysAgo <= startDaysAgo; daysAgo++) {
      final date = widget.selectedDate.subtract(Duration(days: daysAgo));
      try {
        final dayRecords = await feedProvider.getHomeGraphData(date);
        records.addAll(dayRecords);
      } catch (_) {}
    }

    if (!mounted) return;
    // 로드 중에 기간이 바뀌었으면 결과 버림
    if (_comparisonPeriodIndex != periodIndex) {
      setState(() => _isLoadingComparison = false);
      return;
    }
    setState(() {
      _comparisonRecords = records;
      _isLoadingComparison = false;
    });
    _scrollToChip(periodIndex);
  }

  String _getPeriodLabel(int index, AppLocalizations l10n) {
    switch (index) {
      case 0:
        return l10n.compThisWeek;
      case 1:
        return l10n.compLastWeek;
      case 2:
        return l10n.comp3WeeksAgo;
      case 3:
        return l10n.comp1MonthAgo;
      case 4:
        return l10n.comp2MonthsAgo;
      case 5:
        return l10n.comp3MonthsAgo;
      case 6:
        return l10n.comp6MonthsAgo;
      default:
        return _comparisonPeriods[index].$1;
    }
  }

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

  IconData _getEventIcon(FeedItemType type) {
    switch (type) {
      case FeedItemType.meal:
        return Icons.restaurant;
      case FeedItemType.exercise:
        return Icons.local_fire_department;
      case FeedItemType.insulin:
        return Icons.vaccines;
      default:
        return Icons.circle;
    }
  }

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

  void _showChartInfoModal(BuildContext context) async {
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
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
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
                    l10n.trendInfoTitle,
                    style: context.textStyles.tileTitle.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 60),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                              l10n.trendInfoPeriodTitle,
                              style: context.textStyles.tileTitle.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              l10n.trendInfoPeriodDesc,
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
                              l10n.trendInfoZoomTitle,
                              style: context.textStyles.tileTitle.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              l10n.trendInfoZoomDesc,
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(16),
      clipBehavior: Clip.hardEdge,
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
            children: [
              Text(
                l10n.todaysGlucose,
                style: context.textStyles.tileTitle.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              GestureDetector(
                onTap: () => _showChartInfoModal(context),
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
              const Spacer(),
              if (widget.isToday)
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
                  _pinchCenterX = ((positions[0].dx + positions[1].dx) / 2 - 35)
                      .clamp(0.0, _chartAvailableWidth);
                  // 완전 줌아웃 상태이면 stale 스크롤을 여기서 리셋
                  if (_minutesPerBar >= 60.0) _chartScrollOffset = 0.0;
                  _pinchStartScrollOffset = _chartScrollOffset;
                  setState(() => _isPinching = true);
                }
              },
              onPointerMove: (event) {
                if (!_activePointers.containsKey(event.pointer)) return;
                _activePointers[event.pointer] = event.localPosition;
                if (_activePointers.length == 2 && _pinchStartDistance > 0) {
                  final positions = _activePointers.values.toList();
                  final currentDistance = (positions[0] - positions[1]).distance;
                  final scale = currentDistance / _pinchStartDistance;
                  final newMinutes =
                      (_pinchStartMinutesPerBar / scale).clamp(10.0, 60.0);
                  if ((newMinutes - _minutesPerBar).abs() > 0.05 ||
                      (newMinutes == 60.0 && _minutesPerBar < 60.0)) {
                    // 줌+스크롤 동기 업데이트 — X 고정
                    // 완전 줌아웃(60min)이면 스크롤 0으로 리셋해서 24시간 전체 표시
                    final double newScrollOffset;
                    if (newMinutes >= 60.0) {
                      newScrollOffset = 0.0;
                    } else {
                      final oldZoom =
                          math.pow(60.0 / _pinchStartMinutesPerBar, 1.5);
                      final newZoom = math.pow(60.0 / newMinutes, 1.5);
                      final contentPoint =
                          _pinchStartScrollOffset + _pinchCenterX;
                      final maxScroll =
                          math.max(0.0, _chartAvailableWidth * (newZoom - 1));
                      newScrollOffset =
                          (contentPoint * (newZoom / oldZoom) - _pinchCenterX)
                              .clamp(0.0, maxScroll);
                    }
                    setState(() {
                      _minutesPerBar = newMinutes;
                      _chartScrollOffset = newScrollOffset;
                      _touchedBarIndex = null;
                    });
                  }
                } else if (_activePointers.length == 1 &&
                    !_isPinching &&
                    _minutesPerBar < 60) {
                  // 단일 터치 패닝
                  final newZoom = math.pow(60.0 / _minutesPerBar, 1.5);
                  final maxScroll =
                      math.max(0.0, _chartAvailableWidth * (newZoom - 1));
                  setState(() {
                    _chartScrollOffset =
                        (_chartScrollOffset - event.delta.dx)
                            .clamp(0.0, maxScroll);
                  });
                }
              },
              onPointerUp: (event) {
                _activePointers.remove(event.pointer);
                if (_activePointers.length < 2) {
                  _pinchStartDistance = 0.0;
                  if (_isPinching) _endPinch();
                }
              },
              onPointerCancel: (event) {
                _activePointers.remove(event.pointer);
                if (_activePointers.length < 2) {
                  _pinchStartDistance = 0.0;
                  if (_isPinching) _endPinch();
                }
              },
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return AnimatedBuilder(
                    animation: widget.animation,
                    builder: (context, child) {
                      return _buildGlucoseChart(context, l10n, constraints.maxWidth);
                    },
                  );
                },
              ),
            ),
          ),
          if (widget.isToday) ...[
            const SizedBox(height: 12),
            // 비교 기간 칩
            _buildComparisonChips(context, l10n),
          ],
        ],
      ),
    );
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
      controller: _chipsScrollController,
      scrollDirection: Axis.horizontal,
      child: Row(
        key: _chipsRowKey,
        mainAxisSize: MainAxisSize.min,
        children: available.map((i) {
          final label = _getPeriodLabel(i, l10n);
          final color = _periodColors[i];
          final isSelected = _comparisonPeriodIndex == i;
          final isLast = i == available.last;
          return Padding(
            key: _chipKeys[i],
            padding: EdgeInsets.only(right: isLast ? 0 : 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? color : color.withValues(alpha: 0.3),
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
                              : context.colors.textSecondary.withValues(
                                  alpha: 0.4,
                                ),
                        ),
                      ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildGlucoseChart(
      BuildContext context, AppLocalizations l10n, double actualWidth) {
    if (widget.records.isEmpty) {
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

    // 데이터 집계 / 막대 수 계산용 (정수, 안정적인 슬롯 경계)
    final minPerBar = _minutesPerBar.round().clamp(10, 60);
    final totalBars = (24 * 60 / minPerBar).round();
    final timeData = <int, List<double>>{};
    for (final record in widget.records) {
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
    final averageLineColor = isDarkMode ? context.colors.textPrimary : Colors.black;

    // 화면 너비 계산: Y축 동적 범위 계산에 먼저 필요
    final availableWidth = actualWidth - 35; // Y축 너비 제외
    if (_chartAvailableWidth != availableWidth) {
      _chartAvailableWidth = availableWidth;
    }
    // 줌/너비 계산은 _minutesPerBar 연속값 사용 (부드러운 확대/축소)
    final zoomFactor = 60.0 / _minutesPerBar;
    final chartWidth = availableWidth * math.pow(zoomFactor, 1.5);
    final effectiveScroll = _chartScrollOffset.clamp(
        0.0, math.max(0.0, chartWidth - availableWidth).toDouble());

    // 비교 데이터 슬롯 평균 사전 계산 (Y축 범위 계산에 사용)
    final compForYRecords = _comparisonRecords.isNotEmpty
        ? _comparisonRecords
        : _preloadedCompRecords;
    final compAverageForY = <int, double>{};
    if (compForYRecords.isNotEmpty) {
      final compTimeDataForY = <int, List<double>>{};
      for (final record in compForYRecords) {
        final idx =
            (record.timestamp.hour * 60 + record.timestamp.minute) ~/ minPerBar;
        compTimeDataForY.putIfAbsent(idx, () => []).add(record.valueIn('mg/dL'));
      }
      compTimeDataForY.forEach((idx, vals) {
        compAverageForY[idx] = vals.reduce((a, b) => a + b) / vals.length;
      });
    }

    // Y축 범위 캐시 조건:
    // - 줌인/줌아웃 시
    // - records 변경 시
    // - 프리로드 완료 시 (탭 전 최초 1회, 이후 탭·스크롤 시 고정)
    final zoomedIn = _minutesPerBar < 59.0;
    final needsYUpdate = !_yRangeIncludesComp && _preloadedCompRecords.isNotEmpty;
    if (_cachedMinutesPerBar != _minutesPerBar ||
        _cachedYRecords != widget.records ||
        needsYUpdate) {
      _cachedMinutesPerBar = _minutesPerBar;
      _cachedYRecords = widget.records;
      _yRangeIncludesComp = true;

      List<double> yVals;

      if (zoomedIn) {
        // 줌인: 보이는 오늘 슬롯 평균 + 비교 슬롯 평균 전체
        final visStartMin = effectiveScroll / chartWidth * (24 * 60) - minPerBar;
        final visEndMin =
            (effectiveScroll + availableWidth) / chartWidth * (24 * 60) + minPerBar;
        final visibleSlots = timeAverage.entries
            .where((e) => e.key * minPerBar >= visStartMin &&
                e.key * minPerBar <= visEndMin)
            .map((e) => e.value);
        final todayVals = visibleSlots.isNotEmpty
            ? visibleSlots.toList()
            : timeAverage.values.toList();
        yVals = [...todayVals, ...compAverageForY.values];
      } else {
        // 기본 뷰: 오늘 슬롯 평균 + 비교 슬롯 평균 전체
        yVals = [...timeAverage.values, ...compAverageForY.values];
      }

      if (yVals.isEmpty) yVals = [100.0];
      final dataMax = yVals.reduce(math.max);
      final dataMin = yVals.reduce(math.min);

      const yCandidates = [70, 100, 120, 150, 180, 200, 220, 250, 280, 300, 320];
      final rawMax = math.max(180.0, dataMax + 20);
      final rawMin = dataMin - 20;
      // 후보값으로 스냅: max는 rawMax 이상 중 최솟값, min은 rawMin 이하 중 최댓값
      _displayMaxY = yCandidates
          .where((v) => v >= rawMax)
          .map((v) => v.toDouble())
          .fold<double>(320.0, (prev, v) => v < prev ? v : prev);
      _displayMinY = yCandidates
          .where((v) => v <= rawMin)
          .map((v) => v.toDouble())
          .fold<double>(70.0, (prev, v) => v > prev ? v : prev);
    }

    final chartMaxY = _displayMaxY;
    final chartMinY = _displayMinY;

    // 하루 전체 평균 혈당
    final values = widget.records.map((e) => e.valueIn('mg/dL')).toList();
    final averageGlucose = values.reduce((a, b) => a + b) / values.length;

    // 해당 날짜의 이벤트 데이터 가져오기 (식사, 운동, 인슐린)
    final feedProvider = context.watch<FeedProvider>();
    final startOfDay = DateTime(
      widget.selectedDate.year,
      widget.selectedDate.month,
      widget.selectedDate.day,
    );
    final endOfDay = startOfDay.add(const Duration(days: 1));
    final eventsInRange = feedProvider.items.where((item) {
      return item.timestamp.isAfter(startOfDay) &&
          item.timestamp.isBefore(endOfDay) &&
          (item.type == FeedItemType.meal ||
              item.type == FeedItemType.exercise ||
              item.type == FeedItemType.insulin);
    }).toList();

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
    // min/max는 원본 실제 수치 기준 (줌 무관 고정, 라인은 평균치라 항상 이 범위 내)
    final double? compMin;
    final double? compMax;
    if (_comparisonRecords.isEmpty) {
      compMin = null;
      compMax = null;
    } else {
      final rawVals = _comparisonRecords.map((r) => r.valueIn('mg/dL'));
      compMin = rawVals.reduce(math.min);
      compMax = rawVals.reduce(math.max);
    }

    // 차트 위젯 생성
    final chartStack = Stack(
      children: [
        // 이벤트 배경 + 터치 라인 레이어 (CustomPaint)
        CustomPaint(
          painter: EventBackgroundPainter(
            events: _comparisonPeriodIndex != null ? [] : eventsInRange,
            chartMinY: chartMinY,
            chartMaxY: chartMaxY,
            getEventColor: _getEventColor,
            getEventLabelColor: _getEventColor,
            getEventLabel: (type) => _getEventLabel(type, l10n),
            getEventIcon: _getEventIcon,
            getEventDuration: _getEventDuration,
            cardColor: context.colors.card,
            textColor: isDarkMode ? context.colors.textPrimary : Colors.black,
            touchedBarIndex: _touchedBarIndex,
            touchLineColor: context.colors.textPrimary,
            totalBars: totalBars,
            minutesPerBar: minPerBar.toDouble(),
          ),
          child: Container(),
        ),
        // 비교 기간 오버레이 라인 (BarChart 아래에 배치하여 툴팁이 위에 오도록)
        if (compAverage.isNotEmpty && _comparisonPeriodIndex != null)
          IgnorePointer(
            child: ClipRect(
              child: CustomPaint(
                painter: ComparisonLinePainter(
                  compAverage: compAverage,
                  chartMinY: chartMinY,
                  chartMaxY: chartMaxY,
                  totalBars: totalBars,
                  color: _periodColors[_comparisonPeriodIndex!],
                  compMin: compMin,
                  compMax: compMax,
                  unit: settings.unit,
                  viewportWidth: availableWidth,
                  scrollOffset: effectiveScroll,
                ),
                child: Container(),
              ),
            ),
          ),
        // 차트 레이어
        BarChart(
          duration: Duration.zero,
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
                  strokeWidth: 1,
                  dashArray: [8, 4],
                  label: HorizontalLineLabel(
                    show: true,
                    alignment: Alignment.topRight,
                    padding: const EdgeInsets.only(right: 8, bottom: 4),
                    style: TextStyle(
                      color: averageLineColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      backgroundColor:
                          context.colors.card.withValues(alpha: 0.8),
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
                if (event is FlTapUpEvent) {
                  setState(() {
                    _touchedBarIndex = null;
                  });
                  if (barTouchResponse?.spot == null) {
                    _cycleComparisonPeriod();
                  }
                } else if (event is FlPanEndEvent || event is FlLongPressEnd) {
                  setState(() {
                    _touchedBarIndex = null;
                  });
                } else if (barTouchResponse != null &&
                    barTouchResponse.spot != null) {
                  setState(() {
                    _touchedBarIndex =
                        barTouchResponse.spot!.touchedBarGroupIndex;
                  });
                }
              },
              touchTooltipData: BarTouchTooltipData(
                fitInsideVertically: true,
                tooltipPadding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
                getTooltipColor: (group) => Colors.white,
                tooltipBorder: BorderSide(
                  color: Colors.grey.withValues(alpha: 0.3),
                  width: 1.0,
                ),
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  final index = group.x.toInt();
                  final value = rod.toY;

                  final totalMinutes = index * minPerBar;
                  final hour = totalMinutes ~/ 60;
                  final minute = totalMinutes % 60;
                  final timeText =
                      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

                  return BarTooltipItem(
                    '$timeText\n',
                    const TextStyle(
                      color: Color(0xFF333333),
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
              horizontalInterval: 1,
              checkToShowHorizontalLine: (value) {
                const candidates = [70, 100, 120, 150, 180, 200, 220, 250, 280, 300, 320];
                return candidates.contains(value.round());
              },
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: context.colors.divider.withValues(alpha: 0.3),
                  strokeWidth: 1,
                );
              },
            ),
            borderData: FlBorderData(show: false),
            barGroups: List.generate(totalBars, (index) {
              final value = timeAverage[index];
              // 막대 두께는 기본 줌(60분/24칸) 슬롯 기준으로 고정
              final barWidth = (availableWidth / 24 * 0.55).clamp(4.0, 14.0);

              if (value == null) {
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
                    toY: value * widget.animation.value,
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
                  painter: YAxisPainter(
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
        // 차트 영역: 항상 OverflowBox + Transform.translate
        Expanded(
          child: ClipRect(
            child: OverflowBox(
              alignment: Alignment.centerLeft,
              minWidth: chartWidth,
              maxWidth: chartWidth,
              child: Transform.translate(
                offset: Offset(-effectiveScroll, 0),
                child: SizedBox(width: chartWidth, child: chartStack),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
