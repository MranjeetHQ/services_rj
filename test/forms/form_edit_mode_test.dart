import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:services_rj/services_rj.dart';

const _formJson = {
  'confirmDiscard': true,
  'fields': [
    {'type': 'text', 'id': 'name', 'label': 'Name', 'defaultValue': 'anon'},
    {'type': 'email', 'id': 'email', 'label': 'Email'},
    {
      'type': 'chips',
      'id': 'tags',
      'multiple': true,
      'items': ['a', 'b'],
    },
  ],
};

const _record = {
  'name': 'Rupesh',
  'email': 'rupeshrajak438@gmail.com',
  'tags': ['a'],
};

void main() {
  group('edit mode (controller)', () {
    late DynamicFormController c;
    setUp(() => c = DynamicFormController());
    tearDown(() => c.dispose());

    test('attach with initialData prefills and stays clean', () {
      c.attach(FormParser.parse(_formJson), initialData: _record);
      expect(c.getValue('name'), 'Rupesh');
      expect(c.getValue('email'), 'rupeshrajak438@gmail.com');
      expect(c.getList('tags'), ['a']);
      expect(c.isDirty, isFalse, reason: 'untouched edit form is not dirty');
    });

    test('initialData wins over defaultValue; absent keys keep defaults', () {
      c.attach(
        FormParser.parse(_formJson),
        initialData: const {'email': 'x@y.com'},
      );
      expect(c.getValue('email'), 'x@y.com');
      expect(c.getValue('name'), 'anon', reason: 'default kept');
    });

    test('JSON root "data" map prefills (server-driven edit)', () {
      c.attach(
        FormParser.parse(const {
          'data': {'name': 'FromServer'},
          'fields': [
            {'type': 'text', 'id': 'name'},
          ],
        }),
      );
      expect(c.getValue('name'), 'FromServer');
      expect(c.isDirty, isFalse);
    });

    test('reset returns to the record, not to defaults', () {
      c.attach(FormParser.parse(_formJson), initialData: _record);
      c.setValue('name', 'Changed');
      expect(c.isDirty, isTrue);
      c.reset();
      expect(c.getValue('name'), 'Rupesh');
      expect(c.isDirty, isFalse);
    });

    test('dirty only relative to the record baseline', () {
      c.attach(FormParser.parse(_formJson), initialData: _record);
      c.setValue('name', 'Changed');
      expect(c.isDirty, isTrue);
      c.setValue('name', 'Rupesh');
      expect(c.isDirty, isFalse, reason: 'typed back to record value');
    });

    test('setFormData asInitial loads a record without dirtying', () {
      c.attach(FormParser.parse(_formJson));
      c.setFormData(_record, asInitial: true);
      expect(c.isDirty, isFalse);
      expect(c.getValue('name'), 'Rupesh');
      c.setValue('name', 'x');
      c.reset();
      expect(c.getValue('name'), 'Rupesh', reason: 'reset restores record');
    });

    test('plain setFormData still marks dirty', () {
      c.attach(FormParser.parse(_formJson));
      c.setFormData(const {'name': 'x'});
      expect(c.isDirty, isTrue);
    });

    test('runtime JSON change preserves dirty state and baseline', () {
      c.attach(FormParser.parse(_formJson), initialData: _record);
      c.setValue('name', 'Edited');
      expect(c.isDirty, isTrue);
      c.attach(FormParser.parse(_formJson)); // e.g. restyled form
      expect(c.getValue('name'), 'Edited', reason: 'value survives');
      expect(c.isDirty, isTrue, reason: 'dirty survives re-attach');
      c.setValue('name', 'Rupesh');
      expect(c.isDirty, isFalse, reason: 'baseline survived re-attach');
    });
  });

  group('edit mode (widget)', () {
    late DynamicFormController controller;
    setUp(() => controller = DynamicFormController());
    tearDown(() => controller.dispose());

    Future<void> pumpEditRoute(
      WidgetTester tester, {
      Map<String, dynamic>? initialData,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => Scaffold(
                        appBar: AppBar(title: const Text('Edit')),
                        body: DynamicForm(
                          controller: controller,
                          json: _formJson,
                          initialData: initialData,
                        ),
                      ),
                    ),
                  ),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
    }

    testWidgets('prefilled values render in the fields', (tester) async {
      await pumpEditRoute(tester, initialData: _record);
      expect(find.text('Rupesh'), findsOneWidget);
      expect(find.text('rupeshrajak438@gmail.com'), findsOneWidget);
    });

    testWidgets('prefilled form pops without discard dialog', (tester) async {
      await pumpEditRoute(tester, initialData: _record);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Discard changes?'), findsNothing);
      expect(find.text('Open'), findsOneWidget);
    });

    testWidgets('editing a prefilled form arms the discard dialog', (
      tester,
    ) async {
      await pumpEditRoute(tester, initialData: _record);
      await tester.enterText(find.byType(TextField).first, 'Edited');
      await tester.pump();
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Discard changes?'), findsOneWidget);
    });
  });
}
