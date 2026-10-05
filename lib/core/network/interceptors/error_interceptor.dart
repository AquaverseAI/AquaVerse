import 'package:dio/dio.dart';
import '../models/api_error.dart';

/// Handles API errors and normalizes them into AppException
class ErrorInterceptor extends Interceptor {
  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // Convert DioException to AppException
    final appError = ApiError.fromDioException(err);
    
    return handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        error: appError,
        message: appError.message,
        type: err.type,
      ),
    );
  }
}
