import 'package:flutter/material.dart';
import 'package:services_rj/services_rj.dart';

import '../catalog/field_catalog.dart';
import '../catalog/reference_catalog.dart';
import '../widgets/doc_widgets.dart';
import '../widgets/guide_search.dart';

/// The Getting started app. Kept identical to `example/lib/quick_start.dart`,
/// which a test runs.
const quickStartCode = '''
import 'package:flutter/material.dart';
import 'package:services_rj/services_rj.dart';

void main() => runApp(const MaterialApp(home: ProfilePage()));

const profileForm = {
  'padding': 'standard',
  'fields': [
    {
      'type': 'text',
      'id': 'fullName',
      'label': 'Full name',
      'validators': ['required'],
    },
    {
      'type': 'searchableDropdown',
      'id': 'city',
      'label': 'City',
      'options': ['Ahmedabad', 'Bengaluru', 'Mumbai', 'Pune', 'Surat'],
    },
    {
      'type': 'radioGroup',
      'id': 'plan',
      'label': 'Plan',
      'optionStyle': 'card',
      'options': [
        {'label': 'Free', 'value': 'free', 'description': 'For trying out'},
        {'label': 'Pro', 'value': 'pro', 'description': 'For teams'},
      ],
    },
    {'type': 'switch', 'id': 'newsletter', 'label': 'Send me updates'},
  ],
};

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final controller = DynamicFormController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: DynamicForm(
        controller: controller,
        json: profileForm, // a Map, or the JSON string from your API
        showSubmitButton: true,
        onSubmit: (data) => ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Saved: \$data'))),
      ),
    );
  }
}''';

class GettingStartedPage extends StatelessWidget {
  const GettingStartedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DocPage(
      title: 'Getting started',
      intro:
          'services_rj builds complete Flutter forms from JSON: '
          '${FieldType.values.length} field types, validation, conditional '
          'logic, multi-step wizards, enum-driven options, extendable '
          '(repeatable) sections and per-field styling. Every example in '
          'this guide is live — edit it and watch the form data change.',
      children: const [
        GuideSearch(),
        SizedBox(height: 8),
        H2('1. Install'),
        CodeBlock('''
dependencies:
  services_rj: ^1.2.0'''),
        H2('2. Describe the form'),
        P(
          'A form is a map with a `fields` list (or a `steps` list for a '
          'wizard). Each field needs an `id` and a `type`.',
        ),
        LivePreview(
          json: {
            'fields': [
              {
                'type': 'text',
                'id': 'fullName',
                'label': 'Full name',
                'validators': ['required'],
              },
              {
                'type': 'dropdown',
                'id': 'team',
                'label': 'Team',
                'options': ['Design', 'Mobile', 'Platform'],
              },
              {'type': 'switch', 'id': 'remote', 'label': 'Works remotely'},
            ],
          },
        ),
        H2('3. Render it'),
        P(
          'A complete app: paste it into `lib/main.dart` and run. '
          '`DynamicForm` is a scrolling list of fields, so put it in a '
          '`Scaffold` body (it needs a `Material` ancestor and a bounded '
          'height), not directly under `MaterialApp`.',
        ),
        CodeBlock(quickStartCode),
        Callout(
          'Only importing forms? `import '
          '\'package:services_rj/forms.dart\';` exposes just the form '
          'builder.',
        ),
        H2('How it fits together'),
        P(
          '`FormParser` turns JSON into `FormConfig` / `FieldConfig`. The '
          '`DynamicFormController` holds one `ValueNotifier` per field '
          'aspect (value, error, visibility, options…), so typing in one '
          'field never rebuilds another. `DynamicForm` renders each field '
          'through `FieldWrapper`, which picks the renderer from '
          '`FieldFactory` and applies overrides.',
        ),
      ],
    );
  }
}

class FieldTypesPage extends StatefulWidget {
  const FieldTypesPage({super.key});

  @override
  State<FieldTypesPage> createState() => _FieldTypesPageState();
}

class _FieldTypesPageState extends State<FieldTypesPage> {
  FieldCategory? _category;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final docs = fieldCatalog.where((d) {
      if (_category != null && d.category != _category) return false;
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      return d.type.name.toLowerCase().contains(q) ||
          d.summary.toLowerCase().contains(q) ||
          d.aliases.any((a) => a.toLowerCase().contains(q));
    }).toList();

    return DocPage(
      title: 'Field types',
      intro:
          'All ${FieldType.values.length} values of `FieldType`. JSON '
          '`type` accepts camelCase, snake_case or kebab-case.',
      children: [
        TextField(
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            hintText: 'Filter field types',
          ),
          onChanged: (v) => setState(() => _query = v),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              label: const Text('All'),
              selected: _category == null,
              onSelected: (_) => setState(() => _category = null),
            ),
            for (final c in FieldCategory.values)
              ChoiceChip(
                label: Text(c.title),
                selected: _category == c,
                onSelected: (_) => setState(() => _category = c),
              ),
          ],
        ),
        const SizedBox(height: 8),
        for (final d in docs) _FieldDocCard(doc: d),
        if (docs.isEmpty) const P('No field type matches that filter.'),
      ],
    );
  }
}

class _FieldDocCard extends StatelessWidget {
  const _FieldDocCard({required this.doc});
  final FieldDoc doc;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            children: [
              Text(
                '"${doc.type.name}"',
                style: text.titleMedium?.copyWith(fontFamily: 'monospace'),
              ),
              Chip(
                label: Text(doc.category.title),
                visualDensity: VisualDensity.compact,
              ),
              if (doc.pluggable)
                const Chip(
                  avatar: Icon(Icons.extension, size: 16),
                  label: Text('adapter'),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          const SizedBox(height: 6),
          P(doc.summary),
          P(
            'Value: `${doc.valueType}`'
            '${doc.aliases.isEmpty ? '' : ' · Also accepted: ${doc.aliases.map((a) => '`$a`').join(', ')}'}',
          ),
          if (doc.keys.isNotEmpty)
            KeyTable(
              headers: const ['Extra key', 'Meaning'],
              rows: [
                for (final e in doc.keys.entries) [e.key, e.value],
              ],
            ),
          LivePreview(json: doc.example),
        ],
      ),
    );
  }
}

class PropertiesPage extends StatelessWidget {
  const PropertiesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final groups = <String, List<KeyDoc>>{};
    for (final d in fieldPropertyDocs) {
      groups.putIfAbsent(d.group, () => []).add(d);
    }
    return DocPage(
      title: 'Field properties',
      intro:
          'Keys every field understands. Unknown keys are kept in '
          '`FieldConfig.extra` and read by individual field types (see each '
          'type\'s "Extra key" table).',
      children: [
        for (final g in groups.entries) ...[H2(g.key), KeyTable.docs(g.value)],
        const H2('JSON enums'),
        const P(
          'These keys take one of a fixed set of names. In Dart they '
          'are real enums, so `FieldConfig(keyboardType: KeyboardKind.email)` '
          'cannot be misspelt.',
        ),
        KeyTable(
          headers: const ['Key', 'Allowed values'],
          rows: [
            for (final e in jsonEnumDocs.entries)
              [e.key, e.value.map((v) => '`$v`').join(', ')],
          ],
        ),
        const H2('Icons'),
        P(
          'Icon names usable in `prefixIcon`, `suffixIcon` and option `icon`: '
          '${FieldUtils.iconNames.map((n) => '`$n`').join(', ')}. Add your '
          'own with `FieldUtils.registerIcon(\'rocket\', Icons.rocket)`.',
        ),
        const H2('Form root keys'),
        const KeyTable(
          headers: ['Key', 'Meaning'],
          rows: [
            ['id', 'Form id.'],
            ['title', 'Form title.'],
            ['description', 'Form description.'],
            ['fields', 'Fields of a single-page form.'],
            ['steps', 'Wizard steps: `{title, subtitle, fields}`.'],
            ['style', 'Style applied to every field (fields can override).'],
            ['confirmDiscard', 'Ask before leaving with unsaved changes.'],
            ['discardTitle', 'Title of that dialog.'],
            ['discardMessage', 'Message of that dialog.'],
            ['data', 'Record to prefill (alias `initialData`).'],
            [
              'padding',
              'Space around the whole form: a number, a spacing name '
                  '(`standard` = 16) or a Map.',
            ],
            ['fieldSpacing', 'Gap between fields (default 16).'],
            ['fieldPadding', 'Default inner padding of every field.'],
          ],
        ),
      ],
    );
  }
}

class ValidationPage extends StatelessWidget {
  const ValidationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DocPage(
      title: 'Validation',
      intro:
          'Validators run in order and the first failure is shown. Once a '
          'field shows an error it re-validates as the user types.',
      children: [
        const H2('Required and optional fields'),
        const P(
          'One rule drives validation: a required field must have a value, '
          'an optional field may be left empty. A field is required when it '
          'has `"required": true`, a `required` validator, a `requiredWhen` '
          'condition that holds, or `controller.setRequired(id, required: '
          'true)`. An optional field that is empty skips its format, length, '
          'range and item-count checks; once it has a value, they all run. '
          'Custom validators always run, so cross-field rules can check '
          'empty values. `matchField` passes when both fields are empty.',
        ),
        const P(
          'Labels show it: required fields get a red `*` by default. Set '
          '`"requiredMark"` in the form `style` to `optional` ("(optional)" '
          'on the others), `both` or `none`, and style the mark with '
          '`requiredMarkStyle`. Screen readers hear "required". Tick the '
          'checkbox below and watch GSTIN become required.',
        ),
        const LivePreview(
          json: {
            'style': {'requiredMark': 'both'},
            'fields': [
              {
                'type': 'text',
                'id': 'fullName',
                'label': 'Full name',
                'required': true,
              },
              {
                'type': 'email',
                'id': 'workEmail',
                'label': 'Work email',
                'validators': ['email'],
                'helperText': 'Optional: empty is fine, a typo is not',
              },
              {
                'type': 'checkbox',
                'id': 'business',
                'label': 'This is a business purchase',
              },
              {
                'type': 'text',
                'id': 'gstin',
                'label': 'GSTIN',
                'preset': 'gst',
                'requiredWhen': {'field': 'business', 'operator': 'isTrue'},
              },
              {
                'type': 'checkboxGroup',
                'id': 'topics',
                'label': 'Topics',
                'minItems': 2,
                'optionStyle': 'chip',
                'helperText': 'Optional, but pick at least 2 if you pick any',
                'options': ['Billing', 'Delivery', 'Returns', 'Offers'],
              },
            ],
          },
        ),
        const H2('Built-in validators'),
        KeyTable(
          headers: const ['Validator', 'Rule'],
          rows: [
            for (final e in validatorDocs.entries) [e.key.name, e.value],
          ],
        ),
        const H2('Writing validators'),
        const P(
          'A bare string is shorthand for `{"type": ...}`. Every '
          'validator accepts a custom `message`.',
        ),
        const LivePreview(
          json: {
            'fields': [
              {
                'type': 'text',
                'id': 'username',
                'label': 'Username',
                'textCase': 'lower',
                'validators': [
                  'required',
                  {'type': 'minLength', 'value': 4},
                  {
                    'type': 'regex',
                    'value': r'^[a-z0-9_]+$',
                    'message': 'Only a–z, 0–9 and _',
                  },
                ],
              },
              {
                'type': 'password',
                'id': 'pass',
                'label': 'Password',
                'validators': ['required', 'passwordStrength'],
              },
              {
                'type': 'password',
                'id': 'pass2',
                'label': 'Repeat password',
                'validators': [
                  {'type': 'matchField', 'value': 'pass'},
                ],
              },
              {
                'type': 'checkboxGroup',
                'id': 'days',
                'label': 'Pick two or three days',
                'optionLayout': 'horizontal',
                'minItems': 2,
                'maxItems': 3,
                'options': ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'],
              },
            ],
          },
        ),
        const H2('Text presets (PAN, Aadhaar, GST, …)'),
        const P(
          'Set `preset` on a text field to get the right keyboard, allowed '
          'characters, capitalization, length limit and a format check in '
          'one key. Aadhaar uses the Verhoeff checksum and GST the check '
          'character. Empty values pass, so add `required` when needed. '
          'Your own `keyboardType`, `textCase`, `maxLength` and `hint` win '
          'over the preset.',
        ),
        KeyTable(
          headers: const ['Preset', 'Rule'],
          rows: [
            for (final p in TextPreset.values)
              [
                p.name,
                TextPresets.builtIn[p]?.message ??
                    'Your own `regex`, reported with `presetMessage`.',
              ],
          ],
        ),
        const LivePreview(
          json: {
            'fields': [
              {
                'type': 'text',
                'id': 'fullName',
                'label': 'Full name',
                'preset': 'name',
                'required': true,
              },
              {
                'type': 'text',
                'id': 'mobile',
                'label': 'Mobile number',
                'preset': 'mobile',
                'required': true,
              },
              {'type': 'text', 'id': 'pan', 'label': 'PAN', 'preset': 'pan'},
              {
                'type': 'text',
                'id': 'aadhaar',
                'label': 'Aadhaar number',
                'preset': 'aadhaar',
              },
              {
                'type': 'text',
                'id': 'gstin',
                'label': 'GSTIN',
                'preset': 'gst',
                'presetMessage': 'That GSTIN does not look right',
              },
              {
                'type': 'text',
                'id': 'empId',
                'label': 'Employee id',
                'preset': 'custom',
                'regex': r'^EMP-\d{4}$',
                'presetMessage': 'Use the format EMP-1234',
                'textCase': 'upper',
                'maxLength': 8,
              },
            ],
          },
        ),
        const CodeBlock(r'''
// A reusable preset of your own, usable as {"preset": "employeeId"}
TextPresets.register('employeeId', TextPresetSpec(
  message: 'Employee id looks like E-12345',
  pattern: r'^E-\d{5}$',
  textCase: TextCase.upper,
  maxLength: 7,
  hint: 'E-12345',
  // check: (value) => ... for rules a pattern cannot express (checksums)
));'''),
        const H2('Typed Dart validators'),
        const CodeBlock('''
FieldConfig(
  id: 'age',
  type: FieldType.number,
  validators: [
    ValidatorConfig.required(message: 'Age is needed'),
    ValidatorConfig.of(ValidatorType.min, value: 18),
  ],
)'''),
        const H2('Custom validators'),
        const P(
          'Two ways: pass functions to the controller and reference them '
          'with `{"type": "custom", "name": "..."}`, or register a reusable '
          'validator type once for every form.',
        ),
        const CodeBlock(
          '''
// Per controller
final controller = DynamicFormController(customValidators: {
  'evenOnly': (value, data) =>
      (value is int && value.isOdd) ? 'Must be even' : null,
});
// JSON: {"type": "custom", "name": "evenOnly"}

// Globally, usable as {"type": "gstin"}
ValidatorRegistry.register('gstin', (cfg) => CustomValidator(cfg,
    (v, _) => isValidGstin('\$v') ? null : cfg.message ?? 'Invalid GSTIN'));''',
        ),
        const Callout(
          'Hidden and disabled fields are never validated, so a '
          'conditionally hidden required field never blocks submit.',
        ),
      ],
    );
  }
}

class ConditionsPage extends StatelessWidget {
  const ConditionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DocPage(
      title: 'Conditional logic',
      intro:
          '`visibleWhen`, `enabledWhen` and `requiredWhen` take a '
          'condition that is re-evaluated after every change.',
      children: [
        KeyTable(
          headers: const ['Operator', 'Meaning'],
          rows: [
            for (final e in operatorDocs.entries)
              [
                e.key.jsonName,
                '${e.value}${e.key.aliases.isEmpty ? '' : ' Aliases: ${e.key.aliases.map((a) => '`$a`').join(', ')}.'}',
              ],
          ],
        ),
        const H2('Leaf and composite rules'),
        const CodeBlock('''
{"field": "plan", "operator": "equals", "value": "team"}
{"and": [rule, rule]}   // alias "all"
{"or":  [rule, rule]}   // alias "any"
{"not": rule}'''),
        const LivePreview(
          json: {
            'fields': [
              {
                'type': 'segmented',
                'id': 'plan',
                'label': 'Plan',
                'initialValue': 'solo',
                'options': [
                  {'label': 'Solo', 'value': 'solo'},
                  {'label': 'Team', 'value': 'team'},
                ],
              },
              {
                'type': 'stepper',
                'id': 'members',
                'label': 'Team size',
                'min': 2,
                'max': 50,
                'visibleWhen': {
                  'field': 'plan',
                  'operator': 'equals',
                  'value': 'team',
                },
              },
              {
                'type': 'checkbox',
                'id': 'invoice',
                'label': 'I need a GST invoice',
              },
              {
                'type': 'text',
                'id': 'gstin',
                'label': 'GSTIN',
                'textCase': 'upper',
                'visibleWhen': {'field': 'invoice', 'operator': 'isTrue'},
                'requiredWhen': {
                  'and': [
                    {'field': 'invoice', 'operator': 'isTrue'},
                    {'field': 'plan', 'operator': 'equals', 'value': 'team'},
                  ],
                },
                'helperText': 'Required for team plans',
              },
            ],
          },
        ),
        const H2('Typed conditions and custom operators'),
        const CodeBlock('''
Condition.when('members', ConditionOperator.greaterThan, 10)

ConditionEvaluator.registerOperator('divisibleBy',
    (actual, expected) => actual is num && expected is num && actual % expected == 0);
// JSON: {"field": "seats", "operator": "divisibleBy", "value": 4}'''),
        const Callout(
          'Conditionally hidden fields are left out of '
          '`getFormData()`; pass `includeHidden: true` to get everything.',
        ),
      ],
    );
  }
}
