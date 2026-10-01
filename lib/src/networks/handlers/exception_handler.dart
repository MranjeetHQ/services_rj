import 'package:dio/dio.dart';

import '../api_exception.dart';

class ExceptionHandler {
  static ApiException handle(dynamic error, {StackTrace? stackTrace}) {
    if (error is ApiException) return error;

    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return ApiException(
            message: 'Connection timed out',
            statusCode: error.response?.statusCode,
          );

        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode ?? 0;
          final data = error.response?.data;
          final message =
              (data is Map ? data['message']?.toString() : null) ??
              error.message ??
              'Something went wrong';

          return ApiException(
            message: message,
            statusCode: statusCode,
            data: error.response?.data,
          );

        case DioExceptionType.cancel:
          return ApiException(
            message: 'Request cancelled',
            statusCode: error.response?.statusCode,
          );

        case DioExceptionType.connectionError:
          return ApiException(
            message: 'No internet connection',
            statusCode: error.response?.statusCode,
          );

        default:
          return ApiException(
            message: error.message ?? 'Something went wrong',
            statusCode: error.response?.statusCode,
          );
      }
    }
    return ApiException(message: error?.toString() ?? 'Something went wrong');
  }
}
