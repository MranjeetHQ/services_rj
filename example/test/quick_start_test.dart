import 'package:services_rj_example/quick_start.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('the documented quick start runs and submits', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ProfilePage()));
    await tester.pump();

    await tester.enterText(find.byType(TextField).first, 'Asha Patel');
    await tester.tap(find.text('City'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pune'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pro'));
    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Saved:'), findsOneWidget);
    expect(find.textContaining('city: Pune'), findsOneWidget);
    expect(find.textContaining('plan: pro'), findsOneWidget);
  });
}
