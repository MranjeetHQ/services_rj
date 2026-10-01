import 'package:dio/dio.dart';

class NetworkLogger extends Interceptor {
  NetworkLogger({this.printLogs = false});

  /// Controls whether the logs are printed to the console.
  /// Set to `true` (e.g. via [ApiConfig.printLogs]) to enable console output.
  final bool printLogs;

  /// Controlled by [AppController] through the `networkLogs` feature.
  static bool enabled = true;

  bool get _print => printLogs && enabled;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (_print) {
      print('[REQUEST] ${options.method} => ${options.uri}');
    }

    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (_print) {
      print(
        '[RESPONSE] ${response.statusCode} => ${response.requestOptions.uri}',
      );
    }

    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (_print) {
      print('[ERROR] ${err.message}');
    }

    handler.next(err);
  }
}
