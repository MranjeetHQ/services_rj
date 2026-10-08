import 'package:flutter/material.dart';

/// App-wide navigator and scaffold messenger keys, so code without a
/// [BuildContext] (services, controllers, API callbacks) can navigate or show
/// a snackbar.
///
/// `ServicesApp` attaches these keys by default. With a plain `MaterialApp`,
/// pass them yourself:
///
/// ```dart
/// MaterialApp(
///   navigatorKey: AppKeys.navigatorKey,
///   scaffoldMessengerKey: AppKeys.scaffoldMessengerKey,
/// );
///
/// AppKeys.navigator?.pushNamed('/login');
/// AppKeys.messenger?.showSnackBar(const SnackBar(content: Text('Saved')));
/// ```
abstract final class AppKeys {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'AppKeys.navigator');

  static final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>(debugLabel: 'AppKeys.messenger');

  /// The root navigator, or null before the app is built or when the keys
  /// are not attached.
  static NavigatorState? get navigator => navigatorKey.currentState;

  /// The root scaffold messenger, or null when it is not attached.
  static ScaffoldMessengerState? get messenger =>
      scaffoldMessengerKey.currentState;

  /// A context below the root navigator, for dialogs and `Theme.of`.
  static BuildContext? get context => navigatorKey.currentContext;
}
