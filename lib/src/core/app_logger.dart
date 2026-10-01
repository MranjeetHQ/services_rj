import 'dart:developer';

import 'package:flutter/foundation.dart';

class AppLogger {
  AppLogger._();

  /// Controlled by [AppController] through the `logger` feature.
  static bool enabled = true;

  static bool get _active => enabled && kDebugMode;

  static void info(dynamic message) {
    if (_active) {
      log(message.toString(), name: 'INFO');
    }
  }

  static void error(dynamic message, {StackTrace? stackTrace}) {
    if (_active) {
      log(message.toString(), name: 'ERROR', stackTrace: stackTrace);
    }
  }

  static void warning(dynamic message) {
    if (_active) {
      log(message.toString(), name: 'WARNING');
    }
  }
}
