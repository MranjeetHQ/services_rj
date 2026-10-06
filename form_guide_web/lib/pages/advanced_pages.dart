import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:services_rj/services_rj.dart';

import '../catalog/reference_catalog.dart';
import '../guide_enums.dart';
import '../widgets/doc_widgets.dart';

class EnumsPage extends StatelessWidget {
  const EnumsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DocPage(
      title: 'Enums',
      intro:
          'Enums work in two directions: Dart enums can supply a field\'s '
          'options, and every string option in the JSON has a typed enum in '
          'Dart.',
      children: const [
        H2('Dart enums as options'),
        P(
          'Register the enum once, then point any selection field at it with '
          '`"enum"`. The stored value is the enum `name`, so data stays '
          'JSON-friendly; `getEnum` turns it back into the enum.',
        ),
        CodeBlock('''
enum Cuisine { northIndian, southIndian, chinese, continental }
enum ShirtSize { xs, s, m, l, xl }

FormEnumRegistry.register('Cuisine', Cuisine.values);   // "North indian", …
FormEnumRegistry.register('ShirtSize', ShirtSize.values,
    label: (s) => s.name.toUpperCase());

// Reading values back
final cuisine = controller.getEnum('cuisine', Cuisine.values);      // Cuisine?
final sizes = controller.getEnumList('sizes', ShirtSize.values);    // List<ShirtSize>

// Writing: enums are accepted directly
controller.setValue('cuisine', Cuisine.chinese);'''),
        LivePreview(
          json: {
            'fields': [
              {
                'type': 'dropdown',
                'id': 'cuisine',
                'label': 'Cuisine',
                'enum': 'Cuisine',
              },
              {
                'type': 'chips',
                'id': 'sizes',
                'label': 'T-shirt sizes to order',
                'enum': 'ShirtSize',
                'multiple': true,
              },
              {
                'type': 'radioGroup',
                'id': 'seniority',
                'label': 'Seniority',
                'enum': 'Seniority',
                'optionLayout': 'wrap',
              },
            ],
          },
        ),
        Callout(
          '`label`, `description`, `icon` and `enabled` callbacks on '
          '`register` let each enum value carry its own text, icon or '
          'disabled state. `OptionItem.fromEnum(values)` builds the same '
          'options without registering.',
        ),
        H2('Typed configuration'),
        P(
          'Building forms in Dart? Use the enums instead of strings. '
          '`FormConfig.toJson()` turns the result back into JSON for your '
          'server.',
        ),
        CodeBlock('''
final form = FormConfig(fields: [
  FieldConfig(
    id: 'handle',
    type: FieldType.text,
    keyboardType: KeyboardKind.text,
    textInputAction: InputActionKind.next,
    textCase: TextCase.lower,
    validators: [ValidatorConfig.of(ValidatorType.minLength, value: 3)],
  ),
  FieldConfig(
    id: 'seniority',
    type: FieldType.radioGroup,
    enumName: 'Seniority',
    optionLayout: OptionLayout.grid,
    columns: 3,
    visibleWhen: Condition.when('handle', ConditionOperator.isNotEmpty),
  ),
]);

DynamicForm(controller: controller, json: form.toJson());'''),
        H2('Parsing helpers'),
        P(
          'Each enum has a tolerant `fromString` (`KeyboardKind.fromString'
          '(\'EMAIL\')`) and `enumFromString(MyEnum.values, \'late_evening\')` '
          'works for your own enums.',
        ),
      ],
    );
  }
}

class ExtendablePage extends StatelessWidget {
  const ExtendablePage({super.key});

  @override
  Widget build(BuildContext context) {
    return DocPage(
      title: 'Extendable forms',
      intro:
          'Let users grow the form: repeat a whole section as many times '
          'as they need, or add their own option to a list.',
      children: const [
        H2('Repeater: repeatable sections'),
        P(
          'A `repeater` holds a template in `fields`. Each entry is its own '
          'sub-form with its own validation; the value is a list of maps. '
          'Conditions inside an entry read that entry\'s data.',
        ),
        LivePreview(
          json: {
            'fields': [
              {
                'type': 'repeater',
                'id': 'education',
                'label': 'Education',
                'itemLabel': 'Qualification {index}',
                'addLabel': 'Add qualification',
                'minItems': 1,
                'maxItems': 4,
                'reorderable': true,
                'fields': [
                  {
                    'type': 'text',
                    'id': 'degree',
                    'label': 'Degree',
                    'required': true,
                  },
                  {'type': 'text', 'id': 'school', 'label': 'Institute'},
                  {
                    'type': 'switch',
                    'id': 'ongoing',
                    'label': 'Still studying',
                  },
                  {
                    'type': 'number',
                    'id': 'year',
                    'label': 'Year of passing',
                    'visibleWhen': {'field': 'ongoing', 'operator': 'isFalse'},
                  },
                ],
              },
            ],
          },
        ),
        CodeBlock('''
controller.addEntry('education', data: {'degree': 'B.Sc'});
controller.removeEntry('education', 0);
controller.moveEntry('education', 1, 0);
controller.canAddEntry('education');       // false at maxItems
controller.entriesOf('education');         // List<RepeaterEntry>
controller.getEntries('education');        // List<Map<String, dynamic>>
controller.setValue('education', [ {...}, {...} ]);  // replace all'''),
        Callout(
          'Edit mode works too: pass a list of maps in `initialData` '
          'and one entry is created per map, with the form starting clean.',
        ),
        H2('User-addable options'),
        P(
          'Set `allowCustomOptions` on a dropdown, multiselect, radio group, '
          'checkbox group or chips. Users get an "Add option" control; the '
          'new option is selected and `onOptionAdded` fires so you can '
          'save it.',
        ),
        LivePreview(
          json: {
            'fields': [
              {
                'type': 'chips',
                'id': 'hobbies',
                'label': 'Hobbies',
                'multiple': true,
                'maxItems': 4,
                'allowCustomOptions': true,
                'customOptionLabel': 'Something else',
                'options': ['Reading', 'Cycling', 'Gardening'],
              },
              {
                'type': 'dropdown',
                'id': 'source',
                'label': 'How did you hear about us?',
                'allowCustomOptions': true,
                'options': ['Friend', 'Search', 'Social media'],
              },
            ],
          },
        ),
        CodeBlock('''
DynamicForm(
  controller: controller,
  json: json,
  onOptionAdded: (fieldId, option) => api.saveOption(fieldId, option.label),
);

// From code
controller.addOption('source', OptionItem(label: 'Podcast', value: 'podcast'),
    select: true);
controller.removeOption('source', 'podcast');
controller.customOptions('source');   // options the user added'''),
        H2('Adding fields at runtime'),
        CodeBlock('''
controller.addField(FieldConfig(id: 'coupon', type: FieldType.text,
    label: 'Coupon'), index: 2);
controller.removeField('coupon');'''),
      ],
    );
  }
}

class StylingPage extends StatelessWidget {
  const StylingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DocPage(
      title: 'Styling & customization',
      intro:
          'Each field\'s look comes from four layers, merged in order: '
          'app theme → form `style` → field `style` → `FieldOverrides.style` '
          'in code. The most specific layer wins.',
      children: [
        KeyTable.docs(styleDocs),
        const H2('Label position'),
        const P(
          'By default the label floats inside the border. Use '
          '`labelPosition` to show it above the field (never clipped or '
          'animated, good for long labels) or to hide it. `labelStyle` '
          'changes its look in every mode.',
        ),
        const LivePreview(
          json: {
            'fields': [
              {'type': 'text', 'id': 'floating', 'label': 'Floating (default)'},
              {
                'type': 'text',
                'id': 'above',
                'label': 'Label above the field',
                'style': {
                  'labelPosition': 'above',
                  'labelStyle': {'color': '#00796B', 'fontWeight': 'bold'},
                },
              },
              {
                'type': 'text',
                'id': 'hidden',
                'label': 'Hidden label, shown as the hint',
                'style': {'labelPosition': 'hidden'},
              },
            ],
          },
        ),
        const P(
          'Colours: `#RRGGBB`, `#AARRGGBB` or `0xAARRGGBB`. TextStyle '
          'maps: `fontSize`, `color`, `fontWeight` (`bold`, `w600`…), '
          '`italic`, `letterSpacing`.',
        ),
        const LivePreview(
          json: {
            'style': {'variant': 'rounded', 'borderColor': '#90A4AE'},
            'fields': [
              {
                'type': 'text',
                'id': 'a',
                'label': 'Uses the form style (rounded)',
              },
              {
                'type': 'text',
                'id': 'b',
                'label': 'Overrides it: filled',
                'prefixIcon': 'star',
                'style': {
                  'variant': 'filled',
                  'fillColor': '#FFF8E1',
                  'iconColor': '#FF8F00',
                  'labelStyle': {'color': '#FF8F00', 'fontWeight': 'w600'},
                },
              },
              {
                'type': 'decimal',
                'id': 'c',
                'label': 'Underline, right-aligned',
                'prefixText': '₹ ',
                'style': {'variant': 'underline', 'textAlign': 'end'},
              },
              {
                'type': 'switch',
                'id': 'd',
                'label': 'Custom active colour',
                'style': {'activeColor': '#6A1B9A'},
              },
            ],
          },
        ),
        const H2('Option layouts'),
        const LivePreview(
          json: {
            'fields': [
              {
                'type': 'radioGroup',
                'id': 'h',
                'label': 'horizontal',
                'optionLayout': 'horizontal',
                'options': ['One', 'Two', 'Three'],
              },
              {
                'type': 'checkboxGroup',
                'id': 'g',
                'label': 'grid, 3 columns',
                'optionLayout': 'grid',
                'columns': 3,
                'options': ['A', 'B', 'C', 'D', 'E', 'F'],
              },
            ],
          },
        ),
        const H2('Radio and checkbox styles'),
        const P(
          '`optionStyle` changes how radio groups, checkbox groups and single '
          'checkboxes, radios and switches look: `standard` (list tiles), '
          '`card`, `chip` or `button`. `controlShape` (`square`, `rounded`, '
          '`circle`) and `controlPosition` (`leading`, `trailing`, `none`) '
          'adjust the mark. Colours, radius, spacing and padding come from '
          'the style keys below, so each form or field can match your brand.',
        ),
        const LivePreview(
          json: {
            'fields': [
              {
                'type': 'radioGroup',
                'id': 'plan',
                'label': 'card',
                'optionStyle': 'card',
                'options': [
                  {
                    'label': 'Starter',
                    'value': 'starter',
                    'description': 'One project, community support',
                  },
                  {
                    'label': 'Team',
                    'value': 'team',
                    'description': 'Ten projects, email support',
                  },
                ],
              },
              {
                'type': 'checkboxGroup',
                'id': 'days',
                'label': 'button (grid of up to 3 columns)',
                'optionStyle': 'button',
                'options': ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'],
              },
              {
                'type': 'checkboxGroup',
                'id': 'diet',
                'label': 'chip',
                'optionStyle': 'chip',
                'options': ['Vegetarian', 'Vegan', 'Jain', 'Gluten-free'],
              },
              {
                'type': 'checkboxGroup',
                'id': 'notify',
                'label': 'card, trailing round checkbox',
                'optionStyle': 'card',
                'controlShape': 'circle',
                'controlPosition': 'trailing',
                'options': ['Email', 'SMS', 'WhatsApp'],
              },
              {
                'type': 'checkbox',
                'id': 'terms',
                'label': 'I agree to the terms',
                'helperText': 'A single checkbox as a card',
                'optionStyle': 'card',
              },
            ],
          },
        ),
        const P('The same options with custom colours, radius and spacing:'),
        const LivePreview(
          json: {
            'type': 'radioGroup',
            'id': 'size',
            'label': 'Size',
            'optionStyle': 'button',
            'columns': 4,
            'options': ['S', 'M', 'L', 'XL'],
            'style': {
              'activeColor': '#6A1B9A',
              'selectedColor': '#6A1B9A',
              'selectedBorderColor': '#4A148C',
              'optionBorderColor': '#CE93D8',
              'selectedTextStyle': {'color': '#FFFFFF'},
              'optionRadius': 24,
              'optionSpacing': 'standard',
              'optionPadding': {'vertical': 'standard'},
            },
          },
        ),
        KeyTable.docs([
          for (final d in styleDocs)
            if (const {
              'selectedColor',
              'selectedBorderColor',
              'optionBorderColor',
              'optionRadius',
              'optionSpacing',
              'optionPadding',
              'selectedTextStyle',
              'activeColor',
            }.contains(d.key))
              d,
        ]),
        const H2('Padding and spacing'),
        const P(
          'Every padding, margin and spacing accepts a number or a name: '
          '`none` (0), `compact` (8), `standard` (16), `comfortable` (24), '
          '`spacious` (32). On the form root, `padding` adds space around the '
          'whole form, `fieldSpacing` sets the gap between fields and '
          '`fieldPadding` the default padding inside each field. In code, '
          '`DynamicForm(padding: ...)` or `DynamicFormThemeData(formPadding: '
          '..., fieldPadding: ...)` do the same.',
        ),
        const CodeBlock('''
{
  "padding": "standard",
  "fieldSpacing": "comfortable",
  "fields": [
    {"type": "text", "id": "name", "label": "Name",
     "margin": {"bottom": "compact"}}
  ]
}'''),
        const H2('FieldOverrides: customize in code'),
        const P(
          'For anything JSON cannot express, pass `fieldOverrides` (by '
          'field id) or `typeOverrides` (by `FieldType`) to `DynamicForm`. '
          'Id overrides win over type overrides.',
        ),
        const KeyTable(
          headers: ['Override', 'What it does'],
          rows: [
            ['builder', 'Replace the whole widget.'],
            ['style', 'Highest-precedence style layer.'],
            ['decoration', 'Post-process the generated `InputDecoration`.'],
            ['optionBuilder', 'Render each option yourself.'],
            ['wrapper', 'Wrap the rendered field (card, badge, info icon…).'],
            [
              'label / hint / helperText',
              'Replace text, e.g. with translations.',
            ],
          ],
        ),
        LivePreview(
          json: const {
            'fields': [
              {
                'type': 'segmented',
                'id': 'mood',
                'label': 'Mood',
                'options': ['calm', 'busy', 'stressed'],
              },
              {
                'type': 'textarea',
                'id': 'journal',
                'label': 'Journal',
                'maxLines': 3,
              },
            ],
          },
          fieldOverrides: {
            'mood': FieldOverrides(
              style: const FieldStyleConfig(activeColor: Colors.indigo),
              optionBuilder: (context, option, selected) =>
                  Text(switch (option.value) {
                    'calm' => '😌 Calm',
                    'busy' => '🏃 Busy',
                    _ => '😵 Stressed',
                  }),
            ),
            'journal': FieldOverrides(
              label: 'Today, in a few words',
              wrapper: (context, field, child) => Card(
                color: Theme.of(context).colorScheme.tertiaryContainer,
                child: Padding(padding: const EdgeInsets.all(12), child: child),
              ),
            ),
          },
          dartCode: '''
DynamicForm(
  controller: controller,
  json: json,
  fieldOverrides: {
    'mood': FieldOverrides(
      style: FieldStyleConfig(activeColor: Colors.indigo),
      optionBuilder: (context, option, selected) => Text(emojiFor(option)),
    ),
    'journal': FieldOverrides(
      label: 'Today, in a few words',
      wrapper: (context, field, child) => Card(child: child),
    ),
  },
  typeOverrides: {
    FieldType.email: FieldOverrides(
      decoration: (context, field, d) => d.copyWith(suffixText: '@acme.in'),
    ),
  },
)''',
        ),
        const H2('App-wide theme'),
        const CodeBlock('''
DynamicFormTheme(
  data: DynamicFormThemeData(
    fieldSpacing: 20,
    defaultFieldStyle: FieldStyleConfig(variant: FieldStyleVariant.filled),
    errorBuilder: (context, message) => MyErrorText(message),
    decorationBuilder: (context, field, d) => d.copyWith(isDense: true),
  ),
  child: DynamicForm(...),
)'''),
        const H2('Custom field types'),
        const CodeBlock(
          '''
// Replace a built-in renderer everywhere
FieldFactory.register(FieldType.signature, (context, field, controller) =>
    MySignaturePad(onDone: (png) => controller.setValue(field.id, png)));

// A brand-new type: {"type": "custom", "customType": "map_picker"}
FieldFactory.registerCustom('map_picker', (context, field, controller) =>
    MapPicker(onPick: (latLng) => controller.setValue(field.id, latLng.toJson())));''',
        ),
      ],
    );
  }
}

class WizardPage extends StatelessWidget {
  const WizardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DocPage(
      title: 'Multi-step & edit mode',
      intro:
          'Use `steps` instead of `fields` for a wizard. Each step '
          'validates before moving on; the last step submits.',
      children: const [
        LivePreview(
          json: {
            'steps': [
              {
                'title': 'Trip',
                'fields': [
                  {
                    'type': 'text',
                    'id': 'destination',
                    'label': 'Destination',
                    'required': true,
                  },
                  {'type': 'date', 'id': 'leaveOn', 'label': 'Leaving on'},
                ],
              },
              {
                'title': 'Travellers',
                'fields': [
                  {
                    'type': 'repeater',
                    'id': 'travellers',
                    'itemLabel': 'Traveller {index}',
                    'maxItems': 4,
                    'fields': [
                      {
                        'type': 'text',
                        'id': 'name',
                        'label': 'Name',
                        'required': true,
                      },
                    ],
                  },
                ],
              },
            ],
          },
        ),
        H2('Edit mode'),
        P(
          'Pass an existing record as `initialData` (or a root `"data"` map '
          'in the JSON). The form starts clean, so the discard dialog only '
          'appears after a real edit, and `reset()` returns to the record.',
        ),
        LivePreview(
          json: {
            'fields': [
              {'type': 'text', 'id': 'city', 'label': 'City'},
              {'type': 'rating', 'id': 'score', 'label': 'Score'},
              {
                'type': 'repeater',
                'id': 'stops',
                'itemLabel': 'Stop {index}',
                'fields': [
                  {'type': 'text', 'id': 'place', 'label': 'Place'},
                ],
              },
            ],
          },
          initialData: {
            'city': 'Udaipur',
            'score': 4,
            'stops': [
              {'place': 'City Palace'},
              {'place': 'Lake Pichola'},
            ],
          },
        ),
        CodeBlock('''
DynamicForm(controller: controller, json: json, initialData: record);
controller.setFormData(record, asInitial: true);  // load later
controller.isDirty;      // unsaved changes?
controller.markClean();  // after saving a draft'''),
      ],
    );
  }
}

class ControllerPage extends StatelessWidget {
  const ControllerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const DocPage(
      title: 'Controller API',
      intro:
          '`DynamicFormController` works without any widget, so it plugs '
          'into Provider, Riverpod, Bloc or GetX.',
      children: [
        KeyTable(
          headers: ['Member', 'Purpose'],
          rows: [
            [
              'getValue / setValue',
              'Read or write one field (enums are stored by name).',
            ],
            [
              'getString / getInt / getDouble / getBool / getList',
              'Typed reads.',
            ],
            ['getEnum / getEnumList', 'Decode enum-backed values.'],
            ['getFormData({includeHidden})', 'All visible data.'],
            ['setFormData(data, {asInitial})', 'Bulk write / load a record.'],
            [
              'validate / validateField / getErrors / clearErrors',
              'Validation.',
            ],
            ['submit()', 'Validate, then `onSubmit` with data (or `onError`).'],
            ['reset / clearField', 'Back to initial values / empty one field.'],
            ['isDirty / dirty / markClean', 'Unsaved-change tracking.'],
            ['show/hide/enable/disableField, setRequired', 'Runtime state.'],
            [
              'setOptions / addOption / removeOption / customOptions',
              'Options.',
            ],
            [
              'addEntry / removeEntry / moveEntry / entriesOf / getEntries',
              'Repeaters.',
            ],
            ['addField / removeField', 'Change the structure at runtime.'],
            ['focusField / unfocus', 'Focus.'],
            ['listen(id, fn)', 'Watch one field; returns a cancel function.'],
            ['onChanged / onSubmit / onError / onValidation', 'Callbacks.'],
            [
              'onOptionAdded / onFieldAdded / onFieldRemoved',
              'Structure callbacks.',
            ],
            ['fieldOverrides / typeOverrides', 'Code-level customization.'],
          ],
        ),
        H2('Async and dependent options'),
        CodeBlock('''
final controller = DynamicFormController(
  optionsLoader: (fieldId, data) async {
    if (fieldId == 'district') {
      final rows = await api.districts(state: data['state']);
      return [for (final r in rows) OptionItem(label: r.name, value: r.code)];
    }
    return const [];
  },
);
// JSON: {"type": "dropdown", "id": "district", "dependsOn": ["state"]}'''),
        H2('Localization'),
        P(
          'Built-in messages: `en`, `hi`, `ar`, `es`, `fr`, `de` — '
          '`DynamicFormController(locale: \'hi\')`. Override or add any '
          'string with `FormLocalizations.addTranslations(\'en\', {...})`.',
        ),
      ],
    );
  }
}

class PlaygroundPage extends StatefulWidget {
  const PlaygroundPage({super.key});

  @override
  State<PlaygroundPage> createState() => _PlaygroundPageState();
}

class _PlaygroundPageState extends State<PlaygroundPage> {
  static const _starter = {
    'style': {'variant': 'outlined'},
    'fields': [
      {'type': 'text', 'id': 'title', 'label': 'Title', 'required': true},
      {
        'type': 'dropdown',
        'id': 'cuisine',
        'label': 'Cuisine',
        'enum': 'Cuisine',
      },
      {
        'type': 'repeater',
        'id': 'steps',
        'itemLabel': 'Step {index}',
        'fields': [
          {
            'type': 'textarea',
            'id': 'text',
            'label': 'Instruction',
            'maxLines': 2,
          },
        ],
      },
    ],
  };

  late final TextEditingController _source = TextEditingController(
    text: prettyJson(_starter),
  );
  Map<String, dynamic> _json = _starter;
  String? _error;
  int _revision = 0;

  void _apply() {
    try {
      final decoded = jsonDecode(_source.text);
      FormParser.parse(decoded as Object);
      setState(() {
        _json = Map<String, dynamic>.from(decoded as Map);
        _error = null;
        _revision++;
      });
    } on Object catch (e) {
      setState(() => _error = '$e');
    }
  }

  @override
  void dispose() {
    _source.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editor = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _source,
          maxLines: 24,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
          decoration: InputDecoration(errorText: _error, errorMaxLines: 4),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.icon(
            icon: const Icon(Icons.play_arrow),
            label: const Text('Render'),
            onPressed: _apply,
          ),
        ),
      ],
    );
    final preview = LivePreview(key: ValueKey(_revision), json: _json);
    return DocPage(
      title: 'Playground',
      intro:
          'Paste or edit any form JSON and render it. Registered enums: '
          '${guideEnumNames.map((n) => '`$n`').join(', ')}.',
      children: [
        LayoutBuilder(
          builder: (context, c) => c.maxWidth > 760
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: editor),
                    const SizedBox(width: 16),
                    Expanded(child: preview),
                  ],
                )
              : Column(children: [editor, const SizedBox(height: 16), preview]),
        ),
      ],
    );
  }
}
