/// 알림 타입
enum NotificationType {
  /// 첫 리포트 생성 권장 (앱 설치 후 7일 이상 경과, 리포트 없음)
  firstReportReminder,

  /// 리포트 생성 권장 (마지막 리포트 후 3일 경과)
  reportReminder,

  /// 혈당 측정 알림 (하루 3회 미만 측정 시, 18:00)
  glucoseRecordReminder,

  /// 일기 작성 알림 (오늘 일기 없을 시, 22:00)
  diaryReminder,
}

extension NotificationTypeExtension on NotificationType {
  /// 알림 카테고리
  NotificationCategory get category {
    switch (this) {
      case NotificationType.glucoseRecordReminder:
        return NotificationCategory.glucose;

      case NotificationType.diaryReminder:
        return NotificationCategory.diary;

      case NotificationType.firstReportReminder:
      case NotificationType.reportReminder:
        return NotificationCategory.report;
    }
  }

  /// SharedPreferences 저장 키
  String get prefsKey => 'notification_${name}_enabled';

  /// 고유 알림 ID (flutter_local_notifications용)
  int get id {
    switch (this) {
      case NotificationType.firstReportReminder:
        return 1;
      case NotificationType.reportReminder:
        return 2;
      case NotificationType.glucoseRecordReminder:
        return 7;
      case NotificationType.diaryReminder:
        return 6;
    }
  }
}

/// 알림 카테고리 (그룹)
enum NotificationCategory {
  glucose,  // 혈당
  diary,    // 일기
  report,   // 리포트
}
