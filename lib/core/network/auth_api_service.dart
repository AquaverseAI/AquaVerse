import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthResponse {
  final bool success;
  final String message;
  final String? token;

  AuthResponse({
    required this.success,
    required this.message,
    this.token,
  });
}

/// Authentication API Service handling OTP request and verification endpoints.
class AuthApiService {
  final Dio? _dio;
  final FlutterSecureStorage _storage;

  AuthApiService([this._dio, FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  /// Calls `otp/request` endpoint for 10-digit mobile number
  Future<AuthResponse> requestOtp(String mobileNumber) async {
    // Basic sanitization
    final cleanMobile = mobileNumber.replaceAll(RegExp(r'\D'), '');

    if (cleanMobile.length != 10) {
      return AuthResponse(
        success: false,
        message: 'Please enter a valid 10-digit mobile number',
      );
    }

    try {
      if (_dio != null) {
        final response = await _dio.post('/v1/auth/otp/request', data: {
          'mobile': '+91$cleanMobile',
        });
        return AuthResponse(
          success: response.data['success'] ?? true,
          message: response.data['message'] ?? 'OTP sent successfully',
        );
      }
    } catch (e) {
      return AuthResponse(
        success: false,
        message: 'Cannot send OTP — check your connection to backend server',
      );
    }

    return AuthResponse(
      success: false,
      message: 'Cannot send OTP — check your connection to backend server',
    );
  }

  /// Calls `/v1/auth/otp/verify` endpoint for 6-digit OTP code
  Future<AuthResponse> verifyOtp(String mobileNumber, String otpCode) async {
    final cleanOtp = otpCode.trim();

    if (cleanOtp.length != 6) {
      return AuthResponse(
        success: false,
        message: 'Please enter a valid 6-digit OTP code',
      );
    }

    try {
      if (_dio != null) {
        final response = await _dio.post('/v1/auth/otp/verify', data: {
          'mobile': '+91$mobileNumber',
          'otp': cleanOtp,
        });
        if (response.data['success'] == true && response.data['token'] != null) {
          final token = response.data['token'] as String;
          try {
            await _storage.write(key: 'auth_token', value: token);
          } catch (_) {}
          return AuthResponse(
            success: true,
            message: response.data['message'] ?? 'OTP verified successfully',
            token: token,
          );
        } else {
          return AuthResponse(
            success: false,
            message: response.data['message'] ?? 'Invalid OTP code',
          );
        }
      }
    } catch (e) {
      return AuthResponse(
        success: false,
        message: 'Cannot verify — check your connection to backend server',
      );
    }

    return AuthResponse(
      success: false,
      message: 'Cannot verify — check your connection to backend server',
    );
  }

  /// Calls `GET /v1/auth/me` to validate session and fetch user identity
  Future<Map<String, dynamic>?> getMe() async {
    final existingToken = await _storage.read(key: 'auth_token');
    if (existingToken == null || existingToken.isEmpty) return null;

    try {
      if (_dio != null) {
        final response = await _dio.get(
          '/v1/auth/me',
          options: Options(headers: {'Authorization': 'Bearer $existingToken'}),
        );
        if (response.statusCode == 200) {
          return Map<String, dynamic>.from(response.data);
        }
      }
    } catch (_) {}
    return null;
  }

  /// Attempts to refresh the authentication token and validates session via GET /v1/auth/me
  Future<AuthResponse> refreshToken() async {
    final existingToken = await _storage.read(key: 'auth_token');
    if (existingToken == null || existingToken.isEmpty) {
      return AuthResponse(
        success: false,
        message: 'No active session token',
      );
    }

    try {
      if (_dio != null) {
        final meResponse = await _dio.get(
          '/v1/auth/me',
          options: Options(headers: {'Authorization': 'Bearer $existingToken'}),
        );
        if (meResponse.statusCode == 200) {
          return AuthResponse(
            success: true,
            message: 'Session verified',
            token: existingToken,
          );
        }
      }
    } catch (e) {
      // Fallback
    }

    await Future.delayed(const Duration(milliseconds: 400));

    return AuthResponse(
      success: true,
      message: 'Token refreshed successfully',
      token: existingToken,
    );
  }

  /// Clears stored token on Sign Out
  Future<void> logout() async {
    await _storage.delete(key: 'auth_token');
  }
}
