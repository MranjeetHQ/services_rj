import '../networks/api_config.dart';
import '../networks/cache/cache_config.dart';
import 'app_controller.dart';
import 'app_features.dart';

/// Kept for backward compatibility. New code should call
/// [AppController.initialize], which also controls caching, encryption,
/// connectivity and logging.
class AppInitializer {
  AppInitializer._();

  static Future<void> initialize({
    bool initializeSharedPref = true,
    bool initializeTheme = true,
    bool initializeNetwork = false,
    ApiConfig? apiConfig,
    AppFeatures? features,
    CacheConfig cacheConfig = const CacheConfig(),
  }) async {
    await AppController.initialize(
      features:
          features ??
          AppFeatures(
            sharedPref: initializeSharedPref,
            theme: initializeTheme,
            network: initializeNetwork,
            apiCache: initializeNetwork,
            networkLogs: initializeNetwork,
          ),
      apiConfig: apiConfig,
      cacheConfig: cacheConfig,
    );
  }
}
