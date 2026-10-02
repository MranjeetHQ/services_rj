import 'package:flutter/material.dart';

import 'app_theme_config.dart';

class AppThemeManager {
  AppThemeManager._();

  static ThemeData lightTheme(AppThemeConfig config) {
    final base = ThemeData(
      brightness: Brightness.light,
      useMaterial3: config.useMaterial3,
      colorSchemeSeed: config.seedColor,
      fontFamily: config.fontFamily,
      scaffoldBackgroundColor: config.lightScaffoldColor,
    );

    final colorScheme = base.colorScheme;

    return base.copyWith(
      // ── Canvas / background ──────────────────────────────────────────────
      canvasColor: config.lightBackgroundColor ?? colorScheme.surface,
      cardColor: config.lightSurfaceColor ?? colorScheme.surface,

      // ── AppBar ───────────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: config.lightScaffoldColor ?? colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        centerTitle: true,
      ),

      // ── Bottom Navigation ────────────────────────────────────────────────
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: config.lightSurfaceColor ?? colorScheme.surface,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurface.withValues(alpha: 0.6),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      // ── Card ────────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        color: config.lightSurfaceColor ?? colorScheme.surface,
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(config.borderRadius),
          ),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(config.borderRadius),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),

      // ── Text Button ─────────────────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: config.textButtonTextStyle,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(config.borderRadius),
          ),
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
        filled: true,
        fillColor: config.lightSurfaceColor ?? colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(config.borderRadius),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(config.borderRadius),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(config.borderRadius),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),

      // ── Chip ────────────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(config.borderRadius),
        ),
      ),

      // ── Dialog ──────────────────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(config.borderRadius),
        ),
      ),
    );
  }

  static ThemeData darkTheme(AppThemeConfig config) {
    final base = ThemeData(
      brightness: Brightness.dark,
      useMaterial3: config.useMaterial3,
      colorSchemeSeed: config.seedColor,
      fontFamily: config.fontFamily,
      scaffoldBackgroundColor: config.darkScaffoldColor,
    );

    final colorScheme = base.colorScheme;

    return base.copyWith(
      // ── Canvas / background ──────────────────────────────────────────────
      canvasColor: config.darkBackgroundColor ?? colorScheme.surface,
      cardColor: config.darkSurfaceColor ?? colorScheme.surface,

      // ── AppBar ───────────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: config.darkScaffoldColor ?? colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        centerTitle: true,
      ),

      // ── Bottom Navigation ────────────────────────────────────────────────
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: config.darkSurfaceColor ?? colorScheme.surface,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurface.withValues(alpha: 0.6),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      // ── Card ────────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        color: config.darkSurfaceColor ?? colorScheme.surface,
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(config.borderRadius),
          ),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(config.borderRadius),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),

      // ── Text Button ─────────────────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: config.textButtonTextStyle,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(config.borderRadius),
          ),
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
        filled: true,
        fillColor: config.darkSurfaceColor ?? colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(config.borderRadius),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(config.borderRadius),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(config.borderRadius),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),

      // ── Chip ────────────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(config.borderRadius),
        ),
      ),

      // ── Dialog ──────────────────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(config.borderRadius),
        ),
      ),
    );
  }
}
