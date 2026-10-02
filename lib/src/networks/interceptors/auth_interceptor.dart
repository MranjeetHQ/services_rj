import 'package:dio/dio.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor({required this.getToken, required this.onRefreshToken});

  final Future<String?> Function() getToken;

  final Future<String?> Function() onRefreshToken;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await getToken();

    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // -----------------------------------------------------------------------
    // TOKEN EXPIRED
    // -----------------------------------------------------------------------

    if (err.response?.statusCode == 401) {
      final newToken = await onRefreshToken();

      if (newToken != null) {
        final request = err.requestOptions;

        request.headers['Authorization'] = 'Bearer $newToken';

        final response = await Dio().fetch(request);

        return handler.resolve(response);
      }
    }

    handler.next(err);
  }
}
