// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Tamil (`ta`).
class AppLocalizationsTa extends AppLocalizations {
  AppLocalizationsTa([String locale = 'ta']) : super(locale);

  @override
  String get appTitle => 'AquaVerse AI';

  @override
  String get betterDecisionsBetterHarvest =>
      'சிறந்த முடிவுகள், சிறந்த விளைச்சல்';

  @override
  String get getStarted => 'தொடங்குங்கள்';

  @override
  String get navToday => 'இன்று';

  @override
  String get navLog => 'குளத்து சோதனை';

  @override
  String get navAsk => 'AI-ஐ கேளுங்கள்';

  @override
  String get navAlerts => 'எச்சரிக்கைகள்';

  @override
  String get navCrop => 'பயிர்ப் பருவம்';

  @override
  String get navProfile => 'சுயவிவரம்';

  @override
  String get navSettings => 'அமைப்புகள்';

  @override
  String get signOut => 'வெளியேறு';

  @override
  String get back => 'பின்னே';

  @override
  String get cancel => 'ரத்துசெய்';

  @override
  String get confirm => 'உறுதிப்படுத்து';

  @override
  String get save => 'சேமி';

  @override
  String get retry => 'மீண்டும் முயற்சி';

  @override
  String get loading => 'ஏற்றுகிறது…';

  @override
  String get unknown => 'தெரியவில்லை';

  @override
  String get selectLanguage => 'மொழியைத் தேர்ந்தெடுக்கவும்';

  @override
  String get selectLanguageSubtitle =>
      'உங்கள் விருப்பமான மொழியைத் தேர்வு செய்யுங்கள்';

  @override
  String get continueBtn => 'தொடரவும்';

  @override
  String get phoneNumberLabel => 'கைபேசி எண்';

  @override
  String get phoneNumberHint => '10 இலக்க கைபேசி எண்ணை உள்ளிடவும்';

  @override
  String get roleSelectionTitle => 'நீங்கள் யார்?';

  @override
  String get roleSelectionSubtitle =>
      'தொடங்குவதற்கு உங்கள் பாத்திரத்தைத் தேர்ந்தெடுக்கவும்';

  @override
  String get roleLabel => 'நான் ஒரு…';

  @override
  String get roleFarmer => 'விவசாயி';

  @override
  String get farmerSublabel =>
      'உங்கள் குளத்தை நிர்வகித்து தினசரி பரிந்துரைகளைப் பெறுங்கள்';

  @override
  String get roleOfficer => 'விரிவாக்க அலுவலர்';

  @override
  String get officerSublabel =>
      'பல குளங்களை மேற்பார்வையிட்டு கள ஆய்வுகளைப் பதிவு செய்யுங்கள்';

  @override
  String get selectRolePrompt => 'தொடர ஒரு பாத்திரத்தைத் தேர்ந்தெடுக்கவும்';

  @override
  String get selectedRoleLabel => 'தேர்ந்தெடுக்கப்பட்ட பாத்திரம்';

  @override
  String get changeRole => 'மாற்று';

  @override
  String get phoneTitle => 'உங்கள் கைபேசி எண்ணை உள்ளிடவும்';

  @override
  String get phoneSubtitle =>
      'இந்த எண்ணுக்கு சரிபார்ப்புக் குறியீட்டை அனுப்புவோம்';

  @override
  String get phoneValidationError => 'சரியான 10 இலக்க கைபேசி எண்ணை உள்ளிடவும்';

  @override
  String get sendOtp => 'OTP அனுப்பு';

  @override
  String get otpTitle => 'OTP சரிபார்க்கவும்';

  @override
  String get otpSubtitle =>
      'இந்த எண்ணுக்கு அனுப்பப்பட்ட 6 இலக்கக் குறியீட்டை உள்ளிடவும்';

  @override
  String get otpHint => '6 இலக்க OTP';

  @override
  String get verifyOtp => 'சரிபார்க்க';

  @override
  String get resendOtp => 'OTP மீண்டும் அனுப்பு';

  @override
  String resendIn(int seconds) {
    return '$secondsவி-ல் மீண்டும் அனுப்பு';
  }

  @override
  String get otpExpired => 'OTP காலாவதியானது. புதிய ஒன்றைக் கோருங்கள்.';

  @override
  String get otpInvalid => 'தவறான OTP. மீண்டும் முயற்சிக்கவும்.';

  @override
  String get authError =>
      'அங்கீகரிப்பு தோல்வியுற்றது. மீண்டும் முயற்சிக்கவும்.';

  @override
  String get networkError =>
      'இணைய இணைப்பு இல்லை. இணைப்பை சரிபார்த்து மீண்டும் முயற்சிக்கவும்.';

  @override
  String get sessionExpired => 'உங்கள் அமர்வு காலாவதியானது. மீண்டும் உள்நுழைக.';

  @override
  String get vanakkam => 'வணக்கம்,';

  @override
  String get overallPondRisk => 'ஒட்டுமொத்தக் குளத்து அபாய நிலை';

  @override
  String get lowRisk => 'குறைந்த அபாயம்';

  @override
  String get mediumRisk => 'நடுத்தர அபாயம்';

  @override
  String get highRisk => 'அதிக அபாயம்';

  @override
  String get lowRiskDesc =>
      'குளத்தின் சூழல் பாதுகாப்பாகவும் வளர்ப்பிற்கு உகந்ததாகவும் உள்ளது.';

  @override
  String get mediumRiskDesc =>
      'அளவீடுகளில் சிறிய மாற்றம். இன்று உன்னிப்பாகக் கவனிக்கவும்.';

  @override
  String get highRiskDesc =>
      'கவனம் தேவை. சுற்றுப்புற சூழல் உடனடி குளத்து சோதனை தேவைப்படுகிறது.';

  @override
  String get latestParameters => 'சமீபத்திய நீர் அளவீடுகள்';

  @override
  String get fieldCheck => 'நேரடிச் சோதனை';

  @override
  String get recentEvents => 'சமீபத்திய நிகழ்வுகள்';

  @override
  String get todayFarmAction => 'இன்றைய பண்ணை நடவடிக்கை';

  @override
  String get pondHealthIndex => 'குளத்தின் ஆரோக்கிய நிலை';

  @override
  String get doForecastChart => 'ஆக்சிஜன் கணிப்பு';

  @override
  String get feedRecommendation => 'தீவனப் பரிந்துரை';

  @override
  String get sensorReadings => 'சென்சார் அளவீடுகள்';

  @override
  String get waterQualityGood => 'நீரின் தரம் சிறப்பாக உள்ளது';

  @override
  String get advisories => 'பண்ணை ஆலோசனைகள்';

  @override
  String get noAdvisories => 'இன்று ஆலோசனைகள் இல்லை';

  @override
  String get offlineNotice => 'பதில்களைப் பெற இணைய இணைப்பு தேவை.';

  @override
  String get pullToRefresh => 'புதுப்பிக்க இழுக்கவும்';

  @override
  String get dataUnavailable => 'தரவு கிடைக்கவில்லை';

  @override
  String get blindState => 'மதிப்பீட்டிற்கு போதுமான தரவு இல்லை';

  @override
  String get blindStateDetail =>
      'பரிந்துரைகளை மேம்படுத்த குளம் தரவை பதிவிடுங்கள்.';

  @override
  String get pondCheckTitle => 'குளத்து சோதனை';

  @override
  String get feedGiven => 'கொடுக்கப்பட்ட தீவனம் (கிகி)';

  @override
  String get feedGivenHint => 'கிகி-யில் அளவை உள்ளிடவும்';

  @override
  String get mortality => 'இறப்பு எண்ணிக்கை';

  @override
  String get mortalityHint => 'இறந்த மீன்களின் எண்ணிக்கை';

  @override
  String get feedTray => 'தீவன தட்டு நிலை';

  @override
  String get feedTrayEmpty => 'காலி — மீன்கள் எல்லாம் சாப்பிட்டன';

  @override
  String get feedTraySome => 'சிறிது மிச்சம்';

  @override
  String get feedTrayFull => 'நிறைந்துள்ளது — மீன்கள் சாப்பிடவில்லை';

  @override
  String get waterColor => 'நீரின் தோற்றம்';

  @override
  String get waterColorGood => 'நல்லது (பச்சை/தெளிவு)';

  @override
  String get waterColorMuddy => 'கலங்கல் / பழுப்பு';

  @override
  String get waterColorFoamy => 'நுரை / அசாதாரணம்';

  @override
  String get notes => 'கவனிப்புகள் (விரும்பினால்)';

  @override
  String get notesHint => 'எந்த அசாதாரண கவனிப்புகளும்…';

  @override
  String get addPhoto => 'புகைப்படம் சேர்';

  @override
  String get submitLog => 'சமர்ப்பி';

  @override
  String get logSaved => 'பதிவு சேமிக்கப்பட்டது';

  @override
  String get logQueued => 'ஆஃப்லைன் சேமிப்பு — இணைக்கும்போது ஒத்திசைக்கும்';

  @override
  String get logError => 'பதிவை சேமிக்க முடியவில்லை. மீண்டும் முயற்சிக்கவும்.';

  @override
  String get dissolvedOxygen => 'கரைந்த ஆக்சிஜன் (mg/L)';

  @override
  String get pHLevel => 'pH நிலை';

  @override
  String get temperature => 'நீர் வெப்பநிலை (°C)';

  @override
  String get salinity => 'உவர்ப்புத்தன்மை (ppt)';

  @override
  String get ammonia => 'அமோனியா (mg/L)';

  @override
  String get askTitle => 'அக்வா AI-ஐ கேளுங்கள்';

  @override
  String get tapToAsk => 'கோளத்தைத் தொட்டு உங்கள் கேள்வியைப் பேசுங்கள்';

  @override
  String get listeningText => 'கேட்கிறது… இப்போது பேசுங்கள்';

  @override
  String get thinkingText => 'உங்கள் கேள்வியை செயலாக்குகிறது…';

  @override
  String get responsePrompt => 'புதிய கேள்விக்கு கோளத்தைத் தொடவும்';

  @override
  String get typeQuestion => 'உங்கள் கேள்வியைத் தட்டச்சு செய்க…';

  @override
  String get recentQuestions => 'சமீபத்திய கேள்விகள்';

  @override
  String get aquaAnswer => 'அக்வாவின் பதில்';

  @override
  String get callOfficer => 'விரிவாக்க அலுவலரை அழைக்கவும்';

  @override
  String get askOffline => 'Ask AI-க்கு இணைய இணைப்பு தேவை.';

  @override
  String get audioUnavailable => 'குரல் வழிகாட்டல் இல்லை';

  @override
  String get sampleQuery1 => 'இன்று மீன்களுக்கு எவ்வளவு தீவனம் போட வேண்டும்?';

  @override
  String get sampleQuery2 =>
      'ஆக்சிஜன் 4 mg/L கீழே குறைந்தால் என்ன செய்ய வேண்டும்?';

  @override
  String get sampleQuery3 => 'மழைக்காலத்தில் pH சமநிலை பராமரிப்பது எப்படி?';

  @override
  String get sampleQuery4 => 'அமோனியா அளவை எவ்வாறு கட்டுப்படுத்துவது?';

  @override
  String get alertsTitle => 'எச்சரிக்கைகள்';

  @override
  String get noAlerts => 'செயலில் உள்ள எச்சரிக்கைகள் இல்லை';

  @override
  String get noAlertsDetail =>
      'உங்கள் குளங்கள் கண்காணிக்கப்படுகின்றன. எச்சரிக்கைகள் இங்கே தோன்றும்.';

  @override
  String get acknowledge => 'ஒப்புக்கொள்';

  @override
  String get acknowledged => 'ஒப்புக்கொள்ளப்பட்டது';

  @override
  String get alertSuppressed => 'எச்சரிக்கை அடக்கப்பட்டது';

  @override
  String get feedbackCorrect => 'இந்த எச்சரிக்கை சரியானது';

  @override
  String get feedbackIncorrect => 'இந்த எச்சரிக்கை தவறானது';

  @override
  String get alertsLoadError =>
      'எச்சரிக்கைகளை ஏற்ற முடியவில்லை. புதுப்பிக்க இழுக்கவும்.';

  @override
  String get cropTitle => 'பயிர்ப் பருவம்';

  @override
  String get stocking => 'இருப்பு';

  @override
  String get milestones => 'மைல்கற்கள்';

  @override
  String get treatments => 'சிகிச்சைகள்';

  @override
  String get mortalityTotal => 'மொத்த இறப்பு';

  @override
  String get cumulativeFeed => 'மொத்த தீவனம்';

  @override
  String get fcr => 'FCR';

  @override
  String get spending => 'செலவு';

  @override
  String get projectedHarvest => 'கணிக்கப்பட்ட அறுவடை';

  @override
  String get projectedSize => 'கணிக்கப்பட்ட அளவு';

  @override
  String get costPerKg => 'கிகி மதிப்பு';

  @override
  String get marketPrice => 'உள்ளூர் சந்தை விலை';

  @override
  String get cropDataUnavailable => 'பயிர் தரவு இல்லை';

  @override
  String get estimatedLabel => 'மதிப்பிடப்பட்டது';

  @override
  String get unavailableLabel => 'கிடைக்கவில்லை';

  @override
  String get myPondsTitle => 'என் குளங்கள்';

  @override
  String get noPonds => 'குளங்கள் இல்லை';

  @override
  String get noPondsDetail =>
      'குளத்தை பதிவு செய்ய உங்கள் விரிவாக்க அலுவலரை தொடர்புகொள்ளவும்.';

  @override
  String get pondDetails => 'குளத்தின் விவரங்கள்';

  @override
  String get pondArea => 'பரப்பு';

  @override
  String get pondDepth => 'ஆழம்';

  @override
  String get pondSpecies => 'இனம்';

  @override
  String get pondLocation => 'இடம்';

  @override
  String get pondLastUpdated => 'கடைசியாக புதுப்பிக்கப்பட்டது';

  @override
  String get profileTitle => 'சுயவிவரம்';

  @override
  String get language => 'மொழி';

  @override
  String get notifications => 'அறிவிப்புகள்';

  @override
  String get notificationsOn => 'இயக்கப்பட்டது';

  @override
  String get notificationsOff => 'முடக்கப்பட்டது';

  @override
  String get helpCenter => 'உதவி மையம்';

  @override
  String get aboutApp => 'AquaVerse AI பற்றி';

  @override
  String get version => 'பதிப்பு';

  @override
  String get signOutConfirmTitle => 'வெளியேற?';

  @override
  String get signOutConfirmMessage =>
      'உங்கள் கைபேசி எண்ணுடன் மீண்டும் உள்நுழைய வேண்டும்.';

  @override
  String get officerPortal => 'அலுவலர் தளம்';

  @override
  String get officerDashboard => 'டாஷ்போர்டு';

  @override
  String get officerPonds => 'ஒதுக்கப்பட்ட குளங்கள்';

  @override
  String get officerAlerts => 'செயலில் உள்ள எச்சரிக்கைகள்';

  @override
  String get officerVisits => 'களப் பார்வைகள்';

  @override
  String get addVisit => 'களப் பார்வை பதிவிடு';

  @override
  String get visitDate => 'பார்வை தேதி';

  @override
  String get visitObservations => 'கவனிப்புகள்';

  @override
  String get visitWater => 'நீர் கவனிப்புகள்';

  @override
  String get visitMortality => 'கவனிக்கப்பட்ட இறப்பு';

  @override
  String get visitAction => 'எடுக்கப்பட்ட நடவடிக்கை';

  @override
  String get visitAdvice => 'வழங்கப்பட்ட ஆலோசனை';

  @override
  String get visitFollowUp => 'தொடர்வு தேவை';

  @override
  String get visitFollowUpDate => 'தொடர்வு தேதி';

  @override
  String get callFarmer => 'விவசாயியை அழைக்கவும்';

  @override
  String get farmerInfo => 'விவசாயியின் விவரங்கள்';

  @override
  String get visitSaved => 'பார்வை பதிவிடப்பட்டது';

  @override
  String get visitQueued => 'ஆஃப்லைன் சேமிப்பு — இணைக்கும்போது ஒத்திசைக்கும்';

  @override
  String get visitError =>
      'பார்வையை சேமிக்க முடியவில்லை. மீண்டும் முயற்சிக்கவும்.';

  @override
  String get officerLogout => 'வெளியேறு';

  @override
  String get helpTitle => 'உதவி மையம்';

  @override
  String get faqTitle => 'அடிக்கடி கேட்கப்படும் கேள்விகள்';

  @override
  String get contactTitle => 'ஆதரவை தொடர்பு கொள்ளுங்கள்';

  @override
  String get contactDetail =>
      'ஆதரவிற்கு உங்கள் மாவட்ட விரிவாக்க அலுவலகத்தை அழைக்கவும்.';

  @override
  String get offline => 'ஆஃப்லைன்';

  @override
  String get offlineMessage =>
      'நீங்கள் ஆஃப்லைனில் உள்ளீர்கள். காட்டப்படும் தரவு பழமையாக இருக்கலாம்.';

  @override
  String get syncPending => 'ஒத்திசைவு நிலுவையில்';

  @override
  String get syncing => 'ஒத்திசைக்கிறது…';

  @override
  String get synced => 'ஒத்திசைக்கப்பட்டது';

  @override
  String get syncFailed => 'ஒத்திசைவு தோல்வி';

  @override
  String get staleData => 'தரவு பழமையாக இருக்கலாம்';

  @override
  String lastUpdated(String time) {
    return '$time-ல் புதுப்பிக்கப்பட்டது';
  }

  @override
  String get loadError => 'தரவை ஏற்ற முடியவில்லை';

  @override
  String get permissionDenied => 'அனுமதி மறுக்கப்பட்டது';

  @override
  String get unauthorised => 'இதை பார்க்க உங்களுக்கு அனுமதி இல்லை.';
}
