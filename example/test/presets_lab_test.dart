import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:services_rj/services_rj.dart';
import 'package:services_rj_example/demo_enums.dart';
import 'package:services_rj_example/demos/forms_labs.dart';
import 'package:services_rj_example/forms/lab_presets.dart';

void main() {
  setUpAll(() {
    registerDemoEnums();
    registerLabPresets();
  });

  test('the lab uses every TextPreset', () {
    final used = {
      for (final f in textPresetsLabForm['fields'] as List)
        if ((f as Map)['preset'] != null)
          TextPreset.tryParse(f['preset'] as String),
    };
    expect(
      TextPreset.values.where((p) => !used.contains(p)),
      isEmpty,
      reason: 'Add the missing preset to textPresetsLabForm',
    );
  });

  testWidgets('presets lab filters, formats and validates', (tester) async {
    tester.view.physicalSize = const Size(900, 8000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final entry = formLabDemos.firstWhere((e) => e.title == 'Text presets');
    await tester.pumpWidget(MaterialApp(home: Builder(builder: entry.builder)));
    await tester.pumpAndSettle();
    final controller = tester
        .widget<DynamicForm>(find.byType(DynamicForm))
        .controller;

    // Fields are matched to inputs by their order in the form.
    final inputs = find.byType(TextField);
    final order = controller.fieldOrder
        .where((id) => controller.state(id).config.preset != null)
        .toList();
    Future<void> enter(String id, String text) async {
      await tester.enterText(inputs.at(order.indexOf(id)), text);
      await tester.pump();
    }

    await enter('pan', 'abcpe-1234f');
    expect(controller.getValue('pan'), 'ABCPE1234F');
    await enter('mobile', '98x76y54321099');
    expect(controller.getValue('mobile'), '9876543210');
    await enter('fullName', 'Meera 7 Iyer');
    expect(controller.getValue('fullName'), 'Meera  Iyer');
    await enter('aadhaar', '2345 6789 0124');
    await enter('gstin', '27aapfu0939f1zv');
    await enter('ticket', 'tkt-1234');
    await enter('employee', 'e-12345');
    await enter('lot', '123456');
    await enter('panLower', 'ABCPE1234F');
    expect(controller.getValue('ticket'), 'TKT-1234');
    expect(controller.getValue('panLower'), 'abcpe1234f');

    controller.validate();
    expect(controller.getErrors(), isEmpty, reason: 'all samples are valid');

    await enter('gstin', '27AAPFU0939F1ZX');
    controller.validate();
    expect(controller.getErrors()['gstin'], 'That GSTIN does not look right');
    await enter('ticket', 'TKT-12');
    controller.validate();
    expect(controller.getErrors()['ticket'], 'Use the format TKT-1234');
    await enter('lot', '123457');
    controller.validate();
    expect(controller.getErrors()['lot'], contains('divisible by 3'));
  });
}
