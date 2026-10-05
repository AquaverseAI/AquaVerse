// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Telugu (`te`).
class AppLocalizationsTe extends AppLocalizations {
  AppLocalizationsTe([String locale = 'te']) : super(locale);

  @override
  String get appTitle => 'AquaVerse AI';

  @override
  String get betterDecisionsBetterHarvest => 'మంచి నిర్ణయాలు, మెరుగైన దిగుబడి';

  @override
  String get getStarted => 'ప్రారంభించండి';

  @override
  String get navToday => 'నేడు';

  @override
  String get navLog => 'చెరువు తనిఖీ';

  @override
  String get navAsk => 'AI అడగండి';

  @override
  String get navAlerts => 'హెచ్చరికలు';

  @override
  String get navCrop => 'పంట';

  @override
  String get navProfile => 'ప్రొఫైల్';

  @override
  String get navSettings => 'సెట్టింగ్స్';

  @override
  String get signOut => 'సైన్ అవుట్';

  @override
  String get back => 'వెనుకకు';

  @override
  String get cancel => 'రద్దు';

  @override
  String get confirm => 'నిర్ధారించండి';

  @override
  String get save => 'సేవ్ చేయండి';

  @override
  String get retry => 'మళ్ళీ ప్రయత్నించండి';

  @override
  String get loading => 'లోడవుతోంది…';

  @override
  String get unknown => 'తెలియదు';

  @override
  String get selectLanguage => 'భాష ఎంచుకోండి';

  @override
  String get selectLanguageSubtitle => 'మీకు ఇష్టమైన భాషను ఎంచుకోండి';

  @override
  String get continueBtn => 'కొనసాగించు';

  @override
  String get phoneNumberLabel => 'మొబైల్ నంబర్';

  @override
  String get phoneNumberHint => '10 అంకెల మొబైల్ నంబర్ నమోదు చేయండి';

  @override
  String get roleSelectionTitle => 'మీరు ఎవరు?';

  @override
  String get roleSelectionSubtitle => 'ప్రారంభించడానికి మీ పాత్రను ఎంచుకోండి';

  @override
  String get roleLabel => 'నేను…';

  @override
  String get roleFarmer => 'రైతు';

  @override
  String get farmerSublabel =>
      'మీ చెరువును నిర్వహించండి మరియు రోజువారీ సిఫార్సులను పొందండి';

  @override
  String get roleOfficer => 'విస్తరణ అధికారి';

  @override
  String get officerSublabel =>
      'బహుళ చెరువులను పర్యవేక్షించండి మరియు క్షేత్ర పర్యటనలను నమోదు చేయండి';

  @override
  String get selectRolePrompt => 'కొనసాగించడానికి దయచేసి ఒక పాత్రను ఎంచుకోండి';

  @override
  String get selectedRoleLabel => 'ఎంచుకున్న పాత్ర';

  @override
  String get changeRole => 'మార్చు';

  @override
  String get phoneTitle => 'మీ మొబైల్ నంబర్ నమోదు చేయండి';

  @override
  String get phoneSubtitle => 'మేము ఈ నంబర్‌కు ధృవీకరణ కోడ్‌ను పంపుతాము';

  @override
  String get phoneValidationError =>
      'దయచేసి సరైన 10 అంకెల మొబైల్ నంబర్‌ను నమోదు చేయండి';

  @override
  String get sendOtp => 'OTP పంపండి';

  @override
  String get otpTitle => 'OTP ధృవీకరించండి';

  @override
  String get otpSubtitle => 'ఈ నంబర్‌కు పంపిన 6 అంకెల కోడ్ నమోదు చేయండి';

  @override
  String get otpHint => '6 అంకెల OTP';

  @override
  String get verifyOtp => 'ధృవీకరించండి';

  @override
  String get resendOtp => 'OTP మళ్ళీ పంపండి';

  @override
  String resendIn(int seconds) {
    return '$secondsసెకన్లలో మళ్ళీ పంపండి';
  }

  @override
  String get otpExpired => 'OTP గడువు తీరింది. కొత్తది అభ్యర్థించండి.';

  @override
  String get otpInvalid => 'చెల్లని OTP. మళ్ళీ ప్రయత్నించండి.';

  @override
  String get authError => 'ప్రమాణీకరణ విఫలమైంది. మళ్ళీ ప్రయత్నించండి.';

  @override
  String get networkError =>
      'నెట్‌వర్క్ కనెక్షన్ లేదు. కనెక్షన్ తనిఖీ చేసి మళ్ళీ ప్రయత్నించండి.';

  @override
  String get sessionExpired => 'మీ సెషన్ ముగిసింది. మళ్ళీ లాగిన్ చేయండి.';

  @override
  String get vanakkam => 'నమస్కారం,';

  @override
  String get overallPondRisk => 'మొత్తం చెరువు ప్రమాద స్థాయి';

  @override
  String get lowRisk => 'తక్కువ ప్రమాదం';

  @override
  String get mediumRisk => 'మధ్యస్థ ప్రమాదం';

  @override
  String get highRisk => 'అధిక ప్రమాదం';

  @override
  String get lowRiskDesc =>
      'చెరువు వాతావరణం స్థిరంగా మరియు పంటకు అనుకూలంగా ఉంది.';

  @override
  String get mediumRiskDesc =>
      'పారామీటర్లలో కొంత మార్పు ఉంది. నేడు జాగ్రత్తగా గమనించండి.';

  @override
  String get highRiskDesc => 'శ్రద్ధ అవసరం. వెంటనే చెరువు తనిఖీ చేయండి.';

  @override
  String get latestParameters => 'తాజా జల పారామీటర్లు';

  @override
  String get fieldCheck => 'క్షేత్ర తనిఖీ';

  @override
  String get recentEvents => 'ఇటీవలి సంఘటనలు';

  @override
  String get todayFarmAction => 'నేటి వ్యవసాయ కార్యాచరణ';

  @override
  String get pondHealthIndex => 'చెరువు ఆరోగ్య సూచిక';

  @override
  String get doForecastChart => 'DO అంచనా';

  @override
  String get feedRecommendation => 'ఆహారం సిఫారసు';

  @override
  String get sensorReadings => 'సెన్సార్ రీడింగ్‌లు';

  @override
  String get waterQualityGood => 'జల నాణ్యత అద్భుతంగా ఉంది';

  @override
  String get advisories => 'వ్యవసాయ సలహాలు';

  @override
  String get noAdvisories => 'నేడు సలహాలు లేవు';

  @override
  String get offlineNotice => 'సమాధానాలు పొందడానికి ఇంటర్నెట్ కనెక్షన్ అవసరం.';

  @override
  String get pullToRefresh => 'రిఫ్రెష్ చేయడానికి లాగండి';

  @override
  String get dataUnavailable => 'డేటా అందుబాటులో లేదు';

  @override
  String get blindState => 'మూల్యాంకనానికి తగిన డేటా లేదు';

  @override
  String get blindStateDetail =>
      'సిఫారసులు మెరుగుపరచడానికి చెరువు డేటా నమోదు చేయండి.';

  @override
  String get pondCheckTitle => 'చెరువు తనిఖీ';

  @override
  String get feedGiven => 'ఇచ్చిన ఆహారం (కిలో)';

  @override
  String get feedGivenHint => 'కిలోలలో మొత్తం నమోదు చేయండి';

  @override
  String get mortality => 'మరణాల సంఖ్య';

  @override
  String get mortalityHint => 'చనిపోయిన చేపల సంఖ్య';

  @override
  String get feedTray => 'ఆహారం ట్రే స్థితి';

  @override
  String get feedTrayEmpty => 'ఖాళీ — చేపలు అన్నీ తిన్నాయి';

  @override
  String get feedTraySome => 'కొంచెం మిగిలింది';

  @override
  String get feedTrayFull => 'నిండి ఉంది — చేపలు తినడం లేదు';

  @override
  String get waterColor => 'నీటి రూపం';

  @override
  String get waterColorGood => 'మంచిది (పచ్చ/స్వచ్ఛమైన)';

  @override
  String get waterColorMuddy => 'మేలిమి / గోధుమ రంగు';

  @override
  String get waterColorFoamy => 'నురుగు / అసాధారణం';

  @override
  String get notes => 'పరిశీలనలు (ఐచ్ఛికం)';

  @override
  String get notesHint => 'ఏవైనా అసాధారణ పరిశీలనలు…';

  @override
  String get addPhoto => 'ఫోటో జోడించండి';

  @override
  String get submitLog => 'సమర్పించండి';

  @override
  String get logSaved => 'లాగ్ సేవ్ అయింది';

  @override
  String get logQueued =>
      'ఆఫ్‌లైన్‌లో సేవ్ అయింది — కనెక్ట్ అయినప్పుడు సమకాలీకరించబడుతుంది';

  @override
  String get logError => 'లాగ్ సేవ్ చేయలేకపోయాం. మళ్ళీ ప్రయత్నించండి.';

  @override
  String get dissolvedOxygen => 'కరిగిన ఆక్సిజన్ (mg/L)';

  @override
  String get pHLevel => 'pH స్థాయి';

  @override
  String get temperature => 'నీటి ఉష్ణోగ్రత (°C)';

  @override
  String get salinity => 'లవణీయత (ppt)';

  @override
  String get ammonia => 'అమోనియా (mg/L)';

  @override
  String get askTitle => 'Aqua AI అడగండి';

  @override
  String get tapToAsk => 'గోళాన్ని తాకి మీ ప్రశ్న అడగండి';

  @override
  String get listeningText => 'వింటోంది… ఇప్పుడు మాట్లాడండి';

  @override
  String get thinkingText => 'మీ ప్రశ్న ప్రాసెస్ అవుతోంది…';

  @override
  String get responsePrompt => 'కొత్త ప్రశ్నకు గోళాన్ని తాకండి';

  @override
  String get typeQuestion => 'మీ ప్రశ్న టైప్ చేయండి…';

  @override
  String get recentQuestions => 'ఇటీవలి ప్రశ్నలు';

  @override
  String get aquaAnswer => 'Aqua జవాబు';

  @override
  String get callOfficer => 'విస్తరణ అధికారిని కాల్ చేయండి';

  @override
  String get askOffline => 'Ask AI కు ఇంటర్నెట్ కనెక్షన్ అవసరం.';

  @override
  String get audioUnavailable => 'ఆడియో అందుబాటులో లేదు';

  @override
  String get sampleQuery1 => 'నేడు చేపలకు ఎంత ఆహారం ఇవ్వాలి?';

  @override
  String get sampleQuery2 => 'DO 4 mg/L కంటే తగ్గితే ఏమి చేయాలి?';

  @override
  String get sampleQuery3 => 'వర్షాకాలంలో pH సమతుల్యత ఎలా నిర్వహించాలి?';

  @override
  String get sampleQuery4 => 'అమోనియా స్థాయిని ఎలా నియంత్రించాలి?';

  @override
  String get alertsTitle => 'హెచ్చరికలు';

  @override
  String get noAlerts => 'క్రియాశీల హెచ్చరికలు లేవు';

  @override
  String get noAlertsDetail =>
      'మీ చెరువులు పర్యవేక్షించబడుతున్నాయి. హెచ్చరికలు ఇక్కడ కనిపిస్తాయి.';

  @override
  String get acknowledge => 'గుర్తించండి';

  @override
  String get acknowledged => 'గుర్తించబడింది';

  @override
  String get alertSuppressed => 'హెచ్చరిక అణచివేయబడింది';

  @override
  String get feedbackCorrect => 'ఈ హెచ్చరిక సరైనది';

  @override
  String get feedbackIncorrect => 'ఈ హెచ్చరిక తప్పు';

  @override
  String get alertsLoadError => 'హెచ్చరికలు లోడ్ కాలేదు. రిఫ్రెష్ చేయండి.';

  @override
  String get cropTitle => 'పంట చక్రం';

  @override
  String get stocking => 'నిల్వ';

  @override
  String get milestones => 'మైలురాళ్ళు';

  @override
  String get treatments => 'చికిత్సలు';

  @override
  String get mortalityTotal => 'మొత్తం మరణాలు';

  @override
  String get cumulativeFeed => 'మొత్తం ఆహారం';

  @override
  String get fcr => 'FCR';

  @override
  String get spending => 'వ్యయం';

  @override
  String get projectedHarvest => 'అంచనా పంట';

  @override
  String get projectedSize => 'అంచనా పరిమాణం';

  @override
  String get costPerKg => 'కిలో వ్యయం';

  @override
  String get marketPrice => 'స్థానిక మార్కెట్ ధర';

  @override
  String get cropDataUnavailable => 'పంట డేటా అందుబాటులో లేదు';

  @override
  String get estimatedLabel => 'అంచనా';

  @override
  String get unavailableLabel => 'అందుబాటులో లేదు';

  @override
  String get myPondsTitle => 'నా చెరువులు';

  @override
  String get noPonds => 'చెరువులు కనుగొనబడలేదు';

  @override
  String get noPondsDetail =>
      'చెరువు నమోదు చేయడానికి మీ విస్తరణ అధికారిని సంప్రదించండి.';

  @override
  String get pondDetails => 'చెరువు వివరాలు';

  @override
  String get pondArea => 'విస్తీర్ణం';

  @override
  String get pondDepth => 'లోతు';

  @override
  String get pondSpecies => 'జాతి';

  @override
  String get pondLocation => 'స్థానం';

  @override
  String get pondLastUpdated => 'చివరిగా నవీకరించబడింది';

  @override
  String get profileTitle => 'ప్రొఫైల్';

  @override
  String get language => 'భాష';

  @override
  String get notifications => 'నోటిఫికేషన్లు';

  @override
  String get notificationsOn => 'ప్రారంభించబడింది';

  @override
  String get notificationsOff => 'నిలిపివేయబడింది';

  @override
  String get helpCenter => 'సహాయ కేంద్రం';

  @override
  String get aboutApp => 'AquaVerse AI గురించి';

  @override
  String get version => 'వెర్షన్';

  @override
  String get signOutConfirmTitle => 'సైన్ అవుట్?';

  @override
  String get signOutConfirmMessage =>
      'మీరు మీ మొబైల్ నంబర్‌తో మళ్ళీ లాగిన్ చేయాలి.';

  @override
  String get officerPortal => 'అధికారి పోర్టల్';

  @override
  String get officerDashboard => 'డాష్‌బోర్డ్';

  @override
  String get officerPonds => 'కేటాయించిన చెరువులు';

  @override
  String get officerAlerts => 'క్రియాశీల హెచ్చరికలు';

  @override
  String get officerVisits => 'క్షేత్ర సందర్శనలు';

  @override
  String get addVisit => 'క్షేత్ర సందర్శన నమోదు చేయండి';

  @override
  String get visitDate => 'సందర్శన తేదీ';

  @override
  String get visitObservations => 'పరిశీలనలు';

  @override
  String get visitWater => 'నీటి పరిశీలనలు';

  @override
  String get visitMortality => 'గమనించిన మరణాలు';

  @override
  String get visitAction => 'తీసుకున్న చర్య';

  @override
  String get visitAdvice => 'ఇచ్చిన సలహా';

  @override
  String get visitFollowUp => 'ఫాలో-అప్ అవసరం';

  @override
  String get visitFollowUpDate => 'ఫాలో-అప్ తేదీ';

  @override
  String get callFarmer => 'రైతుకు కాల్ చేయండి';

  @override
  String get farmerInfo => 'రైతు సమాచారం';

  @override
  String get visitSaved => 'సందర్శన నమోదు అయింది';

  @override
  String get visitQueued =>
      'ఆఫ్‌లైన్‌లో సేవ్ అయింది — కనెక్ట్ అయినప్పుడు సమకాలీకరించబడుతుంది';

  @override
  String get visitError => 'సందర్శన సేవ్ చేయలేకపోయాం. మళ్ళీ ప్రయత్నించండి.';

  @override
  String get officerLogout => 'లాగ్‌అవుట్';

  @override
  String get helpTitle => 'సహాయ కేంద్రం';

  @override
  String get faqTitle => 'తరచుగా అడిగే ప్రశ్నలు';

  @override
  String get contactTitle => 'మద్దతును సంప్రదించండి';

  @override
  String get contactDetail =>
      'మద్దతు కోసం మీ జిల్లా విస్తరణ కార్యాలయాన్ని కాల్ చేయండి.';

  @override
  String get offline => 'ఆఫ్‌లైన్';

  @override
  String get offlineMessage =>
      'మీరు ఆఫ్‌లైన్‌లో ఉన్నారు. చూపిన డేటా పాతది కావచ్చు.';

  @override
  String get syncPending => 'సమకాలీకరణ పెండింగ్';

  @override
  String get syncing => 'సమకాలీకరిస్తోంది…';

  @override
  String get synced => 'సమకాలీకరించబడింది';

  @override
  String get syncFailed => 'సమకాలీకరణ విఫలమైంది';

  @override
  String get staleData => 'డేటా పాతది కావచ్చు';

  @override
  String lastUpdated(String time) {
    return '$timeకు నవీకరించబడింది';
  }

  @override
  String get loadError => 'డేటా లోడ్ కాలేదు';

  @override
  String get permissionDenied => 'అనుమతి తిరస్కరించబడింది';

  @override
  String get unauthorised => 'మీకు దీన్ని చూసే అనుమతి లేదు.';
}
