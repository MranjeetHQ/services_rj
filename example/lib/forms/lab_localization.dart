import 'package:flutter/material.dart';
import 'package:services_rj/services_rj.dart';

import '../widgets/demo_widgets.dart';

/// Locale codes shipped with the package, in display order.
const List<String> labBuiltInLocales = ['en', 'hi', 'ar', 'es', 'fr', 'de'];

/// Extra locale registered at runtime with [registerLabTranslations].
const String labCustomLocale = 'pt';

/// Every locale shown in the lab.
const List<String> labLocales = [...labBuiltInLocales, labCustomLocale];

/// Native names for the locale chips.
const Map<String, String> labLocaleNames = {
  'en': 'English',
  'hi': 'हिन्दी',
  'ar': 'العربية',
  'es': 'Español',
  'fr': 'Français',
  'de': 'Deutsch',
  'pt': 'Português (custom)',
};

/// Message keys listed in the lookup table.
const List<String> labMessageKeys = [
  'required',
  'email',
  'phone',
  'url',
  'number',
  'decimal',
  'min',
  'max',
  'minLength',
  'maxLength',
  'regex',
  'matchField',
  'passwordStrength',
  'minItems',
  'maxItems',
  'next',
  'back',
  'submit',
  'discardTitle',
  'discardMessage',
  'discard',
  'cancel',
  'addEntry',
  'removeEntry',
  'addOption',
];

/// Registers a partial Portuguese translation with
/// `FormLocalizations.addTranslations`. Keys left out fall back to English.
///
/// Safe to call repeatedly.
void registerLabTranslations() {
  FormLocalizations.addTranslations(labCustomLocale, {
    'required': 'Este campo é obrigatório',
    'email': 'Informe um e-mail válido',
    'minLength': 'Use pelo menos {value} caracteres',
    'matchField': 'Os campos não coincidem',
    'next': 'Avançar',
    'back': 'Voltar',
    'submit': 'Enviar',
    'addEntry': 'Adicionar item',
    'entry': 'Item {value}',
  });
}

/// Single-page form that triggers many localized messages.
const Map<String, dynamic> localeLabForm = {
  'id': 'locale_lab',
  'fields': [
    {'type': 'text', 'id': 'name', 'label': 'Name', 'required': true},
    {
      'type': 'email',
      'id': 'email',
      'label': 'Email',
      'validators': ['required', 'email'],
    },
    {
      'type': 'phone',
      'id': 'phone',
      'label': 'Phone',
      'validators': ['phone'],
    },
    {
      'type': 'url',
      'id': 'site',
      'label': 'Website',
      'validators': ['url'],
    },
    {
      'type': 'number',
      'id': 'age',
      'label': 'Age',
      'validators': [
        'number',
        {'type': 'min', 'value': 18},
        {'type': 'max', 'value': 99},
      ],
    },
    {
      'type': 'decimal',
      'id': 'height',
      'label': 'Height (m)',
      'validators': ['decimal'],
    },
    {
      'type': 'textarea',
      'id': 'bio',
      'label': 'Short bio',
      'maxLines': 2,
      'validators': [
        {'type': 'minLength', 'value': 10},
        {'type': 'maxLength', 'value': 40},
      ],
    },
    {
      'type': 'text',
      'id': 'code',
      'label': 'Code (letters only)',
      'validators': [
        {'type': 'regex', 'value': '^[A-Za-z]+\$'},
      ],
    },
    {
      'type': 'password',
      'id': 'password',
      'label': 'Password',
      'validators': ['passwordStrength'],
    },
    {
      'type': 'password',
      'id': 'confirm',
      'label': 'Repeat password',
      'validators': [
        {'type': 'matchField', 'value': 'password'},
      ],
    },
    {
      'type': 'multiselect',
      'id': 'topics',
      'label': 'Topics (2 to 3)',
      'options': ['Testing', 'Tooling', 'Animations', 'Security'],
      'validators': [
        {'type': 'minItems', 'value': 2},
        {'type': 'maxItems', 'value': 3},
      ],
    },
    {
      'type': 'chips',
      'id': 'skills',
      'label': 'Skills',
      'options': ['Dart', 'Kotlin'],
      'allowCustomOptions': true,
    },
    {
      'type': 'repeater',
      'id': 'guests',
      'label': 'Guests',
      'minItems': 1,
      'maxItems': 3,
      'fields': [
        {'type': 'text', 'id': 'guestName', 'label': 'Guest', 'required': true},
      ],
    },
  ],
};

/// Two-step form that shows the localized Next / Back / Submit buttons.
const Map<String, dynamic> localeWizardForm = {
  'id': 'locale_wizard',
  'steps': [
    {
      'title': 'One',
      'fields': [
        {'type': 'text', 'id': 'first', 'label': 'First', 'required': true},
      ],
    },
    {
      'title': 'Two',
      'fields': [
        {'type': 'email', 'id': 'second', 'label': 'Email', 'required': true},
      ],
    },
  ],
};

/// Page for the localization lab.
class LocalizationLabPage extends StatefulWidget {
  /// Creates the page.
  const LocalizationLabPage({super.key});

  @override
  State<LocalizationLabPage> createState() => _LocalizationLabPageState();
}

class _LocalizationLabPageState extends State<LocalizationLabPage> {
  final _forms = <String, DynamicFormController>{};
  final _wizards = <String, DynamicFormController>{};
  String _locale = 'en';

  @override
  void initState() {
    super.initState();
    registerLabTranslations();
  }

  @override
  void dispose() {
    for (final c in [..._forms.values, ..._wizards.values]) {
      c.dispose();
    }
    super.dispose();
  }

  DynamicFormController _form(String locale) =>
      _forms.putIfAbsent(locale, () => DynamicFormController(locale: locale));

  DynamicFormController _wizard(String locale) =>
      _wizards.putIfAbsent(locale, () => DynamicFormController(locale: locale));

  @override
  Widget build(BuildContext context) {
    final controller = _form(_locale);
    final l10n = controller.l10n;
    return DemoPage(
      title: 'Localization lab',
      intro:
          'One controller per locale. Validation messages, built-in buttons '
          'and the repeater / option controls follow the controller locale; '
          'Arabic is laid out right-to-left.',
      children: [
        DemoSection(
          title: 'Locale',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final code in labLocales)
                ChoiceChip(
                  label: Text(labLocaleNames[code]!),
                  selected: _locale == code,
                  onSelected: (_) => setState(() => _locale = code),
                ),
            ],
          ),
        ),
        Directionality(
          textDirection: l10n.isRtl ? TextDirection.rtl : TextDirection.ltr,
          child: Column(
            children: [
              DemoSection(
                title: 'Form (${l10n.locale}, rtl: ${l10n.isRtl})',
                subtitle: 'Press the button to trigger every message.',
                child: DynamicForm(
                  key: ValueKey('form-$_locale'),
                  controller: controller,
                  json: localeLabForm,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  showSubmitButton: true,
                  footer: Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.bug_report_outlined),
                      onPressed: () {
                        controller.setFormData({
                          'email': 'nope',
                          'phone': 'x',
                          'site': 'nope',
                          'age': 12,
                          'height': 'tall',
                          'bio': 'short',
                          'code': '123',
                          'password': 'weak',
                          'confirm': 'different',
                          'topics': ['Testing'],
                        });
                        controller.validate();
                      },
                      label: const Text('Fill invalid values and validate'),
                    ),
                  ),
                ),
              ),
              DemoSection(
                title: 'Wizard buttons',
                child: DynamicForm(
                  key: ValueKey('wizard-$_locale'),
                  controller: _wizard(_locale),
                  json: localeWizardForm,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                ),
              ),
              DemoSection(
                title: 'Message table',
                subtitle: 'FormLocalizations(locale).message(key, value: 3)',
                child: Table(
                  columnWidths: const {0: IntrinsicColumnWidth()},
                  children: [
                    for (final key in labMessageKeys)
                      TableRow(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 3,
                              horizontal: 8,
                            ),
                            child: Text(
                              key,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: Text(l10n.message(key, value: 3)),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const DemoSection(
          title: 'Adding a language',
          subtitle: 'Missing keys fall back to English.',
          child: CodeSnippet(
            "FormLocalizations.addTranslations('pt', {\n"
            "  'required': 'Este campo é obrigatório',\n"
            "  'submit': 'Enviar',\n"
            '});\n'
            "DynamicFormController(locale: 'pt');",
          ),
        ),
      ],
    );
  }
}
