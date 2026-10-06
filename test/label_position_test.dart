import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:services_rj/services_rj.dart';

Future<DynamicFormController> _pump(
  WidgetTester tester,
  Map<String, dynamic> json,
) async {
  final c = DynamicFormController();
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: DynamicForm(controller: c, json: json),
        ),
      ),
    ),
  );
  await tester.pump();
  return c;
}

Map<String, dynamic> _form(Map<String, dynamic>? style) => {
  'fields': [
    {
      'type': 'text',
      'id': 'name',
      'label': 'Guest name',
      'hint': 'As on the ticket',
      'style': ?style,
    },
  ],
};

/// Label text of a decoration: `labelText`, or the text of the
/// [FieldLabel] widget that carries the required / optional mark.
String? _label(InputDecoration d) =>
    d.labelText ??
    (d.label is FieldLabel ? (d.label! as FieldLabel).field.label : null);

InputDecoration _decoration(WidgetTester tester) =>
    tester.widget<TextField>(find.byType(TextField)).decoration!;

void main() {
  testWidgets('a visible field is not clipped, so the floating label shows', (
    tester,
  ) async {
    await _pump(tester, _form(null));
    // The reveal animation used to wrap every field in a ClipRect, which cut
    // the top half of an outlined field's floating label.
    expect(
      find.descendant(
        of: find.byType(FieldWrapper),
        matching: find.byType(ClipRect),
      ),
      findsNothing,
    );
    await tester.tap(find.byType(TextField));
    await tester.pump();
    expect(find.text('Guest name'), findsOneWidget);
  });

  testWidgets('hiding and showing a field still animates and works', (
    tester,
  ) async {
    final c = await _pump(tester, _form(null));
    c.hideField('name');
    await tester.pump(const Duration(milliseconds: 100));
    // Mid-animation the child is clipped while it shrinks.
    expect(
      find.descendant(
        of: find.byType(FieldWrapper),
        matching: find.byType(ClipRect),
      ),
      findsWidgets,
    );
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNothing);
    c.showField('name');
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(FieldWrapper),
        matching: find.byType(ClipRect),
      ),
      findsNothing,
    );
  });

  testWidgets('labelPosition floating (default) keeps the label in the field', (
    tester,
  ) async {
    await _pump(tester, _form(null));
    expect(_label(_decoration(tester)), 'Guest name');
    expect(_decoration(tester).hintText, 'As on the ticket');
  });

  testWidgets('labelPosition above draws the label outside the field', (
    tester,
  ) async {
    await _pump(tester, _form({'labelPosition': 'above'}));
    expect(_label(_decoration(tester)), isNull);
    expect(_decoration(tester).hintText, 'As on the ticket');
    final label = tester.getTopLeft(find.text('Guest name'));
    final field = tester.getTopLeft(find.byType(TextField));
    expect(label.dy, lessThan(field.dy));
  });

  testWidgets('above takes labelStyle and works for dropdowns', (tester) async {
    await _pump(tester, {
      'fields': [
        {
          'type': 'dropdown',
          'id': 'meal',
          'label': 'Meal preference',
          'options': ['Vegan', 'Jain'],
          'style': {
            'labelPosition': 'above',
            'labelStyle': {'color': '#E65100', 'fontWeight': 'bold'},
          },
        },
      ],
    });
    final text = tester.widget<Text>(find.text('Meal preference'));
    expect(text.style?.fontWeight, FontWeight.bold);
    expect(text.style?.color, const Color(0xFFE65100));
  });

  testWidgets('labelPosition hidden shows no label and uses it as the hint', (
    tester,
  ) async {
    await _pump(tester, {
      'fields': [
        {
          'type': 'text',
          'id': 'name',
          'label': 'Guest name',
          'style': {'labelPosition': 'hidden'},
        },
      ],
    });
    expect(_label(_decoration(tester)), isNull);
    expect(_decoration(tester).hintText, 'Guest name');
  });

  testWidgets('form-level style applies to every field', (tester) async {
    await _pump(tester, {
      'style': {'labelPosition': 'above'},
      'fields': [
        {'type': 'text', 'id': 'a', 'label': 'First'},
        {
          'type': 'text',
          'id': 'b',
          'label': 'Second',
          'style': {'labelPosition': 'floating'},
        },
      ],
    });
    final fields = tester
        .widgetList<TextField>(find.byType(TextField))
        .toList();
    expect(_label(fields[0].decoration!), isNull);
    expect(_label(fields[1].decoration!), 'Second');
  });

  test('labelPosition parses, merges and round-trips', () {
    final s = FieldStyleConfig.fromJson({'labelPosition': 'above'});
    expect(s.labelPosition, LabelPosition.above);
    expect(
      FieldStyleConfig.fromJson(s.toJson()).labelPosition,
      LabelPosition.above,
    );
    expect(FieldStyleConfig.knownKeys, contains('labelPosition'));
    expect(
      FieldStyleConfig.merge([s, const FieldStyleConfig()]).labelPosition,
      LabelPosition.above,
    );
    expect(LabelPosition.fromString('HIDDEN'), LabelPosition.hidden);
  });
}
