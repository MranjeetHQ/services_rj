import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

import 'app_logger.dart';

class AppConnectivity {
  AppConnectivity._();

  static final Connectivity _connectivity = Connectivity();

  static StreamSubscription<List<ConnectivityResult>>? _subscription;

  static bool? _isOnline;

  static bool _enabled = true;

  /// Controlled by [AppController] through the `connectivity` feature.
  /// When disabled the device is treated as always online.
  static bool get enabled => _enabled;
  static set enabled(bool value) {
    _enabled = value;
    if (value) {
      startMonitoring();
    } else {
      stopMonitoring();
      _isOnline = null;
    }
  }

  static Stream<List<ConnectivityResult>> get stream =>
      _enabled ? _connectivity.onConnectivityChanged : const Stream.empty();

  /// Last known state, updated in the background. `null` until known or
  /// when the feature is disabled.
  static bool? get isOnline => _isOnline;

  /// `true` only when monitoring is on and the device is known to be offline.
  /// Read synchronously by the API cache to skip doomed requests.
  static bool get isKnownOffline => _enabled && _isOnline == false;

  static Future<bool> hasInternet() async {
    if (!_enabled) return true;

    final result = await _connectivity.checkConnectivity();
    _isOnline = !result.contains(ConnectivityResult.none);
    return _isOnline!;
  }

  /// Starts tracking connectivity so [isOnline] stays current.
  static Future<void> startMonitoring() async {
    if (!_enabled || _subscription != null) return;

    _subscription = _connectivity.onConnectivityChanged.listen(
      (result) => _isOnline = !result.contains(ConnectivityResult.none),
      onError: (Object e) => AppLogger.warning('Connectivity error: $e'),
    );

    try {
      await hasInternet();
    } catch (e) {
      AppLogger.warning('Connectivity check failed: $e');
    }
  }

  static Future<void> stopMonitoring() async {
    await _subscription?.cancel();
    _subscription = null;
  }
}
