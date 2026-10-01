import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:services_rj/services_rj.dart';

const _guardedJson = {
  'confirmDiscard': true,
  'fields': [
    {'type': 'text', 'id': 'name', 'label': 'Name'},
  ],
};

void main() {
  group('dirty tracking (controller)', () {
    late DynamicFormController c;
    setUp(() {
      c = DynamicFormController();
      c.attach(
        FormParser.parse(const {
          'fields': [
            {'type': 'text', 'id': 'name', 'defaultValue': 'anon'},
            {
              'type': 'chips',
              'id': 'tags',
              'multiple': true,
              'items': ['a', 'b'],
            },
          ],
        }),
      );
    });
    tearDown(() => c.dispose());

    test('clean after attach; dirty after change; clean after revert', () {
      expect(c.isDirty, isFalse);
      c.setValue('name', 'John');
      expect(c.isDirty, isTrue);
      c.setValue('name', 'anon');
      expect(c.isDirty, isFalse, reason: 'back to baseline value');
    });

    test('deep-compares list values', () {
      c.setValue('tags', ['a']);
      expect(c.isDirty, isTrue);
      c.setValue('tags', null);
      expect(c.isDirty, isFalse);
    });

    test('reset and markClean clear dirty', () {
      c.setValue('name', 'x');
      c.reset();
      expect(c.isDirty, isFalse);
      c.setValue('name', 'y');
      c.markClean();
      expect(c.isDirty, isFalse);
    });

    test('successful submit marks clean', () {
      c.setValue('name', 'John');
      expect(c.isDirty, isTrue);
      c.submit();
      expect(c.isDirty, isFalse);
    });

    test('dirty notifier fires', () {
      final events = <bool>[];
      c.dirty.addListener(() => events.add(c.dirty.value));
      c.setValue('name', 'x');
      c.markClean();
      expect(events, [true, false]);
    });
  });

  group('discard guard (widget)', () {
    late DynamicFormController controller;
    setUp(() => controller = DynamicFormController());
    tearDown(() => controller.dispose());

    Future<void> pumpWithRoute(
      WidgetTester tester,
      Object json, {
      bool? confirmDiscard,
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
                        appBar: AppBar(title: const Text('Form')),
                        body: DynamicForm(
                          controller: controller,
                          json: json,
                          confirmDiscard: confirmDiscard,
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

    testWidgets('typing then back shows dialog; cancel stays, discard pops', (
      tester,
    ) async {
      await pumpWithRoute(tester, _guardedJson);
      await tester.enterText(find.byType(TextField), 'draft');
      await tester.pump();
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Discard changes?'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Form'), findsOneWidget, reason: 'stayed on form');

      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();
      expect(find.text('Open'), findsOneWidget, reason: 'route popped');
    });

    testWidgets('clean form pops without dialog', (tester) async {
      await pumpWithRoute(tester, _guardedJson);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Discard changes?'), findsNothing);
      expect(find.text('Open'), findsOneWidget);
    });

    testWidgets('confirmDiscard false in JSON disables the guard', (
      tester,
    ) async {
      await pumpWithRoute(tester, const {
        'confirmDiscard': false,
        'fields': [
          {'type': 'text', 'id': 'name'},
        ],
      });
      await tester.enterText(find.byType(TextField), 'draft');
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Open'), findsOneWidget, reason: 'no dialog');
    });

    testWidgets('code override wins over JSON', (tester) async {
      await pumpWithRoute(tester, _guardedJson, confirmDiscard: false);
      await tester.enterText(find.byType(TextField), 'draft');
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Open'), findsOneWidget);
    });

    testWidgets('custom discardTitle/discardMessage from JSON', (tester) async {
      await pumpWithRoute(tester, const {
        'confirmDiscard': true,
        'discardTitle': 'Ruko!',
        'discardMessage': 'Data chala jayega.',
        'fields': [
          {'type': 'text', 'id': 'name'},
        ],
      });
      await tester.enterText(find.byType(TextField), 'x');
      await tester.pump();
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Ruko!'), findsOneWidget);
      expect(find.text('Data chala jayega.'), findsOneWidget);
    });

    testWidgets('submit clears dirty so back pops freely', (tester) async {
      await pumpWithRoute(tester, _guardedJson);
      await tester.enterText(find.byType(TextField), 'done');
      controller.submit();
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Open'), findsOneWidget);
    });
  });
}
