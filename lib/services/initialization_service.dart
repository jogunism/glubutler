import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'package:glu_butler/services/settings_service.dart';
import 'package:glu_butler/services/cloudkit_service.dart';
import 'package:glu_butler/services/firestore_service.dart';
import 'package:glu_butler/services/notification_service.dart';

/// 앱 초기화 서비스
///
/// 앱 시작 시 필요한 모든 초기화 작업을 수행합니다.
/// [SplashScreen]에서 호출되어 로딩 화면을 표시하는 동안 실행됩니다.
///
/// ## 초기화 작업
/// 1. **설정 로드** - [SettingsService]에서 사용자 설정 로드
/// 2. **건강앱 동기화** - HealthKit/Google Fit 데이터 동기화
/// 3. **(향후) iCloud 동기화** - 클라우드 데이터 동기화
/// 4. **(향후) 로컬 DB 초기화** - Hive 데이터베이스 초기화
///
/// ## 사용 예시
/// ```dart
/// final initService = InitializationService(settingsService: settingsService);
/// await initService.initialize();
/// ```
///
/// ## 관련 파일
/// - [SplashScreen] - 초기화 중 표시되는 화면
/// - [SettingsService] - 설정 상태 관리
/// 초기화 단계 열거형
enum InitializationStep {
  settings,
  healthSync,
  iCloudSync,
  localDatabase,
  notifications,
  done,
}

class InitializationService {
  final SettingsService settingsService;
  final void Function(InitializationStep step)? onStepChanged;

  InitializationService({
    required this.settingsService,
    this.onStepChanged,
  });

  /// 모든 초기화 작업 수행
  ///
  /// 순차적으로 초기화 작업을 실행하며, 각 단계 완료 시 로그를 출력합니다.
  /// 에러 발생 시에도 앱 실행을 계속하도록 각 단계별로 try-catch 처리합니다.
  Future<void> initialize() async {
    // 1. 설정 로드 (이미 main.dart에서 수행됨)
    if (settingsService.hapticEnabled) {
      HapticFeedback.mediumImpact(); // 첫 번째 "툭"
    }
    onStepChanged?.call(InitializationStep.settings);
    await _loadSettings();

    // 2. 건강앱 동기화
    if (settingsService.hapticEnabled) {
      HapticFeedback.mediumImpact(); // 두 번째 "툭"
    }
    onStepChanged?.call(InitializationStep.healthSync);
    await _syncHealthData();

    // 3. iCloud 동기화
    onStepChanged?.call(InitializationStep.iCloudSync);
    await _synciCloudData();

    // 4. 로컬 DB 초기화
    onStepChanged?.call(InitializationStep.localDatabase);
    await _initializeLocalDatabase();

    // 5. 알림 스케줄링
    onStepChanged?.call(InitializationStep.notifications);
    await _scheduleNotifications();

    // 6. 완료
    if (settingsService.hapticEnabled) {
      HapticFeedback.lightImpact(); // 완료 "툭" (가볍게)
    }
    onStepChanged?.call(InitializationStep.done);
  }

  /// 설정 로드
  Future<void> _loadSettings() async {
    // SettingsService.init()은 이미 main.dart에서 호출됨
    // 추가 설정 로드가 필요한 경우 여기에 구현
    await Future.delayed(const Duration(milliseconds: 600));
  }

  /// 건강앱 데이터 동기화
  ///
  /// HealthKit (iOS) 또는 Google Fit (Android)에서 데이터를 가져옵니다.
  /// 건강앱 연결이 활성화된 경우에만 동기화를 수행합니다.
  Future<void> _syncHealthData() async {
    // 최소 표시 시간 보장
    const minDisplayTime = Duration(milliseconds: 400);
    final startTime = DateTime.now();

    if (settingsService.isHealthConnected) {
      try {
        // TODO: 실제 HealthKit/Google Fit 동기화 구현
        await Future.delayed(const Duration(milliseconds: 800));
      } catch (e) {
        debugPrint('[InitializationService] Health sync error: $e');
      }
    }

    // 최소 표시 시간까지 대기
    final elapsed = DateTime.now().difference(startTime);
    if (elapsed < minDisplayTime) {
      await Future.delayed(minDisplayTime - elapsed);
    }
  }

  /// 클라우드 데이터 동기화
  ///
  /// iOS: iCloud(CloudKit), Android: Firestore
  /// 업로드는 다이어리 작성/수정/삭제 시 실시간으로 처리되므로 여기서는 다운로드만 수행합니다.
  Future<void> _synciCloudData() async {
    // 최소 표시 시간 보장
    const minDisplayTime = Duration(milliseconds: 400);
    final startTime = DateTime.now();

    if (Platform.isIOS) {
      await _syncIOS();
    } else {
      await _syncAndroid();
    }

    // 최소 표시 시간까지 대기
    final elapsed = DateTime.now().difference(startTime);
    if (elapsed < minDisplayTime) {
      await Future.delayed(minDisplayTime - elapsed);
    }
  }

  Future<void> _syncIOS() async {
    if (!settingsService.iCloudSyncEnabled) return;

    try {
      final isAvailable = await CloudKitService.isAvailable();
      final isSignedIn = await CloudKitService.isUserSignedIn();

      if (isAvailable && isSignedIn) {
        // Service start date 체크 (무료 체험 우회 방지)
        try {
          final iCloudDate = await CloudKitService.fetchServiceStartDate();
          if (iCloudDate != null) {
            final localDate = settingsService.serviceStartDate;
            if (localDate == null || iCloudDate.isBefore(localDate)) {
              debugPrint('[InitializationService] Updating service start date from iCloud: $iCloudDate');
              await settingsService.updateServiceStartDateFromICloud(iCloudDate);
            }
          }
        } catch (e) {
          debugPrint('[InitializationService] Failed to sync service start date: $e');
        }

        // 리포트 다운로드 (다이어리는 main.dart에서 백그라운드 동기화)
        await CloudKitService.downloadReports();
      }
    } catch (e) {
      debugPrint('[InitializationService] iCloud sync error: $e');
    }
  }

  Future<void> _syncAndroid() async {
    if (!settingsService.googleSyncEnabled) return;

    final googleId = settingsService.userIdentity.googleId;
    if (googleId == null || googleId.isEmpty) return;

    try {
      // Service start date 체크 (무료 체험 우회 방지)
      try {
        final firestoreDate = await FirestoreService.fetchServiceStartDate(googleId);
        if (firestoreDate != null) {
          final localDate = settingsService.serviceStartDate;
          if (localDate == null || firestoreDate.isBefore(localDate)) {
            debugPrint('[InitializationService] Updating service start date from Firestore: $firestoreDate');
            await settingsService.updateServiceStartDateFromICloud(firestoreDate);
          }
        }
      } catch (e) {
        debugPrint('[InitializationService] Failed to sync service start date from Firestore: $e');
      }

      // 리포트 다운로드
      await FirestoreService.downloadReports(googleId);
    } catch (e) {
      debugPrint('[InitializationService] Firestore sync error: $e');
    }
  }

  /// 로컬 데이터베이스 추가 초기화
  ///
  /// 데이터베이스는 이미 main.dart에서 초기화되었습니다.
  /// 이 단계는 향후 앱 업데이트 시 다음 작업을 위해 예약되어 있습니다:
  /// - 데이터 마이그레이션
  /// - 스키마 업데이트
  /// - 캐시 정리
  Future<void> _initializeLocalDatabase() async {
    // 최소 표시 시간
    await Future.delayed(const Duration(milliseconds: 400));
  }

  /// 알림 스케줄링
  ///
  /// 온보딩을 완료한 사용자만 설정에 따라 알림을 스케줄링합니다.
  /// 권한 요청은 온보딩에서 이미 처리되었으므로 여기서는 스케줄링만 수행합니다.
  ///
  /// ## 알림 종류 (iOS 플랫폼 제약으로 인한 설계)
  ///
  /// ### 1. 혈당 측정 알림
  /// - 시간: 18:00
  /// - 메시지: "꾸준한 혈당 측정을 권장합니다\n식전 식후의 혈당 변화를 관찰해 보세요"
  /// - 로직: 스플래시에서 오늘 혈당 측정 3회 이상이면 → 알림 취소
  ///
  /// ### 2. 일기 작성 알림
  /// - 시간: 22:00
  /// - 메시지: "오늘의 혈당 일기를 작성해 보세요"
  /// - 로직: 스플래시에서 오늘 일기 있으면 → 알림 취소
  ///
  /// ### 3. 리포트 생성 권장 알림 (조건부 등록)
  /// - 시간: 10:00
  /// - 메시지: "건강 리포트를 확인하세요"
  /// - 로직: 리포트가 없거나 마지막 리포트 후 3일 경과 시에만 등록
  ///
  /// ## 제약 사항
  /// iOS는 백그라운드에서 Flutter 코드 실행 불가
  /// → 앱을 열지 않으면 조건 체크 불가능 (예: 오전에 혈당 3회 측정했지만 앱을 안 열면 18시에 알림 발송됨)
  Future<void> _scheduleNotifications() async {
    // 최소 표시 시간 보장
    const minDisplayTime = Duration(milliseconds: 400);
    final startTime = DateTime.now();

    if (settingsService.hasCompletedOnboarding) {
      try {
        final notificationService = NotificationService();

        // 만료된 알림 정리
        await notificationService.cleanupExpiredNotifications();

        // 1. Fixed 알림 등록 (매일 고정 시간에 발송)
        //    - 혈당 측정 알림: 18:00
        //    - 일기 작성 알림: 22:00
        //    - 설정에서 ON인 경우에만 등록
        await notificationService.scheduleAllNotifications();

        // 2. 조건부 알림 처리
        //    - 리포트 알림: 조건 충족 시에만 등록 (마지막 리포트 후 3일 경과)
        await notificationService.scheduleReportReminderIfNeeded();

        // 3. 조건부 알림 취소 (오늘 조건 충족 시 오늘 알림 취소)
        //    - 혈당 알림: 오늘 3회 이상 측정했으면 오늘 18시 알림 취소
        //    - 일기 알림: 오늘 일기 작성했으면 오늘 22시 알림 취소
        await notificationService.cancelGlucoseReminderIfNeeded();
        await notificationService.cancelDiaryReminderIfNeeded();

        debugPrint('[InitializationService] Notifications scheduled successfully');
      } catch (e) {
        debugPrint('[InitializationService] Notification scheduling error: $e');
      }
    }

    // 최소 표시 시간까지 대기
    final elapsed = DateTime.now().difference(startTime);
    if (elapsed < minDisplayTime) {
      await Future.delayed(minDisplayTime - elapsed);
    }
  }
}
