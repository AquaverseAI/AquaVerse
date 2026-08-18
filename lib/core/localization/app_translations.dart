import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Language state provider linked with Riverpod
final appLanguageProvider = StateNotifierProvider<AppLanguageNotifier, String>((ref) {
  return AppLanguageNotifier();
});

class AppLanguageNotifier extends StateNotifier<String> {
  AppLanguageNotifier() : super('ta'); // Default Tamil

  void setLanguage(String code) {
    state = code;
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
      'todayFarmAction': "Today's Farm Action",
      'pondHealthIndex': 'Pond Health Index',
      'doForecastChart': 'DO Forecast Chart',
      'feedRecommendation': 'Feed Recommendation',
      'sensorReadings': 'Live IoT Sensor Telemetry',
      'waterQualityGood': 'Water Quality Optimal',

      // Log & Media
      'pondTelemetryAndAi': 'Pond Telemetry & AI Check',
      'waterPhotosMedia': 'Water Appearance & Quality Photo Media',
      'submitWaterPhotos': 'Submit Water Photo Media',

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
      'ask': 'அக்வா AI-யிடம் கேளுங்கள்',
      'alerts': 'எச்சரிக்கைகள்',
      'crop': 'பயிர்ப் பருவம்',
      'profile': 'சுயவிவரம்',
      'settings': 'அமைப்புகள்',
      'signOut': 'வெளியேறு',
      
      // Farmer Dashboard
      'todayFarmAction': 'இன்றைய பண்ணை நடவடிக்கை',
      'pondHealthIndex': 'குளத்தின் ஆரோக்கிய நிலை',
      'doForecastChart': 'ஆக்சிஜன் கணிப்பு வரைபடம்',
      'feedRecommendation': 'தீவனப் பரிந்துரை',
      'sensorReadings': 'நேரலை சென்சார் அளவீடுகள்',
      'waterQualityGood': 'நீரின் தரம் சிறப்பாக உள்ளது',

      // Log & Media
      'pondTelemetryAndAi': 'குளத்து சென்சார் & AI பரிசோதனை',
      'waterPhotosMedia': 'நீர் தோற்றம் & தரம் புகைப்படங்கள்',
      'submitWaterPhotos': 'நீரின் புகைப்படங்களைச் சமர்ப்பி',

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
