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

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

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

  /// No description provided for @fasting.
  ///
  /// In en, this message translates to:
  /// **'Fasting'**
  String get fasting;

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

  /// No description provided for @healthConnect.
  ///
  /// In en, this message translates to:
  /// **'Health Connect'**
  String get healthConnect;

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
  /// **'This app is for reference only and does not provide medical advice.'**
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

  /// No description provided for @times.
  ///
  /// In en, this message translates to:
  /// **'times'**
  String get times;

  /// No description provided for @viewReport.
  ///
  /// In en, this message translates to:
  /// **'View Report'**
  String get viewReport;

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

  /// No description provided for @shortActing.
  ///
  /// In en, this message translates to:
  /// **'Short-acting'**
  String get shortActing;

  /// No description provided for @intermediateActing.
  ///
  /// In en, this message translates to:
  /// **'Intermediate'**
  String get intermediateActing;

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
