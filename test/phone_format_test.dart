import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:services_rj/services_rj.dart';

Map<String, dynamic> _form({Map<String, dynamic>? phone}) => {
  'fields': [
    {
      'type': 'phone',
      'id': 'mobile',
      'label': 'Mobile',
      'countryCode': true,
      ...?phone,
    },
    {'type': 'text', 'id': 'name', 'label': 'Name'},
  ],
};

DynamicFormController _controller(
  Map<String, dynamic> json, {
  PhoneFormat format = PhoneFormat.combined,
  Map<String, dynamic>? initialData,
}) =>
    DynamicFormController(phoneFormat: format)
      ..attach(FormParser.parse(json), initialData: initialData);

void main() {
  group('getFormData shape', () {
    test('combined is the default', () {
      final c = _controller(_form())..setValue('mobile', '+919876543210');
      expect(c.getFormData(), {'mobile': '+919876543210', 'name': null});
    });

    test('separate reports the number and the code under two keys', () {
      final c = _controller(_form())..setValue('mobile', '+919876543210');
      expect(c.getFormData(phoneFormat: PhoneFormat.separate), {
        'mobile': '9876543210',
        'mobileCountryCode': '+91',
        'name': null,
      });
    });

    test('an empty phone gives null for both keys', () {
      final c = _controller(_form());
      expect(c.getFormData(phoneFormat: PhoneFormat.separate), {
        'mobile': null,
        'mobileCountryCode': null,
        'name': null,
      });
    });

    test('the controller default applies to every phone field', () {
      final c = _controller(_form(), format: PhoneFormat.separate)
        ..setValue('mobile', '+447911123456');
      expect(c.getFormData(), containsPair('mobileCountryCode', '+44'));
      expect(c.getFormData(), containsPair('mobile', '7911123456'));
    });

    test('a field phoneFormat key wins over the controller default', () {
      final c = _controller(
        _form(phone: {'phoneFormat': 'combined'}),
        format: PhoneFormat.separate,
      )..setValue('mobile', '+447911123456');
      expect(c.getFormData()['mobile'], '+447911123456');
      expect(c.getFormData().containsKey('mobileCountryCode'), isFalse);

      final d = _controller(_form(phone: {'phoneFormat': 'separate'}))
        ..setValue('mobile', '+447911123456');
      expect(d.getFormData(), containsPair('mobileCountryCode', '+44'));
    });

    test('the getFormData argument wins over field and controller', () {
      final c = _controller(
        _form(phone: {'phoneFormat': 'separate'}),
        format: PhoneFormat.separate,
      )..setValue('mobile', '+919876543210');
      expect(
        c.getFormData(phoneFormat: PhoneFormat.combined)['mobile'],
        '+919876543210',
      );
    });

    test('countryCodeKey names the code key', () {
      final c = _controller(_form(phone: {'countryCodeKey': 'dial'}))
        ..setValue('mobile', '+919876543210');
      expect(
        c.getFormData(phoneFormat: PhoneFormat.separate),
        containsPair('dial', '+91'),
      );
    });

    test('phone fields without a country code are never split', () {
      final c = _controller(
        _form(phone: {'countryCode': false}),
        format: PhoneFormat.separate,
      )..setValue('mobile', '+919876543210');
      expect(c.getFormData()['mobile'], '+919876543210');
      expect(c.getFormData().containsKey('mobileCountryCode'), isFalse);
    });

    test('onChanged and onSubmit use the configured shape', () {
      final c = _controller(_form(), format: PhoneFormat.separate);
      Map<String, dynamic>? changed;
      Map<String, dynamic>? submitted;
      c.onChanged = (id, value, data) {
        changed = data;
      };
      c.onSubmit = (data) {
        submitted = data;
      };
      c.setValue('mobile', '+919876543210');
      expect(changed, containsPair('mobileCountryCode', '+91'));
      c.submit();
      expect(submitted, containsPair('mobile', '9876543210'));
      expect(submitted, containsPair('mobileCountryCode', '+91'));
    });

    test('validation and conditions always see the combined value', () {
      final c = _controller({
        'fields': [
          {
            'type': 'phone',
            'id': 'mobile',
            'countryCode': true,
            'required': true,
          },
          {
            'type': 'text',
            'id': 'note',
            'visibleWhen': {
              'field': 'mobile',
              'operator': 'startsWith',
              'value': '+91',
            },
          },
        ],
      }, format: PhoneFormat.separate)..setValue('mobile', '+919876543210');
      expect(c.validate(), isTrue);
      expect(c.state('note').visible.value, isTrue);
      c.setValue('mobile', '+447911123456');
      expect(c.state('note').visible.value, isFalse);
    });
  });

  group('input accepts either shape', () {
    test('initialData with separate keys fills the field', () {
      final c = _controller(
        _form(),
        initialData: {'mobile': '98765 43210', 'mobileCountryCode': '+91'},
      );
      expect(c.getValue('mobile'), '+919876543210');
      expect(c.isDirty, isFalse);
    });

    test('initialData with a combined value still works', () {
      final c = _controller(_form(), initialData: {'mobile': '+447911123456'});
      expect(c.getValue('mobile'), '+447911123456');
    });

    test('a country code can be given by ISO code', () {
      final c = _controller(
        _form(),
        initialData: {'mobile': '7911123456', 'mobileCountryCode': 'GB'},
      );
      expect(c.getValue('mobile'), '+447911123456');
    });

    test('setFormData accepts separate keys and reset restores them', () {
      final c = _controller(_form());
      c.setFormData({
        'mobile': '9876543210',
        'mobileCountryCode': '+91',
      }, asInitial: true);
      expect(c.getValue('mobile'), '+919876543210');
      c.setValue('mobile', '+971501234567');
      c.reset();
      expect(c.getValue('mobile'), '+919876543210');
    });

    test('a number without a code stays as typed', () {
      final c = _controller(_form(), initialData: {'mobile': '9876543210'});
      expect(c.getValue('mobile'), '9876543210');
    });

    test('round trip: separate data in, separate data out', () {
      final record = {
        'mobile': '9876543210',
        'mobileCountryCode': '+91',
        'name': 'Meera',
      };
      final c = _controller(_form(), initialData: record);
      expect(c.getFormData(phoneFormat: PhoneFormat.separate), record);
    });
  });

  group('controller accessors', () {
    test('full number, code and national number', () {
      final c = _controller(_form())..setValue('mobile', '+919876543210');
      expect(c.getPhoneNumber('mobile'), '+919876543210');
      expect(c.getCountryCode('mobile'), '+91');
      expect(c.getNationalNumber('mobile'), '9876543210');
      expect(c.getPhone('mobile'), (dial: '+91', number: '9876543210'));
    });

    test('all are null for an empty field', () {
      final c = _controller(_form());
      expect(c.getPhoneNumber('mobile'), isNull);
      expect(c.getCountryCode('mobile'), isNull);
      expect(c.getNationalNumber('mobile'), isNull);
    });

    test('setPhone writes code and number, and clears on empty', () {
      final c = _controller(_form());
      c.setPhone('mobile', dial: '+44', number: '7911 123456');
      expect(c.getValue('mobile'), '+447911123456');
      c.setPhone('mobile', dial: 'IN', number: '9876543210');
      expect(c.getValue('mobile'), '+919876543210');
      c.setPhone('mobile', dial: '+91', number: '');
      expect(c.getValue('mobile'), isNull);
    });
  });

  group('repeaters', () {
    final json = {
      'fields': [
        {
          'type': 'repeater',
          'id': 'people',
          'initialItems': 1,
          'fields': [
            {'type': 'phone', 'id': 'mobile', 'countryCode': true},
          ],
        },
      ],
    };

    test('entries follow the controller format', () {
      final c = _controller(json, format: PhoneFormat.separate);
      c
          .entriesOf('people')
          .first
          .controller
          .setValue('mobile', '+919876543210');
      expect((c.getFormData()['people'] as List).first, {
        'mobile': '9876543210',
        'mobileCountryCode': '+91',
      });
    });

    test('the getFormData argument reaches the entries', () {
      final c = _controller(json);
      c
          .entriesOf('people')
          .first
          .controller
          .setValue('mobile', '+919876543210');
      expect(
        (c.getFormData(phoneFormat: PhoneFormat.separate)['people'] as List)
            .first,
        {'mobile': '9876543210', 'mobileCountryCode': '+91'},
      );
      expect((c.getFormData()['people'] as List).first, {
        'mobile': '+919876543210',
      });
    });

    test('prefilling entries accepts separate keys', () {
      final c = _controller(
        json,
        initialData: {
          'people': [
            {'mobile': '9876543210', 'mobileCountryCode': '+91'},
          ],
        },
      );
      expect(c.entriesOf('people').first.data['mobile'], '+919876543210');
    });
  });

  test('PhoneFormat parses names', () {
    expect(PhoneFormat.fromString('SEPARATE'), PhoneFormat.separate);
    expect(PhoneFormat.fromString('nope'), isNull);
  });

  testWidgets('typing in the picker field feeds both shapes', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final c = DynamicFormController(phoneFormat: PhoneFormat.separate);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DynamicForm(controller: c, json: _form()),
        ),
      ),
    );
    await tester.enterText(find.byType(TextField).first, '98765 43210');
    await tester.pump();
    expect(c.getFormData(), containsPair('mobile', '9876543210'));
    expect(c.getFormData(), containsPair('mobileCountryCode', '+91'));
    expect(c.getPhoneNumber('mobile'), '+919876543210');
  });
}
