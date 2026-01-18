import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:glu_butler/models/notification_type.dart';
import 'package:glu_butler/services/database_service.dart';
import 'package:glu_butler/core/navigation/app_router.dart';
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
          'glucoseReminderTitle': 'Check your glucose',
          'glucoseReminderBody': 'Record your blood glucose level',
          'glucoseAbsenceTitle': 'Don\'t forget to measure',
          'glucoseAbsenceBody': 'Consistent tracking is the first step to glucose management',
          'diaryReminderTitle': 'Record your meal',
          'diaryReminderBody': 'Track your eating patterns',
          'reportReminderTitle': 'Create a health report',
          'reportReminderBody': 'Generate your glucose report',
        };
      case 'ja':
        return {
          'glucoseReminderTitle': '血糖値を確認して記録しましょう',
          'glucoseReminderBody': '食前血糖値を測定してください',
          'glucoseAbsenceTitle': '血糖値測定を忘れずに',
          'glucoseAbsenceBody': '継続的な記録が血糖管理の第一歩です',
          'diaryReminderTitle': '食事内容を記録しましょう',
          'diaryReminderBody': '食生活パターンを把握できます',
          'reportReminderTitle': '健康レポートを作成しましょう',
          'reportReminderBody': '血糖レポートを確認してください',
        };
      case 'zh':
        return {
          'glucoseReminderTitle': '检查并记录血糖',
          'glucoseReminderBody': '请测量餐前血糖',
          'glucoseAbsenceTitle': '别忘了测量血糖',
          'glucoseAbsenceBody': '坚持记录是血糖管理的第一步',
          'diaryReminderTitle': '记录您的饮食',
          'diaryReminderBody': '追踪您的饮食习惯',
          'reportReminderTitle': '创建健康报告',
          'reportReminderBody': '生成血糖报告',
        };
      case 'de':
        return {
          'glucoseReminderTitle': 'Überprüfen Sie Ihren Blutzucker',
          'glucoseReminderBody': 'Messen Sie Ihren Blutzuckerspiegel',
          'glucoseAbsenceTitle': 'Vergessen Sie nicht zu messen',
          'glucoseAbsenceBody': 'Konsequentes Tracking ist der erste Schritt',
          'diaryReminderTitle': 'Zeichnen Sie Ihre Mahlzeit auf',
          'diaryReminderBody': 'Verfolgen Sie Ihre Essgewohnheiten',
          'reportReminderTitle': 'Erstellen Sie einen Gesundheitsbericht',
          'reportReminderBody': 'Generieren Sie Ihren Glukosebericht',
        };
      case 'es':
        return {
          'glucoseReminderTitle': 'Revisa tu glucosa',
          'glucoseReminderBody': 'Registra tu nivel de glucosa en sangre',
          'glucoseAbsenceTitle': 'No olvides medir',
          'glucoseAbsenceBody': 'El seguimiento constante es el primer paso',
          'diaryReminderTitle': 'Registra tu comida',
          'diaryReminderBody': 'Haz seguimiento de tus hábitos alimenticios',
          'reportReminderTitle': 'Crea un informe de salud',
          'reportReminderBody': 'Genera tu informe de glucosa',
        };
      case 'fr':
        return {
          'glucoseReminderTitle': 'Vérifiez votre glycémie',
          'glucoseReminderBody': 'Enregistrez votre taux de glucose sanguin',
          'glucoseAbsenceTitle': 'N\'oubliez pas de mesurer',
          'glucoseAbsenceBody': 'Le suivi régulier est la première étape',
          'diaryReminderTitle': 'Enregistrez votre repas',
          'diaryReminderBody': 'Suivez vos habitudes alimentaires',
          'reportReminderTitle': 'Créez un rapport de santé',
          'reportReminderBody': 'Générez votre rapport de glucose',
        };
      case 'it':
        return {
          'glucoseReminderTitle': 'Controlla il tuo glucosio',
          'glucoseReminderBody': 'Registra il tuo livello di glucosio nel sangue',
          'glucoseAbsenceTitle': 'Non dimenticare di misurare',
          'glucoseAbsenceBody': 'Il monitoraggio costante è il primo passo',
          'diaryReminderTitle': 'Registra il tuo pasto',
          'diaryReminderBody': 'Monitora le tue abitudini alimentari',
          'reportReminderTitle': 'Crea un report sulla salute',
          'reportReminderBody': 'Genera il tuo report sul glucosio',
        };
      default: // ko
        return {
          'glucoseReminderTitle': '혈당을 확인하고 기록을 남겨보세요',
          'glucoseReminderBody': '식전 혈당을 측정해보세요',
          'glucoseAbsenceTitle': '혈당 측정을 잊지 마세요',
          'glucoseAbsenceBody': '꾸준한 기록이 혈당 관리의 첫걸음입니다',
          'diaryReminderTitle': '식사 내용을 기록해 보세요',
          'diaryReminderBody': '자신의 식생활 패턴을 파악할 수 있습니다',
          'reportReminderTitle': '혈당 리포트를 생성해 보세요',
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

      // 타임존 초기화 (백그라운드에서도 필요)
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Asia/Seoul'));

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
        case 'checkMealGlucoseMorning':
          await _checkAndSendMealGlucoseReminder(
            notifications,
            prefs,
            databaseService,
            9,
            NotificationType.glucoseReminderMorning,
          );
          break;

        case 'checkMealGlucoseLunch':
          await _checkAndSendMealGlucoseReminder(
            notifications,
            prefs,
            databaseService,
            12,
            NotificationType.glucoseReminderLunch,
          );
          break;

        case 'checkMealGlucoseDinner':
          await _checkAndSendMealGlucoseReminder(
            notifications,
            prefs,
            databaseService,
            19,
            NotificationType.glucoseReminderDinner,
          );
          break;

        case 'checkLongTermGlucoseAbsence':
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

/// 식전 혈당 데이터 체크 및 조건부 알림 발송
Future<void> _checkAndSendMealGlucoseReminder(
  FlutterLocalNotificationsPlugin notifications,
  SharedPreferences prefs,
  DatabaseService databaseService,
  int mealHour,
  NotificationType type,
) async {
  // 설정 체크
  final isEnabled = prefs.getBool(type.prefsKey) ?? true;
  if (!isEnabled) {
    debugPrint('[NotificationService] ${type.name} is disabled');
    return;
  }

  // 해당 시간대의 혈당 데이터가 있는지 체크
  final now = DateTime.now();
  final startOfDay = DateTime(now.year, now.month, now.day);
  final mealTime = DateTime(now.year, now.month, now.day, mealHour);

  final records = await databaseService.getGlucoseRecords(
    startDate: startOfDay,
    endDate: mealTime,
  );

  // 해당 시간 전에 이미 기록이 있으면 알림 보내지 않음
  final hasRecordBeforeMeal = records.any((record) {
    return record.timestamp.hour < mealHour;
  });

  if (hasRecordBeforeMeal) {
    debugPrint('[NotificationService] Glucose record exists before meal time, skipping notification');
    return;
  }

  // 국제화 메시지 가져오기
  final messages = await _NotificationMessages.getMessages();

  // 알림 발송
  await notifications.show(
    type.id,
    messages['glucoseReminderTitle'],
    messages['glucoseReminderBody'],
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'meal_glucose_reminders',
        '식전 혈당 측정 알림',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    ),
    payload: 'feed_glucose',
  );

  debugPrint('[NotificationService] Sent meal glucose reminder for ${type.name}');
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
    messages['glucoseAbsenceTitle'],
    messages['glucoseAbsenceBody'],
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

  /// 알림 서비스 초기화
  Future<void> initialize() async {
    if (_isInitialized) return;

    // 타임존 초기화
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Seoul'));

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

    // Android만 Workmanager 초기화
    if (defaultTargetPlatform == TargetPlatform.android) {
      await Workmanager().initialize(
        notificationBackgroundCallback,
        isInDebugMode: kDebugMode,
      );
    }

    _isInitialized = true;
  }

  /// 알림 권한 요청 (iOS)
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
    return true;
  }

  /// 현재 알림 권한 상태 확인
  Future<bool> checkPermissionStatus() async {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final result = await _notifications
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.checkPermissions();

      // isEnabled가 true면 권한이 허용된 상태
      return result?.isEnabled ?? false;
    }
    // Android는 기본적으로 true (권한이 필요 없음)
    return true;
  }

  /// 알림 클릭 시 처리
  void _onNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null) return;

    debugPrint('[NotificationService] Notification tapped: $payload');

    // 페이로드에 따라 화면 라우팅
    final context = AppRouter.router.routerDelegate.navigatorKey.currentContext;
    if (context == null) {
      debugPrint('[NotificationService] No context available for navigation');
      return;
    }

    // 먼저 메인 화면으로 이동
    AppRouter.router.go('/home');

    // 딜레이 후 탭 전환 및 모달 열기
    Future.delayed(const Duration(milliseconds: 300), () {
      switch (payload) {
        case 'feed_glucose':
          // 피드 탭으로 이동 후 혈당 기록 팝업
          MainScreen.switchToTabAndOpenModal(0, 'open_glucose_input');
          break;

        case 'diary':
          // 일기 탭으로 이동 후 일기 입력 팝업
          MainScreen.switchToTabAndOpenModal(2, 'open_diary_input');
          break;

        case 'report':
          // 리포트 탭으로 이동 후 리포트 생성 트리거
          MainScreen.switchToTabAndOpenModal(3, 'trigger_report_generation');
          break;

        default:
          debugPrint('[NotificationService] Unknown payload: $payload');
      }
    });
  }

  /// 모든 알림 스케줄 업데이트
  Future<void> scheduleAllNotifications() async {
    await initialize();
    final prefs = await SharedPreferences.getInstance();

    for (final type in NotificationType.values) {
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
      case NotificationType.glucoseReminderMorning:
        await _scheduleWorkmanagerTask('checkMealGlucoseMorning', 8, 0);
        break;
      case NotificationType.glucoseReminderLunch:
        await _scheduleWorkmanagerTask('checkMealGlucoseLunch', 11, 0);
        break;
      case NotificationType.glucoseReminderDinner:
        await _scheduleWorkmanagerTask('checkMealGlucoseDinner', 18, 0);
        break;
      case NotificationType.glucoseRecordReminder:
        await _scheduleWorkmanagerTask('checkLongTermGlucoseAbsence', 10, 0);
        break;
      case NotificationType.diaryReminder:
        await _scheduleWorkmanagerTask('checkDiaryAbsence', 20, 0);
        break;
      case NotificationType.firstReportReminder:
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
      case NotificationType.glucoseReminderMorning:
        await _scheduleDailyNotificationIOS(
          type.id,
          8, 0,
          messages['glucoseReminderTitle']!,
          messages['glucoseReminderBody'],
          'feed_glucose',
        );
        break;
      case NotificationType.glucoseReminderLunch:
        await _scheduleDailyNotificationIOS(
          type.id,
          11, 0,
          messages['glucoseReminderTitle']!,
          messages['glucoseReminderBody'],
          'feed_glucose',
        );
        break;
      case NotificationType.glucoseReminderDinner:
        await _scheduleDailyNotificationIOS(
          type.id,
          18, 0,
          messages['glucoseReminderTitle']!,
          messages['glucoseReminderBody'],
          'feed_glucose',
        );
        break;
      case NotificationType.glucoseRecordReminder:
        await _scheduleDailyNotificationIOS(
          type.id,
          10, 0,
          messages['glucoseAbsenceTitle']!,
          messages['glucoseAbsenceBody'],
          'feed_glucose',
        );
        break;
      case NotificationType.diaryReminder:
        await _scheduleDailyNotificationIOS(
          type.id,
          20, 0,
          messages['diaryReminderTitle']!,
          messages['diaryReminderBody'],
          'diary',
        );
        break;
      case NotificationType.firstReportReminder:
      case NotificationType.reportReminder:
        await _scheduleDailyNotificationIOS(
          type.id,
          10, 0,
          messages['reportReminderTitle']!,
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
    String title,
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
      existingWorkPolicy: ExistingWorkPolicy.replace,
      constraints: Constraints(
        networkType: NetworkType.not_required,
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
        case NotificationType.glucoseReminderMorning:
          taskName = 'checkMealGlucoseMorning';
          break;
        case NotificationType.glucoseReminderLunch:
          taskName = 'checkMealGlucoseLunch';
          break;
        case NotificationType.glucoseReminderDinner:
          taskName = 'checkMealGlucoseDinner';
          break;
        case NotificationType.glucoseRecordReminder:
          taskName = 'checkLongTermGlucoseAbsence';
          break;
        case NotificationType.diaryReminder:
          taskName = 'checkDiaryAbsence';
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
}
