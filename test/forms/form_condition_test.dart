import 'package:flutter_test/flutter_test.dart';
import 'package:services_rj/services_rj.dart';

void main() {
  bool eval(Map<String, dynamic> json, Map<String, dynamic> data) =>
      ConditionEvaluator.evaluate(Condition.fromJson(json), data);

  group('ConditionEvaluator', () {
    test('equals / notEquals', () {
      expect(
        eval(
          {'field': 'country', 'operator': 'equals', 'value': 'IN'},
          {'country': 'IN'},
        ),
        isTrue,
      );
      expect(
        eval(
          {'field': 'country', 'operator': 'notEquals', 'value': 'IN'},
          {'country': 'US'},
        ),
        isTrue,
      );
    });

    test('numeric comparisons with string coercion', () {
      expect(
        eval(
          {'field': 'age', 'operator': 'greaterThanOrEqual', 'value': 18},
          {'age': '18'},
        ),
        isTrue,
      );
      expect(
        eval(
          {'field': 'age', 'operator': 'lessThan', 'value': 18},
          {'age': 17},
        ),
        isTrue,
      );
      expect(
        eval(
          {'field': 'age', 'operator': 'greaterThan', 'value': 18},
          {'age': null},
        ),
        isFalse,
      );
    });

    test('string operators', () {
      final data = {
        'name': 'Rupesh',
        'tags': ['a', 'b'],
      };
      expect(
        eval({'field': 'name', 'operator': 'startsWith', 'value': 'Ru'}, data),
        isTrue,
      );
      expect(
        eval({'field': 'name', 'operator': 'endsWith', 'value': 'sh'}, data),
        isTrue,
      );
      expect(
        eval({'field': 'name', 'operator': 'contains', 'value': 'pes'}, data),
        isTrue,
      );
      expect(
        eval({'field': 'tags', 'operator': 'contains', 'value': 'b'}, data),
        isTrue,
      );
    });

    test('AND / OR / NOT composition', () {
      final data = {'country': 'IN', 'age': 20};
      expect(
        eval({
          'and': [
            {'field': 'country', 'operator': 'equals', 'value': 'IN'},
            {'field': 'age', 'operator': 'greaterThanOrEqual', 'value': 18},
          ],
        }, data),
        isTrue,
      );
      expect(
        eval({
          'or': [
            {'field': 'country', 'operator': 'equals', 'value': 'US'},
            {'field': 'age', 'operator': 'greaterThan', 'value': 100},
          ],
        }, data),
        isFalse,
      );
      expect(
        eval({
          'not': {'field': 'country', 'operator': 'equals', 'value': 'US'},
        }, data),
        isTrue,
      );
    });

    test('isEmpty / isNotEmpty / in', () {
      expect(eval({'field': 'x', 'operator': 'isEmpty'}, {'x': ''}), isTrue);
      expect(
        eval({'field': 'x', 'operator': 'isNotEmpty'}, {'x': 'v'}),
        isTrue,
      );
      expect(
        eval(
          {
            'field': 'x',
            'operator': 'in',
            'value': ['a', 'b'],
          },
          {'x': 'b'},
        ),
        isTrue,
      );
    });
  });
}
