import 'package:shared_preferences/shared_preferences.dart';

/// Persistence store for onboarding flags and locale/role preferences.
class OnboardingFlagStore {
  static const String _keyHasOnboarded = 'has_onboarded';
  static const String _keySelectedLanguage = 'selected_language';
  static const String _keySelectedRole = 'selected_role';
  static const String _keyMobileNumber = 'user_mobile_number';

  final SharedPreferences _prefs;

  OnboardingFlagStore(this._prefs);

  static Future<OnboardingFlagStore> create() async {
    final prefs = await SharedPreferences.getInstance();
    return OnboardingFlagStore(prefs);
  }

  bool get hasOnboarded => _prefs.getBool(_keyHasOnboarded) ?? false;

  String get selectedLanguage => _prefs.getString(_keySelectedLanguage) ?? 'ta';

  String get selectedRole => _prefs.getString(_keySelectedRole) ?? 'farmer';

  String? get mobileNumber => _prefs.getString(_keyMobileNumber);

  Future<void> setHasOnboarded(bool value) async {
    await _prefs.setBool(_keyHasOnboarded, value);
  }

  Future<void> setSelectedLanguage(String languageCode) async {
    await _prefs.setString(_keySelectedLanguage, languageCode);
  }

  Future<void> setSelectedRole(String role) async {
    await _prefs.setString(_keySelectedRole, role);
  }

  Future<void> setMobileNumber(String mobile) async {
    await _prefs.setString(_keyMobileNumber, mobile);
  }

  Future<void> clearAll() async {
    await _prefs.remove(_keyHasOnboarded);
    await _prefs.remove(_keySelectedLanguage);
    await _prefs.remove(_keySelectedRole);
    await _prefs.remove(_keyMobileNumber);
  }
}
