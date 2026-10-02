import '../models/condition.dart';
import '../models/field_enums.dart';

/// Signature of a custom condition operator.
typedef ConditionOperatorFn = bool Function(Object? actual, Object? expected);

/// Evaluates [Condition] trees against current form data.
class ConditionEvaluator {
  const ConditionEvaluator._();

  static final Map<String, ConditionOperatorFn> _custom = {};

  /// Adds (or overrides) an operator usable from JSON by [name].
  ///
  /// ```dart
  /// ConditionEvaluator.registerOperator('divisibleBy',
  ///     (a, b) => a is num && b is num && a % b == 0);
  /// ```
  static void registerOperator(String name, ConditionOperatorFn fn) =>
      _custom[name] = fn;

  /// Returns whether [condition] holds for [data].
  static bool evaluate(Condition condition, Map<String, dynamic> data) {
    if (condition.and != null) {
      return condition.and!.every((c) => evaluate(c, data));
    }
    if (condition.or != null) {
      return condition.or!.any((c) => evaluate(c, data));
    }
    if (condition.not != null) {
      return !evaluate(condition.not!, data);
    }
    return _leaf(condition, data);
  }

  static bool _leaf(Condition c, Map<String, dynamic> data) {
    final actual = data[c.field];
    final expected = c.value;
    final custom = _custom[c.operator];
    if (custom != null) return custom(actual, expected);
    final op = c.op;
    if (op == null) return false;
    switch (op) {
      case ConditionOperator.equals:
        return _eq(actual, expected);
      case ConditionOperator.notEquals:
        return !_eq(actual, expected);
      case ConditionOperator.greaterThan:
        return _cmp(actual, expected, (r) => r > 0);
      case ConditionOperator.greaterThanOrEqual:
        return _cmp(actual, expected, (r) => r >= 0);
      case ConditionOperator.lessThan:
        return _cmp(actual, expected, (r) => r < 0);
      case ConditionOperator.lessThanOrEqual:
        return _cmp(actual, expected, (r) => r <= 0);
      case ConditionOperator.contains:
        return _contains(actual, expected);
      case ConditionOperator.notContains:
        return !_contains(actual, expected);
      case ConditionOperator.startsWith:
        return actual?.toString().startsWith(expected.toString()) ?? false;
      case ConditionOperator.endsWith:
        return actual?.toString().endsWith(expected.toString()) ?? false;
      case ConditionOperator.isEmpty:
        return _empty(actual);
      case ConditionOperator.isNotEmpty:
        return !_empty(actual);
      case ConditionOperator.isIn:
        return (expected as Iterable?)?.any((e) => _eq(actual, e)) ?? false;
      case ConditionOperator.notIn:
        return !((expected as Iterable?)?.any((e) => _eq(actual, e)) ?? false);
      case ConditionOperator.isTrue:
        return actual == true;
      case ConditionOperator.isFalse:
        return actual != true;
    }
  }

  static bool _empty(Object? v) =>
      v == null ||
      (v is String && v.isEmpty) ||
      (v is Iterable && v.isEmpty) ||
      (v is Map && v.isEmpty);

  static bool _contains(Object? actual, Object? expected) {
    if (actual is Iterable) return actual.any((e) => _eq(e, expected));
    return actual?.toString().contains(expected.toString()) ?? false;
  }

  static bool _eq(Object? a, Object? b) {
    if (a is Enum) a = a.name;
    if (b is Enum) b = b.name;
    if (a is num && b is num) return a == b;
    if (a is num || b is num) {
      final na = num.tryParse(a.toString());
      final nb = num.tryParse(b.toString());
      if (na != null && nb != null) return na == nb;
    }
    return a == b;
  }

  static bool _cmp(Object? a, Object? b, bool Function(int) test) {
    final na = a is num ? a : num.tryParse(a?.toString() ?? '');
    final nb = b is num ? b : num.tryParse(b?.toString() ?? '');
    if (na == null || nb == null) return false;
    return test(na.compareTo(nb));
  }
}
