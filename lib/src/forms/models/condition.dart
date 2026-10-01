import 'field_enums.dart';

/// A conditional-logic rule evaluated against current form data.
///
/// Leaf rule:
/// ```json
/// {"field": "country", "operator": "equals", "value": "IN"}
/// ```
///
/// Composite rules:
/// ```json
/// {"and": [ ... ]}, {"or": [ ... ]}, {"not": { ... }}
/// ```
///
/// Supported operators are listed in [ConditionOperator]; custom ones can be
/// added with `ConditionEvaluator.registerOperator`.
///
/// Typed Dart form:
/// ```dart
/// Condition.when('country', ConditionOperator.equals, 'IN')
/// ```
class Condition {
  /// Creates a leaf condition.
  const Condition.leaf({
    required this.field,
    required this.operator,
    this.value,
  }) : and = null,
       or = null,
       not = null;

  /// Creates a leaf condition from a typed [ConditionOperator].
  Condition.when(String this.field, ConditionOperator op, [this.value])
    : operator = op.jsonName,
      and = null,
      or = null,
      not = null;

  /// Creates an AND composite.
  const Condition.allOf(List<Condition> this.and)
    : or = null,
      not = null,
      field = null,
      operator = null,
      value = null;

  /// Creates an OR composite.
  const Condition.anyOf(List<Condition> this.or)
    : and = null,
      not = null,
      field = null,
      operator = null,
      value = null;

  /// Creates a NOT composite.
  const Condition.negate(Condition this.not)
    : and = null,
      or = null,
      field = null,
      operator = null,
      value = null;

  /// Parses a condition tree from JSON.
  factory Condition.fromJson(Map<String, dynamic> json) {
    List<Condition> parseList(Object? raw) => (raw as List? ?? const [])
        .map((e) => Condition.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();

    if (json.containsKey('and') || json.containsKey('all')) {
      return Condition.allOf(parseList(json['and'] ?? json['all']));
    }
    if (json.containsKey('or') || json.containsKey('any')) {
      return Condition.anyOf(parseList(json['or'] ?? json['any']));
    }
    if (json.containsKey('not')) {
      return Condition.negate(
        Condition.fromJson(Map<String, dynamic>.from(json['not'] as Map)),
      );
    }
    return Condition.leaf(
      field: json['field']?.toString() ?? '',
      operator: json['operator']?.toString() ?? 'equals',
      value: json['value'],
    );
  }

  /// AND children (composite).
  final List<Condition>? and;

  /// OR children (composite).
  final List<Condition>? or;

  /// Negated child (composite).
  final Condition? not;

  /// Field id referenced by a leaf rule.
  final String? field;

  /// Comparison operator of a leaf rule.
  final String? operator;

  /// Comparison operand of a leaf rule.
  final Object? value;

  /// Typed operator of a leaf rule (null for custom operators).
  ConditionOperator? get op => ConditionOperator.fromString(operator);

  /// Every field id this condition reads.
  Set<String> get referencedFields => {
    if (field != null && field!.isNotEmpty) field!,
    for (final c in and ?? const <Condition>[]) ...c.referencedFields,
    for (final c in or ?? const <Condition>[]) ...c.referencedFields,
    ...?not?.referencedFields,
  };

  /// Serializes back to JSON.
  Map<String, dynamic> toJson() {
    if (and != null)
      return {
        'and': [for (final c in and!) c.toJson()],
      };
    if (or != null)
      return {
        'or': [for (final c in or!) c.toJson()],
      };
    if (not != null) return {'not': not!.toJson()};
    return {
      'field': field,
      'operator': operator,
      if (value != null) 'value': value,
    };
  }
}
