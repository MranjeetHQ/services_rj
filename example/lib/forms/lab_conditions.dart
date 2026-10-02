import 'package:flutter/material.dart';
import 'package:services_rj/services_rj.dart';

import '../widgets/demo_widgets.dart';

/// One `visibleWhen` rule in the conditions lab, with sample inputs that make
/// it pass and fail (used by the UI hints and by tests).
class ConditionRule {
  /// Creates a rule.
  const ConditionRule({
    required this.op,
    required this.field,
    required this.label,
    required this.matching,
    required this.nonMatching,
    this.value,
  });

  /// Operator under demonstration.
  final ConditionOperator op;

  /// Id of the control field the rule reads.
  final String field;

  /// Text shown on the target field.
  final String label;

  /// Operand of the rule.
  final Object? value;

  /// Control value for which the target is visible.
  final Object? matching;

  /// Control value for which the target is hidden.
  final Object? nonMatching;

  /// Id of the target field this rule shows or hides.
  String get targetId => conditionTargetId(op);

  /// The typed condition.
  Condition get condition => Condition.when(field, op, value);
}

/// Id of the field that demonstrates [op].
String conditionTargetId(ConditionOperator op) => 'show_${op.name}';

/// Sixteen rules, one per [ConditionOperator].
const List<ConditionRule> conditionRules = [
  ConditionRule(
    op: ConditionOperator.equals,
    field: 'plan',
    value: 'pro',
    label: 'equals: plan is Pro',
    matching: 'pro',
    nonMatching: 'free',
  ),
  ConditionRule(
    op: ConditionOperator.notEquals,
    field: 'plan',
    value: 'free',
    label: 'notEquals: plan is not Free',
    matching: 'team',
    nonMatching: 'free',
  ),
  ConditionRule(
    op: ConditionOperator.greaterThan,
    field: 'age',
    value: 17,
    label: 'greaterThan: age above 17',
    matching: 18,
    nonMatching: 17,
  ),
  ConditionRule(
    op: ConditionOperator.greaterThanOrEqual,
    field: 'age',
    value: 21,
    label: 'greaterThanOrEqual: age 21 or more',
    matching: 21,
    nonMatching: 20,
  ),
  ConditionRule(
    op: ConditionOperator.lessThan,
    field: 'age',
    value: 13,
    label: 'lessThan: age under 13',
    matching: 12,
    nonMatching: 13,
  ),
  ConditionRule(
    op: ConditionOperator.lessThanOrEqual,
    field: 'age',
    value: 65,
    label: 'lessThanOrEqual: age 65 or less',
    matching: 65,
    nonMatching: 66,
  ),
  ConditionRule(
    op: ConditionOperator.contains,
    field: 'topics',
    value: 'testing',
    label: 'contains: topics include Testing',
    matching: ['testing'],
    nonMatching: ['tooling'],
  ),
  ConditionRule(
    op: ConditionOperator.notContains,
    field: 'topics',
    value: 'testing',
    label: 'notContains: Testing not chosen',
    matching: ['tooling'],
    nonMatching: ['testing'],
  ),
  ConditionRule(
    op: ConditionOperator.startsWith,
    field: 'promo',
    value: 'EARLY',
    label: 'startsWith: promo begins EARLY',
    matching: 'EARLY-77',
    nonMatching: 'LATE-77',
  ),
  ConditionRule(
    op: ConditionOperator.endsWith,
    field: 'promo',
    value: '2026',
    label: 'endsWith: promo ends 2026',
    matching: 'SPRING-2026',
    nonMatching: 'SPRING-2025',
  ),
  ConditionRule(
    op: ConditionOperator.isEmpty,
    field: 'notes',
    label: 'isEmpty: notes are blank',
    matching: '',
    nonMatching: 'something',
  ),
  ConditionRule(
    op: ConditionOperator.isNotEmpty,
    field: 'notes',
    label: 'isNotEmpty: notes have text',
    matching: 'something',
    nonMatching: '',
  ),
  ConditionRule(
    op: ConditionOperator.isIn,
    field: 'country',
    value: ['IN', 'DE'],
    label: 'in: country is India or Germany',
    matching: 'DE',
    nonMatching: 'US',
  ),
  ConditionRule(
    op: ConditionOperator.notIn,
    field: 'country',
    value: ['IN', 'DE'],
    label: 'notIn: country is neither',
    matching: 'US',
    nonMatching: 'IN',
  ),
  ConditionRule(
    op: ConditionOperator.isTrue,
    field: 'newsletter',
    label: 'isTrue: newsletter switched on',
    matching: true,
    nonMatching: false,
  ),
  ConditionRule(
    op: ConditionOperator.isFalse,
    field: 'newsletter',
    label: 'isFalse: newsletter off or untouched',
    matching: false,
    nonMatching: true,
  ),
];

/// Cities offered per country by [labCityLoader].
const Map<String, List<String>> labCities = {
  'IN': ['Bengaluru', 'Pune', 'Jaipur'],
  'US': ['Austin', 'Denver'],
  'DE': ['Berlin', 'Leipzig', 'Hamburg'],
};

/// Fake async loader for the `city` field (no network): resolves after a
/// short delay with the cities of the selected country.
Future<List<OptionItem>> labCityLoader(
  String fieldId,
  Map<String, dynamic> data,
) async {
  await Future<void>.delayed(const Duration(milliseconds: 250));
  if (fieldId != 'city') return const [];
  final cities = labCities[data['country']] ?? const <String>[];
  return [for (final c in cities) OptionItem(label: c, value: c)];
}

/// Registers the custom `divisibleBy` condition operator.
///
/// Safe to call repeatedly.
void registerLabOperators() {
  ConditionEvaluator.registerOperator('divisibleBy', (actual, expected) {
    final a = num.tryParse(actual?.toString() ?? '');
    final b = num.tryParse(expected?.toString() ?? '');
    return a != null && b != null && b != 0 && a % b == 0;
  });
}

Map<String, dynamic> _target(
  String id,
  String label,
  String key,
  Map<String, dynamic> condition, {
  String type = 'text',
  String? helper,
  Map<String, dynamic> extra = const {},
}) => {
  'type': type,
  'id': id,
  'label': label,
  'helperText': ?helper,
  key: condition,
  ...extra,
};

Map<String, dynamic> _header(String id, String label) => {
  'type': 'sectionHeader',
  'id': id,
  'label': label,
};

/// Builds the lab form: controls, sixteen `visibleWhen` targets, `enabledWhen`
/// and `requiredWhen` targets, compound conditions and a `dependsOn` chain.
Map<String, dynamic> buildConditionsLabForm() => {
  'id': 'conditions_lab',
  'fields': [
    _header('hc', 'Controls: change these and watch the rest'),
    {
      'type': 'radioGroup',
      'id': 'plan',
      'label': 'Plan',
      'optionLayout': 'horizontal',
      'options': [
        {'label': 'Free', 'value': 'free'},
        {'label': 'Pro', 'value': 'pro'},
        {'label': 'Team', 'value': 'team'},
      ],
    },
    {'type': 'number', 'id': 'age', 'label': 'Age'},
    {
      'type': 'dropdown',
      'id': 'country',
      'label': 'Country',
      'options': [
        {'label': 'India', 'value': 'IN'},
        {'label': 'United States', 'value': 'US'},
        {'label': 'Germany', 'value': 'DE'},
      ],
    },
    {
      'type': 'multiselect',
      'id': 'topics',
      'label': 'Topics',
      'options': [
        {'label': 'Testing', 'value': 'testing'},
        {'label': 'Tooling', 'value': 'tooling'},
      ],
    },
    {
      'type': 'text',
      'id': 'promo',
      'label': 'Promo code',
      'hint': 'EARLY-77 or SPRING-2026',
    },
    {'type': 'textarea', 'id': 'notes', 'label': 'Notes', 'maxLines': 2},
    {'type': 'switch', 'id': 'newsletter', 'label': 'Send me the newsletter'},
    {'type': 'number', 'id': 'quantity', 'label': 'Quantity'},
    _header('hv', 'visibleWhen: one target per ConditionOperator'),
    for (final r in conditionRules)
      _target(
        r.targetId,
        r.label,
        'visibleWhen',
        r.condition.toJson(),
        helper: 'Reads "${r.field}"',
      ),
    _header('he', 'enabledWhen'),
    _target(
      'licence',
      'Licence number (enabled when age >= 18)',
      'enabledWhen',
      Condition.when('age', ConditionOperator.greaterThanOrEqual, 18).toJson(),
    ),
    _target(
      'coupon',
      'Coupon (enabled when plan is not Free)',
      'enabledWhen',
      Condition.when('plan', ConditionOperator.notEquals, 'free').toJson(),
    ),
    _header('hr', 'requiredWhen'),
    _target(
      'company',
      'Company (required for Pro and Team)',
      'requiredWhen',
      Condition.when('plan', ConditionOperator.isIn, ['pro', 'team']).toJson(),
    ),
    _target(
      'promoReason',
      'Why this promo?',
      'requiredWhen',
      Condition.when('promo', ConditionOperator.isNotEmpty).toJson(),
    ),
    _header('hc2', 'Compound conditions'),
    _target(
      'both',
      'and: Team plan AND age 18+',
      'visibleWhen',
      Condition.allOf([
        Condition.when('plan', ConditionOperator.equals, 'team'),
        Condition.when('age', ConditionOperator.greaterThanOrEqual, 18),
      ]).toJson(),
    ),
    _target(
      'either',
      'or: India OR newsletter on',
      'visibleWhen',
      Condition.anyOf([
        Condition.when('country', ConditionOperator.equals, 'IN'),
        Condition.when('newsletter', ConditionOperator.isTrue),
      ]).toJson(),
    ),
    _target(
      'notFree',
      'not: anything but the Free plan',
      'visibleWhen',
      Condition.negate(
        Condition.when('plan', ConditionOperator.equals, 'free'),
      ).toJson(),
    ),
    _target(
      'nested',
      'nested: (Pro OR Team) AND promo not empty',
      'visibleWhen',
      Condition.allOf([
        Condition.anyOf([
          Condition.when('plan', ConditionOperator.equals, 'pro'),
          Condition.when('plan', ConditionOperator.equals, 'team'),
        ]),
        Condition.negate(Condition.when('promo', ConditionOperator.isEmpty)),
      ]).toJson(),
    ),
    // Raw JSON with operator aliases ("gte", "oneOf") and the "all" key.
    _target('aliases', 'JSON aliases: "all" + "gte" + "oneOf"', 'visibleWhen', {
      'all': [
        {'field': 'age', 'operator': 'gte', 'value': 18},
        {
          'field': 'country',
          'operator': 'oneOf',
          'value': ['IN', 'US'],
        },
      ],
    }),
    _target(
      'custom_divisible',
      'Custom operator: quantity divisible by 5',
      'visibleWhen',
      {'field': 'quantity', 'operator': 'divisibleBy', 'value': 5},
      helper: 'ConditionEvaluator.registerOperator',
    ),
    _header('hd', 'dependsOn: city options reload when country changes'),
    {
      'type': 'dropdown',
      'id': 'city',
      'label': 'City (loaded for the chosen country)',
      'dependsOn': ['country'],
    },
  ],
};

/// Page for the conditional-logic lab.
class ConditionsLabPage extends StatefulWidget {
  /// Creates the page.
  const ConditionsLabPage({super.key});

  @override
  State<ConditionsLabPage> createState() => _ConditionsLabPageState();
}

class _ConditionsLabPageState extends State<ConditionsLabPage> {
  late final DynamicFormController _c;
  late final Map<String, dynamic> _json;
  final _tick = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    registerLabOperators();
    _json = buildConditionsLabForm();
    _c = DynamicFormController(optionsLoader: labCityLoader);
    // The form attaches during the first build; refresh the summary after it.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _tick.value++;
    });
  }

  @override
  void dispose() {
    _tick.dispose();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => DemoPage(
    title: 'Conditional logic lab',
    intro:
        'visibleWhen, enabledWhen and requiredWhen with every '
        'ConditionOperator, compound and/or/not rules, and dependsOn.',
    children: [
      DemoSection(
        title: 'Live summary',
        child: ValueListenableBuilder<int>(
          valueListenable: _tick,
          builder: (context, _, _) {
            if (_c.config == null) return const SizedBox.shrink();
            final shown = conditionRules
                .where((r) => _c.state(r.targetId).visible.value)
                .map((r) => r.op.jsonName)
                .join(', ');
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Operator targets visible: $shown'),
                const SizedBox(height: 4),
                Text(
                  'licence enabled: ${_c.state('licence').enabled.value}, '
                  'company required: ${_c.state('company').required.value}',
                ),
              ],
            );
          },
        ),
      ),
      DemoSection(
        title: 'Form',
        child: DynamicForm(
          controller: _c,
          json: _json,
          onChanged: (_) => _tick.value++,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          showSubmitButton: true,
          submitLabel: 'Validate (requiredWhen)',
        ),
      ),
      const DemoSection(
        title: 'Typed conditions',
        child: CodeSnippet(
          "Condition.when('age', ConditionOperator.greaterThanOrEqual, 18)\n"
          'Condition.allOf([a, b])   // and\n'
          'Condition.anyOf([a, b])   // or\n'
          'Condition.negate(a)       // not',
        ),
      ),
    ],
  );
}
