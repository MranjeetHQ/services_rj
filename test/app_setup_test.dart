import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:services_rj/services_rj.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Brand extends ThemeExtension<_Brand> {
  const _Brand(this.logoColor);

  final Color logoColor;

  @override
  _Brand copyWith({Color? logoColor}) => _Brand(logoColor ?? this.logoColor);

  @override
  _Brand lerp(_Brand? other, double t) => this;
}

/// Fresh preferences, then shared prefs + theme initialized with [config].
///
/// SharedPrefManager keeps its first SharedPreferences instance, so mock
/// values set later are not seen; clear stored data instead.
Future<void> _initPrefs([AppThemeConfig? config]) async {
  SharedPreferences.setMockInitialValues({});
  if (SharedPrefManager.isInitialized) {
    await SharedPrefManager.clearAllSharedPrefData();
  }
  AppController.instance.resetForTest();
  await AppController.initialize(
    features: const AppFeatures(sharedPref: true, theme: true),
    themeConfig: config,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppThemeConfig', () {
    test('copyWith keeps unset values', () {
      const config = AppThemeConfig(seedColor: Colors.teal, borderRadius: 4);
      final copy = config.copyWith(initialThemeMode: ThemeMode.dark);
      expect(copy.seedColor, Colors.teal);
      expect(copy.borderRadius, 4);
      expect(copy.initialThemeMode, ThemeMode.dark);
    });
  });

  group('AppThemeManager', () {
    test('defaults are unchanged', () {
      final light = AppThemeManager.lightTheme(const AppThemeConfig());
      expect(light.brightness, Brightness.light);
      expect(light.appBarTheme.centerTitle, isTrue);
      expect(light.appBarTheme.elevation, 0);
      expect(light.inputDecorationTheme.filled, isTrue);
      expect(
        AppThemeManager.darkTheme(const AppThemeConfig()).brightness,
        Brightness.dark,
      );
    });

    test('colour scheme overrides replace the seed', () {
      final scheme = ColorScheme.fromSeed(
        seedColor: Colors.red,
        brightness: Brightness.dark,
      );
      final dark = AppThemeManager.darkTheme(
        AppThemeConfig(seedColor: Colors.blue, darkColorScheme: scheme),
      );
      expect(dark.colorScheme.primary, scheme.primary);
      expect(dark.brightness, Brightness.dark);
    });

    test('new options, extensions and customize apply', () {
      final seen = <Brightness>[];
      final config = AppThemeConfig(
        appBarCenterTitle: false,
        appBarElevation: 3,
        inputFilled: false,
        visualDensity: VisualDensity.compact,
        textTheme: const TextTheme(bodyLarge: TextStyle(fontSize: 21)),
        extensions: const [_Brand(Colors.orange)],
        customize: (theme, brightness) {
          seen.add(brightness);
          return theme.copyWith(
            dividerTheme: const DividerThemeData(thickness: 5),
          );
        },
      );
      final light = AppThemeManager.lightTheme(config);
      AppThemeManager.darkTheme(config);

      expect(light.appBarTheme.centerTitle, isFalse);
      expect(light.appBarTheme.elevation, 3);
      expect(light.inputDecorationTheme.filled, isFalse);
      expect(light.visualDensity, VisualDensity.compact);
      expect(light.textTheme.bodyLarge!.fontSize, 21);
      expect(light.textTheme.bodyMedium, isNotNull);
      expect(light.extension<_Brand>()!.logoColor, Colors.orange);
      expect(light.dividerTheme.thickness, 5);
      expect(seen, [Brightness.light, Brightness.dark]);
    });
  });

  group('AppThemeController', () {
    final theme = AppThemeController.instance;

    test('first launch uses initialThemeMode', () async {
      await _initPrefs(const AppThemeConfig(initialThemeMode: ThemeMode.dark));
      expect(theme.themeMode, ThemeMode.dark);
    });

    test('a saved mode wins over initialThemeMode', () async {
      await _initPrefs();
      await theme.setThemeMode(ThemeMode.system);
      await theme.initialize(
        config: const AppThemeConfig(initialThemeMode: ThemeMode.dark),
      );
      expect(theme.themeMode, ThemeMode.system);
    });

    test('accent colour is saved, restored and cleared', () async {
      await _initPrefs();
      final before = theme.lightTheme;
      await theme.setSeedColor(Colors.pink);
      expect(theme.seedColor, Colors.pink);
      expect(theme.hasCustomSeedColor, isTrue);
      expect(theme.lightTheme, isNot(same(before)));
      expect(
        SharedPrefManager.getData<int>(SharedPrefKeys.themeSeedColor),
        Colors.pink.toARGB32(),
      );

      theme.resetForTest();
      await theme.initialize();
      expect(theme.seedColor.toARGB32(), Colors.pink.toARGB32());

      await theme.setSeedColor(null);
      expect(theme.hasCustomSeedColor, isFalse);
      expect(theme.seedColor, theme.config.seedColor);
      expect(
        SharedPrefManager.containsKey(SharedPrefKeys.themeSeedColor),
        isFalse,
      );
    });

    test('themes are cached until something changes', () async {
      await _initPrefs();
      expect(theme.lightTheme, same(theme.lightTheme));
      var notified = 0;
      void listener() => notified++;
      theme.addListener(listener);
      addTearDown(() => theme.removeListener(listener));

      final before = theme.darkTheme;
      theme.setConfig(const AppThemeConfig(borderRadius: 2));
      expect(notified, 1);
      expect(theme.darkTheme, isNot(same(before)));
      expect(theme.config.borderRadius, 2);
    });

    test('resetToDefaults forgets mode and colour', () async {
      await _initPrefs();
      await theme.setThemeMode(ThemeMode.dark);
      await theme.setSeedColor(Colors.green);
      await theme.resetToDefaults();
      expect(theme.themeMode, ThemeMode.system);
      expect(theme.hasCustomSeedColor, isFalse);
      expect(SharedPrefManager.containsKey(SharedPrefKeys.themeMode), isFalse);
    });

    test('themeConfig applies even with the theme feature off', () async {
      if (SharedPrefManager.isInitialized) {
        await SharedPrefManager.clearAllSharedPrefData();
      }
      AppController.instance.resetForTest();
      await AppController.initialize(
        themeConfig: const AppThemeConfig(
          seedColor: Colors.orange,
          initialThemeMode: ThemeMode.light,
        ),
      );
      expect(theme.config.seedColor, Colors.orange);
      expect(theme.themeMode, ThemeMode.light);
      expect(AppController.instance.isReady(AppFeature.theme), isFalse);
    });
  });

  group('ServicesApp', () {
    setUp(_initPrefs);

    testWidgets('follows the controller and attaches AppKeys', (tester) async {
      AppThemeController.instance.setConfig(
        const AppThemeConfig(seedColor: Colors.teal),
      );
      await tester.pumpWidget(
        const ServicesApp(
          title: 'Test',
          home: Scaffold(body: Text('home')),
        ),
      );
      final context = tester.element(find.text('home'));
      expect(
        Theme.of(context).colorScheme.primary,
        AppThemeController.instance.lightTheme.colorScheme.primary,
      );
      expect(
        tester
            .widget<MaterialApp>(find.byType(MaterialApp))
            .debugShowCheckedModeBanner,
        isFalse,
      );

      await AppThemeController.instance.setThemeMode(ThemeMode.dark);
      await tester.pumpAndSettle();
      expect(
        Theme.of(tester.element(find.text('home'))).brightness,
        Brightness.dark,
      );

      expect(AppKeys.navigator, isNotNull);
      expect(AppKeys.context, isNotNull);
      AppKeys.messenger!.showSnackBar(const SnackBar(content: Text('saved')));
      await tester.pump();
      expect(find.text('saved'), findsOneWidget);
    });

    testWidgets('explicit theme and mode override the controller', (
      tester,
    ) async {
      final custom = ThemeData(colorSchemeSeed: Colors.red);
      await tester.pumpWidget(
        ServicesApp(
          theme: custom,
          themeMode: ThemeMode.light,
          home: const Scaffold(body: Text('home')),
        ),
      );
      expect(
        Theme.of(tester.element(find.text('home'))).colorScheme.primary,
        custom.colorScheme.primary,
      );
    });
  });

  group('theme settings widgets', () {
    setUp(_initPrefs);

    testWidgets('ThemeModeSelector sets the mode', (tester) async {
      await tester.pumpWidget(
        const ServicesApp(home: Scaffold(body: ThemeModeSelector())),
      );
      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();
      expect(AppThemeController.instance.themeMode, ThemeMode.dark);
      await tester.tap(find.text('Light'));
      await tester.pumpAndSettle();
      expect(AppThemeController.instance.themeMode, ThemeMode.light);
    });

    testWidgets('ThemeColorPicker sets and resets the accent', (tester) async {
      await tester.pumpWidget(
        const ServicesApp(
          home: Scaffold(
            body: ThemeColorPicker(colors: [Colors.green, Colors.purple]),
          ),
        ),
      );
      await tester.tap(find.bySemanticsLabel('#4caf50'));
      await tester.pumpAndSettle();
      expect(
        AppThemeController.instance.seedColor.toARGB32(),
        Colors.green.toARGB32(),
      );

      await tester.tap(find.bySemanticsLabel('Default'));
      await tester.pumpAndSettle();
      expect(AppThemeController.instance.hasCustomSeedColor, isFalse);
    });
  });

  group('AppSetup.run', () {
    setUp(() async {
      if (SharedPrefManager.isInitialized) {
        await SharedPrefManager.clearAllSharedPrefData();
      }
      AppController.instance.resetForTest();
    });

    /// Runs [body] with the test framework's FlutterError handler swapped
    /// out, so AppSetup does not chain errors into it, and restores it.
    Future<void> isolateErrors(Future<void> Function() body) async {
      final testHandler = FlutterError.onError;
      FlutterError.onError = (_) {};
      try {
        await body();
      } finally {
        FlutterError.onError = testHandler;
      }
    }

    testWidgets('initializes, runs beforeRun and starts the app', (
      tester,
    ) async {
      await isolateErrors(() async {
        final errors = <Object>[];
        var ranBeforeRun = false;
        await AppSetup.run(
          features: const AppFeatures(sharedPref: true, theme: true),
          themeConfig: const AppThemeConfig(seedColor: Colors.indigo),
          beforeRun: () async => ranBeforeRun = true,
          onError: (e, _) => errors.add(e),
          app: const ServicesApp(home: Scaffold(body: Text('started'))),
        );
        await tester.pump();

        expect(find.text('started'), findsOneWidget);
        expect(ranBeforeRun, isTrue);
        expect(AppController.instance.isReady(AppFeature.theme), isTrue);
        expect(AppThemeController.instance.config.seedColor, Colors.indigo);

        // The test binding ignores PlatformDispatcher.onError writes, so
        // only the framework error route can be checked here.
        FlutterError.onError!(FlutterErrorDetails(exception: 'boom'));
        expect(errors, ['boom']);
      });
    });

    testWidgets('a setup failure is reported and the app still starts', (
      tester,
    ) async {
      await isolateErrors(() async {
        final errors = <Object>[];
        await AppSetup.run(
          beforeRun: () async => throw StateError('no user'),
          onError: (e, _) => errors.add(e),
          app: const ServicesApp(home: Scaffold(body: Text('started'))),
        );
        await tester.pump();
        expect(find.text('started'), findsOneWidget);
        expect(errors.single, isA<StateError>());
      });
    });

    testWidgets('without onError a setup failure is rethrown', (tester) async {
      await expectLater(
        AppSetup.run(
          beforeRun: () async => throw StateError('no user'),
          app: const SizedBox(),
        ),
        throwsStateError,
      );
    });
  });
}
