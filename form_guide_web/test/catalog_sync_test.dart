// Keeps the guide in sync with the package. When one of these fails, the
// package gained something the website does not document yet: add it to
// lib/catalog/field_catalog.dart or lib/catalog/reference_catalog.dart.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:form_guide_web/catalog/field_catalog.dart';
import 'package:form_guide_web/catalog/reference_catalog.dart';
import 'package:form_guide_web/guide_enums.dart';
import 'package:form_guide_web/main.dart';
import 'package:form_guide_web/pages/basics_pages.dart';
import 'package:form_guide_web/widgets/guide_search.dart';
import 'package:form_guide_web/pages/elements_page.dart';
import 'package:services_rj/services_rj.dart';

void main() {
  setUpAll(registerGuideEnums);

  test('every FieldType is documented exactly once', () {
    final documented = fieldCatalog.map((d) => d.type).toList();
    final missing = FieldType.values.where((t) => !documented.contains(t));
    expect(missing, isEmpty, reason: 'Undocumented field types: $missing');
    expect(
      documented.toSet().length,
      documented.length,
      reason: 'A field type is documented twice',
    );
  });

  test('every example parses to its own type', () {
    for (final d in fieldCatalog) {
      final parsed = FieldConfig.fromJson(d.example);
      expect(parsed.type, d.type, reason: '${d.type.name} example');
      for (final alias in d.aliases) {
        expect(
          FieldType.fromString(alias),
          d.type,
          reason: 'alias "$alias" of ${d.type.name}',
        );
      }
    }
  });

  test('every FieldConfig JSON key is documented', () {
    final documented = fieldPropertyDocs.map((d) => d.key).toSet();
    final missing = FieldConfig.knownKeys.difference(documented);
    final stale = documented.difference(FieldConfig.knownKeys);
    expect(missing, isEmpty, reason: 'Undocumented properties: $missing');
    expect(stale, isEmpty, reason: 'Documented but no longer parsed: $stale');
  });

  test('every style key is documented', () {
    final documented = styleDocs.map((d) => d.key).toSet();
    expect(FieldStyleConfig.knownKeys.difference(documented), isEmpty);
    expect(documented.difference(FieldStyleConfig.knownKeys), isEmpty);
  });

  test('every validator and operator is documented', () {
    expect(
      ValidatorType.values.where((v) => !validatorDocs.containsKey(v)),
      isEmpty,
    );
    expect(
      ConditionOperator.values.where((o) => !operatorDocs.containsKey(o)),
      isEmpty,
    );
    for (final v in ValidatorType.values) {
      if (v == ValidatorType.custom || v == ValidatorType.required) continue;
      expect(
        ValidatorRegistry.isRegistered(v.name),
        isTrue,
        reason: '${v.name} is documented but not registered',
      );
    }
  });

  testWidgets('every guide page renders without errors', (tester) async {
    tester.view.physicalSize = const Size(1400, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const FormGuideApp());
    for (final s in guideSections) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: Builder(builder: s.builder)),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: s.title);
    }
  });

  testWidgets('every field example renders', (tester) async {
    tester.view.physicalSize = const Size(1000, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    for (final d in fieldCatalog) {
      final c = DynamicFormController();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DynamicForm(
              controller: c,
              json: {
                'fields': [d.example],
              },
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull, reason: d.type.name);
      await tester.pumpWidget(const SizedBox());
      c.dispose();
    }
  });

  testWidgets('element builder opens every element and deep links', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        onGenerateRoute: (settings) => MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const Scaffold(body: ElementsPage()),
        ),
        initialRoute: '/elements/dropdown',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('"dropdown"'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('Getting started code matches the runnable example', () {
    final file = File('../example/lib/quick_start.dart').readAsStringSync();
    expect(file, contains(quickStartCode.trim()));
  });

  testWidgets('guide search finds elements and keys', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: SingleChildScrollView(child: GuideSearch())),
      ),
    );
    await tester.enterText(
      find.byKey(const ValueKey('guide-search')),
      'searchable',
    );
    await tester.pump();
    expect(find.text('searchableDropdown'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('guide-search')),
      'optionStyle',
    );
    await tester.pump();
    expect(find.textContaining('Property ·'), findsWidgets);
    expect(
      guideSearchIndex.where((e) => e.kind == 'Element').length,
      FieldType.values.length,
    );
  });
}
