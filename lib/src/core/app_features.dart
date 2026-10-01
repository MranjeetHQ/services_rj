/// Every functionality in `services_rj` that [AppController] can switch
/// on or off.
enum AppFeature {
  /// Persistent key/value storage via [SharedPrefManager].
  sharedPref,

  /// Light/dark theme handling via [AppThemeController].
  theme,

  /// HTTP layer: [DioService] and [ApiClient].
  network,

  /// Offline-first API response caching via [ApiCacheManager].
  apiCache,

  /// AES-256-GCM encryption of shared preferences and the API cache.
  encryption,

  /// Online/offline tracking via [AppConnectivity].
  connectivity,

  /// Console logging via [AppLogger].
  logger,

  /// Request/response logging from the network layer.
  networkLogs,

  /// Runtime permissions via [AppPermissionManager].
  permissions,
}

/// Features that can be switched on or off at runtime with
/// [AppController.setEnabled]. All others are fixed once
/// [AppController.initialize] has run, because turning them on or off later
/// would leave stored data in an inconsistent state.
const Set<AppFeature> runtimeToggleableFeatures = {
  AppFeature.apiCache,
  AppFeature.connectivity,
  AppFeature.logger,
  AppFeature.networkLogs,
  AppFeature.permissions,
};

/// Declares which features the app uses. Features are opt-in and disabled by
/// default.
///
/// ```dart
/// // Nothing starts unless selected.
/// const AppFeatures();
///
/// // Enable only the features this app uses.
/// const AppFeatures(sharedPref: true, theme: true);
///
/// // Only the features listed
/// AppFeatures.only({AppFeature.sharedPref, AppFeature.theme});
/// ```
class AppFeatures {
  const AppFeatures({
    this.sharedPref = false,
    this.theme = false,
    this.network = false,
    this.apiCache = false,
    this.encryption = false,
    this.connectivity = false,
    this.logger = false,
    this.networkLogs = false,
    this.permissions = false,
  });

  /// Every feature disabled.
  const AppFeatures.none()
    : sharedPref = false,
      theme = false,
      network = false,
      apiCache = false,
      encryption = false,
      connectivity = false,
      logger = false,
      networkLogs = false,
      permissions = false;

  /// Only the given features enabled.
  factory AppFeatures.only(Set<AppFeature> enabled) {
    return AppFeatures(
      sharedPref: enabled.contains(AppFeature.sharedPref),
      theme: enabled.contains(AppFeature.theme),
      network: enabled.contains(AppFeature.network),
      apiCache: enabled.contains(AppFeature.apiCache),
      encryption: enabled.contains(AppFeature.encryption),
      connectivity: enabled.contains(AppFeature.connectivity),
      logger: enabled.contains(AppFeature.logger),
      networkLogs: enabled.contains(AppFeature.networkLogs),
      permissions: enabled.contains(AppFeature.permissions),
    );
  }

  final bool sharedPref;
  final bool theme;
  final bool network;
  final bool apiCache;
  final bool encryption;
  final bool connectivity;
  final bool logger;
  final bool networkLogs;
  final bool permissions;

  bool isEnabled(AppFeature feature) => toMap()[feature]!;

  Map<AppFeature, bool> toMap() => {
    AppFeature.sharedPref: sharedPref,
    AppFeature.theme: theme,
    AppFeature.network: network,
    AppFeature.apiCache: apiCache,
    AppFeature.encryption: encryption,
    AppFeature.connectivity: connectivity,
    AppFeature.logger: logger,
    AppFeature.networkLogs: networkLogs,
    AppFeature.permissions: permissions,
  };

  AppFeatures copyWith({
    bool? sharedPref,
    bool? theme,
    bool? network,
    bool? apiCache,
    bool? encryption,
    bool? connectivity,
    bool? logger,
    bool? networkLogs,
    bool? permissions,
  }) {
    return AppFeatures(
      sharedPref: sharedPref ?? this.sharedPref,
      theme: theme ?? this.theme,
      network: network ?? this.network,
      apiCache: apiCache ?? this.apiCache,
      encryption: encryption ?? this.encryption,
      connectivity: connectivity ?? this.connectivity,
      logger: logger ?? this.logger,
      networkLogs: networkLogs ?? this.networkLogs,
      permissions: permissions ?? this.permissions,
    );
  }

  /// Returns a copy with a single feature changed.
  AppFeatures withFeature(AppFeature feature, bool enabled) {
    final map = toMap()..[feature] = enabled;
    return AppFeatures.only(
      map.entries.where((e) => e.value).map((e) => e.key).toSet(),
    );
  }

  @override
  String toString() =>
      'AppFeatures(${toMap().entries.map((e) => '${e.key.name}: ${e.value}').join(', ')})';
}
