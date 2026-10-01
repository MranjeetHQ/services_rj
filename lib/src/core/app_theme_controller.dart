import 'package:flutter/material.dart';

import 'shared_pref_manager.dart';

class AppThemeController extends ChangeNotifier {
  AppThemeController._();

  static final AppThemeController instance = AppThemeController._();

  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  bool get isLightMode => _themeMode == ThemeMode.light;

  bool get isSystemMode => _themeMode == ThemeMode.system;

  Future<void> initialize() async {
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

      default:
        _themeMode = ThemeMode.system;
    }
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
}
