import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:glu_butler/l10n/app_localizations.dart';
import 'package:glu_butler/core/theme/app_theme.dart';
import 'package:glu_butler/core/theme/app_text_styles.dart';
import 'package:glu_butler/repositories/glucose_repository.dart';
import 'package:glu_butler/repositories/report_repository.dart';
import 'package:glu_butler/services/settings_service.dart';
import 'package:glu_butler/models/report.dart';

/// 날짜 범위 선택 모달
///
/// 리포트 생성을 위한 시작일/종료일 선택 기능 제공
class DateRangePickerModal extends StatefulWidget {
  const DateRangePickerModal({super.key});

  /// 모달 표시 및 선택된 날짜 범위 반환
  ///
  /// Returns: [startDate, endDate] 또는 null (취소 시)
  static Future<List<DateTime>?> show(BuildContext context) async {
    return await showModalBottomSheet<List<DateTime>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const DateRangePickerModal(),
    );
  }

  @override
  State<DateRangePickerModal> createState() => _DateRangePickerModalState();
}

class _DateRangePickerModalState extends State<DateRangePickerModal> {
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  DateTime _focusedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;

  final GlucoseRepository _glucoseRepository = GlucoseRepository();
  final ReportRepository _reportRepository = ReportRepository();
  Set<DateTime> _datesWithData = {};
  List<Report> _existingReports = [];

  late Future<void> _initializationFuture;

  @override
  void initState() {
    super.initState();
    _initializationFuture = _initializeData();
  }

  Future<void> _initializeData() async {
    // 먼저 리포트를 로드하고 시작일 설정
    await _loadExistingReportsAndSetStartDate();
    // 그 다음 혈당 데이터 로드
    await _loadDatesWithData();
  }

  Future<void> _loadExistingReportsAndSetStartDate() async {
    // BuildContext를 async gap 전에 미리 읽기
    final settings = context.read<SettingsService>();

    // DB에서 모든 리포트 조회
    _existingReports = await _reportRepository.getAllReports();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (_existingReports.isNotEmpty) {
      // 가장 최근 리포트의 종료일 다음 날을 시작일로 설정
      final latestReport = _existingReports.first;
      final nextDay = DateTime(
        latestReport.endDate.year,
        latestReport.endDate.month,
        latestReport.endDate.day + 1,
      );

      // setState 없이 직접 값 설정 (initState에서 호출되므로)
      _rangeStart = nextDay;
      // focusedDay는 오늘보다 미래면 안되므로, 오늘과 nextDay 중 작은 값 사용
      _focusedDay = nextDay.isAfter(today) ? today : nextDay;

      debugPrint('[DateRangePickerModal] Auto-set start date to: $_rangeStart');
      debugPrint('[DateRangePickerModal] Focused day: $_focusedDay');
    } else {
      // 리포트가 없을 때: 서비스 시작일 - 7일을 시작일로 설정
      final serviceStartDate = settings.serviceStartDate;

      if (serviceStartDate != null) {
        // 서비스 시작일 - 7일
        final startDate = DateTime(
          serviceStartDate.year,
          serviceStartDate.month,
          serviceStartDate.day - 7,
        );

        _rangeStart = startDate;
        _focusedDay = startDate.isAfter(today) ? today : startDate;

        debugPrint('[DateRangePickerModal] First report - auto-set start date to: $_rangeStart (service start: $serviceStartDate)');
      }
    }
  }

  Future<void> _loadDatesWithData() async {
    final settings = context.read<SettingsService>();
    final syncPeriod = settings.syncPeriod;
    final now = DateTime.now();
    final startDate = now.subtract(Duration(days: syncPeriod));

    final records = await _glucoseRepository.fetch(
      startDate: startDate,
      endDate: now,
    );

    final datesSet = <DateTime>{};
    for (final record in records) {
      final date = DateTime(
        record.timestamp.year,
        record.timestamp.month,
        record.timestamp.day,
      );
      datesSet.add(date);
    }

    _datesWithData = datesSet;
  }

  /// 선택된 날짜 범위가 기존 리포트와 겹치는지 확인
  bool _hasOverlapWithExistingReports() {
    if (_rangeStart == null || _rangeEnd == null) return false;

    for (var report in _existingReports) {
      // 겹침 조건: A <= Y && B >= X
      // 새 리포트: _rangeStart ~ _rangeEnd
      // 기존 리포트: report.startDate ~ report.endDate
      final normalizedStart = DateTime(_rangeStart!.year, _rangeStart!.month, _rangeStart!.day);
      final normalizedEnd = DateTime(_rangeEnd!.year, _rangeEnd!.month, _rangeEnd!.day);
      final reportStart = DateTime(report.startDate.year, report.startDate.month, report.startDate.day);
      final reportEnd = DateTime(report.endDate.year, report.endDate.month, report.endDate.day);

      if ((normalizedStart.isBefore(reportEnd) || normalizedStart.isAtSameMomentAs(reportEnd)) &&
          (normalizedEnd.isAfter(reportStart) || normalizedEnd.isAtSameMomentAs(reportStart))) {
        return true;
      }
    }
    return false;
  }

  /// 겹치는 리포트의 날짜 범위를 반환
  String _getOverlappingReportRange() {
    if (_rangeStart == null || _rangeEnd == null) return '';

    for (var report in _existingReports) {
      final normalizedStart = DateTime(_rangeStart!.year, _rangeStart!.month, _rangeStart!.day);
      final normalizedEnd = DateTime(_rangeEnd!.year, _rangeEnd!.month, _rangeEnd!.day);
      final reportStart = DateTime(report.startDate.year, report.startDate.month, report.startDate.day);
      final reportEnd = DateTime(report.endDate.year, report.endDate.month, report.endDate.day);

      if ((normalizedStart.isBefore(reportEnd) || normalizedStart.isAtSameMomentAs(reportEnd)) &&
          (normalizedEnd.isAfter(reportStart) || normalizedEnd.isAtSameMomentAs(reportStart))) {
        final locale = Localizations.localeOf(context).toString();
        final isSameYear = report.startDate.year == report.endDate.year;

        String format = isSameYear ? 'd MMM' : 'd MMM y';
        final formatter = DateFormat(format, locale);

        return '${formatter.format(report.startDate)} - ${formatter.format(report.endDate)}';
      }
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return FutureBuilder<void>(
      future: _initializationFuture,
      builder: (context, snapshot) {
        // 로딩 중이면 로딩 인디케이터 표시
        if (snapshot.connectionState != ConnectionState.done) {
          return Container(
            decoration: BoxDecoration(
              color: AppTheme.iosBackground(context),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: const SafeArea(
              child: Center(
                child: CupertinoActivityIndicator(),
              ),
            ),
          );
        }

        return _buildContent(l10n);
      },
    );
  }

  Widget _buildContent(AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.iosBackground(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 드래그 핸들
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              // 제목
              Text(
                l10n.selectDateRange,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              // 선택된 날짜 범위 표시
              if (_rangeStart != null && _rangeEnd != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _getDateRangeString(),
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )
              else
                Text(
                  l10n.selectStartAndEndDate,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              const SizedBox(height: 20),

              // 달력
              TableCalendar(
                firstDay: DateTime.now().subtract(const Duration(days: 365)),
                lastDay: DateTime.now(),
                focusedDay: _focusedDay,
                calendarFormat: _calendarFormat,
                rangeStartDay: _rangeStart,
                rangeEndDay: _rangeEnd,
                rangeSelectionMode: RangeSelectionMode.enforced,
                // 날짜 활성화 조건
                enabledDayPredicate: (day) {
                  final normalizedDay = DateTime(day.year, day.month, day.day);

                  if (_existingReports.isNotEmpty) {
                    // 리포트가 있을 때: 마지막 리포트 종료일 이후 날짜만 활성화
                    final latestReport = _existingReports.first;
                    final lastReportEndDate = DateTime(
                      latestReport.endDate.year,
                      latestReport.endDate.month,
                      latestReport.endDate.day,
                    );
                    return normalizedDay.isAfter(lastReportEndDate);
                  } else {
                    // 리포트가 없을 때: 서비스 시작일 - 7일 이후 날짜만 활성화
                    final settings = context.read<SettingsService>();
                    final serviceStartDate = settings.serviceStartDate;

                    if (serviceStartDate != null) {
                      final minDate = DateTime(
                        serviceStartDate.year,
                        serviceStartDate.month,
                        serviceStartDate.day - 7,
                      );
                      return normalizedDay.isAfter(minDate) || normalizedDay.isAtSameMomentAs(minDate);
                    }

                    return true;
                  }
                },
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _focusedDay = focusedDay;
                    if (_rangeStart == null || _rangeEnd != null) {
                      // 새로운 범위 시작
                      _rangeStart = selectedDay;
                      _rangeEnd = null;
                    } else {
                      // 범위 종료
                      if (selectedDay.isBefore(_rangeStart!)) {
                        // 시작일보다 이전 날짜 선택 시 순서 바꿈
                        _rangeEnd = _rangeStart;
                        _rangeStart = selectedDay;
                      } else {
                        _rangeEnd = selectedDay;
                      }
                    }
                  });
                },
                onFormatChanged: (format) {
                  setState(() {
                    _calendarFormat = format;
                  });
                },
                onPageChanged: (focusedDay) {
                  _focusedDay = focusedDay;
                },
                // 커스텀 빌더로 빨간 점 표시
                calendarBuilders: CalendarBuilders(
                  defaultBuilder: (context, day, focusedDay) {
                    final normalizedDate = DateTime(day.year, day.month, day.day);
                    final hasData = _datesWithData.contains(normalizedDate);

                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${day.day}',
                            style: context.textStyles.tileSubtitle,
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: hasData ? Colors.red : Colors.transparent,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  todayBuilder: (context, day, focusedDay) {
                    final normalizedDate = DateTime(day.year, day.month, day.day);
                    final hasData = _datesWithData.contains(normalizedDate);

                    return Container(
                      margin: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${day.day}',
                              style: context.textStyles.tileSubtitle.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: hasData ? Colors.red : Colors.transparent,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  rangeStartBuilder: (context, day, focusedDay) {
                    final normalizedDate = DateTime(day.year, day.month, day.day);
                    final hasData = _datesWithData.contains(normalizedDate);

                    return Container(
                      margin: const EdgeInsets.all(7),
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${day.day}',
                              style: context.textStyles.tileSubtitle.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: hasData ? Colors.white : Colors.transparent,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  rangeEndBuilder: (context, day, focusedDay) {
                    final normalizedDate = DateTime(day.year, day.month, day.day);
                    final hasData = _datesWithData.contains(normalizedDate);

                    return Container(
                      margin: const EdgeInsets.all(7),
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${day.day}',
                              style: context.textStyles.tileSubtitle.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: hasData ? Colors.white : Colors.transparent,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  withinRangeBuilder: (context, day, focusedDay) {
                    final normalizedDate = DateTime(day.year, day.month, day.day);
                    final hasData = _datesWithData.contains(normalizedDate);

                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${day.day}',
                            style: context.textStyles.tileSubtitle.copyWith(
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: hasData ? Colors.red : Colors.transparent,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                // 스타일링
                calendarStyle: CalendarStyle(
                  rangeHighlightColor: AppTheme.primaryColor.withOpacity(0.2),
                  rangeStartDecoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    shape: BoxShape.circle,
                  ),
                  rangeEndDecoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    shape: BoxShape.circle,
                  ),
                  todayDecoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    shape: BoxShape.circle,
                  ),
                  withinRangeTextStyle: TextStyle(
                    color: AppTheme.primaryColor,
                  ),
                  outsideDaysVisible: false,
                ),
                headerStyle: HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  leftChevronIcon: Icon(
                    Icons.chevron_left,
                    color: AppTheme.primaryColor,
                  ),
                  rightChevronIcon: Icon(
                    Icons.chevron_right,
                    color: AppTheme.primaryColor,
                  ),
                ),
                daysOfWeekStyle: DaysOfWeekStyle(
                  weekdayStyle: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                  weekendStyle: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 리포트 생성 버튼
              SizedBox(
                width: double.infinity,
                child: CupertinoButton(
                  onPressed: _rangeStart != null && _rangeEnd != null
                      ? () {
                          // 겹침 검증
                          if (_hasOverlapWithExistingReports()) {
                            final overlappingRange = _getOverlappingReportRange();
                            showCupertinoDialog(
                              context: context,
                              builder: (context) => CupertinoAlertDialog(
                                title: const Text('오류'),
                                content: Text(
                                  '이미 해당 기간의 리포트가 존재합니다.\n\n$overlappingRange',
                                ),
                                actions: [
                                  CupertinoDialogAction(
                                    child: const Text('확인'),
                                    onPressed: () => Navigator.of(context).pop(),
                                  ),
                                ],
                              ),
                            );
                            return;
                          }

                          // 겹치지 않으면 날짜 범위 반환
                          Navigator.of(context).pop([_rangeStart!, _rangeEnd!]);
                        }
                      : null,
                  color: _rangeStart != null && _rangeEnd != null
                      ? AppTheme.primaryColor
                      : Colors.grey[300],
                  disabledColor: Colors.grey[300]!,
                  borderRadius: BorderRadius.circular(12),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    l10n.generateReport,
                    style: TextStyle(
                      color: _rangeStart != null && _rangeEnd != null
                          ? Colors.white
                          : Colors.grey[500],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getDateRangeString() {
    if (_rangeStart == null || _rangeEnd == null) return '';

    final locale = Localizations.localeOf(context).toString();
    final isSameYear = _rangeStart!.year == _rangeEnd!.year;

    // 시작일과 종료일의 년도가 같으면 년도 생략
    // 다르면 년도 포함
    String startFormat;
    String endFormat;

    if (isSameYear) {
      // 같은 년도: "24 Dec - 27 Dec"
      startFormat = 'd MMM';
      endFormat = 'd MMM';
    } else {
      // 다른 년도: "24 Dec 2024 - 3 Jan 2025"
      startFormat = 'd MMM y';
      endFormat = 'd MMM y';
    }

    final startFormatter = DateFormat(startFormat, locale);
    final endFormatter = DateFormat(endFormat, locale);

    final start = startFormatter.format(_rangeStart!);
    final end = endFormatter.format(_rangeEnd!);

    return '$start - $end';
  }
}
