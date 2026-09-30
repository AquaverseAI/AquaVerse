import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../storage/secure_token_storage.dart';

/// Handles authentication by attaching JWT tokens to every request
class AuthInterceptor extends QueuedInterceptor {
  final FlutterSecureStorage secureStorage;
  final SharedPreferences preferences;
  late final SecureTokenStorage _tokenStorage;

  AuthInterceptor({
    required this.secureStorage,
    required this.preferences,
  }) {
    _tokenStorage = SecureTokenStorage(
      secureStorage: secureStorage,
      preferences: preferences,
    );
  }

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Skip auth for public endpoints
    if (_isPublicEndpoint(options.path)) {
      return handler.next(options);
    }

    try {
      final token = await _tokenStorage.getAccessToken();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    } catch (e) {
      // If token retrieval fails, continue without auth
      // The error interceptor will handle 401s
    }

    return handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // Handle 401 Unauthorized
    if (err.response?.statusCode == 401) {
      try {
        // Try to refresh token
        final refreshed = await _attemptTokenRefresh();
        if (refreshed) {
          // Retry the original request
          final retryOptions = err.requestOptions;
          final token = await _tokenStorage.getAccessToken();
          retryOptions.headers['Authorization'] = 'Bearer $token';
          return handler.resolve(await Dio().request(
            retryOptions.path,
            options: Options(
              method: retryOptions.method,
              headers: retryOptions.headers,
            ),
            data: retryOptions.data,
            queryParameters: retryOptions.queryParameters,
          ));
        }
      } catch (e) {
        // Token refresh failed, let error pass through
      }
    }

    return handler.next(err);
  }

  Future<bool> _attemptTokenRefresh() async {
    try {
      final refreshToken = await _tokenStorage.getRefreshToken();
      if (refreshToken == null) {
        return false;
      }

      // In a real app, call /v1/auth/refresh endpoint
      // For now, we'll just clear credentials on 401
      // This requires implementing token refresh endpoint in the backend
      return false;
    } catch (e) {
      return false;
    }
  }

  bool _isPublicEndpoint(String path) {
    final publicEndpoints = [
      '/v1/auth/otp/request',
      '/v1/auth/otp/verify',
      '/v1/auth/token',
      '/v1/health',
    ];
    return publicEndpoints.any((endpoint) => path.contains(endpoint));
  }
}
