import 'package:dio/dio.dart';
import 'package:json_annotation/json_annotation.dart';

part 'api_error.g.dart';

/// Represents an API error response
@JsonSerializable()
class ApiErrorResponse {
  final String? detail;
  final String? message;
  final String? error;
  final int? code;
  final Map<String, dynamic>? errors;

  ApiErrorResponse({
    this.detail,
    this.message,
    this.error,
    this.code,
    this.errors,
  });

  factory ApiErrorResponse.fromJson(Map<String, dynamic> json) =>
      _$ApiErrorResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ApiErrorResponseToJson(this);

  String get displayMessage {
    return detail ?? message ?? error ?? 'An unknown error occurred';
  }
}

/// Normalized error representation
class ApiError extends DioException {
  final String? detail;
  final int? errorCode;
  final ApiErrorResponse? errorResponse;

  ApiError({
    required super.requestOptions,
    super.message,
    super.type = DioExceptionType.unknown,
    this.detail,
    this.errorCode,
    this.errorResponse,
  });

  factory ApiError.fromDioException(DioException exception) {
    final statusCode = exception.response?.statusCode;

    ApiErrorResponse? errorResponse;
    String? detail;

    try {
      if (exception.response?.data is Map<String, dynamic>) {
        errorResponse = ApiErrorResponse.fromJson(
          exception.response?.data as Map<String, dynamic>,
        );
        detail = errorResponse.displayMessage;
      }
    } catch (e) {
      // Ignore JSON parse errors
    }

    // Provide default messages based on connection error or status code
    String defaultMessage;
    if (exception.type == DioExceptionType.connectionTimeout ||
        exception.type == DioExceptionType.sendTimeout ||
        exception.type == DioExceptionType.receiveTimeout ||
        exception.type == DioExceptionType.connectionError) {
      defaultMessage = 'Unable to connect to AquaVerse server. Please ensure the server is running.';
    } else {
      defaultMessage = _getDefaultMessageForStatus(statusCode);
    }
    final message = detail ?? defaultMessage;

    return ApiError(
      requestOptions: exception.requestOptions,
      message: message,
      type: exception.type,
      detail: detail,
      errorCode: statusCode,
      errorResponse: errorResponse,
    );
  }

  static String _getDefaultMessageForStatus(int? statusCode) {
    switch (statusCode) {
      case 400:
        return 'Invalid request. Please check your input.';
      case 401:
        return 'Your session has expired. Please sign in again.';
      case 403:
        return 'You do not have permission to access this resource.';
      case 404:
        return 'The resource you are looking for does not exist.';
      case 429:
        return 'Too many requests. Please try again later.';
      case 500:
      case 502:
      case 503:
        return 'We are experiencing technical difficulties. Please try again later.';
      default:
        return 'An error occurred. Please try again.';
    }
  }

  bool get isNetworkError {
    return type == DioExceptionType.connectionTimeout ||
        type == DioExceptionType.receiveTimeout ||
        type == DioExceptionType.sendTimeout ||
        type == DioExceptionType.connectionError;
  }

  bool get isAuthError => errorCode == 401;

  bool get isValidationError => errorCode == 400;

  bool get isServerError => errorCode != null && errorCode! >= 500;
}
