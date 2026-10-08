import 'package:flutter/material.dart';
import 'package:services_rj/services_rj.dart';

import '../widgets/demo_widgets.dart';
import 'lab_common.dart';

/// Programmatic validators handed to `DynamicFormController(customValidators:)`
/// and referenced from JSON as `{"type": "custom", "name": ...}`.
final Map<String, CustomValidatorFn> labCustomValidators = {
  'noSpaces': (value, data) {
    final text = value?.toString() ?? '';
    return text.contains(' ') ? 'Handles cannot contain spaces' : null;
  },
  // Cross-field rule: the badge must start with the first letter of the name.
  'badgeMatchesName': (value, data) {
    final badge = value?.toString().trim() ?? '';
    final name = data['fullName']?.toString().trim() ?? '';
    if (badge.isEmpty || name.isEmpty) return null;
    return badge.toLowerCase().startsWith(name[0].toLowerCase())
        ? null
        : 'Badge text must start with "${name[0]}"';
  },
};

/// Registers the globally available `evenNumber` validator, usable from any
/// form JSON as `{"type": "evenNumber"}`.
///
/// Safe to call repeatedly.
void registerLabValidators() {
  ValidatorRegistry.register(
    'evenNumber',
    (cfg) => CustomValidator(cfg, (value, data) {
      if (value == null || value.toString().isEmpty) return null;
      final n = int.tryParse(value.toString());
      return n != null && n.isEven
          ? null
          : cfg.message ?? 'Pick an even number';
    }),
  );
}

/// One field per [ValidatorType], each with its own custom message.
const Map<String, dynamic> validatorsLabForm = {
  'id': 'validators_lab',
  'fields': [
    {'type': 'sectionHeader', 'id': 'h1', 'label': 'Required and format rules'},
    {
      'type': 'text',
      'id': 'fullName',
      'label': 'Full name',
      'validators': [
        {'type': 'required', 'message': 'Please tell us your name'},
      ],
    },
    {
      'type': 'email',
      'id': 'email',
      'label': 'Email',
      'validators': [
        {'type': 'email', 'message': 'That email looks incomplete'},
      ],
    },
    {
      'type': 'phone',
      'id': 'phone',
      'label': 'Phone',
      'validators': [
        {'type': 'phone', 'message': 'Use 7 to 15 digits, spaces allowed'},
      ],
    },
    {
      'type': 'url',
      'id': 'website',
      'label': 'Website',
      'validators': [
        {'type': 'url', 'message': 'Add a domain like example.com'},
      ],
    },
    {'type': 'sectionHeader', 'id': 'h2', 'label': 'Numbers'},
    {
      'type': 'number',
      'id': 'seats',
      'label': 'Seats (1 to 10, whole numbers)',
      'validators': [
        {'type': 'number', 'message': 'Whole numbers only'},
        {'type': 'min', 'value': 1, 'message': 'Book at least one seat'},
        {'type': 'max', 'value': 10, 'message': 'We cap bookings at ten'},
      ],
    },
    {
      'type': 'decimal',
      'id': 'budget',
      'label': 'Budget in rupees',
      'validators': [
        {'type': 'decimal', 'message': 'Enter an amount like 1250.50'},
      ],
    },
    {'type': 'sectionHeader', 'id': 'h3', 'label': 'Text length and pattern'},
    {
      'type': 'text',
      'id': 'username',
      'label': 'Username (4 to 12 chars, a-z 0-9 _)',
      'validators': [
        {'type': 'minLength', 'value': 4, 'message': 'Four characters minimum'},
        {'type': 'maxLength', 'value': 12, 'message': 'Twelve characters max'},
        {
          'type': 'regex',
          'value': r'^[a-z0-9_]+$',
          'message': 'Lowercase letters, digits and underscore only',
        },
      ],
    },
    {
      'type': 'text',
      'id': 'postcode',
      'label': 'Postcode',
      'helperText': 'Uses the field-level regex / maxLength keys',
      'regex': r'^\d{6}$',
      'maxLength': 6,
    },
    {'type': 'sectionHeader', 'id': 'h4', 'label': 'Passwords'},
    {
      'type': 'password',
      'id': 'password',
      'label': 'Password',
      'validators': [
        {
          'type': 'passwordStrength',
          'value': 10,
          'message': 'Use 10+ chars with Aa, 1 and a symbol',
        },
      ],
    },
    {
      'type': 'password',
      'id': 'confirm',
      'label': 'Repeat password',
      'validators': [
        {
          'type': 'matchField',
          'value': 'password',
          'message': 'Passwords differ',
        },
      ],
    },
    {'type': 'sectionHeader', 'id': 'h5', 'label': 'Selections'},
    {
      'type': 'multiselect',
      'id': 'topics',
      'label': 'Pick two or three topics',
      'required': true,
      'options': [
        {'label': 'Testing', 'value': 'testing'},
        {'label': 'Tooling', 'value': 'tooling'},
        {'label': 'Performance', 'value': 'performance'},
        {'label': 'Animations', 'value': 'animations'},
      ],
      'validators': [
        {'type': 'minItems', 'value': 2, 'message': 'Choose at least two'},
        {'type': 'maxItems', 'value': 3, 'message': 'Three at most'},
      ],
    },
    {'type': 'sectionHeader', 'id': 'h6', 'label': 'Custom validators'},
    {
      'type': 'text',
      'id': 'handle',
      'label': 'Handle (controller customValidators)',
      'validators': [
        {'type': 'custom', 'name': 'noSpaces'},
      ],
    },
    {
      'type': 'text',
      'id': 'badge',
      'label': 'Badge text (reads fullName)',
      'validators': [
        {'type': 'custom', 'name': 'badgeMatchesName'},
      ],
    },
    {
      'type': 'number',
      'id': 'lucky',
      'label': 'Lucky number (ValidatorRegistry.register)',
      'validators': [
        {'type': 'evenNumber', 'message': 'Lucky numbers here are even'},
      ],
    },
  ],
};

/// A record that satisfies every rule in [validatorsLabForm].
const Map<String, dynamic> validatorsValidSample = {
  'fullName': 'Asha Verma',
  'email': 'asha@example.com',
  'phone': '+91 98765 43210',
  'website': 'https://example.com',
  'seats': 4,
  'budget': '1250.50',
  'username': 'asha_v',
  'postcode': '560001',
  'password': 'Str0ng!Passw',
  'confirm': 'Str0ng!Passw',
  'topics': ['testing', 'tooling'],
  'handle': 'ashav',
  'badge': 'Asha',
  'lucky': 8,
};

/// A record that breaks every rule in [validatorsLabForm] except the
/// cross-field badge rule (it is skipped while the name is empty).
const Map<String, dynamic> validatorsInvalidSample = {
  'fullName': '',
  'email': 'asha@',
  'phone': 'abc',
  'website': 'not a url',
  'seats': 40,
  'budget': 'lots',
  'username': 'A B',
  'postcode': '12',
  'password': 'weak',
  'confirm': 'other',
  'topics': ['testing'],
  'handle': 'has space',
  'badge': 'Zed',
  'lucky': 7,
};

/// Page for the validators lab.
class ValidatorsLabPage extends StatefulWidget {
  /// Creates the page.
  const ValidatorsLabPage({super.key});

  @override
  State<ValidatorsLabPage> createState() => _ValidatorsLabPageState();
}

class _ValidatorsLabPageState extends State<ValidatorsLabPage> {
  final _log = EventLog();
  late final DynamicFormController _c;

  @override
  void initState() {
    super.initState();
    registerLabValidators();
    _c = DynamicFormController(customValidators: labCustomValidators);
  }

  @override
  void dispose() {
    _c.dispose();
    _log.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => DemoPage(
    title: 'Validators lab',
    intro:
        'Every ValidatorType, each with its own message. Fill the form with '
        'the valid or invalid sample, then run the checks below.',
    children: [
      DemoSection(
        title: 'Form',
        subtitle: 'Fields validate live once they have shown an error.',
        child: DynamicForm(
          controller: _c,
          json: validatorsLabForm,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          showSubmitButton: true,
          submitLabel: 'submit()',
          onValidation: (e) => _log.add('onValidation: ${e.length} error(s)'),
          onError: (e) => _log.add('onError: ${e.keys.join(', ')}'),
          onSubmit: (d) => _log.add('onSubmit: ${labCompact(d)}'),
        ),
      ),
      DemoSection(
        title: 'Run the checks',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LabActions(
              actions: {
                'Fill valid sample': () =>
                    _c.setFormData(validatorsValidSample),
                'Fill invalid sample': () =>
                    _c.setFormData(validatorsInvalidSample),
                'validate()': () => _log.add('validate() -> ${_c.validate()}'),
                'validateField(email)': () => _log.add(
                  'validateField(email) -> ${_c.validateField('email')}',
                ),
                'getErrors()': () =>
                    _log.add('getErrors() -> ${labCompact(_c.getErrors())}'),
                'clearErrors()': () {
                  _c.clearErrors();
                  _log.add('clearErrors() -> hasErrors=${_c.hasErrors}');
                },
                'reset()': () {
                  _c.reset();
                  _log.add('reset()');
                },
              },
            ),
            const SizedBox(height: 12),
            EventLogView(log: _log),
          ],
        ),
      ),
      const DemoSection(
        title: 'Registering custom rules',
        child: CodeSnippet(
          "// Per controller, used as {\"type\": \"custom\", \"name\": \"noSpaces\"}\n"
          "DynamicFormController(customValidators: {\n"
          "  'noSpaces': (value, data) =>\n"
          "      '\$value'.contains(' ') ? 'No spaces' : null,\n"
          "});\n\n"
          "// Global, used as {\"type\": \"evenNumber\"}\n"
          "ValidatorRegistry.register('evenNumber', (cfg) =>\n"
          "    CustomValidator(cfg, (v, _) => ...));",
        ),
      ),
    ],
  );
}
