import 'package:dio/dio.dart';
import 'dart:developer' as developer;

/// Logs HTTP requests and responses in development mode
class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    developer.log(
      'REQUEST: ${options.method} ${options.path}',
      name: 'AquaVerse.API',
    );
    if (options.data != null) {
      developer.log(
        'REQUEST BODY: ${options.data}',
        name: 'AquaVerse.API',
      );
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    developer.log(
      'RESPONSE: ${response.statusCode} ${response.requestOptions.path}',
      name: 'AquaVerse.API',
    );
    if (response.data != null && response.data is! String) {
      developer.log(
        'RESPONSE BODY: ${response.data}',
        name: 'AquaVerse.API',
      );
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    developer.log(
      'ERROR: ${err.type} ${err.message}',
      name: 'AquaVerse.API',
      error: err.error,
      stackTrace: err.stackTrace,
    );
    handler.next(err);
  }
}
