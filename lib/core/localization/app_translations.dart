import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../storage/onboarding_flag_store.dart';

/// Language state provider linked with Riverpod and persistent store
final appLanguageProvider = StateNotifierProvider<AppLanguageNotifier, String>((ref) {
  return AppLanguageNotifier();
});

class AppLanguageNotifier extends StateNotifier<String> {
  AppLanguageNotifier() : super('ta') {
    _loadStoredLanguage();
  }

  Future<void> _loadStoredLanguage() async {
    try {
      final store = await OnboardingFlagStore.create();
      state = store.selectedLanguage;
    } catch (_) {}
  }

  Future<void> setLanguage(String code) async {
    state = code;
    try {
      final store = await OnboardingFlagStore.create();
      await store.setSelectedLanguage(code);
    } catch (_) {}
  }
}

/// Centralized Translation Dictionary (English & Tamil) for Bhashini & App UI
class AppTranslations {
  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      // General Navigation
      'today': 'Today',
      'log': 'Pond Check',
      'ask': 'Ask Aqua AI',
      'alerts': 'Alerts',
      'crop': 'Crop',
      'profile': 'Profile',
      'settings': 'Settings',
      'signOut': 'Sign Out',
      
      // Farmer Dashboard
      'vanakkam': 'Vanakkam,',
      'overallPondRisk': 'Overall Pond Risk',
      'lowRisk': 'Low Risk',
      'mediumRisk': 'Medium Risk',
      'highRisk': 'High Risk',
      'lowRiskDesc': 'Pond environment is stable and optimal for crop growth.',
      'mediumRiskDesc': 'Parameters show slight variance. Monitor closely today.',
      'highRiskDesc': 'Attention required! Environmental conditions warrant immediate check.',
      'latestParameters': 'Latest Parameters',
      'fieldCheck': 'Field Check →',
      'recentEvents': 'Recent Pond Events',
      'todayFarmAction': "Today's Farm Action",
      'pondHealthIndex': 'Pond Health Index',
      'doForecastChart': 'DO Forecast Chart',
      'feedRecommendation': 'Feed Recommendation',
      'sensorReadings': 'Live IoT Sensor Telemetry',
      'waterQualityGood': 'Water Quality Optimal',
      'advisories': 'Farm Advisories',
      'offlineNotice': 'Ask Aqua needs internet. Connect to get answers.',

      // Log & Media
      'pondTelemetryAndAi': 'Pond Telemetry & AI Check',
      'waterPhotosMedia': 'Water Appearance & Quality Photo Media',
      'submitWaterPhotos': 'Submit Water Photo Media',
      'dissolvedOxygen': 'Dissolved Oxygen',
      'pHLevel': 'pH Level',
      'temperature': 'Water Temperature',
      'salinity': 'Salinity',
      'ammonia': 'Ammonia Level',

      // Ask AI
      'aquaAiAssistant': 'AQUA AI ASSISTANT',
      'askTitle': 'Ask Aqua',
      'tapToAsk': 'Tap Aurora AI and ask your question',
      'listeningText': 'Listening… Speak your question',
      'thinkingText': 'Aqua AI is processing…',
      'responsePrompt': 'Tap Aurora AI for new question',
      'typeQuestion': 'Type your question…',
      'recentQuestions': 'Recent Questions',
      'aquaAnswer': "Aqua's Answer",
      'callOfficer': 'Call Officer',
      'sampleQuery1': 'How much feed should I give today?',
      'sampleQuery2': 'What to do if DO drops below 4 mg/L?',
      'sampleQuery3': 'How to maintain pH balance in rainy season?',
      'sampleQuery4': 'What is the optimal ammonia level?',

      // Extension Officer
      'officerPortal': 'Extension Officer Portal',
      'sendAdvice': 'Send Advice',
      'addVisit': 'Add Visit',
      'viewReports': 'View Reports',
      'callFarmer': 'Call Farmer',
      'farmerInfo': 'Farmer Information',
      'clusterAnalytics': 'Cluster Analytics & Reports',
      'downloadPdfReport': 'Download Full District Report (PDF)',

      // Speaker & TTS
      'speakingText': 'Reading aloud in English…',
    },
    'ta': {
      // General Navigation
      'today': 'இன்று',
      'log': 'குளத்து சோதனை',
      'ask': 'அக்வா AI',
      'alerts': 'எச்சரிக்கைகள்',
      'crop': 'பயிர்ப் பருவம்',
      'profile': 'சுயவிவரம்',
      'settings': 'அமைப்புகள்',
      'signOut': 'வெளியேறு',
      
      // Farmer Dashboard
      'vanakkam': 'வணக்கம்,',
      'overallPondRisk': 'ஒட்டுமொத்தக் குளத்து அபாய நிலை',
      'lowRisk': 'குறைந்த அபாயம்',
      'mediumRisk': 'நடுத்தர அபாயம்',
      'highRisk': 'அதிக அபாயம்',
      'lowRiskDesc': 'குளத்தின் சூழ்நிலை பாதுகாப்பாகவும் வளர்ப்பிற்கு உகந்ததாகவும் உள்ளது.',
      'mediumRiskDesc': 'அளவீடுகளில் சிறிய மாற்றம் உள்ளது. இன்று உன்னிப்பாகக் கவனிக்கவும்.',
      'highRiskDesc': 'கவனத்திற்கு! சுற்றுப்புற சூழ்நிலை காரணமாக உடனடி குளத்து சோதனை தேவை.',
      'latestParameters': 'சமீபத்திய நீர் அளவீடுகள்',
      'fieldCheck': 'நேரடிச் சோதனை →',
      'recentEvents': 'சமீபத்திய நிகழ்வுகள்',
      'todayFarmAction': 'இன்றைய பண்ணை நடவடிக்கை',
      'pondHealthIndex': 'குளத்தின் ஆரோக்கிய நிலை',
      'doForecastChart': 'ஆக்சிஜன் கணிப்பு வரைபடம்',
      'feedRecommendation': 'தீவனப் பரிந்துரை',
      'sensorReadings': 'நேரலை சென்சார் அளவீடுகள்',
      'waterQualityGood': 'நீரின் தரம் சிறப்பாக உள்ளது',
      'advisories': 'பண்ணை ஆலோசனைகள்',
      'offlineNotice': 'பதில்களைப் பெற இணைய இணைப்பு தேவை.',

      // Log & Media
      'pondTelemetryAndAi': 'குளத்து சென்சார் & AI பரிசோதனை',
      'waterPhotosMedia': 'நீர் தோற்றம் & தரம் புகைப்படங்கள்',
      'submitWaterPhotos': 'நீரின் புகைப்படங்களைச் சமர்ப்பி',
      'dissolvedOxygen': 'கரைந்த ஆக்சிஜன் (DO)',
      'pHLevel': 'pH நிலை (pH)',
      'temperature': 'வெப்பநிலை (Temp)',
      'salinity': 'உவர்ப்புத் தன்மை (Salinity)',
      'ammonia': 'அமோனியா அளவு (Ammonia)',

      // Ask AI
      'aquaAiAssistant': 'அக்வா AI உதவியாளர்',
      'askTitle': 'அக்வாவிடம் கேளுங்கள்',
      'tapToAsk': 'ஆரோரா AI-ஐ தொட்டு உங்கள் கேள்வியைக் கேளுங்கள்',
      'listeningText': 'கேட்கிறது… உங்கள் கேள்வியைப் பேசுங்கள்',
      'thinkingText': 'அக்வா AI செயலாக்குகிறது…',
      'responsePrompt': 'புதிய கேள்விக்கு ஆரோரா AI-ஐ தொடவும்',
      'typeQuestion': 'உங்கள் கேள்வியைத் தட்டச்சு செய்க…',
      'recentQuestions': 'சமீபத்திய கேள்விகள்',
      'aquaAnswer': 'அக்வாவின் பதில்',
      'callOfficer': 'அலுவலரை அழைக்கவும்',
      'sampleQuery1': 'இன்று மீன்களுக்கு எவ்வளவு தீவனம் போட வேண்டும்?',
      'sampleQuery2': 'ஆக்சிஜன் 4 mg/L கீழே குறைந்தால் என்ன செய்ய வேண்டும்?',
      'sampleQuery3': 'மழைக்காலத்தில் pH சமநிலை பராமரிப்பது எப்படி?',
      'sampleQuery4': 'அமோனியா அளவை எவ்வாறு கட்டுப்படுத்துவது?',

      // Extension Officer
      'officerPortal': 'விரிவாக்க அலுவலர் தளம்',
      'sendAdvice': 'ஆலோசனை அனுப்பு',
      'addVisit': 'பார்வை பதிவு',
      'viewReports': 'அறிக்கைகளைப் பார்',
      'callFarmer': 'விவசாயியை அழைக்கவும்',
      'farmerInfo': 'விவசாயியின் விவரங்கள்',
      'clusterAnalytics': 'மாவட்டக் குழு பகுப்பாய்வு',
      'downloadPdfReport': 'முழு அறிக்கையைப் பதிவிறக்கு (PDF)',

      // Speaker & TTS
      'speakingText': 'தமிழில் குரல் வழிகாட்டல் இயங்குகிறது…',
    },
  };

  static String getText(String key, String langCode) {
    final langMap = _localizedValues[langCode] ?? _localizedValues['ta']!;
    return langMap[key] ?? _localizedValues['en']?[key] ?? key;
  }
}
