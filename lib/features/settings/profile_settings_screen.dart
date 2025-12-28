import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';

import 'package:glu_butler/l10n/app_localizations.dart';
import 'package:glu_butler/core/theme/app_theme.dart';
import 'package:glu_butler/core/theme/app_text_styles.dart';
import 'package:glu_butler/core/theme/app_colors.dart';
import 'package:glu_butler/core/widgets/glass_icon.dart';
import 'package:glu_butler/services/settings_service.dart';

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
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settings = context.watch<SettingsService>();

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: CupertinoNavigationBar(
        backgroundColor: context.colors.background,
        border: null,
        middle: Text(
          l10n.profile,
          style: context.textStyles.tileTitle,
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          children: [
            // Personal Section
            _buildSectionTitle(context, l10n.personal),
            _buildGroupedSection(
              context: context,
              children: [
                _buildSettingsTile(
                  context: context,
                  icon: CupertinoIcons.person_fill,
                  iconColor: AppTheme.iconBlue,
                  title: l10n.name,
                  subtitle: settings.userProfile.name ?? '-',
                  onTap: () {
                    // TODO: Navigate to name edit
                  },
                ),
                _buildDivider(context),
                _buildAdaptivePopupTile(
                  context: context,
                  icon: CupertinoIcons.person_2_fill,
                  iconColor: AppTheme.iconPurple,
                  title: l10n.gender,
                  displayValue: _getGenderLabel(settings.userProfile.gender, l10n),
                  items: [
                    AdaptivePopupMenuItem<String>(value: 'male', label: l10n.male),
                    AdaptivePopupMenuItem<String>(value: 'female', label: l10n.female),
                  ],
                  onSelected: (index, item) {
                    final profile = settings.userProfile.copyWith(gender: item.value);
                    settings.updateUserProfile(profile);
                  },
                ),
                _buildDivider(context),
                _buildSettingsTile(
                  context: context,
                  icon: CupertinoIcons.calendar,
                  iconColor: AppTheme.iconOrange,
                  title: l10n.birthday,
                  subtitle: settings.userProfile.birthday != null
                      ? '${settings.userProfile.birthday!.year}.${settings.userProfile.birthday!.month}.${settings.userProfile.birthday!.day}'
                      : '-',
                  onTap: () {
                    _showDatePicker(context, settings);
                  },
                ),
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
                  items: [
                    AdaptivePopupMenuItem<String>(value: 'type1', label: l10n.type1),
                    AdaptivePopupMenuItem<String>(value: 'type2', label: l10n.type2),
                    AdaptivePopupMenuItem<String>(value: 'none', label: l10n.none),
                  ],
                  onSelected: (index, item) {
                    final profile = settings.userProfile.copyWith(diabetesType: item.value);
                    settings.updateUserProfile(profile);
                  },
                ),
                _buildDivider(context),
                _buildSettingsTile(
                  context: context,
                  icon: CupertinoIcons.calendar_badge_plus,
                  iconColor: AppTheme.iconGreen,
                  title: l10n.yearOfDiagnosis,
                  subtitle: settings.userProfile.diagnosisYear?.toString() ?? '-',
                  onTap: () {
                    _showYearPicker(context, settings);
                  },
                ),
              ],
            ),

            const SizedBox(height: 32),
          ],
        ),
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

  Widget _buildSettingsTile({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              GlassIcon(icon: icon, color: iconColor, size: 32),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: context.textStyles.tileTitle,
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: context.textStyles.tileSubtitle,
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                CupertinoIcons.chevron_right,
                size: 16,
                color: context.colors.iconGrey,
              ),
            ],
          ),
        ),
      ),
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
  }) {
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
          AdaptivePopupMenuButton.widget<String>(
            items: items,
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
      default:
        return '-';
    }
  }

  String _getDiabetesTypeLabel(String? type, AppLocalizations l10n) {
    if (type == null) return '-';
    switch (type) {
      case 'type1':
        return l10n.type1;
      case 'type2':
        return l10n.type2;
      default:
        return l10n.none;
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
                      child: Text(l10n.cancel),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        final profile = settings.userProfile.copyWith(birthday: selectedDate);
                        settings.updateUserProfile(profile);
                        Navigator.of(context).pop();
                      },
                      child: Text(l10n.done, style: const TextStyle(fontWeight: FontWeight.w600)),
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
                      child: Text(l10n.cancel),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        final profile = settings.userProfile.copyWith(diagnosisYear: selectedYear);
                        settings.updateUserProfile(profile);
                        Navigator.of(context).pop();
                      },
                      child: Text(l10n.done, style: const TextStyle(fontWeight: FontWeight.w600)),
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

}
