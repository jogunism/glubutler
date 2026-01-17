import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import 'package:glu_butler/l10n/app_localizations.dart';
import 'package:glu_butler/core/constants/app_constants.dart';
import 'package:glu_butler/core/theme/app_theme.dart';
import 'package:glu_butler/core/theme/app_text_styles.dart';
import 'package:glu_butler/core/theme/app_colors.dart';
import 'package:glu_butler/core/theme/app_decorations.dart';
import 'package:glu_butler/services/settings_service.dart';
import 'package:glu_butler/core/widgets/glass_icon.dart';
import 'package:glu_butler/core/widgets/large_title_scroll_view.dart';

/// 디스플레이 설정 화면
///
/// 앱의 테마 모드를 설정하는 화면입니다.
/// iOS 스타일의 라디오 버튼 리스트로 테마를 선택합니다.
///
/// ## 테마 옵션
/// | 모드 | 아이콘 | 설명 |
/// |------|--------|------|
/// | 시스템 기본 | device_phone_portrait | 기기 설정 따름 |
/// | 라이트 모드 | sun_max_fill | 항상 밝은 테마 |
/// | 다크 모드 | moon_fill | 항상 어두운 테마 |
///
/// ## 상태 관리
/// - [SettingsService.themeMode] - 현재 테마 모드 읽기
/// - [SettingsService.setThemeMode] - 테마 모드 변경
///
/// ## 라우팅
/// - `/settings/display` - 설정 화면에서 네비게이션
///
/// ## 디자인 상수
/// - [AppTheme.iosBackground] - iOS 스타일 배경색
/// - [AppTheme.iosCard] - iOS 스타일 카드색
/// - [AppTheme.iconOrange] - 라이트 모드 아이콘
/// - [AppTheme.iconIndigo] - 다크 모드 아이콘
///
/// ## 관련 파일
/// - [SettingsService] - 테마 설정 저장/로드
/// - [SettingsScreen] - 부모 설정 화면
/// - [AppConstants] - 테마 모드 상수
class DisplaySettingsScreen extends StatelessWidget {
  const DisplaySettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settings = context.watch<SettingsService>();
    final currentMode = settings.themeMode;

    return LargeTitleScrollView(
      title: l10n.displaySettings,
      showBackButton: true,
      showLargeTitle: false,
      onRefresh: null,
      slivers: [
        // Appearance Section Title
        SliverToBoxAdapter(
          child: _buildSectionTitle(context, l10n.appearance),
        ),

        // Theme Mode Section
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          sliver: SliverToBoxAdapter(
            child: Container(
              decoration: context.decorations.card,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildThemeOption(
                    context: context,
                    icon: CupertinoIcons.device_phone_portrait,
                    iconColor: context.colors.iconGrey,
                    title: l10n.systemDefault,
                    subtitle: l10n.systemDefaultDescription,
                    value: AppConstants.themeModeSystem,
                    currentValue: currentMode,
                    onTap: () => settings.setThemeMode(AppConstants.themeModeSystem),
                    isFirst: true,
                  ),
                  _buildDivider(context),
                  _buildThemeOption(
                    context: context,
                    icon: CupertinoIcons.sun_max_fill,
                    iconColor: AppTheme.iconOrange,
                    title: l10n.lightMode,
                    value: AppConstants.themeModeLight,
                    currentValue: currentMode,
                    onTap: () => settings.setThemeMode(AppConstants.themeModeLight),
                  ),
                  _buildDivider(context),
                  _buildThemeOption(
                    context: context,
                    icon: CupertinoIcons.moon_fill,
                    iconColor: AppTheme.iconIndigo,
                    title: l10n.darkModeOption,
                    value: AppConstants.themeModeDark,
                    currentValue: currentMode,
                    onTap: () => settings.setThemeMode(AppConstants.themeModeDark),
                    isLast: true,
                  ),
                ],
              ),
            ),
          ),
        ),

        // Text Size Section Title
        SliverToBoxAdapter(
          child: _buildSectionTitle(context, l10n.textSizeTitle),
        ),

        // Text Size Section
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          sliver: SliverToBoxAdapter(
            child: Container(
              decoration: context.decorations.card,
              padding: const EdgeInsets.all(16),
              child: _buildTextSizeSlider(context, settings),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 24, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: context.colors.textSecondary,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildThemeOption({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    required String value,
    required String currentValue,
    required VoidCallback onTap,
    bool isFirst = false,
    bool isLast = false,
  }) {
    final isSelected = value == currentValue;
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.vertical(
          top: isFirst ? const Radius.circular(12) : Radius.zero,
          bottom: isLast ? const Radius.circular(12) : Radius.zero,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              GlassIcon(
                icon: icon,
                color: iconColor,
                size: 32,
              ),
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
              if (isSelected)
                Icon(
                  CupertinoIcons.checkmark,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
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

  Widget _buildTextSizeSlider(BuildContext context, SettingsService settings) {
    final l10n = AppLocalizations.of(context)!;

    // Convert scale to slider value (0, 1, 2)
    int sliderValue;
    if (settings.textScale == AppConstants.textScaleSmall) {
      sliderValue = 0;
    } else if (settings.textScale == AppConstants.textScaleMedium) {
      sliderValue = 1;
    } else {
      sliderValue = 2;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              l10n.textSizeSmall,
              style: context.textStyles.tileSubtitle.copyWith(fontSize: 12),
            ),
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: AppTheme.primaryColor,
                  inactiveTrackColor: context.colors.divider,
                  thumbColor: AppTheme.primaryColor,
                  overlayColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                  trackHeight: 4,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                ),
                child: Slider(
                  value: sliderValue.toDouble(),
                  min: 0,
                  max: 2,
                  divisions: 2,
                  onChanged: (value) {
                    double newScale;
                    if (value == 0) {
                      newScale = AppConstants.textScaleSmall;
                    } else if (value == 1) {
                      newScale = AppConstants.textScaleMedium;
                    } else {
                      newScale = AppConstants.textScaleLarge;
                    }
                    settings.setTextScale(newScale);
                  },
                ),
              ),
            ),
            Text(
              l10n.textSizeLarge,
              style: context.textStyles.tileSubtitle.copyWith(fontSize: 16),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            sliderValue == 0 ? l10n.textSizeSmall : (sliderValue == 1 ? l10n.textSizeMedium : l10n.textSizeLarge),
            style: context.textStyles.tileSubtitle.copyWith(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
