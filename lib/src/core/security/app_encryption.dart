import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pointycastle/export.dart';

/// Loads or creates the 256-bit data key.
///
/// The default provider keeps the key in the platform keystore
/// (iOS/macOS Keychain, Android Keystore) through `flutter_secure_storage`.
/// Supply your own to fetch the key from a server or for tests.
typedef EncryptionKeyProvider = Future<Uint8List> Function();

/// AES-256-GCM encryption used for shared preferences and the API cache.
///
/// * The key never touches SharedPreferences or the file system. It lives
///   in the platform keystore and in memory while the app runs.
/// * Every value gets its own random 96-bit nonce.
/// * GCM authenticates the data, so tampered values fail to decrypt instead
///   of returning garbage.
/// * Encryption and decryption are synchronous after [initialize], so reads
///   add no async hop and no UI lag.
class AppEncryption {
  AppEncryption._();

  static final AppEncryption instance = AppEncryption._();

  /// Prefix that marks a string as produced by [encrypt].
  static const String marker = 'enc1:';

  static const String _keyStorageName = 'services_rj_data_key_v1';
  static const int _keyLength = 32;
  static const int _nonceLength = 12;
  static const int _tagBits = 128;

  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
    mOptions: MacOsOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  final Random _random = Random.secure();

  Uint8List? _key;

  Future<void>? _loading;

  EncryptionKeyProvider? _keyProvider;

  /// Applied by [AppController] from the `encryption` feature flag.
  /// Not meant to be set directly by apps.
  bool enabled = true;

  /// Whether a key has been loaded.
  bool get isInitialized => _key != null;

  /// Whether new data is encrypted. False when the feature is disabled or
  /// the key is not loaded.
  bool get isActive => enabled && _key != null;

  /// Loads the data key, creating and storing a new one on first launch.
  ///
  /// Concurrent calls share one load, so two callers can never create two
  /// different keys. The provider is remembered for [destroyKey].
  Future<void> initialize({EncryptionKeyProvider? keyProvider}) {
    if (_key != null) return Future.value();
    if (keyProvider != null) _keyProvider = keyProvider;

    return _loading ??= () async {
      try {
        final key = await (_keyProvider ?? _loadOrCreateKey)();
        if (key.length != _keyLength) {
          throw ArgumentError(
            'Encryption key must be $_keyLength bytes, got ${key.length}.',
          );
        }
        _key = key;
      } finally {
        _loading = null;
      }
    }();
  }

  /// Removes the key and any custom provider from memory. Stored
  /// ciphertext stays on disk.
  void reset() {
    _key = null;
    _keyProvider = null;
  }

  /// Deletes the key from the keystore. Everything encrypted with it becomes
  /// unreadable. Use this for a full "wipe my data" flow.
  ///
  /// With a custom [EncryptionKeyProvider] only the in-memory key is
  /// dropped; the provider owns the stored key.
  Future<void> destroyKey() async {
    _key = null;
    if (_keyProvider == null) {
      await _secureStorage.delete(key: _keyStorageName);
    }
  }

  // ---------------------------------------------------------------------------
  // String API
  // ---------------------------------------------------------------------------

  /// Encrypts [plainText] to a `enc1:`-prefixed base64 string.
  String encrypt(String plainText) {
    return marker + base64Encode(encryptBytes(utf8.encode(plainText)));
  }

  /// Decrypts a value produced by [encrypt].
  ///
  /// Throws [FormatException] if the value is not encrypted and
  /// [StateError] if it was tampered with or encrypted with another key.
  String decrypt(String cipherText) {
    if (!isEncrypted(cipherText)) {
      throw const FormatException('Value is not encrypted.');
    }
    final bytes = base64Decode(cipherText.substring(marker.length));
    return utf8.decode(decryptBytes(bytes));
  }

  /// Whether [value] carries the [marker] prefix.
  static bool isEncrypted(Object? value) =>
      value is String && value.startsWith(marker);

  // ---------------------------------------------------------------------------
  // Bytes API. Layout: nonce(12) | ciphertext | tag(16)
  // ---------------------------------------------------------------------------

  Uint8List encryptBytes(List<int> plain) {
    final key = _requireKey();
    final nonce = _randomBytes(_nonceLength);

    final cipher = GCMBlockCipher(AESEngine())
      ..init(
        true,
        AEADParameters(KeyParameter(key), _tagBits, nonce, Uint8List(0)),
      );

    final sealed = cipher.process(Uint8List.fromList(plain));

    return Uint8List(_nonceLength + sealed.length)
      ..setRange(0, _nonceLength, nonce)
      ..setRange(_nonceLength, _nonceLength + sealed.length, sealed);
  }

  Uint8List decryptBytes(Uint8List data) {
    final key = _requireKey();

    if (data.length < _nonceLength + _tagBits ~/ 8) {
      throw StateError('Encrypted data is too short.');
    }

    final nonce = Uint8List.sublistView(data, 0, _nonceLength);
    final sealed = Uint8List.sublistView(data, _nonceLength);

    final cipher = GCMBlockCipher(AESEngine())
      ..init(
        false,
        AEADParameters(KeyParameter(key), _tagBits, nonce, Uint8List(0)),
      );

    try {
      return cipher.process(sealed);
    } on InvalidCipherTextException {
      throw StateError(
        'Decryption failed: data was modified or encrypted with a different key.',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Hashing (used for cache file names so URLs are not visible on disk)
  // ---------------------------------------------------------------------------

  static String sha256Hex(String input) {
    final digest = SHA256Digest().process(
      Uint8List.fromList(utf8.encode(input)),
    );
    final buffer = StringBuffer();
    for (final b in digest) {
      buffer.write(b.toRadixString(16).padLeft(2, '0'));
    }
    return buffer.toString();
  }

  // ---------------------------------------------------------------------------
  // Private
  // ---------------------------------------------------------------------------

  Uint8List _requireKey() {
    final key = _key;
    if (key == null) {
      throw StateError(
        'AppEncryption is not initialized. Call AppController.initialize() first.',
      );
    }
    return key;
  }

  Uint8List _randomBytes(int length) {
    final bytes = Uint8List(length);
    for (var i = 0; i < length; i++) {
      bytes[i] = _random.nextInt(256);
    }
    return bytes;
  }

  Future<Uint8List> _loadOrCreateKey() async {
    try {
      final stored = await _secureStorage.read(key: _keyStorageName);
      if (stored != null) {
        final key = base64Decode(stored);
        if (key.length == _keyLength) return key;
        throw const FormatException('Stored key has the wrong length.');
      }
    } catch (e) {
      // Typical after an Android backup restore: the preferences come back
      // but the keystore entry does not, and reading throws. Data encrypted
      // with the old key is unreadable either way, so start with a new key
      // instead of failing app start-up.
      debugPrint(
        'AppEncryption: stored key unreadable ($e); creating a new one.',
      );
      try {
        await _secureStorage.delete(key: _keyStorageName);
      } catch (_) {}
    }

    final key = _randomBytes(_keyLength);
    await _secureStorage.write(key: _keyStorageName, value: base64Encode(key));
    return key;
  }
}
