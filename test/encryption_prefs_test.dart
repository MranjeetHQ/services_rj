import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:services_rj/services_rj.dart';
import 'package:shared_preferences/shared_preferences.dart';

Uint8List key(int seed) =>
    Uint8List.fromList(List.generate(32, (i) => (i + seed) % 256));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final crypto = AppEncryption.instance;
  late SharedPreferences raw;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({
      'legacy_plain': 'hello',
      'legacy_int': 7,
    });
    await AppController.initialize(
      features: const AppFeatures(network: false, connectivity: false),
      encryptionKeyProvider: () async => key(0),
    );
    raw = await SharedPreferences.getInstance();
  });

  group('AppEncryption', () {
    test('round-trips text, including unicode', () {
      const text = 'token: abc123 ✓ नमस्ते';
      expect(crypto.decrypt(crypto.encrypt(text)), text);
    });

    test('same input gives different ciphertext each time', () {
      expect(crypto.encrypt('same'), isNot(crypto.encrypt('same')));
    });

    test('tampered ciphertext fails loudly', () {
      final c = crypto.encrypt('value');
      final flipped =
          c.substring(0, c.length - 3) +
          (c[c.length - 3] == 'A' ? 'B' : 'A') +
          c.substring(c.length - 2);
      expect(() => crypto.decrypt(flipped), throwsStateError);
    });

    test('a different key cannot decrypt', () async {
      final c = crypto.encrypt('value');
      crypto.reset();
      await crypto.initialize(keyProvider: () async => key(1));
      expect(() => crypto.decrypt(c), throwsStateError);
      crypto.reset();
      await crypto.initialize(keyProvider: () async => key(0));
    });

    test('wrong key length is rejected', () async {
      crypto.reset();
      await expectLater(
        crypto.initialize(keyProvider: () async => Uint8List(16)),
        throwsArgumentError,
      );
      await crypto.initialize(keyProvider: () async => key(0));
    });
  });

  group('SharedPrefManager with encryption', () {
    test('every supported type round-trips and is stored encrypted', () async {
      final values = <String, dynamic>{
        's': 'secret',
        'i': 42,
        'd': 3.5,
        'b': true,
        'l': ['a', 'b'],
        'm': {'id': 1, 'name': 'Ranjit'},
      };
      for (final e in values.entries) {
        expect(await SharedPrefManager.saveData('t_${e.key}', e.value), isTrue);
        expect(
          AppEncryption.isEncrypted(raw.get('t_${e.key}')),
          isTrue,
          reason: e.key,
        );
      }
      expect(SharedPrefManager.getData<String>('t_s'), 'secret');
      expect(SharedPrefManager.getData<int>('t_i'), 42);
      expect(SharedPrefManager.getData<double>('t_d'), 3.5);
      expect(SharedPrefManager.getData<bool>('t_b'), true);
      expect(SharedPrefManager.getData<List<String>>('t_l'), ['a', 'b']);
      expect(SharedPrefManager.getData<Map<String, dynamic>>('t_m'), {
        'id': 1,
        'name': 'Ranjit',
      });
      expect((raw.get('t_s') as String).contains('secret'), isFalse);
    });

    test('whole-number doubles keep their type', () async {
      await SharedPrefManager.saveData('t_d2', 2.0);
      expect(SharedPrefManager.getData<double>('t_d2'), 2.0);
    });

    test('auth token is encrypted at rest', () async {
      await AuthTokenService.instance.saveToken('jwt-abc');
      expect(AuthTokenService.instance.token, 'jwt-abc');
      expect(
        (raw.get(SharedPrefKeys.userToken) as String).contains('jwt'),
        isFalse,
      );
    });

    test('plain values written before encryption still read', () {
      expect(SharedPrefManager.getData<String>('legacy_plain'), 'hello');
      expect(SharedPrefManager.getData<int>('legacy_int'), 7);
    });

    test(
      'migrateToEncrypted converts plain values and keeps them readable',
      () async {
        final count = await SharedPrefManager.migrateToEncrypted(
          keys: {'legacy_plain', 'legacy_int'},
        );
        expect(count, 2);
        expect(AppEncryption.isEncrypted(raw.get('legacy_plain')), isTrue);
        expect(SharedPrefManager.getData<String>('legacy_plain'), 'hello');
        expect(SharedPrefManager.getData<int>('legacy_int'), 7);
        expect(
          await SharedPrefManager.migrateToEncrypted(keys: {'legacy_plain'}),
          0,
        );
      },
    );

    test('unreadable value returns null instead of crashing', () async {
      await raw.setString('broken', '${AppEncryption.marker}not-base64!!');
      expect(SharedPrefManager.getData<String>('broken'), isNull);
    });

    test('theme mode persists through encrypted prefs', () async {
      await AppThemeController.instance.setThemeMode(ThemeMode.dark);
      expect(
        AppEncryption.isEncrypted(raw.get(SharedPrefKeys.themeMode)),
        isTrue,
      );
      await AppThemeController.instance.initialize();
      expect(AppThemeController.instance.themeMode, ThemeMode.dark);
    });

    test('with encryption switched off values are stored plain', () async {
      crypto.enabled = false;
      await SharedPrefManager.saveData('t_plain', 'visible');
      expect(raw.get('t_plain'), 'visible');
      crypto.enabled = true;
    });
  });
}
