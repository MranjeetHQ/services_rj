import 'package:flutter/material.dart';

import 'app_theme_config.dart';
import 'app_theme_manager.dart';
import 'shared_pref_manager.dart';

/// Holds the app's [AppThemeConfig], the current [ThemeMode] and an optional
/// user-picked accent colour, and builds the light and dark themes from them.
///
/// The theme mode and accent colour are saved when shared preferences are
/// initialized. `ServicesApp` listens to this controller; with a plain
/// `MaterialApp`, wrap it in a `ListenableBuilder` and use [lightTheme],
/// [darkTheme] and [themeMode].
class AppThemeController extends ChangeNotifier {
  AppThemeController._();

  static final AppThemeController instance = AppThemeController._();

  AppThemeConfig _config = const AppThemeConfig();

  ThemeMode _themeMode = ThemeMode.system;

  Color? _seedColor;

  ThemeData? _light;

  ThemeData? _dark;

  /// The config the themes are built from.
  AppThemeConfig get config => _config;

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  bool get isLightMode => _themeMode == ThemeMode.light;

  bool get isSystemMode => _themeMode == ThemeMode.system;

  /// The accent colour in use: the one set with [setSeedColor], otherwise
  /// [AppThemeConfig.seedColor].
  Color get seedColor => _seedColor ?? _config.seedColor;

  /// Whether the user picked an accent colour with [setSeedColor].
  bool get hasCustomSeedColor => _seedColor != null;

  /// The light theme for the current config and accent colour.
  ThemeData get lightTheme =>
      _light ??= AppThemeManager.lightTheme(_effectiveConfig);

  /// The dark theme for the current config and accent colour.
  ThemeData get darkTheme =>
      _dark ??= AppThemeManager.darkTheme(_effectiveConfig);

  /// Sets [config] (when given) and restores the saved theme mode and accent
  /// colour. Without a saved mode, [AppThemeConfig.initialThemeMode] is used.
  Future<void> initialize({AppThemeConfig? config}) async {
    if (config != null) _config = config;
    _themeMode = _config.initialThemeMode;
    _invalidate();

    // Without the sharedPref feature the theme works but is not persisted.
    if (!SharedPrefManager.isInitialized) return;

    final savedTheme = SharedPrefManager.getData<String>(
      SharedPrefKeys.themeMode,
    );

    switch (savedTheme) {
      case 'light':
        _themeMode = ThemeMode.light;
        break;

      case 'dark':
        _themeMode = ThemeMode.dark;
        break;

      case 'system':
        _themeMode = ThemeMode.system;
        break;
    }

    final savedSeed = SharedPrefManager.getData<int>(
      SharedPrefKeys.themeSeedColor,
    );
    if (savedSeed != null) _seedColor = Color(savedSeed);
  }

  /// Replaces the config at runtime, for example to switch brands. The saved
  /// theme mode and accent colour are kept.
  void setConfig(AppThemeConfig config) {
    _config = config;
    _invalidate();
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;

    if (SharedPrefManager.isInitialized) {
      await SharedPrefManager.saveData(SharedPrefKeys.themeMode, mode.name);
    }

    notifyListeners();
  }

  Future<void> toggleTheme() async {
    if (_themeMode == ThemeMode.dark) {
      await setThemeMode(ThemeMode.light);
    } else {
      await setThemeMode(ThemeMode.dark);
    }
  }

  /// Uses [color] as the accent colour instead of [AppThemeConfig.seedColor]
  /// and saves it. Pass `null` to go back to the config's colour.
  Future<void> setSeedColor(Color? color) async {
    _seedColor = color;
    _invalidate();

    if (SharedPrefManager.isInitialized) {
      if (color == null) {
        await SharedPrefManager.delete(SharedPrefKeys.themeSeedColor);
      } else {
        await SharedPrefManager.saveData(
          SharedPrefKeys.themeSeedColor,
          color.toARGB32(),
        );
      }
    }

    notifyListeners();
  }

  /// Forgets the user's theme mode and accent colour and returns to the
  /// config's defaults.
  Future<void> resetToDefaults() async {
    _themeMode = _config.initialThemeMode;
    _seedColor = null;
    _invalidate();

    if (SharedPrefManager.isInitialized) {
      await SharedPrefManager.delete(SharedPrefKeys.themeMode);
      await SharedPrefManager.delete(SharedPrefKeys.themeSeedColor);
    }

    notifyListeners();
  }

  /// Restores the initial in-memory state without touching storage. Used by
  /// `AppController.resetForTest`; tests only.
  void resetForTest() {
    _config = const AppThemeConfig();
    _themeMode = ThemeMode.system;
    _seedColor = null;
    _invalidate();
  }

  AppThemeConfig get _effectiveConfig =>
      _seedColor == null ? _config : _config.copyWith(seedColor: _seedColor);

  void _invalidate() {
    _light = null;
    _dark = null;
  }
}
