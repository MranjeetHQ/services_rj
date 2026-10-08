import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:services_rj/services_rj.dart';

void main() {
  group('String checks', () {
    test('blank', () {
      expect('  '.isBlank, isTrue);
      expect(''.isBlank, isTrue);
      expect(' a '.isNotBlank, isTrue);
    });

    test('email', () {
      expect('asha.patel+news@example.co.in'.isEmail, isTrue);
      expect(' user@example.com '.isEmail, isTrue);
      expect('user@example'.isEmail, isFalse);
      expect('user@@example.com'.isEmail, isFalse);
      expect('@example.com'.isEmail, isFalse);
    });

    test('phone', () {
      expect('+91 98765-43210'.isPhone, isTrue);
      expect('(022) 2345 6789'.isPhone, isTrue);
      expect('12345'.isPhone, isFalse);
      expect('98765abc10'.isPhone, isFalse);
    });

    test('url', () {
      expect('https://example.com/a?b=1'.isUrl, isTrue);
      expect('http://localhost:8080'.isUrl, isTrue);
      expect('example.com'.isUrl, isFalse);
      expect('ftp://example.com'.isUrl, isFalse);
    });

    test('numeric, alphabetic, alphanumeric', () {
      expect('-3.5'.isNumeric, isTrue);
      expect(' 42 '.isNumeric, isTrue);
      expect('4 2'.isNumeric, isFalse);
      expect('नमस्ते'.isAlphabetic, isTrue); // letters plus vowel signs
      expect('Asha'.isAlphabetic, isTrue);
      expect('Asha1'.isAlphabetic, isFalse);
      expect('Asha1'.isAlphanumeric, isTrue);
      expect('Asha 1'.isAlphanumeric, isFalse);
      expect('ABC'.equalsIgnoreCase('abc'), isTrue);
    });
  });

  group('String conversions', () {
    test('numbers and bools', () {
      expect(' 42 '.toIntOrNull(), 42);
      expect('4.2'.toIntOrNull(), isNull);
      expect('4.2'.toDoubleOrNull(), 4.2);
      expect('abc'.toDoubleOrNull(), isNull);
      for (final yes in ['true', 'YES', 'y', 'On', '1']) {
        expect(yes.toBool(), isTrue, reason: yes);
      }
      expect('no'.toBool(), isFalse);
      expect(''.toBool(), isFalse);
    });

    test('case', () {
      expect('hello world'.capitalize(), 'Hello world');
      expect(''.capitalize(), '');
      expect('hello  WORLD'.toTitleCase(), 'Hello  World');
      expect('user name'.toCamelCase(), 'userName');
      expect('user_name-id'.toCamelCase(), 'userNameId');
      expect('UserName'.toCamelCase(), 'userName');
      expect('userName'.toSnakeCase(), 'user_name');
      expect('User Name 2'.toSnakeCase(), 'user_name_2');
      expect('userName'.toKebabCase(), 'user-name');
      expect(''.toCamelCase(), '');
    });

    test('editing', () {
      expect(' a b\tc\n'.removeWhitespace(), 'abc');
      expect('  a   b \n c '.collapseWhitespace(), 'a b c');
      expect('+91 98765-43210'.onlyDigits(), '919876543210');
      expect('abc'.reverse(), 'cba');
      expect('a👍🏽b'.reverse(), 'b👍🏽a');
    });

    test('truncate counts characters, not code units', () {
      expect('Hello world'.truncate(8), 'Hello w…');
      expect('Hello'.truncate(8), 'Hello');
      expect('Hello world'.truncate(9, ellipsis: '...'), 'Hello...');
      expect('👍🏽👍🏽👍🏽'.truncate(2), '👍🏽…');
      expect('Hello'.truncate(1), '…');
    });

    test('mask', () {
      expect('9876543210'.mask(), '••••••3210');
      expect(
        '4111111111111111'.mask(visibleStart: 4, char: '*'),
        '4111********1111',
      );
      expect('123'.mask(), '123');
    });

    test('initials', () {
      expect('Ranjit Kumar Makwana'.initials, 'RM');
      expect('asha'.initials, 'A');
      expect('  '.initials, '');
      // A letter with its vowel sign is one character.
      expect('राज कुमार'.initials, 'राकु');
    });
  });

  group('nullable String', () {
    test('null and blank helpers', () {
      const String? none = null;
      expect(none.isNullOrEmpty, isTrue);
      expect(none.isNullOrBlank, isTrue);
      expect(' '.isNullOrEmpty, isFalse);
      expect(' '.isNullOrBlank, isTrue);
      expect(none.orEmpty, '');
      expect(none.or('Guest'), 'Guest');
      expect(' '.or('Guest'), 'Guest');
      expect('Asha'.or('Guest'), 'Asha');
    });
  });

  group('double', () {
    test('roundTo, isWhole, toCleanString', () {
      expect(3.14159.roundTo(2), 3.14);
      expect(2.5.roundTo(0), 3.0);
      expect(3.0.isWhole, isTrue);
      expect(3.5.isWhole, isFalse);
      expect(double.infinity.isWhole, isFalse);
      expect(2.50.toCleanString(), '2.5');
      expect(3.0.toCleanString(), '3');
      expect(1.23456.toCleanString(), '1.23');
      expect(1200.0.toCleanString(), '1200');
      expect((-0.001).toCleanString(), '0');
      expect(double.nan.toCleanString(), 'NaN');
    });

    test('orZero', () {
      const double? none = null;
      expect(none.orZero, 0.0);
      expect(2.5.orZero, 2.5);
    });
  });

  group('num formatting', () {
    test('withSeparators', () {
      expect(1234567.891.withSeparators(decimals: 2), '1,234,567.89');
      expect(
        1234567.891.withSeparators(decimals: 2, indian: true),
        '12,34,567.89',
      );
      expect(999.withSeparators(), '999');
      expect(1000.withSeparators(separator: ' '), '1 000');
      expect((-1234.5).withSeparators(decimals: 1), '-1,234.5');
      expect((-0.001).withSeparators(), '0');
      expect(double.infinity.withSeparators(), 'Infinity');
    });

    test('toCurrency', () {
      expect(1499.5.toCurrency('₹'), '₹1,499.50');
      expect(150000.toCurrency('₹', decimals: 0, indian: true), '₹1,50,000');
      expect((-20).toCurrency(r'$'), r'-$20.00');
    });

    test('toCompact', () {
      expect(950.toCompact(), '950');
      expect(1250.toCompact(), '1.3K');
      expect(3400000.toCompact(), '3.4M');
      expect(2500000000.toCompact(), '2.5B');
      expect(1e12.toCompact(), '1T');
      expect((-1500).toCompact(), '-1.5K');
      expect(999950.toCompact(), '1M');
      expect(150000.toCompact(indian: true), '1.5L');
      expect(25000000.toCompact(indian: true), '2.5Cr');
      expect(99999.toCompact(indian: true), '1L');
      expect(0.04.toCompact(), '0');
      expect(12.5.toCompact(), '12.5');
    });

    test('toPercent and isBetween', () {
      expect(0.256.toPercent(), '26%');
      expect(0.256.toPercent(decimals: 1), '25.6%');
      expect(1.toPercent(), '100%');
      expect(5.isBetween(1, 5), isTrue);
      expect(5.5.isBetween(1, 5), isFalse);
    });

    test('layout helpers', () {
      expect(16.heightBox.height, 16);
      expect(8.5.widthBox.width, 8.5);
      expect(12.allInsets, const EdgeInsets.all(12));
      expect(12.horizontalInsets, const EdgeInsets.symmetric(horizontal: 12));
      expect(4.verticalInsets, const EdgeInsets.symmetric(vertical: 4));
      expect(10.borderRadius, BorderRadius.circular(10));
    });
  });
}
