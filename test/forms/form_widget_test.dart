import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:services_rj/services_rj.dart';

Widget _app(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  late DynamicFormController controller;

  setUp(() => controller = DynamicFormController());
  tearDown(() => controller.dispose());

  group('DynamicForm widget', () {
    testWidgets('renders fields from JSON and binds text input', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          DynamicForm(
            controller: controller,
            json: const {
              'fields': [
                {'type': 'text', 'id': 'name', 'label': 'Full Name'},
                {'type': 'email', 'id': 'email', 'label': 'Email'},
              ],
            },
          ),
        ),
      );
      expect(find.text('Full Name'), findsOneWidget);
      await tester.enterText(find.byType(TextField).first, 'Rupesh');
      expect(controller.getValue('name'), 'Rupesh');
    });

    testWidgets('external setValue updates the rendered text field', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          DynamicForm(
            controller: controller,
            json: const {
              'fields': [
                {'type': 'text', 'id': 'name', 'label': 'Name'},
              ],
            },
          ),
        ),
      );
      controller.setValue('name', 'External');
      await tester.pump();
      expect(find.text('External'), findsOneWidget);
    });

    testWidgets('conditional visibility toggles a field', (tester) async {
      await tester.pumpWidget(
        _app(
          DynamicForm(
            controller: controller,
            json: const {
              'fields': [
                {
                  'type': 'dropdown',
                  'id': 'country',
                  'label': 'Country',
                  'items': [
                    {'label': 'India', 'value': 'IN'},
                    {'label': 'USA', 'value': 'US'},
                  ],
                },
                {
                  'type': 'text',
                  'id': 'state',
                  'label': 'State',
                  'visibleWhen': {
                    'field': 'country',
                    'operator': 'equals',
                    'value': 'IN',
                  },
                },
              ],
            },
          ),
        ),
      );
      expect(find.text('State'), findsNothing);
      controller.setValue('country', 'IN');
      await tester.pumpAndSettle();
      expect(find.text('State'), findsOneWidget);
      controller.setValue('country', 'US');
      await tester.pumpAndSettle();
      expect(find.text('State'), findsNothing);
    });

    testWidgets('validation errors render and submit button works', (
      tester,
    ) async {
      Map<String, dynamic>? submitted;
      await tester.pumpWidget(
        _app(
          DynamicForm(
            controller: controller,
            showSubmitButton: true,
            onSubmit: (d) => submitted = d,
            json: const {
              'fields': [
                {
                  'type': 'text',
                  'id': 'name',
                  'label': 'Name',
                  'validators': ['required'],
                },
              ],
            },
          ),
        ),
      );
      await tester.tap(find.text('Submit'));
      await tester.pump();
      expect(find.text('This field is required'), findsOneWidget);
      expect(submitted, isNull);

      await tester.enterText(find.byType(TextField), 'ok');
      await tester.tap(find.text('Submit'));
      await tester.pump();
      expect(submitted, {'name': 'ok'});
    });

    testWidgets('checkbox, switch, slider and chips update the controller', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          DynamicForm(
            controller: controller,
            json: const {
              'fields': [
                {'type': 'checkbox', 'id': 'agree', 'label': 'Agree'},
                {'type': 'switch', 'id': 'push', 'label': 'Push'},
                {'type': 'slider', 'id': 'vol', 'min': 0, 'max': 10},
                {
                  'type': 'chips',
                  'id': 'tags',
                  'multiple': true,
                  'items': ['a', 'b'],
                },
              ],
            },
          ),
        ),
      );
      await tester.tap(find.byType(Checkbox));
      await tester.tap(find.byType(Switch));
      await tester.tap(find.text('a'));
      await tester.pump();
      await tester.tap(find.text('b'));
      await tester.pump();
      expect(controller.getBool('agree'), isTrue);
      expect(controller.getBool('push'), isTrue);
      expect(controller.getList('tags'), ['a', 'b']);
    });

    testWidgets('runtime addField and removeField update the UI', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          DynamicForm(
            controller: controller,
            json: const {
              'fields': [
                {'type': 'text', 'id': 'a', 'label': 'A'},
              ],
            },
          ),
        ),
      );
      controller.addField(
        FieldConfig.fromJson({'type': 'text', 'id': 'b', 'label': 'B'}),
      );
      await tester.pump();
      expect(find.text('B'), findsOneWidget);
      controller.removeField('b');
      await tester.pump();
      expect(find.text('B'), findsNothing);
    });

    testWidgets('multi-step form validates before advancing', (tester) async {
      await tester.pumpWidget(
        _app(
          DynamicForm(
            controller: controller,
            json: const {
              'steps': [
                {
                  'title': 'Account',
                  'fields': [
                    {
                      'type': 'text',
                      'id': 'user',
                      'label': 'User',
                      'validators': ['required'],
                    },
                  ],
                },
                {
                  'title': 'Profile',
                  'fields': [
                    {'type': 'text', 'id': 'bio', 'label': 'Bio'},
                  ],
                },
              ],
            },
          ),
        ),
      );
      expect(find.byType(Stepper), findsOneWidget);
      await tester.tap(find.text('Next').first);
      await tester.pump();
      expect(find.text('This field is required'), findsOneWidget);
      await tester.enterText(find.byType(TextField).first, 'rupesh');
      await tester.tap(find.text('Next').first);
      await tester.pumpAndSettle();
      expect(find.text('Submit'), findsWidgets);
    });

    testWidgets('custom registered field renders', (tester) async {
      FieldFactory.registerCustom(
        'hello',
        (context, field, controller) => Text('custom:${field.id}'),
      );
      await tester.pumpWidget(
        _app(
          DynamicForm(
            controller: controller,
            json: const {
              'fields': [
                {'type': 'custom', 'id': 'x', 'customType': 'hello'},
              ],
            },
          ),
        ),
      );
      expect(find.text('custom:x'), findsOneWidget);
    });

    testWidgets('theme decorationBuilder is applied', (tester) async {
      await tester.pumpWidget(
        _app(
          DynamicFormTheme(
            data: DynamicFormThemeData(
              decorationBuilder: (context, field, decoration) =>
                  decoration.copyWith(hintText: 'themed-hint'),
            ),
            child: DynamicForm(
              controller: controller,
              json: const {
                'fields': [
                  {'type': 'text', 'id': 'name'},
                ],
              },
            ),
          ),
        ),
      );
      expect(find.text('themed-hint'), findsOneWidget);
    });

    testWidgets('large form renders lazily', (tester) async {
      final fields = [
        for (var i = 0; i < 1000; i++)
          {'type': 'text', 'id': 'f$i', 'label': 'Field $i'},
      ];
      await tester.pumpWidget(
        _app(DynamicForm(controller: controller, json: {'fields': fields})),
      );
      // Only the on-screen subset is built.
      final built = tester.widgetList(find.byType(TextField)).length;
      expect(built, lessThan(50));
      expect(controller.fieldOrder.length, 1000);
    });
  });
}
