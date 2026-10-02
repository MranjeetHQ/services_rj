import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'security/app_encryption.dart';

/// ---------------------------------------------------------------------------
/// Smart Shared Preference Manager
/// ---------------------------------------------------------------------------
///
/// Features:
/// ✅ Single Initialization
/// ✅ Singleton Memory Management
/// ✅ Dynamic Data Retrieval
/// ✅ Generic Save Support
/// ✅ Model Serialization Support
/// ✅ Common Key Management
/// ✅ Industry Standard Architecture
/// ✅ Lightweight & Scalable
/// ✅ Package Friendly
/// ✅ Transparent AES-256-GCM encryption when the `encryption` feature is on
///
/// ---------------------------------------------------------------------------
/// Usage:
/// ---------------------------------------------------------------------------
///
/// await SharedPrefManager.init();
///
/// await SharedPrefManager.saveData(
///   SharedPrefKeys.userToken,
///   "abc123",
/// );
///
/// final String? token = SharedPrefManager.getData(
///   SharedPrefKeys.userToken,
/// );
///
/// final dynamicData = SharedPrefManager.getData(
///   "custom_key",
/// );
///
/// ---------------------------------------------------------------------------
class SharedPrefManager {
  SharedPrefManager._();

  static SharedPreferences? _preferences;

  static Completer<void>? _completer;

  // ---------------------------------------------------------------------------
  // Initialize SharedPreferences Once
  // ---------------------------------------------------------------------------

  static Future<void> initilization() async {
    if (_preferences != null) return;

    if (_completer != null) {
      return _completer!.future;
    }

    _completer = Completer<void>();

    try {
      _preferences = await SharedPreferences.getInstance();
      _completer!.complete();
    } catch (e, stackTrace) {
      _completer!.completeError(e, stackTrace);
      debugPrint('SharedPref Init Error: $e');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    } finally {
      _completer = null;
    }
  }

  /// Whether [initilization] has completed.
  static bool get isInitialized => _preferences != null;

  static AppEncryption get _crypto => AppEncryption.instance;

  static SharedPreferences get _prefs {
    assert(
      _preferences != null,
      'SharedPrefManager is not initialized.\n'
      'Call SharedPrefManager.init() before using it.',
    );

    return _preferences!;
  }

  // ---------------------------------------------------------------------------
  // Save Data
  // ---------------------------------------------------------------------------

  static Future<bool> saveData(String key, dynamic value) async {
    try {
      if (_crypto.isActive) {
        return await _prefs.setString(key, _crypto.encrypt(_envelope(value)));
      }

      if (value is String) {
        return await _prefs.setString(key, value);
      }

      if (value is int) {
        return await _prefs.setInt(key, value);
      }

      if (value is double) {
        return await _prefs.setDouble(key, value);
      }

      if (value is bool) {
        return await _prefs.setBool(key, value);
      }

      if (value is List<String>) {
        return await _prefs.setStringList(key, value);
      }

      /// Save Map / JSON Serializable Object
      if (value is Map<String, dynamic>) {
        return await _prefs.setString(key, jsonEncode(value));
      }

      throw UnsupportedError('Unsupported value type: ${value.runtimeType}');
    } catch (e, stackTrace) {
      debugPrint('saveData Error: $e');
      debugPrintStack(stackTrace: stackTrace);

      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Get Data Dynamically
  // ---------------------------------------------------------------------------

  static T? getData<T>(String key) {
    try {
      dynamic value = _prefs.get(key);

      if (value == null) return null;

      /// Encrypted value: decrypt and unwrap the typed envelope.
      if (AppEncryption.isEncrypted(value)) {
        if (!_crypto.isInitialized) {
          debugPrint(
            'getData: "$key" is encrypted but encryption is not initialized.',
          );
          return null;
        }
        value = _openEnvelope(_crypto.decrypt(value as String));
        if (value == null) return null;
      }

      /// Direct Type Match
      if (value is T) {
        return value;
      }

      /// Decode JSON String to Map
      if (T == (Map<String, dynamic>) && value is String) {
        return jsonDecode(value) as T;
      }

      return value as T;
    } catch (e, stackTrace) {
      debugPrint('getData Error: $e');
      debugPrintStack(stackTrace: stackTrace);

      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Encryption Migration
  // ---------------------------------------------------------------------------

  /// Re-writes existing plain-text values as encrypted values.
  ///
  /// Run this once after turning on encryption in an app that already
  /// stored data without it. Pass [keys] to limit the migration, for example
  /// when other code reads SharedPreferences directly. Returns the number of
  /// values migrated.
  static Future<int> migrateToEncrypted({Set<String>? keys}) async {
    if (!_crypto.isActive) return 0;

    var migrated = 0;

    for (final key in keys ?? _prefs.getKeys()) {
      final value = _prefs.get(key);
      if (value == null || AppEncryption.isEncrypted(value)) continue;

      final typed = value is List ? value.cast<String>() : value;
      if (await _prefs.setString(key, _crypto.encrypt(_envelope(typed)))) {
        migrated++;
      }
    }

    return migrated;
  }

  // Values are wrapped as {"t": type, "v": value} before encryption so the
  // original Dart type comes back on read.
  static String _envelope(dynamic value) {
    final String type;
    if (value is String) {
      type = 's';
    } else if (value is int) {
      type = 'i';
    } else if (value is double) {
      type = 'd';
    } else if (value is bool) {
      type = 'b';
    } else if (value is List<String>) {
      type = 'l';
    } else if (value is Map<String, dynamic>) {
      type = 'm';
    } else {
      throw UnsupportedError('Unsupported value type: ${value.runtimeType}');
    }
    return jsonEncode({'t': type, 'v': value});
  }

  static dynamic _openEnvelope(String json) {
    final map = jsonDecode(json) as Map<String, dynamic>;
    final v = map['v'];
    switch (map['t']) {
      case 'i':
        return (v as num).toInt();
      case 'd':
        return (v as num).toDouble();
      case 'l':
        return (v as List).cast<String>();
      case 'm':
        return Map<String, dynamic>.from(v as Map);
      default:
        return v;
    }
  }

  // ---------------------------------------------------------------------------
  // Delete Single Key
  // ---------------------------------------------------------------------------

  static Future<bool> delete(String key) async {
    try {
      return await _prefs.remove(key);
    } catch (e, stackTrace) {
      debugPrint('delete Error: $e');
      debugPrintStack(stackTrace: stackTrace);

      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Clear All SharedPreferences Data
  // ---------------------------------------------------------------------------

  static Future<bool> clearAllSharedPrefData() async {
    try {
      return await _prefs.clear();
    } catch (e, stackTrace) {
      debugPrint('clearAllSharedPrefData Error: $e');
      debugPrintStack(stackTrace: stackTrace);

      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Check Key Exists
  // ---------------------------------------------------------------------------

  static bool containsKey(String key) {
    return _prefs.containsKey(key);
  }

  // ---------------------------------------------------------------------------
  // Get All Keys
  // ---------------------------------------------------------------------------

  static Set<String> getKeys() {
    return _prefs.getKeys();
  }

  // ---------------------------------------------------------------------------
  // Reload SharedPreferences
  // ---------------------------------------------------------------------------

  static Future<void> reload() async {
    await _prefs.reload();
  }
}

/// ---------------------------------------------------------------------------
/// Standard SharedPreference Keys
/// ---------------------------------------------------------------------------
///
/// Users can:
/// ✅ Use these default keys
/// ✅ Extend this class
/// ✅ Add their own custom keys
///
/// Example:
///
/// class AppPrefKeys extends SharedPrefKeys {
///   static const userId = "user_id";
/// }
///
/// ---------------------------------------------------------------------------
abstract final class SharedPrefKeys {
  static const String userToken = "AUTH_TOKEN";
  static const String refreshToken = "REFRESH_TOKEN";
  static const String fullName = "FULL_NAME";
  static const String isDemoUser = "IS_DEMO_USER";
  static const String themeMode = 'theme_mode';
}
