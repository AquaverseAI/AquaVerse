// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appTitle => 'AquaVerse AI';

  @override
  String get betterDecisionsBetterHarvest => 'बेहतर फैसले, बेहतरीन फसल';

  @override
  String get getStarted => 'शुरू करें';

  @override
  String get navToday => 'आज';

  @override
  String get navLog => 'तालाब जाँच';

  @override
  String get navAsk => 'AI से पूछें';

  @override
  String get navAlerts => 'अलर्ट';

  @override
  String get navCrop => 'फसल';

  @override
  String get navProfile => 'प्रोफ़ाइल';

  @override
  String get navSettings => 'सेटिंग्स';

  @override
  String get signOut => 'साइन आउट';

  @override
  String get back => 'वापस';

  @override
  String get cancel => 'रद्द करें';

  @override
  String get confirm => 'पुष्टि करें';

  @override
  String get save => 'सहेजें';

  @override
  String get retry => 'पुनः प्रयास';

  @override
  String get loading => 'लोड हो रहा है…';

  @override
  String get unknown => 'अज्ञात';

  @override
  String get selectLanguage => 'भाषा चुनें';

  @override
  String get selectLanguageSubtitle => 'अपनी पसंदीदा भाषा चुनें';

  @override
  String get continueBtn => 'जारी रखें';

  @override
  String get phoneNumberLabel => 'मोबाइल नंबर';

  @override
  String get phoneNumberHint => '10 अंकों का मोबाइल नंबर दर्ज करें';

  @override
  String get roleSelectionTitle => 'आप कौन हैं?';

  @override
  String get roleSelectionSubtitle => 'शुरू करने के लिए अपनी भूमिका चुनें';

  @override
  String get roleLabel => 'मैं हूँ…';

  @override
  String get roleFarmer => 'किसान';

  @override
  String get farmerSublabel =>
      'अपने तालाब का प्रबंधन करें और दैनिक सुझाव प्राप्त करें';

  @override
  String get roleOfficer => 'विस्तार अधिकारी';

  @override
  String get officerSublabel =>
      'कई तालाबों की निगरानी करें और क्षेत्र भ्रमण दर्ज करें';

  @override
  String get selectRolePrompt => 'जारी रखने के लिए कृपया एक भूमिका चुनें';

  @override
  String get selectedRoleLabel => 'चयनित भूमिका';

  @override
  String get changeRole => 'बदलें';

  @override
  String get phoneTitle => 'अपना मोबाइल नंबर दर्ज करें';

  @override
  String get phoneSubtitle => 'हम इस नंबर पर एक सत्यापन कोड भेजेंगे';

  @override
  String get phoneValidationError =>
      'कृपया एक वैध 10-अंकीय मोबाइल नंबर दर्ज करें';

  @override
  String get sendOtp => 'OTP भेजें';

  @override
  String get otpTitle => 'OTP सत्यापित करें';

  @override
  String get otpSubtitle => 'इस नंबर पर भेजे गए 6 अंकों का कोड दर्ज करें';

  @override
  String get otpHint => '6 अंकों का OTP';

  @override
  String get verifyOtp => 'सत्यापित करें';

  @override
  String get resendOtp => 'OTP पुनः भेजें';

  @override
  String resendIn(int seconds) {
    return '$secondsसेकंड में पुनः भेजें';
  }

  @override
  String get otpExpired => 'OTP समाप्त हो गया। नया अनुरोध करें।';

  @override
  String get otpInvalid => 'अमान्य OTP। पुनः प्रयास करें।';

  @override
  String get authError => 'प्रमाणीकरण विफल। पुनः प्रयास करें।';

  @override
  String get networkError =>
      'कोई नेटवर्क नहीं। कनेक्शन जाँचें और पुनः प्रयास करें।';

  @override
  String get sessionExpired => 'सत्र समाप्त हो गया। कृपया फिर से लॉग इन करें।';

  @override
  String get vanakkam => 'नमस्कार,';

  @override
  String get overallPondRisk => 'कुल तालाब जोखिम';

  @override
  String get lowRisk => 'कम जोखिम';

  @override
  String get mediumRisk => 'मध्यम जोखिम';

  @override
  String get highRisk => 'अधिक जोखिम';

  @override
  String get lowRiskDesc => 'तालाब का वातावरण स्थिर और फसल के लिए उपयुक्त है।';

  @override
  String get mediumRiskDesc =>
      'मापदंडों में थोड़ा बदलाव है। आज ध्यान से देखें।';

  @override
  String get highRiskDesc => 'ध्यान आवश्यक। तुरंत तालाब जाँच करें।';

  @override
  String get latestParameters => 'नवीनतम जल मापदंड';

  @override
  String get fieldCheck => 'क्षेत्र जाँच';

  @override
  String get recentEvents => 'हाल की घटनाएँ';

  @override
  String get todayFarmAction => 'आज की कृषि गतिविधि';

  @override
  String get pondHealthIndex => 'तालाब स्वास्थ्य सूचकांक';

  @override
  String get doForecastChart => 'DO पूर्वानुमान';

  @override
  String get feedRecommendation => 'चारा सिफारिश';

  @override
  String get sensorReadings => 'सेंसर रीडिंग';

  @override
  String get waterQualityGood => 'जल गुणवत्ता अच्छी है';

  @override
  String get advisories => 'कृषि सलाह';

  @override
  String get noAdvisories => 'आज कोई सलाह नहीं';

  @override
  String get offlineNotice => 'उत्तर पाने के लिए इंटरनेट चाहिए।';

  @override
  String get pullToRefresh => 'ताज़ा करने के लिए खींचें';

  @override
  String get dataUnavailable => 'डेटा उपलब्ध नहीं';

  @override
  String get blindState => 'मूल्यांकन के लिए पर्याप्त डेटा नहीं';

  @override
  String get blindStateDetail =>
      'सिफारिशें बेहतर करने के लिए तालाब डेटा दर्ज करें।';

  @override
  String get pondCheckTitle => 'तालाब जाँच';

  @override
  String get feedGiven => 'दिया गया चारा (kg)';

  @override
  String get feedGivenHint => 'kg में मात्रा दर्ज करें';

  @override
  String get mortality => 'मृत्यु संख्या';

  @override
  String get mortalityHint => 'मरी मछलियों की संख्या';

  @override
  String get feedTray => 'चारा ट्रे स्थिति';

  @override
  String get feedTrayEmpty => 'खाली — मछलियों ने सब खाया';

  @override
  String get feedTraySome => 'कुछ बचा';

  @override
  String get feedTrayFull => 'भरा — मछलियाँ नहीं खा रहीं';

  @override
  String get waterColor => 'जल का दिखावट';

  @override
  String get waterColorGood => 'अच्छा (हरा/साफ)';

  @override
  String get waterColorMuddy => 'गंदला / भूरा';

  @override
  String get waterColorFoamy => 'झागदार / असामान्य';

  @override
  String get notes => 'अवलोकन (वैकल्पिक)';

  @override
  String get notesHint => 'कोई असामान्य अवलोकन…';

  @override
  String get addPhoto => 'फोटो जोड़ें';

  @override
  String get submitLog => 'जमा करें';

  @override
  String get logSaved => 'लॉग सहेजा गया';

  @override
  String get logQueued => 'ऑफलाइन सहेजा — कनेक्ट होने पर सिंक होगा';

  @override
  String get logError => 'लॉग सहेजा नहीं जा सका। पुनः प्रयास करें।';

  @override
  String get dissolvedOxygen => 'घुलित ऑक्सीजन (mg/L)';

  @override
  String get pHLevel => 'pH स्तर';

  @override
  String get temperature => 'जल तापमान (°C)';

  @override
  String get salinity => 'लवणता (ppt)';

  @override
  String get ammonia => 'अमोनिया (mg/L)';

  @override
  String get askTitle => 'Aqua AI से पूछें';

  @override
  String get tapToAsk => 'गोले को छूएँ और सवाल पूछें';

  @override
  String get listeningText => 'सुन रहा है… बोलें';

  @override
  String get thinkingText => 'सवाल प्रोसेस हो रहा है…';

  @override
  String get responsePrompt => 'नए सवाल के लिए गोले को छूएँ';

  @override
  String get typeQuestion => 'अपना सवाल टाइप करें…';

  @override
  String get recentQuestions => 'हाल के सवाल';

  @override
  String get aquaAnswer => 'Aqua का जवाब';

  @override
  String get callOfficer => 'विस्तार अधिकारी को कॉल करें';

  @override
  String get askOffline => 'Ask AI के लिए इंटरनेट चाहिए।';

  @override
  String get audioUnavailable => 'ऑडियो उपलब्ध नहीं';

  @override
  String get sampleQuery1 => 'आज मछलियों को कितना चारा देना चाहिए?';

  @override
  String get sampleQuery2 => 'DO 4 mg/L से नीचे गिरने पर क्या करें?';

  @override
  String get sampleQuery3 => 'बारिश में pH संतुलन कैसे बनाए रखें?';

  @override
  String get sampleQuery4 => 'अमोनिया स्तर कैसे नियंत्रित करें?';

  @override
  String get alertsTitle => 'अलर्ट';

  @override
  String get noAlerts => 'कोई सक्रिय अलर्ट नहीं';

  @override
  String get noAlertsDetail =>
      'आपके तालाब निगरानी में हैं। अलर्ट यहाँ दिखेंगे।';

  @override
  String get acknowledge => 'स्वीकार करें';

  @override
  String get acknowledged => 'स्वीकृत';

  @override
  String get alertSuppressed => 'अलर्ट दबाया गया';

  @override
  String get feedbackCorrect => 'यह अलर्ट सही था';

  @override
  String get feedbackIncorrect => 'यह अलर्ट गलत था';

  @override
  String get alertsLoadError =>
      'अलर्ट लोड नहीं हो सके। ताज़ा करने के लिए खींचें।';

  @override
  String get cropTitle => 'फसल चक्र';

  @override
  String get stocking => 'स्टॉकिंग';

  @override
  String get milestones => 'मील के पत्थर';

  @override
  String get treatments => 'उपचार';

  @override
  String get mortalityTotal => 'कुल मृत्यु';

  @override
  String get cumulativeFeed => 'कुल चारा';

  @override
  String get fcr => 'FCR';

  @override
  String get spending => 'खर्च';

  @override
  String get projectedHarvest => 'अनुमानित फसल';

  @override
  String get projectedSize => 'अनुमानित आकार';

  @override
  String get costPerKg => 'प्रति kg लागत';

  @override
  String get marketPrice => 'स्थानीय बाजार मूल्य';

  @override
  String get cropDataUnavailable => 'फसल डेटा उपलब्ध नहीं';

  @override
  String get estimatedLabel => 'अनुमानित';

  @override
  String get unavailableLabel => 'उपलब्ध नहीं';

  @override
  String get myPondsTitle => 'मेरे तालाब';

  @override
  String get noPonds => 'कोई तालाब नहीं मिला';

  @override
  String get noPondsDetail =>
      'तालाब पंजीकृत करने के लिए विस्तार अधिकारी से संपर्क करें।';

  @override
  String get pondDetails => 'तालाब विवरण';

  @override
  String get pondArea => 'क्षेत्रफल';

  @override
  String get pondDepth => 'गहराई';

  @override
  String get pondSpecies => 'प्रजाति';

  @override
  String get pondLocation => 'स्थान';

  @override
  String get pondLastUpdated => 'अंतिम अपडेट';

  @override
  String get profileTitle => 'प्रोफ़ाइल';

  @override
  String get language => 'भाषा';

  @override
  String get notifications => 'सूचनाएँ';

  @override
  String get notificationsOn => 'सक्षम';

  @override
  String get notificationsOff => 'अक्षम';

  @override
  String get helpCenter => 'सहायता केंद्र';

  @override
  String get aboutApp => 'AquaVerse AI के बारे में';

  @override
  String get version => 'संस्करण';

  @override
  String get signOutConfirmTitle => 'साइन आउट करें?';

  @override
  String get signOutConfirmMessage =>
      'आपको अपने मोबाइल नंबर से फिर से लॉग इन करना होगा।';

  @override
  String get officerPortal => 'अधिकारी पोर्टल';

  @override
  String get officerDashboard => 'डैशबोर्ड';

  @override
  String get officerPonds => 'आवंटित तालाब';

  @override
  String get officerAlerts => 'सक्रिय अलर्ट';

  @override
  String get officerVisits => 'क्षेत्र भ्रमण';

  @override
  String get addVisit => 'क्षेत्र भ्रमण दर्ज करें';

  @override
  String get visitDate => 'भ्रमण तिथि';

  @override
  String get visitObservations => 'अवलोकन';

  @override
  String get visitWater => 'जल अवलोकन';

  @override
  String get visitMortality => 'देखी गई मृत्यु';

  @override
  String get visitAction => 'की गई कार्रवाई';

  @override
  String get visitAdvice => 'दी गई सलाह';

  @override
  String get visitFollowUp => 'अनुवर्ती आवश्यक';

  @override
  String get visitFollowUpDate => 'अनुवर्ती तिथि';

  @override
  String get callFarmer => 'किसान को कॉल करें';

  @override
  String get farmerInfo => 'किसान जानकारी';

  @override
  String get visitSaved => 'भ्रमण दर्ज किया गया';

  @override
  String get visitQueued => 'ऑफलाइन सहेजा — कनेक्ट होने पर सिंक होगा';

  @override
  String get visitError => 'भ्रमण सहेजा नहीं जा सका। पुनः प्रयास करें।';

  @override
  String get officerLogout => 'लॉगआउट';

  @override
  String get helpTitle => 'सहायता केंद्र';

  @override
  String get faqTitle => 'अक्सर पूछे जाने वाले सवाल';

  @override
  String get contactTitle => 'सहायता से संपर्क करें';

  @override
  String get contactDetail =>
      'सहायता के लिए अपने जिले के विस्तार कार्यालय को कॉल करें।';

  @override
  String get offline => 'ऑफलाइन';

  @override
  String get offlineMessage =>
      'आप ऑफलाइन हैं। दिखाया गया डेटा पुराना हो सकता है।';

  @override
  String get syncPending => 'सिंक प्रतीक्षित';

  @override
  String get syncing => 'सिंक हो रहा है…';

  @override
  String get synced => 'सिंक हो गया';

  @override
  String get syncFailed => 'सिंक विफल';

  @override
  String get staleData => 'डेटा पुराना हो सकता है';

  @override
  String lastUpdated(String time) {
    return '$time को अपडेट किया गया';
  }

  @override
  String get loadError => 'डेटा लोड नहीं हो सका';

  @override
  String get permissionDenied => 'अनुमति अस्वीकृत';

  @override
  String get unauthorised => 'आपको इसे देखने की अनुमति नहीं है।';
}
