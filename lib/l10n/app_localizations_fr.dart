// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appName => 'Glu Butler';

  @override
  String get feed => 'Fil';

  @override
  String get diary => 'Journal';

  @override
  String get report => 'Rapport';

  @override
  String get settings => 'Paramètres';

  @override
  String get add => 'Ajouter';

  @override
  String get cancel => 'Annuler';

  @override
  String get close => 'Fermer';

  @override
  String get save => 'Enregistrer';

  @override
  String get done => 'Terminé';

  @override
  String get delete => 'Supprimer';

  @override
  String get edit => 'Modifier';

  @override
  String get selectDate => 'Sélectionner une date';

  @override
  String get today => 'Aujourd\'hui';

  @override
  String get yesterday => 'Hier';

  @override
  String get thisWeek => 'Cette semaine';

  @override
  String get thisMonth => 'Ce mois-ci';

  @override
  String get bloodGlucose => 'Glycémie';

  @override
  String get meal => 'Repas';

  @override
  String get exercise => 'Exercice';

  @override
  String get glucoseUnit => 'Unité';

  @override
  String get glucoseUnitDescription =>
      'Select the unit for glucose measurement.';

  @override
  String get mgdl => 'mg/dL';

  @override
  String get mmoll => 'mmol/L';

  @override
  String get low => 'Bas';

  @override
  String get normal => 'Normal';

  @override
  String get high => 'Élevé';

  @override
  String get breakfast => 'Petit-déjeuner';

  @override
  String get lunch => 'Déjeuner';

  @override
  String get dinner => 'Dîner';

  @override
  String get snack => 'Collation';

  @override
  String get fasting => 'À jeun';

  @override
  String get beforeMeal => 'Avant le repas';

  @override
  String get afterMeal => 'Après le repas';

  @override
  String get unspecified => 'Non spécifié';

  @override
  String get dailyReport => 'Rapport quotidien';

  @override
  String get weeklyReport => 'Rapport hebdomadaire';

  @override
  String get aiInsight => 'Analyse IA';

  @override
  String get glucoseScore => 'Score glycémique';

  @override
  String get profile => 'Profil';

  @override
  String get name => 'Nom';

  @override
  String get gender => 'Genre';

  @override
  String get male => 'Masculin';

  @override
  String get female => 'Féminin';

  @override
  String get birthday => 'Date de naissance';

  @override
  String get diabetesType => 'Type de diabète';

  @override
  String get type1 => 'Type 1';

  @override
  String get type2 => 'Type 2';

  @override
  String get none => 'Aucun';

  @override
  String get language => 'Langue';

  @override
  String get changeInSettings => 'Modifier dans Réglages';

  @override
  String get darkMode => 'Mode sombre';

  @override
  String get displaySettings => 'Affichage';

  @override
  String get systemDefault => 'Par défaut du système';

  @override
  String get systemDefaultDescription => 'Suivre le thème du système';

  @override
  String get lightMode => 'Clair';

  @override
  String get darkModeOption => 'Sombre';

  @override
  String get notifications => 'Notifications';

  @override
  String get notificationTime => 'Heure de notification';

  @override
  String get sync => 'Synchronisation';

  @override
  String get healthConnect => 'Connexion santé';

  @override
  String get iCloudSync => 'Synchronisation iCloud';

  @override
  String get iCloudSyncDescription =>
      'Synchroniser les données sur plusieurs appareils';

  @override
  String get connected => 'Connecté';

  @override
  String get notConnected => 'Non connecté';

  @override
  String get connect => 'Connecter';

  @override
  String get disconnect => 'Déconnecter';

  @override
  String get subscription => 'Abonnement';

  @override
  String get gluButlerPro => 'Glu Butler Pro';

  @override
  String get upgradeToPro => 'Passer à Pro';

  @override
  String get proDescription => 'Débloquez toutes les fonctionnalités premium';

  @override
  String get proFeature1 => 'Analyses IA illimitées';

  @override
  String get proFeature2 => 'Analyses et rapports avancés';

  @override
  String get proFeature3 => 'Exportation des données';

  @override
  String get proFeature4 => 'Support prioritaire';

  @override
  String get subscribeMonthly => 'Abonnement mensuel';

  @override
  String get subscribeYearly => 'Abonnement annuel';

  @override
  String get monthlyPrice => '4,99 €/mois';

  @override
  String get yearlyPrice => '39,99 €/an';

  @override
  String get restorePurchases => 'Restaurer les achats';

  @override
  String get currentPlan => 'Plan actuel';

  @override
  String get freePlan => 'Gratuit';

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
  String get disclaimer =>
      'Cette application est fournie à titre indicatif. Veuillez consulter directement votre médecin pour des conseils médicaux.';

  @override
  String get enterGlucose => 'Saisir la glycémie';

  @override
  String get enterMeal => 'Ajouter un repas';

  @override
  String get enterExercise => 'Ajouter un exercice';

  @override
  String get takePhoto => 'Prendre une photo';

  @override
  String get chooseFromGallery => 'Choisir dans la galerie';

  @override
  String maxImagesReached(int count, int added) {
    return 'Vous pouvez joindre jusqu\'à $count images. $added images ont été ajoutées.';
  }

  @override
  String get onlyImageFiles =>
      'Seuls les fichiers image peuvent être sélectionnés.';

  @override
  String get imageLoadFailed => 'Échec du chargement des photos.';

  @override
  String get photoPermissionRequired =>
      'Permission d\'accès aux photos requise';

  @override
  String get photoPermissionMessage =>
      'Pour joindre des photos, vous devez autoriser l\'accès à votre bibliothèque de photos.\n\nAllez dans Réglages > Glu Butler pour activer l\'accès aux photos.';

  @override
  String get goToSettings => 'Aller aux Réglages';

  @override
  String get noRecords => 'Aucun enregistrement';

  @override
  String get noReportYet => 'Pas encore de rapport.';

  @override
  String get startTracking => 'Commencez à suivre votre santé !';

  @override
  String get feedEmptyHint => 'Connectez Apple Santé pour plus d\'informations';

  @override
  String get goodMorning => 'Bonjour !';

  @override
  String get goodAfternoon => 'Bon après-midi !';

  @override
  String get goodEvening => 'Bonsoir !';

  @override
  String get butlerGreeting => 'Votre majordome est prêt à vous aider.';

  @override
  String get home => 'Aujourd\'hui';

  @override
  String get yourToday => 'Votre Aujourd\'hui';

  @override
  String get points => 'pts';

  @override
  String get todaysGlucose => 'Tendance Glycémique';

  @override
  String get todaysStats => 'Statistiques du Jour';

  @override
  String get average => 'Moyenne';

  @override
  String get lowest => 'Minimum';

  @override
  String get highest => 'Maximum';

  @override
  String get glucoseDistribution => 'Distribution Glycémique';

  @override
  String get glucoseStatus => 'État Glycémique';

  @override
  String get scoreHint => 'En savoir plus sur le score';

  @override
  String get scoreInfoTitle => 'Guide du score glycémique';

  @override
  String get scoreInfoQuality => 'Qualité de la gestion glycémique';

  @override
  String get scoreInfoQualityDesc =>
      'Plus vos mesures de glycémie sont proches de la plage cible, plus votre score est élevé.';

  @override
  String get scoreInfoConsistency => 'Cohérence des mesures';

  @override
  String get scoreInfoConsistencyDesc =>
      'Plus vous mesurez régulièrement votre glycémie tout au long de la journée, plus votre score est élevé.';

  @override
  String get scoreInfoRecommendation => 'Fréquence de mesure recommandée';

  @override
  String get scoreInfoMorning => 'Matin (avant 9h) : 1 mesure à jeun';

  @override
  String get scoreInfoLunch =>
      'Avant le déjeuner (avant 14h) : 3 mesures au total';

  @override
  String get scoreInfoDinner =>
      'Avant le dîner (avant 19h) : 5 mesures au total';

  @override
  String get scoreInfoBedtime =>
      'Avant de dormir (après 22h) : 6 mesures au total';

  @override
  String get scoreInfoLifestyle => 'Mode de vie (avec app Santé)';

  @override
  String get scoreInfoLifestyleDesc =>
      'Les données de sommeil et d\'exercice d\'Apple Santé sont incluses pour un score plus précis.';

  @override
  String get scoreInfoPrivacy =>
      '*Toutes les informations utilisées dans l\'app ne sont pas stockées séparément ni partagées en externe.';

  @override
  String get times => '×';

  @override
  String get viewReport => 'Voir le Rapport';

  @override
  String get noData => 'Aucune donnée disponible';

  @override
  String get excellentScore =>
      'Excellent ! Vous gérez bien votre glycémie aujourd\'hui.';

  @override
  String get goodScore =>
      'Bien ! Encore un peu d\'attention et ce sera parfait.';

  @override
  String get needsAttention =>
      'Votre glycémie a beaucoup varié aujourd\'hui. Vérifiez votre alimentation.';

  @override
  String get noGlucoseToday => 'Pas de glycémie enregistrée aujourd\'hui';

  @override
  String get addGlucose => 'Ajouter Glycémie';

  @override
  String get addDiaryEntry => 'Ajouter une entrée';

  @override
  String get diaryPlaceholder =>
      'Écrivez votre journal de gestion de la glycémie';

  @override
  String get attachPhoto => 'Joindre une photo';

  @override
  String get discardDiaryTitle => 'Annuler l\'entrée';

  @override
  String get discardDiaryMessage =>
      'Vos modifications non enregistrées seront perdues.\nAbandonner cette entrée?';

  @override
  String get diarySaved => 'Entrée enregistrée';

  @override
  String get diarySaveFailed => 'Échec de l\'enregistrement de l\'entrée';

  @override
  String get yes => 'Oui';

  @override
  String get no => 'Non';

  @override
  String get insulin => 'Insuline';

  @override
  String get addInsulin => 'Ajouter Insuline';

  @override
  String get insulinType => 'Type d\'insuline';

  @override
  String get rapidActing => 'Action rapide';

  @override
  String get longActing => 'Action prolongée';

  @override
  String get insulinDose => 'Dose';

  @override
  String get units => 'U';

  @override
  String get injectionSite => 'Site d\'injection';

  @override
  String get abdomen => 'Abdomen';

  @override
  String get thigh => 'Cuisse';

  @override
  String get arm => 'Bras';

  @override
  String get buttock => 'Fesse';

  @override
  String get measurementTime => 'Heure';

  @override
  String get injectionTime => 'Heure d\'injection';

  @override
  String get deliveryType => 'Type d\'insuline';

  @override
  String get bolus => 'Action rapide';

  @override
  String get basal => 'Action prolongée';

  @override
  String get measurementTiming => 'Moment';

  @override
  String get addRecord => 'Ajouter un enregistrement';

  @override
  String get glucoseSaved => 'Glycémie enregistrée';

  @override
  String get insulinSaved => 'Dose d\'insuline enregistrée';

  @override
  String get saveFailed => 'Échec de l\'enregistrement';

  @override
  String get appleHealth => 'Apple Santé';

  @override
  String get appleHealthDescription =>
      'Connectez-vous à l\'app Santé pour consulter diverses données pouvant vous aider à gérer votre glycémie.';

  @override
  String get syncedData => 'Données synchronisées';

  @override
  String get connectAppleHealth => 'Connecter Apple Santé';

  @override
  String get successfullyConnected =>
      'Les informations de synchronisation ont été mises à jour';

  @override
  String get failedToConnect =>
      'Échec de la connexion. Veuillez vérifier les autorisations dans l\'app Apple Santé.';

  @override
  String get privacyNote =>
      'Vos données de santé sont stockées uniquement sur votre appareil et ne sont jamais partagées à l\'extérieur. Vous pouvez gérer l\'accès dans Santé > Partage > Apps > Glu Butler.';

  @override
  String get readWrite => 'Lecture et écriture';

  @override
  String get readOnly => 'Lecture seule';

  @override
  String get workouts => 'Exercices';

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
  String get sleep => 'Sommeil';

  @override
  String get weightBody => 'Poids et corps';

  @override
  String get waterIntake => 'Consommation d\'eau';

  @override
  String get menstrualCycle => 'Cycle menstruel';

  @override
  String get steps => 'Pas';

  @override
  String get mindfulness => 'Pleine conscience';

  @override
  String get openHealthApp =>
      'Ouvrez Santé > Partage > Apps pour gérer les autorisations';

  @override
  String get syncPeriod => 'Période de synchronisation';

  @override
  String get syncPeriod1Week => '1 semaine';

  @override
  String get syncPeriod2Weeks => '2 semaines';

  @override
  String get syncPeriod1Month => '1 mois';

  @override
  String get syncPeriod3Months => '3 mois';

  @override
  String get disconnected => 'Déconnecté d\'Apple Santé';

  @override
  String get cgmBaseline => 'Stable';

  @override
  String get cgmFluctuation => 'Fluctuation';

  @override
  String get targetGlucoseRange => 'Plage de glycémie cible';

  @override
  String get targetGlucoseRangeDescription =>
      'Your target values are used to analyze glucose data more accurately in the feed.';

  @override
  String get veryHigh => 'Très Élevé';

  @override
  String get warning => 'Attention';

  @override
  String get target => 'Cible';

  @override
  String get veryLow => 'Très Bas';

  @override
  String get appSlogan => 'Votre compagnon santé';

  @override
  String get initLoadingSettings => 'Chargement des paramètres...';

  @override
  String get initCheckingHealth =>
      'Vérification de la synchronisation santé...';

  @override
  String get initCheckingiCloud =>
      'Vérification de la synchronisation iCloud...';

  @override
  String get initLocalDatabase =>
      'Initialisation de la base de données locale...';

  @override
  String get initDone => 'Terminé';

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
  String get deleteGlucoseConfirmation =>
      'Êtes-vous sûr de vouloir supprimer ?\nCette action ne peut pas être annulée.';

  @override
  String get glucoseDeleted => 'Glycémie supprimée';

  @override
  String get insulinDeleted => 'Insuline supprimée';

  @override
  String get deleteFailed => 'Échec de la suppression';

  @override
  String get deleteDiary => 'Supprimer le journal';

  @override
  String get deleteDiaryConfirmation =>
      'Voulez-vous vraiment supprimer ?\nCette action est irréversible.';

  @override
  String get diaryDeleted => 'Supprimé';

  @override
  String get diaryDeleteFailed => 'Échec de la suppression';

  @override
  String get diaryUpdated => 'Journal mis à jour';

  @override
  String get editDiary => 'Modifier le journal';

  @override
  String get showMore => 'Afficher plus';

  @override
  String get showLess => 'Afficher moins';

  @override
  String get diaryContentRequired =>
      'Veuillez saisir du contenu ou joindre des photos.';

  @override
  String get error => 'Erreur';

  @override
  String get confirm => 'OK';

  @override
  String dataSyncPeriodInfo(String period) {
    return 'Affichage des données de $period récentes. La période peut être modifiée dans les paramètres Apple Health';
  }

  @override
  String get generateReport => 'Générer un rapport';

  @override
  String get reportGuideTitle => 'À propos des rapports';

  @override
  String get reportGuideMessage =>
      '• Les rapports sont générés par l\'IA en analysant vos données de glucose.\n\n• Bien que vous puissiez générer maintenant, avoir au moins un jour de données de glucose fournira une analyse plus précise.\n\n• Après votre premier rapport, vous pouvez générer de nouveaux rapports chaque semaine.\n\n• Les rapports fournissent des informations détaillées basées sur le sommeil, l\'exercice et d\'autres données de santé de l\'application Santé.\n\n• Rédiger des entrées quotidiennes dans le journal de glucose aide à identifier les schémas quotidiens.\n\n• Essayez de mettre en œuvre les améliorations de style de vie suggérées dans les rapports et notez toute observation inhabituelle dans votre journal.';

  @override
  String get doNotShowAgain => 'Ne plus afficher';

  @override
  String get viewPastReports => 'Voir les rapports précédents';

  @override
  String get reportPeriod => 'Période du rapport';

  @override
  String get selectDateRange => 'Sélectionner la plage de dates';

  @override
  String get selectStartAndEndDate =>
      'Sélectionnez les dates de début et de fin';

  @override
  String get month => 'mois';

  @override
  String get day => 'jour';

  @override
  String get newReport => 'Créer un nouveau rapport';
}
