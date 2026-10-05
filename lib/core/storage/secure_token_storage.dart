import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Handles secure storage of authentication tokens
class SecureTokenStorage {
  static const String _accessTokenKey = 'aquaverse_access_token';
  static const String _refreshTokenKey = 'aquaverse_refresh_token';
  static const String _tokenExpireTimeKey = 'aquaverse_token_expire_time';
  static const String _userRoleKey = 'aquaverse_user_role';

  final FlutterSecureStorage secureStorage;
  final SharedPreferences preferences;

  SecureTokenStorage({
    required this.secureStorage,
    required this.preferences,
  });

  /// Save access and refresh tokens
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    int? expiresInSeconds,
    String? role,
  }) async {
    await secureStorage.write(
      key: _accessTokenKey,
      value: accessToken,
    );
    await secureStorage.write(
      key: 'auth_token',
      value: accessToken,
    );
    await secureStorage.write(
      key: _refreshTokenKey,
      value: refreshToken,
    );

    if (role != null) {
      await secureStorage.write(
        key: _userRoleKey,
        value: role,
      );
    }

    // Store expiration time if provided
    if (expiresInSeconds != null) {
      final expirationTime = DateTime.now()
          .add(Duration(seconds: expiresInSeconds))
          .millisecondsSinceEpoch;
      await preferences.setInt(_tokenExpireTimeKey, expirationTime);
    }
  }

  /// Get the access token
  Future<String?> getAccessToken() async {
    final token = await secureStorage.read(key: _accessTokenKey);
    if (token != null && token.isNotEmpty) return token;
    return await secureStorage.read(key: 'auth_token');
  }

  /// Get the refresh token
  Future<String?> getRefreshToken() async {
    return await secureStorage.read(key: _refreshTokenKey);
  }

  /// Get the verified user role
  Future<String?> getUserRole() async {
    return await secureStorage.read(key: _userRoleKey);
  }

  /// Check if access token is expired
  Future<bool> isAccessTokenExpired() async {
    final expirationTime = preferences.getInt(_tokenExpireTimeKey);
    if (expirationTime == null) {
      return false; // No expiration time set, assume not expired
    }
    return DateTime.now().millisecondsSinceEpoch > expirationTime;
  }

  /// Clear all tokens
  Future<void> clearTokens() async {
    await secureStorage.delete(key: _accessTokenKey);
    await secureStorage.delete(key: _refreshTokenKey);
    await secureStorage.delete(key: 'auth_token');
    await secureStorage.delete(key: _userRoleKey);
    await preferences.remove(_tokenExpireTimeKey);
  }

  /// Check if any token is stored
  Future<bool> hasTokens() async {
    final accessToken = await getAccessToken();
    return accessToken != null && accessToken.isNotEmpty;
  }
}
