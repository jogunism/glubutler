import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:glu_butler/l10n/app_localizations.dart';
import 'package:glu_butler/core/theme/app_theme.dart';
import 'package:glu_butler/core/theme/app_text_styles.dart';
import 'package:glu_butler/core/theme/app_colors.dart';
import 'package:glu_butler/core/theme/app_decorations.dart';
import 'package:glu_butler/providers/feed_provider.dart';
import 'package:glu_butler/models/glucose_record.dart';
import 'package:glu_butler/models/insulin_record.dart';

/// 이벤트 유형
enum RecordType { glucose, insulin }

/// 기록 입력 모달 팝업
///
/// feed 화면에서 [+] 버튼을 누르면 표시되는 바텀 시트입니다.
/// 세그먼트 컨트롤로 혈당/인슐린을 선택하고 해당 폼을 입력합니다.
///
/// ## 사용법
/// ```dart
/// RecordInputModal.show(context);
/// ```
class RecordInputModal extends StatefulWidget {
  const RecordInputModal({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useRootNavigator: true,
      builder: (context) => const RecordInputModal(),
    );
  }

  @override
  State<RecordInputModal> createState() => _RecordInputModalState();
}

class _RecordInputModalState extends State<RecordInputModal> {
  RecordType _selectedType = RecordType.glucose;

  // 혈당 관련 상태
  final _glucoseController = TextEditingController();
  final _glucoseFocusNode = FocusNode();
  bool _glucoseHasFocus = false;
  String _selectedTiming = 'unspecified'; // unspecified, beforeMeal, afterMeal
  bool _isSaving = false;
  DateTime _selectedTime = DateTime.now();

  // 인슐린 관련 상태
  final _insulinDoseController = TextEditingController();
  final _insulinFocusNode = FocusNode();
  bool _insulinHasFocus = false;
  String _selectedInsulinType = 'rapidActing';
  String _selectedInjectionSite = 'abdomen';
  DateTime _selectedInsulinTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _glucoseFocusNode.addListener(_onFocusChange);
    _insulinFocusNode.addListener(_onFocusChange);
    _glucoseController.addListener(_onTextChange);
    _insulinDoseController.addListener(_onTextChange);
  }

  void _onFocusChange() {
    setState(() {
      _glucoseHasFocus = _glucoseFocusNode.hasFocus;
      _insulinHasFocus = _insulinFocusNode.hasFocus;
    });
  }

  void _onTextChange() {
    setState(() {});
  }

  @override
  void dispose() {
    _glucoseFocusNode.removeListener(_onFocusChange);
    _insulinFocusNode.removeListener(_onFocusChange);
    _glucoseController.removeListener(_onTextChange);
    _insulinDoseController.removeListener(_onTextChange);
    _glucoseController.dispose();
    _glucoseFocusNode.dispose();
    _insulinDoseController.dispose();
    _insulinFocusNode.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_isSaving) return;

    // Capture navigator before async gap
    final nav = Navigator.of(context);
    final feedProvider = context.read<FeedProvider>();

    if (_selectedType == RecordType.glucose) {
      final glucoseValue = double.tryParse(_glucoseController.text);
      if (glucoseValue == null || glucoseValue <= 0) {
        return;
      }

      setState(() => _isSaving = true);

      final record = GlucoseRecord(
        id: 'manual_${_selectedTime.millisecondsSinceEpoch}',
        value: glucoseValue,
        unit: 'mg/dL',
        timestamp: _selectedTime,
        isFromHealthKit: false,
        mealContext: _selectedTiming == 'unspecified' ? null : _selectedTiming,
      );

      // Save via FeedProvider (handles Health/Local routing)
      await feedProvider.addGlucoseRecord(record);

      if (mounted) {
        nav.pop();
      }
    } else {
      final doseValue = double.tryParse(_insulinDoseController.text);
      if (doseValue == null || doseValue <= 0) {
        return;
      }

      setState(() => _isSaving = true);

      final record = InsulinRecord(
        id: 'manual_${_selectedInsulinTime.millisecondsSinceEpoch}',
        timestamp: _selectedInsulinTime,
        units: doseValue,
        insulinType: _mapInsulinType(_selectedInsulinType),
        injectionSite: _selectedInjectionSite,
        isFromHealthKit: false,
      );

      // Save via FeedProvider (handles Health/Local routing)
      await feedProvider.addInsulinRecord(record);

      if (mounted) {
        nav.pop();
      }
    }
  }

  InsulinType _mapInsulinType(String type) {
    switch (type) {
      case 'rapidActing':
        return InsulinType.rapidActing;
      case 'shortActing':
        return InsulinType.shortActing;
      case 'intermediateActing':
        return InsulinType.intermediate;
      case 'longActing':
        return InsulinType.longActing;
      default:
        return InsulinType.rapidActing;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Container(
        decoration: BoxDecoration(
          color: context.colors.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.only(bottom: bottomPadding),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
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
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Text(
                      l10n.addRecord,
                      style: context.textStyles.tileTitle.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: _save,
                      child: Text(
                        l10n.save,
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

              // 세그먼트 컨트롤 (혈당 / 인슐린)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: CupertinoSlidingSegmentedControl<RecordType>(
                  groupValue: _selectedType,
                  backgroundColor: CupertinoColors.systemGrey5,
                  thumbColor: CupertinoColors.white,
                  children: {
                    RecordType.glucose: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 8),
                      child: Text(
                        l10n.bloodGlucose,
                        style: TextStyle(
                          color: _selectedType == RecordType.glucose
                              ? AppTheme.primaryColor
                              : Colors.grey[600],
                          fontWeight: _selectedType == RecordType.glucose
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                    RecordType.insulin: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 8),
                      child: Text(
                        l10n.insulin,
                        style: TextStyle(
                          color: _selectedType == RecordType.insulin
                              ? AppTheme.primaryColor
                              : Colors.grey[600],
                          fontWeight: _selectedType == RecordType.insulin
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  },
                  onValueChanged: (value) {
                    if (value != null) {
                      HapticFeedback.lightImpact();
                      setState(() {
                        _selectedType = value;
                      });
                    }
                  },
                ),
              ),

              const SizedBox(height: 24),

              // 폼 영역
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _selectedType == RecordType.glucose
                    ? _buildGlucoseForm(context, l10n)
                    : _buildInsulinForm(context, l10n),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildGlucoseForm(BuildContext context, AppLocalizations l10n) {
    return Column(
      key: const ValueKey('glucose_form'),
      children: [
        // 혈당 수치 입력
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.bloodGlucose,
                style: context.textStyles.tileSubtitle,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.primaryColor,
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Stack(
                        alignment: Alignment.centerRight,
                        children: [
                          // Placeholder
                          if (!_glucoseHasFocus && _glucoseController.text.isEmpty)
                            Padding(
                              padding: const EdgeInsets.only(right: 16),
                              child: Text(
                                '0',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[400],
                                ),
                              ),
                            ),
                          // TextField
                          TextField(
                            controller: _glucoseController,
                            focusNode: _glucoseFocusNode,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(3),
                            ],
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                            decoration: InputDecoration(
                              filled: false,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Text(
                        l10n.mgdl,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // 측정 시점 선택
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.measurementTiming,
                style: context.textStyles.tileSubtitle,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildTimingChip(
                    context,
                    label: l10n.unspecified,
                    value: 'unspecified',
                  ),
                  const SizedBox(width: 8),
                  _buildTimingChip(
                    context,
                    label: l10n.beforeMeal,
                    value: 'beforeMeal',
                  ),
                  const SizedBox(width: 8),
                  _buildTimingChip(
                    context,
                    label: l10n.afterMeal,
                    value: 'afterMeal',
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // 시간 선택
        _buildTimeSelector(
          context,
          l10n,
          label: l10n.measurementTime,
          time: _selectedTime,
          onTimeChanged: (time) => setState(() => _selectedTime = time),
        ),
      ],
    );
  }

  Widget _buildInsulinForm(BuildContext context, AppLocalizations l10n) {
    return Column(
      key: const ValueKey('insulin_form'),
      children: [
        // 투여량 입력
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.insulinDose,
                style: context.textStyles.tileSubtitle,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.primaryColor,
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Stack(
                        alignment: Alignment.centerRight,
                        children: [
                          // Placeholder
                          if (!_insulinHasFocus && _insulinDoseController.text.isEmpty)
                            Padding(
                              padding: const EdgeInsets.only(right: 16),
                              child: Text(
                                '0',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[400],
                                ),
                              ),
                            ),
                          // TextField
                          TextField(
                            controller: _insulinDoseController,
                            focusNode: _insulinFocusNode,
                            keyboardType:
                                const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d{0,3}\.?\d{0,1}$')),
                            ],
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                            decoration: InputDecoration(
                              filled: false,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Text(
                        l10n.units,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // 인슐린 종류 선택
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.insulinType,
                style: context.textStyles.tileSubtitle,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildInsulinTypeChip(context, l10n.rapidActing, 'rapidActing'),
                  _buildInsulinTypeChip(context, l10n.shortActing, 'shortActing'),
                  _buildInsulinTypeChip(
                      context, l10n.intermediateActing, 'intermediateActing'),
                  _buildInsulinTypeChip(context, l10n.longActing, 'longActing'),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // 주사 부위 선택
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.injectionSite,
                style: context.textStyles.tileSubtitle,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildSiteChip(context, l10n.abdomen, 'abdomen'),
                  const SizedBox(width: 8),
                  _buildSiteChip(context, l10n.thigh, 'thigh'),
                  const SizedBox(width: 8),
                  _buildSiteChip(context, l10n.arm, 'arm'),
                  const SizedBox(width: 8),
                  _buildSiteChip(context, l10n.buttock, 'buttock'),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // 시간 선택
        _buildTimeSelector(
          context,
          l10n,
          label: l10n.injectionTime,
          time: _selectedInsulinTime,
          onTimeChanged: (time) => setState(() => _selectedInsulinTime = time),
        ),
      ],
    );
  }

  Widget _buildTimingChip(
    BuildContext context, {
    required String label,
    required String value,
  }) {
    final isSelected = _selectedTiming == value;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          setState(() {
            _selectedTiming = value;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primaryColor.withValues(alpha: 0.15)
                : context.colors.card,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppTheme.primaryColor : context.colors.divider,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected
                  ? AppTheme.primaryColor
                  : context.textStyles.tileTitle.color,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInsulinTypeChip(
      BuildContext context, String label, String value) {
    final isSelected = _selectedInsulinType == value;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() {
          _selectedInsulinType = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor.withValues(alpha: 0.15)
              : context.colors.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : context.colors.divider,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected
                ? AppTheme.primaryColor
                : context.textStyles.tileTitle.color,
          ),
        ),
      ),
    );
  }

  Widget _buildSiteChip(BuildContext context, String label, String value) {
    final isSelected = _selectedInjectionSite == value;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          setState(() {
            _selectedInjectionSite = value;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primaryColor.withValues(alpha: 0.15)
                : context.colors.card,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppTheme.primaryColor : context.colors.divider,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected
                  ? AppTheme.primaryColor
                  : context.textStyles.tileTitle.color,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeSelector(
    BuildContext context,
    AppLocalizations l10n, {
    required String label,
    required DateTime time,
    required ValueChanged<DateTime> onTimeChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: context.textStyles.tileSubtitle,
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => _showTimePicker(context, time, onTimeChanged),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              decoration: context.decorations.card.copyWith(
                border: Border.all(
                  color: context.colors.divider,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatTime(time),
                    style: context.textStyles.tileTitle,
                  ),
                  Icon(
                    CupertinoIcons.time,
                    color: Colors.grey[400],
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showTimePicker(
    BuildContext context,
    DateTime currentTime,
    ValueChanged<DateTime> onTimeChanged,
  ) {
    // 5분 단위로 반올림
    final roundedMinute = (currentTime.minute / 5).round() * 5;
    final initialTime = DateTime(
      currentTime.year,
      currentTime.month,
      currentTime.day,
      currentTime.hour,
      roundedMinute >= 60 ? 0 : roundedMinute,
    );

    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 280,
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[900]
            : Colors.white,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(
                  child: Text(AppLocalizations.of(context)!.cancel),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                CupertinoButton(
                  child: Text(AppLocalizations.of(context)!.save),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.time,
                initialDateTime: initialTime,
                use24hFormat: true,
                minuteInterval: 5,
                onDateTimeChanged: onTimeChanged,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    // 5분 단위로 반올림해서 표시
    final roundedMinute = (time.minute / 5).round() * 5;
    final minute = (roundedMinute >= 60 ? 0 : roundedMinute).toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
