/// Environment configuration for the app
class EnvironmentConfig {
  static const bool isDevelopment = bool.fromEnvironment('DEV', defaultValue: false);
  static const bool isStaging = bool.fromEnvironment('STAGING', defaultValue: false);

  // API base URL - configurable per environment
  static const String apiBaseUrlDev = 'http://localhost:8000';
  static const String apiBaseUrlStaging = 'https://staging-api.aquaverse.ai';
  static const String apiBaseUrlProduction = 'https://api.aquaverse.ai';

  static String get apiBaseUrl {
    if (isDevelopment) {
      return apiBaseUrlDev;
    } else if (isStaging) {
      return apiBaseUrlStaging;
    } else {
      return apiBaseUrlProduction;
    }
  }

  // App version
  static const String appVersion = '1.0.0';

  // Feature flags
  static const bool enableOfflineMode = true;
  static const bool enableLogging = !bool.fromEnvironment('RELEASE', defaultValue: false);
}
