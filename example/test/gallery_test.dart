import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:services_rj/services_rj.dart';
import 'package:services_rj_example/demo_enums.dart';
import 'package:services_rj_example/demos/forms_gallery.dart';
import 'package:services_rj_example/demos/pluggable_adapters.dart';
import 'package:services_rj_example/forms/field_gallery_forms.dart';

void _collect(List<dynamic> fields, Set<FieldType> out) {
  for (final f in fields) {
    final map = f as Map<String, dynamic>;
    out.add(FieldType.fromString(map['type'] as String));
    _collect((map['fields'] as List?) ?? const [], out);
  }
}

Finder _field(String label) => find.byWidgetPredicate(
  (w) => w is TextField && w.decoration?.labelText == label,
);

void main() {
  setUp(() {
    registerDemoEnums();
    registerDemoAdapters();
  });

  test('gallery covers every FieldType', () {
    final used = <FieldType>{};
    for (final form in allGalleryForms) {
      _collect(form['fields'] as List, used);
    }
    expect(FieldType.values.toSet().difference(used), isEmpty);
  });

  test('every gallery form parses and attaches', () {
    for (final json in allGalleryForms) {
      final c = DynamicFormController()..attach(FormParser.parse(json));
      expect(c.fieldOrder, isNotEmpty);
      c.dispose();
    }
  });

  test('registerDemoAdapters is idempotent', () {
    registerDemoAdapters();
    registerDemoAdapters();
    expect(galleryDemos, hasLength(6));
  });

  Future<void> open(WidgetTester tester, int index) async {
    tester.view.physicalSize = const Size(900, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(home: Builder(builder: galleryDemos[index].builder)),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('text inputs page collects typed values', (tester) async {
    await open(tester, 0);
    expect(find.text('Name your boat'), findsOneWidget);
    await tester.enterText(_field('Name your boat'), 'Sea Biscuit');
    await tester.enterText(_field('Crew email'), 'crew@example.com');
    await tester.pump();
    final form = tester.widget<DynamicForm>(find.byType(DynamicForm));
    final data = form.controller.getFormData();
    expect(data['boatName'], 'Sea Biscuit');
    expect(data['crewEmail'], 'crew@example.com');
  });

  testWidgets('selection page builds and toggles a switch', (tester) async {
    await open(tester, 2);
    expect(find.text('Vessel class'), findsOneWidget);
    await tester.tap(find.widgetWithText(SwitchListTile, 'Weather alerts'));
    await tester.pump();
    final form = tester.widget<DynamicForm>(find.byType(DynamicForm));
    expect(form.controller.getFormData()['weatherAlerts'], isTrue);
  });

  testWidgets('adapters page: scan, mood and markdown flow into data', (
    tester,
  ) async {
    await open(tester, 5);
    await tester.tap(find.byKey(const ValueKey('dockPass_scan')));
    await tester.tap(find.byKey(const ValueKey('tripMood_4')));
    await tester.enterText(
      find.byKey(const ValueKey('handoverNotes_input')),
      'Check **bilge** pump',
    );
    await tester.pump();
    final form = tester.widget<DynamicForm>(find.byType(DynamicForm));
    final data = form.controller.getFormData();
    expect(data['dockPass'], startsWith('QR-'));
    expect(data['tripMood'], 4);
    expect(data['handoverNotes'], 'Check **bilge** pump');
  });

  testWidgets('signature pad survives multi-segment drags, reset and clear', (
    tester,
  ) async {
    await open(tester, 5);
    final controller = tester
        .widget<DynamicForm>(find.byType(DynamicForm))
        .controller;
    final pad = find.byKey(const ValueKey('signature_pad'));

    // Several updates inside one stroke, then a second stroke.
    for (var stroke = 0; stroke < 2; stroke++) {
      final gesture = await tester.startGesture(
        tester.getCenter(pad) + Offset(0, stroke * 20.0),
      );
      for (var i = 0; i < 6; i++) {
        await gesture.moveBy(const Offset(12, 5));
        await tester.pump();
      }
      await gesture.up();
      await tester.pump();
    }
    expect(tester.takeException(), isNull);
    expect(controller.getValue('captainSignature'), hasLength(2));

    controller.reset();
    await tester.pump();
    expect(controller.getValue('captainSignature'), isNull);

    // Drawing works again after a reset.
    final gesture = await tester.startGesture(tester.getCenter(pad));
    await gesture.moveBy(const Offset(60, 30));
    await tester.pump();
    await gesture.up();
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(controller.getValue('captainSignature'), hasLength(1));

    await tester.tap(find.text('Clear'));
    await tester.pump();
    expect(controller.getValue('captainSignature'), isNull);
  });

  testWidgets('drawing on the signature pad never scrolls the page', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(home: Builder(builder: galleryDemos[5].builder)),
    );
    await tester.pumpAndSettle();
    final scrollable = tester.state<ScrollableState>(
      find.byType(Scrollable).first,
    );
    final before = scrollable.position.pixels;
    final pad = find.byKey(const ValueKey('signature_pad'));
    final controller = tester
        .widget<DynamicForm>(find.byType(DynamicForm))
        .controller;

    // Control: the same upward drag outside the pad does scroll the page.
    await tester.dragFrom(const Offset(450, 800), const Offset(0, -150));
    await tester.pump();
    expect(scrollable.position.pixels, greaterThan(before));
    scrollable.position.jumpTo(before);
    await tester.pump();

    // A long mostly-vertical drag that starts on the pad draws instead.
    final gesture = await tester.startGesture(tester.getCenter(pad));
    for (var i = 0; i < 8; i++) {
      await gesture.moveBy(const Offset(4, -14));
      await tester.pump();
    }
    await gesture.up();
    await tester.pump();

    expect(scrollable.position.pixels, before, reason: 'page must not scroll');
    expect(controller.getValue('captainSignature'), hasLength(1));
  });

  testWidgets('a tap leaves a dot and a tiny stroke registers', (tester) async {
    await open(tester, 5);
    final controller = tester
        .widget<DynamicForm>(find.byType(DynamicForm))
        .controller;
    final pad = find.byKey(const ValueKey('signature_pad'));
    await tester.tapAt(tester.getCenter(pad));
    await tester.pump();
    expect(controller.getValue('captainSignature'), hasLength(1));
  });

  for (final brightness in Brightness.values) {
    testWidgets('signature ink contrasts with the pad in ${brightness.name} '
        'mode', (tester) async {
      tester.view.physicalSize = const Size(900, 3000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(brightness: brightness, useMaterial3: true),
          home: Builder(builder: galleryDemos[5].builder),
        ),
      );
      await tester.pumpAndSettle();
      final pad = find.byKey(const ValueKey('signature_pad'));
      final paper =
          (tester.widget<Container>(pad).decoration! as BoxDecoration).color!;
      final painter = tester
          .widgetList<CustomPaint>(
            find.descendant(of: pad, matching: find.byType(CustomPaint)),
          )
          .map((p) => p.painter)
          .whereType<SignatureInkPainter>()
          .single;
      final gap = (painter.ink.computeLuminance() - paper.computeLuminance())
          .abs();
      expect(gap, greaterThan(0.6), reason: 'ink must stand out from paper');
    });
  }

  testWidgets('media and layout pages build', (tester) async {
    await open(tester, 3);
    expect(find.text('Hull photos'), findsOneWidget);
    await open(tester, 4);
    expect(find.text('Waypoint 1'), findsOneWidget);
  });
}
