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

void main() {
  test('option style enums and keys parse', () {
    final f = FieldConfig.fromJson({
      'id': 'plan',
      'type': 'radioGroup',
      'optionStyle': 'card',
      'style': {
        'selectedColor': '#E0F2F1',
        'optionRadius': 16,
        'optionSpacing': 'compact',
        'optionPadding': {'horizontal': 'standard', 'vertical': 12},
      },
    });
    expect(f.optionStyle, OptionStyle.card);
    expect(f.styleConfig!.optionSpacing, 8);
    expect(
      f.styleConfig!.optionPadding,
      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
    expect(OptionStyle.fromString('pill'), OptionStyle.chip);
    expect(FieldConfig.fromJson(f.toJson()).optionStyle, OptionStyle.card);
    expect(FieldConfig.knownKeys, contains('optionStyle'));
  });

  test('spacing names work for padding and spacing', () {
    expect(
      FieldStyleConfig.parseEdgeInsets('standard'),
      const EdgeInsets.all(16),
    );
    expect(FormSpacing.parse('comfortable'), 24);
    expect(FormSpacing.parse(12), 12);
    final form = FormConfig.fromJson({
      'padding': 'standard',
      'fieldSpacing': 'compact',
      'fieldPadding': {'horizontal': 4},
    });
    expect(form.padding, const EdgeInsets.all(16));
    expect(form.fieldSpacing, 8);
    expect(FormConfig.fromJson(form.toJson()).padding, form.padding);
  });

  testWidgets('form padding reaches the field list', (tester) async {
    await _pump(tester, {
      'padding': 'standard',
      'fields': [
        {'type': 'text', 'id': 'a', 'label': 'A'},
      ],
    });
    final list = tester.widget<ListView>(find.byType(ListView));
    expect(list.padding, const EdgeInsets.all(16));
  });

  testWidgets('card radio group selects on tap', (tester) async {
    final c = await _pump(tester, {
      'fields': [
        {
          'type': 'radioGroup',
          'id': 'plan',
          'label': 'Plan',
          'optionStyle': 'card',
          'options': [
            {'label': 'Free', 'value': 'free', 'description': 'For trying'},
            {'label': 'Pro', 'value': 'pro'},
          ],
        },
      ],
    });
    expect(find.byType(StyledOption), findsNWidgets(2));
    await tester.tap(find.text('Pro'));
    await tester.pump();
    expect(c.getFormData()['plan'], 'pro');
  });

  testWidgets('button and chip checkbox groups toggle and honour maxItems', (
    tester,
  ) async {
    for (final style in ['button', 'chip']) {
      final c = await _pump(tester, {
        'fields': [
          {
            'type': 'checkboxGroup',
            'id': 'days',
            'label': 'Days',
            'optionStyle': style,
            'maxItems': 2,
            'options': ['Mon', 'Tue', 'Wed'],
          },
        ],
      });
      await tester.tap(find.text('Mon'));
      await tester.pump();
      await tester.tap(find.text('Tue'));
      await tester.pump();
      await tester.tap(find.text('Wed'));
      await tester.pump();
      expect(c.getFormData()['days'], ['Mon', 'Tue'], reason: style);
      await tester.tap(find.text('Mon'));
      await tester.pump();
      expect(c.getFormData()['days'], ['Tue'], reason: style);
      await tester.pumpWidget(const SizedBox());
      c.dispose();
    }
  });

  testWidgets('single checkbox and switch render as cards', (tester) async {
    final c = await _pump(tester, {
      'fields': [
        {
          'type': 'checkbox',
          'id': 'terms',
          'label': 'I accept the terms',
          'optionStyle': 'card',
          'controlShape': 'circle',
        },
        {
          'type': 'switch',
          'id': 'alerts',
          'label': 'Alerts',
          'optionStyle': 'card',
        },
      ],
    });
    await tester.tap(find.text('I accept the terms'));
    await tester.pump();
    await tester.tap(find.byType(Switch));
    await tester.pump();
    expect(c.getFormData(), containsPair('terms', true));
    expect(c.getFormData(), containsPair('alerts', true));
  });

  testWidgets('standard checkbox honours controlShape and position', (
    tester,
  ) async {
    await _pump(tester, {
      'fields': [
        {
          'type': 'checkboxGroup',
          'id': 'x',
          'controlShape': 'circle',
          'controlPosition': 'trailing',
          'options': ['A'],
        },
      ],
    });
    final tile = tester.widget<CheckboxListTile>(find.byType(CheckboxListTile));
    expect(tile.checkboxShape, isA<CircleBorder>());
    expect(tile.controlAffinity, ListTileControlAffinity.trailing);
  });
}
