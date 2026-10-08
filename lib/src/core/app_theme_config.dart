import 'package:flutter/material.dart';

/// Signature of [AppThemeConfig.customize].
typedef ThemeCustomizer =
    ThemeData Function(ThemeData theme, Brightness brightness);

/// Describes the app's look once; [AppThemeManager] turns it into light and
/// dark [ThemeData].
///
/// Every field is optional. Pass the config to `AppController.initialize`
/// (as `themeConfig`) and use `ServicesApp`, or build the themes yourself
/// with [AppThemeManager.lightTheme] and [AppThemeManager.darkTheme].
class AppThemeConfig {
  const AppThemeConfig({
    this.seedColor = Colors.blue,
    this.useMaterial3 = true,
    this.initialThemeMode = ThemeMode.system,
    this.lightColorScheme,
    this.darkColorScheme,
    this.borderRadius = 12.0,
    this.cardRadius,
    this.fontFamily,
    this.textTheme,
    this.visualDensity,
    this.lightScaffoldColor,
    this.darkScaffoldColor,
    this.lightBackgroundColor,
    this.darkBackgroundColor,
    this.lightSurfaceColor,
    this.darkSurfaceColor,
    this.appBarCenterTitle = true,
    this.appBarElevation = 0,
    this.inputFilled = true,
    this.outlinedButtonSideWidth,
    this.outlinedButtonSideColor,
    this.elevatedButtonElevation,
    this.elevatedButtonTextStyle,
    this.outlinedButtonTextStyle,
    this.textButtonTextStyle,
    this.iconThemeColor,
    this.extensions = const [],
    this.customize,
  });

  // ── Core colours ──────────────────────────────────────────────────────────

  final Color seedColor;
  final bool useMaterial3;

  /// Theme mode used on first launch, before the user has picked one.
  /// A mode saved with `AppThemeController.setThemeMode` wins over this.
  final ThemeMode initialThemeMode;

  /// Replaces the scheme generated from [seedColor] in light mode.
  final ColorScheme? lightColorScheme;

  /// Replaces the scheme generated from [seedColor] in dark mode.
  final ColorScheme? darkColorScheme;

  // ── Radii ─────────────────────────────────────────────────────────────────

  final double borderRadius;
  final double? cardRadius;

  // ── Typography & density ──────────────────────────────────────────────────

  final String? fontFamily;

  /// Merged over the default text theme, so only the styles you set change.
  final TextTheme? textTheme;

  final VisualDensity? visualDensity;

  // ── Background / Surface ──────────────────────────────────────────────────

  final Color? lightScaffoldColor;
  final Color? darkScaffoldColor;

  final Color? lightBackgroundColor;
  final Color? darkBackgroundColor;

  final Color? lightSurfaceColor;
  final Color? darkSurfaceColor;

  // ── AppBar & inputs ───────────────────────────────────────────────────────

  final bool appBarCenterTitle;
  final double appBarElevation;

  /// Whether text fields get a filled background.
  final bool inputFilled;

  // ── Buttons ───────────────────────────────────────────────────────────────

  final double? elevatedButtonElevation;

  final double? outlinedButtonSideWidth;
  final Color? outlinedButtonSideColor;

  final TextStyle? elevatedButtonTextStyle;
  final TextStyle? outlinedButtonTextStyle;
  final TextStyle? textButtonTextStyle;

  // ── Misc ──────────────────────────────────────────────────────────────────

  final Color? iconThemeColor;

  /// Custom design tokens, read with `Theme.of(context).extension<T>()`.
  final List<ThemeExtension<dynamic>> extensions;

  /// Runs last on both themes, for anything the config does not cover:
  ///
  /// ```dart
  /// AppThemeConfig(
  ///   customize: (theme, brightness) => theme.copyWith(
  ///     dividerTheme: const DividerThemeData(thickness: 2),
  ///   ),
  /// )
  /// ```
  final ThemeCustomizer? customize;

  // ── Convenience helpers ───────────────────────────────────────────────────

  double get effectiveCardRadius => cardRadius ?? borderRadius;

  AppThemeConfig copyWith({
    Color? seedColor,
    bool? useMaterial3,
    ThemeMode? initialThemeMode,
    ColorScheme? lightColorScheme,
    ColorScheme? darkColorScheme,
    double? borderRadius,
    double? cardRadius,
    String? fontFamily,
    TextTheme? textTheme,
    VisualDensity? visualDensity,
    Color? lightScaffoldColor,
    Color? darkScaffoldColor,
    Color? lightBackgroundColor,
    Color? darkBackgroundColor,
    Color? lightSurfaceColor,
    Color? darkSurfaceColor,
    bool? appBarCenterTitle,
    double? appBarElevation,
    bool? inputFilled,
    double? outlinedButtonSideWidth,
    Color? outlinedButtonSideColor,
    double? elevatedButtonElevation,
    TextStyle? elevatedButtonTextStyle,
    TextStyle? outlinedButtonTextStyle,
    TextStyle? textButtonTextStyle,
    Color? iconThemeColor,
    List<ThemeExtension<dynamic>>? extensions,
    ThemeCustomizer? customize,
  }) {
    return AppThemeConfig(
      seedColor: seedColor ?? this.seedColor,
      useMaterial3: useMaterial3 ?? this.useMaterial3,
      initialThemeMode: initialThemeMode ?? this.initialThemeMode,
      lightColorScheme: lightColorScheme ?? this.lightColorScheme,
      darkColorScheme: darkColorScheme ?? this.darkColorScheme,
      borderRadius: borderRadius ?? this.borderRadius,
      cardRadius: cardRadius ?? this.cardRadius,
      fontFamily: fontFamily ?? this.fontFamily,
      textTheme: textTheme ?? this.textTheme,
      visualDensity: visualDensity ?? this.visualDensity,
      lightScaffoldColor: lightScaffoldColor ?? this.lightScaffoldColor,
      darkScaffoldColor: darkScaffoldColor ?? this.darkScaffoldColor,
      lightBackgroundColor: lightBackgroundColor ?? this.lightBackgroundColor,
      darkBackgroundColor: darkBackgroundColor ?? this.darkBackgroundColor,
      lightSurfaceColor: lightSurfaceColor ?? this.lightSurfaceColor,
      darkSurfaceColor: darkSurfaceColor ?? this.darkSurfaceColor,
      appBarCenterTitle: appBarCenterTitle ?? this.appBarCenterTitle,
      appBarElevation: appBarElevation ?? this.appBarElevation,
      inputFilled: inputFilled ?? this.inputFilled,
      outlinedButtonSideWidth:
          outlinedButtonSideWidth ?? this.outlinedButtonSideWidth,
      outlinedButtonSideColor:
          outlinedButtonSideColor ?? this.outlinedButtonSideColor,
      elevatedButtonElevation:
          elevatedButtonElevation ?? this.elevatedButtonElevation,
      elevatedButtonTextStyle:
          elevatedButtonTextStyle ?? this.elevatedButtonTextStyle,
      outlinedButtonTextStyle:
          outlinedButtonTextStyle ?? this.outlinedButtonTextStyle,
      textButtonTextStyle: textButtonTextStyle ?? this.textButtonTextStyle,
      iconThemeColor: iconThemeColor ?? this.iconThemeColor,
      extensions: extensions ?? this.extensions,
      customize: customize ?? this.customize,
    );
  }
}
