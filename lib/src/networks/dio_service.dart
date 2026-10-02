import 'package:dio/dio.dart';

import 'api_config.dart';
import 'api_interceptor.dart';
import 'network_logger.dart';

class DioService {
  DioService._();

  static final DioService instance = DioService._();

  Dio? _dio;
  final List<ApiInterceptor> _interceptors = [];
  bool _isInitialized = false;

  /// Returns the initialized [Dio] instance.
  ///
  /// Throws a [StateError] if [initialize] has not been called yet.
  Dio get dio {
    if (_dio == null) {
      throw StateError(
        'DioService has not been initialized. Call initialize() first.',
      );
    }
    return _dio!;
  }

  void initialize(ApiConfig config) {
    if (_isInitialized) return;

    _dio = Dio(
      BaseOptions(
        baseUrl: config.baseUrl,
        connectTimeout: Duration(milliseconds: config.connectTimeout),
        receiveTimeout: Duration(milliseconds: config.receiveTimeout),
        sendTimeout: Duration(milliseconds: config.sendTimeout),
        headers: config.defaultHeaders,
      ),
    );

    _registerInterceptors(config);

    _isInitialized = true;
  }

  /// Registers custom [ApiInterceptor]s before the global error/response
  /// interceptors so they run first.
  void addInterceptor(ApiInterceptor interceptor) {
    _interceptors.add(interceptor);

    if (_isInitialized) {
      _registerInterceptor(interceptor);
    }
  }

  void addInterceptors(Iterable<ApiInterceptor> interceptors) {
    for (final interceptor in interceptors) {
      addInterceptor(interceptor);
    }
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  void _registerInterceptors(ApiConfig config) {
    _dio!.interceptors.add(NetworkLogger(printLogs: config.printLogs));

    for (final interceptor in _interceptors) {
      _registerInterceptor(interceptor);
    }

    _dio!.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          handler.next(options);
        },
        onResponse: (response, handler) async {
          handler.next(response);
        },
        onError: (error, handler) async {
          handler.next(error);
        },
      ),
    );
  }

  void _registerInterceptor(ApiInterceptor interceptor) {
    _dio!.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          try {
            await interceptor.onRequest(options);
          } finally {
            handler.next(options);
          }
        },
        onResponse: (response, handler) async {
          try {
            await interceptor.onResponse(response);
          } finally {
            handler.next(response);
          }
        },
        onError: (error, handler) async {
          try {
            await interceptor.onError(error);
          } finally {
            handler.next(error);
          }
        },
      ),
    );
  }
}
