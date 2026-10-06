import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:services_rj/services_rj.dart';

enum Shift { morning, lateEvening, nightOwl }

enum Meal { veg, nonVeg, vegan }

Future<void> pumpForm(
  WidgetTester tester,
  DynamicFormController c,
  Map<String, dynamic> json, {
  Map<String, FieldOverrides> overrides = const {},
  Map<FieldType, FieldOverrides> typeOverrides = const {},
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: DynamicForm(
          controller: c,
          json: json,
          fieldOverrides: overrides,
          typeOverrides: typeOverrides,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    FormEnumRegistry.register('Shift', Shift.values);
    FormEnumRegistry.register(
      'Meal',
      Meal.values,
      label: (m) => switch (m) {
        Meal.veg => 'Vegetarian',
        Meal.nonVeg => 'Non-vegetarian',
        Meal.vegan => 'Vegan',
      },
    );
  });

  group('enums', () {
    test('string parsers accept every spelling', () {
      expect(KeyboardKind.fromString('EMAIL'), KeyboardKind.email);
      expect(InputActionKind.fromString('next'), InputActionKind.next);
      expect(OptionLayout.fromString('grid'), OptionLayout.grid);
      expect(TextCase.fromString('uppercase'), TextCase.upper);
      expect(ValidatorType.fromString('pattern'), ValidatorType.regex);
      expect(
        ConditionOperator.fromString('>='),
        ConditionOperator.greaterThanOrEqual,
      );
      expect(ConditionOperator.fromString('in'), ConditionOperator.isIn);
      expect(enumFromString(Shift.values, 'late_evening'), Shift.lateEvening);
    });

    test('enum registry builds humanized options', () {
      final options = FormEnumRegistry.options('Shift')!;
      expect(options.map((o) => o.label), [
        'Morning',
        'Late evening',
        'Night owl',
      ]);
      expect(options.map((o) => o.value), [
        'morning',
        'lateEvening',
        'nightOwl',
      ]);
      expect(FormEnumRegistry.options('Meal')!.first.label, 'Vegetarian');
    });

    test('"enum" fields get options and decode values', () {
      final c = DynamicFormController()
        ..attach(
          FormConfig.fromJson({
            'fields': [
              {'type': 'radioGroup', 'id': 'shift', 'enum': 'Shift'},
              {
                'type': 'chips',
                'id': 'meals',
                'enum': 'Meal',
                'multiple': true,
              },
            ],
          }),
        );
      expect(c.state('shift').options.value, hasLength(3));

      c.setValue('shift', Shift.nightOwl);
      expect(c.getValue('shift'), 'nightOwl');
      expect(c.getEnum('shift', Shift.values), Shift.nightOwl);

      c.setValue('meals', [Meal.veg, Meal.vegan]);
      expect(c.getValue('meals'), ['veg', 'vegan']);
      expect(c.getEnumList('meals', Meal.values), [Meal.veg, Meal.vegan]);
    });

    test('typed constructors match JSON', () {
      final v = ValidatorConfig.of(ValidatorType.minLength, value: 3);
      expect(v.type, 'minLength');
      expect(v.kind, ValidatorType.minLength);
      final cond = Condition.when('age', ConditionOperator.greaterThan, 17);
      expect(cond.toJson(), {
        'field': 'age',
        'operator': 'greaterThan',
        'value': 17,
      });
    });
  });

  group('conditions', () {
    bool eval(Map<String, dynamic> json, Map<String, dynamic> data) =>
        ConditionEvaluator.evaluate(Condition.fromJson(json), data);

    test('new operators', () {
      expect(
        eval(
          {
            'field': 'a',
            'operator': 'notIn',
            'value': [1, 2],
          },
          {'a': 3},
        ),
        isTrue,
      );
      expect(eval({'field': 'a', 'operator': 'isTrue'}, {'a': true}), isTrue);
      expect(eval({'field': 'a', 'operator': 'isFalse'}, {'a': null}), isTrue);
      expect(
        eval(
          {'field': 'a', 'operator': 'notContains', 'value': 'x'},
          {
            'a': ['y'],
          },
        ),
        isTrue,
      );
    });

    test('custom operator', () {
      ConditionEvaluator.registerOperator(
        'divisibleBy',
        (a, b) => a is num && b is num && a % b == 0,
      );
      expect(
        eval({'field': 'n', 'operator': 'divisibleBy', 'value': 5}, {'n': 25}),
        isTrue,
      );
    });

    test('referencedFields walks the tree', () {
      final c = Condition.fromJson({
        'and': [
          {'field': 'a', 'operator': 'isNotEmpty'},
          {
            'not': {'field': 'b', 'operator': 'isTrue'},
          },
        ],
      });
      expect(c.referencedFields, {'a', 'b'});
    });
  });

  group('repeater (extendable forms)', () {
    Map<String, dynamic> json({int? min, int? max}) => {
      'fields': [
        {
          'type': 'repeater',
          'id': 'guests',
          'label': 'Guests',
          'itemLabel': 'Guest {index}',
          'addLabel': 'Add guest',
          'minItems': ?min,
          'maxItems': ?max,
          'fields': [
            {'type': 'text', 'id': 'name', 'label': 'Name', 'required': true},
            {'type': 'dropdown', 'id': 'meal', 'label': 'Meal', 'enum': 'Meal'},
          ],
        },
      ],
    };

    test('starts with one blank entry and syncs data', () {
      final c = DynamicFormController()..attach(FormConfig.fromJson(json()));
      expect(c.entriesOf('guests'), hasLength(1));
      expect(c.isDirty, isFalse);

      c.entriesOf('guests').first.controller.setValue('name', 'Asha');
      expect(c.getEntries('guests'), [
        {'name': 'Asha', 'meal': null},
      ]);
      expect(c.isDirty, isTrue);
    });

    test('add / remove respect min and max', () {
      final c = DynamicFormController()
        ..attach(FormConfig.fromJson(json(min: 1, max: 2)));
      expect(c.canRemoveEntry('guests'), isFalse);
      expect(c.addEntry('guests'), isNotNull);
      expect(c.addEntry('guests'), isNull);
      expect(c.entriesOf('guests'), hasLength(2));
      expect(c.removeEntry('guests', 0), isTrue);
      expect(c.removeEntry('guests', 0), isFalse);
    });

    test('validation covers every entry', () {
      final c = DynamicFormController()..attach(FormConfig.fromJson(json()));
      expect(c.validate(), isFalse);
      expect(c.getErrors()['guests'], 'Fix the highlighted entries');
      final entry = c.entriesOf('guests').first.controller;
      expect(entry.getErrors()['name'], 'This field is required');

      entry.setValue('name', 'Ravi');
      expect(c.validate(), isTrue);
    });

    test('prefill, reset and setValue rebuild entries', () {
      final c = DynamicFormController()
        ..attach(
          FormConfig.fromJson(json()),
          initialData: {
            'guests': [
              {'name': 'A', 'meal': 'veg'},
              {'name': 'B', 'meal': 'vegan'},
            ],
          },
        );
      expect(c.entriesOf('guests'), hasLength(2));
      expect(c.isDirty, isFalse);

      c.removeEntry('guests', 1);
      expect(c.isDirty, isTrue);
      c.reset();
      expect(c.getEntries('guests').map((e) => e['name']), ['A', 'B']);

      c.setValue('guests', [
        {'name': 'C'},
      ]);
      expect(c.getEntries('guests'), [
        {'name': 'C', 'meal': null},
      ]);
    });

    test('moveEntry reorders', () {
      final c = DynamicFormController()
        ..attach(
          FormConfig.fromJson(json()),
          initialData: {
            'guests': [
              {'name': 'A'},
              {'name': 'B'},
            ],
          },
        );
      c.moveEntry('guests', 0, 1);
      expect(c.getEntries('guests').map((e) => e['name']), ['B', 'A']);
    });

    testWidgets('renders entries and adds one from the button', (tester) async {
      final c = DynamicFormController();
      await pumpForm(tester, c, json(max: 3));
      expect(find.text('Guest 1'), findsOneWidget);
      await tester.tap(find.text('Add guest'));
      await tester.pumpAndSettle();
      expect(find.text('Guest 2'), findsOneWidget);
      await tester.enterText(find.byType(TextField).last, 'Mo');
      expect(c.getEntries('guests').last['name'], 'Mo');
      c.dispose();
    });
  });

  group('extendable options', () {
    test('addOption / removeOption / customOptions', () {
      final added = <String>[];
      final c = DynamicFormController()
        ..onOptionAdded = (id, o) {
          added.add('$id:${o.label}');
        }
        ..attach(
          FormConfig.fromJson({
            'fields': [
              {
                'type': 'checkboxGroup',
                'id': 'tags',
                'options': ['A', 'B'],
              },
            ],
          }),
        );
      c.addOption(
        'tags',
        const OptionItem(label: 'C', value: 'C', isCustom: true),
        select: true,
      );
      expect(c.state('tags').options.value, hasLength(3));
      expect(c.getValue('tags'), ['C']);
      expect(c.customOptions('tags').single.value, 'C');
      expect(added, ['tags:C']);

      c.addOption('tags', const OptionItem(label: 'C', value: 'C'));
      expect(c.state('tags').options.value, hasLength(3));

      c.removeOption('tags', 'C');
      expect(c.getValue('tags'), isEmpty);
    });

    test('min/max items on multi-select', () {
      final c = DynamicFormController()
        ..attach(
          FormConfig.fromJson({
            'fields': [
              {
                'type': 'chips',
                'id': 'skills',
                'multiple': true,
                'minItems': 2,
                'maxItems': 3,
                'options': ['a', 'b', 'c', 'd'],
              },
            ],
          }),
        );
      // Optional and empty: valid. Limits apply once something is picked.
      expect(c.validateField('skills'), isNull);
      c.setValue('skills', ['a']);
      expect(c.validateField('skills'), 'Add at least 2');
      c.setValue('skills', ['a', 'b', 'c', 'd']);
      expect(c.validateField('skills'), 'No more than 3 allowed');
      c.setValue('skills', ['a', 'b']);
      expect(c.validateField('skills'), isNull);
    });

    testWidgets('user adds an option through the chip', (tester) async {
      final c = DynamicFormController();
      await pumpForm(tester, c, {
        'fields': [
          {
            'type': 'chips',
            'id': 'topics',
            'label': 'Topics',
            'options': ['Design'],
            'allowCustomOptions': true,
            'customOptionLabel': 'Suggest a topic',
          },
        ],
      });
      await tester.tap(find.text('Suggest a topic'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, 'Testing');
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();
      expect(find.text('Testing'), findsOneWidget);
      expect(c.getValue('topics'), 'Testing');
      c.dispose();
    });
  });

  group('per-field customization', () {
    testWidgets('JSON style keys and typed props reach the widgets', (
      tester,
    ) async {
      final c = DynamicFormController();
      await pumpForm(tester, c, {
        'fields': [
          {
            'type': 'text',
            'id': 'code',
            'label': 'Code',
            'prefixText': 'ID-',
            'suffixText': '#',
            'textCase': 'upper',
            'maxLength': 6,
            'showCounter': true,
            'style': {'textAlign': 'center', 'cursorColor': '#FF0000'},
          },
        ],
      });
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.textAlign, TextAlign.center);
      expect(field.cursorColor, const Color(0xFFFF0000));
      expect(field.decoration!.prefixText, 'ID-');
      expect(field.decoration!.suffixText, '#');
      expect(field.maxLength, 6);
      await tester.enterText(find.byType(TextField), 'ab12');
      expect(c.getValue('code'), 'AB12');
      c.dispose();
    });

    testWidgets('grid layout and option descriptions', (tester) async {
      final c = DynamicFormController();
      await pumpForm(tester, c, {
        'fields': [
          {
            'type': 'radioGroup',
            'id': 'plan',
            'label': 'Plan',
            'optionLayout': 'grid',
            'columns': 2,
            'options': [
              {'label': 'Starter', 'value': 's', 'description': 'For one'},
              {'label': 'Team', 'value': 't', 'description': 'Up to 10'},
            ],
          },
        ],
      });
      expect(find.text('For one'), findsOneWidget);
      await tester.tap(find.text('Team'));
      expect(c.getValue('plan'), 't');
      c.dispose();
    });

    testWidgets('FieldOverrides: builder, wrapper, label, decoration', (
      tester,
    ) async {
      final c = DynamicFormController();
      await pumpForm(
        tester,
        c,
        {
          'fields': [
            {'type': 'text', 'id': 'a', 'label': 'Original'},
            {'type': 'text', 'id': 'b', 'label': 'B'},
            {'type': 'email', 'id': 'mail', 'label': 'Mail'},
          ],
        },
        overrides: {
          'a': FieldOverrides(
            label: 'Renamed',
            wrapper: (context, field, child) =>
                Card(key: const Key('wrapped'), child: child),
          ),
          'b': FieldOverrides(
            builder: (context, field, controller) =>
                const Text('custom widget'),
          ),
        },
        typeOverrides: {
          FieldType.email: FieldOverrides(
            decoration: (context, field, d) => d.copyWith(suffixText: '@co'),
          ),
        },
      );
      expect(find.text('Renamed'), findsOneWidget);
      expect(find.byKey(const Key('wrapped')), findsOneWidget);
      expect(find.text('custom widget'), findsOneWidget);
      expect(find.text('@co'), findsOneWidget);
      c.dispose();
    });
  });

  group('serialization', () {
    test('FormConfig round-trips through toJson', () {
      final source = {
        'id': 'trip',
        'title': 'Trip',
        'style': {'variant': 'rounded', 'fillColor': '#F1F3FF'},
        'fields': [
          {
            'type': 'text',
            'id': 'city',
            'label': 'City',
            'keyboardType': 'text',
            'textCase': 'words',
            'validators': [
              'required',
              {'type': 'minLength', 'value': 2},
            ],
            'visibleWhen': {'field': 'going', 'operator': 'isTrue'},
          },
          {
            'type': 'repeater',
            'id': 'stops',
            'minItems': 1,
            'fields': [
              {'type': 'text', 'id': 'stop'},
            ],
          },
          {'type': 'slider', 'id': 'budget', 'min': 0, 'max': 10},
        ],
      };
      final first = FormConfig.fromJson(source);
      final again = FormConfig.fromJson(first.toJson());
      expect(again.toJson(), first.toJson());
      expect(again.fields.first.textCase, TextCase.words);
      expect(again.fields[1].type, FieldType.repeater);
      expect(again.fields[2].ex<double>('max'), 10);
      expect(again.style!.fillColor, const Color(0xFFF1F3FF));
    });
  });
}
