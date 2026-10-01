import '../api_exception.dart';
import '../api_response.dart';

class ResponseHandler {
  static ApiResponse<dynamic> handle(ApiResponse<dynamic> response) {
    final statusCode = response.statusCode ?? 0;

    // Every 2xx is a success, including 202 Accepted and 204 No Content.
    if (statusCode >= 200 && statusCode < 300) {
      return ApiResponse(
        success: true,
        data: response.data,
        statusCode: statusCode,
      );
    }

    if (statusCode == 401) {
      throw ApiException(message: 'Unauthorized', statusCode: statusCode);
    }

    throw ApiException(
      message: _message(response.data) ?? 'Something went wrong',
      statusCode: statusCode,
      data: response.data,
    );
  }

  /// Reads `message` only when the body is a JSON object. A plain-text or
  /// list body must not crash the error path.
  static String? _message(dynamic data) =>
      data is Map ? data['message']?.toString() : null;
}
