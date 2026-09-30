import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/environment_config.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/error_interceptor.dart';
import 'interceptors/logging_interceptor.dart';

/// Creates and configures a Dio instance for AquaVerse API
class DioConfig {
  static Dio? _instance;

  static Future<Dio> getInstance({
    required String baseUrl,
    required FlutterSecureStorage secureStorage,
    required SharedPreferences preferences,
  }) async {
    if (_instance != null) {
      return _instance!;
    }

    _instance = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 10),
      contentType: 'application/json',
      validateStatus: (status) => status != null && status < 500,
    ));

    // Add interceptors in order (outermost first)
    _instance!.interceptors.add(
      AuthInterceptor(
        secureStorage: secureStorage,
        preferences: preferences,
      ),
    );

    if (EnvironmentConfig.isDevelopment) {
      _instance!.interceptors.add(LoggingInterceptor());
    }

    _instance!.interceptors.add(ErrorInterceptor());

    return _instance!;
  }

  static Dio? getInstanceOrNull() => _instance;

  static void resetInstance() {
    _instance = null;
  }
}
