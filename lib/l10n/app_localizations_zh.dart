// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appName => '血糖管家';

  @override
  String get feed => '动态';

  @override
  String get diary => '日记';

  @override
  String get report => '报告';

  @override
  String get settings => '设置';

  @override
  String get add => '添加';

  @override
  String get cancel => '取消';

  @override
  String get close => '关闭';

  @override
  String get save => '保存';

  @override
  String get done => '完成';

  @override
  String get delete => '删除';

  @override
  String get edit => '编辑';

  @override
  String get selectDate => '选择日期';

  @override
  String get today => '今天';

  @override
  String get yesterday => '昨天';

  @override
  String get thisWeek => '本周';

  @override
  String get thisMonth => '本月';

  @override
  String get bloodGlucose => '血糖';

  @override
  String get meal => '餐食';

  @override
  String get exercise => '运动';

  @override
  String get glucoseUnit => '单位';

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
  String get high => '高';

  @override
  String get breakfast => '早餐';

  @override
  String get lunch => '午餐';

  @override
  String get dinner => '晚餐';

  @override
  String get snack => '零食';

  @override
  String get fasting => '空腹';

  @override
  String get beforeMeal => '餐前';

  @override
  String get afterMeal => '餐后';

  @override
  String get unspecified => '未指定';

  @override
  String get dailyReport => '每日报告';

  @override
  String get weeklyReport => '每周报告';

  @override
  String get aiInsight => 'AI洞察';

  @override
  String get glucoseScore => '血糖评分';

  @override
  String get profile => '个人资料';

  @override
  String get name => '姓名';

  @override
  String get gender => '性别';

  @override
  String get male => '男';

  @override
  String get female => '女';

  @override
  String get birthday => '生日';

  @override
  String get diabetesType => '糖尿病类型';

  @override
  String get type1 => '1型';

  @override
  String get type2 => '2型';

  @override
  String get none => '无';

  @override
  String get language => '语言';

  @override
  String get changeInSettings => '在设置中更改';

  @override
  String get darkMode => '深色模式';

  @override
  String get displaySettings => '显示';

  @override
  String get systemDefault => '跟随系统';

  @override
  String get systemDefaultDescription => '跟随系统主题';

  @override
  String get lightMode => '浅色';

  @override
  String get darkModeOption => '深色';

  @override
  String get notifications => '通知';

  @override
  String get notificationTime => '通知时间';

  @override
  String get sync => '同步';

  @override
  String get healthConnect => '健康连接';

  @override
  String get iCloudSync => 'iCloud同步';

  @override
  String get iCloudSyncDescription => '跨设备同步数据';

  @override
  String get connected => '已连接';

  @override
  String get notConnected => '未连接';

  @override
  String get connect => '连接';

  @override
  String get disconnect => '断开连接';

  @override
  String get subscription => '订阅';

  @override
  String get gluButlerPro => '血糖管家 Pro';

  @override
  String get upgradeToPro => '升级到 Pro';

  @override
  String get proDescription => '解锁所有高级功能';

  @override
  String get proFeature1 => '无限 AI 洞察';

  @override
  String get proFeature2 => '高级分析和报告';

  @override
  String get proFeature3 => '数据导出';

  @override
  String get proFeature4 => '优先支持';

  @override
  String get subscribeMonthly => '月度订阅';

  @override
  String get subscribeYearly => '年度订阅';

  @override
  String get monthlyPrice => '¥35/月';

  @override
  String get yearlyPrice => '¥298/年';

  @override
  String get restorePurchases => '恢复购买';

  @override
  String get currentPlan => '当前方案';

  @override
  String get freePlan => '免费版';

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
  String get disclaimer => '本应用仅供参考，医疗建议请务必直接咨询医生。';

  @override
  String get enterGlucose => '输入血糖';

  @override
  String get enterMeal => '添加餐食';

  @override
  String get enterExercise => '添加运动';

  @override
  String get takePhoto => '拍照';

  @override
  String get chooseFromGallery => '从相册选择';

  @override
  String maxImagesReached(int count, int added) {
    return '最多只能附加$count张。已添加$added张。';
  }

  @override
  String get onlyImageFiles => '只能选择图片文件。';

  @override
  String get imageLoadFailed => '加载照片失败。';

  @override
  String get photoPermissionRequired => '需要照片访问权限';

  @override
  String get photoPermissionMessage =>
      '要附加照片，需要允许访问照片库。\n\n请在设置 > Glu Butler中启用照片访问。';

  @override
  String get goToSettings => '前往设置';

  @override
  String get noRecords => '暂无记录';

  @override
  String get noReportYet => '暂无报告';

  @override
  String get startTracking => '开始记录您的健康！';

  @override
  String get feedEmptyHint => '连接健康 App 查看更多信息';

  @override
  String get goodMorning => '早上好！';

  @override
  String get goodAfternoon => '下午好！';

  @override
  String get goodEvening => '晚上好！';

  @override
  String get butlerGreeting => '您的管家随时准备为您服务。';

  @override
  String get home => '今天';

  @override
  String get yourToday => '你的今天';

  @override
  String get points => '分';

  @override
  String get todaysGlucose => '血糖趋势';

  @override
  String get todaysStats => '今日统计';

  @override
  String get average => '平均';

  @override
  String get lowest => '最低';

  @override
  String get highest => '最高';

  @override
  String get glucoseDistribution => '血糖分布';

  @override
  String get glucoseStatus => '血糖状态';

  @override
  String get scoreHint => '了解评分';

  @override
  String get scoreInfoTitle => '血糖评分指南';

  @override
  String get scoreInfoQuality => '血糖管理质量';

  @override
  String get scoreInfoQualityDesc => '血糖测量值越接近目标范围，评分越高。';

  @override
  String get scoreInfoConsistency => '测量一致性';

  @override
  String get scoreInfoConsistencyDesc => '全天定期测量血糖，评分越高。';

  @override
  String get scoreInfoRecommendation => '建议测量次数';

  @override
  String get scoreInfoMorning => '早上（9点前）：空腹1次';

  @override
  String get scoreInfoLunch => '午餐前（14点前）：共3次';

  @override
  String get scoreInfoDinner => '晚餐前（19点前）：共5次';

  @override
  String get scoreInfoBedtime => '睡前（22点后）：共6次';

  @override
  String get scoreInfoLifestyle => '生活习惯（连接健康App时）';

  @override
  String get scoreInfoLifestyleDesc => '结合睡眠时间、运动记录等健康App数据计算评分。';

  @override
  String get scoreInfoPrivacy => '*应用中使用的所有信息不会单独存储或分享到外部。';

  @override
  String get times => '次';

  @override
  String get viewReport => '查看报告';

  @override
  String get noData => '暂无数据';

  @override
  String get excellentScore => '太棒了！今天的血糖管理很好。';

  @override
  String get goodScore => '不错！再注意一点就完美了。';

  @override
  String get needsAttention => '今天血糖波动较大，请检查饮食。';

  @override
  String get noGlucoseToday => '今天没有血糖记录';

  @override
  String get addGlucose => '添加血糖';

  @override
  String get addDiaryEntry => '添加日记';

  @override
  String get diaryPlaceholder => '写下您的血糖管理日记';

  @override
  String get attachPhoto => '附加照片';

  @override
  String get discardDiaryTitle => '取消编写';

  @override
  String get discardDiaryMessage => '正在编写的内容将消失。\n要取消写作吗？';

  @override
  String get diarySaved => '日记已保存';

  @override
  String get diarySaveFailed => '保存日记失败';

  @override
  String get yes => '是';

  @override
  String get no => '否';

  @override
  String get insulin => '胰岛素';

  @override
  String get addInsulin => '添加胰岛素';

  @override
  String get insulinType => '胰岛素类型';

  @override
  String get rapidActing => '速效型';

  @override
  String get longActing => '长效型';

  @override
  String get insulinDose => '剂量';

  @override
  String get units => '单位';

  @override
  String get injectionSite => '注射部位';

  @override
  String get abdomen => '腹部';

  @override
  String get thigh => '大腿';

  @override
  String get arm => '手臂';

  @override
  String get buttock => '臀部';

  @override
  String get measurementTime => '时间';

  @override
  String get injectionTime => '注射时间';

  @override
  String get deliveryType => '胰岛素类型';

  @override
  String get bolus => '速效型';

  @override
  String get basal => '长效型';

  @override
  String get measurementTiming => '测量时机';

  @override
  String get addRecord => '添加记录';

  @override
  String get glucoseSaved => '血糖记录已保存';

  @override
  String get insulinSaved => '胰岛素剂量已保存';

  @override
  String get saveFailed => '保存失败';

  @override
  String get appleHealth => 'Apple 健康';

  @override
  String get appleHealthDescription => '连接健康 App，查看有助于血糖管理的各种数据。';

  @override
  String get syncedData => '同步数据';

  @override
  String get connectAppleHealth => '连接 Apple 健康';

  @override
  String get successfullyConnected => '同步信息已更新';

  @override
  String get failedToConnect => '连接失败，请在 Apple 健康 App 中检查权限设置。';

  @override
  String get privacyNote =>
      '您的健康数据仅保存在您的设备上，不会向外部共享任何数据。您可以在健康 App > 共享 > App > Glu Butler 中管理权限。';

  @override
  String get readWrite => '读写';

  @override
  String get readOnly => '只读';

  @override
  String get workouts => '体能训练';

  @override
  String get running => 'Running';

  @override
  String get walking => 'Walking';

  @override
  String get cycling => 'Cycling';

  @override
  String get swimming => 'Swimming';

  @override
  String get yoga => 'Yoga';

  @override
  String get strength => 'Strength Training';

  @override
  String get hiit => 'HIIT';

  @override
  String get stairs => 'Stairs';

  @override
  String get dance => 'Dance';

  @override
  String get functional => 'Functional Training';

  @override
  String get core => 'Core Training';

  @override
  String get flexibility => 'Flexibility';

  @override
  String get cardio => 'Cardio';

  @override
  String get other => 'Workout';

  @override
  String get sleep => '睡眠';

  @override
  String get weightBody => '体重与身体数据';

  @override
  String get waterIntake => '饮水量';

  @override
  String get menstrualCycle => '月经周期';

  @override
  String get steps => '步数';

  @override
  String get mindfulness => '正念';

  @override
  String get openHealthApp => '在健康 App > 共享 > App 中管理权限';

  @override
  String get syncPeriod => '同步周期';

  @override
  String get syncPeriod1Week => '1周';

  @override
  String get syncPeriod2Weeks => '2周';

  @override
  String get syncPeriod1Month => '1个月';

  @override
  String get syncPeriod3Months => '3个月';

  @override
  String get disconnected => '已断开与 Apple 健康的连接';

  @override
  String get cgmBaseline => '稳定';

  @override
  String get cgmFluctuation => '波动';

  @override
  String get targetGlucoseRange => '目标血糖范围';

  @override
  String get targetGlucoseRangeDescription =>
      'Your target values are used to analyze glucose data more accurately in the feed.';

  @override
  String get veryHigh => '非常高';

  @override
  String get warning => '注意';

  @override
  String get target => '目标';

  @override
  String get veryLow => '非常低';

  @override
  String get appSlogan => '您的健康伙伴';

  @override
  String get initLoadingSettings => '正在加载设置...';

  @override
  String get initCheckingHealth => '正在检查健康数据同步...';

  @override
  String get initCheckingiCloud => '正在检查 iCloud 同步...';

  @override
  String get initLocalDatabase => '正在初始化本地数据库...';

  @override
  String get initDone => '完成';

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
  String get deleteGlucoseConfirmation => '确定要删除吗？\n此操作无法撤销。';

  @override
  String get glucoseDeleted => '血糖记录已删除';

  @override
  String get insulinDeleted => '胰岛素记录已删除';

  @override
  String get deleteFailed => '删除失败';

  @override
  String get deleteDiary => '删除日记';

  @override
  String get deleteDiaryConfirmation => '确定要删除吗？\n此操作无法撤销。';

  @override
  String get diaryDeleted => '已删除';

  @override
  String get diaryDeleteFailed => '删除失败';

  @override
  String get diaryUpdated => '日记已更新';

  @override
  String get editDiary => '编辑日记';

  @override
  String get showMore => '展开';

  @override
  String get showLess => '收起';

  @override
  String get diaryContentRequired => '请输入内容或附加照片。';

  @override
  String get error => '错误';

  @override
  String get confirm => '确定';

  @override
  String dataSyncPeriodInfo(String period) {
    return '显示最近$period的数据。可在Apple Health设置中更改期间';
  }

  @override
  String get generateReport => '生成报告';

  @override
  String get reportGuideTitle => '关于报告';

  @override
  String get reportGuideMessage =>
      '• 报告由AI分析您的血糖数据生成。\n\n• 虽然现在可以生成，但至少有一天的血糖数据时分析结果会更准确。\n\n• 首次报告生成后，可以每周生成新报告。\n\n• 报告基于健康应用中的睡眠、运动等信息提供详细分析。\n\n• 每天写血糖日记有助于识别日常模式。\n\n• 尝试实施报告中建议的生活方式改善，并在日记中记录任何异常观察。';

  @override
  String get doNotShowAgain => '不再显示';

  @override
  String get viewPastReports => '查看过去的报告';

  @override
  String get reportPeriod => '报告期间';
}
