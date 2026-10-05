import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../storage/secure_token_storage.dart';
import 'api_client.dart';

class AuthResponse {
  final bool success;
  final String message;
  final String? token;
  final String? role;
  final String? requestId;

  AuthResponse({
    required this.success,
    required this.message,
    this.token,
    this.role,
    this.requestId,
  });
}

/// Authentication API Service handling OTP request, verification, session check and logout.
class AuthApiService {
  final ApiClient _api;
  final SecureTokenStorage _tokenStorage;
  String? _lastRequestId;

  AuthApiService(this._api, this._tokenStorage);

  /// Calls `/v1/auth/otp/request` endpoint for 10-digit mobile number
  Future<AuthResponse> requestOtp(String mobileNumber) async {
    final cleanMobile = mobileNumber.replaceAll(RegExp(r'\D'), '');

    if (cleanMobile.length != 10) {
      return AuthResponse(
        success: false,
        message: 'Please enter a valid 10-digit mobile number',
      );
    }

    try {
      final formattedPhone = '+91$cleanMobile';
      final response = await _api.requestOtp({
        'phone': formattedPhone,
      });

      _lastRequestId = response.requestId;
      return AuthResponse(
        success: true,
        message: response.message,
        requestId: _lastRequestId,
      );
    } on DioException catch (e) {
      final detail = e.response?.data is Map
          ? (e.response!.data['detail'] ?? e.response!.data['message'])
          : null;
      return AuthResponse(
        success: false,
        message: detail?.toString() ?? e.message ?? 'Failed to send OTP',
      );
    } catch (_) {
      return AuthResponse(
        success: false,
        message: 'Network error. Please check connection.',
      );
    }
  }

  /// Calls `/v1/auth/otp/verify` endpoint for 6-digit OTP code
  Future<AuthResponse> verifyOtp(String mobileNumber, String otpCode, {String? role}) async {
    final cleanMobile = mobileNumber.replaceAll(RegExp(r'\D'), '');
    final cleanOtp = otpCode.trim();

    if (cleanOtp.length != 6) {
      return AuthResponse(
        success: false,
        message: 'Please enter a valid 6-digit OTP code',
      );
    }

    try {
      final formattedPhone = '+91$cleanMobile';
      final payload = <String, dynamic>{
        'request_id': _lastRequestId ?? '',
        'phone': formattedPhone,
        'otp': cleanOtp,
        'role': ?role,
      };

      final response = await _api.verifyOtp(payload);

      // Save tokens & verified role securely in flutter_secure_storage
      await _tokenStorage.saveTokens(
        accessToken: response.accessToken,
        refreshToken: '',
        expiresInSeconds: response.expiresIn,
        role: response.role,
      );

      return AuthResponse(
        success: true,
        message: 'OTP verified successfully',
        token: response.accessToken,
        role: response.role,
      );
    } on DioException catch (e) {
      final detail = e.response?.data is Map
          ? (e.response!.data['detail'] ?? e.response!.data['message'])
          : null;
      return AuthResponse(
        success: false,
        message: detail?.toString() ?? 'Invalid OTP code',
      );
    } catch (_) {
      return AuthResponse(
        success: false,
        message: 'Verification failed. Please check connection.',
      );
    }
  }

  /// Calls `GET /v1/auth/me` to validate session and fetch user identity
  Future<User?> getMe() async {
    final hasToken = await _tokenStorage.hasTokens();
    if (!hasToken) return null;

    try {
      return await _api.getMe();
    } catch (_) {
      return null;
    }
  }

  /// Attempts to refresh the authentication token and validates session via GET /v1/auth/me
  Future<AuthResponse> refreshToken() async {
    final hasToken = await _tokenStorage.hasTokens();
    if (!hasToken) {
      return AuthResponse(
        success: false,
        message: 'No active session token',
      );
    }

    try {
      final user = await _api.getMe().timeout(const Duration(seconds: 4));
      return AuthResponse(
        success: true,
        message: 'Session verified',
        token: await _tokenStorage.getAccessToken(),
        role: user.role,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await logout();
        return AuthResponse(
          success: false,
          message: 'Session expired. Please log in again.',
        );
      }
      // If network timeout or offline, check if token exists and is not expired
      final isExpired = await _tokenStorage.isAccessTokenExpired();
      if (!isExpired) {
        return AuthResponse(
          success: true,
          message: 'Offline session valid',
          token: await _tokenStorage.getAccessToken(),
          role: await _tokenStorage.getUserRole(),
        );
      }
      return AuthResponse(
        success: false,
        message: 'Session verification failed',
      );
    } catch (_) {
      final token = await _tokenStorage.getAccessToken();
      final role = await _tokenStorage.getUserRole();
      return AuthResponse(
        success: token != null,
        message: token != null ? 'Offline session valid' : 'No active session',
        token: token,
        role: role,
      );
    }
  }

  /// Clears stored token on Sign Out
  Future<void> logout() async {
    await _tokenStorage.clearTokens();
  }
}

final authApiServiceProvider = Provider<AuthApiService>((ref) {
  final api = ref.watch(apiClientProvider);
  final tokenStorage = ref.watch(tokenStorageProvider);
  return AuthApiService(api, tokenStorage);
});
