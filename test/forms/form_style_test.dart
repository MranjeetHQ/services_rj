import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:services_rj/services_rj.dart';

void main() {
  group('FieldStyleConfig', () {
    test('parses variant, colors and text style from JSON', () {
      final s = FieldStyleConfig.fromJson({
        'variant': 'rounded',
        'borderRadius': 24,
        'fillColor': '#F1F3FF',
        'borderColor': '#3F51B5',
        'textStyle': {'fontSize': 18, 'fontWeight': 'w600', 'color': '#333333'},
      });
      expect(s.variant, FieldStyleVariant.rounded);
      expect(s.borderRadius, 24);
      expect(s.fillColor, const Color(0xFFF1F3FF));
      expect(s.textStyle!.fontSize, 18);
      expect(s.textStyle!.fontWeight, FontWeight.w600);
    });

    test('merge: later layers win per property', () {
      final merged = FieldStyleConfig.merge([
        FieldStyleConfig.fromJson({'variant': 'outlined', 'borderRadius': 8}),
        FieldStyleConfig.fromJson({'variant': 'filled'}),
      ]);
      expect(merged.variant, FieldStyleVariant.filled);
      expect(merged.borderRadius, 8, reason: 'kept from base layer');
    });

    test('parseColor accepts #RRGGBB, #AARRGGBB and 0x forms', () {
      expect(FieldStyleConfig.parseColor('#FF0000'), const Color(0xFFFF0000));
      expect(FieldStyleConfig.parseColor('#80FF0000'), const Color(0x80FF0000));
      expect(
        FieldStyleConfig.parseColor('0xFF00FF00'),
        const Color(0xFF00FF00),
      );
      expect(FieldStyleConfig.parseColor('junk'), isNull);
    });
  });

  group('styled rendering', () {
    late DynamicFormController controller;
    setUp(() => controller = DynamicFormController());
    tearDown(() => controller.dispose());

    Widget app(Object json) => MaterialApp(
      home: Scaffold(
        body: DynamicForm(controller: controller, json: json),
      ),
    );

    testWidgets('form-level filled variant applies to fields', (tester) async {
      await tester.pumpWidget(
        app(const {
          'style': {'variant': 'filled', 'fillColor': '#EEEEEE'},
          'fields': [
            {'type': 'text', 'id': 'a', 'label': 'A'},
          ],
        }),
      );
      final tf = tester.widget<TextField>(find.byType(TextField));
      expect(tf.decoration!.filled, isTrue);
      expect(tf.decoration!.fillColor, const Color(0xFFEEEEEE));
      final border = tf.decoration!.enabledBorder! as OutlineInputBorder;
      expect(border.borderSide, BorderSide.none);
    });

    testWidgets('per-field style overrides form-level style', (tester) async {
      await tester.pumpWidget(
        app(const {
          'style': {'variant': 'underline'},
          'fields': [
            {'type': 'text', 'id': 'a', 'label': 'A'},
            {
              'type': 'text',
              'id': 'b',
              'label': 'B',
              'style': {'variant': 'rounded', 'borderRadius': 30},
            },
          ],
        }),
      );
      final fields = tester
          .widgetList<TextField>(find.byType(TextField))
          .toList();
      expect(fields[0].decoration!.enabledBorder, isA<UnderlineInputBorder>());
      final rounded =
          fields[1].decoration!.enabledBorder! as OutlineInputBorder;
      expect(rounded.borderRadius, BorderRadius.circular(30));
    });

    testWidgets('textStyle from JSON reaches the TextField', (tester) async {
      await tester.pumpWidget(
        app(const {
          'fields': [
            {
              'type': 'text',
              'id': 'a',
              'style': {
                'textStyle': {'fontSize': 22, 'fontWeight': 'bold'},
              },
            },
          ],
        }),
      );
      final tf = tester.widget<TextField>(find.byType(TextField));
      expect(tf.style!.fontSize, 22);
      expect(tf.style!.fontWeight, FontWeight.bold);
    });
  });
}
