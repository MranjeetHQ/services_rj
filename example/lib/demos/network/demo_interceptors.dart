import 'package:services_rj/services_rj.dart';

import 'network_common.dart';

/// Logs every request, response and error to [demoNetworkEvents] and counts
/// the requests that really reached the network.
///
/// The parameter types are inferred from [ApiInterceptor], so this file needs
/// no direct dependency on `dio`.
class DemoLogInterceptor extends ApiInterceptor {
  /// Creates the interceptor.
  DemoLogInterceptor();

  /// Requests sent since the app started. The cache demos diff it to show
  /// whether a call hit the network.
  static int requestCount = 0;

  /// Whether lines are written to [demoNetworkEvents].
  static bool logging = true;

  @override
  Future<void> onRequest(options) async {
    requestCount++;
    if (logging) {
      demoNetworkEvents.add(
        '[interceptor] -> ${options.method} ${options.uri}',
      );
    }
  }

  @override
  Future<void> onResponse(response) async {
    if (logging) {
      demoNetworkEvents.add(
        '[interceptor] <- ${response.statusCode} ${response.requestOptions.uri}',
      );
    }
  }

  @override
  Future<void> onError(error) async {
    if (logging) {
      demoNetworkEvents.add(
        '[interceptor] x ${error.type.name} '
        '${error.response?.statusCode ?? ''} ${error.requestOptions.uri}',
      );
    }
  }
}

/// Adds the saved token to the header named by `ApiConfig.tokenHeaderKey`.
///
/// `ApiConfig.tokenHeaderKey` is only a setting; the package does not read
/// it on its own. This interceptor is the small piece of app code that
/// applies it.
class TokenHeaderInterceptor extends ApiInterceptor {
  /// Creates the interceptor.
  TokenHeaderInterceptor();

  /// Whether the header is added.
  static bool enabled = true;

  @override
  Future<void> onRequest(options) async {
    if (!enabled) return;
    final key = AppController.instance.apiConfig?.tokenHeaderKey;
    if (key == null || !AppController.instance.isReady(AppFeature.sharedPref)) {
      return;
    }
    final token = AuthTokenService.instance.token;
    if (token != null && token.isNotEmpty) {
      options.headers[key] = token;
    }
  }
}

/// Forwards failed responses to the `ApiConfig` callbacks.
///
/// The callbacks are stored on [ApiConfig] but the package never calls them
/// by itself, so the app decides which status maps to which callback. The
/// mapping here is a common convention: 401 unauthorized, 419 session
/// expired, 403 user banned, anything else the global error handler.
class CallbackBridgeInterceptor extends ApiInterceptor {
  /// Creates the interceptor.
  CallbackBridgeInterceptor();

  /// Whether callbacks are invoked.
  static bool enabled = true;

  @override
  Future<void> onError(error) async {
    if (!enabled) return;
    final config = AppController.instance.apiConfig;
    if (config == null) return;
    final status = error.response?.statusCode;
    final message = error.message ?? 'Request failed';
    try {
      switch (status) {
        case 401:
          await config.onUnauthorized?.call();
        case 419:
          await config.onSessionExpired?.call();
        case 403:
          await config.onUserBanned?.call(message);
        default:
          config.onError?.call('${status ?? error.type.name}: $message');
      }
    } catch (e) {
      demoNetworkEvents.add('[callback] handler threw: $e');
    }
  }
}

bool _registered = false;

/// Registers the demo interceptors once. Calling it again does nothing,
/// because [DioService] has no way to remove an interceptor.
///
/// Returns `false` when the network feature is not ready.
bool ensureDemoInterceptors() {
  if (!AppController.instance.isReady(AppFeature.network)) return false;
  if (_registered) return true;
  _registered = true;
  DioService.instance.addInterceptors([
    DemoLogInterceptor(),
    TokenHeaderInterceptor(),
    CallbackBridgeInterceptor(),
  ]);
  return true;
}

/// Whether [ensureDemoInterceptors] already ran.
bool get demoInterceptorsRegistered => _registered;

bool _packageAuthRegistered = false;

/// Whether the package's own [AuthInterceptor] sends the token.
bool packageAuthEnabled = false;

/// Adds the package's [AuthInterceptor] to the raw Dio once. It is switched
/// on and off with [packageAuthEnabled].
bool ensurePackageAuthInterceptor() {
  if (!AppController.instance.isReady(AppFeature.network)) return false;
  if (_packageAuthRegistered) return true;
  _packageAuthRegistered = true;
  DioService.instance.dio.interceptors.add(
    AuthInterceptor(
      getToken: () async {
        if (!packageAuthEnabled ||
            !AppController.instance.isReady(AppFeature.sharedPref)) {
          return null;
        }
        return AuthTokenService.instance.token;
      },
      onRefreshToken: () async {
        demoNetworkEvents.add(
          '[AuthInterceptor] 401 received, onRefreshToken called (returning null)',
        );
        return null;
      },
    ),
  );
  return true;
}

/// Whether the package [AuthInterceptor] was added.
bool get packageAuthRegistered => _packageAuthRegistered;
