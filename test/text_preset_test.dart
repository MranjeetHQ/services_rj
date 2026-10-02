import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:services_rj/services_rj.dart';

DynamicFormController _form(List<Map<String, dynamic>> fields) {
  return DynamicFormController()..attach(FormParser.parse({'fields': fields}));
}

String? _error(String preset, String? value, {Map<String, dynamic>? extra}) {
  final c = _form([
    {'type': 'text', 'id': 'f', 'preset': preset, ...?extra},
  ]);
  c.setValue('f', value);
  final error = c.validateField('f');
  c.dispose();
  return error;
}

void main() {
  const valid = <String, List<String>>{
    'name': ['Meera Iyer', "D'Souza-Rao", 'प्रिया शर्मा'],
    'mobile': ['9876543210', '6000000000'],
    'phone': ['+91 22 1234 5678', '02212345678', '(022) 1234-5678'],
    'pan': ['ABCPE1234F', 'abcpe1234f'],
    'aadhaar': ['234567890124', '2345 6789 0124'],
    'gst': ['27AAPFU0939F1ZV', '22AAAAA0000A1ZC'],
    'ifsc': ['HDFC0001234', 'SBIN0A12345'],
    'pincode': ['400001', '110011'],
    'vehicleNumber': ['MH12AB1234', 'DL1CAB1234', 'MH 12 AB 1234'],
    'voterId': ['ABC1234567'],
    'passport': ['K1234567'],
    'upiId': ['meera.iyer@okhdfcbank', 'a_b-c@ybl'],
  };
  const invalid = <String, List<String>>{
    'name': ['A', '12345', 'Meera@Iyer'],
    'mobile': ['5876543210', '987654321', '98765432101', 'abcdefghij'],
    'phone': ['12345', '+1234567890123456', 'call-me-maybe'],
    'pan': ['ABCDE1234F', 'ABCPE12345', 'ABCP1234FE', 'ABC'],
    'aadhaar': ['134567890124', '234567890123', '2345678901', 'abcdefghijkl'],
    'gst': ['27AAPFU0939F1ZX', '99AAPFU0939F1ZV', '27AAPFU0939F1AV', 'GST'],
    'ifsc': ['HDFC1001234', 'HDF00001234', 'HDFC000123'],
    'pincode': ['012345', '40000', '4000011'],
    'vehicleNumber': ['1212AB1234', 'MH12AB12', 'MH12ABCD1234'],
    'voterId': ['AB12345678', 'ABC123456'],
    'passport': ['Q1234567', 'K0234567', 'K123456'],
    'upiId': ['meera', 'meera@', '@ybl', 'me era@ybl'],
  };

  group('every preset has samples', () {
    test('built-in presets are all covered', () {
      final covered = {...valid.keys, ...invalid.keys, 'custom'};
      expect(
        TextPreset.values.map((p) => p.name).toSet().difference(covered),
        isEmpty,
      );
    });
  });

  group('validation', () {
    valid.forEach((preset, samples) {
      for (final s in samples) {
        test('$preset accepts "$s"', () => expect(_error(preset, s), isNull));
      }
    });
    invalid.forEach((preset, samples) {
      for (final s in samples) {
        test(
          '$preset rejects "$s"',
          () => expect(_error(preset, s), isNotNull),
        );
      }
    });

    test('empty passes unless required', () {
      expect(_error('pan', null), isNull);
      expect(_error('pan', null, extra: {'required': true}), isNotNull);
    });

    test('presetMessage replaces the default message', () {
      expect(
        _error('pan', 'nope', extra: {'presetMessage': 'Bad PAN'}),
        'Bad PAN',
      );
      expect(_error('pan', 'nope'), contains('PAN'));
    });

    test('works inside a repeater entry and with other validators', () {
      final c = _form([
        {
          'type': 'repeater',
          'id': 'people',
          'initialItems': 1,
          'fields': [
            {'type': 'text', 'id': 'pan', 'preset': 'pan', 'required': true},
          ],
        },
      ]);
      c.entriesOf('people').first.controller.setValue('pan', 'bad');
      expect(c.validate(), isFalse);
      c.entriesOf('people').first.controller.setValue('pan', 'ABCPE1234F');
      expect(c.validate(), isTrue);
      c.dispose();
    });
  });

  group('custom option', () {
    test('preset custom uses the field regex and presetMessage', () {
      const extra = {
        'regex': r'^EMP-\d{4}$',
        'presetMessage': 'Use EMP-1234',
        'textCase': 'upper',
        'maxLength': 8,
      };
      expect(_error('custom', 'EMP-1234', extra: extra), isNull);
      expect(_error('custom', 'EMP-12', extra: extra), 'Use EMP-1234');
    });

    test('registered presets work by name, also in snake_case', () {
      TextPresets.register(
        'employeeId',
        const TextPresetSpec(
          message: 'Employee id looks like E-12345',
          pattern: r'^E-\d{5}$',
          textCase: TextCase.upper,
          maxLength: 7,
        ),
      );
      expect(TextPresets.names, contains('employeeId'));
      expect(_error('employeeId', 'E-12345'), isNull);
      expect(_error('employee_id', 'e-12345'), isNull);
      expect(_error('employeeId', 'E-123'), contains('E-12345'));
    });

    test('a registered spec can add a checksum', () {
      TextPresets.register(
        'evenSum',
        TextPresetSpec(
          message: 'Digits must sum to an even number',
          pattern: r'^\d+$',
          check: (v) =>
              v.split('').map(int.parse).reduce((a, b) => a + b).isEven,
        ),
      );
      expect(_error('evenSum', '1122'), isNull);
      expect(_error('evenSum', '1121'), isNotNull);
    });

    test('unknown presets are ignored instead of crashing', () {
      expect(_error('doesNotExist', 'anything'), isNull);
    });
  });

  group('input behaviour', () {
    FieldConfig field(String preset, [Map<String, dynamic>? extra]) =>
        FieldConfig.fromJson({
          'type': 'text',
          'id': 'f',
          'preset': preset,
          ...?extra,
        });

    String typed(FieldConfig f, String input) {
      var value = TextEditingValue.empty;
      for (final ch in input.split('')) {
        var next = TextEditingValue(
          text: value.text + ch,
          selection: TextSelection.collapsed(offset: value.text.length + 1),
        );
        for (final fmt in FieldUtils.formatters(f)) {
          next = fmt.formatEditUpdate(value, next);
        }
        value = next;
      }
      return value.text;
    }

    test('PAN is upper-cased, alphanumeric and limited to 10', () {
      expect(typed(field('pan'), 'abcpe-1234f99'), 'ABCPE1234F');
    });

    test('mobile accepts only 10 digits', () {
      expect(typed(field('mobile'), '98a76-543210999'), '9876543210');
    });

    test('name rejects digits but keeps unicode letters', () {
      expect(typed(field('name'), 'Meera 7 Iyer'), 'Meera  Iyer');
      expect(typed(field('name'), 'प्रिया'), 'प्रिया');
    });

    test('field settings win over the preset', () {
      final f = field('pan', {'maxLength': 4, 'textCase': 'lower'});
      expect(typed(f, 'ABCDEFG'), 'abcd');
    });

    test('keyboard and capitalization come from the preset', () {
      expect(FieldUtils.keyboardType(field('mobile')), TextInputType.phone);
      expect(FieldUtils.keyboardType(field('aadhaar')), TextInputType.number);
      expect(
        FieldUtils.capitalization(field('gst')),
        TextCapitalization.characters,
      );
      expect(
        FieldUtils.keyboardType(field('mobile', {'keyboardType': 'text'})),
        TextInputType.text,
      );
    });
  });

  group('JSON', () {
    test('preset keys round-trip through toJson', () {
      final f = FieldConfig.fromJson({
        'type': 'text',
        'id': 'f',
        'preset': 'gst',
        'presetMessage': 'Bad GSTIN',
      });
      expect(f.preset, 'gst');
      final again = FieldConfig.fromJson(f.toJson());
      expect(again.preset, 'gst');
      expect(again.presetMessage, 'Bad GSTIN');
      expect(f.extra.containsKey('preset'), isFalse);
    });

    test('TextPreset.tryParse accepts common spellings', () {
      expect(TextPreset.tryParse('vehicle_number'), TextPreset.vehicleNumber);
      expect(TextPreset.tryParse('UPI-id'), TextPreset.upiId);
      expect(TextPreset.tryParse('nope'), isNull);
    });
  });

  testWidgets('a preset field shows hint, icon and validates on submit', (
    tester,
  ) async {
    final c = DynamicFormController();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DynamicForm(
            controller: c,
            json: const {
              'fields': [
                {
                  'type': 'text',
                  'id': 'pan',
                  'label': 'PAN',
                  'preset': 'pan',
                  'required': true,
                },
              ],
            },
          ),
        ),
      ),
    );
    expect(find.text('ABCPE1234F'), findsOneWidget); // preset hint
    expect(find.byIcon(Icons.badge_outlined), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'abcde');
    await tester.pump();
    expect(c.getValue('pan'), 'ABCDE');
    expect(c.validate(), isFalse);
    await tester.enterText(find.byType(TextField), 'abcpe1234f');
    await tester.pump();
    expect(c.getValue('pan'), 'ABCPE1234F');
    expect(c.validate(), isTrue);
    c.dispose();
  });
}
