// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appName => 'グル バトラー';

  @override
  String get feed => 'フィード';

  @override
  String get diary => '日記';

  @override
  String get report => 'レポート';

  @override
  String get settings => '設定';

  @override
  String get add => '追加';

  @override
  String get cancel => 'キャンセル';

  @override
  String get close => '閉じる';

  @override
  String get save => '保存';

  @override
  String get done => '完了';

  @override
  String get delete => '削除';

  @override
  String get edit => '編集';

  @override
  String get selectDate => '日付を選択';

  @override
  String get today => '今日';

  @override
  String get yesterday => '昨日';

  @override
  String get thisWeek => '今週';

  @override
  String get thisMonth => '今月';

  @override
  String get bloodGlucose => '血糖値';

  @override
  String get meal => '食事';

  @override
  String get exercise => '運動';

  @override
  String get glucoseUnit => '単位';

  @override
  String get glucoseUnitDescription =>
      'Select the unit for glucose measurement.';

  @override
  String get mgdl => 'mg/dL';

  @override
  String get mmoll => 'mmol/L';

  @override
  String get low => '低血糖';

  @override
  String get normal => '正常';

  @override
  String get high => '高い';

  @override
  String get breakfast => '朝食';

  @override
  String get lunch => '昼食';

  @override
  String get dinner => '夕食';

  @override
  String get snack => 'おやつ';

  @override
  String get fasting => '空腹';

  @override
  String get beforeMeal => '食前';

  @override
  String get afterMeal => '食後';

  @override
  String get unspecified => '未指定';

  @override
  String get dailyReport => '日次レポート';

  @override
  String get weeklyReport => '週次レポート';

  @override
  String get aiInsight => 'AIインサイト';

  @override
  String get glucoseScore => '血糖スコア';

  @override
  String get profile => 'プロフィール';

  @override
  String get name => '名前';

  @override
  String get gender => '性別';

  @override
  String get male => '男性';

  @override
  String get female => '女性';

  @override
  String get birthday => '生年月日';

  @override
  String get diabetesType => '糖尿病タイプ';

  @override
  String get type1 => '1型';

  @override
  String get type2 => '2型';

  @override
  String get none => 'なし';

  @override
  String get language => '言語';

  @override
  String get changeInSettings => '設定アプリで変更';

  @override
  String get darkMode => 'ダークモード';

  @override
  String get displaySettings => '表示';

  @override
  String get systemDefault => 'システム設定';

  @override
  String get systemDefaultDescription => 'システムテーマに従う';

  @override
  String get lightMode => 'ライト';

  @override
  String get darkModeOption => 'ダーク';

  @override
  String get notifications => '通知';

  @override
  String get notificationTime => '通知時間';

  @override
  String get sync => '連携';

  @override
  String get healthConnect => 'ヘルスケア連携';

  @override
  String get iCloudSync => 'iCloud同期';

  @override
  String get iCloudSyncDescription => '複数のデバイスでデータを同期';

  @override
  String get connected => '接続済み';

  @override
  String get notConnected => '未接続';

  @override
  String get connect => '接続する';

  @override
  String get disconnect => '接続解除';

  @override
  String get subscription => 'サブスクリプション';

  @override
  String get gluButlerPro => 'グル バトラー Pro';

  @override
  String get upgradeToPro => 'Proにアップグレード';

  @override
  String get proDescription => 'すべてのプレミアム機能をアンロック';

  @override
  String get proFeature1 => '無制限のAIインサイト';

  @override
  String get proFeature2 => '高度な分析とレポート';

  @override
  String get proFeature3 => 'データエクスポート';

  @override
  String get proFeature4 => '優先サポート';

  @override
  String get subscribeMonthly => '月額プラン';

  @override
  String get subscribeYearly => '年額プラン';

  @override
  String get monthlyPrice => '¥700/月';

  @override
  String get yearlyPrice => '¥5,800/年';

  @override
  String get restorePurchases => '購入を復元';

  @override
  String get currentPlan => '現在のプラン';

  @override
  String get freePlan => '無料';

  @override
  String get proPlan => 'Pro';

  @override
  String get youArePro => 'You\'re Pro!';

  @override
  String get proThankYou =>
      'Thank you for supporting Glu Butler. Enjoy all premium features!';

  @override
  String get subscriptionStartDate => 'Started';

  @override
  String get subscriptionPlan => 'Plan';

  @override
  String get yearlyPlan => 'Yearly';

  @override
  String get monthlyPlan => 'Monthly';

  @override
  String get manageSubscription => 'Manage Subscription';

  @override
  String get disclaimer => 'このアプリは参考用です。医療アドバイスについては必ず医師に直接ご相談ください。';

  @override
  String get enterGlucose => '血糖値を入力';

  @override
  String get enterMeal => '食事を追加';

  @override
  String get enterExercise => '運動を追加';

  @override
  String get takePhoto => '写真を撮る';

  @override
  String get chooseFromGallery => 'ギャラリーから選択';

  @override
  String maxImagesReached(int count, int added) {
    return '最大$count枚まで添付できます。$added枚が追加されました。';
  }

  @override
  String get onlyImageFiles => '画像ファイルのみ選択できます。';

  @override
  String get imageLoadFailed => '写真の読み込みに失敗しました。';

  @override
  String get photoPermissionRequired => '写真アクセス権限が必要です';

  @override
  String get photoPermissionMessage =>
      '写真を添付するには、フォトライブラリへのアクセス権限が必要です。\n\n設定 > Glu Butlerで写真アクセスを許可してください。';

  @override
  String get goToSettings => '設定へ移動';

  @override
  String get noRecords => '記録がありません';

  @override
  String get noReportYet => 'レポートがありません';

  @override
  String get startTracking => '健康記録を始めましょう！';

  @override
  String get feedEmptyHint => 'ヘルスケアアプリと連携してより多くの情報を確認できます';

  @override
  String get goodMorning => 'おはようございます！';

  @override
  String get goodAfternoon => 'こんにちは！';

  @override
  String get goodEvening => 'こんばんは！';

  @override
  String get butlerGreeting => '執事がお手伝いいたします。';

  @override
  String get home => '今日';

  @override
  String get yourToday => '今日のあなた';

  @override
  String get points => '点';

  @override
  String get todaysGlucose => '血糖トレンド';

  @override
  String get todaysStats => '今日の統計';

  @override
  String get average => '平均';

  @override
  String get lowest => '最低';

  @override
  String get highest => '最高';

  @override
  String get glucoseDistribution => '血糖分布';

  @override
  String get glucoseStatus => '血糖状態';

  @override
  String get scoreHint => 'スコアについて詳しく';

  @override
  String get scoreInfoTitle => '血糖スコアガイド';

  @override
  String get scoreInfoQuality => '血糖管理の質';

  @override
  String get scoreInfoQualityDesc => '測定した血糖値が目標範囲に近いほど、スコアが高くなります。';

  @override
  String get scoreInfoConsistency => '測定の一貫性';

  @override
  String get scoreInfoConsistencyDesc => '1日を通して定期的に血糖値を測定するほど、スコアが高くなります。';

  @override
  String get scoreInfoRecommendation => '推奨測定回数';

  @override
  String get scoreInfoMorning => '朝（9時前）：空腹時1回';

  @override
  String get scoreInfoLunch => '昼食前（14時前）：合計3回';

  @override
  String get scoreInfoDinner => '夕食前（19時前）：合計5回';

  @override
  String get scoreInfoBedtime => '就寝前（22時以降）：合計6回';

  @override
  String get scoreInfoLifestyle => '生活習慣（ヘルスケア連携時）';

  @override
  String get scoreInfoLifestyleDesc => '睡眠時間、運動記録などのヘルスケアデータを一緒に評価してスコアを計算します。';

  @override
  String get scoreInfoPrivacy => '*アプリで使用されるすべての情報は、別途保存されたり外部に共有されることはありません。';

  @override
  String get times => '回';

  @override
  String get viewReport => 'レポートを見る';

  @override
  String get noData => 'データがありません';

  @override
  String get excellentScore => '素晴らしい！今日の血糖管理は順調です。';

  @override
  String get goodScore => '良いですね！もう少し気をつければ完璧です。';

  @override
  String get needsAttention => '今日は血糖の変動が大きかったです。食事を確認してください。';

  @override
  String get noGlucoseToday => '今日の血糖記録がありません';

  @override
  String get addGlucose => '血糖を追加';

  @override
  String get addDiaryEntry => '日記を追加';

  @override
  String get diaryPlaceholder => '血糖管理日記を書いてみてください';

  @override
  String get attachPhoto => '写真を添付';

  @override
  String get discardDiaryTitle => '作成キャンセル';

  @override
  String get discardDiaryMessage => '作成中の内容が消えます。\n書き込みをキャンセルしますか？';

  @override
  String get diarySaved => '日記が保存されました';

  @override
  String get diarySaveFailed => '日記の保存に失敗しました';

  @override
  String get yes => 'はい';

  @override
  String get no => 'いいえ';

  @override
  String get insulin => 'インスリン';

  @override
  String get addInsulin => 'インスリンを追加';

  @override
  String get insulinType => 'インスリンの種類';

  @override
  String get rapidActing => '超速効型';

  @override
  String get longActing => '持効型';

  @override
  String get insulinDose => '投与量';

  @override
  String get units => '単位';

  @override
  String get injectionSite => '注射部位';

  @override
  String get abdomen => '腹部';

  @override
  String get thigh => '太もも';

  @override
  String get arm => '腕';

  @override
  String get buttock => '臀部';

  @override
  String get measurementTime => '時間';

  @override
  String get injectionTime => '投与時間';

  @override
  String get deliveryType => 'インスリンの種類';

  @override
  String get bolus => '超速効型';

  @override
  String get basal => '持効型';

  @override
  String get measurementTiming => '測定タイミング';

  @override
  String get addRecord => '記録を追加';

  @override
  String get glucoseSaved => '血糖値を保存しました';

  @override
  String get insulinSaved => 'インスリン投与量を保存しました';

  @override
  String get saveFailed => '保存に失敗しました';

  @override
  String get appleHealth => 'Apple ヘルスケア';

  @override
  String get appleHealthDescription => 'ヘルスケアアプリと連携して、血糖管理に役立つ様々なデータを確認できます。';

  @override
  String get syncedData => '連携データ';

  @override
  String get connectAppleHealth => 'Apple ヘルスケアに接続';

  @override
  String get successfullyConnected => '連携情報が更新されました';

  @override
  String get failedToConnect => '接続に失敗しました。Apple ヘルスケアアプリで権限を確認してください。';

  @override
  String get privacyNote =>
      '健康データはお使いのデバイスにのみ保存され、外部に共有されることは一切ありません。ヘルスケアアプリ > 共有 > App > Glu Butlerで権限を管理できます。';

  @override
  String get readWrite => '読み取り/書き込み';

  @override
  String get readOnly => '読み取りのみ';

  @override
  String get workouts => 'ワークアウト';

  @override
  String get running => 'ランニング';

  @override
  String get walking => 'ウォーキング';

  @override
  String get cycling => 'サイクリング';

  @override
  String get swimming => '水泳';

  @override
  String get yoga => 'ヨガ';

  @override
  String get strength => '筋力トレーニング';

  @override
  String get hiit => 'HIIT';

  @override
  String get stairs => '階段';

  @override
  String get dance => 'ダンス';

  @override
  String get functional => 'ファンクショナルトレーニング';

  @override
  String get core => '体幹トレーニング';

  @override
  String get flexibility => '柔軟性トレーニング';

  @override
  String get cardio => '有酸素運動';

  @override
  String get other => 'ワークアウト';

  @override
  String get sleep => '睡眠';

  @override
  String get weightBody => '体重・体組成';

  @override
  String get waterIntake => '水分摂取';

  @override
  String get menstrualCycle => '月経周期';

  @override
  String get steps => '歩数';

  @override
  String get mindfulness => 'マインドフルネス';

  @override
  String get openHealthApp => 'ヘルスケアアプリ > 共有 > Appで権限を管理してください';

  @override
  String get syncPeriod => '連携期間';

  @override
  String get syncPeriod1Week => '1週間';

  @override
  String get syncPeriod2Weeks => '2週間';

  @override
  String get syncPeriod1Month => '1ヶ月';

  @override
  String get syncPeriod3Months => '3ヶ月';

  @override
  String get disconnected => 'Apple ヘルスケアとの連携が解除されました';

  @override
  String get cgmBaseline => '安定';

  @override
  String get cgmFluctuation => '変動';

  @override
  String get targetGlucoseRange => '目標血糖値範囲';

  @override
  String get targetGlucoseRangeDescription =>
      'Your target values are used to analyze glucose data more accurately in the feed.';

  @override
  String get veryHigh => '非常に高い';

  @override
  String get warning => '注意';

  @override
  String get target => '目標';

  @override
  String get veryLow => '非常に低い';

  @override
  String get appSlogan => 'あなたの健康パートナー';

  @override
  String get initLoadingSettings => '設定を読み込み中...';

  @override
  String get initCheckingHealth => 'ヘルスデータ同期を確認中...';

  @override
  String get initCheckingiCloud => 'iCloud同期を確認中...';

  @override
  String get initLocalDatabase => 'ローカルデータベースを初期化中...';

  @override
  String get initDone => '完了';

  @override
  String syncCompleteMessage(int count) {
    return '$count records synced to Apple Health';
  }

  @override
  String syncPartialMessage(int success, int total) {
    return '$success of $total records synced. Rest will retry later.';
  }

  @override
  String get syncFailedMessage => 'Sync failed. Will retry on next app launch.';

  @override
  String get deleteGlucoseConfirmation => '本当に削除しますか？\nこの操作は元に戻せません。';

  @override
  String get glucoseDeleted => '血糖値を削除しました';

  @override
  String get insulinDeleted => 'インスリンを削除しました';

  @override
  String get deleteFailed => '削除に失敗しました';

  @override
  String get deleteDiary => '日記を削除';

  @override
  String get deleteDiaryConfirmation => '削除しますか？\n元に戻すことはできません。';

  @override
  String get diaryDeleted => '削除されました';

  @override
  String get diaryDeleteFailed => '削除に失敗しました';

  @override
  String get diaryUpdated => '日記が更新されました';

  @override
  String get editDiary => '日記を編集';

  @override
  String get showMore => 'もっと見る';

  @override
  String get showLess => '閉じる';

  @override
  String get diaryContentRequired => '内容を入力するか、写真を添付してください。';

  @override
  String get error => 'エラー';

  @override
  String get confirm => '確認';

  @override
  String dataSyncPeriodInfo(String period) {
    return '最近$periodのデータが表示されます。Apple Healthの設定で期間変更が可能です';
  }

  @override
  String get generateReport => 'レポート生成';

  @override
  String get reportGuideTitle => 'レポートについて';

  @override
  String get reportGuideMessage =>
      '• レポートはAIが血糖データを分析して生成します。\n\n• 今すぐ生成できますが、最低1日分の血糖データがあるとより正確な分析結果が得られます。\n\n• 初回レポート生成後、次のレポートは1週間間隔で生成できます。\n\n• Health appに連携された睡眠、運動などの情報に基づいて詳細な分析を提供します。\n\n• 毎日血糖日記を書くと、日々のパターンを把握するのに役立ちます。\n\n• レポートで提案される生活習慣の改善を実践し、特記事項は日記に記録してください。';

  @override
  String get doNotShowAgain => '今後表示しない';

  @override
  String get viewPastReports => '過去のレポート';

  @override
  String get reportPeriod => 'レポート期間';

  @override
  String get selectDateRange => '日付範囲を選択';

  @override
  String get selectStartAndEndDate => '開始日と終了日を選択してください';

  @override
  String get month => '月';

  @override
  String get day => '日';

  @override
  String get newReport => '新しいレポートを作成';
}
