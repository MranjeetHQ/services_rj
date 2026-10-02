import 'package:flutter/material.dart';
import 'package:services_rj/services_rj.dart';

import '../widgets/demo_widgets.dart';
import 'lab_common.dart';

/// Wizard used with `MultiStepForm` directly. Step two holds a repeater
/// whose entries contain a nested repeater and a group.
const Map<String, dynamic> multiStepLabJson = {
  'id': 'trip_wizard',
  'style': {'variant': 'filled', 'borderRadius': 12},
  'steps': [
    {
      'title': 'Trip',
      'subtitle': 'Where and when',
      'fields': [
        {
          'type': 'text',
          'id': 'destination',
          'label': 'Destination',
          'prefixIcon': 'location',
          'required': true,
        },
        {
          'type': 'date',
          'id': 'departure',
          'label': 'Departure date',
          'required': true,
        },
      ],
    },
    {
      'title': 'Travellers',
      'subtitle': 'One entry per person',
      'fields': [
        {
          'type': 'repeater',
          'id': 'travellers',
          'label': 'Travellers',
          'itemLabel': 'Traveller {index}',
          'addLabel': 'Add traveller',
          'initialItems': 2,
          'minItems': 1,
          'maxItems': 4,
          'reorderable': true,
          'fields': [
            {
              'type': 'text',
              'id': 'travellerName',
              'label': 'Name',
              'required': true,
            },
            {
              'type': 'repeater',
              'id': 'bags',
              'label': 'Bags',
              'itemLabel': 'Bag {index}',
              'addLabel': 'Add bag',
              'initialItems': 1,
              'maxItems': 2,
              'fields': [
                {
                  'type': 'decimal',
                  'id': 'weight',
                  'label': 'Weight (kg)',
                  'validators': [
                    {'type': 'max', 'value': 32, 'message': 'Over 32 kg'},
                  ],
                },
              ],
            },
          ],
        },
      ],
    },
    {
      'title': 'Confirm',
      'subtitle': 'Last check',
      'fields': [
        {
          'type': 'checkbox',
          'id': 'terms',
          'label': 'I accept the fare rules',
          'validators': ['required'],
        },
      ],
    },
  ],
};

/// Extendable form: nested repeaters, groups, user-added options.
const Map<String, dynamic> extendableLabForm = {
  'id': 'extendable_lab',
  'fields': [
    {'type': 'text', 'id': 'household', 'label': 'Household name'},
    {
      'type': 'chips',
      'id': 'interests',
      'label': 'Interests',
      'options': ['Hiking', 'Chess'],
      'allowCustomOptions': true,
      'customOptionLabel': 'Add your own',
      'multiple': true,
    },
    {
      'type': 'repeater',
      'id': 'contacts',
      'label': 'Contacts',
      'itemLabel': 'Contact {index}',
      'addLabel': 'Add contact',
      'initialItems': 2,
      'minItems': 1,
      'maxItems': 4,
      'reorderable': true,
      'fields': [
        {
          'type': 'text',
          'id': 'contactName',
          'label': 'Name',
          'required': true,
        },
        {
          'type': 'repeater',
          'id': 'phones',
          'label': 'Phone numbers',
          'itemLabel': 'Number {index}',
          'minItems': 1,
          'maxItems': 3,
          'fields': [
            {
              'type': 'phone',
              'id': 'number',
              'label': 'Number',
              'validators': ['required', 'phone'],
            },
          ],
        },
        {
          'type': 'group',
          'id': 'address',
          'label': 'Address',
          'style': {'containerColor': '#F1F8E9', 'containerRadius': 12},
          'fields': [
            {'type': 'text', 'id': 'street', 'label': 'Street'},
            {'type': 'text', 'id': 'town', 'label': 'Town'},
          ],
        },
      ],
    },
  ],
};

/// A saved household for edit mode.
const Map<String, dynamic> labRecordA = {
  'household': 'The Mehtas',
  'interests': ['Hiking'],
  'contacts': [
    {
      'contactName': 'Anil Mehta',
      'phones': [
        {'number': '+91 98765 11111'},
        {'number': '+91 98765 22222'},
      ],
      'street': '4 Lake Road',
      'town': 'Udaipur',
    },
    {
      'contactName': 'Rina Mehta',
      'phones': [
        {'number': '+91 98765 33333'},
      ],
    },
  ],
};

/// A second saved household, to switch the edit target at runtime.
const Map<String, dynamic> labRecordB = {
  'household': 'Okafor family',
  'interests': ['Chess'],
  'contacts': [
    {
      'contactName': 'Ngozi Okafor',
      'phones': [
        {'number': '+234 801 234 5678'},
      ],
    },
  ],
};

/// A short form that scrolls on its own (shrinkWrap false + physics).
const Map<String, dynamic> scrollLabForm = {
  'id': 'scroll_lab',
  'fields': [
    {'type': 'text', 'id': 's1', 'label': 'First line'},
    {'type': 'text', 'id': 's2', 'label': 'Second line'},
    {'type': 'text', 'id': 's3', 'label': 'Third line'},
    {'type': 'text', 'id': 's4', 'label': 'Fourth line'},
    {'type': 'text', 'id': 's5', 'label': 'Fifth line'},
    {'type': 'text', 'id': 's6', 'label': 'Sixth line'},
  ],
};

/// Page for the multi-step and extendable forms lab.
class MultiStepLabPage extends StatefulWidget {
  /// Creates the page.
  const MultiStepLabPage({super.key});

  @override
  State<MultiStepLabPage> createState() => _MultiStepLabPageState();
}

class _MultiStepLabPageState extends State<MultiStepLabPage> {
  final _log = EventLog();
  final _wizard = DynamicFormController();
  final _extendable = DynamicFormController();
  final _scroll = DynamicFormController();
  late final FormConfig _wizardConfig = FormParser.parse(multiStepLabJson);
  Map<String, dynamic>? _record;

  @override
  void initState() {
    super.initState();
    // MultiStepForm does not parse JSON itself: attach the config first.
    _wizard
      ..attach(_wizardConfig)
      ..onSubmit = (d) => _log.add('wizard submitted: ${labCompact(d)}');
  }

  @override
  void dispose() {
    _wizard.dispose();
    _extendable.dispose();
    _scroll.dispose();
    _log.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => DemoPage(
    title: 'Multi-step and extendable forms',
    intro:
        'MultiStepForm used directly, repeaters with limits, nesting and '
        'reordering, edit mode, and the DynamicForm layout hooks.',
    children: [
      DemoSection(
        title: 'MultiStepForm with a FormConfig',
        subtitle:
            'Each step validates before Next. The last step calls '
            'controller.submit().',
        child: MultiStepForm(
          controller: _wizard,
          config: _wizardConfig,
          onSubmit: (d) => _log.add('MultiStepForm.onSubmit: ${labCompact(d)}'),
        ),
      ),
      DemoSection(
        title: 'Repeaters, nesting and edit mode',
        subtitle:
            'initialItems 2, min 1, max 4, reorderable, with a nested '
            'repeater and a group per entry. Load a record to edit it: the '
            'form stays clean and reset() restores it.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              children: [
                OutlinedButton(
                  onPressed: () => setState(() => _record = {...labRecordA}),
                  child: const Text('Edit household A'),
                ),
                OutlinedButton(
                  onPressed: () => setState(() => _record = {...labRecordB}),
                  child: const Text('Edit household B'),
                ),
                OutlinedButton(
                  onPressed: () => _extendable.reset(),
                  child: const Text('reset()'),
                ),
              ],
            ),
            DynamicForm(
              controller: _extendable,
              json: extendableLabForm,
              initialData: _record,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              showSubmitButton: true,
              submitLabel: 'Save household',
              header: ValueListenableBuilder<bool>(
                valueListenable: _extendable.dirty,
                builder: (context, dirty, _) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'header widget: form is ${dirty ? 'dirty' : 'clean'}',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ),
              ),
              footer: const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text('footer widget'),
              ),
              onChanged: (d) => _log.add('onChanged: ${d.keys.join(', ')}'),
              onOptionAdded: (id, option) =>
                  _log.add('onOptionAdded: $id += ${option.label}'),
              onSubmit: (d) => _log.add('saved: ${labCompact(d)}'),
            ),
          ],
        ),
      ),
      DemoSection(
        title: 'Self-scrolling form',
        subtitle:
            'shrinkWrap false with BouncingScrollPhysics inside a fixed box.',
        child: SizedBox(
          height: 220,
          child: DynamicForm(
            controller: _scroll,
            json: scrollLabForm,
            physics: const BouncingScrollPhysics(),
          ),
        ),
      ),
      DemoSection(
        title: 'Log',
        child: EventLogView(log: _log),
      ),
    ],
  );
}
