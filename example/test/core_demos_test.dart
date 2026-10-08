import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:services_rj/services_rj.dart';
import 'package:services_rj_example/demos/core/app_setup_demo.dart';
import 'package:services_rj_example/demos/core/core_common.dart';
import 'package:services_rj_example/demos/core_demos.dart';
import 'package:services_rj_example/demos/core/theme_demo.dart';
// Test-only: the package under demo depends on it and tests need its mock.
// ignore: depend_on_referenced_packages
import 'package:shared_preferences/shared_preferences.dart';

Future<void> pumpPage(
  WidgetTester tester,
  Widget page, {
  Size size = const Size(900, 1400),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(MaterialApp(home: page));
  await tester.pump();
}

Widget entryPage(BuildContext context, String title) =>
    coreDemos.firstWhere((e) => e.title == title).builder(context);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('every core page renders without AppController.initialize', () {
    for (final entry in coreDemos) {
      testWidgets(entry.title, (tester) async {
        await pumpPage(tester, Builder(builder: entry.builder));
        expect(tester.takeException(), isNull);
        expect(find.byType(Scaffold), findsWidgets);
      });
    }

    test('exposes ten entries with unique titles', () {
      expect(coreDemos.length, 10);
      expect(coreDemos.map((e) => e.title).toSet().length, 10);
    });
  });

  group('AppController dashboard', () {
    testWidgets('lists every feature and disables fixed ones', (tester) async {
      await pumpPage(
        tester,
        Builder(builder: (c) => entryPage(c, 'AppController')),
      );
      for (final f in AppFeature.values) {
        expect(find.text(f.name), findsWidgets);
      }
      final switches = tester.widgetList<SwitchListTile>(
        find.byType(SwitchListTile),
      );
      final enabledCount = switches.where((s) => s.onChanged != null).length;
      expect(enabledCount, runtimeToggleableFeatures.length);
      expect(find.textContaining('has not run'), findsOneWidget);
    });
  });

  group('AppFeatures helpers', () {
    test('none, only, copyWith, withFeature, toMap', () {
      const none = AppFeatures.none();
      expect(none.toMap().values.every((v) => !v), isTrue);
      final only = AppFeatures.only({AppFeature.theme, AppFeature.logger});
      expect(only.theme && only.logger && !only.network, isTrue);
      expect(only.copyWith(network: true).network, isTrue);
      expect(only.withFeature(AppFeature.theme, false).theme, isFalse);
      expect(only.toMap().length, AppFeature.values.length);
    });

    test('setEnabled rejects fixed features', () {
      expect(
        AppController.instance.setEnabled(AppFeature.theme, true),
        throwsStateError,
      );
    });
  });

  group('AppValidators', () {
    test('email', () {
      expect(AppValidators.email(''), isNotNull);
      expect(AppValidators.email('nope'), isNotNull);
      expect(AppValidators.email('a@b.co'), isNull);
    });
    test('password', () {
      expect(AppValidators.password('12345'), isNotNull);
      expect(AppValidators.password('123456'), isNull);
    });
    test('requiredField', () {
      expect(AppValidators.requiredField('   '), isNotNull);
      expect(AppValidators.requiredField('x'), isNull);
    });

    testWidgets('form page shows errors then passes', (tester) async {
      await pumpPage(
        tester,
        Builder(builder: (c) => entryPage(c, 'Validators and debouncer')),
      );
      await tester.tap(find.text('Validate'));
      await tester.pump();
      expect(find.text('This field is required'), findsOneWidget);
      expect(find.text('Email is required'), findsOneWidget);
      expect(find.text('Password must be 6+ characters'), findsOneWidget);

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Asha');
      await tester.enterText(fields.at(1), 'asha@example.com');
      await tester.enterText(fields.at(2), 'secret1');
      await tester.tap(find.text('Validate'));
      await tester.pump();
      expect(find.text('All fields are valid.'), findsOneWidget);
    });
  });

  group('AppDebouncer', () {
    testWidgets('collapses rapid calls into one', (tester) async {
      var calls = 0;
      final d = AppDebouncer(milliseconds: 200);
      for (var i = 0; i < 5; i++) {
        d.run(() => calls++);
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(calls, 0);
      await tester.pump(const Duration(milliseconds: 250));
      expect(calls, 1);
      d.run(() => calls++);
      d.dispose();
      await tester.pump(const Duration(milliseconds: 300));
      expect(calls, 1);
    });

    testWidgets('page counts keystrokes vs calls', (tester) async {
      await pumpPage(
        tester,
        Builder(builder: (c) => entryPage(c, 'Validators and debouncer')),
      );
      final search = find.widgetWithText(TextField, 'Search the catalogue');
      await tester.enterText(search, 'a');
      await tester.enterText(search, 'ab');
      await tester.enterText(search, 'abc');
      await tester.pump();
      expect(find.text('Keystrokes: 3'), findsOneWidget);
      expect(find.text('Debounced calls: 0'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 700));
      expect(find.text('Debounced calls: 1'), findsOneWidget);
      expect(find.text('Last debounced value: "abc"'), findsOneWidget);
    });
  });

  group('AppResponsive', () {
    Future<void> check(
      WidgetTester tester,
      Size size,
      List<bool> expected,
    ) async {
      late BuildContext ctx;
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(size: size),
          child: Builder(
            builder: (c) {
              ctx = c;
              return const SizedBox();
            },
          ),
        ),
      );
      expect([
        AppResponsive.isMobile(ctx),
        AppResponsive.isTablet(ctx),
        AppResponsive.isDesktop(ctx),
      ], expected);
    }

    testWidgets(
      'mobile',
      (t) => check(t, const Size(390, 800), [true, false, false]),
    );
    testWidgets(
      'tablet',
      (t) => check(t, const Size(800, 900), [false, true, false]),
    );
    testWidgets(
      'desktop',
      (t) => check(t, const Size(1280, 900), [false, false, true]),
    );
  });

  group('Buttons', () {
    testWidgets('renders every type and factory', (tester) async {
      await pumpPage(tester, Builder(builder: (c) => entryPage(c, 'Buttons')));
      expect(find.byType(ElevatedButton), findsWidgets);
      expect(find.byType(FilledButton), findsWidgets);
      expect(find.byType(OutlinedButton), findsWidgets);
      expect(find.byType(TextButton), findsWidgets);
      expect(find.byType(IconButton), findsWidgets);
      expect(find.byType(FloatingActionButton), findsWidgets);
      expect(find.text('custom builder'), findsOneWidget);
    });

    testWidgets('isEnabled false disables the button', (tester) async {
      await pumpPage(
        tester,
        Scaffold(
          body: AppButtons.filled(
            label: 'Go',
            isEnabled: false,
            onPressed: () {},
          ),
        ),
      );
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
    });

    testWidgets('onPressed and onLongPress fire', (tester) async {
      var taps = 0, holds = 0;
      await pumpPage(
        tester,
        Scaffold(
          body: AppButtons.elevated(
            label: 'Hit',
            onPressed: () => taps++,
            onLongPress: () => holds++,
          ),
        ),
      );
      await tester.tap(find.text('Hit'));
      await tester.longPress(find.text('Hit'));
      expect([taps, holds], [1, 1]);
    });

    testWidgets('custom without builder throws ArgumentError', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AppButtons(type: AppButtonType.custom, label: 'x'),
        ),
      );
      expect(tester.takeException(), isArgumentError);
    });
  });

  group('Theme', () {
    testWidgets('previews build and are scoped', (tester) async {
      await pumpPage(
        tester,
        Builder(builder: (c) => entryPage(c, 'Theme')),
        size: const Size(900, 3000),
      );
      expect(find.byType(ThemePreviewPane), findsNWidgets(2));
      expect(find.byType(BottomNavigationBar), findsNWidgets(2));
      expect(tester.takeException(), isNull);

      final panes = tester
          .widgetList<ThemePreviewPane>(find.byType(ThemePreviewPane))
          .toList();
      expect(panes[0].data.brightness, Brightness.light);
      expect(panes[1].data.brightness, Brightness.dark);
      // The page's own theme is not the preview theme.
      final pageTheme = Theme.of(
        tester.element(find.byType(DropdownButtonFormField<String?>)),
      );
      expect(pageTheme.brightness, Brightness.light);
    });

    testWidgets('narrow width stacks the previews', (tester) async {
      await pumpPage(
        tester,
        Builder(builder: (c) => entryPage(c, 'Theme')),
        size: const Size(400, 4000),
      );
      expect(find.byType(ThemePreviewPane), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    });

    testWidgets('controller buttons change the theme mode', (tester) async {
      addTearDown(
        () => AppThemeController.instance.setThemeMode(ThemeMode.system),
      );
      await pumpPage(
        tester,
        Builder(builder: (c) => entryPage(c, 'Theme')),
        size: const Size(900, 3000),
      );
      final toggle = find.text('toggleTheme()');
      await tester.ensureVisible(toggle);
      await tester.pumpAndSettle();
      await tester.tap(toggle);
      await tester.pump();
      expect(AppThemeController.instance.isDarkMode, isTrue);
      await tester.tap(toggle);
      await tester.pump();
      expect(AppThemeController.instance.isLightMode, isTrue);
    });

    testWidgets('theme settings widgets change mode and accent', (
      tester,
    ) async {
      addTearDown(AppThemeController.instance.resetToDefaults);
      await pumpPage(
        tester,
        Builder(builder: (c) => entryPage(c, 'Theme')),
        size: const Size(900, 3000),
      );
      final dark = find.descendant(
        of: find.byType(ThemeModeSelector),
        matching: find.text('Dark'),
      );
      await tester.ensureVisible(dark);
      await tester.pumpAndSettle();
      await tester.tap(dark);
      await tester.pump();
      expect(AppThemeController.instance.isDarkMode, isTrue);

      await tester.tap(find.bySemanticsLabel('#e91e63')); // Colors.pink
      await tester.pump();
      expect(AppThemeController.instance.hasCustomSeedColor, isTrue);

      await tester.tap(find.text('resetToDefaults()'));
      await tester.pump();
      expect(AppThemeController.instance.isSystemMode, isTrue);
      expect(AppThemeController.instance.hasCustomSeedColor, isFalse);
    });

    testWidgets('new options preview and apply to the whole app', (
      tester,
    ) async {
      final original = AppThemeController.instance.config;
      addTearDown(() => AppThemeController.instance.setConfig(original));
      await pumpPage(
        tester,
        Builder(builder: (c) => entryPage(c, 'Theme')),
        size: const Size(900, 5000),
      );
      expect(find.text('ThemeExtension badge'), findsNWidgets(2));

      await tester.tap(find.text('appBarCenterTitle'));
      await tester.tap(find.text('customize: thick primary dividers'));
      await tester.pump();
      final panes = tester
          .widgetList<ThemePreviewPane>(find.byType(ThemePreviewPane))
          .toList();
      expect(panes[0].data.appBarTheme.centerTitle, isFalse);
      expect(panes[0].data.dividerTheme.thickness, 3);
      expect(panes[0].data.extension<DemoBrand>(), isNotNull);

      await tester.tap(find.text('Apply to whole app'));
      await tester.pump();
      expect(AppThemeController.instance.config.appBarCenterTitle, isFalse);
      expect(AppThemeController.instance.config.customize, isNotNull);

      await tester.tap(find.text('Restore app config'));
      await tester.pump();
      expect(AppThemeController.instance.config, same(original));
    });

    test('config maps to ThemeData', () {
      const config = AppThemeConfig(
        seedColor: Colors.teal,
        borderRadius: 4,
        cardRadius: 20,
      );
      final light = AppThemeManager.lightTheme(config);
      final dark = AppThemeManager.darkTheme(config);
      expect(light.brightness, Brightness.light);
      expect(dark.brightness, Brightness.dark);
      expect(config.effectiveCardRadius, 20);
    });
  });

  group('App setup', () {
    Future<void> pumpInServicesApp(WidgetTester tester) async {
      tester.view.physicalSize = const Size(900, 3000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      addTearDown(AppThemeController.instance.resetToDefaults);
      await tester.pumpWidget(const ServicesApp(home: AppSetupDemo()));
      await tester.pump();
    }

    testWidgets('without ServicesApp the keys report not attached', (
      tester,
    ) async {
      await pumpPage(
        tester,
        Builder(builder: (c) => entryPage(c, 'App setup')),
        size: const Size(900, 3000),
      );
      expect(find.text('Not inside a ServicesApp'), findsOneWidget);
      await tester.tap(find.text('Snackbar via messenger'));
      await tester.pump();
      expect(find.textContaining('not attached'), findsWidgets);
    });

    testWidgets('AppKeys reach the UI from plain functions', (tester) async {
      await pumpInServicesApp(tester);
      expect(find.text('This page runs inside a ServicesApp'), findsOneWidget);
      expect(find.text('Keys attached'), findsOneWidget);

      await tester.tap(find.text('Snackbar via messenger'));
      await tester.pump();
      expect(find.text('Profile saved (from a service)'), findsOneWidget);

      await tester.tap(find.text('Dialog via context'));
      await tester.pumpAndSettle();
      expect(find.text('Session expiring'), findsOneWidget);
      await tester.tap(find.text('Stay signed in'));
      await tester.pumpAndSettle();
      expect(find.textContaining('stay signed in: true'), findsOneWidget);

      await tester.tap(find.text('Push via navigator'));
      await tester.pumpAndSettle();
      expect(find.text('Pushed by AppKeys'), findsOneWidget);
    });

    testWidgets('settings screen changes mode and resets', (tester) async {
      await pumpInServicesApp(tester);
      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();
      expect(AppThemeController.instance.isDarkMode, isTrue);
      await tester.tap(find.text('Reset theme settings'));
      await tester.pumpAndSettle();
      expect(AppThemeController.instance.isSystemMode, isTrue);
    });
  });

  group('Extensions', () {
    String row(WidgetTester tester, String label) => tester
        .widgetList<KeyValueRow>(find.byType(KeyValueRow))
        .firstWhere((r) => r.label == label)
        .value;

    Future<void> open(WidgetTester tester) => pumpPage(
      tester,
      Builder(builder: (c) => entryPage(c, 'Extensions')),
      size: const Size(900, 5000),
    );

    testWidgets('string rows follow the input', (tester) async {
      await open(tester);
      expect(row(tester, 'isEmail'), 'true');
      expect(row(tester, 'isPhone'), 'false');

      await tester.enterText(find.byType(TextField).first, 'user_name id');
      await tester.pump();
      expect(row(tester, 'toCamelCase()'), 'userNameId');
      expect(row(tester, 'toSnakeCase()'), 'user_name_id');
      expect(row(tester, 'initials'), 'UI');
      expect(row(tester, 'truncate(10)'), 'user_name…');

      await tester.tap(find.text('+91 98765-43210'));
      await tester.pump();
      expect(row(tester, 'isPhone'), 'true');
      expect(row(tester, 'onlyDigits()'), '919876543210');
      expect(
        row(tester, 'mask(visibleStart: 0, visibleEnd: 4)'),
        '•••••••••••3210',
      );
    });

    testWidgets('nullable rows', (tester) async {
      await open(tester);
      await tester.tap(find.text('Value is null'));
      await tester.pump();
      expect(row(tester, 'isNullOrEmpty'), 'true');
      expect(row(tester, "or('Guest')"), 'Guest');
    });

    testWidgets('number rows follow input, decimals and grouping', (
      tester,
    ) async {
      await open(tester);
      expect(row(tester, 'withSeparators'), '1,234,567.89');
      expect(row(tester, "toCurrency('₹')"), '₹1,234,567.89');
      expect(row(tester, 'toCompact'), '1.23M');

      await tester.tap(find.text('Indian grouping (lakh / crore)'));
      await tester.pump();
      expect(row(tester, 'withSeparators'), '12,34,567.89');
      expect(row(tester, 'toCompact'), '12.35L');

      await tester.tap(find.text(r'$'));
      await tester.enterText(find.byType(TextField).at(1), '-20');
      await tester.pump();
      expect(row(tester, r"toCurrency('$')"), r'-$20.00');

      await tester.enterText(find.byType(TextField).at(1), 'abc');
      await tester.pump();
      expect(row(tester, 'orZero'), '0.0');
      expect(find.textContaining('Not a number'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('UI helpers', () {
    testWidgets('snackbar, message dialog and loading dialog', (tester) async {
      await pumpPage(
        tester,
        Builder(builder: (c) => entryPage(c, 'UI helpers')),
      );

      await tester.tap(find.text('success'));
      await tester.pump();
      expect(find.text('Profile updated'), findsOneWidget);

      final message = find.text('showMessage');
      await tester.ensureVisible(message);
      await tester.tap(message);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Backup complete'), findsOneWidget);
      await tester.tapAt(const Offset(5, 5));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      final loading = find.text('showLoading');
      await tester.ensureVisible(loading);
      await tester.tap(loading);
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(CircularProgressIndicator), findsWidgets);
      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(milliseconds: 500));
      expect(
        find.text('Loading dialog closed after 2 seconds'),
        findsOneWidget,
      );
    });

    testWidgets('responsive chips follow the window size', (tester) async {
      await pumpPage(
        tester,
        Builder(builder: (c) => entryPage(c, 'UI helpers')),
        size: const Size(500, 2500),
      );
      expect(find.text('isMobile true'), findsOneWidget);
      await pumpPage(
        tester,
        Builder(builder: (c) => entryPage(c, 'UI helpers')),
        size: const Size(1200, 2500),
      );
      expect(find.text('isDesktop true'), findsOneWidget);
    });

    testWidgets('AppScaffold page opens with a floating action button', (
      tester,
    ) async {
      await pumpPage(
        tester,
        Builder(builder: (c) => entryPage(c, 'UI helpers')),
        size: const Size(900, 2500),
      );
      final open = find.text('Open an AppScaffold page');
      await tester.ensureVisible(open);
      await tester.tap(open);
      await tester.pumpAndSettle();
      expect(find.byType(AppScaffold), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(AppScaffold),
          matching: find.byType(SafeArea),
        ),
        findsWidgets,
      );
      await tester.tap(find.text('Add'));
      await tester.pump();
      expect(find.text('Reminder 3'), findsOneWidget);
    });

    testWidgets('context extensions show values', (tester) async {
      await pumpPage(
        tester,
        Builder(builder: (c) => entryPage(c, 'UI helpers')),
        size: const Size(900, 2500),
      );
      expect(find.text('900 x 2500'), findsOneWidget);
    });
  });

  group('Logger', () {
    testWidgets('buttons write to the sent log and respect enabled', (
      tester,
    ) async {
      final wasEnabled = AppLogger.enabled;
      addTearDown(() => AppLogger.enabled = wasEnabled);
      await pumpPage(
        tester,
        Builder(builder: (c) => entryPage(c, 'Logger and connectivity')),
      );
      await tester.tap(find.text('info'));
      await tester.pump();
      expect(find.textContaining('info: "Checkout started"'), findsOneWidget);
      expect(
        find.textContaining('connectivity" feature is off'),
        findsOneWidget,
      );
    });
  });

  group('Encryption', () {
    final crypto = AppEncryption.instance;
    setUp(() async {
      crypto.reset();
      await crypto.initialize(keyProvider: () async => Uint8List(32));
    });
    tearDown(crypto.reset);

    test('round trips text and bytes, marks ciphertext', () {
      final sealed = crypto.encrypt('hello');
      expect(AppEncryption.isEncrypted(sealed), isTrue);
      expect(sealed.startsWith(AppEncryption.marker), isTrue);
      expect(crypto.decrypt(sealed), 'hello');
      final bytes = crypto.encryptBytes([1, 2, 3]);
      expect(bytes.length, 12 + 3 + 16);
      expect(crypto.decryptBytes(bytes), [1, 2, 3]);
    });

    testWidgets('page encrypts, decrypts and detects tampering', (
      tester,
    ) async {
      await pumpPage(
        tester,
        Builder(builder: (c) => entryPage(c, 'Encryption')),
        size: const Size(900, 2500),
      );
      await tester.tap(find.text('Encrypt'));
      await tester.pump();
      expect(find.textContaining('enc1:'), findsWidgets);
      await tester.tap(find.text('Decrypt'));
      await tester.pump();
      expect(
        find.textContaining('decrypt -> "card ending 4242"'),
        findsOneWidget,
      );

      await tester.tap(find.text('Tamper'));
      await tester.pump();
      await tester.tap(find.text('Decrypt'));
      await tester.pump();
      expect(find.textContaining('StateError'), findsOneWidget);

      final bytes = find.text('Encrypt the plain text as bytes');
      await tester.ensureVisible(bytes);
      await tester.tap(bytes);
      await tester.pump();
      expect(
        find.textContaining('round trip: "card ending 4242"'),
        findsOneWidget,
      );
    });

    testWidgets('destroyKey needs a confirm', (tester) async {
      await pumpPage(
        tester,
        Builder(builder: (c) => entryPage(c, 'Encryption')),
        size: const Size(900, 2500),
      );
      final destroy = find.text('destroyKey()');
      await tester.ensureVisible(destroy);
      await tester.tap(destroy);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(crypto.isInitialized, isTrue);
      await tester.tap(destroy);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Destroy key'));
      await tester.pumpAndSettle();
      expect(crypto.isInitialized, isFalse);
    });
  });

  group('Storage', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({'seed': 'x'});
      await SharedPrefManager.initilization();
    });

    testWidgets('saves and reads typed values', (tester) async {
      await pumpPage(
        tester,
        Builder(builder: (c) => entryPage(c, 'Storage')),
        size: const Size(900, 3000),
      );
      await tester.runAsync(() async {
        await tester.tap(find.text('saveData'));
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pump();
      expect(SharedPrefManager.getData<String>('demo_value'), 'Asha Verma');
      expect(
        find.textContaining('saveData("demo_value", String) -> true'),
        findsOneWidget,
      );
      await tester.tap(find.text('getData'));
      await tester.pump();
      expect(
        find.textContaining('getData<String>("demo_value") -> Asha Verma'),
        findsOneWidget,
      );
    });

    test('manager supports every documented type', () async {
      await SharedPrefManager.saveData('i', 1);
      await SharedPrefManager.saveData('d', 1.5);
      await SharedPrefManager.saveData('b', true);
      await SharedPrefManager.saveData('l', ['a']);
      await SharedPrefManager.saveData('m', {'k': 1});
      expect(SharedPrefManager.getData<int>('i'), 1);
      expect(SharedPrefManager.getData<double>('d'), 1.5);
      expect(SharedPrefManager.getData<bool>('b'), true);
      expect(SharedPrefManager.getData<List<String>>('l'), ['a']);
      expect(SharedPrefManager.getData<Map<String, dynamic>>('m'), {'k': 1});
      expect(SharedPrefManager.containsKey('i'), isTrue);
      expect(await SharedPrefManager.delete('i'), isTrue);
      expect(SharedPrefManager.containsKey('i'), isFalse);
    });

    test('migrateToEncrypted encrypts plain values', () async {
      final crypto = AppEncryption.instance;
      await crypto.initialize(keyProvider: () async => Uint8List(32));
      addTearDown(crypto.reset);
      await SharedPrefManager.saveData('plain_after', 'v');
      crypto.enabled = false;
      await SharedPrefManager.saveData('legacy', 'old');
      crypto.enabled = true;
      expect(await SharedPrefManager.migrateToEncrypted(), greaterThan(0));
      expect(SharedPrefManager.getData<String>('legacy'), 'old');
    });
  });
}
