import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:services_rj/forms.dart';

const _cities = [
  {'label': 'Ahmedabad', 'value': 'amd'},
  {'label': 'Pune', 'value': 'pnq'},
  {'label': 'Surat', 'value': 'stv'},
  {'label': 'Mumbai', 'value': 'bom'},
];

Future<DynamicFormController> _pump(
  WidgetTester tester,
  Map<String, dynamic> field, {
  DynamicFormController? controller,
  void Function(String, OptionItem)? onOptionAdded,
}) async {
  final c = controller ?? DynamicFormController();
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: DynamicForm(
          controller: c,
          json: {
            'fields': [field],
          },
          onOptionAdded: onOptionAdded,
        ),
      ),
    ),
  );
  await tester.pump();
  return c;
}

Future<void> _open(WidgetTester tester, String label) async {
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

void main() {
  test('type, aliases and multi-value detection', () {
    expect(
      FieldType.fromString('searchable-dropdown'),
      FieldType.searchableDropdown,
    );
    expect(
      FieldType.fromString('dropdownSearch'),
      FieldType.searchableDropdown,
    );
    expect(FieldType.fromString('searchable'), FieldType.searchableDropdown);
    expect(
      DynamicSearchableDropdownField.handles(
        FieldConfig.fromJson({'id': 'a', 'type': 'dropdown'}),
      ),
      isFalse,
    );
    expect(
      DynamicSearchableDropdownField.handles(
        FieldConfig.fromJson({'id': 'a', 'type': 'dropdown', 'multiple': true}),
      ),
      isTrue,
    );
  });

  testWidgets('local list: search filters and selects one value', (
    tester,
  ) async {
    final c = await _pump(tester, {
      'type': 'searchableDropdown',
      'id': 'city',
      'label': 'City',
      'options': _cities,
    });
    await _open(tester, 'City');
    expect(find.text('Surat'), findsOneWidget);

    await tester.enterText(find.byKey(const ValueKey('city-search')), 'pu');
    await tester.pumpAndSettle();
    expect(find.text('Surat'), findsNothing);

    await tester.tap(find.text('Pune'));
    await tester.pumpAndSettle();
    expect(c.getFormData()['city'], 'pnq');
    expect(find.text('Pune'), findsOneWidget); // shown in the closed field

    await tester.tap(find.byKey(const ValueKey('city-clear')));
    await tester.pump();
    expect(c.getFormData()['city'], isNull);
  });

  testWidgets('multiple: select all respects maxItems, chips can be removed', (
    tester,
  ) async {
    final c = await _pump(tester, {
      'type': 'searchableDropdown',
      'id': 'cities',
      'label': 'Cities',
      'multiple': true,
      'showSelectAll': true,
      'maxItems': 3,
      'options': _cities,
    });
    await _open(tester, 'Cities');
    await tester.tap(find.byKey(const ValueKey('cities-select-all')));
    await tester.pump();
    expect(find.text('3 selected'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('cities-done')));
    await tester.pumpAndSettle();
    expect(c.getFormData()['cities'], ['amd', 'pnq', 'stv']);

    await tester.tap(
      find.descendant(
        of: find.widgetWithText(InputChip, 'Pune'),
        matching: find.byIcon(Icons.close_rounded),
      ),
    );
    await tester.pump();
    expect(c.getFormData()['cities'], ['amd', 'stv']);
  });

  testWidgets('dismissing a multiple picker keeps the old selection', (
    tester,
  ) async {
    final c = await _pump(tester, {
      'type': 'dropdown',
      'id': 'tags',
      'label': 'Tags',
      'multiple': true,
      'initialValue': ['amd'],
      'options': _cities,
    });
    await _open(tester, 'Tags');
    await tester.tap(find.text('Mumbai'));
    await tester.pump();
    Navigator.of(tester.element(find.text('Mumbai').last)).pop();
    await tester.pumpAndSettle();
    expect(c.getFormData()['tags'], ['amd']);
  });

  testWidgets('API source: waits for minSearchLength, debounces, keeps label', (
    tester,
  ) async {
    final queries = <String>[];
    final c = DynamicFormController(
      searchSources: {
        'cities': (query, formData) async {
          queries.add(query);
          return [
            for (final city in _cities)
              if ((city['label']!).toLowerCase().contains(query.toLowerCase()))
                OptionItem(label: city['label']!, value: city['value']),
          ];
        },
      },
    );
    await _pump(tester, {
      'type': 'searchableDropdown',
      'id': 'city',
      'label': 'City',
      'searchSource': 'cities',
      'minSearchLength': 2,
      'debounceMs': 200,
    }, controller: c);
    await _open(tester, 'City');
    expect(find.text('Type at least 2 characters to search'), findsOneWidget);

    await tester.enterText(find.byKey(const ValueKey('city-search')), 'm');
    await tester.pump(const Duration(milliseconds: 300));
    expect(queries, isEmpty);

    await tester.enterText(find.byKey(const ValueKey('city-search')), 'mu');
    await tester.pump(const Duration(milliseconds: 100));
    await tester.enterText(find.byKey(const ValueKey('city-search')), 'mum');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(queries, ['mum']);

    await tester.tap(find.text('Mumbai'));
    await tester.pumpAndSettle();
    expect(c.getFormData()['city'], 'bom');
    expect(find.text('Mumbai'), findsOneWidget);
  });

  testWidgets('API source failure shows retry', (tester) async {
    var fail = true;
    FormSearchSources.register('flaky', (query, formData) async {
      if (fail) throw StateError('offline');
      return const [OptionItem(label: 'Back online', value: 1)];
    });
    addTearDown(() => FormSearchSources.unregister('flaky'));
    await _pump(tester, {
      'type': 'searchableDropdown',
      'id': 'f',
      'label': 'Flaky',
      'searchSource': 'flaky',
    });
    await _open(tester, 'Flaky');
    expect(find.text('Could not load results'), findsOneWidget);
    fail = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Back online'), findsOneWidget);
  });

  testWidgets('allowCustomOptions adds the typed text', (tester) async {
    OptionItem? added;
    final c = await _pump(tester, {
      'type': 'searchableDropdown',
      'id': 'city',
      'label': 'City',
      'allowCustomOptions': true,
      'options': _cities,
    }, onOptionAdded: (_, o) => added = o);
    await _open(tester, 'City');
    await tester.enterText(find.byKey(const ValueKey('city-search')), 'Indore');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('city-add')));
    await tester.pumpAndSettle();
    expect(c.getFormData()['city'], 'Indore');
    expect(added?.label, 'Indore');
  });

  testWidgets('required multiple field reports an error when empty', (
    tester,
  ) async {
    final c = await _pump(tester, {
      'type': 'searchableDropdown',
      'id': 'langs',
      'label': 'Languages',
      'multiple': true,
      'required': true,
      'options': ['Dart', 'Kotlin'],
    });
    expect(c.validate(), isFalse);
    await tester.pump();
    expect(find.text('This field is required'), findsOneWidget);
  });

  testWidgets('plain dropdown still uses the Material dropdown', (
    tester,
  ) async {
    await _pump(tester, {
      'type': 'dropdown',
      'id': 'd',
      'label': 'Plain',
      'options': ['a', 'b'],
    });
    expect(find.byType(DropdownButtonFormField<Object?>), findsOneWidget);
    expect(find.byType(DynamicSearchableDropdownField), findsNothing);
  });

  testWidgets('dialog and full-screen pickers open', (tester) async {
    for (final style in ['dialog', 'fullScreen']) {
      final c = await _pump(tester, {
        'type': 'searchableDropdown',
        'id': 'p',
        'label': 'Picker $style',
        'pickerStyle': style,
        'options': _cities,
      });
      await _open(tester, 'Picker $style');
      await tester.tap(find.text('Surat'));
      await tester.pumpAndSettle();
      expect(c.getFormData()['p'], 'stv', reason: style);
      await tester.pumpWidget(const SizedBox());
      c.dispose();
    }
  });
}
