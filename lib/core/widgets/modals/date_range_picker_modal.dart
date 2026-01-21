import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:glu_butler/l10n/app_localizations.dart';
import 'package:glu_butler/core/theme/app_theme.dart';
import 'package:glu_butler/core/theme/app_text_styles.dart';
import 'package:glu_butler/core/theme/app_colors.dart';
import 'package:glu_butler/repositories/glucose_repository.dart';
import 'package:glu_butler/repositories/report_repository.dart';
import 'package:glu_butler/services/settings_service.dart';
import 'package:glu_butler/models/report.dart';

/// 날짜 범위 선택 모달
///
/// 리포트 생성을 위한 시작일/종료일 선택 기능 제공
class DateRangePickerModal extends StatefulWidget {
  const DateRangePickerModal({super.key});

  // 리포트 생성 최소 기간 (일)
  static const int minReportDays = 3;

  // 첫 리포트 기간 (일)
  static const int firstReportDays = 7;

  /// 모달 표시 및 선택된 날짜 범위 반환
  ///
  /// Returns:
  /// - [startDate, endDate] (성공 시)
  /// - {'error': true, 'message': String} (날짜 겹침 시)
  /// - null (취소 시)
  static Future<dynamic> show(BuildContext context) async {
    return await showModalBottomSheet<dynamic>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      useRootNavigator: true,
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

  final GlucoseRepository _glucoseRepository = GlucoseRepository();
  final ReportRepository _reportRepository = ReportRepository();
  Set<DateTime> _datesWithData = {};
  List<Report> _existingReports = [];

  late Future<void> _initializationFuture;

  bool get _isCurrentMonth {
    final now = DateTime.now();
    return _focusedDay.year == now.year && _focusedDay.month == now.month;
  }

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
    // DB에서 모든 리포트 조회 (삭제된 것 포함)
    // 삭제된 리포트도 날짜 범위 검증에 사용되므로 포함해야 함
    _existingReports = await _reportRepository.getAllReportsIncludingDeleted();

    final now = DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final isDevMode = dotenv.env['APP_ENV'] == 'development';

    // 개발 모드: 날짜 범위 제한 없음
    if (isDevMode) {
      _rangeStart = null;
      _rangeEnd = null;
      _focusedDay = yesterday;
      return;
    }

    if (_existingReports.isNotEmpty) {
      // 가장 최근 리포트의 종료일 다음 날을 시작일로 고정
      final latestReport = _existingReports.first;
      final nextDay = DateTime(
        latestReport.endDate.year,
        latestReport.endDate.month,
        latestReport.endDate.day + 1,
      );

      _rangeStart = nextDay;
      _focusedDay = nextDay.isAfter(yesterday) ? yesterday : nextDay;
    } else {
      // 첫 리포트: 어제부터 7일 전까지 고정 (총 7일간)
      final startDate = DateTime(
        yesterday.year,
        yesterday.month,
        yesterday.day - (DateRangePickerModal.firstReportDays - 1),
      );

      _rangeStart = startDate;
      _rangeEnd = yesterday;
      _focusedDay = yesterday;
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

  /// 선택된 날짜 범위가 최소 기간을 충족하는지 확인
  bool _isValidDateRange() {
    if (_rangeStart == null || _rangeEnd == null) return false;

    final isDevMode = dotenv.env['APP_ENV'] == 'development';
    if (isDevMode) return true; // 개발 모드: 최소 기간 제한 없음

    final days = _rangeEnd!.difference(_rangeStart!).inDays + 1;
    return days >= DateRangePickerModal.minReportDays;
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
              color: context.colors.card,
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
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
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

          // 닫기 버튼
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  l10n.close,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ),
          ),

          // 타이틀
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Center(
              child: Text(
                l10n.selectDateRange,
                style: context.textStyles.tileTitle.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

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
              SizedBox(
                height: 400,
                child: TableCalendar(
                  firstDay: DateTime.now().subtract(const Duration(days: 365)),
                  lastDay: DateTime.now(),
                  focusedDay: _focusedDay,
                  calendarFormat: CalendarFormat.month,
                  availableCalendarFormats: const {CalendarFormat.month: 'Month'},
                  rangeStartDay: _rangeStart,
                  rangeEndDay: _rangeEnd,
                  rangeSelectionMode: RangeSelectionMode.enforced,
                  daysOfWeekHeight: 40,
                  rowHeight: 48,
                // 날짜 활성화 조건
                enabledDayPredicate: (day) {
                  final isDevMode = dotenv.env['APP_ENV'] == 'development';

                  // 개발 모드: 모든 과거 날짜 활성화
                  if (isDevMode) {
                    final normalizedDay = DateTime(day.year, day.month, day.day);
                    final normalizedToday = DateTime(
                      DateTime.now().year,
                      DateTime.now().month,
                      DateTime.now().day,
                    );
                    return normalizedDay.isBefore(normalizedToday) || normalizedDay.isAtSameMomentAs(normalizedToday);
                  }

                  final normalizedDay = DateTime(day.year, day.month, day.day);
                  final normalizedToday = DateTime(
                    DateTime.now().year,
                    DateTime.now().month,
                    DateTime.now().day,
                  );

                  // 오늘은 항상 활성화 (todayBuilder로 렌더링되도록)
                  if (normalizedDay.isAtSameMomentAs(normalizedToday)) {
                    return true;
                  }

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
                  final isDevMode = dotenv.env['APP_ENV'] == 'development';

                  // 개발 모드: 자유롭게 시작일/종료일 선택
                  if (isDevMode) {
                    final normalizedSelectedDay = DateTime(
                      selectedDay.year,
                      selectedDay.month,
                      selectedDay.day,
                    );
                    final normalizedToday = DateTime(
                      DateTime.now().year,
                      DateTime.now().month,
                      DateTime.now().day,
                    );

                    // 오늘은 선택 불가
                    if (normalizedSelectedDay.isAtSameMomentAs(normalizedToday)) {
                      return;
                    }

                    setState(() {
                      _focusedDay = focusedDay;
                      if (_rangeStart == null || _rangeEnd != null) {
                        // 첫 번째 선택 또는 범위가 이미 설정된 경우 -> 시작일로 설정
                        _rangeStart = selectedDay;
                        _rangeEnd = null;
                      } else {
                        // 두 번째 선택 -> 종료일로 설정
                        if (selectedDay.isBefore(_rangeStart!)) {
                          // 종료일이 시작일보다 이전이면 둘을 바꿈
                          _rangeEnd = _rangeStart;
                          _rangeStart = selectedDay;
                        } else {
                          _rangeEnd = selectedDay;
                        }
                      }
                    });
                    return;
                  }

                  // 첫 리포트는 날짜 선택 불가 (7일 고정)
                  if (_existingReports.isEmpty) {
                    return;
                  }

                  // 오늘은 선택 불가
                  final normalizedSelectedDay = DateTime(
                    selectedDay.year,
                    selectedDay.month,
                    selectedDay.day,
                  );
                  final normalizedToday = DateTime(
                    DateTime.now().year,
                    DateTime.now().month,
                    DateTime.now().day,
                  );
                  if (normalizedSelectedDay.isAtSameMomentAs(normalizedToday)) {
                    return;
                  }

                  setState(() {
                    _focusedDay = focusedDay;
                    // 두 번째 리포트부터: 시작일 고정, 종료일만 선택 가능
                    if (_rangeEnd != null) {
                      // 이미 범위가 선택된 경우, 새로운 종료일로 업데이트
                      _rangeEnd = selectedDay;
                    } else {
                      // 첫 선택은 종료일로 설정
                      _rangeEnd = selectedDay;
                    }
                  });
                },
                onPageChanged: (focusedDay) {
                  setState(() {
                    _focusedDay = focusedDay;
                  });
                },
                // 커스텀 빌더로 빨간 점 표시
                calendarBuilders: CalendarBuilders(
                  defaultBuilder: (context, day, focusedDay) {
                    final normalizedDate = DateTime(day.year, day.month, day.day);
                    final hasData = _datesWithData.contains(normalizedDate);
                    final isDark = Theme.of(context).brightness == Brightness.dark;

                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${day.day}',
                            style: context.textStyles.tileSubtitle.copyWith(
                              color: isDark ? context.colors.textPrimary : Colors.black87,
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
                  disabledBuilder: (context, day, focusedDay) {
                    final normalizedDate = DateTime(day.year, day.month, day.day);
                    final hasData = _datesWithData.contains(normalizedDate);
                    final isDark = Theme.of(context).brightness == Brightness.dark;

                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${day.day}',
                            style: context.textStyles.tileSubtitle.copyWith(
                              color: isDark ? context.colors.textSecondary : Colors.grey[300],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: hasData
                                ? (isDark ? context.colors.textSecondary.withValues(alpha: 0.3) : Colors.grey[300])
                                : Colors.transparent,
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

                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${day.day}',
                            style: context.textStyles.tileSubtitle.copyWith(
                              color: Colors.red,
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
                    );
                  },
                  rangeStartBuilder: (context, day, focusedDay) {
                    final normalizedDate = DateTime(day.year, day.month, day.day);
                    final hasData = _datesWithData.contains(normalizedDate);

                    return Container(
                      margin: const EdgeInsets.all(7),
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryColor, // 시작일은 항상 빨간색
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
                    final isValid = _isValidDateRange();

                    return Container(
                      margin: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: isValid ? AppTheme.primaryColor : Colors.grey,
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
                    final isValid = _isValidDateRange();

                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${day.day}',
                            style: context.textStyles.tileSubtitle.copyWith(
                              color: isValid ? AppTheme.primaryColor : Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: hasData ? (isValid ? Colors.red : Colors.grey) : Colors.transparent,
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
                  rangeHighlightColor: _isValidDateRange()
                      ? AppTheme.primaryColor.withOpacity(0.2)
                      : Colors.grey.withOpacity(0.2),
                  rangeStartDecoration: const BoxDecoration(
                    color: AppTheme.primaryColor, // 시작일은 항상 빨간색
                    shape: BoxShape.circle,
                  ),
                  rangeEndDecoration: BoxDecoration(
                    color: _isValidDateRange() ? AppTheme.primaryColor : Colors.grey,
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
                    color: _isCurrentMonth ? Colors.transparent : AppTheme.primaryColor,
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
            ),
              const SizedBox(height: 16),

              // 안내 메시지 (첫 리포트 여부에 따라 다른 메시지 표시)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _existingReports.isEmpty
                      ? l10n.firstReportInfo
                      : l10n.subsequentReportInfo,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      height: 1.4,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 리포트 생성 버튼
              SizedBox(
                width: double.infinity,
                child: CupertinoButton(
                  onPressed: _isValidDateRange()
                      ? () {
                          // 겹침 검증
                          if (_hasOverlapWithExistingReports()) {
                            final overlappingRange = _getOverlappingReportRange();
                            // 에러를 나타내는 특별한 값을 반환
                            Navigator.of(context).pop({
                              'error': true,
                              'message': '이미 해당 기간의 리포트가 존재합니다.\n\n$overlappingRange',
                            });
                            return;
                          }

                          // 겹치지 않으면 날짜 범위 반환
                          Navigator.of(context).pop([_rangeStart!, _rangeEnd!]);
                        }
                      : null,
                  color: _isValidDateRange()
                      ? AppTheme.primaryColor
                      : Colors.grey[300],
                  disabledColor: Colors.grey[300]!,
                  borderRadius: BorderRadius.circular(12),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    l10n.generateReport,
                    style: TextStyle(
                      color: _isValidDateRange()
                          ? Colors.white
                          : Colors.grey[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
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

    // 언어별 날짜 형식 설정
    // 한국어, 중국어, 일본어는 "월 일" 순서, 그 외는 "일 월" 순서
    final isAsianLocale = locale.startsWith('ko') ||
                          locale.startsWith('zh') ||
                          locale.startsWith('ja');

    if (isSameYear) {
      if (isAsianLocale) {
        // 같은 년도 (동아시아): "1월 10일 - 1월 16일"
        startFormat = 'M월 d일';
        endFormat = 'M월 d일';
      } else {
        // 같은 년도 (기타): "24 Dec - 27 Dec"
        startFormat = 'd MMM';
        endFormat = 'd MMM';
      }
    } else {
      if (isAsianLocale) {
        // 다른 년도 (동아시아): "2024년 12월 24일 - 2025년 1월 3일"
        startFormat = 'y년 M월 d일';
        endFormat = 'y년 M월 d일';
      } else {
        // 다른 년도 (기타): "24 Dec 2024 - 3 Jan 2025"
        startFormat = 'd MMM y';
        endFormat = 'd MMM y';
      }
    }

    final startFormatter = DateFormat(startFormat, locale);
    final endFormatter = DateFormat(endFormat, locale);

    final start = startFormatter.format(_rangeStart!);
    final end = endFormatter.format(_rangeEnd!);

    return '$start - $end';
  }
}
