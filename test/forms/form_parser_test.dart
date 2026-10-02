import 'package:flutter_test/flutter_test.dart';
import 'package:services_rj/services_rj.dart';

void main() {
  group('FormParser', () {
    test('parses a JSON string with fields', () {
      final config = FormParser.parse('''
      {
        "id": "registration",
        "title": "Registration",
        "fields": [
          {"type": "text", "id": "name", "label": "Full Name",
           "validators": ["required", {"type": "minLength", "value": 3}]},
          {"type": "email", "id": "email", "label": "Email"},
          {"type": "dropdown", "id": "country",
           "items": [{"label": "India", "value": "IN"},
                     {"label": "USA", "value": "US"}]}
        ]
      }''');
      expect(config.id, 'registration');
      expect(config.fields, hasLength(3));
      expect(config.fields[0].validators, hasLength(2));
      expect(config.fields[0].validators[1].type, 'minLength');
      expect(config.fields[2].type, FieldType.dropdown);
      expect(config.fields[2].options[0].value, 'IN');
    });

    test('parses steps, conditions and extras', () {
      final config = FormParser.parse({
        'steps': [
          {
            'title': 'Step 1',
            'fields': [
              {'type': 'text', 'id': 'a'},
              {
                'type': 'slider',
                'id': 's',
                'min': 5,
                'max': 50,
                'visibleWhen': {'field': 'a', 'operator': 'isNotEmpty'},
              },
            ],
          },
        ],
      });
      expect(config.steps, hasLength(1));
      final slider = config.steps[0].fields[1];
      expect(slider.ex<double>('min'), 5);
      expect(slider.visibleWhen, isNotNull);
    });

    test('resolves type aliases and unknown types', () {
      expect(FieldType.fromString('multi_select'), FieldType.multiselect);
      expect(FieldType.fromString('switch'), FieldType.switchField);
      expect(FieldType.fromString('range-slider'), FieldType.rangeSlider);
      expect(FieldType.fromString('made_up_thing'), FieldType.custom);
    });

    test('throws on non-object JSON', () {
      expect(() => FormParser.parse('[1,2]'), throwsFormatException);
    });
  });
}
