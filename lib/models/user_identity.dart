/// 사용자 식별 정보
///
/// 서버에서 우선순위에 따라 사용자를 식별
/// - cloudKitId: iCloud 연동 시 CloudKit에서 받아오는 사용자 ID (최우선, 기기간 동기화)
/// - idfv: iOS Identifier For Vendor (앱 재설치 시에도 유지, 같은 기기)
class UserIdentity {
  /// iOS Identifier For Vendor (IDFV)
  /// 앱 재설치 시에도 유지되는 기기 고유 ID
  /// 동일 vendor의 모든 앱이 삭제되기 전까지 유지됨
  final String? idfv;

  /// CloudKit 사용자 ID
  /// iCloud 연동 시에만 사용 가능 (기기간 동기화)
  final String? cloudKitId;

  const UserIdentity({
    this.idfv,
    this.cloudKitId,
  });

  /// JSON으로 변환 (API 전송용)
  Map<String, dynamic> toJson() {
    return {
      if (idfv != null) 'idfv': idfv,
      if (cloudKitId != null) 'cloudKitId': cloudKitId,
    };
  }

  /// JSON에서 생성
  factory UserIdentity.fromJson(Map<String, dynamic> json) {
    return UserIdentity(
      idfv: json['idfv'] as String?,
      cloudKitId: json['cloudKitId'] as String?,
    );
  }

  /// IDFV 업데이트
  UserIdentity withIdfv(String idfv) {
    return UserIdentity(
      idfv: idfv,
      cloudKitId: cloudKitId,
    );
  }

  /// CloudKit ID 업데이트
  UserIdentity withCloudKitId(String cloudKitId) {
    return UserIdentity(
      idfv: idfv,
      cloudKitId: cloudKitId,
    );
  }

  @override
  String toString() {
    return 'UserIdentity(idfv: $idfv, cloudKitId: $cloudKitId)';
  }
}
