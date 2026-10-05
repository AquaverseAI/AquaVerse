import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_ta.dart';
import 'app_localizations_te.dart';

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
    Locale('en'),
    Locale('hi'),
    Locale('ta'),
    Locale('te'),
  ];

  /// The title of the application
  ///
  /// In ta, this message translates to:
  /// **'AquaVerse AI'**
  String get appTitle;

  /// App tagline displayed on splash screen
  ///
  /// In ta, this message translates to:
  /// **'சிறந்த முடிவுகள், சிறந்த விளைச்சல்'**
  String get betterDecisionsBetterHarvest;

  /// No description provided for @getStarted.
  ///
  /// In ta, this message translates to:
  /// **'தொடங்குங்கள்'**
  String get getStarted;

  /// No description provided for @navToday.
  ///
  /// In ta, this message translates to:
  /// **'இன்று'**
  String get navToday;

  /// No description provided for @navLog.
  ///
  /// In ta, this message translates to:
  /// **'குளத்து சோதனை'**
  String get navLog;

  /// No description provided for @navAsk.
  ///
  /// In ta, this message translates to:
  /// **'AI-ஐ கேளுங்கள்'**
  String get navAsk;

  /// No description provided for @navAlerts.
  ///
  /// In ta, this message translates to:
  /// **'எச்சரிக்கைகள்'**
  String get navAlerts;

  /// No description provided for @navCrop.
  ///
  /// In ta, this message translates to:
  /// **'பயிர்ப் பருவம்'**
  String get navCrop;

  /// No description provided for @navProfile.
  ///
  /// In ta, this message translates to:
  /// **'சுயவிவரம்'**
  String get navProfile;

  /// No description provided for @navSettings.
  ///
  /// In ta, this message translates to:
  /// **'அமைப்புகள்'**
  String get navSettings;

  /// No description provided for @signOut.
  ///
  /// In ta, this message translates to:
  /// **'வெளியேறு'**
  String get signOut;

  /// No description provided for @back.
  ///
  /// In ta, this message translates to:
  /// **'பின்னே'**
  String get back;

  /// No description provided for @cancel.
  ///
  /// In ta, this message translates to:
  /// **'ரத்துசெய்'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In ta, this message translates to:
  /// **'உறுதிப்படுத்து'**
  String get confirm;

  /// No description provided for @save.
  ///
  /// In ta, this message translates to:
  /// **'சேமி'**
  String get save;

  /// No description provided for @retry.
  ///
  /// In ta, this message translates to:
  /// **'மீண்டும் முயற்சி'**
  String get retry;

  /// No description provided for @loading.
  ///
  /// In ta, this message translates to:
  /// **'ஏற்றுகிறது…'**
  String get loading;

  /// No description provided for @unknown.
  ///
  /// In ta, this message translates to:
  /// **'தெரியவில்லை'**
  String get unknown;

  /// No description provided for @selectLanguage.
  ///
  /// In ta, this message translates to:
  /// **'மொழியைத் தேர்ந்தெடுக்கவும்'**
  String get selectLanguage;

  /// No description provided for @selectLanguageSubtitle.
  ///
  /// In ta, this message translates to:
  /// **'உங்கள் விருப்பமான மொழியைத் தேர்வு செய்யுங்கள்'**
  String get selectLanguageSubtitle;

  /// No description provided for @continueBtn.
  ///
  /// In ta, this message translates to:
  /// **'தொடரவும்'**
  String get continueBtn;

  /// No description provided for @phoneNumberLabel.
  ///
  /// In ta, this message translates to:
  /// **'கைபேசி எண்'**
  String get phoneNumberLabel;

  /// No description provided for @phoneNumberHint.
  ///
  /// In ta, this message translates to:
  /// **'10 இலக்க கைபேசி எண்ணை உள்ளிடவும்'**
  String get phoneNumberHint;

  /// No description provided for @roleSelectionTitle.
  ///
  /// In ta, this message translates to:
  /// **'நீங்கள் யார்?'**
  String get roleSelectionTitle;

  /// No description provided for @roleSelectionSubtitle.
  ///
  /// In ta, this message translates to:
  /// **'தொடங்குவதற்கு உங்கள் பாத்திரத்தைத் தேர்ந்தெடுக்கவும்'**
  String get roleSelectionSubtitle;

  /// No description provided for @roleLabel.
  ///
  /// In ta, this message translates to:
  /// **'நான் ஒரு…'**
  String get roleLabel;

  /// No description provided for @roleFarmer.
  ///
  /// In ta, this message translates to:
  /// **'விவசாயி'**
  String get roleFarmer;

  /// No description provided for @farmerSublabel.
  ///
  /// In ta, this message translates to:
  /// **'உங்கள் குளத்தை நிர்வகித்து தினசரி பரிந்துரைகளைப் பெறுங்கள்'**
  String get farmerSublabel;

  /// No description provided for @roleOfficer.
  ///
  /// In ta, this message translates to:
  /// **'விரிவாக்க அலுவலர்'**
  String get roleOfficer;

  /// No description provided for @officerSublabel.
  ///
  /// In ta, this message translates to:
  /// **'பல குளங்களை மேற்பார்வையிட்டு கள ஆய்வுகளைப் பதிவு செய்யுங்கள்'**
  String get officerSublabel;

  /// No description provided for @selectRolePrompt.
  ///
  /// In ta, this message translates to:
  /// **'தொடர ஒரு பாத்திரத்தைத் தேர்ந்தெடுக்கவும்'**
  String get selectRolePrompt;

  /// No description provided for @selectedRoleLabel.
  ///
  /// In ta, this message translates to:
  /// **'தேர்ந்தெடுக்கப்பட்ட பாத்திரம்'**
  String get selectedRoleLabel;

  /// No description provided for @changeRole.
  ///
  /// In ta, this message translates to:
  /// **'மாற்று'**
  String get changeRole;

  /// No description provided for @phoneTitle.
  ///
  /// In ta, this message translates to:
  /// **'உங்கள் கைபேசி எண்ணை உள்ளிடவும்'**
  String get phoneTitle;

  /// No description provided for @phoneSubtitle.
  ///
  /// In ta, this message translates to:
  /// **'இந்த எண்ணுக்கு சரிபார்ப்புக் குறியீட்டை அனுப்புவோம்'**
  String get phoneSubtitle;

  /// No description provided for @phoneValidationError.
  ///
  /// In ta, this message translates to:
  /// **'சரியான 10 இலக்க கைபேசி எண்ணை உள்ளிடவும்'**
  String get phoneValidationError;

  /// No description provided for @sendOtp.
  ///
  /// In ta, this message translates to:
  /// **'OTP அனுப்பு'**
  String get sendOtp;

  /// No description provided for @otpTitle.
  ///
  /// In ta, this message translates to:
  /// **'OTP சரிபார்க்கவும்'**
  String get otpTitle;

  /// No description provided for @otpSubtitle.
  ///
  /// In ta, this message translates to:
  /// **'இந்த எண்ணுக்கு அனுப்பப்பட்ட 6 இலக்கக் குறியீட்டை உள்ளிடவும்'**
  String get otpSubtitle;

  /// No description provided for @otpHint.
  ///
  /// In ta, this message translates to:
  /// **'6 இலக்க OTP'**
  String get otpHint;

  /// No description provided for @verifyOtp.
  ///
  /// In ta, this message translates to:
  /// **'சரிபார்க்க'**
  String get verifyOtp;

  /// No description provided for @resendOtp.
  ///
  /// In ta, this message translates to:
  /// **'OTP மீண்டும் அனுப்பு'**
  String get resendOtp;

  /// No description provided for @resendIn.
  ///
  /// In ta, this message translates to:
  /// **'{seconds}வி-ல் மீண்டும் அனுப்பு'**
  String resendIn(int seconds);

  /// No description provided for @otpExpired.
  ///
  /// In ta, this message translates to:
  /// **'OTP காலாவதியானது. புதிய ஒன்றைக் கோருங்கள்.'**
  String get otpExpired;

  /// No description provided for @otpInvalid.
  ///
  /// In ta, this message translates to:
  /// **'தவறான OTP. மீண்டும் முயற்சிக்கவும்.'**
  String get otpInvalid;

  /// No description provided for @authError.
  ///
  /// In ta, this message translates to:
  /// **'அங்கீகரிப்பு தோல்வியுற்றது. மீண்டும் முயற்சிக்கவும்.'**
  String get authError;

  /// No description provided for @networkError.
  ///
  /// In ta, this message translates to:
  /// **'இணைய இணைப்பு இல்லை. இணைப்பை சரிபார்த்து மீண்டும் முயற்சிக்கவும்.'**
  String get networkError;

  /// No description provided for @sessionExpired.
  ///
  /// In ta, this message translates to:
  /// **'உங்கள் அமர்வு காலாவதியானது. மீண்டும் உள்நுழைக.'**
  String get sessionExpired;

  /// No description provided for @vanakkam.
  ///
  /// In ta, this message translates to:
  /// **'வணக்கம்,'**
  String get vanakkam;

  /// No description provided for @overallPondRisk.
  ///
  /// In ta, this message translates to:
  /// **'ஒட்டுமொத்தக் குளத்து அபாய நிலை'**
  String get overallPondRisk;

  /// No description provided for @lowRisk.
  ///
  /// In ta, this message translates to:
  /// **'குறைந்த அபாயம்'**
  String get lowRisk;

  /// No description provided for @mediumRisk.
  ///
  /// In ta, this message translates to:
  /// **'நடுத்தர அபாயம்'**
  String get mediumRisk;

  /// No description provided for @highRisk.
  ///
  /// In ta, this message translates to:
  /// **'அதிக அபாயம்'**
  String get highRisk;

  /// No description provided for @lowRiskDesc.
  ///
  /// In ta, this message translates to:
  /// **'குளத்தின் சூழல் பாதுகாப்பாகவும் வளர்ப்பிற்கு உகந்ததாகவும் உள்ளது.'**
  String get lowRiskDesc;

  /// No description provided for @mediumRiskDesc.
  ///
  /// In ta, this message translates to:
  /// **'அளவீடுகளில் சிறிய மாற்றம். இன்று உன்னிப்பாகக் கவனிக்கவும்.'**
  String get mediumRiskDesc;

  /// No description provided for @highRiskDesc.
  ///
  /// In ta, this message translates to:
  /// **'கவனம் தேவை. சுற்றுப்புற சூழல் உடனடி குளத்து சோதனை தேவைப்படுகிறது.'**
  String get highRiskDesc;

  /// No description provided for @latestParameters.
  ///
  /// In ta, this message translates to:
  /// **'சமீபத்திய நீர் அளவீடுகள்'**
  String get latestParameters;

  /// No description provided for @fieldCheck.
  ///
  /// In ta, this message translates to:
  /// **'நேரடிச் சோதனை'**
  String get fieldCheck;

  /// No description provided for @recentEvents.
  ///
  /// In ta, this message translates to:
  /// **'சமீபத்திய நிகழ்வுகள்'**
  String get recentEvents;

  /// No description provided for @todayFarmAction.
  ///
  /// In ta, this message translates to:
  /// **'இன்றைய பண்ணை நடவடிக்கை'**
  String get todayFarmAction;

  /// No description provided for @pondHealthIndex.
  ///
  /// In ta, this message translates to:
  /// **'குளத்தின் ஆரோக்கிய நிலை'**
  String get pondHealthIndex;

  /// No description provided for @doForecastChart.
  ///
  /// In ta, this message translates to:
  /// **'ஆக்சிஜன் கணிப்பு'**
  String get doForecastChart;

  /// No description provided for @feedRecommendation.
  ///
  /// In ta, this message translates to:
  /// **'தீவனப் பரிந்துரை'**
  String get feedRecommendation;

  /// No description provided for @sensorReadings.
  ///
  /// In ta, this message translates to:
  /// **'சென்சார் அளவீடுகள்'**
  String get sensorReadings;

  /// No description provided for @waterQualityGood.
  ///
  /// In ta, this message translates to:
  /// **'நீரின் தரம் சிறப்பாக உள்ளது'**
  String get waterQualityGood;

  /// No description provided for @advisories.
  ///
  /// In ta, this message translates to:
  /// **'பண்ணை ஆலோசனைகள்'**
  String get advisories;

  /// No description provided for @noAdvisories.
  ///
  /// In ta, this message translates to:
  /// **'இன்று ஆலோசனைகள் இல்லை'**
  String get noAdvisories;

  /// No description provided for @offlineNotice.
  ///
  /// In ta, this message translates to:
  /// **'பதில்களைப் பெற இணைய இணைப்பு தேவை.'**
  String get offlineNotice;

  /// No description provided for @pullToRefresh.
  ///
  /// In ta, this message translates to:
  /// **'புதுப்பிக்க இழுக்கவும்'**
  String get pullToRefresh;

  /// No description provided for @dataUnavailable.
  ///
  /// In ta, this message translates to:
  /// **'தரவு கிடைக்கவில்லை'**
  String get dataUnavailable;

  /// No description provided for @blindState.
  ///
  /// In ta, this message translates to:
  /// **'மதிப்பீட்டிற்கு போதுமான தரவு இல்லை'**
  String get blindState;

  /// No description provided for @blindStateDetail.
  ///
  /// In ta, this message translates to:
  /// **'பரிந்துரைகளை மேம்படுத்த குளம் தரவை பதிவிடுங்கள்.'**
  String get blindStateDetail;

  /// No description provided for @pondCheckTitle.
  ///
  /// In ta, this message translates to:
  /// **'குளத்து சோதனை'**
  String get pondCheckTitle;

  /// No description provided for @feedGiven.
  ///
  /// In ta, this message translates to:
  /// **'கொடுக்கப்பட்ட தீவனம் (கிகி)'**
  String get feedGiven;

  /// No description provided for @feedGivenHint.
  ///
  /// In ta, this message translates to:
  /// **'கிகி-யில் அளவை உள்ளிடவும்'**
  String get feedGivenHint;

  /// No description provided for @mortality.
  ///
  /// In ta, this message translates to:
  /// **'இறப்பு எண்ணிக்கை'**
  String get mortality;

  /// No description provided for @mortalityHint.
  ///
  /// In ta, this message translates to:
  /// **'இறந்த மீன்களின் எண்ணிக்கை'**
  String get mortalityHint;

  /// No description provided for @feedTray.
  ///
  /// In ta, this message translates to:
  /// **'தீவன தட்டு நிலை'**
  String get feedTray;

  /// No description provided for @feedTrayEmpty.
  ///
  /// In ta, this message translates to:
  /// **'காலி — மீன்கள் எல்லாம் சாப்பிட்டன'**
  String get feedTrayEmpty;

  /// No description provided for @feedTraySome.
  ///
  /// In ta, this message translates to:
  /// **'சிறிது மிச்சம்'**
  String get feedTraySome;

  /// No description provided for @feedTrayFull.
  ///
  /// In ta, this message translates to:
  /// **'நிறைந்துள்ளது — மீன்கள் சாப்பிடவில்லை'**
  String get feedTrayFull;

  /// No description provided for @waterColor.
  ///
  /// In ta, this message translates to:
  /// **'நீரின் தோற்றம்'**
  String get waterColor;

  /// No description provided for @waterColorGood.
  ///
  /// In ta, this message translates to:
  /// **'நல்லது (பச்சை/தெளிவு)'**
  String get waterColorGood;

  /// No description provided for @waterColorMuddy.
  ///
  /// In ta, this message translates to:
  /// **'கலங்கல் / பழுப்பு'**
  String get waterColorMuddy;

  /// No description provided for @waterColorFoamy.
  ///
  /// In ta, this message translates to:
  /// **'நுரை / அசாதாரணம்'**
  String get waterColorFoamy;

  /// No description provided for @notes.
  ///
  /// In ta, this message translates to:
  /// **'கவனிப்புகள் (விரும்பினால்)'**
  String get notes;

  /// No description provided for @notesHint.
  ///
  /// In ta, this message translates to:
  /// **'எந்த அசாதாரண கவனிப்புகளும்…'**
  String get notesHint;

  /// No description provided for @addPhoto.
  ///
  /// In ta, this message translates to:
  /// **'புகைப்படம் சேர்'**
  String get addPhoto;

  /// No description provided for @submitLog.
  ///
  /// In ta, this message translates to:
  /// **'சமர்ப்பி'**
  String get submitLog;

  /// No description provided for @logSaved.
  ///
  /// In ta, this message translates to:
  /// **'பதிவு சேமிக்கப்பட்டது'**
  String get logSaved;

  /// No description provided for @logQueued.
  ///
  /// In ta, this message translates to:
  /// **'ஆஃப்லைன் சேமிப்பு — இணைக்கும்போது ஒத்திசைக்கும்'**
  String get logQueued;

  /// No description provided for @logError.
  ///
  /// In ta, this message translates to:
  /// **'பதிவை சேமிக்க முடியவில்லை. மீண்டும் முயற்சிக்கவும்.'**
  String get logError;

  /// No description provided for @dissolvedOxygen.
  ///
  /// In ta, this message translates to:
  /// **'கரைந்த ஆக்சிஜன் (mg/L)'**
  String get dissolvedOxygen;

  /// No description provided for @pHLevel.
  ///
  /// In ta, this message translates to:
  /// **'pH நிலை'**
  String get pHLevel;

  /// No description provided for @temperature.
  ///
  /// In ta, this message translates to:
  /// **'நீர் வெப்பநிலை (°C)'**
  String get temperature;

  /// No description provided for @salinity.
  ///
  /// In ta, this message translates to:
  /// **'உவர்ப்புத்தன்மை (ppt)'**
  String get salinity;

  /// No description provided for @ammonia.
  ///
  /// In ta, this message translates to:
  /// **'அமோனியா (mg/L)'**
  String get ammonia;

  /// No description provided for @askTitle.
  ///
  /// In ta, this message translates to:
  /// **'அக்வா AI-ஐ கேளுங்கள்'**
  String get askTitle;

  /// No description provided for @tapToAsk.
  ///
  /// In ta, this message translates to:
  /// **'கோளத்தைத் தொட்டு உங்கள் கேள்வியைப் பேசுங்கள்'**
  String get tapToAsk;

  /// No description provided for @listeningText.
  ///
  /// In ta, this message translates to:
  /// **'கேட்கிறது… இப்போது பேசுங்கள்'**
  String get listeningText;

  /// No description provided for @thinkingText.
  ///
  /// In ta, this message translates to:
  /// **'உங்கள் கேள்வியை செயலாக்குகிறது…'**
  String get thinkingText;

  /// No description provided for @responsePrompt.
  ///
  /// In ta, this message translates to:
  /// **'புதிய கேள்விக்கு கோளத்தைத் தொடவும்'**
  String get responsePrompt;

  /// No description provided for @typeQuestion.
  ///
  /// In ta, this message translates to:
  /// **'உங்கள் கேள்வியைத் தட்டச்சு செய்க…'**
  String get typeQuestion;

  /// No description provided for @recentQuestions.
  ///
  /// In ta, this message translates to:
  /// **'சமீபத்திய கேள்விகள்'**
  String get recentQuestions;

  /// No description provided for @aquaAnswer.
  ///
  /// In ta, this message translates to:
  /// **'அக்வாவின் பதில்'**
  String get aquaAnswer;

  /// No description provided for @callOfficer.
  ///
  /// In ta, this message translates to:
  /// **'விரிவாக்க அலுவலரை அழைக்கவும்'**
  String get callOfficer;

  /// No description provided for @askOffline.
  ///
  /// In ta, this message translates to:
  /// **'Ask AI-க்கு இணைய இணைப்பு தேவை.'**
  String get askOffline;

  /// No description provided for @audioUnavailable.
  ///
  /// In ta, this message translates to:
  /// **'குரல் வழிகாட்டல் இல்லை'**
  String get audioUnavailable;

  /// No description provided for @sampleQuery1.
  ///
  /// In ta, this message translates to:
  /// **'இன்று மீன்களுக்கு எவ்வளவு தீவனம் போட வேண்டும்?'**
  String get sampleQuery1;

  /// No description provided for @sampleQuery2.
  ///
  /// In ta, this message translates to:
  /// **'ஆக்சிஜன் 4 mg/L கீழே குறைந்தால் என்ன செய்ய வேண்டும்?'**
  String get sampleQuery2;

  /// No description provided for @sampleQuery3.
  ///
  /// In ta, this message translates to:
  /// **'மழைக்காலத்தில் pH சமநிலை பராமரிப்பது எப்படி?'**
  String get sampleQuery3;

  /// No description provided for @sampleQuery4.
  ///
  /// In ta, this message translates to:
  /// **'அமோனியா அளவை எவ்வாறு கட்டுப்படுத்துவது?'**
  String get sampleQuery4;

  /// No description provided for @alertsTitle.
  ///
  /// In ta, this message translates to:
  /// **'எச்சரிக்கைகள்'**
  String get alertsTitle;

  /// No description provided for @noAlerts.
  ///
  /// In ta, this message translates to:
  /// **'செயலில் உள்ள எச்சரிக்கைகள் இல்லை'**
  String get noAlerts;

  /// No description provided for @noAlertsDetail.
  ///
  /// In ta, this message translates to:
  /// **'உங்கள் குளங்கள் கண்காணிக்கப்படுகின்றன. எச்சரிக்கைகள் இங்கே தோன்றும்.'**
  String get noAlertsDetail;

  /// No description provided for @acknowledge.
  ///
  /// In ta, this message translates to:
  /// **'ஒப்புக்கொள்'**
  String get acknowledge;

  /// No description provided for @acknowledged.
  ///
  /// In ta, this message translates to:
  /// **'ஒப்புக்கொள்ளப்பட்டது'**
  String get acknowledged;

  /// No description provided for @alertSuppressed.
  ///
  /// In ta, this message translates to:
  /// **'எச்சரிக்கை அடக்கப்பட்டது'**
  String get alertSuppressed;

  /// No description provided for @feedbackCorrect.
  ///
  /// In ta, this message translates to:
  /// **'இந்த எச்சரிக்கை சரியானது'**
  String get feedbackCorrect;

  /// No description provided for @feedbackIncorrect.
  ///
  /// In ta, this message translates to:
  /// **'இந்த எச்சரிக்கை தவறானது'**
  String get feedbackIncorrect;

  /// No description provided for @alertsLoadError.
  ///
  /// In ta, this message translates to:
  /// **'எச்சரிக்கைகளை ஏற்ற முடியவில்லை. புதுப்பிக்க இழுக்கவும்.'**
  String get alertsLoadError;

  /// No description provided for @cropTitle.
  ///
  /// In ta, this message translates to:
  /// **'பயிர்ப் பருவம்'**
  String get cropTitle;

  /// No description provided for @stocking.
  ///
  /// In ta, this message translates to:
  /// **'இருப்பு'**
  String get stocking;

  /// No description provided for @milestones.
  ///
  /// In ta, this message translates to:
  /// **'மைல்கற்கள்'**
  String get milestones;

  /// No description provided for @treatments.
  ///
  /// In ta, this message translates to:
  /// **'சிகிச்சைகள்'**
  String get treatments;

  /// No description provided for @mortalityTotal.
  ///
  /// In ta, this message translates to:
  /// **'மொத்த இறப்பு'**
  String get mortalityTotal;

  /// No description provided for @cumulativeFeed.
  ///
  /// In ta, this message translates to:
  /// **'மொத்த தீவனம்'**
  String get cumulativeFeed;

  /// No description provided for @fcr.
  ///
  /// In ta, this message translates to:
  /// **'FCR'**
  String get fcr;

  /// No description provided for @spending.
  ///
  /// In ta, this message translates to:
  /// **'செலவு'**
  String get spending;

  /// No description provided for @projectedHarvest.
  ///
  /// In ta, this message translates to:
  /// **'கணிக்கப்பட்ட அறுவடை'**
  String get projectedHarvest;

  /// No description provided for @projectedSize.
  ///
  /// In ta, this message translates to:
  /// **'கணிக்கப்பட்ட அளவு'**
  String get projectedSize;

  /// No description provided for @costPerKg.
  ///
  /// In ta, this message translates to:
  /// **'கிகி மதிப்பு'**
  String get costPerKg;

  /// No description provided for @marketPrice.
  ///
  /// In ta, this message translates to:
  /// **'உள்ளூர் சந்தை விலை'**
  String get marketPrice;

  /// No description provided for @cropDataUnavailable.
  ///
  /// In ta, this message translates to:
  /// **'பயிர் தரவு இல்லை'**
  String get cropDataUnavailable;

  /// No description provided for @estimatedLabel.
  ///
  /// In ta, this message translates to:
  /// **'மதிப்பிடப்பட்டது'**
  String get estimatedLabel;

  /// No description provided for @unavailableLabel.
  ///
  /// In ta, this message translates to:
  /// **'கிடைக்கவில்லை'**
  String get unavailableLabel;

  /// No description provided for @myPondsTitle.
  ///
  /// In ta, this message translates to:
  /// **'என் குளங்கள்'**
  String get myPondsTitle;

  /// No description provided for @noPonds.
  ///
  /// In ta, this message translates to:
  /// **'குளங்கள் இல்லை'**
  String get noPonds;

  /// No description provided for @noPondsDetail.
  ///
  /// In ta, this message translates to:
  /// **'குளத்தை பதிவு செய்ய உங்கள் விரிவாக்க அலுவலரை தொடர்புகொள்ளவும்.'**
  String get noPondsDetail;

  /// No description provided for @pondDetails.
  ///
  /// In ta, this message translates to:
  /// **'குளத்தின் விவரங்கள்'**
  String get pondDetails;

  /// No description provided for @pondArea.
  ///
  /// In ta, this message translates to:
  /// **'பரப்பு'**
  String get pondArea;

  /// No description provided for @pondDepth.
  ///
  /// In ta, this message translates to:
  /// **'ஆழம்'**
  String get pondDepth;

  /// No description provided for @pondSpecies.
  ///
  /// In ta, this message translates to:
  /// **'இனம்'**
  String get pondSpecies;

  /// No description provided for @pondLocation.
  ///
  /// In ta, this message translates to:
  /// **'இடம்'**
  String get pondLocation;

  /// No description provided for @pondLastUpdated.
  ///
  /// In ta, this message translates to:
  /// **'கடைசியாக புதுப்பிக்கப்பட்டது'**
  String get pondLastUpdated;

  /// No description provided for @profileTitle.
  ///
  /// In ta, this message translates to:
  /// **'சுயவிவரம்'**
  String get profileTitle;

  /// No description provided for @language.
  ///
  /// In ta, this message translates to:
  /// **'மொழி'**
  String get language;

  /// No description provided for @notifications.
  ///
  /// In ta, this message translates to:
  /// **'அறிவிப்புகள்'**
  String get notifications;

  /// No description provided for @notificationsOn.
  ///
  /// In ta, this message translates to:
  /// **'இயக்கப்பட்டது'**
  String get notificationsOn;

  /// No description provided for @notificationsOff.
  ///
  /// In ta, this message translates to:
  /// **'முடக்கப்பட்டது'**
  String get notificationsOff;

  /// No description provided for @helpCenter.
  ///
  /// In ta, this message translates to:
  /// **'உதவி மையம்'**
  String get helpCenter;

  /// No description provided for @aboutApp.
  ///
  /// In ta, this message translates to:
  /// **'AquaVerse AI பற்றி'**
  String get aboutApp;

  /// No description provided for @version.
  ///
  /// In ta, this message translates to:
  /// **'பதிப்பு'**
  String get version;

  /// No description provided for @signOutConfirmTitle.
  ///
  /// In ta, this message translates to:
  /// **'வெளியேற?'**
  String get signOutConfirmTitle;

  /// No description provided for @signOutConfirmMessage.
  ///
  /// In ta, this message translates to:
  /// **'உங்கள் கைபேசி எண்ணுடன் மீண்டும் உள்நுழைய வேண்டும்.'**
  String get signOutConfirmMessage;

  /// No description provided for @officerPortal.
  ///
  /// In ta, this message translates to:
  /// **'அலுவலர் தளம்'**
  String get officerPortal;

  /// No description provided for @officerDashboard.
  ///
  /// In ta, this message translates to:
  /// **'டாஷ்போர்டு'**
  String get officerDashboard;

  /// No description provided for @officerPonds.
  ///
  /// In ta, this message translates to:
  /// **'ஒதுக்கப்பட்ட குளங்கள்'**
  String get officerPonds;

  /// No description provided for @officerAlerts.
  ///
  /// In ta, this message translates to:
  /// **'செயலில் உள்ள எச்சரிக்கைகள்'**
  String get officerAlerts;

  /// No description provided for @officerVisits.
  ///
  /// In ta, this message translates to:
  /// **'களப் பார்வைகள்'**
  String get officerVisits;

  /// No description provided for @addVisit.
  ///
  /// In ta, this message translates to:
  /// **'களப் பார்வை பதிவிடு'**
  String get addVisit;

  /// No description provided for @visitDate.
  ///
  /// In ta, this message translates to:
  /// **'பார்வை தேதி'**
  String get visitDate;

  /// No description provided for @visitObservations.
  ///
  /// In ta, this message translates to:
  /// **'கவனிப்புகள்'**
  String get visitObservations;

  /// No description provided for @visitWater.
  ///
  /// In ta, this message translates to:
  /// **'நீர் கவனிப்புகள்'**
  String get visitWater;

  /// No description provided for @visitMortality.
  ///
  /// In ta, this message translates to:
  /// **'கவனிக்கப்பட்ட இறப்பு'**
  String get visitMortality;

  /// No description provided for @visitAction.
  ///
  /// In ta, this message translates to:
  /// **'எடுக்கப்பட்ட நடவடிக்கை'**
  String get visitAction;

  /// No description provided for @visitAdvice.
  ///
  /// In ta, this message translates to:
  /// **'வழங்கப்பட்ட ஆலோசனை'**
  String get visitAdvice;

  /// No description provided for @visitFollowUp.
  ///
  /// In ta, this message translates to:
  /// **'தொடர்வு தேவை'**
  String get visitFollowUp;

  /// No description provided for @visitFollowUpDate.
  ///
  /// In ta, this message translates to:
  /// **'தொடர்வு தேதி'**
  String get visitFollowUpDate;

  /// No description provided for @callFarmer.
  ///
  /// In ta, this message translates to:
  /// **'விவசாயியை அழைக்கவும்'**
  String get callFarmer;

  /// No description provided for @farmerInfo.
  ///
  /// In ta, this message translates to:
  /// **'விவசாயியின் விவரங்கள்'**
  String get farmerInfo;

  /// No description provided for @visitSaved.
  ///
  /// In ta, this message translates to:
  /// **'பார்வை பதிவிடப்பட்டது'**
  String get visitSaved;

  /// No description provided for @visitQueued.
  ///
  /// In ta, this message translates to:
  /// **'ஆஃப்லைன் சேமிப்பு — இணைக்கும்போது ஒத்திசைக்கும்'**
  String get visitQueued;

  /// No description provided for @visitError.
  ///
  /// In ta, this message translates to:
  /// **'பார்வையை சேமிக்க முடியவில்லை. மீண்டும் முயற்சிக்கவும்.'**
  String get visitError;

  /// No description provided for @officerLogout.
  ///
  /// In ta, this message translates to:
  /// **'வெளியேறு'**
  String get officerLogout;

  /// No description provided for @helpTitle.
  ///
  /// In ta, this message translates to:
  /// **'உதவி மையம்'**
  String get helpTitle;

  /// No description provided for @faqTitle.
  ///
  /// In ta, this message translates to:
  /// **'அடிக்கடி கேட்கப்படும் கேள்விகள்'**
  String get faqTitle;

  /// No description provided for @contactTitle.
  ///
  /// In ta, this message translates to:
  /// **'ஆதரவை தொடர்பு கொள்ளுங்கள்'**
  String get contactTitle;

  /// No description provided for @contactDetail.
  ///
  /// In ta, this message translates to:
  /// **'ஆதரவிற்கு உங்கள் மாவட்ட விரிவாக்க அலுவலகத்தை அழைக்கவும்.'**
  String get contactDetail;

  /// No description provided for @offline.
  ///
  /// In ta, this message translates to:
  /// **'ஆஃப்லைன்'**
  String get offline;

  /// No description provided for @offlineMessage.
  ///
  /// In ta, this message translates to:
  /// **'நீங்கள் ஆஃப்லைனில் உள்ளீர்கள். காட்டப்படும் தரவு பழமையாக இருக்கலாம்.'**
  String get offlineMessage;

  /// No description provided for @syncPending.
  ///
  /// In ta, this message translates to:
  /// **'ஒத்திசைவு நிலுவையில்'**
  String get syncPending;

  /// No description provided for @syncing.
  ///
  /// In ta, this message translates to:
  /// **'ஒத்திசைக்கிறது…'**
  String get syncing;

  /// No description provided for @synced.
  ///
  /// In ta, this message translates to:
  /// **'ஒத்திசைக்கப்பட்டது'**
  String get synced;

  /// No description provided for @syncFailed.
  ///
  /// In ta, this message translates to:
  /// **'ஒத்திசைவு தோல்வி'**
  String get syncFailed;

  /// No description provided for @staleData.
  ///
  /// In ta, this message translates to:
  /// **'தரவு பழமையாக இருக்கலாம்'**
  String get staleData;

  /// No description provided for @lastUpdated.
  ///
  /// In ta, this message translates to:
  /// **'{time}-ல் புதுப்பிக்கப்பட்டது'**
  String lastUpdated(String time);

  /// No description provided for @loadError.
  ///
  /// In ta, this message translates to:
  /// **'தரவை ஏற்ற முடியவில்லை'**
  String get loadError;

  /// No description provided for @permissionDenied.
  ///
  /// In ta, this message translates to:
  /// **'அனுமதி மறுக்கப்பட்டது'**
  String get permissionDenied;

  /// No description provided for @unauthorised.
  ///
  /// In ta, this message translates to:
  /// **'இதை பார்க்க உங்களுக்கு அனுமதி இல்லை.'**
  String get unauthorised;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'hi', 'ta', 'te'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
    case 'ta':
      return AppLocalizationsTa();
    case 'te':
      return AppLocalizationsTe();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
