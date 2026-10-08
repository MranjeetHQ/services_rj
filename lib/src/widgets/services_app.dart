import 'package:flutter/material.dart';

import '../core/app_keys.dart';
import '../core/app_theme_controller.dart';

/// A [MaterialApp] already wired to `services_rj`.
///
/// * Themes and theme mode come from [AppThemeController], so the
///   `themeConfig` passed to `AppController.initialize`, the saved theme mode
///   and the user's accent colour apply, and the app rebuilds when they
///   change.
/// * [AppKeys.navigatorKey] and [AppKeys.scaffoldMessengerKey] are attached.
/// * The debug banner is off.
///
/// Every common [MaterialApp] option is available; pass [theme],
/// [darkTheme] or [themeMode] to override the controller.
///
/// ```dart
/// await AppController.initialize(
///   features: const AppFeatures(sharedPref: true, theme: true),
///   themeConfig: const AppThemeConfig(seedColor: Colors.indigo),
/// );
/// runApp(const ServicesApp(title: 'My app', home: HomePage()));
/// ```
class ServicesApp extends StatelessWidget {
  /// An app that uses a [Navigator] with [home], [routes] or
  /// [onGenerateRoute].
  const ServicesApp({
    super.key,
    this.title = '',
    this.onGenerateTitle,
    this.home,
    this.routes = const {},
    this.initialRoute,
    this.onGenerateRoute,
    this.onUnknownRoute,
    this.navigatorObservers = const [],
    this.navigatorKey,
    this.scaffoldMessengerKey,
    this.builder,
    this.theme,
    this.darkTheme,
    this.themeMode,
    this.locale,
    this.supportedLocales = const [Locale('en', 'US')],
    this.localizationsDelegates,
    this.localeResolutionCallback,
    this.debugShowCheckedModeBanner = false,
    this.scrollBehavior,
  }) : routerConfig = null;

  /// An app driven by a [RouterConfig], such as one from go_router.
  const ServicesApp.router({
    super.key,
    required RouterConfig<Object> this.routerConfig,
    this.title = '',
    this.onGenerateTitle,
    this.scaffoldMessengerKey,
    this.builder,
    this.theme,
    this.darkTheme,
    this.themeMode,
    this.locale,
    this.supportedLocales = const [Locale('en', 'US')],
    this.localizationsDelegates,
    this.localeResolutionCallback,
    this.debugShowCheckedModeBanner = false,
    this.scrollBehavior,
  }) : home = null,
       routes = const {},
       initialRoute = null,
       onGenerateRoute = null,
       onUnknownRoute = null,
       navigatorObservers = const [],
       navigatorKey = null;

  final String title;
  final GenerateAppTitle? onGenerateTitle;

  final Widget? home;
  final Map<String, WidgetBuilder> routes;
  final String? initialRoute;
  final RouteFactory? onGenerateRoute;
  final RouteFactory? onUnknownRoute;
  final List<NavigatorObserver> navigatorObservers;

  /// Set by [ServicesApp.router]; null otherwise.
  final RouterConfig<Object>? routerConfig;

  /// Defaults to [AppKeys.navigatorKey]. Not used by [ServicesApp.router],
  /// where the router owns the navigator.
  final GlobalKey<NavigatorState>? navigatorKey;

  /// Defaults to [AppKeys.scaffoldMessengerKey].
  final GlobalKey<ScaffoldMessengerState>? scaffoldMessengerKey;

  /// Wraps every route, for app-wide overlays or a [MediaQuery] override.
  final TransitionBuilder? builder;

  /// Replaces [AppThemeController.lightTheme].
  final ThemeData? theme;

  /// Replaces [AppThemeController.darkTheme].
  final ThemeData? darkTheme;

  /// Replaces [AppThemeController.themeMode].
  final ThemeMode? themeMode;

  final Locale? locale;
  final Iterable<Locale> supportedLocales;
  final Iterable<LocalizationsDelegate<dynamic>>? localizationsDelegates;
  final LocaleResolutionCallback? localeResolutionCallback;
  final bool debugShowCheckedModeBanner;
  final ScrollBehavior? scrollBehavior;

  @override
  Widget build(BuildContext context) {
    final controller = AppThemeController.instance;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final light = theme ?? controller.lightTheme;
        final dark = darkTheme ?? controller.darkTheme;
        final mode = themeMode ?? controller.themeMode;
        final messengerKey =
            scaffoldMessengerKey ?? AppKeys.scaffoldMessengerKey;

        final router = routerConfig;
        if (router != null) {
          return MaterialApp.router(
            routerConfig: router,
            scaffoldMessengerKey: messengerKey,
            title: title,
            onGenerateTitle: onGenerateTitle,
            builder: builder,
            theme: light,
            darkTheme: dark,
            themeMode: mode,
            locale: locale,
            supportedLocales: supportedLocales,
            localizationsDelegates: localizationsDelegates,
            localeResolutionCallback: localeResolutionCallback,
            debugShowCheckedModeBanner: debugShowCheckedModeBanner,
            scrollBehavior: scrollBehavior,
          );
        }

        return MaterialApp(
          navigatorKey: navigatorKey ?? AppKeys.navigatorKey,
          scaffoldMessengerKey: messengerKey,
          title: title,
          onGenerateTitle: onGenerateTitle,
          home: home,
          routes: routes,
          initialRoute: initialRoute,
          onGenerateRoute: onGenerateRoute,
          onUnknownRoute: onUnknownRoute,
          navigatorObservers: navigatorObservers,
          builder: builder,
          theme: light,
          darkTheme: dark,
          themeMode: mode,
          locale: locale,
          supportedLocales: supportedLocales,
          localizationsDelegates: localizationsDelegates,
          localeResolutionCallback: localeResolutionCallback,
          debugShowCheckedModeBanner: debugShowCheckedModeBanner,
          scrollBehavior: scrollBehavior,
        );
      },
    );
  }
}
