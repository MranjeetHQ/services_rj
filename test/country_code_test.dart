import 'package:country_flags/country_flags.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:services_rj/services_rj.dart';

Future<DynamicFormController> _pump(
  WidgetTester tester,
  Map<String, dynamic> field, {
  Map<String, dynamic>? initialData,
}) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final c = DynamicFormController();
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: DynamicForm(
          controller: c,
          initialData: initialData,
          json: {
            'fields': [
              {'type': 'phone', 'id': 'phone', 'label': 'Phone', ...field},
            ],
          },
        ),
      ),
    ),
  );
  await tester.pump();
  return c;
}

Finder get _button => find.byKey(const ValueKey('phone_country'));

void main() {
  group('CountryDialCodes', () {
    test('iso codes are unique and every dial starts with +', () {
      final isos = CountryDialCodes.all.map((c) => c.iso).toList();
      expect(isos.toSet(), hasLength(isos.length));
      expect(CountryDialCodes.all.every((c) => c.dial.startsWith('+')), isTrue);
    });

    test('lookup by iso or dial code', () {
      expect(CountryDialCodes.lookup('IN')?.dial, '+91');
      expect(CountryDialCodes.lookup('in')?.name, 'India');
      expect(CountryDialCodes.lookup('+44')?.iso, 'GB');
      expect(CountryDialCodes.lookup('44')?.iso, 'GB');
      expect(CountryDialCodes.lookup('+999'), isNull);
      expect(CountryDialCodes.lookup(null), isNull);
    });

    test('flag emoji is built from the iso code', () {
      expect(CountryDialCodes.lookup('IN')!.flag, '\u{1F1EE}\u{1F1F3}');
    });

    test('split uses the longest matching dial code', () {
      expect(CountryDialCodes.split('+919876543210'), (
        dial: '+91',
        national: '9876543210',
      ));
      expect(CountryDialCodes.split('+971501234567'), (
        dial: '+971',
        national: '501234567',
      ));
      expect(CountryDialCodes.split('+91 98765-43210').national, '9876543210');
      expect(CountryDialCodes.split('9876543210'), (
        dial: null,
        national: '9876543210',
      ));
      expect(CountryDialCodes.split(null).national, '');
    });

    test('resolve keeps the given order and falls back to all', () {
      expect(CountryDialCodes.resolve(['US', '+91']).map((c) => c.iso), [
        'US',
        'IN',
      ]);
      expect(CountryDialCodes.resolve(['??']), CountryDialCodes.all);
      expect(CountryDialCodes.resolve(null), CountryDialCodes.all);
    });
  });

  group('flag images', () {
    testWidgets('every listed country has a flag in the flag package', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Wrap(
                children: [
                  for (final c in CountryDialCodes.all)
                    CountryFlag.fromCountryCode(
                      c.iso,
                      theme: const ImageTheme(width: 24, height: 16),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(
        find.byType(CountryFlag),
        findsNWidgets(CountryDialCodes.all.length),
      );
    });

    testWidgets('the field and the picker show flag images', (tester) async {
      await _pump(tester, {'countryCode': true});
      expect(find.byType(CountryFlag), findsOneWidget);
      expect(find.text(CountryDialCodes.lookup('IN')!.flag), findsNothing);
      await tester.tap(_button);
      await tester.pumpAndSettle();
      // One in the field plus a flag on every visible list row.
      expect(find.byType(CountryFlag).evaluate().length, greaterThan(5));
      expect(find.text(CountryDialCodes.lookup('IN')!.flag), findsNothing);
    });
  });

  group('CountryDialCodes.search', () {
    List<String> isos(String q, {Iterable<CountryDialCode>? among}) => [
      for (final c in CountryDialCodes.search(q, among: among)) c.iso,
    ];

    test('empty query returns everything', () {
      expect(CountryDialCodes.search('  '), CountryDialCodes.all);
    });

    test('matches the country name, case-insensitively', () {
      expect(isos('india'), contains('IN'));
      expect(isos('UNITED'), containsAll(['US', 'GB', 'AE']));
      expect(isos('korea'), contains('KR'));
    });

    test('matches a word inside the name', () {
      expect(isos('emirates'), ['AE']);
      expect(isos('kingdom'), ['GB']);
    });

    test('matches the dial code with or without the plus', () {
      expect(isos('+44'), ['GB']);
      expect(isos('44'), ['GB']);
      expect(isos('+91').first, 'IN');
      expect(isos('971'), ['AE']);
    });

    test('a numeric query matches dial codes that start with it', () {
      final one = isos('1');
      expect(one, containsAll(['US', 'CA']));
      expect(one.first, 'US', reason: 'exact dial code first');
      expect(isos('3'), containsAll(['GR', 'NL', 'FR'])); // +30, +31, +33
      expect(isos('3'), isNot(contains('DE'))); // +49
      expect(isos('3'), isNot(contains('IN'))); // +91
    });

    test('matches the ISO code', () {
      expect(isos('gb').first, 'GB');
      expect(isos('IN').first, 'IN');
    });

    test('prefix matches rank before matches inside the name', () {
      final r = isos('ind');
      expect(r.indexOf('IN'), lessThan(r.indexOf('ID')));
      expect(r.first, 'IN');
      // "Dominican Republic" contains "ind"? no; "Ireland" does not either.
      expect(isos('land').first, isNot('IN'));
    });

    test('searches only the given countries', () {
      final among = CountryDialCodes.resolve(['IN', 'US']);
      expect(isos('united', among: among), ['US']);
      expect(isos('korea', among: among), isEmpty);
    });

    test('no match returns an empty list', () {
      expect(isos('zzzz'), isEmpty);
    });
  });

  group('phone field with a country code picker', () {
    testWidgets('is optional: without the key there is no picker', (
      tester,
    ) async {
      final c = await _pump(tester, {});
      expect(_button, findsNothing);
      await tester.enterText(find.byType(TextField), '9876543210');
      expect(c.getValue('phone'), '9876543210');
    });

    testWidgets('countryCode: true shows India and prefixes the value', (
      tester,
    ) async {
      final c = await _pump(tester, {'countryCode': true});
      expect(_button, findsOneWidget);
      expect(find.text('+91'), findsOneWidget);
      await tester.enterText(find.byType(TextField), '98765 43210');
      await tester.pump();
      expect(c.getValue('phone'), '+919876543210');
      expect(c.getPhone('phone'), (dial: '+91', number: '9876543210'));
      expect(c.getFormData()['phone'], '+919876543210');
    });

    testWidgets('picking a country changes the code and the value', (
      tester,
    ) async {
      final c = await _pump(tester, {'countryCode': true});
      await tester.enterText(find.byType(TextField), '7911123456');
      await tester.tap(_button);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, 'united king');
      await tester.pumpAndSettle();
      expect(find.text('India'), findsNothing);
      await tester.tap(find.text('United Kingdom'));
      await tester.pumpAndSettle();
      expect(find.text('+44'), findsOneWidget);
      expect(c.getValue('phone'), '+447911123456');
      // The typed digits stay in the input; only the code changed.
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        '7911123456',
      );
    });

    testWidgets('the search box finds countries by name and by code', (
      tester,
    ) async {
      final c = await _pump(tester, {'countryCode': true});
      await tester.tap(_button);
      await tester.pumpAndSettle();
      expect(find.text('Search country or code'), findsOneWidget);

      await tester.enterText(find.byType(TextField).last, 'germ');
      await tester.pumpAndSettle();
      expect(find.text('Germany'), findsOneWidget);
      expect(find.text('India'), findsNothing);

      await tester.enterText(find.byType(TextField).last, '+971');
      await tester.pumpAndSettle();
      expect(find.text('United Arab Emirates'), findsOneWidget);
      expect(find.text('Germany'), findsNothing);

      await tester.enterText(find.byType(TextField).last, '33');
      await tester.pumpAndSettle();
      expect(find.text('France'), findsOneWidget);

      await tester.enterText(find.byType(TextField).last, 'zzzz');
      await tester.pumpAndSettle();
      expect(find.text('No results'), findsOneWidget);

      await tester.enterText(find.byType(TextField).last, 'france');
      await tester.pumpAndSettle();
      await tester.tap(find.text('France'));
      await tester.pumpAndSettle();
      expect(find.text('+33'), findsOneWidget);
      await tester.enterText(find.byType(TextField), '612345678');
      expect(c.getValue('phone'), '+33612345678');
    });

    testWidgets('results stay above the on-screen keyboard', (tester) async {
      await _pump(tester, {'countryCode': true});
      tester.view.viewInsets = const FakeViewPadding(bottom: 600);
      addTearDown(tester.view.resetViewInsets);
      await tester.tap(_button);
      await tester.pumpAndSettle();
      // The whole result list must end above the keyboard (1600 - 600), so
      // every row can be reached while the keyboard is open.
      final list = tester.getRect(find.byType(ListView).last);
      expect(list.bottom, lessThanOrEqualTo(1600 - 600));
      expect(find.text('India'), findsOneWidget);
    });

    testWidgets('a default country can be named (ISO or dial code)', (
      tester,
    ) async {
      await _pump(tester, {'countryCode': 'US'});
      expect(find.text('+1'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await _pump(tester, {'countryCode': '+44'});
      expect(find.text('+44'), findsOneWidget);
    });

    testWidgets('countryCodes limits the list', (tester) async {
      await _pump(tester, {
        'countryCode': true,
        'countryCodes': ['SG', 'AU'],
      });
      expect(find.text('+65'), findsOneWidget, reason: 'first allowed');
      await tester.tap(_button);
      await tester.pumpAndSettle();
      expect(find.text('Singapore'), findsOneWidget);
      expect(find.text('Australia'), findsOneWidget);
      expect(find.text('India'), findsNothing);
    });

    testWidgets('an existing value fills the code and the number', (
      tester,
    ) async {
      final c = await _pump(
        tester,
        {'countryCode': true},
        initialData: {'phone': '+447911123456'},
      );
      expect(find.text('+44'), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        '7911123456',
      );
      expect(c.isDirty, isFalse);
      // setValue and reset keep the picker in step.
      c.setValue('phone', '+971501234567');
      await tester.pump();
      expect(find.text('+971'), findsOneWidget);
      c.reset();
      await tester.pump();
      expect(find.text('+44'), findsOneWidget);
    });

    testWidgets('clearing the number clears the value', (tester) async {
      final c = await _pump(tester, {'countryCode': true});
      await tester.enterText(find.byType(TextField), '9876543210');
      await tester.enterText(find.byType(TextField), '');
      await tester.pump();
      expect(c.getValue('phone'), isNull);
      expect(c.getPhone('phone'), isNull);
    });

    testWidgets('a disabled field cannot open the picker', (tester) async {
      await _pump(tester, {'countryCode': true, 'enabled': false});
      await tester.tap(_button, warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.text('India'), findsNothing);
    });

    testWidgets('works for the mobile preset and keeps its input rules', (
      tester,
    ) async {
      final c = await _pump(tester, {
        'type': 'text',
        'preset': 'mobile',
        'countryCode': true,
      });
      expect(_button, findsOneWidget);
      await tester.enterText(find.byType(TextField), '98a76543210999');
      await tester.pump();
      expect(c.getValue('phone'), '+919876543210'); // 10 digits max
    });

    testWidgets('a plain text field ignores countryCode', (tester) async {
      await _pump(tester, {'type': 'text', 'countryCode': true});
      expect(_button, findsNothing);
    });
  });

  group('validation with a country code', () {
    String? error(String value, {String preset = 'mobile'}) {
      final c = DynamicFormController()
        ..attach(
          FormParser.parse({
            'fields': [
              {'type': 'text', 'id': 'f', 'preset': preset},
            ],
          }),
        );
      c.setValue('f', value);
      final e = c.validateField('f');
      c.dispose();
      return e;
    }

    test('India keeps the 6-9 and 10-digit rule', () {
      expect(error('+919876543210'), isNull);
      expect(error('+915876543210'), contains('6-9'));
      expect(error('+91987654321'), contains('6-9'));
    });

    test('other countries accept 6-14 national digits', () {
      expect(error('+447911123456'), isNull);
      expect(error('+971501234567'), isNull);
      expect(error('+4412'), 'Enter a valid mobile number');
    });

    test('numbers without a code still follow the Indian rule', () {
      expect(error('9876543210'), isNull);
      expect(error('5876543210'), contains('6-9'));
    });

    test('the phone preset accepts a number with its code', () {
      expect(error('+912212345678', preset: 'phone'), isNull);
      expect(error('+91', preset: 'phone'), isNotNull);
    });
  });
}
