import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';

import 'package:glu_butler/l10n/app_localizations.dart';
import 'package:glu_butler/core/theme/app_theme.dart';
import 'package:glu_butler/core/theme/app_text_styles.dart';
import 'package:glu_butler/core/theme/app_colors.dart';
import 'package:glu_butler/core/widgets/glass_icon.dart';
import 'package:glu_butler/core/widgets/large_title_scroll_view.dart';
import 'package:glu_butler/services/settings_service.dart';
import 'package:glu_butler/services/health_service.dart';

/// 프로필 설정 화면
///
/// 사용자의 개인 정보와 당뇨 관련 정보를 설정하는 화면입니다.
///
/// ## 섹션 구성
/// 1. **Personal** - 이름, 성별, 생년월일
/// 2. **Diabetes** - 당뇨 유형, 진단 연도
class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  bool _isEditingName = false;
  final TextEditingController _nameController = TextEditingController();
  final FocusNode _nameFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Listen to focus changes to save when losing focus
    _nameFocusNode.addListener(() {
      if (!_nameFocusNode.hasFocus && _isEditingName) {
        _saveName();
      }
    });
  }

  @override
  void dispose() {
    _nameFocusNode.removeListener(() {});
    _nameController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  void _saveName() {
    final settings = context.read<SettingsService>();
    final value = _nameController.text.trim();
    if (value.isNotEmpty && value != settings.userProfile.name) {
      final profile = settings.userProfile.copyWith(name: value);
      settings.updateUserProfile(profile);
    }
    setState(() {
      _isEditingName = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settings = context.watch<SettingsService>();

    return GestureDetector(
      onTap: () {
        // Unfocus when tapping outside
        FocusScope.of(context).unfocus();
      },
      child: LargeTitleScrollView(
        title: l10n.profile,
        showBackButton: true,
        showLargeTitle: false,
        onRefresh: null,
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Personal Section
                _buildSectionTitle(context, l10n.personal),
                _buildGroupedSection(
                  context: context,
                  children: [
                    _buildNameTile(context, settings, l10n),
                    _buildDivider(context),
                    _buildAdaptivePopupTile(
                      context: context,
                      icon: CupertinoIcons.person_2_fill,
                      iconColor: AppTheme.iconPurple,
                      title: l10n.gender,
                      displayValue: _getGenderLabel(settings.userProfile.gender, l10n),
                      currentValue: settings.userProfile.gender,
                      items: [
                        AdaptivePopupMenuItem<String>(value: 'male', label: l10n.male),
                        AdaptivePopupMenuItem<String>(value: 'female', label: l10n.female),
                        AdaptivePopupMenuItem<String>(value: 'other', label: l10n.otherGender),
                      ],
                      onSelected: (index, item) {
                        final profile = settings.userProfile.copyWith(gender: item.value);
                        settings.updateUserProfile(profile);
                      },
                    ),
                    _buildDivider(context),
                    _buildDateTile(context, settings, l10n),
                    _buildDivider(context),
                    _buildWeightTile(context, settings, l10n),
                  ],
                ),

                const SizedBox(height: 24),

                // Diabetes Section
                _buildSectionTitle(context, l10n.diabetes),
                _buildGroupedSection(
                  context: context,
                  children: [
                    _buildAdaptivePopupTile(
                      context: context,
                      icon: CupertinoIcons.drop_fill,
                      iconColor: AppTheme.iconRed,
                      title: l10n.diabetesType,
                      displayValue: _getDiabetesTypeLabel(settings.userProfile.diabetesType, l10n),
                      currentValue: settings.userProfile.diabetesType,
                      items: [
                        AdaptivePopupMenuItem<String>(value: 'prediabetes', label: l10n.preDiabetes),
                        AdaptivePopupMenuItem<String>(value: 'type1', label: l10n.type1),
                        AdaptivePopupMenuItem<String>(value: 'type2', label: l10n.type2),
                        AdaptivePopupMenuItem<String>(value: 'lada', label: l10n.lada),
                        AdaptivePopupMenuItem<String>(value: 'mody', label: l10n.mody),
                        AdaptivePopupMenuItem<String>(value: 'unknown', label: l10n.diabetesTypeUnknown),
                      ],
                      onSelected: (index, item) {
                        final profile = settings.userProfile.copyWith(diabetesType: item.value);
                        settings.updateUserProfile(profile);
                      },
                    ),
                    _buildDivider(context),
                    _buildYearTile(context, settings, l10n),
                  ],
                ),

                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNameTile(BuildContext context, SettingsService settings, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GlassIcon(icon: CupertinoIcons.person_fill, color: AppTheme.iconBlue, size: 32),
          const SizedBox(width: 14),
          Expanded(
            child: _isEditingName
                ? CupertinoTextField(
                    controller: _nameController,
                    focusNode: _nameFocusNode,
                    style: context.textStyles.tileTitle,
                    decoration: null,
                    padding: EdgeInsets.zero,
                    placeholder: l10n.name,
                    textInputAction: TextInputAction.done,
                  )
                : GestureDetector(
                    onTap: () {
                      setState(() {
                        _isEditingName = true;
                        _nameController.text = settings.userProfile.name ?? '';
                      });
                      // Focus after the build completes
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _nameFocusNode.requestFocus();
                      });
                    },
                    child: Text(
                      settings.userProfile.name ?? l10n.name,
                      style: context.textStyles.tileTitle.copyWith(
                        color: settings.userProfile.name == null
                            ? context.colors.textSecondary
                            : null,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateTile(BuildContext context, SettingsService settings, AppLocalizations l10n) {
    final displayValue = settings.userProfile.birthday != null
        ? '${settings.userProfile.birthday!.year}.${settings.userProfile.birthday!.month}.${settings.userProfile.birthday!.day}'
        : '-';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GlassIcon(icon: CupertinoIcons.calendar, color: AppTheme.iconOrange, size: 32),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              l10n.birthday,
              style: context.textStyles.tileTitle,
            ),
          ),
          GestureDetector(
            onTap: () => _showDatePicker(context, settings),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  displayValue,
                  style: context.textStyles.tileSubtitle,
                ),
                const SizedBox(width: 4),
                Icon(
                  CupertinoIcons.chevron_down,
                  size: 16,
                  color: context.colors.iconGrey,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeightTile(BuildContext context, SettingsService settings, AppLocalizations l10n) {
    final weightFormatted = _formatWeight(settings.userProfile.weightKg, context);
    final displayValue = settings.userProfile.weightKg != null
        ? '$weightFormatted kg'
        : '-';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GlassIcon(icon: CupertinoIcons.gauge, color: AppTheme.iconPink, size: 32),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              l10n.weight,
              style: context.textStyles.tileTitle,
            ),
          ),
          GestureDetector(
            onTap: () => _showWeightPicker(context, settings),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  displayValue,
                  style: context.textStyles.tileSubtitle,
                ),
                const SizedBox(width: 4),
                Icon(
                  CupertinoIcons.chevron_down,
                  size: 16,
                  color: context.colors.iconGrey,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYearTile(BuildContext context, SettingsService settings, AppLocalizations l10n) {
    final displayValue = settings.userProfile.diagnosisYear?.toString() ?? '-';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GlassIcon(icon: CupertinoIcons.calendar_badge_plus, color: AppTheme.iconGreen, size: 32),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              l10n.yearOfDiagnosis,
              style: context.textStyles.tileTitle,
            ),
          ),
          GestureDetector(
            onTap: () => _showYearPicker(context, settings),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  displayValue,
                  style: context.textStyles.tileSubtitle,
                ),
                const SizedBox(width: 4),
                Icon(
                  CupertinoIcons.chevron_down,
                  size: 16,
                  color: context.colors.iconGrey,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: context.textStyles.sectionTitle,
      ),
    );
  }

  Widget _buildGroupedSection({
    required BuildContext context,
    required List<Widget> children,
  }) {
    return Container(
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
      child: Column(children: children),
    );
  }

  Widget _buildAdaptivePopupTile({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String displayValue,
    required List<AdaptivePopupMenuEntry> items,
    required void Function(int index, AdaptivePopupMenuItem<String> entry) onSelected,
    String? currentValue,
  }) {
    // Add checkmarks to items based on currentValue
    final itemsWithCheckmarks = items.map((item) {
      if (item is AdaptivePopupMenuItem<String>) {
        final isSelected = item.value == currentValue;
        return AdaptivePopupMenuItem<String>(
          value: item.value,
          label: item.label,
          icon: isSelected ? 'checkmark' : null,
        );
      }
      return item;
    }).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GlassIcon(icon: icon, color: iconColor, size: 32),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: context.textStyles.tileTitle,
            ),
          ),
          MediaQuery(
            data: MediaQuery.of(context).copyWith(
              platformBrightness: Theme.of(context).brightness,
            ),
            child: AdaptivePopupMenuButton.widget<String>(
              items: itemsWithCheckmarks,
              onSelected: onSelected,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    displayValue,
                    style: context.textStyles.tileSubtitle,
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    CupertinoIcons.chevron_down,
                    size: 16,
                    color: context.colors.iconGrey,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getGenderLabel(String? gender, AppLocalizations l10n) {
    if (gender == null) return '-';
    switch (gender) {
      case 'male':
        return l10n.male;
      case 'female':
        return l10n.female;
      case 'other':
        return l10n.otherGender;
      default:
        return '-';
    }
  }

  String _getDiabetesTypeLabel(String? type, AppLocalizations l10n) {
    if (type == null) return '-';
    switch (type) {
      case 'prediabetes':
        return l10n.preDiabetes;
      case 'type1':
        return l10n.type1;
      case 'type2':
        return l10n.type2;
      case 'lada':
        return l10n.lada;
      case 'mody':
        return l10n.mody;
      case 'unknown':
        return l10n.diabetesTypeUnknown;
      default:
        return '-';
    }
  }

  Widget _buildDivider(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 62),
      child: Divider(
        height: 1,
        color: context.colors.divider,
      ),
    );
  }

  /// 앱 언어에 따라 소수점 구분자를 반환
  /// de, fr, it, es: "," / en, ko, ja, zh: "."
  String _getDecimalSeparator(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    const commaLocales = ['de', 'fr', 'it', 'es'];
    return commaLocales.contains(locale) ? ',' : '.';
  }

  /// 숫자를 앱 언어에 맞는 소수점 형식으로 변환
  String _formatWeight(double? weight, BuildContext context) {
    if (weight == null) return '-';
    final separator = _getDecimalSeparator(context);
    final formatted = weight.toStringAsFixed(1);
    return separator == ',' ? formatted.replaceAll('.', ',') : formatted;
  }

  void _showDatePicker(BuildContext context, SettingsService settings) {
    final l10n = AppLocalizations.of(context)!;
    DateTime selectedDate = settings.userProfile.birthday ?? DateTime(2000, 1, 1);

    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => Container(
        height: 300,
        decoration: BoxDecoration(
          color: context.colors.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        l10n.cancel,
                        style: TextStyle(color: context.colors.textSecondary),
                      ),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        final profile = settings.userProfile.copyWith(birthday: selectedDate);
                        settings.updateUserProfile(profile);
                        Navigator.of(context).pop();
                      },
                      child: Text(
                        l10n.done,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Picker
              Expanded(
                child: CupertinoDatePicker(
                  backgroundColor: context.colors.background,
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: selectedDate,
                  minimumDate: DateTime(1900, 1, 1),
                  maximumDate: DateTime.now(),
                  onDateTimeChanged: (DateTime newDate) {
                    selectedDate = newDate;
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  void _showYearPicker(BuildContext context, SettingsService settings) {
    final l10n = AppLocalizations.of(context)!;
    final currentYear = DateTime.now().year;
    int selectedYear = settings.userProfile.diagnosisYear ?? currentYear;

    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => Container(
        height: 250,
        decoration: BoxDecoration(
          color: context.colors.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        l10n.cancel,
                        style: TextStyle(color: context.colors.textSecondary),
                      ),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        final profile = settings.userProfile.copyWith(diagnosisYear: selectedYear);
                        settings.updateUserProfile(profile);
                        Navigator.of(context).pop();
                      },
                      child: Text(
                        l10n.done,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Picker
              Expanded(
                child: CupertinoPicker(
                  backgroundColor: context.colors.background,
                  itemExtent: 40,
                  scrollController: FixedExtentScrollController(
                    initialItem: currentYear - (settings.userProfile.diagnosisYear ?? currentYear),
                  ),
                  onSelectedItemChanged: (int index) {
                    selectedYear = currentYear - index;
                  },
                  children: List.generate(
                    100,
                    (index) => Center(child: Text('${currentYear - index}')),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showWeightPicker(BuildContext context, SettingsService settings) {
    final l10n = AppLocalizations.of(context)!;
    final decimalSeparator = _getDecimalSeparator(context);
    final initialValue = settings.userProfile.weightKg != null
        ? _formatWeight(settings.userProfile.weightKg, context)
        : '';
    final controller = TextEditingController(text: initialValue);
    final placeholder = decimalSeparator == ',' ? '0,0' : '0.0';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          behavior: HitTestBehavior.opaque,
          child: GestureDetector(
            onTap: () {},
            child: Container(
              decoration: BoxDecoration(
                color: context.colors.background,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          CupertinoButton(
                            padding: EdgeInsets.zero,
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text(
                              l10n.cancel,
                              style: TextStyle(color: context.colors.textSecondary),
                            ),
                          ),
                          Text(
                            l10n.weight,
                            style: context.textStyles.tileTitle.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          CupertinoButton(
                            padding: EdgeInsets.zero,
                            onPressed: () async {
                              final normalizedText = controller.text.replaceAll(',', '.');
                              final value = double.tryParse(normalizedText);
                              if (value != null && value > 0) {
                                final profile = settings.userProfile.copyWith(weightKg: value);
                                settings.updateUserProfile(profile);

                                // Apple Health에도 체중 저장
                                final healthService = HealthService();
                                await healthService.writeWeight(value);
                              }
                              if (context.mounted) {
                                Navigator.of(context).pop();
                              }
                            },
                            child: Text(
                              l10n.done,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Weight input field
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: CupertinoTextField(
                              controller: controller,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                              placeholder: placeholder,
                              placeholderStyle: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[400],
                              ),
                              decoration: BoxDecoration(
                                color: context.colors.card,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: context.colors.divider),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                              autofocus: true,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'^\d*[.,]?\d{0,1}')),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'kg',
                            style: context.textStyles.bodyTextSecondary.copyWith(
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

}
