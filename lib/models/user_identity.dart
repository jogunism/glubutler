/// 사용자 식별 정보
///
/// 서버에서 우선순위에 따라 사용자를 식별
/// - cloudKitId: iCloud 연동 시 CloudKit에서 받아오는 사용자 ID (iOS, 기기간 동기화)
/// - googleId: Google 로그인으로 받아오는 사용자 ID (Android, 기기간 동기화)
/// - idfv: iOS Identifier For Vendor (앱 재설치 시에도 유지, 같은 기기)
class UserIdentity {
  /// iOS Identifier For Vendor (IDFV)
  /// 앱 재설치 시에도 유지되는 기기 고유 ID
  /// 동일 vendor의 모든 앱이 삭제되기 전까지 유지됨
  final String? idfv;

  /// CloudKit 사용자 ID (iOS 전용)
  /// iCloud 연동 시에만 사용 가능 (기기간 동기화)
  final String? cloudKitId;

  /// Google 사용자 ID (Android 전용)
  /// Google 로그인 시 발급되는 고유 ID (기기간 동기화)
  final String? googleId;

  const UserIdentity({
    this.idfv,
    this.cloudKitId,
    this.googleId,
  });

  /// 플랫폼 공통 사용자 ID
  /// iOS: cloudKitId, Android: googleId
  String? get userId => cloudKitId ?? googleId;

  /// JSON으로 변환 (API 전송용)
  Map<String, dynamic> toJson() {
    return {
      if (idfv != null) 'idfv': idfv,
      if (cloudKitId != null) 'cloudKitId': cloudKitId,
      if (googleId != null) 'googleId': googleId,
    };
  }

  /// JSON에서 생성
  factory UserIdentity.fromJson(Map<String, dynamic> json) {
    return UserIdentity(
      idfv: json['idfv'] as String?,
      cloudKitId: json['cloudKitId'] as String?,
      googleId: json['googleId'] as String?,
    );
  }

  /// IDFV 업데이트
  UserIdentity withIdfv(String idfv) {
    return UserIdentity(
      idfv: idfv,
      cloudKitId: cloudKitId,
      googleId: googleId,
    );
  }

  /// CloudKit ID 업데이트 (iOS 전용)
  UserIdentity withCloudKitId(String cloudKitId) {
    return UserIdentity(
      idfv: idfv,
      cloudKitId: cloudKitId,
      googleId: googleId,
    );
  }

  /// Google ID 업데이트 (Android 전용)
  UserIdentity withGoogleId(String googleId) {
    return UserIdentity(
      idfv: idfv,
      cloudKitId: cloudKitId,
      googleId: googleId,
    );
  }

  @override
  String toString() {
    return 'UserIdentity(idfv: $idfv, cloudKitId: $cloudKitId, googleId: $googleId)';
  }
}
