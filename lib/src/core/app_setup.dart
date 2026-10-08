import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../networks/api_config.dart';
import '../networks/cache/cache_config.dart';
import 'app_controller.dart';
import 'app_features.dart';
import 'app_logger.dart';
import 'app_theme_config.dart';
import 'security/app_encryption.dart';

/// Signature of [AppSetup.run]'s `onError`.
typedef AppErrorHandler = void Function(Object error, StackTrace stackTrace);

/// Starts an app in one call: binding, global error handlers, orientation,
/// system bars, [AppController.initialize], your own async setup, then
/// [runApp].
///
/// ```dart
/// Future<void> main() => AppSetup.run(
///   features: const AppFeatures(sharedPref: true, theme: true, logger: true),
///   themeConfig: const AppThemeConfig(seedColor: Colors.indigo),
///   orientations: const [DeviceOrientation.portraitUp],
///   onError: (error, stack) => crashReporter.record(error, stack),
///   app: const ServicesApp(title: 'My app', home: HomePage()),
/// );
/// ```
abstract final class AppSetup {
  /// Runs the steps in this order:
  ///
  /// 1. `WidgetsFlutterBinding.ensureInitialized()`.
  /// 2. When [onError] is given, routes framework errors
  ///    (`FlutterError.onError`, after the default console output) and
  ///    uncaught async errors (`PlatformDispatcher.onError`) to it.
  /// 3. [orientations] and [systemUiOverlayStyle], when given.
  /// 4. [AppController.initialize] with [features], [apiConfig],
  ///    [themeConfig], [cacheConfig] and [encryptionKeyProvider].
  /// 5. [beforeRun], for app-specific setup such as registering form enums
  ///    or loading the signed-in user.
  /// 6. `runApp(app)`.
  ///
  /// If step 4 or 5 throws, the error goes to [onError] and the app still
  /// starts, with the failed features unavailable. Without [onError] the
  /// error is rethrown and the app does not start.
  static Future<void> run({
    required Widget app,
    AppFeatures features = const AppFeatures(),
    ApiConfig? apiConfig,
    AppThemeConfig? themeConfig,
    CacheConfig cacheConfig = const CacheConfig(),
    EncryptionKeyProvider? encryptionKeyProvider,
    List<DeviceOrientation>? orientations,
    SystemUiOverlayStyle? systemUiOverlayStyle,
    Future<void> Function()? beforeRun,
    AppErrorHandler? onError,
  }) async {
    final binding = WidgetsFlutterBinding.ensureInitialized();

    if (onError != null) {
      final previous = FlutterError.onError;
      FlutterError.onError = (details) {
        previous?.call(details);
        onError(details.exception, details.stack ?? StackTrace.empty);
      };
      binding.platformDispatcher.onError = (error, stack) {
        AppLogger.error('Uncaught error: $error', stackTrace: stack);
        onError(error, stack);
        return true;
      };
    }

    if (orientations != null) {
      await SystemChrome.setPreferredOrientations(orientations);
    }
    if (systemUiOverlayStyle != null) {
      SystemChrome.setSystemUIOverlayStyle(systemUiOverlayStyle);
    }

    try {
      await AppController.initialize(
        features: features,
        apiConfig: apiConfig,
        themeConfig: themeConfig,
        cacheConfig: cacheConfig,
        encryptionKeyProvider: encryptionKeyProvider,
      );
      await beforeRun?.call();
    } catch (error, stack) {
      if (onError == null) rethrow;
      AppLogger.error('App setup failed: $error', stackTrace: stack);
      onError(error, stack);
    }

    runApp(app);
  }
}
