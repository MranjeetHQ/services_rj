import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:services_rj/forms.dart';

Future<DynamicFormController> _pump(
  WidgetTester tester,
  Map<String, dynamic> form,
) async {
  final c = DynamicFormController();
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: DynamicForm(controller: c, json: form),
      ),
    ),
  );
  await tester.pump();
  return c;
}

/// Plain text of every rendered [FieldLabel], without semantics labels.
List<String> _labels(WidgetTester tester) => [
  for (final e in find.byType(FieldLabel).evaluate())
    for (final t
        in find
            .descendant(
              of: find.byWidget(e.widget),
              matching: find.byType(Text),
            )
            .evaluate()
            .map((e) => e.widget as Text))
      t.textSpan?.toPlainText(includeSemanticsLabels: false) ?? t.data ?? '',
];

void main() {
  testWidgets('asterisk on required fields of every kind by default', (
    tester,
  ) async {
    await _pump(tester, {
      'fields': [
        {'type': 'text', 'id': 'a', 'label': 'Name', 'required': true},
        {'type': 'email', 'id': 'b', 'label': 'Email'},
        {
          'type': 'text',
          'id': 'c',
          'label': 'Via validator',
          'validators': ['required'],
        },
        {
          'type': 'radioGroup',
          'id': 'd',
          'label': 'Plan',
          'required': true,
          'options': ['A', 'B'],
        },
        {'type': 'checkbox', 'id': 'e', 'label': 'Terms', 'required': true},
        {
          'type': 'searchableDropdown',
          'id': 'f',
          'label': 'City',
          'required': true,
          'options': ['X'],
        },
        {'type': 'slider', 'id': 'g', 'label': 'Volume', 'required': true},
        {'type': 'sectionHeader', 'id': 'h', 'label': 'Section'},
      ],
    });
    expect(
      _labels(tester),
      containsAll([
        'Name *',
        'Email',
        'Via validator *',
        'Plan *',
        'Terms *',
        'City *',
        'Volume *',
      ]),
    );
    expect(find.text('Section'), findsOneWidget); // display fields: no mark
  });

  testWidgets('optional and both modes, set at form level', (tester) async {
    await _pump(tester, {
      'style': {'requiredMark': 'both'},
      'fields': [
        {'type': 'text', 'id': 'a', 'label': 'Name', 'required': true},
        {'type': 'text', 'id': 'b', 'label': 'Nickname'},
        {
          'type': 'text',
          'id': 'c',
          'label': 'Plain',
          'style': {'requiredMark': 'none'},
          'required': true,
        },
        {
          'type': 'text',
          'id': 'd',
          'label': 'Opt',
          'style': {'requiredMark': 'optional'},
        },
      ],
    });
    expect(
      _labels(tester),
      containsAll(['Name *', 'Nickname (optional)', 'Opt (optional)']),
    );
    // `none`: a plain label, no mark.
    final plain = tester.widget<TextField>(find.byType(TextField).at(2));
    expect(plain.decoration!.labelText, 'Plain');
  });

  testWidgets('mark follows requiredWhen and setRequired', (tester) async {
    final c = await _pump(tester, {
      'fields': [
        {'type': 'checkbox', 'id': 'company', 'label': 'Company purchase'},
        {
          'type': 'text',
          'id': 'gstin',
          'label': 'GSTIN',
          'requiredWhen': {'field': 'company', 'operator': 'isTrue'},
        },
      ],
    });
    expect(_labels(tester), contains('GSTIN'));
    c.setValue('company', true);
    await tester.pump();
    expect(_labels(tester), contains('GSTIN *'));
    expect(c.validateField('gstin'), 'This field is required');

    c.setValue('company', false);
    await tester.pump();
    expect(_labels(tester), contains('GSTIN'));
    expect(c.validateField('gstin'), isNull);

    c.setRequired('gstin', required: true);
    await tester.pump();
    expect(_labels(tester), contains('GSTIN *'));
  });

  testWidgets('screen readers hear "required"', (tester) async {
    final handle = tester.ensureSemantics();
    await _pump(tester, {
      'fields': [
        {'type': 'text', 'id': 'a', 'label': 'Name', 'required': true},
      ],
    });
    expect(find.bySemanticsLabel(RegExp('Name, required')), findsWidgets);
    handle.dispose();
  });

  group('optional fields may stay empty', () {
    DynamicFormController attach(Map<String, dynamic> field) =>
        DynamicFormController()..attach(
          FormConfig.fromJson({
            'fields': [
              field,
              {'type': 'text', 'id': 'other'},
            ],
          }),
        );

    test('format, length and item checks skip an empty optional field', () {
      for (final field in [
        {
          'type': 'email',
          'id': 'f',
          'validators': ['email'],
        },
        {'type': 'text', 'id': 'f', 'minLength': 3},
        {'type': 'text', 'id': 'f', 'preset': 'pan'},
        {
          'type': 'checkboxGroup',
          'id': 'f',
          'minItems': 2,
          'options': ['a', 'b', 'c'],
        },
        {
          'type': 'number',
          'id': 'f',
          'validators': [
            {'type': 'min', 'value': 5},
          ],
        },
      ]) {
        final c = attach(field);
        expect(c.validateField('f'), isNull, reason: '$field');
        c.dispose();
      }
    });

    test('the same field validates once it has a value or is required', () {
      final c = attach({'type': 'text', 'id': 'f', 'minLength': 3});
      c.setValue('f', 'ab');
      expect(c.validateField('f'), 'Must be at least 3 characters');
      c.setValue('f', '');
      c.setRequired('f', required: true);
      expect(c.validateField('f'), 'This field is required');
      c.dispose();
    });

    test('custom validators and matchField still see empty values', () {
      final c =
          DynamicFormController(
            customValidators: {
              'phoneOrEmail': (value, data) =>
                  (value == null || value == '') && data['other'] == null
                  ? 'Give a phone or an email'
                  : null,
            },
          )..attach(
            FormConfig.fromJson({
              'fields': [
                {'type': 'text', 'id': 'other'},
                {
                  'type': 'text',
                  'id': 'f',
                  'validators': [
                    {'type': 'custom', 'name': 'phoneOrEmail'},
                  ],
                },
                {
                  'type': 'password',
                  'id': 'confirm',
                  'validators': [
                    {'type': 'matchField', 'value': 'other'},
                  ],
                },
              ],
            }),
          );
      expect(c.validateField('f'), 'Give a phone or an email');
      expect(c.validateField('confirm'), isNull); // both empty
      c.setValue('other', 'secret');
      expect(c.validateField('f'), isNull);
      expect(c.validateField('confirm'), 'Fields do not match');
      c.dispose();
    });
  });
}
