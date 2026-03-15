import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:glu_butler/models/notification_type.dart';
import 'package:glu_butler/services/database_service.dart';
import 'package:glu_butler/services/health_service.dart';
import 'package:glu_butler/core/navigation/main_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:workmanager/workmanager.dart';

/// 알림 메시지 헬퍼 - SharedPreferences에서 언어 설정 읽어오기
class _NotificationMessages {
  static Future<Map<String, String>> getMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final locale = prefs.getString('locale') ?? 'ko';

    switch (locale) {
      case 'en':
        return {
          'glucoseReminderBody': 'Regular glucose monitoring is recommended\nObserve glucose changes before and after meals',
          'diaryReminderBody': 'Write your glucose diary for today',
          'reportReminderBody': 'Check your health report',
        };
      case 'ja':
        return {
          'glucoseReminderBody': '定期的な血糖測定をお勧めします\n食前食後の血糖変化を観察してみましょう',
          'diaryReminderBody': '今日の血糖日記を書いてみましょう',
          'reportReminderBody': '健康レポートを確認してください',
        };
      case 'zh':
        return {
          'glucoseReminderBody': '建议定期测量血糖\n观察餐前餐后的血糖变化',
          'diaryReminderBody': '记录今天的血糖日记吧',
          'reportReminderBody': '查看健康报告',
        };
      case 'de':
        return {
          'glucoseReminderBody': 'Regelmäßige Blutzuckermessung wird empfohlen\nBeobachten Sie Blutzuckerveränderungen vor und nach den Mahlzeiten',
          'diaryReminderBody': 'Schreiben Sie Ihr heutiges Blutzucker-Tagebuch',
          'reportReminderBody': 'Überprüfen Sie Ihren Gesundheitsbericht',
        };
      case 'es':
        return {
          'glucoseReminderBody': 'Se recomienda la medición regular de glucosa\nObserva los cambios de glucosa antes y después de las comidas',
          'diaryReminderBody': 'Escribe tu diario de glucosa de hoy',
          'reportReminderBody': 'Revisa tu informe de salud',
        };
      case 'fr':
        return {
          'glucoseReminderBody': 'Une surveillance régulière de la glycémie est recommandée\nObservez les changements de glycémie avant et après les repas',
          'diaryReminderBody': 'Écrivez votre journal de glycémie d\'aujourd\'hui',
          'reportReminderBody': 'Consultez votre rapport de santé',
        };
      case 'it':
        return {
          'glucoseReminderBody': 'Si consiglia un monitoraggio regolare del glucosio\nOsserva i cambiamenti del glucosio prima e dopo i pasti',
          'diaryReminderBody': 'Scrivi il tuo diario del glucosio di oggi',
          'reportReminderBody': 'Controlla il tuo report sulla salute',
        };
      default: // ko
        return {
          'glucoseReminderBody': '꾸준한 혈당 측정을 권장합니다\n식전 식후의 혈당 변화를 관찰해 보세요',
          'diaryReminderBody': '오늘의 혈당 일기를 작성해 보세요',
          'reportReminderBody': '건강 리포트를 확인하세요',
        };
    }
  }
}

/// Workmanager 백그라운드 작업 콜백
///
/// 이 함수는 앱이 종료된 상태에서도 실행됩니다.
@pragma('vm:entry-point')
void notificationBackgroundCallback() {
  Workmanager().executeTask((task, inputData) async {
    try {
      debugPrint('[NotificationService] Background task started: $task');

      // 타임존 초기화 (백그라운드에서도 필요) - 기기의 현재 타임존 사용
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.local);

      // 데이터베이스 서비스 초기화
      final databaseService = DatabaseService();
      await databaseService.initialize();

      // 알림 플러그인 초기화
      final notifications = FlutterLocalNotificationsPlugin();
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings();
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );
      await notifications.initialize(initSettings);

      // SharedPreferences 로드
      final prefs = await SharedPreferences.getInstance();

      switch (task) {
        case 'checkGlucoseReminder':
          await _checkAndSendLongTermAbsenceReminder(
            notifications,
            prefs,
            databaseService,
          );
          break;

        case 'checkDiaryAbsence':
          await _checkAndSendDiaryReminder(
            notifications,
            prefs,
            databaseService,
          );
          break;

        case 'checkReportReminder':
          await _checkAndSendReportReminder(
            notifications,
            prefs,
            databaseService,
          );
          break;
      }

      return Future.value(true);
    } catch (e) {
      debugPrint('[NotificationService] Background task error: $e');
      return Future.value(false);
    }
  });
}

/// 장기간 혈당 기록 부재 체크 및 조건부 알림 발송
Future<void> _checkAndSendLongTermAbsenceReminder(
  FlutterLocalNotificationsPlugin notifications,
  SharedPreferences prefs,
  DatabaseService databaseService,
) async {
  // 설정 체크
  final isEnabled = prefs.getBool(NotificationType.glucoseRecordReminder.prefsKey) ?? true;
  if (!isEnabled) {
    debugPrint('[NotificationService] Long-term glucose absence reminder is disabled');
    return;
  }

  // 최근 3일간 혈당 기록 체크
  final threeDaysAgo = DateTime.now().subtract(const Duration(days: 3));
  final records = await databaseService.getGlucoseRecords(
    startDate: threeDaysAgo,
    endDate: DateTime.now(),
  );

  // 국제화 메시지 가져오기
  final messages = await _NotificationMessages.getMessages();

  // 알림 발송
  await notifications.show(
    NotificationType.glucoseRecordReminder.id,
    null,
    messages['glucoseReminderBody'],
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'glucose_absence_reminder',
        '장기간 혈당 기록 부재 알림',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    ),
    payload: 'feed_glucose',
  );

  debugPrint('[NotificationService] Sent long-term glucose absence reminder (has records: ${records.isNotEmpty})');
}

/// 장기간 일기 작성 부재 체크 및 조건부 알림 발송
Future<void> _checkAndSendDiaryReminder(
  FlutterLocalNotificationsPlugin notifications,
  SharedPreferences prefs,
  DatabaseService databaseService,
) async {
  // 설정 체크
  final isEnabled = prefs.getBool(NotificationType.diaryReminder.prefsKey) ?? true;
  if (!isEnabled) {
    debugPrint('[NotificationService] Diary reminder is disabled');
    return;
  }

  // 최근 3일간 일기 기록 체크
  final threeDaysAgo = DateTime.now().subtract(const Duration(days: 3));
  final diaries = await databaseService.getDiaryEntries(
    startDate: threeDaysAgo,
    endDate: DateTime.now(),
  );

  // 3일 이상 일기가 없을 때만 알림 발송
  if (diaries.isNotEmpty) {
    debugPrint('[NotificationService] Diary entries exist in last 3 days, skipping notification');
    return;
  }

  // 국제화 메시지 가져오기
  final messages = await _NotificationMessages.getMessages();

  // 알림 발송
  await notifications.show(
    NotificationType.diaryReminder.id,
    messages['diaryReminderTitle'],
    messages['diaryReminderBody'],
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'diary_absence_reminder',
        '장기간 일기 작성 부재 알림',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    ),
    payload: 'diary',
  );

  debugPrint('[NotificationService] Sent diary absence reminder');
}

/// 리포트 생성 알림 체크 및 발송
Future<void> _checkAndSendReportReminder(
  FlutterLocalNotificationsPlugin notifications,
  SharedPreferences prefs,
  DatabaseService databaseService,
) async {
  // 설정 체크
  final isFirstEnabled = prefs.getBool(NotificationType.firstReportReminder.prefsKey) ?? true;
  final isRegularEnabled = prefs.getBool(NotificationType.reportReminder.prefsKey) ?? true;

  if (!isFirstEnabled && !isRegularEnabled) {
    debugPrint('[NotificationService] Report reminders are disabled');
    return;
  }

  // 리포트 생성 이력 체크
  final reports = await databaseService.getAllReports();

  bool shouldSend = false;
  if (reports.isEmpty && isFirstEnabled) {
    // 첫 리포트 미생성
    shouldSend = true;
  } else if (reports.isNotEmpty && isRegularEnabled) {
    // 마지막 리포트 이후 3일 경과 체크
    final latestReport = await databaseService.getLatestReport();
    if (latestReport != null) {
      final threeDaysAgo = DateTime.now().subtract(const Duration(days: 3));
      if (latestReport.createdAt.isBefore(threeDaysAgo)) {
        shouldSend = true;
      } else {
        debugPrint('[NotificationService] Last report is within 3 days, skipping notification');
        return;
      }
    } else {
      return;
    }
  } else {
    return;
  }

  if (!shouldSend) return;

  // 국제화 메시지 가져오기
  final messages = await _NotificationMessages.getMessages();

  // 알림 발송
  await notifications.show(
    NotificationType.reportReminder.id,
    messages['reportReminderTitle'],
    messages['reportReminderBody'],
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'report_reminder',
        '리포트 생성 알림',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    ),
    payload: 'report',
  );

  debugPrint('[NotificationService] Sent report reminder');
}

/// 로컬 알림 관리 서비스
///
/// Flutter Local Notifications와 Workmanager를 사용하여 조건부 알림을 관리합니다.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  final DatabaseService _databaseService = DatabaseService();

  bool _isInitialized = false;

  // 앱 시작 시 알림으로 실행된 경우의 페이로드 저장
  static String? _pendingLaunchPayload;

  /// MainScreen이 준비되었을 때 pending payload를 처리하는 static 메서드
  static void handlePendingPayloadIfReady() {
    if (_pendingLaunchPayload != null && MainScreen.globalKey.currentState != null) {
      final payload = _pendingLaunchPayload!;
      _pendingLaunchPayload = null;
      NotificationService()._handleNotificationPayload(payload);
    }
  }

  /// 알림 서비스 초기화
  Future<void> initialize() async {
    if (_isInitialized) return;

    // 타임존 초기화 - 기기의 현재 타임존 사용
    tz.initializeTimeZones();
    final String currentTimeZone = DateTime.now().timeZoneName;
    final String timeZoneOffset = DateTime.now().timeZoneOffset.toString();
    debugPrint('[NotificationService] Device timezone: $currentTimeZone, offset: $timeZoneOffset');

    // 기기의 로컬 타임존으로 설정
    tz.setLocalLocation(tz.local);

    // Android 설정
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS 설정 - 권한 요청은 온보딩에서만 수행
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Android 알림 채널 생성
    if (defaultTargetPlatform == TargetPlatform.android) {
      await _createAndroidNotificationChannels();
    }

    // 앱이 종료된 상태에서 알림을 클릭해서 실행된 경우 처리
    final launchDetails = await _notifications.getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp ?? false) {
      final payload = launchDetails?.notificationResponse?.payload;
      if (payload != null) {
        _pendingLaunchPayload = payload;
      }
    }

    // Android만 Workmanager 초기화
    if (defaultTargetPlatform == TargetPlatform.android) {
      await Workmanager().initialize(
        notificationBackgroundCallback,
        isInDebugMode: kDebugMode,
      );
    }

    _isInitialized = true;
  }

  /// Android 알림 채널 생성 (Android 8.0+)
  Future<void> _createAndroidNotificationChannels() async {
    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin == null) return;

    await androidPlugin.createNotificationChannel(const AndroidNotificationChannel(
      'glucose_reminder',
      '혈당 측정 알림',
      description: '혈당 측정을 권장하는 알림',
      importance: Importance.high,
    ));

    await androidPlugin.createNotificationChannel(const AndroidNotificationChannel(
      'diary_reminder',
      '일기 작성 알림',
      description: '혈당 일기 작성을 권장하는 알림',
      importance: Importance.defaultImportance,
    ));

    await androidPlugin.createNotificationChannel(const AndroidNotificationChannel(
      'report_reminder',
      '리포트 알림',
      description: '건강 리포트 확인을 권장하는 알림',
      importance: Importance.defaultImportance,
    ));
  }

  /// 알림 권한 요청 (iOS: 시스템 다이얼로그, Android 13+: POST_NOTIFICATIONS)
  Future<bool> requestPermissions() async {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final result = await _notifications
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
      return result ?? false;
    }

    // Android 13+ (API 33+): POST_NOTIFICATIONS 런타임 권한 요청
    if (defaultTargetPlatform == TargetPlatform.android) {
      final androidPlugin = _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      final granted = await androidPlugin?.requestNotificationsPermission();
      return granted ?? true;
    }

    return true;
  }

  /// 현재 알림 권한 상태 확인
  Future<bool> checkPermissionStatus() async {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final result = await _notifications
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.checkPermissions();
      return result?.isEnabled ?? false;
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      final androidPlugin = _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      return await androidPlugin?.areNotificationsEnabled() ?? true;
    }

    return true;
  }

  /// 알림 클릭 시 처리
  void _onNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null) return;

    _handleNotificationPayload(payload);
  }

  /// 알림 페이로드 처리 (앱 실행 중 또는 종료 상태에서 공통 처리)
  void _handleNotificationPayload(String payload) {
    if (MainScreen.globalKey.currentState == null) return;

    final context = MainScreen.globalKey.currentContext;
    if (context == null) return;

    // 현재 push된 모든 화면 닫기 (MainScreen으로 돌아가기)
    Navigator.of(context).popUntil((route) => route.isFirst);

    // 딜레이 후 탭 전환 및 모달 열기
    Future.delayed(const Duration(milliseconds: 300), () {
      switch (payload) {
        case 'feed_glucose':
          MainScreen.switchToTabAndOpenModal(1, 'open_glucose_input');
          break;
        case 'diary':
          MainScreen.switchToTabAndOpenModal(2, 'open_diary_input');
          break;
        case 'report':
          MainScreen.switchToTabAndOpenModal(3, 'trigger_report_generation');
          break;
      }
    });
  }

  /// 모든 알림 스케줄 업데이트
  Future<void> scheduleAllNotifications() async {
    await initialize();
    final prefs = await SharedPreferences.getInstance();

    for (final type in NotificationType.values) {
      // 리포트 알림은 조건부 스케줄링이므로 제외
      if (type == NotificationType.reportReminder ||
          type == NotificationType.firstReportReminder) {
        continue;
      }

      final isEnabled = prefs.getBool(type.prefsKey) ?? true;

      if (isEnabled) {
        // Android는 Workmanager, iOS는 직접 스케줄링
        if (defaultTargetPlatform == TargetPlatform.android) {
          await _scheduleNotification(type);
        } else {
          await _scheduleNotificationIOS(type);
        }
      } else {
        await cancelNotification(type);
      }
    }
  }

  /// 특정 알림 타입 스케줄링
  Future<void> _scheduleNotification(NotificationType type) async {
    switch (type) {
      case NotificationType.glucoseRecordReminder:
        await _scheduleWorkmanagerTask('checkGlucoseReminder', 18, 0);
        break;
      case NotificationType.diaryReminder:
        await _scheduleWorkmanagerTask('checkDiaryReminder', 22, 0);
        break;
      case NotificationType.firstReportReminder:
        // firstReportReminder는 reportReminder와 동일한 조건부 체크를 사용하므로 별도 스케줄 불필요
        break;
      case NotificationType.reportReminder:
        await _scheduleWorkmanagerTask('checkReportReminder', 10, 0);
        break;
    }
  }

  /// iOS용 알림 스케줄링 (매일 반복)
  Future<void> _scheduleNotificationIOS(NotificationType type) async {
    // 국제화 메시지 가져오기
    final messages = await _NotificationMessages.getMessages();

    switch (type) {
      case NotificationType.glucoseRecordReminder:
        await _scheduleDailyNotificationIOS(
          type.id,
          18, 0,
          null,
          messages['glucoseReminderBody'],
          'feed_glucose',
        );
        break;
      case NotificationType.diaryReminder:
        await _scheduleDailyNotificationIOS(
          type.id,
          22, 0,
          null,
          messages['diaryReminderBody'],
          'diary',
        );
        break;
      case NotificationType.firstReportReminder:
        // firstReportReminder는 reportReminder와 동일한 조건부 체크를 사용하므로 별도 스케줄 불필요
        break;
      case NotificationType.reportReminder:
        await _scheduleDailyNotificationIOS(
          type.id,
          10, 0,
          null,
          messages['reportReminderBody'],
          'report',
        );
        break;
    }
  }

  /// iOS용 매일 반복 알림 스케줄링 헬퍼
  Future<void> _scheduleDailyNotificationIOS(
    int id,
    int hour,
    int minute,
    String? title,
    String? body,
    String payload,
  ) async {
    await _notifications.zonedSchedule(
      id,
      title,
      body,
      _nextInstanceOfTime(hour, minute),
      const NotificationDetails(
        iOS: DarwinNotificationDetails(),
        android: AndroidNotificationDetails(
          'daily_reminders',
          '일일 알림',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: payload,
    );

    debugPrint('[NotificationService] Scheduled iOS notification: id=$id at $hour:$minute');
  }

  /// 다음 발생 시간 계산
  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  /// Workmanager 작업 스케줄링 (Android용)
  Future<void> _scheduleWorkmanagerTask(
    String taskName,
    int hour,
    int minute,
  ) async {
    // 매일 지정된 시간에 실행되도록 스케줄
    final now = DateTime.now();
    var scheduledTime = DateTime(now.year, now.month, now.day, hour, minute);

    // 이미 지난 시간이면 다음날로 설정
    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }

    final initialDelay = scheduledTime.difference(now);

    await Workmanager().registerPeriodicTask(
      taskName,
      taskName,
      frequency: const Duration(days: 1),
      initialDelay: initialDelay,
      existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
      constraints: Constraints(
        networkType: NetworkType.notRequired,
      ),
    );

    debugPrint('[NotificationService] Scheduled workmanager task: $taskName at $hour:$minute');
  }

  /// 특정 알림 취소
  Future<void> cancelNotification(NotificationType type) async {
    await _notifications.cancel(type.id);

    // Android만 Workmanager 작업 취소
    if (defaultTargetPlatform == TargetPlatform.android) {
      String taskName;
      switch (type) {
        case NotificationType.glucoseRecordReminder:
          taskName = 'checkGlucoseReminder';
          break;
        case NotificationType.diaryReminder:
          taskName = 'checkDiaryReminder';
          break;
        case NotificationType.firstReportReminder:
        case NotificationType.reportReminder:
          taskName = 'checkReportReminder';
          break;
      }

      await Workmanager().cancelByUniqueName(taskName);
    }

    debugPrint('[NotificationService] Cancelled notification: ${type.name}');
  }

  /// 모든 알림 취소
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();

    // Android만 Workmanager 작업 취소
    if (defaultTargetPlatform == TargetPlatform.android) {
      await Workmanager().cancelAll();
    }

    debugPrint('[NotificationService] Cancelled all notifications');
  }

  /// 3일 이상 혈당 기록이 없는지 체크
  Future<bool> hasGlucoseRecordInLastThreeDays() async {
    final threeDaysAgo = DateTime.now().subtract(const Duration(days: 3));
    final records = await _databaseService.getGlucoseRecords(
      startDate: threeDaysAgo,
      endDate: DateTime.now(),
    );
    return records.isNotEmpty;
  }

  /// 3일 이상 일기 작성이 없는지 체크
  Future<bool> hasDiaryInLastThreeDays() async {
    final threeDaysAgo = DateTime.now().subtract(const Duration(days: 3));
    final diaries = await _databaseService.getDiaryEntries(
      startDate: threeDaysAgo,
      endDate: DateTime.now(),
    );
    return diaries.isNotEmpty;
  }

  /// 리포트가 한번도 생성되지 않았는지 체크
  Future<bool> hasNeverCreatedReport() async {
    final reports = await _databaseService.getAllReports();
    return reports.isEmpty;
  }

  /// 마지막 리포트 이후 3일이 지났는지 체크
  Future<bool> isLastReportOlderThanThreeDays() async {
    final latestReport = await _databaseService.getLatestReport();
    if (latestReport == null) return false;

    final threeDaysAgo = DateTime.now().subtract(const Duration(days: 3));
    return latestReport.createdAt.isBefore(threeDaysAgo);
  }

  /// 개발용: 10초 후 테스트 알림 발송
  Future<void> scheduleTestNotification(NotificationType type) async {
    await initialize();

    final now = tz.TZDateTime.now(tz.local);
    final scheduledTime = now.add(const Duration(seconds: 10));

    // 국제화 메시지 가져오기
    final messages = await _NotificationMessages.getMessages();

    String? body;
    String payload;

    switch (type) {
      case NotificationType.glucoseRecordReminder:
        body = messages['glucoseReminderBody'];
        payload = 'feed_glucose';
        break;
      case NotificationType.diaryReminder:
        body = messages['diaryReminderBody'];
        payload = 'diary';
        break;
      case NotificationType.firstReportReminder:
      case NotificationType.reportReminder:
        body = messages['reportReminderBody'];
        payload = 'report';
        break;
    }

    await _notifications.zonedSchedule(
      999 + type.id, // 테스트 알림은 999 + id로 구분
      null,
      body,
      scheduledTime,
      NotificationDetails(
        iOS: DarwinNotificationDetails(
          sound: 'default',
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
        android: AndroidNotificationDetails(
          'test_notifications',
          '테스트 알림',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );

    debugPrint('[NotificationService] Test notification scheduled for ${type.name} at $scheduledTime');
  }

  /// 개발용: 모든 테스트 알림 스케줄 취소
  Future<void> cancelAllTestNotifications() async {
    for (final type in NotificationType.values) {
      await _notifications.cancel(999 + type.id);
    }
    debugPrint('[NotificationService] All test notifications cancelled');
  }

  /// 개발용: 알림 처리 로직을 직접 테스트
  void testNotificationHandler(String payload) {
    _handleNotificationPayload(payload);
  }

  /// 리포트 알림 조건부 스케줄링 (앱 시작 시 호출)
  Future<void> scheduleReportReminderIfNeeded() async {
    await initialize();

    final prefs = await SharedPreferences.getInstance();
    final isEnabled = prefs.getBool(NotificationType.reportReminder.prefsKey) ?? true;

    if (!isEnabled) return;

    // 1. 리포트 조건 체크
    final latestReport = await _databaseService.getLatestReport();
    final shouldSchedule = latestReport == null ||
        latestReport.endDate.isBefore(DateTime.now().subtract(const Duration(days: 4)));

    if (!shouldSchedule) {
      // 조건 미충족 시 기존 알림 취소
      await cancelNotification(NotificationType.reportReminder);
      await prefs.remove('report_reminder_scheduled_date');
      return;
    }

    // 2. 오늘 이미 스케줄했는지 확인 (날짜로 체크)
    final scheduledDateStr = prefs.getString('report_reminder_scheduled_date');
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month}-${today.day}';

    if (scheduledDateStr == todayStr) {
      // 오늘 이미 스케줄했으면 패스
      return;
    }

    // 3. 이미 예정된 알림이 있는지 확인
    final pendingNotifications = await _notifications.pendingNotificationRequests();
    final isAlreadyScheduled = pendingNotifications.any(
      (notification) => notification.id == NotificationType.reportReminder.id,
    );

    if (isAlreadyScheduled) {
      // 예정된 알림은 있지만 날짜 기록이 없으면 오늘 날짜로 저장
      await prefs.setString('report_reminder_scheduled_date', todayStr);
      return;
    }

    // 4. 조건 충족 + 미등록 → 알림 스케줄
    // 참고: 스케줄 시간(10:00)이 이미 지났으면 flutter_local_notifications가
    // 자동으로 다음날로 스케줄링하므로 별도 날짜 체크 불필요
    if (defaultTargetPlatform == TargetPlatform.android) {
      await _scheduleNotification(NotificationType.reportReminder);
    } else {
      await _scheduleNotificationIOS(NotificationType.reportReminder);
    }

    // 5. 스케줄 등록 완료 - 오늘 날짜 저장
    await prefs.setString('report_reminder_scheduled_date', todayStr);
  }

  /// 리포트 생성 시 알림 취소
  Future<void> cancelReportReminder() async {
    await cancelNotification(NotificationType.reportReminder);

    // 스케줄 날짜 기록도 삭제
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('report_reminder_scheduled_date');
  }

  /// 혈당 알림 조건부 취소 (앱 시작 시 호출)
  ///
  /// 오늘 혈당 측정 횟수가 3회 이상이면 오늘 18시 혈당 알림 취소
  /// (수동 입력 + HealthKit/CGM 데이터 모두 포함)
  Future<void> cancelGlucoseReminderIfNeeded() async {
    await initialize();

    final prefs = await SharedPreferences.getInstance();
    final isEnabled = prefs.getBool(NotificationType.glucoseRecordReminder.prefsKey) ?? true;

    if (!isEnabled) return;

    // 오늘 혈당 측정 횟수 체크
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    // 1. DB에서 수동 입력 혈당 가져오기
    final dbRecords = await _databaseService.getGlucoseRecords(
      startDate: todayStart,
      endDate: todayEnd,
    );

    // 2. HealthKit에서 혈당 가져오기 (CGM 포함)
    final healthService = HealthService();
    final healthKitRecords = await healthService.fetchGlucoseData(
      startDate: todayStart,
      endDate: todayEnd,
    );

    // 3. 중복 제거를 위해 ID 기반으로 합치기
    //    (DB 레코드는 id, HealthKit 레코드는 hk_ prefix)
    final allRecordIds = <String>{};
    allRecordIds.addAll(dbRecords.map((r) => r.id));
    allRecordIds.addAll(healthKitRecords.map((r) => r.id));

    final totalCount = allRecordIds.length;

    // 오늘 혈당 측정 3회 이상이면 알림 취소
    if (totalCount >= 3) {
      await cancelNotification(NotificationType.glucoseRecordReminder);
      debugPrint('[NotificationService] Glucose reminder cancelled - today: $totalCount measurements (DB: ${dbRecords.length}, HealthKit: ${healthKitRecords.length})');
    }
  }

  /// 일기 알림 조건부 취소 (앱 시작 시 호출)
  ///
  /// 오늘 일기가 존재하면 오늘 22시 일기 알림 취소
  Future<void> cancelDiaryReminderIfNeeded() async {
    await initialize();

    final prefs = await SharedPreferences.getInstance();
    final isEnabled = prefs.getBool(NotificationType.diaryReminder.prefsKey) ?? true;

    if (!isEnabled) return;

    // 오늘 일기 존재 여부 체크
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    final diaryEntries = await _databaseService.getDiaryEntries(
      startDate: todayStart,
      endDate: todayEnd,
    );

    // 오늘 일기가 있으면 알림 취소
    if (diaryEntries.isNotEmpty) {
      await cancelNotification(NotificationType.diaryReminder);
      debugPrint('[NotificationService] Diary reminder cancelled - today has ${diaryEntries.length} entries');
    }
  }

  /// 만료된 알림 정리 (앱 시작 시 호출)
  Future<void> cleanupExpiredNotifications() async {
    await initialize();

    final pendingNotifications = await _notifications.pendingNotificationRequests();
    final now = DateTime.now();

    // 모든 pending 알림을 확인하고 이미 지난 시간의 알림은 취소
    for (final notification in pendingNotifications) {
      // 테스트 알림(ID 999+)은 제외
      if (notification.id >= 999) continue;

      // flutter_local_notifications의 반복 알림은 자동으로 다음 날짜로 갱신되므로
      // pending 목록에 있는 알림은 모두 미래 시간이어야 함
      // 하지만 혹시 모를 버그나 시스템 시간 변경으로 과거 알림이 남아있을 수 있으므로 체크
      // (실제로는 거의 발생하지 않음)
    }

    // SharedPreferences에 저장된 스케줄 날짜가 오늘보다 이전이면 삭제
    final prefs = await SharedPreferences.getInstance();
    final scheduledDateStr = prefs.getString('report_reminder_scheduled_date');

    if (scheduledDateStr != null) {
      try {
        final parts = scheduledDateStr.split('-');
        final scheduledDate = DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );

        final today = DateTime(now.year, now.month, now.day);
        final savedDate = DateTime(scheduledDate.year, scheduledDate.month, scheduledDate.day);

        // 오늘보다 이전 날짜면 삭제 (어제 이전 날짜)
        if (savedDate.isBefore(today)) {
          await prefs.remove('report_reminder_scheduled_date');
        }
      } catch (e) {
        // 파싱 실패 시 삭제
        await prefs.remove('report_reminder_scheduled_date');
      }
    }
  }
}
