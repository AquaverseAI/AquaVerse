// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'AquaVerse AI';

  @override
  String get betterDecisionsBetterHarvest => 'Better decisions, better harvest';

  @override
  String get getStarted => 'Get Started';

  @override
  String get navToday => 'Today';

  @override
  String get navLog => 'Pond Check';

  @override
  String get navAsk => 'Ask AI';

  @override
  String get navAlerts => 'Alerts';

  @override
  String get navCrop => 'Crop';

  @override
  String get navProfile => 'Profile';

  @override
  String get navSettings => 'Settings';

  @override
  String get signOut => 'Sign Out';

  @override
  String get back => 'Back';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get save => 'Save';

  @override
  String get retry => 'Retry';

  @override
  String get loading => 'Loading…';

  @override
  String get unknown => 'Unknown';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get selectLanguageSubtitle => 'Choose your preferred language';

  @override
  String get continueBtn => 'Continue';

  @override
  String get phoneNumberLabel => 'Mobile Number';

  @override
  String get phoneNumberHint => 'Enter 10-digit mobile number';

  @override
  String get roleSelectionTitle => 'Who are you?';

  @override
  String get roleSelectionSubtitle => 'Select your role to get started';

  @override
  String get roleLabel => 'I am a…';

  @override
  String get roleFarmer => 'Farmer';

  @override
  String get farmerSublabel => 'Manage your pond and get daily recommendations';

  @override
  String get roleOfficer => 'Extension Officer';

  @override
  String get officerSublabel => 'Oversee multiple ponds and log field visits';

  @override
  String get selectRolePrompt => 'Please select a role to continue';

  @override
  String get selectedRoleLabel => 'Selected role';

  @override
  String get changeRole => 'Change';

  @override
  String get phoneTitle => 'Enter your phone number';

  @override
  String get phoneSubtitle => 'We\'ll send a verification code to this number';

  @override
  String get phoneValidationError =>
      'Please enter a valid 10-digit mobile number';

  @override
  String get sendOtp => 'Send OTP';

  @override
  String get otpTitle => 'Verify OTP';

  @override
  String get otpSubtitle => 'Enter the 6-digit code sent to';

  @override
  String get otpHint => '6-digit OTP';

  @override
  String get verifyOtp => 'Verify';

  @override
  String get resendOtp => 'Resend OTP';

  @override
  String resendIn(int seconds) {
    return 'Resend in ${seconds}s';
  }

  @override
  String get otpExpired => 'OTP expired. Please request a new one.';

  @override
  String get otpInvalid => 'Invalid OTP. Please try again.';

  @override
  String get authError => 'Authentication failed. Please try again.';

  @override
  String get networkError =>
      'No network connection. Check your connection and retry.';

  @override
  String get sessionExpired => 'Your session has expired. Please log in again.';

  @override
  String get vanakkam => 'Hello,';

  @override
  String get overallPondRisk => 'Overall Pond Risk';

  @override
  String get lowRisk => 'Low Risk';

  @override
  String get mediumRisk => 'Medium Risk';

  @override
  String get highRisk => 'High Risk';

  @override
  String get lowRiskDesc =>
      'Pond environment is stable and optimal for crop growth.';

  @override
  String get mediumRiskDesc =>
      'Parameters show slight variance. Monitor closely today.';

  @override
  String get highRiskDesc =>
      'Attention required. Environmental conditions need immediate check.';

  @override
  String get latestParameters => 'Latest Water Parameters';

  @override
  String get fieldCheck => 'Field Check';

  @override
  String get recentEvents => 'Recent Pond Events';

  @override
  String get todayFarmAction => 'Today\'s Farm Action';

  @override
  String get pondHealthIndex => 'Pond Health Index';

  @override
  String get doForecastChart => 'DO Forecast';

  @override
  String get feedRecommendation => 'Feed Recommendation';

  @override
  String get sensorReadings => 'Sensor Readings';

  @override
  String get waterQualityGood => 'Water Quality Optimal';

  @override
  String get advisories => 'Farm Advisories';

  @override
  String get noAdvisories => 'No advisories today';

  @override
  String get offlineNotice => 'Ask AI needs internet. Connect to get answers.';

  @override
  String get pullToRefresh => 'Pull to refresh';

  @override
  String get dataUnavailable => 'Data unavailable';

  @override
  String get blindState => 'Not enough data to assess';

  @override
  String get blindStateDetail => 'Log pond data to improve recommendations.';

  @override
  String get pondCheckTitle => 'Pond Check';

  @override
  String get feedGiven => 'Feed Given (kg)';

  @override
  String get feedGivenHint => 'Enter amount in kg';

  @override
  String get mortality => 'Mortality Count';

  @override
  String get mortalityHint => 'Number of dead fish';

  @override
  String get feedTray => 'Feed Tray Status';

  @override
  String get feedTrayEmpty => 'Empty — fish ate all';

  @override
  String get feedTraySome => 'Some left';

  @override
  String get feedTrayFull => 'Full — fish not eating';

  @override
  String get waterColor => 'Water Appearance';

  @override
  String get waterColorGood => 'Good (green/clear)';

  @override
  String get waterColorMuddy => 'Muddy / Brown';

  @override
  String get waterColorFoamy => 'Foamy / Unusual';

  @override
  String get notes => 'Observations (optional)';

  @override
  String get notesHint => 'Any unusual observations…';

  @override
  String get addPhoto => 'Add Photo';

  @override
  String get submitLog => 'Submit';

  @override
  String get logSaved => 'Log saved';

  @override
  String get logQueued => 'Saved offline — will sync when connected';

  @override
  String get logError => 'Could not save log. Please try again.';

  @override
  String get dissolvedOxygen => 'Dissolved Oxygen (mg/L)';

  @override
  String get pHLevel => 'pH Level';

  @override
  String get temperature => 'Water Temperature (°C)';

  @override
  String get salinity => 'Salinity (ppt)';

  @override
  String get ammonia => 'Ammonia (mg/L)';

  @override
  String get askTitle => 'Ask Aqua AI';

  @override
  String get tapToAsk => 'Tap the orb and speak your question';

  @override
  String get listeningText => 'Listening… Speak now';

  @override
  String get thinkingText => 'Processing your question…';

  @override
  String get responsePrompt => 'Tap orb for a new question';

  @override
  String get typeQuestion => 'Type your question…';

  @override
  String get recentQuestions => 'Recent Questions';

  @override
  String get aquaAnswer => 'Aqua\'s Answer';

  @override
  String get callOfficer => 'Call Extension Officer';

  @override
  String get askOffline => 'Ask AI requires internet connection.';

  @override
  String get audioUnavailable => 'Audio read-aloud not available';

  @override
  String get sampleQuery1 => 'How much feed should I give today?';

  @override
  String get sampleQuery2 => 'What to do if DO drops below 4 mg/L?';

  @override
  String get sampleQuery3 => 'How to maintain pH balance in rainy season?';

  @override
  String get sampleQuery4 => 'What is the optimal ammonia level?';

  @override
  String get alertsTitle => 'Alerts';

  @override
  String get noAlerts => 'No active alerts';

  @override
  String get noAlertsDetail =>
      'Your ponds are being monitored. Alerts will appear here.';

  @override
  String get acknowledge => 'Acknowledge';

  @override
  String get acknowledged => 'Acknowledged';

  @override
  String get alertSuppressed => 'Alert suppressed';

  @override
  String get feedbackCorrect => 'This alert was correct';

  @override
  String get feedbackIncorrect => 'This alert was incorrect';

  @override
  String get alertsLoadError => 'Could not load alerts. Pull to refresh.';

  @override
  String get cropTitle => 'Crop Cycle';

  @override
  String get stocking => 'Stocking';

  @override
  String get milestones => 'Milestones';

  @override
  String get treatments => 'Treatments';

  @override
  String get mortalityTotal => 'Total Mortality';

  @override
  String get cumulativeFeed => 'Cumulative Feed';

  @override
  String get fcr => 'FCR';

  @override
  String get spending => 'Spending';

  @override
  String get projectedHarvest => 'Projected Harvest';

  @override
  String get projectedSize => 'Projected Size';

  @override
  String get costPerKg => 'Cost per kg';

  @override
  String get marketPrice => 'Local Market Price';

  @override
  String get cropDataUnavailable => 'Crop data not available';

  @override
  String get estimatedLabel => 'Estimated';

  @override
  String get unavailableLabel => 'Not available';

  @override
  String get myPondsTitle => 'My Ponds';

  @override
  String get noPonds => 'No ponds found';

  @override
  String get noPondsDetail =>
      'Contact your extension officer to register a pond.';

  @override
  String get pondDetails => 'Pond Details';

  @override
  String get pondArea => 'Area';

  @override
  String get pondDepth => 'Depth';

  @override
  String get pondSpecies => 'Species';

  @override
  String get pondLocation => 'Location';

  @override
  String get pondLastUpdated => 'Last updated';

  @override
  String get profileTitle => 'Profile';

  @override
  String get language => 'Language';

  @override
  String get notifications => 'Notifications';

  @override
  String get notificationsOn => 'Enabled';

  @override
  String get notificationsOff => 'Disabled';

  @override
  String get helpCenter => 'Help Center';

  @override
  String get aboutApp => 'About AquaVerse AI';

  @override
  String get version => 'Version';

  @override
  String get signOutConfirmTitle => 'Sign Out?';

  @override
  String get signOutConfirmMessage =>
      'You will need to log in again with your mobile number.';

  @override
  String get officerPortal => 'Officer Portal';

  @override
  String get officerDashboard => 'Dashboard';

  @override
  String get officerPonds => 'Assigned Ponds';

  @override
  String get officerAlerts => 'Active Alerts';

  @override
  String get officerVisits => 'Field Visits';

  @override
  String get addVisit => 'Log Field Visit';

  @override
  String get visitDate => 'Visit Date';

  @override
  String get visitObservations => 'Observations';

  @override
  String get visitWater => 'Water Observations';

  @override
  String get visitMortality => 'Mortality Observed';

  @override
  String get visitAction => 'Action Taken';

  @override
  String get visitAdvice => 'Advice Given';

  @override
  String get visitFollowUp => 'Follow-up Required';

  @override
  String get visitFollowUpDate => 'Follow-up Date';

  @override
  String get callFarmer => 'Call Farmer';

  @override
  String get farmerInfo => 'Farmer Information';

  @override
  String get visitSaved => 'Visit logged';

  @override
  String get visitQueued => 'Visit saved offline — will sync when connected';

  @override
  String get visitError => 'Could not save visit. Please try again.';

  @override
  String get officerLogout => 'Logout';

  @override
  String get helpTitle => 'Help Center';

  @override
  String get faqTitle => 'Frequently Asked Questions';

  @override
  String get contactTitle => 'Contact Support';

  @override
  String get contactDetail =>
      'For support, call your district extension office.';

  @override
  String get offline => 'Offline';

  @override
  String get offlineMessage => 'You are offline. Data shown may be outdated.';

  @override
  String get syncPending => 'Pending sync';

  @override
  String get syncing => 'Syncing…';

  @override
  String get synced => 'Synced';

  @override
  String get syncFailed => 'Sync failed';

  @override
  String get staleData => 'Data may be outdated';

  @override
  String lastUpdated(String time) {
    return 'Last updated $time';
  }

  @override
  String get loadError => 'Could not load data';

  @override
  String get permissionDenied => 'Permission denied';

  @override
  String get unauthorised => 'You are not authorised to view this.';
}
