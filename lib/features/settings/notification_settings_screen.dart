import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:glu_butler/l10n/app_localizations.dart';
import 'package:glu_butler/core/theme/app_text_styles.dart';
import 'package:glu_butler/core/theme/app_colors.dart';
import 'package:glu_butler/core/theme/app_theme.dart';
import 'package:glu_butler/core/widgets/large_title_scroll_view.dart';
import 'package:glu_butler/models/notification_type.dart';
import 'package:glu_butler/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_settings/app_settings.dart';

/// 알림 관리 화면
///
/// 알림 타입별로 on/off 설정을 관리합니다.
/// 혈당, 일기, 리포트 세 가지 카테고리로 그룹화되어 있습니다.
class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> with WidgetsBindingObserver {
  final Map<NotificationType, bool> _notificationSettings = {};
  bool _isLoading = true;
  bool _hasPermission = true;
  bool _permissionDeniedOnce = false; // 권한 한 번이라도 거부했는지 추적

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadSettings();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 앱이 다시 활성화되면 권한 상태 재확인
    if (state == AppLifecycleState.resumed) {
      _checkPermissionAndRefresh();
    }
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final notificationService = NotificationService();

    // 권한 상태 확인
    _hasPermission = await notificationService.checkPermissionStatus();

    for (final type in NotificationType.values) {
      // 기본값은 모두 true (활성화)
      _notificationSettings[type] = prefs.getBool(type.prefsKey) ?? true;
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 권한 상태 재확인 및 필요시 새로고침
  Future<void> _checkPermissionAndRefresh() async {
    final notificationService = NotificationService();
    final hasPermission = await notificationService.checkPermissionStatus();

    // 권한 상태가 변경되었으면 새로고침
    if (hasPermission != _hasPermission) {
      _hasPermission = hasPermission;

      // 권한이 새로 부여된 경우, 모든 알림을 켜고 스케줄링
      if (hasPermission) {
        final prefs = await SharedPreferences.getInstance();
        for (final type in NotificationType.values) {
          await prefs.setBool(type.prefsKey, true);
          _notificationSettings[type] = true;
        }
        await notificationService.scheduleAllNotifications();
        debugPrint('[NotificationSettings] Permission granted, enabled all notifications');
      }

      if (mounted) {
        setState(() {});
      }
    }
  }

  /// 그룹 설정 업데이트 (여러 타입을 한번에)
  Future<void> _updateGroupSetting(List<NotificationType> types, bool value) async {
    // 권한이 없으면 권한 요청
    if (!_hasPermission && value) {
      await _requestPermissionAndEnable(types);
      return;
    }

    final prefs = await SharedPreferences.getInstance();

    for (final type in types) {
      await prefs.setBool(type.prefsKey, value);
      _notificationSettings[type] = value;
    }

    setState(() {});

    // 알림 스케줄링 업데이트
    final notificationService = NotificationService();
    await notificationService.scheduleAllNotifications();

    debugPrint('[NotificationSettings] Updated group: ${types.map((t) => t.name).join(', ')} = $value');
  }

  /// 권한 요청 후 알림 활성화
  Future<void> _requestPermissionAndEnable(List<NotificationType> types) async {
    final notificationService = NotificationService();
    final granted = await notificationService.requestPermissions();

    if (granted) {
      // 권한 허용됨 - 요청한 타입들 활성화
      _hasPermission = true;
      final prefs = await SharedPreferences.getInstance();

      for (final type in types) {
        await prefs.setBool(type.prefsKey, true);
        _notificationSettings[type] = true;
      }

      await notificationService.scheduleAllNotifications();
      debugPrint('[NotificationSettings] Permission granted, enabled requested notifications');

      if (mounted) {
        setState(() {});
      }
    } else {
      // 권한 거부됨 - 플래그만 설정 (다이얼로그 없이)
      _permissionDeniedOnce = true;
      if (mounted) {
        setState(() {});
      }
    }
  }

  /// 그룹 전체가 활성화되어 있는지 확인
  bool _isGroupEnabled(List<NotificationType> types) {
    return types.every((type) => _notificationSettings[type] ?? true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CupertinoActivityIndicator(),
        ),
      );
    }

    return LargeTitleScrollView(
      title: l10n.notifications,
      showBackButton: true,
      onRefresh: null,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // 혈당 섹션
              _buildSectionTitle(context, l10n.bloodGlucose),
              _buildGroupedSection(
                context: context,
                children: [
                  _buildSimpleNotificationTile(
                    context: context,
                    types: [
                      NotificationType.glucoseReminderMorning,
                      NotificationType.glucoseReminderLunch,
                      NotificationType.glucoseReminderDinner,
                    ],
                    title: l10n.mealGlucoseReminders,
                  ),
                  _buildDivider(context),
                  _buildSimpleNotificationTile(
                    context: context,
                    types: [NotificationType.glucoseRecordReminder],
                    title: l10n.longTermGlucoseAbsence,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // 일기 섹션
              _buildSectionTitle(context, l10n.diary),
              _buildGroupedSection(
                context: context,
                children: [
                  _buildSimpleNotificationTile(
                    context: context,
                    types: [NotificationType.diaryReminder],
                    title: l10n.longTermDiaryAbsence,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // 리포트 섹션
              _buildSectionTitle(context, l10n.report),
              _buildGroupedSection(
                context: context,
                children: [
                  _buildSimpleNotificationTile(
                    context: context,
                    types: [
                      NotificationType.firstReportReminder,
                      NotificationType.reportReminder,
                    ],
                    title: l10n.reportGenerationReminder,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // 권한이 없을 때 안내 배너 (페이지 맨 아래)
              if (!_hasPermission) ...[
                _buildPermissionBanner(context, l10n),
                const SizedBox(height: 16),
              ],

              const SizedBox(height: 16),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildPermissionBanner(BuildContext context, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                CupertinoIcons.bell_slash,
                color: AppTheme.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.notificationPermissionRequired,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: context.colors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            l10n.notificationPermissionDescription,
            style: TextStyle(
              fontSize: 14,
              color: context.colors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: CupertinoButton(
              padding: const EdgeInsets.symmetric(vertical: 12),
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(12),
              onPressed: () async {
                if (_permissionDeniedOnce) {
                  // 이미 한 번 거부했으면 바로 iOS 설정으로 이동 (다이얼로그 없이)
                  AppSettings.openAppSettings(type: AppSettingsType.notification);
                } else {
                  // 처음이면 권한 요청 시도
                  final notificationService = NotificationService();
                  final granted = await notificationService.requestPermissions();

                  if (granted) {
                    // 권한 허용됨 - 모든 알림 활성화
                    _hasPermission = true;
                    final prefs = await SharedPreferences.getInstance();
                    for (final type in NotificationType.values) {
                      await prefs.setBool(type.prefsKey, true);
                      _notificationSettings[type] = true;
                    }
                    await notificationService.scheduleAllNotifications();
                    debugPrint('[NotificationSettings] Permission granted from banner, enabled all notifications');

                    if (mounted) {
                      setState(() {});
                    }
                  } else {
                    // 권한 거부됨 - 플래그만 설정 (iOS 설정으로 이동하지 않음)
                    _permissionDeniedOnce = true;
                    if (mounted) {
                      setState(() {});
                    }
                  }
                }
              },
              child: Text(
                _permissionDeniedOnce ? l10n.goToSettings : l10n.allowNotifications,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
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

  Widget _buildSimpleNotificationTile({
    required BuildContext context,
    required List<NotificationType> types,
    required String title,
  }) {
    // 모든 타입이 활성화되어 있으면 그룹도 활성화
    final isEnabled = _isGroupEnabled(types);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: context.textStyles.tileTitle.copyWith(
                color: _hasPermission
                    ? context.colors.textPrimary
                    : context.colors.textSecondary.withValues(alpha: 0.5),
              ),
            ),
          ),
          const SizedBox(width: 12),
          CupertinoSwitch(
            value: _hasPermission && isEnabled,
            onChanged: _hasPermission
                ? (value) => _updateGroupSetting(types, value)
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: Divider(
        height: 1,
        color: context.colors.divider,
      ),
    );
  }
}
