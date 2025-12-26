import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_it.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('it'),
    Locale('ja'),
    Locale('ko'),
    Locale('zh'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Glu Butler'**
  String get appName;

  /// No description provided for @feed.
  ///
  /// In en, this message translates to:
  /// **'Feed'**
  String get feed;

  /// No description provided for @diary.
  ///
  /// In en, this message translates to:
  /// **'Diary'**
  String get diary;

  /// No description provided for @report.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get report;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select Date'**
  String get selectDate;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @thisWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get thisWeek;

  /// No description provided for @thisMonth.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get thisMonth;

  /// No description provided for @bloodGlucose.
  ///
  /// In en, this message translates to:
  /// **'Blood Glucose'**
  String get bloodGlucose;

  /// No description provided for @meal.
  ///
  /// In en, this message translates to:
  /// **'Meal'**
  String get meal;

  /// No description provided for @exercise.
  ///
  /// In en, this message translates to:
  /// **'Exercise'**
  String get exercise;

  /// No description provided for @glucoseUnit.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get glucoseUnit;

  /// No description provided for @mgdl.
  ///
  /// In en, this message translates to:
  /// **'mg/dL'**
  String get mgdl;

  /// No description provided for @mmoll.
  ///
  /// In en, this message translates to:
  /// **'mmol/L'**
  String get mmoll;

  /// No description provided for @low.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get low;

  /// No description provided for @normal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get normal;

  /// No description provided for @high.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get high;

  /// No description provided for @breakfast.
  ///
  /// In en, this message translates to:
  /// **'Breakfast'**
  String get breakfast;

  /// No description provided for @lunch.
  ///
  /// In en, this message translates to:
  /// **'Lunch'**
  String get lunch;

  /// No description provided for @dinner.
  ///
  /// In en, this message translates to:
  /// **'Dinner'**
  String get dinner;

  /// No description provided for @snack.
  ///
  /// In en, this message translates to:
  /// **'Snack'**
  String get snack;

  /// No description provided for @fasting.
  ///
  /// In en, this message translates to:
  /// **'Fasting'**
  String get fasting;

  /// No description provided for @beforeMeal.
  ///
  /// In en, this message translates to:
  /// **'Before Meal'**
  String get beforeMeal;

  /// No description provided for @afterMeal.
  ///
  /// In en, this message translates to:
  /// **'After Meal'**
  String get afterMeal;

  /// No description provided for @unspecified.
  ///
  /// In en, this message translates to:
  /// **'Unspecified'**
  String get unspecified;

  /// No description provided for @dailyReport.
  ///
  /// In en, this message translates to:
  /// **'Daily Report'**
  String get dailyReport;

  /// No description provided for @weeklyReport.
  ///
  /// In en, this message translates to:
  /// **'Weekly Report'**
  String get weeklyReport;

  /// No description provided for @aiInsight.
  ///
  /// In en, this message translates to:
  /// **'AI Insight'**
  String get aiInsight;

  /// No description provided for @glucoseScore.
  ///
  /// In en, this message translates to:
  /// **'Glucose Score'**
  String get glucoseScore;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @gender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get gender;

  /// No description provided for @male.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get male;

  /// No description provided for @female.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get female;

  /// No description provided for @birthday.
  ///
  /// In en, this message translates to:
  /// **'Birthday'**
  String get birthday;

  /// No description provided for @diabetesType.
  ///
  /// In en, this message translates to:
  /// **'Diabetes Type'**
  String get diabetesType;

  /// No description provided for @type1.
  ///
  /// In en, this message translates to:
  /// **'Type 1'**
  String get type1;

  /// No description provided for @type2.
  ///
  /// In en, this message translates to:
  /// **'Type 2'**
  String get type2;

  /// No description provided for @none.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get none;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @changeInSettings.
  ///
  /// In en, this message translates to:
  /// **'Change in Settings app'**
  String get changeInSettings;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @displaySettings.
  ///
  /// In en, this message translates to:
  /// **'Display'**
  String get displaySettings;

  /// No description provided for @systemDefault.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get systemDefault;

  /// No description provided for @systemDefaultDescription.
  ///
  /// In en, this message translates to:
  /// **'Follow system theme'**
  String get systemDefaultDescription;

  /// No description provided for @lightMode.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get lightMode;

  /// No description provided for @darkModeOption.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get darkModeOption;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @notificationTime.
  ///
  /// In en, this message translates to:
  /// **'Notification Time'**
  String get notificationTime;

  /// No description provided for @sync.
  ///
  /// In en, this message translates to:
  /// **'Sync'**
  String get sync;

  /// No description provided for @healthConnect.
  ///
  /// In en, this message translates to:
  /// **'Health Connect'**
  String get healthConnect;

  /// No description provided for @iCloudSync.
  ///
  /// In en, this message translates to:
  /// **'iCloud Sync'**
  String get iCloudSync;

  /// No description provided for @iCloudSyncDescription.
  ///
  /// In en, this message translates to:
  /// **'Sync data across devices'**
  String get iCloudSyncDescription;

  /// No description provided for @connected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get connected;

  /// No description provided for @notConnected.
  ///
  /// In en, this message translates to:
  /// **'Not Connected'**
  String get notConnected;

  /// No description provided for @connect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get connect;

  /// No description provided for @disconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get disconnect;

  /// No description provided for @subscription.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get subscription;

  /// No description provided for @gluButlerPro.
  ///
  /// In en, this message translates to:
  /// **'Glu Butler Pro'**
  String get gluButlerPro;

  /// No description provided for @upgradeToPro.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Pro'**
  String get upgradeToPro;

  /// No description provided for @proDescription.
  ///
  /// In en, this message translates to:
  /// **'Unlock all premium features'**
  String get proDescription;

  /// No description provided for @proFeature1.
  ///
  /// In en, this message translates to:
  /// **'Unlimited AI insights'**
  String get proFeature1;

  /// No description provided for @proFeature2.
  ///
  /// In en, this message translates to:
  /// **'Advanced analytics & reports'**
  String get proFeature2;

  /// No description provided for @proFeature3.
  ///
  /// In en, this message translates to:
  /// **'Data export'**
  String get proFeature3;

  /// No description provided for @proFeature4.
  ///
  /// In en, this message translates to:
  /// **'Priority support'**
  String get proFeature4;

  /// No description provided for @subscribeMonthly.
  ///
  /// In en, this message translates to:
  /// **'Subscribe Monthly'**
  String get subscribeMonthly;

  /// No description provided for @subscribeYearly.
  ///
  /// In en, this message translates to:
  /// **'Subscribe Yearly'**
  String get subscribeYearly;

  /// No description provided for @monthlyPrice.
  ///
  /// In en, this message translates to:
  /// **'\$4.99/month'**
  String get monthlyPrice;

  /// No description provided for @yearlyPrice.
  ///
  /// In en, this message translates to:
  /// **'\$39.99/year'**
  String get yearlyPrice;

  /// No description provided for @restorePurchases.
  ///
  /// In en, this message translates to:
  /// **'Restore Purchases'**
  String get restorePurchases;

  /// No description provided for @currentPlan.
  ///
  /// In en, this message translates to:
  /// **'Current Plan'**
  String get currentPlan;

  /// No description provided for @freePlan.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get freePlan;

  /// No description provided for @proPlan.
  ///
  /// In en, this message translates to:
  /// **'Pro'**
  String get proPlan;

  /// No description provided for @youArePro.
  ///
  /// In en, this message translates to:
  /// **'You\'re Pro!'**
  String get youArePro;

  /// No description provided for @proThankYou.
  ///
  /// In en, this message translates to:
  /// **'Thank you for supporting Glu Butler. Enjoy all premium features!'**
  String get proThankYou;

  /// No description provided for @subscriptionStartDate.
  ///
  /// In en, this message translates to:
  /// **'Started'**
  String get subscriptionStartDate;

  /// No description provided for @subscriptionPlan.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get subscriptionPlan;

  /// No description provided for @yearlyPlan.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get yearlyPlan;

  /// No description provided for @monthlyPlan.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthlyPlan;

  /// No description provided for @manageSubscription.
  ///
  /// In en, this message translates to:
  /// **'Manage Subscription'**
  String get manageSubscription;

  /// No description provided for @disclaimer.
  ///
  /// In en, this message translates to:
  /// **'This app is for reference only. Please consult with your doctor directly for medical advice.'**
  String get disclaimer;

  /// No description provided for @enterGlucose.
  ///
  /// In en, this message translates to:
  /// **'Enter Blood Glucose'**
  String get enterGlucose;

  /// No description provided for @enterMeal.
  ///
  /// In en, this message translates to:
  /// **'Add Meal'**
  String get enterMeal;

  /// No description provided for @enterExercise.
  ///
  /// In en, this message translates to:
  /// **'Add Exercise'**
  String get enterExercise;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get takePhoto;

  /// No description provided for @chooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from Gallery'**
  String get chooseFromGallery;

  /// No description provided for @maxImagesReached.
  ///
  /// In en, this message translates to:
  /// **'You can attach up to {count} images. {added} images have been added.'**
  String maxImagesReached(int count, int added);

  /// No description provided for @onlyImageFiles.
  ///
  /// In en, this message translates to:
  /// **'Only image files can be selected.'**
  String get onlyImageFiles;

  /// No description provided for @imageLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load images.'**
  String get imageLoadFailed;

  /// No description provided for @photoPermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Photo Access Permission Required'**
  String get photoPermissionRequired;

  /// No description provided for @photoPermissionMessage.
  ///
  /// In en, this message translates to:
  /// **'To attach photos, you need to allow access to your photo library.\n\nGo to Settings > Glu Butler to enable photo access.'**
  String get photoPermissionMessage;

  /// No description provided for @goToSettings.
  ///
  /// In en, this message translates to:
  /// **'Go to Settings'**
  String get goToSettings;

  /// No description provided for @noRecords.
  ///
  /// In en, this message translates to:
  /// **'No records yet'**
  String get noRecords;

  /// No description provided for @startTracking.
  ///
  /// In en, this message translates to:
  /// **'Start tracking your health!'**
  String get startTracking;

  /// No description provided for @feedEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Connect Apple Health to see more insights'**
  String get feedEmptyHint;

  /// No description provided for @goodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning!'**
  String get goodMorning;

  /// No description provided for @goodAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon!'**
  String get goodAfternoon;

  /// No description provided for @goodEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening!'**
  String get goodEvening;

  /// No description provided for @butlerGreeting.
  ///
  /// In en, this message translates to:
  /// **'Your butler is ready to help.'**
  String get butlerGreeting;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get home;

  /// No description provided for @yourToday.
  ///
  /// In en, this message translates to:
  /// **'Your Today'**
  String get yourToday;

  /// No description provided for @points.
  ///
  /// In en, this message translates to:
  /// **'pts'**
  String get points;

  /// No description provided for @todaysGlucose.
  ///
  /// In en, this message translates to:
  /// **'Glucose Trend'**
  String get todaysGlucose;

  /// No description provided for @todaysStats.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Stats'**
  String get todaysStats;

  /// No description provided for @average.
  ///
  /// In en, this message translates to:
  /// **'Average'**
  String get average;

  /// No description provided for @lowest.
  ///
  /// In en, this message translates to:
  /// **'Lowest'**
  String get lowest;

  /// No description provided for @highest.
  ///
  /// In en, this message translates to:
  /// **'Highest'**
  String get highest;

  /// No description provided for @glucoseDistribution.
  ///
  /// In en, this message translates to:
  /// **'Glucose Distribution'**
  String get glucoseDistribution;

  /// No description provided for @glucoseStatus.
  ///
  /// In en, this message translates to:
  /// **'Glucose Status'**
  String get glucoseStatus;

  /// No description provided for @scoreHint.
  ///
  /// In en, this message translates to:
  /// **'Learn about the score'**
  String get scoreHint;

  /// No description provided for @scoreInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Glucose Score Guide'**
  String get scoreInfoTitle;

  /// No description provided for @scoreInfoQuality.
  ///
  /// In en, this message translates to:
  /// **'Glucose Management Quality'**
  String get scoreInfoQuality;

  /// No description provided for @scoreInfoQualityDesc.
  ///
  /// In en, this message translates to:
  /// **'The closer your glucose measurements are to the target range, the higher your score.'**
  String get scoreInfoQualityDesc;

  /// No description provided for @scoreInfoConsistency.
  ///
  /// In en, this message translates to:
  /// **'Measurement Consistency'**
  String get scoreInfoConsistency;

  /// No description provided for @scoreInfoConsistencyDesc.
  ///
  /// In en, this message translates to:
  /// **'The more regularly you measure your glucose throughout the day, the higher your score.'**
  String get scoreInfoConsistencyDesc;

  /// No description provided for @scoreInfoRecommendation.
  ///
  /// In en, this message translates to:
  /// **'Recommended Measurement Frequency'**
  String get scoreInfoRecommendation;

  /// No description provided for @scoreInfoMorning.
  ///
  /// In en, this message translates to:
  /// **'Morning (before 9 AM): 1 fasting measurement'**
  String get scoreInfoMorning;

  /// No description provided for @scoreInfoLunch.
  ///
  /// In en, this message translates to:
  /// **'Before lunch (before 2 PM): 3 total measurements'**
  String get scoreInfoLunch;

  /// No description provided for @scoreInfoDinner.
  ///
  /// In en, this message translates to:
  /// **'Before dinner (before 7 PM): 5 total measurements'**
  String get scoreInfoDinner;

  /// No description provided for @scoreInfoBedtime.
  ///
  /// In en, this message translates to:
  /// **'Before bed (after 10 PM): 6 total measurements'**
  String get scoreInfoBedtime;

  /// No description provided for @scoreInfoLifestyle.
  ///
  /// In en, this message translates to:
  /// **'Lifestyle (with Health app)'**
  String get scoreInfoLifestyle;

  /// No description provided for @scoreInfoLifestyleDesc.
  ///
  /// In en, this message translates to:
  /// **'Sleep and exercise data from Apple Health are included for more accurate scoring.'**
  String get scoreInfoLifestyleDesc;

  /// No description provided for @scoreInfoPrivacy.
  ///
  /// In en, this message translates to:
  /// **'*All information used in the app is not stored separately or shared externally.'**
  String get scoreInfoPrivacy;

  /// No description provided for @times.
  ///
  /// In en, this message translates to:
  /// **'×'**
  String get times;

  /// No description provided for @viewReport.
  ///
  /// In en, this message translates to:
  /// **'View Report'**
  String get viewReport;

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'No data available'**
  String get noData;

  /// No description provided for @excellentScore.
  ///
  /// In en, this message translates to:
  /// **'Excellent! You\'re managing your glucose well today.'**
  String get excellentScore;

  /// No description provided for @goodScore.
  ///
  /// In en, this message translates to:
  /// **'Good! Just a little more attention and you\'ll be perfect.'**
  String get goodScore;

  /// No description provided for @needsAttention.
  ///
  /// In en, this message translates to:
  /// **'Your glucose varied a lot today. Check your diet.'**
  String get needsAttention;

  /// No description provided for @noGlucoseToday.
  ///
  /// In en, this message translates to:
  /// **'No glucose records today'**
  String get noGlucoseToday;

  /// No description provided for @addGlucose.
  ///
  /// In en, this message translates to:
  /// **'Add Glucose'**
  String get addGlucose;

  /// No description provided for @addDiaryEntry.
  ///
  /// In en, this message translates to:
  /// **'Add Diary Entry'**
  String get addDiaryEntry;

  /// No description provided for @diaryPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Write your glucose management diary'**
  String get diaryPlaceholder;

  /// No description provided for @attachPhoto.
  ///
  /// In en, this message translates to:
  /// **'Attach Photo'**
  String get attachPhoto;

  /// No description provided for @discardDiaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard Entry'**
  String get discardDiaryTitle;

  /// No description provided for @discardDiaryMessage.
  ///
  /// In en, this message translates to:
  /// **'Your unsaved changes will be lost.\nDiscard this entry?'**
  String get discardDiaryMessage;

  /// No description provided for @diarySaved.
  ///
  /// In en, this message translates to:
  /// **'Diary entry saved'**
  String get diarySaved;

  /// No description provided for @diarySaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save diary entry'**
  String get diarySaveFailed;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @insulin.
  ///
  /// In en, this message translates to:
  /// **'Insulin'**
  String get insulin;

  /// No description provided for @addInsulin.
  ///
  /// In en, this message translates to:
  /// **'Add Insulin'**
  String get addInsulin;

  /// No description provided for @insulinType.
  ///
  /// In en, this message translates to:
  /// **'Insulin Type'**
  String get insulinType;

  /// No description provided for @rapidActing.
  ///
  /// In en, this message translates to:
  /// **'Rapid-acting'**
  String get rapidActing;

  /// No description provided for @longActing.
  ///
  /// In en, this message translates to:
  /// **'Long-acting'**
  String get longActing;

  /// No description provided for @insulinDose.
  ///
  /// In en, this message translates to:
  /// **'Dose'**
  String get insulinDose;

  /// No description provided for @units.
  ///
  /// In en, this message translates to:
  /// **'U'**
  String get units;

  /// No description provided for @injectionSite.
  ///
  /// In en, this message translates to:
  /// **'Injection Site'**
  String get injectionSite;

  /// No description provided for @abdomen.
  ///
  /// In en, this message translates to:
  /// **'Abdomen'**
  String get abdomen;

  /// No description provided for @thigh.
  ///
  /// In en, this message translates to:
  /// **'Thigh'**
  String get thigh;

  /// No description provided for @arm.
  ///
  /// In en, this message translates to:
  /// **'Arm'**
  String get arm;

  /// No description provided for @buttock.
  ///
  /// In en, this message translates to:
  /// **'Buttock'**
  String get buttock;

  /// No description provided for @measurementTime.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get measurementTime;

  /// No description provided for @injectionTime.
  ///
  /// In en, this message translates to:
  /// **'Injection Time'**
  String get injectionTime;

  /// No description provided for @deliveryType.
  ///
  /// In en, this message translates to:
  /// **'Insulin Type'**
  String get deliveryType;

  /// No description provided for @bolus.
  ///
  /// In en, this message translates to:
  /// **'Rapid-acting'**
  String get bolus;

  /// No description provided for @basal.
  ///
  /// In en, this message translates to:
  /// **'Long-acting'**
  String get basal;

  /// No description provided for @measurementTiming.
  ///
  /// In en, this message translates to:
  /// **'Timing'**
  String get measurementTiming;

  /// No description provided for @addRecord.
  ///
  /// In en, this message translates to:
  /// **'Add Record'**
  String get addRecord;

  /// No description provided for @glucoseSaved.
  ///
  /// In en, this message translates to:
  /// **'Blood glucose saved'**
  String get glucoseSaved;

  /// No description provided for @insulinSaved.
  ///
  /// In en, this message translates to:
  /// **'Insulin dose saved'**
  String get insulinSaved;

  /// No description provided for @saveFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save'**
  String get saveFailed;

  /// No description provided for @appleHealth.
  ///
  /// In en, this message translates to:
  /// **'Apple Health'**
  String get appleHealth;

  /// No description provided for @appleHealthDescription.
  ///
  /// In en, this message translates to:
  /// **'Connect with the Health app to view workouts, sleep, weight, and other data that may help you manage your blood glucose.'**
  String get appleHealthDescription;

  /// No description provided for @syncedData.
  ///
  /// In en, this message translates to:
  /// **'Synced Data'**
  String get syncedData;

  /// No description provided for @connectAppleHealth.
  ///
  /// In en, this message translates to:
  /// **'Connect Apple Health'**
  String get connectAppleHealth;

  /// No description provided for @successfullyConnected.
  ///
  /// In en, this message translates to:
  /// **'Sync info has been updated'**
  String get successfullyConnected;

  /// No description provided for @failedToConnect.
  ///
  /// In en, this message translates to:
  /// **'Failed to connect. Please check your permissions in the Apple Health app.'**
  String get failedToConnect;

  /// No description provided for @privacyNote.
  ///
  /// In en, this message translates to:
  /// **'Your health data is stored only on your device and is never shared externally. You can manage access in Health app > Sharing > Apps > Glu Butler.'**
  String get privacyNote;

  /// No description provided for @readWrite.
  ///
  /// In en, this message translates to:
  /// **'Read & Write'**
  String get readWrite;

  /// No description provided for @readOnly.
  ///
  /// In en, this message translates to:
  /// **'Read only'**
  String get readOnly;

  /// No description provided for @workouts.
  ///
  /// In en, this message translates to:
  /// **'Workouts'**
  String get workouts;

  /// No description provided for @running.
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get running;

  /// No description provided for @walking.
  ///
  /// In en, this message translates to:
  /// **'Walking'**
  String get walking;

  /// No description provided for @cycling.
  ///
  /// In en, this message translates to:
  /// **'Cycling'**
  String get cycling;

  /// No description provided for @swimming.
  ///
  /// In en, this message translates to:
  /// **'Swimming'**
  String get swimming;

  /// No description provided for @yoga.
  ///
  /// In en, this message translates to:
  /// **'Yoga'**
  String get yoga;

  /// No description provided for @strength.
  ///
  /// In en, this message translates to:
  /// **'Strength Training'**
  String get strength;

  /// No description provided for @hiit.
  ///
  /// In en, this message translates to:
  /// **'HIIT'**
  String get hiit;

  /// No description provided for @stairs.
  ///
  /// In en, this message translates to:
  /// **'Stairs'**
  String get stairs;

  /// No description provided for @dance.
  ///
  /// In en, this message translates to:
  /// **'Dance'**
  String get dance;

  /// No description provided for @functional.
  ///
  /// In en, this message translates to:
  /// **'Functional Training'**
  String get functional;

  /// No description provided for @core.
  ///
  /// In en, this message translates to:
  /// **'Core Training'**
  String get core;

  /// No description provided for @flexibility.
  ///
  /// In en, this message translates to:
  /// **'Flexibility'**
  String get flexibility;

  /// No description provided for @cardio.
  ///
  /// In en, this message translates to:
  /// **'Cardio'**
  String get cardio;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Workout'**
  String get other;

  /// No description provided for @sleep.
  ///
  /// In en, this message translates to:
  /// **'Sleep'**
  String get sleep;

  /// No description provided for @weightBody.
  ///
  /// In en, this message translates to:
  /// **'Weight & Body'**
  String get weightBody;

  /// No description provided for @waterIntake.
  ///
  /// In en, this message translates to:
  /// **'Water Intake'**
  String get waterIntake;

  /// No description provided for @menstrualCycle.
  ///
  /// In en, this message translates to:
  /// **'Menstrual Cycle'**
  String get menstrualCycle;

  /// No description provided for @steps.
  ///
  /// In en, this message translates to:
  /// **'Steps'**
  String get steps;

  /// No description provided for @mindfulness.
  ///
  /// In en, this message translates to:
  /// **'Mindfulness'**
  String get mindfulness;

  /// No description provided for @openHealthApp.
  ///
  /// In en, this message translates to:
  /// **'Open Health app > Sharing > Apps to manage permissions'**
  String get openHealthApp;

  /// No description provided for @syncPeriod.
  ///
  /// In en, this message translates to:
  /// **'Sync Period'**
  String get syncPeriod;

  /// No description provided for @syncPeriod1Week.
  ///
  /// In en, this message translates to:
  /// **'1 Week'**
  String get syncPeriod1Week;

  /// No description provided for @syncPeriod2Weeks.
  ///
  /// In en, this message translates to:
  /// **'2 Weeks'**
  String get syncPeriod2Weeks;

  /// No description provided for @syncPeriod1Month.
  ///
  /// In en, this message translates to:
  /// **'1 Month'**
  String get syncPeriod1Month;

  /// No description provided for @syncPeriod3Months.
  ///
  /// In en, this message translates to:
  /// **'3 Months'**
  String get syncPeriod3Months;

  /// No description provided for @disconnected.
  ///
  /// In en, this message translates to:
  /// **'Disconnected from Apple Health'**
  String get disconnected;

  /// No description provided for @cgmBaseline.
  ///
  /// In en, this message translates to:
  /// **'Stable'**
  String get cgmBaseline;

  /// No description provided for @cgmFluctuation.
  ///
  /// In en, this message translates to:
  /// **'Fluctuation'**
  String get cgmFluctuation;

  /// No description provided for @targetGlucoseRange.
  ///
  /// In en, this message translates to:
  /// **'Target Glucose Range'**
  String get targetGlucoseRange;

  /// No description provided for @targetGlucoseRangeDescription.
  ///
  /// In en, this message translates to:
  /// **'Your target values are used to analyze glucose data more accurately in the feed.'**
  String get targetGlucoseRangeDescription;

  /// No description provided for @veryHigh.
  ///
  /// In en, this message translates to:
  /// **'Very High'**
  String get veryHigh;

  /// No description provided for @warning.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get warning;

  /// No description provided for @target.
  ///
  /// In en, this message translates to:
  /// **'Target'**
  String get target;

  /// No description provided for @veryLow.
  ///
  /// In en, this message translates to:
  /// **'Very Low'**
  String get veryLow;

  /// No description provided for @appSlogan.
  ///
  /// In en, this message translates to:
  /// **'Your Health Companion'**
  String get appSlogan;

  /// No description provided for @initLoadingSettings.
  ///
  /// In en, this message translates to:
  /// **'Loading settings...'**
  String get initLoadingSettings;

  /// No description provided for @initCheckingHealth.
  ///
  /// In en, this message translates to:
  /// **'Checking health data sync...'**
  String get initCheckingHealth;

  /// No description provided for @initCheckingiCloud.
  ///
  /// In en, this message translates to:
  /// **'Checking iCloud sync...'**
  String get initCheckingiCloud;

  /// No description provided for @initLocalDatabase.
  ///
  /// In en, this message translates to:
  /// **'Initializing local database...'**
  String get initLocalDatabase;

  /// No description provided for @initDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get initDone;

  /// No description provided for @syncCompleteMessage.
  ///
  /// In en, this message translates to:
  /// **'{count} records synced to Apple Health'**
  String syncCompleteMessage(int count);

  /// No description provided for @syncPartialMessage.
  ///
  /// In en, this message translates to:
  /// **'{success} of {total} records synced. Rest will retry later.'**
  String syncPartialMessage(int success, int total);

  /// No description provided for @syncFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Sync failed. Will retry on next app launch.'**
  String get syncFailedMessage;

  /// No description provided for @deleteGlucoseConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete?\nThis action cannot be undone.'**
  String get deleteGlucoseConfirmation;

  /// No description provided for @glucoseDeleted.
  ///
  /// In en, this message translates to:
  /// **'Glucose record deleted'**
  String get glucoseDeleted;

  /// No description provided for @insulinDeleted.
  ///
  /// In en, this message translates to:
  /// **'Insulin record deleted'**
  String get insulinDeleted;

  /// No description provided for @deleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Delete failed'**
  String get deleteFailed;

  /// No description provided for @deleteDiary.
  ///
  /// In en, this message translates to:
  /// **'Delete Diary'**
  String get deleteDiary;

  /// No description provided for @deleteDiaryConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete?\nThis action cannot be undone.'**
  String get deleteDiaryConfirmation;

  /// No description provided for @diaryDeleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted'**
  String get diaryDeleted;

  /// No description provided for @diaryDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Delete failed'**
  String get diaryDeleteFailed;

  /// No description provided for @diaryUpdated.
  ///
  /// In en, this message translates to:
  /// **'Diary updated'**
  String get diaryUpdated;

  /// No description provided for @editDiary.
  ///
  /// In en, this message translates to:
  /// **'Edit Diary'**
  String get editDiary;

  /// No description provided for @showMore.
  ///
  /// In en, this message translates to:
  /// **'Show More'**
  String get showMore;

  /// No description provided for @showLess.
  ///
  /// In en, this message translates to:
  /// **'Show Less'**
  String get showLess;

  /// No description provided for @diaryContentRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter content or attach photos.'**
  String get diaryContentRequired;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get confirm;

  /// No description provided for @dataSyncPeriodInfo.
  ///
  /// In en, this message translates to:
  /// **'Showing recent {period} data. Period can be changed in Apple Health settings'**
  String dataSyncPeriodInfo(String period);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'de',
    'en',
    'es',
    'fr',
    'it',
    'ja',
    'ko',
    'zh',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'it':
      return AppLocalizationsIt();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
