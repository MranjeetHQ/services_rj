import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:services_rj/services_rj.dart';
import 'package:services_rj_example/app_setup_start.dart' as setup;
import 'package:services_rj_example/readme_forms.dart' as readme;

/// The code of [path] after its leading comment block.
String _code(String path) => File(
  path,
).readAsLinesSync().skipWhile((l) => l.startsWith('//')).join('\n').trim();

void main() {
  test('docs show the runnable example files unchanged', () {
    final readmeText = File('../README.md').readAsStringSync();
    expect(readmeText, contains(_code('lib/readme_forms.dart')));
    final notes = File('../RELEASE_NOTES.md').readAsStringSync();
    expect(notes, contains(_code('lib/quick_start.dart')));
    final forms = File('../docs/forms.md').readAsStringSync();
    expect(forms, contains(_code('lib/quick_start.dart')));
    final setup = _code('lib/app_setup_start.dart');
    expect(File('../FEATURES.md').readAsStringSync(), contains(setup));
    expect(readmeText, contains(setup));
  });

  testWidgets('app setup example starts with the theme controls', (
    tester,
  ) async {
    await tester.pumpWidget(const ServicesApp(home: setup.HomePage()));
    expect(find.byType(ThemeModeSelector), findsOneWidget);
    expect(find.byType(ThemeColorPicker), findsOneWidget);
    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    expect(AppThemeController.instance.isDarkMode, isTrue);
    await AppThemeController.instance.resetToDefaults();
  });

  testWidgets('README forms example runs and submits', (tester) async {
    tester.view.physicalSize = const Size(900, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    readme.main();
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Ravi');
    await tester.tap(find.text('Venue'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'roof');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rooftop Garden'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Middle'));
    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();
    expect(find.textContaining('venue: Rooftop Garden'), findsOneWidget);
    expect(find.textContaining('seating: Middle'), findsOneWidget);
  });
}
