/// 사용자 식별 정보
///
/// 3가지 ID를 모두 보유하여 서버에서 우선순위에 따라 사용자를 식별
/// - deviceId: 앱 첫 실행 시 생성되는 UUIDv7 (필수, 영구 보관)
/// - cloudKitId: iCloud 연동 시 CloudKit에서 받아오는 사용자 ID (선택)
/// - receiptId: 유료 구독 시 App Store Receipt의 Original Transaction ID (선택)
class UserIdentity {
  /// 기기 고유 ID (UUIDv7)
  /// 앱 첫 실행 시 생성되며 절대 변경되지 않음
  final String deviceId;

  /// CloudKit 사용자 ID
  /// iCloud 연동 시에만 사용 가능
  final String? cloudKitId;

  /// App Store Receipt의 Original Transaction ID
  /// 유료 구독 후에만 사용 가능
  final String? receiptId;

  const UserIdentity({
    required this.deviceId,
    this.cloudKitId,
    this.receiptId,
  });

  /// JSON으로 변환 (API 전송용)
  Map<String, dynamic> toJson() {
    return {
      'deviceId': deviceId,
      if (cloudKitId != null) 'cloudKitId': cloudKitId,
      if (receiptId != null) 'receiptId': receiptId,
    };
  }

  /// JSON에서 생성
  factory UserIdentity.fromJson(Map<String, dynamic> json) {
    return UserIdentity(
      deviceId: json['deviceId'] as String,
      cloudKitId: json['cloudKitId'] as String?,
      receiptId: json['receiptId'] as String?,
    );
  }

  /// CloudKit ID 업데이트
  UserIdentity withCloudKitId(String cloudKitId) {
    return UserIdentity(
      deviceId: deviceId,
      cloudKitId: cloudKitId,
      receiptId: receiptId,
    );
  }

  /// Receipt ID 업데이트
  UserIdentity withReceiptId(String receiptId) {
    return UserIdentity(
      deviceId: deviceId,
      cloudKitId: cloudKitId,
      receiptId: receiptId,
    );
  }

  @override
  String toString() {
    return 'UserIdentity(deviceId: $deviceId, cloudKitId: $cloudKitId, receiptId: $receiptId)';
  }
}
