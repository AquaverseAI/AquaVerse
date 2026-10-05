import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/environment_config.dart';
import '../database/database.dart';
import '../network/api_client.dart';
import '../network/standalone_local_api_client.dart';
import '../network/interceptors/auth_interceptor.dart';
import '../network/interceptors/error_interceptor.dart';
import '../network/interceptors/logging_interceptor.dart';
import '../storage/secure_token_storage.dart';
import 'shared_preferences_provider.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

final tokenStorageProvider = Provider<SecureTokenStorage>((ref) {
  final secureStorage = ref.watch(secureStorageProvider);
  final prefs = ref.watch(sharedPreferencesProvider);
  return SecureTokenStorage(secureStorage: secureStorage, preferences: prefs);
});

final dioProvider = Provider<Dio>((ref) {
  final secureStorage = ref.watch(secureStorageProvider);
  final preferences = ref.watch(sharedPreferencesProvider);
  final baseUrl = EnvironmentConfig.apiBaseUrl;

  final dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
    contentType: 'application/json',
  ));

  dio.interceptors.add(
    AuthInterceptor(
      secureStorage: secureStorage,
      preferences: preferences,
    ),
  );

  if (EnvironmentConfig.isDevelopment) {
    dio.interceptors.add(LoggingInterceptor());
  }

  dio.interceptors.add(ErrorInterceptor());

  return dio;
});

final standaloneLocalApiClientProvider = Provider<ApiClient>((ref) {
  return StandaloneLocalApiClient();
});

/// Master API Client Provider.
/// Configured for 100% standalone local operation — zero remote backend required.
/// All data, auth, ponds, logs, alerts, and advisories are served instantly offline.
final apiClientProvider = Provider<ApiClient>((ref) {
  return ref.watch(standaloneLocalApiClientProvider);
});
