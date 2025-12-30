import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:glu_butler/l10n/app_localizations.dart';
import 'package:glu_butler/core/theme/app_theme.dart';
import 'package:glu_butler/core/theme/app_text_styles.dart';
import 'package:glu_butler/core/theme/app_colors.dart';
import 'package:glu_butler/services/settings_service.dart';
import 'package:glu_butler/providers/feed_provider.dart';

/// 날짜 선택 모달 팝업
///
/// 차트 화면 등에서 날짜를 선택할 때 사용하는 바텀 시트입니다.
/// 혈당/인슐린 데이터가 있는 날짜에는 빨간 점이 표시됩니다.
///
/// ## 사용법
/// ```dart
/// final selectedDate = await DatePickerModal.show(
///   context,
///   initialDate: DateTime.now(),
/// );
/// ```
class DatePickerModal extends StatefulWidget {
  final DateTime initialDate;

  const DatePickerModal({super.key, required this.initialDate});

  static Future<DateTime?> show(
    BuildContext context, {
    required DateTime initialDate,
  }) {
    return showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      useRootNavigator: true,
      builder: (context) => DatePickerModal(initialDate: initialDate),
    );
  }

  @override
  State<DatePickerModal> createState() => _DatePickerModalState();
}

class _DatePickerModalState extends State<DatePickerModal> {
  late DateTime _selectedDate;
  late DateTime _focusedDate;
  Set<DateTime> _datesWithData = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _focusedDate = widget.initialDate;
    _loadDatesWithData();
  }

  bool get _isCurrentMonth {
    final now = DateTime.now();
    return _focusedDate.year == now.year && _focusedDate.month == now.month;
  }

  Future<void> _loadDatesWithData() async {
    setState(() => _isLoading = true);

    try {
      // FeedProvider에서 데이터 가져오기
      final feedProvider = context.read<FeedProvider>();
      final settings = context.read<SettingsService>();
      final syncPeriod = settings.syncPeriod;
      final now = DateTime.now();

      // 오늘 포함 syncPeriod일 = (syncPeriod - 1)일 전부터
      // 예: 오늘이 30일, syncPeriod=7 -> 24일부터 30일까지 (7일간)
      final startDate = now.subtract(Duration(days: syncPeriod - 1));

      // FeedProvider의 캐시된 데이터에서 날짜 추출
      final feedItems = feedProvider.getReportData(
        startDate: startDate,
        endDate: now,
      );

      final datesSet = <DateTime>{};
      for (final item in feedItems) {
        // 혈당 데이터만 체크
        if (item.glucoseRecord != null) {
          final date = DateTime(
            item.timestamp.year,
            item.timestamp.month,
            item.timestamp.day,
          );
          datesSet.add(date);
        }
      }

      setState(() {
        _datesWithData = datesSet;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('[DatePickerModal] Error loading data: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
                  l10n.selectDate,
                  style: context.textStyles.tileTitle.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    // 오늘 날짜를 선택하고 모달 닫기
                    Navigator.of(context).pop(DateTime.now());
                  },
                  child: Text(
                    l10n.today,
                    style: const TextStyle(
                      color: AppTheme.primaryColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 커스텀 헤더
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 왼쪽 버튼
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    final previousMonth = DateTime(
                      _focusedDate.year,
                      _focusedDate.month - 1,
                    );
                    setState(() {
                      _focusedDate = previousMonth;
                    });
                    _loadDatesWithData();
                  },
                  child: Icon(
                    Icons.chevron_left,
                    color: context.colors.textPrimary,
                  ),
                ),
                // 중앙 타이틀
                Text(
                  DateFormat.yMMMM(Localizations.localeOf(context).toString())
                      .format(_focusedDate),
                  style: context.textStyles.tileTitle.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                // 오른쪽 버튼 (현재 월이면 투명, 아니면 표시)
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: _isCurrentMonth
                      ? null
                      : () {
                          final nextMonth = DateTime(
                            _focusedDate.year,
                            _focusedDate.month + 1,
                          );
                          setState(() {
                            _focusedDate = nextMonth;
                          });
                          _loadDatesWithData();
                        },
                  child: Icon(
                    Icons.chevron_right,
                    color: _isCurrentMonth
                        ? Colors.transparent
                        : context.colors.textPrimary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // 달력
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TableCalendar(
              firstDay: DateTime(2020, 1, 1),
              lastDay: DateTime.now(),
              focusedDay: _focusedDate,
              selectedDayPredicate: (day) => isSameDay(_selectedDate, day),
              onDaySelected: (selectedDay, focusedDay) {
                // 날짜 선택 시 바로 모달 닫기
                Navigator.of(context).pop(selectedDay);
              },
              onPageChanged: (focusedDay) {
                setState(() {
                  _focusedDate = focusedDay;
                });
                _loadDatesWithData();
              },
              calendarFormat: CalendarFormat.month,
              availableCalendarFormats: const {CalendarFormat.month: 'Month'},
              headerVisible: false,
              daysOfWeekStyle: DaysOfWeekStyle(
                weekdayStyle: context.textStyles.caption.copyWith(
                  color: context.colors.textSecondary,
                ),
                weekendStyle: context.textStyles.caption.copyWith(
                  color: context.colors.textSecondary,
                ),
              ),
              calendarStyle: CalendarStyle(
                // 오늘 날짜 스타일 (배경 없이 텍스트만)
                todayDecoration: const BoxDecoration(),
                todayTextStyle: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
                // 선택된 날짜 스타일
                selectedDecoration: const BoxDecoration(
                  color: AppTheme.primaryColor,
                  shape: BoxShape.circle,
                ),
                selectedTextStyle: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
                // 일반 날짜 스타일
                defaultTextStyle: context.textStyles.tileSubtitle,
                weekendTextStyle: context.textStyles.tileSubtitle,
                outsideTextStyle: context.textStyles.tileSubtitle.copyWith(
                  color: context.colors.textSecondary.withValues(alpha: 0.3),
                ),
                // 비활성 날짜 (미래 날짜)
                disabledTextStyle: context.textStyles.tileSubtitle.copyWith(
                  color: context.colors.textSecondary.withValues(alpha: 0.3),
                ),
                // 마커 스타일
                markerDecoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                markerSize: 6,
                markersMaxCount: 1,
              ),
              calendarBuilders: CalendarBuilders(
                // 일반 날짜 빌더 (데이터 마커 포함)
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
                // 선택된 날짜 커스텀 빌더 (오늘이 아닌 날짜)
                selectedBuilder: (context, day, focusedDay) {
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
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: hasData
                                  ? Colors.white.withValues(alpha: 0.9)
                                  : Colors.transparent,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                // 오늘 날짜 커스텀 빌더
                todayBuilder: (context, day, focusedDay) {
                  final isSelected = isSameDay(_selectedDate, day);
                  final normalizedDate = DateTime(day.year, day.month, day.day);
                  final hasData = _datesWithData.contains(normalizedDate);

                  return Container(
                    margin: const EdgeInsets.all(7),
                    decoration: isSelected
                        ? const BoxDecoration(
                            color: AppTheme.primaryColor,
                            shape: BoxShape.circle,
                          )
                        : null,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${day.day}',
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: hasData
                                  ? (isSelected
                                        ? Colors.white.withValues(alpha: 0.9)
                                        : Colors.red)
                                  : Colors.transparent,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // 연동 기간 안내 메시지
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 40, 16, 0),
            child: Consumer<SettingsService>(
              builder: (context, settings, child) {
                final syncPeriod = settings.syncPeriod;
                String periodText;
                switch (syncPeriod) {
                  case 7:
                    periodText = l10n.syncPeriod1Week;
                    break;
                  case 14:
                    periodText = l10n.syncPeriod2Weeks;
                    break;
                  case 30:
                    periodText = l10n.syncPeriod1Month;
                    break;
                  case 90:
                    periodText = l10n.syncPeriod3Months;
                    break;
                  default:
                    periodText = l10n.syncPeriod1Week;
                }

                final message = l10n.dataSyncPeriodInfo(periodText);
                // "최근 {기간} 데이터만..." 형태에서 기간 부분만 볼드 처리
                // 메시지를 ". "로 분리하여 두 줄로 표시
                final messageParts = message.split('. ');
                final firstLine = messageParts.isNotEmpty ? messageParts[0] : '';
                final secondLine = messageParts.length > 1 ? messageParts[1] : '';

                final parts = firstLine.split(periodText);

                return Align(
                  alignment: Alignment.centerLeft,
                  child: RichText(
                    textAlign: TextAlign.left,
                    text: TextSpan(
                      style: TextStyle(
                        color: context.colors.textSecondary,
                        fontSize: 12,
                      ),
                      children: [
                        if (parts.isNotEmpty) TextSpan(text: parts[0]),
                        TextSpan(
                          text: periodText,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        if (parts.length > 1) TextSpan(text: parts[1]),
                        if (secondLine.isNotEmpty) ...[
                          const TextSpan(text: '\n'),
                          TextSpan(text: secondLine),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
