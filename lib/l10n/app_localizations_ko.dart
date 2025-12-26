// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appName => '글루 버틀러';

  @override
  String get feed => '피드';

  @override
  String get diary => '일기';

  @override
  String get report => '리포트';

  @override
  String get settings => '설정';

  @override
  String get add => '추가';

  @override
  String get cancel => '취소';

  @override
  String get close => '닫기';

  @override
  String get save => '저장';

  @override
  String get done => '완료';

  @override
  String get delete => '삭제';

  @override
  String get edit => '수정';

  @override
  String get selectDate => '날짜 선택';

  @override
  String get today => '오늘';

  @override
  String get yesterday => '어제';

  @override
  String get thisWeek => '이번 주';

  @override
  String get thisMonth => '이번 달';

  @override
  String get bloodGlucose => '혈당';

  @override
  String get meal => '식사';

  @override
  String get exercise => '운동';

  @override
  String get glucoseUnit => '단위';

  @override
  String get mgdl => 'mg/dL';

  @override
  String get mmoll => 'mmol/L';

  @override
  String get low => '저혈당';

  @override
  String get normal => '정상';

  @override
  String get high => '높음';

  @override
  String get breakfast => '아침';

  @override
  String get lunch => '점심';

  @override
  String get dinner => '저녁';

  @override
  String get snack => '간식';

  @override
  String get fasting => '공복';

  @override
  String get beforeMeal => '식전';

  @override
  String get afterMeal => '식후';

  @override
  String get unspecified => '미지정';

  @override
  String get dailyReport => '일일 리포트';

  @override
  String get weeklyReport => '주간 리포트';

  @override
  String get aiInsight => 'AI 인사이트';

  @override
  String get glucoseScore => '혈당 점수';

  @override
  String get profile => '프로필';

  @override
  String get name => '이름';

  @override
  String get gender => '성별';

  @override
  String get male => '남성';

  @override
  String get female => '여성';

  @override
  String get birthday => '생년월일';

  @override
  String get diabetesType => '당뇨 유형';

  @override
  String get type1 => '1형';

  @override
  String get type2 => '2형';

  @override
  String get none => '해당없음';

  @override
  String get language => '언어';

  @override
  String get changeInSettings => '설정 앱에서 변경';

  @override
  String get darkMode => '다크 모드';

  @override
  String get displaySettings => '화면';

  @override
  String get systemDefault => '시스템 설정';

  @override
  String get systemDefaultDescription => '시스템 테마를 따름';

  @override
  String get lightMode => '라이트';

  @override
  String get darkModeOption => '다크';

  @override
  String get notifications => '알림';

  @override
  String get notificationTime => '알림 시간';

  @override
  String get sync => '연동';

  @override
  String get healthConnect => '건강 앱 연동';

  @override
  String get iCloudSync => 'iCloud';

  @override
  String get iCloudSyncDescription => '여러기기와 동기화';

  @override
  String get connected => '연결됨';

  @override
  String get notConnected => '연결 안됨';

  @override
  String get connect => '연결하기';

  @override
  String get disconnect => '연결 해제';

  @override
  String get subscription => '구독';

  @override
  String get gluButlerPro => '글루 버틀러 Pro';

  @override
  String get upgradeToPro => 'Pro로 업그레이드';

  @override
  String get proDescription => '모든 프리미엄 기능을 잠금 해제하세요';

  @override
  String get proFeature1 => '무제한 AI 인사이트';

  @override
  String get proFeature2 => '고급 분석 및 리포트';

  @override
  String get proFeature3 => '데이터 내보내기';

  @override
  String get proFeature4 => '우선 지원';

  @override
  String get subscribeMonthly => '월간 구독';

  @override
  String get subscribeYearly => '연간 구독';

  @override
  String get monthlyPrice => '₩6,500/월';

  @override
  String get yearlyPrice => '₩54,000/년';

  @override
  String get restorePurchases => '구매 복원';

  @override
  String get currentPlan => '현재 플랜';

  @override
  String get freePlan => '무료';

  @override
  String get proPlan => 'Pro';

  @override
  String get youArePro => 'Pro 구독 중!';

  @override
  String get proThankYou => '글루 버틀러를 지원해 주셔서 감사합니다. 모든 프리미엄 기능을 즐기세요!';

  @override
  String get subscriptionStartDate => '구독 시작일';

  @override
  String get subscriptionPlan => '구독 플랜';

  @override
  String get yearlyPlan => '연간';

  @override
  String get monthlyPlan => '월간';

  @override
  String get manageSubscription => '구독 관리';

  @override
  String get disclaimer => '이 앱은 참고용이며, 의료적인 조언은 반드시 의사와 직접 상의하시기 바랍니다.';

  @override
  String get enterGlucose => '혈당 입력';

  @override
  String get enterMeal => '식사 추가';

  @override
  String get enterExercise => '운동 추가';

  @override
  String get takePhoto => '사진 촬영';

  @override
  String get chooseFromGallery => '갤러리에서 선택';

  @override
  String maxImagesReached(int count, int added) {
    return '최대 $count장까지만 첨부 가능합니다. $added장이 추가되었습니다.';
  }

  @override
  String get onlyImageFiles => '이미지 파일만 선택할 수 있습니다.';

  @override
  String get imageLoadFailed => '사진을 불러오는데 실패했습니다.';

  @override
  String get photoPermissionRequired => '사진 접근 권한 필요';

  @override
  String get photoPermissionMessage =>
      '사진을 첨부하려면 사진 라이브러리 접근 권한이 필요합니다.\n\n설정 > Glu Butler에서 사진 접근을 허용해주세요.';

  @override
  String get goToSettings => '설정으로 이동';

  @override
  String get noRecords => '기록이 없습니다';

  @override
  String get noReportYet => '리포트가 없습니다';

  @override
  String get startTracking => '건강 기록을 시작하세요!';

  @override
  String get feedEmptyHint => '건강 앱을 연동해 더 많은 정보를 확인하세요';

  @override
  String get goodMorning => '좋은 아침이에요!';

  @override
  String get goodAfternoon => '좋은 오후예요!';

  @override
  String get goodEvening => '좋은 저녁이에요!';

  @override
  String get butlerGreeting => '집사가 도와드릴 준비가 되었습니다.';

  @override
  String get home => '오늘';

  @override
  String get yourToday => '당신의 오늘';

  @override
  String get points => '점';

  @override
  String get todaysGlucose => '혈당추이';

  @override
  String get todaysStats => '오늘의 통계';

  @override
  String get average => '평균';

  @override
  String get lowest => '최저';

  @override
  String get highest => '최고';

  @override
  String get glucoseDistribution => '혈당 범위 분포';

  @override
  String get glucoseStatus => '혈당상태';

  @override
  String get scoreHint => '점수에 대해 알아보세요';

  @override
  String get scoreInfoTitle => '혈당 점수 안내';

  @override
  String get scoreInfoQuality => '혈당 관리 품질';

  @override
  String get scoreInfoQualityDesc => '측정한 혈당이 목표 범위에 가까울수록 점수가 높아집니다.';

  @override
  String get scoreInfoConsistency => '측정 일관성';

  @override
  String get scoreInfoConsistencyDesc => '하루 동안 규칙적으로 혈당을 측정할수록 점수가 높아집니다.';

  @override
  String get scoreInfoRecommendation => '권장 측정 횟수';

  @override
  String get scoreInfoMorning => '아침 (9시 전): 공복 1회';

  @override
  String get scoreInfoLunch => '점심 전 (2시 전): 총 3회';

  @override
  String get scoreInfoDinner => '저녁 전 (7시 전): 총 5회';

  @override
  String get scoreInfoBedtime => '자기 전 (10시 후): 총 6회';

  @override
  String get scoreInfoLifestyle => '생활습관 (건강 앱 연동시)';

  @override
  String get scoreInfoLifestyleDesc =>
      '수면시간, 운동기록 등의 건강앱 데이터를 함께 평가하여 점수를 계산합니다.';

  @override
  String get scoreInfoPrivacy => '*앱에 사용되는 모든 정보는 따로 저장되거나 외부로 공유되지 않습니다.';

  @override
  String get times => '회';

  @override
  String get viewReport => '리포트 보기';

  @override
  String get noData => '데이터가 없습니다';

  @override
  String get excellentScore => '훌륭해요! 오늘 혈당 관리를 잘 하고 계세요.';

  @override
  String get goodScore => '좋아요! 조금만 더 신경 쓰면 완벽해요.';

  @override
  String get needsAttention => '오늘은 혈당 변동이 컸어요. 식단을 확인해보세요.';

  @override
  String get noGlucoseToday => '오늘 기록된 혈당이 없습니다';

  @override
  String get addGlucose => '혈당 추가';

  @override
  String get addDiaryEntry => '일기 추가';

  @override
  String get diaryPlaceholder => '혈당 관리 일기를 작성해보세요';

  @override
  String get attachPhoto => '사진 첨부';

  @override
  String get discardDiaryTitle => '작성 취소';

  @override
  String get discardDiaryMessage => '작성중인 내용이 사라집니다.\n글쓰기를 취소하시겠습니까?';

  @override
  String get diarySaved => '일기가 저장되었습니다';

  @override
  String get diarySaveFailed => '일기 저장에 실패했습니다';

  @override
  String get yes => '예';

  @override
  String get no => '아니오';

  @override
  String get insulin => '인슐린';

  @override
  String get addInsulin => '인슐린 추가';

  @override
  String get insulinType => '인슐린 종류';

  @override
  String get rapidActing => '속효형';

  @override
  String get longActing => '지속형';

  @override
  String get insulinDose => '투여량';

  @override
  String get units => 'U';

  @override
  String get injectionSite => '주사 부위';

  @override
  String get abdomen => '복부';

  @override
  String get thigh => '허벅지';

  @override
  String get arm => '팔';

  @override
  String get buttock => '엉덩이';

  @override
  String get measurementTime => '측정 시간';

  @override
  String get injectionTime => '투여 시간';

  @override
  String get deliveryType => '인슐린 종류';

  @override
  String get bolus => '속효성';

  @override
  String get basal => '지속형';

  @override
  String get measurementTiming => '측정 시점';

  @override
  String get addRecord => '기록 추가';

  @override
  String get glucoseSaved => '혈당 기록이 저장되었습니다';

  @override
  String get insulinSaved => '인슐린 기록이 저장되었습니다';

  @override
  String get saveFailed => '저장에 실패했습니다';

  @override
  String get appleHealth => 'Apple 건강';

  @override
  String get appleHealthDescription =>
      '건강 앱과 연동하여 혈당 관리에 도움이 되는 운동, 수면, 체중 등 다양한 데이터를 함께 확인할 수 있습니다.';

  @override
  String get syncedData => '연동 데이터';

  @override
  String get connectAppleHealth => 'Apple 건강 연결';

  @override
  String get successfullyConnected => '연동 정보가 업데이트 되었습니다';

  @override
  String get failedToConnect => '연결에 실패했습니다. 애플 건강앱에서 권한을 확인해주세요.';

  @override
  String get privacyNote =>
      '건강 데이터는 사용자의 기기에만 저장되며, 그 어떤 데이터도 외부에 공유되지 않습니다. 건강 앱 > 공유 > 앱 > Glu Butler에서 권한을 관리할 수 있습니다.';

  @override
  String get readWrite => '읽기 및 쓰기';

  @override
  String get readOnly => '읽기 전용';

  @override
  String get workouts => '운동';

  @override
  String get running => '달리기';

  @override
  String get walking => '걷기';

  @override
  String get cycling => '자전거';

  @override
  String get swimming => '수영';

  @override
  String get yoga => '요가';

  @override
  String get strength => '근력 운동';

  @override
  String get hiit => '고강도 인터벌';

  @override
  String get stairs => '계단 오르기';

  @override
  String get dance => '댄스';

  @override
  String get functional => '기능성 운동';

  @override
  String get core => '코어 운동';

  @override
  String get flexibility => '유연성 운동';

  @override
  String get cardio => '유산소 운동';

  @override
  String get other => '기타 운동';

  @override
  String get sleep => '수면';

  @override
  String get weightBody => '체중 및 신체';

  @override
  String get waterIntake => '수분 섭취';

  @override
  String get menstrualCycle => '생리 주기';

  @override
  String get steps => '걸음 수';

  @override
  String get mindfulness => '마음 챙김';

  @override
  String get openHealthApp => '건강 앱 > 공유 > 앱에서 권한을 관리하세요';

  @override
  String get syncPeriod => '연동 기간';

  @override
  String get syncPeriod1Week => '1주';

  @override
  String get syncPeriod2Weeks => '2주';

  @override
  String get syncPeriod1Month => '1개월';

  @override
  String get syncPeriod3Months => '3개월';

  @override
  String get disconnected => 'Apple 건강 연동이 해제되었습니다';

  @override
  String get cgmBaseline => '표준';

  @override
  String get cgmFluctuation => '변동';

  @override
  String get targetGlucoseRange => '목표 혈당 범위';

  @override
  String get targetGlucoseRangeDescription =>
      '설정된 목표수치를 바탕으로 피드에서 보이는 혈당 정보를 더 정확하게 분석할 수 있습니다.';

  @override
  String get veryHigh => '매우 높음';

  @override
  String get warning => '주의';

  @override
  String get target => '목표';

  @override
  String get veryLow => '매우 낮음';

  @override
  String get appSlogan => '당신의 건강 파트너';

  @override
  String get initLoadingSettings => '설정 불러오는 중...';

  @override
  String get initCheckingHealth => '건강 데이터 동기화 확인 중...';

  @override
  String get initCheckingiCloud => 'iCloud 동기화 확인 중...';

  @override
  String get initLocalDatabase => '로컬 데이터베이스 초기화 중...';

  @override
  String get initDone => '완료';

  @override
  String syncCompleteMessage(int count) {
    return '$count개 기록이 Apple 건강에 동기화되었습니다';
  }

  @override
  String syncPartialMessage(int success, int total) {
    return '$total개 중 $success개 동기화 완료. 나머지는 다음에 재시도합니다.';
  }

  @override
  String get syncFailedMessage => '동기화에 실패했습니다. 다음 실행시 재시도합니다.';

  @override
  String get deleteGlucoseConfirmation => '정말 삭제하시겠습니까?\n삭제하면 되돌릴 수 없습니다.';

  @override
  String get glucoseDeleted => '혈당 기록이 삭제되었습니다';

  @override
  String get insulinDeleted => '인슐린 기록이 삭제되었습니다';

  @override
  String get deleteFailed => '삭제에 실패했습니다';

  @override
  String get deleteDiary => '일기 삭제';

  @override
  String get deleteDiaryConfirmation => '삭제하시겠습니까?\n되돌릴 수 없습니다.';

  @override
  String get diaryDeleted => '삭제되었습니다';

  @override
  String get diaryDeleteFailed => '삭제에 실패했습니다';

  @override
  String get diaryUpdated => '일기가 수정되었습니다';

  @override
  String get editDiary => '일기 수정';

  @override
  String get showMore => '더보기';

  @override
  String get showLess => '줄이기';

  @override
  String get diaryContentRequired => '내용을 입력하거나 사진을 첨부해주세요.';

  @override
  String get error => '오류';

  @override
  String get confirm => '확인';

  @override
  String dataSyncPeriodInfo(String period) {
    return '최근 $period 데이터가 표시됩니다. 애플 건강앱 설정에서 기간변경이 가능합니다';
  }

  @override
  String get generateReport => '레포트 생성하기';

  @override
  String get reportGuideTitle => '레포트 안내';

  @override
  String get reportGuideMessage =>
      '• 레포트는 혈당 데이터를 분석하여 AI가 생성합니다.\n\n• 지금 생성해도 되지만, 최소 하루 이상의 혈당 데이터가 쌓여있을 때 더 정확한 분석 결과를 받을 수 있습니다.\n\n• 최초 리포트 생성 이후, 다음 리포트는 일주일 간격으로 생성할 수 있습니다.\n\n• 건강 앱에 연동된 수면, 운동 등의 정보를 바탕으로 더 상세한 분석을 제공합니다.\n\n• 매일 혈당 일기를 작성하면 하루 패턴을 파악하는데 도움이 됩니다.\n\n• 리포트에서 제안하는 생활습관 개선을 실천하고, 특이사항은 일기에 기록해보세요.';

  @override
  String get doNotShowAgain => '다시 보지 않기';

  @override
  String get viewPastReports => '지난 리포트 보기';

  @override
  String get reportPeriod => '리포트 기간';
}
