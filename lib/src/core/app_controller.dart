import 'dart:io';

import 'package:flutter/widgets.dart';

import '../networks/api_client.dart';
import '../networks/api_config.dart';
import '../networks/cache/api_cache_manager.dart';
import '../networks/cache/cache_config.dart';
import '../networks/dio_service.dart';
import '../networks/network_logger.dart';
import '../networks/services/auth_token_service.dart';
import '../permissions/app_permission_manager.dart';
import 'app_connectivity.dart';
import 'app_features.dart';
import 'app_logger.dart';
import 'app_theme_controller.dart';
import 'security/app_encryption.dart';
import 'shared_pref_manager.dart';

/// Single place that controls every functionality of `services_rj`.
///
/// Call [initialize] once in `main()`. Features are disabled by default;
/// pass [AppFeatures] to enable only the functionality the app uses.
///
/// ```dart
/// await AppController.initialize(
///   apiConfig: ApiConfig(baseUrl: 'https://api.example.com'),
///   features: const AppFeatures(network: true, apiCache: true),
///   cacheConfig: const CacheConfig(defaultTtl: Duration(minutes: 10)),
/// );
///
/// AppController.instance.isEnabled(AppFeature.apiCache); // true
/// AppController.instance.setEnabled(AppFeature.logger, false);
/// ```
///
/// [AppController] is a [ChangeNotifier], so widgets can rebuild when a
/// feature is switched at runtime.
class AppController extends ChangeNotifier {
  AppController._();

  static final AppController instance = AppController._();

  AppFeatures _features = const AppFeatures();

  final Set<AppFeature> _ready = {};

  bool _isInitialized = false;

  ApiConfig? _apiConfig;

  CacheConfig _cacheConfig = const CacheConfig();

  Directory? _cacheDirectory;

  // ---------------------------------------------------------------------------
  // INITIALIZE
  // ---------------------------------------------------------------------------

  /// Initializes the enabled features in dependency order:
  /// encryption, shared preferences, theme, connectivity, network, cache,
  /// permissions.
  ///
  /// * [apiConfig] is required for the network and cache features. When it
  ///   is missing those features are skipped with a warning.
  /// * [encryptionKeyProvider] replaces the default keystore-backed key.
  ///   If the key cannot be loaded, initialization fails instead of
  ///   silently storing data unencrypted.
  static Future<void> initialize({
    AppFeatures features = const AppFeatures(),
    ApiConfig? apiConfig,
    CacheConfig cacheConfig = const CacheConfig(),
    EncryptionKeyProvider? encryptionKeyProvider,
    @visibleForTesting Directory? cacheDirectory,
  }) {
    return instance._initialize(
      features: features,
      apiConfig: apiConfig,
      cacheConfig: cacheConfig,
      encryptionKeyProvider: encryptionKeyProvider,
      cacheDirectory: cacheDirectory,
    );
  }

  Future<void> _initialize({
    required AppFeatures features,
    required ApiConfig? apiConfig,
    required CacheConfig cacheConfig,
    required EncryptionKeyProvider? encryptionKeyProvider,
    required Directory? cacheDirectory,
  }) async {
    if (_isInitialized) {
      AppLogger.warning('AppController.initialize() called twice; ignoring.');
      return;
    }

    WidgetsFlutterBinding.ensureInitialized();

    _features = features;
    _apiConfig = apiConfig;
    _cacheConfig = cacheConfig;
    _cacheDirectory = cacheDirectory;
    _applyRuntimeFlags();

    // Encryption first, so everything read afterwards can be decrypted.
    if (features.encryption) {
      await AppEncryption.instance.initialize(
        keyProvider: encryptionKeyProvider,
      );
      _ready.add(AppFeature.encryption);
    }

    if (features.sharedPref) {
      await SharedPrefManager.initilization();
      _ready.add(AppFeature.sharedPref);
    }

    if (features.theme) {
      if (!features.sharedPref) {
        AppLogger.warning(
          'Theme is enabled without sharedPref: theme mode will not be saved.',
        );
      }
      await AppThemeController.instance.initialize();
      _ready.add(AppFeature.theme);
    }

    if (features.connectivity) {
      await AppConnectivity.startMonitoring();
      _ready.add(AppFeature.connectivity);
    }

    if (features.network) {
      if (apiConfig == null) {
        AppLogger.warning(
          'Network is enabled but no ApiConfig was passed. '
          'Pass apiConfig to AppController.initialize(), or set network: false.',
        );
      } else {
        DioService.instance.initialize(apiConfig);
        _ready.add(AppFeature.network);
      }
    }

    if (features.apiCache && _ready.contains(AppFeature.network)) {
      try {
        await ApiCacheManager.instance.initialize(
          cacheConfig,
          directoryOverride: cacheDirectory,
        );
        _ready.add(AppFeature.apiCache);
      } catch (e, st) {
        // The app keeps working without a cache; requests go to the network.
        AppLogger.error('API cache could not start: $e', stackTrace: st);
      }
    }

    if (features.permissions) {
      await AppPermissionManager.instance.warmUp();
      _ready.add(AppFeature.permissions);
    }

    if (features.logger) _ready.add(AppFeature.logger);
    if (features.networkLogs && _ready.contains(AppFeature.network)) {
      _ready.add(AppFeature.networkLogs);
    }

    _isInitialized = true;
    AppLogger.info('AppController ready: $_features');
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // STATE
  // ---------------------------------------------------------------------------

  bool get isInitialized => _isInitialized;

  /// The features currently switched on.
  AppFeatures get features => _features;

  /// Whether [feature] is switched on.
  bool isEnabled(AppFeature feature) => _features.isEnabled(feature);

  /// Whether [feature] is switched on and started successfully.
  bool isReady(AppFeature feature) =>
      _ready.contains(feature) && _features.isEnabled(feature);

  /// Switches a feature at runtime. Only features in
  /// [runtimeToggleableFeatures] can be changed after [initialize]; the rest
  /// throw a [StateError]. Turning on the cache or connectivity also starts
  /// them if they were not started during [initialize].
  Future<void> setEnabled(AppFeature feature, bool enabled) async {
    if (!runtimeToggleableFeatures.contains(feature)) {
      throw StateError(
        '${feature.name} can only be configured in AppController.initialize().',
      );
    }
    if (_features.isEnabled(feature) == enabled) return;

    _features = _features.withFeature(feature, enabled);
    _applyRuntimeFlags();

    if (enabled) {
      switch (feature) {
        case AppFeature.connectivity:
          await AppConnectivity.startMonitoring();
          _ready.add(feature);
        case AppFeature.apiCache:
          if (_ready.contains(AppFeature.network) &&
              !ApiCacheManager.instance.isInitialized) {
            await ApiCacheManager.instance.initialize(
              _cacheConfig,
              directoryOverride: _cacheDirectory,
            );
          }
          if (ApiCacheManager.instance.isInitialized) {
            _ready.add(feature);
          }
        case AppFeature.logger:
        case AppFeature.permissions:
          _ready.add(feature);
        case AppFeature.networkLogs:
          if (_ready.contains(AppFeature.network)) {
            _ready.add(feature);
          }
        default:
          break;
      }
    }

    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // ACCESSORS: one entry point for every functionality
  // ---------------------------------------------------------------------------

  ApiConfig? get apiConfig => _apiConfig;

  ApiClient get api {
    _require(AppFeature.network);
    return ApiClient.instance;
  }

  DioService get dio {
    _require(AppFeature.network);
    return DioService.instance;
  }

  ApiCacheManager get cache {
    _require(AppFeature.apiCache);
    return ApiCacheManager.instance;
  }

  AppThemeController get theme {
    _require(AppFeature.theme);
    return AppThemeController.instance;
  }

  AppEncryption get encryption {
    _require(AppFeature.encryption);
    return AppEncryption.instance;
  }

  AppPermissionManager get permissions {
    _require(AppFeature.permissions);
    return AppPermissionManager.instance;
  }

  AuthTokenService get auth {
    _require(AppFeature.sharedPref);
    return AuthTokenService.instance;
  }

  // ---------------------------------------------------------------------------
  // DATA LIFECYCLE
  // ---------------------------------------------------------------------------

  /// Logs out: clears the token and, if configured, the API cache.
  Future<void> logout() async {
    if (isReady(AppFeature.sharedPref)) {
      await AuthTokenService.instance.logout();
    } else if (isReady(AppFeature.apiCache)) {
      await ApiCacheManager.instance.clear();
    }
  }

  /// Deletes all data this package stored: preferences, the API cache and,
  /// when [destroyEncryptionKey] is true, the encryption key itself.
  Future<void> wipeAllData({bool destroyEncryptionKey = false}) async {
    if (ApiCacheManager.instance.isInitialized) {
      await ApiCacheManager.instance.clear();
    }
    if (SharedPrefManager.isInitialized) {
      await SharedPrefManager.clearAllSharedPrefData();
    }
    if (destroyEncryptionKey && AppEncryption.instance.isInitialized) {
      await AppEncryption.instance.destroyKey();
      await AppEncryption.instance.initialize();
    }
  }

  /// Resets controller state so [initialize] can run again. Tests only.
  @visibleForTesting
  void resetForTest() {
    _isInitialized = false;
    _ready.clear();
    _features = const AppFeatures();
    _apiConfig = null;
    ApiCacheManager.instance.reset();
    AppEncryption.instance.reset();
    AppConnectivity.stopMonitoring();
  }

  // ---------------------------------------------------------------------------
  // PRIVATE
  // ---------------------------------------------------------------------------

  void _applyRuntimeFlags() {
    AppLogger.enabled = _features.logger;
    NetworkLogger.enabled = _features.networkLogs;
    ApiCacheManager.instance.enabled = _features.apiCache;
    AppEncryption.instance.enabled = _features.encryption;
    AppPermissionManager.instance.enabled = _features.permissions;
    if (AppConnectivity.enabled != _features.connectivity) {
      AppConnectivity.enabled = _features.connectivity;
    }
  }

  void _require(AppFeature feature) {
    if (!isReady(feature)) {
      throw StateError(
        '${feature.name} is not available. It is disabled in AppFeatures '
        'or AppController.initialize() has not run.',
      );
    }
  }
}
