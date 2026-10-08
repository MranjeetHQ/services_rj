import 'package:flutter/material.dart';

import 'app_theme_config.dart';

class AppThemeManager {
  AppThemeManager._();

  static ThemeData lightTheme(AppThemeConfig config) =>
      theme(config, Brightness.light);

  static ThemeData darkTheme(AppThemeConfig config) =>
      theme(config, Brightness.dark);

  /// The theme for [brightness]. [lightTheme] and [darkTheme] call this.
  static ThemeData theme(AppThemeConfig config, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final schemeOverride = isDark
        ? config.darkColorScheme
        : config.lightColorScheme;
    final scaffoldColor = isDark
        ? config.darkScaffoldColor
        : config.lightScaffoldColor;
    final backgroundColor = isDark
        ? config.darkBackgroundColor
        : config.lightBackgroundColor;
    final surfaceColor = isDark
        ? config.darkSurfaceColor
        : config.lightSurfaceColor;

    final base = ThemeData(
      brightness: schemeOverride == null ? brightness : null,
      useMaterial3: config.useMaterial3,
      colorScheme: schemeOverride,
      colorSchemeSeed: schemeOverride == null ? config.seedColor : null,
      fontFamily: config.fontFamily,
      scaffoldBackgroundColor: scaffoldColor,
      visualDensity: config.visualDensity,
      extensions: config.extensions,
    );

    final colorScheme = base.colorScheme;
    final radius = BorderRadius.circular(config.borderRadius);

    final themed = base.copyWith(
      textTheme: config.textTheme == null
          ? null
          : base.textTheme.merge(config.textTheme),

      // ── Canvas / background ──────────────────────────────────────────────
      canvasColor: backgroundColor ?? colorScheme.surface,
      cardColor: surfaceColor ?? colorScheme.surface,

      // ── AppBar ───────────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: scaffoldColor ?? colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: config.appBarElevation,
        centerTitle: config.appBarCenterTitle,
      ),

      // ── Bottom Navigation ────────────────────────────────────────────────
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surfaceColor ?? colorScheme.surface,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurface.withValues(alpha: 0.6),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      // ── Card ────────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        color: surfaceColor ?? colorScheme.surface,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(config.effectiveCardRadius),
        ),
      ),

      // ── Elevated Button ─────────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: config.elevatedButtonElevation,
          textStyle: config.elevatedButtonTextStyle,
          shape: RoundedRectangleBorder(borderRadius: radius),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),

      // ── Outlined Button ─────────────────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: config.outlinedButtonSideColor ?? colorScheme.primary,
            width: config.outlinedButtonSideWidth ?? 1.5,
          ),
          textStyle: config.outlinedButtonTextStyle,
          shape: RoundedRectangleBorder(borderRadius: radius),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),

      // ── Text Button ─────────────────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: config.textButtonTextStyle,
          shape: RoundedRectangleBorder(borderRadius: radius),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),

      // ── Icon Theme ──────────────────────────────────────────────────────
      iconTheme: IconThemeData(
        color: config.iconThemeColor ?? colorScheme.onSurface,
        size: 24,
      ),

      // ── Input Decoration ────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: config.inputFilled,
        fillColor: surfaceColor ?? colorScheme.surface,
        border: OutlineInputBorder(borderRadius: radius),
        enabledBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),

      // ── Chip ────────────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: radius),
      ),

      // ── Dialog ──────────────────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: radius),
      ),
    );

    return config.customize?.call(themed, brightness) ?? themed;
  }
}
