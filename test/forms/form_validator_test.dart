import 'package:flutter_test/flutter_test.dart';
import 'package:services_rj/services_rj.dart';

void main() {
  final l10n = FormLocalizations('en');
  String? run(
    String type,
    Object? value, {
    Object? param,
    Map<String, dynamic> data = const {},
  }) => ValidatorRegistry.build(
    ValidatorConfig(type: type, value: param),
  )!.validate(value, data, l10n);

  group('validators', () {
    test('required', () {
      expect(run('required', null), isNotNull);
      expect(run('required', ''), isNotNull);
      expect(run('required', <Object>[]), isNotNull);
      expect(run('required', 'x'), isNull);
      expect(run('required', 0), isNull);
    });

    test('email', () {
      expect(run('email', 'a@b.com'), isNull);
      expect(run('email', 'rupeshrajak438@gmail.com'), isNull);
      expect(run('email', 'nope'), isNotNull);
      expect(run('email', 'a@b'), isNotNull);
      expect(run('email', null), isNull, reason: 'empty skipped');
    });

    test('phone', () {
      expect(run('phone', '+91 98765 43210'), isNull);
      expect(run('phone', '12'), isNotNull);
    });

    test('url', () {
      expect(run('url', 'https://pub.dev/packages/x'), isNull);
      expect(run('url', 'not a url'), isNotNull);
    });

    test('number and decimal', () {
      expect(run('number', '42'), isNull);
      expect(run('number', '4.2'), isNotNull);
      expect(run('decimal', '4.2'), isNull);
      expect(run('decimal', 'abc'), isNotNull);
    });

    test('min / max', () {
      expect(run('min', 17, param: 18), isNotNull);
      expect(run('min', 18, param: 18), isNull);
      expect(run('max', '101', param: 100), isNotNull);
      expect(run('max', 100, param: 100), isNull);
    });

    test('minLength / maxLength', () {
      expect(run('minLength', 'ab', param: 3), isNotNull);
      expect(run('minLength', 'abc', param: 3), isNull);
      expect(run('maxLength', 'abcd', param: 3), isNotNull);
    });

    test('regex', () {
      expect(run('regex', 'ABC', param: r'^[A-Z]+$'), isNull);
      expect(run('regex', 'abc', param: r'^[A-Z]+$'), isNotNull);
    });

    test('matchField', () {
      expect(
        run(
          'matchField',
          'secret',
          param: 'password',
          data: {'password': 'secret'},
        ),
        isNull,
      );
      expect(
        run(
          'matchField',
          'other',
          param: 'password',
          data: {'password': 'secret'},
        ),
        isNotNull,
      );
    });

    test('passwordStrength', () {
      expect(run('passwordStrength', 'Aa1!aaaa'), isNull);
      expect(run('passwordStrength', 'weakpass'), isNotNull);
    });

    test('custom message overrides localized default', () {
      final v = ValidatorRegistry.build(
        const ValidatorConfig(type: 'required', message: 'Custom!'),
      )!;
      expect(v.validate(null, const {}, l10n), 'Custom!');
    });

    test('localized messages resolve per locale', () {
      expect(
        FormLocalizations('hi').message('required'),
        'यह फ़ील्ड आवश्यक है',
      );
      expect(
        FormLocalizations('de').message('minLength', value: 5),
        contains('5'),
      );
      expect(FormLocalizations('ar').isRtl, isTrue);
    });

    test('registered custom validator works from JSON name', () {
      ValidatorRegistry.register(
        'even',
        (cfg) => CustomValidator(
          cfg,
          (v, _) => ((v as num?) ?? 1) % 2 == 0 ? null : 'Must be even',
        ),
      );
      expect(run('even', 3), 'Must be even');
      expect(run('even', 4), isNull);
    });
  });
}
