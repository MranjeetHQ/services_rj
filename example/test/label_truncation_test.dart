import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:services_rj_example/demo_enums.dart';
import 'package:services_rj_example/demos/pluggable_adapters.dart';
import 'package:services_rj_example/main.dart';

void main() {
  setUpAll(() async {
    registerDemoEnums();
    registerDemoAdapters();
    final root =
        Platform.environment['FLUTTER_ROOT'] ??
        File(Platform.resolvedExecutable).parent.parent.parent.parent.path;
    final bytes = File(
      '$root/bin/cache/artifacts/material_fonts/Roboto-Regular.ttf',
    ).readAsBytesSync();
    final loader = FontLoader('Roboto')
      ..addFont(Future.value(ByteData.view(bytes.buffer)));
    await loader.load();
  });

  testWidgets('no form label or text is truncated at phone width', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(393, 6000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final found = <String>[];
    for (final (_, entries) in demoSections.take(3)) {
      for (final e in entries) {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(fontFamily: 'Roboto'),
            home: Builder(builder: e.builder),
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));
        void visit(RenderObject o) {
          if (o is RenderParagraph && o.didExceedMaxLines) {
            found.add('${e.title}: "${o.text.toPlainText()}"');
          }
          o.visitChildren(visit);
        }

        visit(tester.binding.rootElement!.renderObject!);
      }
    }
    expect(found.toSet(), isEmpty, reason: 'Truncated at 393dp wide');
  });
}
