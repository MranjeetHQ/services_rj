import 'package:flutter_test/flutter_test.dart';
import 'package:services_rj/services_rj.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppFeatures', () {
    test('features are disabled by default', () {
      const f = AppFeatures();
      for (final feature in AppFeature.values) {
        expect(f.isEnabled(feature), isFalse, reason: feature.name);
      }
    });

    test('none, only and withFeature', () {
      expect(
        AppFeature.values.any(const AppFeatures.none().isEnabled),
        isFalse,
      );
      final only = AppFeatures.only({AppFeature.theme});
      expect(only.theme, isTrue);
      expect(only.network, isFalse);
      expect(only.withFeature(AppFeature.logger, true).logger, isTrue);
      expect(
        const AppFeatures().withFeature(AppFeature.logger, false).logger,
        isFalse,
      );
    });

    test('toMap covers every feature', () {
      expect(
        const AppFeatures().toMap().keys.toSet(),
        AppFeature.values.toSet(),
      );
    });
  });

  group('AppController', () {
    final c = AppController.instance;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      c.resetForTest();
    });

    test('network without ApiConfig is skipped, not a crash', () async {
      await c.initialize_(
        const AppFeatures(sharedPref: true, theme: true, network: true),
      );
      expect(c.isEnabled(AppFeature.network), isTrue);
      expect(c.isReady(AppFeature.network), isFalse);
      expect(c.isReady(AppFeature.apiCache), isFalse);
      expect(() => c.api, throwsStateError);
      expect(c.isReady(AppFeature.sharedPref), isTrue);
      expect(c.isReady(AppFeature.theme), isTrue);
    });

    test('default initialization succeeds without enabling features', () async {
      await AppController.initialize();
      expect(c.isInitialized, isTrue);
      expect(AppFeature.values.any(c.isReady), isFalse);
      expect(c.isReady(AppFeature.network), isFalse);
    });

    test(
      'disabled features are not started and their accessors throw',
      () async {
        await c.initialize_(AppFeatures.only({AppFeature.sharedPref}));
        expect(c.isReady(AppFeature.theme), isFalse);
        expect(() => c.theme, throwsStateError);
        expect(() => c.permissions, throwsStateError);
        expect(() => c.encryption, throwsStateError);
        expect(AppLogger.enabled, isFalse);
        expect(AppPermissionManager.instance.enabled, isFalse);
      },
    );

    test('second initialize is ignored', () async {
      await c.initialize_(const AppFeatures(theme: true));
      await c.initialize_(const AppFeatures.none());
      expect(c.isEnabled(AppFeature.theme), isTrue);
    });

    test('only runtime-safe features can be switched later', () async {
      await c.initialize_(const AppFeatures(logger: true));
      expect(
        () => c.setEnabled(AppFeature.encryption, false),
        throwsStateError,
      );
      expect(
        () => c.setEnabled(AppFeature.sharedPref, false),
        throwsStateError,
      );

      var notified = 0;
      void listener() => notified++;
      c.addListener(listener);
      await c.setEnabled(AppFeature.logger, false);
      expect(AppLogger.enabled, isFalse);
      expect(c.isReady(AppFeature.logger), isFalse);
      await c.setEnabled(AppFeature.logger, true);
      expect(c.isReady(AppFeature.logger), isTrue);
      expect(notified, 2);
      c.removeListener(listener);
    });

    test('connectivity on in a test host does not crash', () async {
      await c.initialize_(const AppFeatures(connectivity: true));
      expect(c.isReady(AppFeature.connectivity), isTrue);
    });

    test('theme without sharedPref works in memory', () async {
      await c.initialize_(AppFeatures.only({AppFeature.theme}));
      await c.theme.toggleTheme();
      expect(c.theme.isDarkMode, isTrue);
    });
  });

  test('legacy AppInitializer tolerates missing optional ApiConfig', () async {
    AppController.instance.resetForTest();
    await AppInitializer.initialize(initializeNetwork: true);
    expect(AppController.instance.isInitialized, isTrue);
    expect(AppController.instance.isReady(AppFeature.network), isFalse);
    expect(AppController.instance.isReady(AppFeature.theme), isTrue);
  });
}

extension on AppController {
  Future<void> initialize_(AppFeatures f) =>
      AppController.initialize(features: f);
}
