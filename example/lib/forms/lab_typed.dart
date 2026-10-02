import 'package:flutter/material.dart';
import 'package:services_rj/services_rj.dart';

import '../widgets/demo_widgets.dart';
import 'lab_common.dart';
import 'lab_validators.dart';

/// Builds the sign-up form from Dart objects only (no JSON literals).
///
/// With [phoneRequired] the phone field is replaced by a `copyWith` copy.
FormConfig buildTypedConfig({bool phoneRequired = false}) {
  final phone = FieldConfig(
    id: 'phone',
    type: FieldType.phone,
    label: 'Phone',
    prefixText: '+91 ',
    keyboardType: KeyboardKind.phone,
    validators: [ValidatorConfig.of(ValidatorType.phone)],
  );
  return FormConfig(
    id: 'typed_signup',
    title: 'Typed sign-up',
    description: 'Built from FormConfig and FieldConfig objects',
    style: const FieldStyleConfig(
      variant: FieldStyleVariant.rounded,
      borderRadius: 18,
    ),
    fields: [
      FieldConfig(
        id: 'fullName',
        type: FieldType.text,
        label: 'Full name',
        prefixIcon: 'person',
        textCase: TextCase.words,
        textInputAction: InputActionKind.next,
        validators: [ValidatorConfig.required(message: 'We need a name')],
      ),
      FieldConfig(
        id: 'email',
        type: FieldType.email,
        label: 'Email',
        keyboardType: KeyboardKind.email,
        validators: [
          ValidatorConfig.required(),
          ValidatorConfig.of(ValidatorType.email, message: 'Check that email'),
        ],
      ),
      if (phoneRequired)
        phone.copyWith(label: 'Phone (required via copyWith)', required: true)
      else
        phone,
      FieldConfig(
        id: 'handle',
        type: FieldType.text,
        label: 'Handle (custom validator)',
        validators: [ValidatorConfig.custom('noSpaces')],
      ),
      FieldConfig(
        id: 'plan',
        type: FieldType.radioGroup,
        label: 'Plan (from FormEnumRegistry)',
        enumName: 'LabPlan',
        optionLayout: OptionLayout.horizontal,
        initialValue: 'free',
      ),
      FieldConfig(
        id: 'topics',
        type: FieldType.chips,
        label: 'Topics (enum with a disabled value)',
        enumName: 'LabTopic',
        extra: const {'multiple': true},
      ),
      const FieldConfig(
        id: 'level',
        type: FieldType.radioGroup,
        label: 'Experience (OptionItem features)',
        options: labLevelOptions,
      ),
      const FieldConfig(
        id: 'newsletter',
        type: FieldType.switchField,
        label: 'Subscribe to the newsletter',
      ),
      FieldConfig(
        id: 'newsletterEmail',
        type: FieldType.email,
        label: 'Newsletter address',
        visibleWhen: Condition.when('newsletter', ConditionOperator.isTrue),
        validators: [ValidatorConfig.required()],
      ),
      const FieldConfig(
        id: 'guests',
        type: FieldType.repeater,
        label: 'Guests',
        itemLabel: 'Guest {index}',
        addLabel: 'Add a guest',
        minItems: 0,
        maxItems: 3,
        initialItems: 1,
        fields: [
          FieldConfig(id: 'guestName', type: FieldType.text, label: 'Name'),
        ],
      ),
    ],
  );
}

/// Options that show off every [OptionItem] property.
const List<OptionItem> labLevelOptions = [
  OptionItem(
    label: 'Beginner',
    value: 'beginner',
    icon: 'school',
    description: 'First month with Flutter',
  ),
  OptionItem(
    label: 'Intermediate',
    value: 'intermediate',
    icon: 'work',
    description: 'Ships features alone',
    extra: {'years': 2},
  ),
  OptionItem(
    label: 'Expert (waitlist)',
    value: 'expert',
    icon: 'star',
    enabled: false,
    description: 'Disabled option',
  ),
];

/// Fake server data for [labAsyncForm].
const Map<String, List<(String, String)>> labAsyncCities = {
  'IN': [('Chennai', 'chennai'), ('Surat', 'surat')],
  'US': [('Boston', 'boston'), ('Seattle', 'seattle')],
};

/// Fields whose options come from `optionsLoader`.
const Map<String, dynamic> labAsyncForm = {
  'id': 'async_lab',
  'fields': [
    {
      'type': 'dropdown',
      'id': 'country',
      'label': 'Country (optionsUrl)',
      'optionsUrl': 'https://api.example.invalid/countries',
    },
    {
      'type': 'dropdown',
      'id': 'city',
      'label': 'City (dependsOn country)',
      'optionsUrl': 'https://api.example.invalid/cities',
      'dependsOn': ['country'],
    },
    {
      'type': 'radioGroup',
      'id': 'slot',
      'label': 'Time slot (no options, no url: loader still runs)',
      'optionLayout': 'wrap',
    },
  ],
};

/// Page for the typed config and async options lab.
class TypedLabPage extends StatefulWidget {
  /// Creates the page.
  const TypedLabPage({super.key});

  @override
  State<TypedLabPage> createState() => _TypedLabPageState();
}

class _TypedLabPageState extends State<TypedLabPage> {
  final _log = EventLog();
  final _typed = DynamicFormController(customValidators: labCustomValidators);
  late final _async = DynamicFormController(optionsLoader: _load);
  bool _phoneRequired = false;
  late FormConfig _config = buildTypedConfig();
  late Map<String, dynamic> _json = _config.toJson();
  bool _tempRegistered = false;

  @override
  void initState() {
    super.initState();
    registerLabEnums();
  }

  @override
  void dispose() {
    _typed.dispose();
    _async.dispose();
    _log.dispose();
    super.dispose();
  }

  Future<List<OptionItem>> _load(String id, Map<String, dynamic> data) async {
    final url = _async.state(id).config.optionsUrl;
    _log.add('optionsLoader(id: $id, url: $url, country: ${data['country']})');
    await Future<void>.delayed(const Duration(milliseconds: 400));
    final cities =
        labAsyncCities[data['country']] ?? const <(String, String)>[];
    return switch (id) {
      'country' => const [
        OptionItem(label: 'India', value: 'IN', extra: {'dial': '+91'}),
        OptionItem(label: 'United States', value: 'US', extra: {'dial': '+1'}),
      ],
      'city' => [
        for (final (label, value) in cities)
          OptionItem(label: label, value: value),
      ],
      'slot' => const [
        OptionItem(label: '9:00', value: '09'),
        OptionItem(label: '11:30', value: '1130'),
        OptionItem(label: '16:00', value: '16'),
      ],
      _ => const [],
    };
  }

  void _setPhoneRequired(bool v) => setState(() {
    _phoneRequired = v;
    _config = buildTypedConfig(phoneRequired: v);
    _json = _config.toJson();
  });

  @override
  Widget build(BuildContext context) {
    final roundTrip =
        labCompact(FormConfig.fromJson(_json).toJson()) == labCompact(_json);
    final planOptions = FormEnumRegistry.options('LabPlan') ?? const [];
    return DemoPage(
      title: 'Typed config and async options',
      intro:
          'A form built from FormConfig / FieldConfig objects, enum-backed '
          'options, OptionItem features and options loaded by a fake async '
          'loader.',
      children: [
        DemoSection(
          title: 'FormConfig built in Dart',
          subtitle:
              'DynamicForm takes JSON, so the typed config is passed as '
              'config.toJson(). copyWith creates the changed field.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('phone.copyWith(required: true)'),
                value: _phoneRequired,
                onChanged: _setPhoneRequired,
              ),
              DynamicForm(
                controller: _typed,
                json: _json,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                showSubmitButton: true,
                onSubmit: (d) => _log.add('typed onSubmit: ${labCompact(d)}'),
                onError: (e) => _log.add('typed onError: ${e.keys.join(', ')}'),
              ),
              const SizedBox(height: 8),
              LabActions(
                actions: {
                  'getEnum(plan)': () => _log.add(
                    'plan -> ${_typed.getEnum('plan', LabPlan.values)}',
                  ),
                  'getEnumList(topics)': () => _log.add(
                    'topics -> ${_typed.getEnumList('topics', LabTopic.values)}',
                  ),
                  'setValue(plan, LabPlan.team)': () =>
                      _typed.setValue('plan', LabPlan.team),
                  'Parse bad JSON': () {
                    try {
                      FormParser.parse('[1, 2]');
                    } on FormatException catch (e) {
                      _log.add('FormatException: ${e.message}');
                    }
                  },
                },
              ),
              const SizedBox(height: 8),
              Text('toJson -> fromJson -> toJson identical: $roundTrip'),
              ExpansionTile(
                title: const Text('Generated JSON'),
                children: [CodeSnippet(labPretty(_json))],
              ),
            ],
          ),
        ),
        DemoSection(
          title: 'FormEnumRegistry',
          subtitle: 'Label, description, icon and enabled callbacks.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Registered: ${FormEnumRegistry.names.join(', ')}'),
              const SizedBox(height: 8),
              for (final o in planOptions)
                ListTile(
                  dense: true,
                  leading: Icon(FieldUtils.icon(o.icon) ?? Icons.circle),
                  title: Text('${o.label}  (${o.value})'),
                  subtitle: Text(o.description ?? ''),
                ),
              Text(
                "decode(LabPlan.values, 'pro') = "
                '${FormEnumRegistry.decode(LabPlan.values, 'pro')}',
              ),
              Text(
                "humanize('inPerson') = ${FormEnumRegistry.humanize('inPerson')}",
              ),
              const SizedBox(height: 8),
              LabActions(
                actions: {
                  _tempRegistered
                      ? 'unregister(LabTemp)'
                      : 'register(LabTemp)': () => setState(() {
                    if (_tempRegistered) {
                      FormEnumRegistry.unregister('LabTemp');
                    } else {
                      FormEnumRegistry.register('LabTemp', LabPlan.values);
                    }
                    _tempRegistered = FormEnumRegistry.contains('LabTemp');
                  }),
                },
              ),
            ],
          ),
        ),
        DemoSection(
          title: 'OptionItem',
          subtitle:
              'fromJson accepts maps, bare scalars and enums; fromEnum '
              'builds a list; toJson round-trips.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "fromJson('Delhi') -> ${labCompact(OptionItem.fromJson('Delhi').toJson())}",
              ),
              Text(
                'fromJson(LabPlan.pro) -> '
                '${labCompact(OptionItem.fromJson(LabPlan.pro).toJson())}',
              ),
              Text(
                'fromJson(map) -> '
                '${labCompact(OptionItem.fromJson({
                  'label': 'Custom',
                  'value': 7,
                  'enabled': false,
                  'isCustom': true,
                  'extra': {'k': 1},
                }).toJson())}',
              ),
              Text(
                'fromEnum(LabTopic) labels: '
                '${OptionItem.fromEnum(LabTopic.values).map((o) => o.label).join(', ')}',
              ),
              Text(
                'equality (label + value): '
                "${const OptionItem(label: 'A', value: 1) == const OptionItem(label: 'A', value: 1, enabled: false)}",
              ),
            ],
          ),
        ),
        DemoSection(
          title: 'Async options',
          subtitle:
              'optionsUrl fields and dependsOn go through '
              'DynamicFormController(optionsLoader: ...).',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DynamicForm(
                controller: _async,
                json: labAsyncForm,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
              ),
              LabActions(
                actions: {
                  'Reload country options': () => _async.addField(
                    const FieldConfig(
                      id: 'country',
                      type: FieldType.dropdown,
                      label: 'Country (optionsUrl)',
                      optionsUrl: 'https://api.example.invalid/countries',
                    ),
                    index: 0,
                  ),
                },
              ),
              const SizedBox(height: 8),
              EventLogView(log: _log, emptyText: 'Loader calls and results.'),
            ],
          ),
        ),
      ],
    );
  }
}
