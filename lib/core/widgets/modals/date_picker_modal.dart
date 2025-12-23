import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import 'package:glu_butler/l10n/app_localizations.dart';
import 'package:glu_butler/core/theme/app_theme.dart';
import 'package:glu_butler/core/theme/app_text_styles.dart';
import 'package:glu_butler/core/theme/app_colors.dart';
import 'package:glu_butler/repositories/glucose_repository.dart';

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
  final _glucoseRepository = GlucoseRepository();
  Set<DateTime> _datesWithData = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _focusedDate = widget.initialDate;
    _loadDatesWithData();
  }

  Future<void> _loadDatesWithData() async {
    setState(() => _isLoading = true);

    try {
      // 현재 보이는 달의 전후 3개월 데이터를 로드
      final startDate = DateTime(_focusedDate.year, _focusedDate.month - 3, 1);
      final endDate = DateTime(_focusedDate.year, _focusedDate.month + 4, 0);

      final records = await _glucoseRepository.fetch(
        startDate: startDate,
        endDate: endDate,
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

      setState(() {
        _datesWithData = datesSet;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('[DatePickerModal] Error loading data: $e');
      setState(() => _isLoading = false);
    }
  }

  void _save() {
    Navigator.of(context).pop(_selectedDate);
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
                    l10n.cancel,
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                ),
                Text(
                  '날짜 선택',
                  style: context.textStyles.tileTitle.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: _save,
                  child: Text(
                    '확인',
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
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: context.textStyles.tileTitle.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
                leftChevronIcon: Icon(
                  Icons.chevron_left,
                  color: context.colors.textPrimary,
                ),
                rightChevronIcon: Icon(
                  Icons.chevron_right,
                  color: context.colors.textPrimary,
                ),
              ),
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
                // 오늘 날짜 커스텀 빌더
                todayBuilder: (context, day, focusedDay) {
                  final isSelected = isSameDay(_selectedDate, day);
                  return Container(
                    margin: const EdgeInsets.all(6),
                    alignment: Alignment.center,
                    decoration: isSelected
                        ? const BoxDecoration(
                            color: AppTheme.primaryColor,
                            shape: BoxShape.circle,
                          )
                        : null,
                    child: Text(
                      '${day.day}',
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
                // 데이터가 있는 날짜에 빨간 점 표시
                markerBuilder: (context, date, events) {
                  final normalizedDate = DateTime(
                    date.year,
                    date.month,
                    date.day,
                  );
                  if (_datesWithData.contains(normalizedDate)) {
                    return Positioned(
                      bottom: -6,
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    );
                  }
                  return null;
                },
              ),
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
