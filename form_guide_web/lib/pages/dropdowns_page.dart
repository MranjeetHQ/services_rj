import 'package:flutter/material.dart';

import '../catalog/reference_catalog.dart';
import '../guide_enums.dart';
import '../widgets/doc_widgets.dart';

const _cities = [
  'Ahmedabad',
  'Bengaluru',
  'Bhopal',
  'Chandigarh',
  'Chennai',
  'Coimbatore',
  'Delhi',
  'Hyderabad',
  'Indore',
  'Jaipur',
  'Kochi',
  'Kolkata',
  'Lucknow',
  'Mumbai',
  'Nagpur',
  'Pune',
  'Surat',
  'Vadodara',
];

class DropdownsPage extends StatelessWidget {
  const DropdownsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DocPage(
      title: 'Dropdowns & search',
      intro:
          '`searchableDropdown` opens a picker with a search box. Options can '
          'be a local list, an API list loaded once, or an API searched as '
          'the user types, and `"multiple": true` picks several values. No '
          'extra package is needed.',
      children: [
        const H2('Do you need a searchable dropdown?'),
        const P(
          'Pick the lightest field that fits. Search helps when the list is '
          'long or the user already knows the answer; for a handful of '
          'choices, showing them all is faster.',
        ),
        const KeyTable(
          headers: ['Situation', 'Use'],
          rows: [
            [
              '2–5 choices',
              '`radioGroup` (try `optionStyle: card`), `segmented` or `chips`. '
                  'Every option is visible, one tap to choose.',
            ],
            ['5–10 choices, one value', '`dropdown`.'],
            [
              'More than ~10 choices, or users type what they want',
              '`searchableDropdown` with `options`.',
            ],
            [
              'The list comes from an API but is small (< ~500)',
              '`searchableDropdown` + `optionsLoader` on the controller: load '
                  'once, search locally.',
            ],
            [
              'The list is large or filtered on the server',
              '`searchableDropdown` + `searchSource`: the API is called as '
                  'the user types.',
            ],
            [
              'Several values',
              'Up to ~8: `checkboxGroup` or `chips` with `multiple`. More: '
                  '`searchableDropdown` with `multiple`.',
            ],
            [
              'Free text with suggestions',
              '`autocomplete`: the typed text is kept even when nothing '
                  'matches.',
            ],
          ],
        ),
        const H2('1. Local list'),
        const P(
          'Options are filtered as the user types (label, description and '
          'value are searched). Tap the field to open the bottom sheet.',
        ),
        const LivePreview(
          json: {
            'type': 'searchableDropdown',
            'id': 'city',
            'label': 'City',
            'hint': 'Choose a city',
            'searchHint': 'Search 18 cities',
            'prefixIcon': 'location',
            'required': true,
            'options': _cities,
          },
        ),
        const H2('2. Multiple selection'),
        const P(
          '`multiple` makes the value a List. The picker shows checkboxes and a '
          'Done button; dismissing it keeps the old selection. '
          '`showSelectAll` adds Select all / Clear, `maxItems` caps the '
          'selection and `selectedDisplay` picks chips, text or a count.',
        ),
        const LivePreview(
          json: {
            'type': 'searchableDropdown',
            'id': 'preferredCities',
            'label': 'Preferred cities',
            'multiple': true,
            'showSelectAll': true,
            'maxItems': 5,
            'helperText': 'Up to 5',
            'selectedDisplay': 'chips',
            'options': _cities,
          },
        ),
        const P(
          'A plain `dropdown` with `"multiple": true` gives the same picker '
          'without the search box, which suits short lists.',
        ),
        const LivePreview(
          json: {
            'type': 'dropdown',
            'id': 'shifts',
            'label': 'Shifts',
            'multiple': true,
            'selectedDisplay': 'text',
            'options': ['Morning', 'Afternoon', 'Night'],
          },
        ),
        const H2('3. API: load the list once'),
        const P(
          'For a list that fits in memory, give the controller an '
          '`optionsLoader`. It runs once per field (and again when a field '
          'in `dependsOn` changes); the picker then searches locally.',
        ),
        const CodeBlock('''
final controller = DynamicFormController(
  optionsLoader: (fieldId, formData) async {
    if (fieldId != 'department') return const [];
    final res = await ApiClient.instance.request(
      ApiRequest(endpoint: '/departments', method: ApiMethod.get),
    );
    return [
      for (final d in res.data as List)
        OptionItem(label: d['name'] as String, value: d['id']),
    ];
  },
);

// JSON: no "options"; they come from the loader.
{"type": "searchableDropdown", "id": "department", "label": "Department"}'''),
        const H2('4. API: search as you type'),
        const P(
          'For large lists, register a search function and name it in '
          '`searchSource`. It receives the typed text and the current form '
          'data. Calls are debounced (`debounceMs`), wait for '
          '`minSearchLength` characters, and stale responses are dropped. If '
          'it throws, the picker shows "Could not load results" with Retry.',
        ),
        const CodeBlock('''
// Once, for example in main():
FormSearchSources.register('cities', (query, formData) async {
  final res = await ApiClient.instance.request(
    ApiRequest(
      endpoint: '/cities',
      method: ApiMethod.get,
      queryParameters: {'q': query},
    ),
  );
  return [
    for (final c in res.data as List)
      OptionItem(
        label: c['name'] as String,
        value: c['id'],
        description: c['state'] as String?,
      ),
  ];
});

// Or only for one form:
DynamicFormController(searchSources: {'cities': mySearch});'''),
        const P(
          'Live example (the guide answers from local data after 400 ms, like '
          'a real API). Type at least 2 letters.',
        ),
        const LivePreview(
          json: {
            'type': 'searchableDropdown',
            'id': 'remoteCity',
            'label': 'City (API)',
            'searchSource': 'guideCities',
            'minSearchLength': 2,
            'debounceMs': 300,
            'searchHint': 'Type a city name',
          },
        ),
        const Callout(
          'Prefilling an API-backed field? Also put the saved item in '
          '`options` ({"label": "Pune", "value": 42}) so the closed field can '
          'show its label before the user searches. Picked results are '
          'remembered automatically.',
        ),
        const H2('5. Depends on another field'),
        P(
          'The search function gets `formData`, so it can filter by another '
          'field. `dependsOn` clears the city when the state changes. States: '
          '${guideStates.join(', ')}.',
        ),
        LivePreview(
          json: {
            'fields': [
              {
                'type': 'dropdown',
                'id': 'state',
                'label': 'State',
                'options': guideStates,
              },
              const {
                'type': 'searchableDropdown',
                'id': 'stateCity',
                'label': 'City',
                'searchSource': 'guideCitiesByState',
                'dependsOn': ['state'],
                'enabledWhen': {'field': 'state', 'operator': 'isNotEmpty'},
                'helperText': 'Pick a state first',
              },
            ],
          },
        ),
        const H2('6. Picker styles and custom options'),
        const P(
          '`pickerStyle: dialog` suits tablets and the web; `fullScreen` suits '
          'very long lists on phones. `allowCustomOptions` offers "Add …" '
          'when nothing matches.',
        ),
        const LivePreview(
          json: {
            'fields': [
              {
                'type': 'searchableDropdown',
                'id': 'dialogCity',
                'label': 'Dialog picker',
                'pickerStyle': 'dialog',
                'options': _cities,
              },
              {
                'type': 'searchableDropdown',
                'id': 'skills',
                'label': 'Skills (full screen, add your own)',
                'pickerStyle': 'fullScreen',
                'multiple': true,
                'allowCustomOptions': true,
                'selectedDisplay': 'count',
                'options': ['Dart', 'Flutter', 'Kotlin', 'Swift', 'SQL'],
              },
            ],
          },
        ),
        const H2('Styling'),
        const P(
          'The closed field uses the normal field style (`variant`, '
          '`fillColor`, `borderRadius`, `labelPosition`…). Picker rows use '
          '`activeColor`, `selectedColor`, `selectedTextStyle`, '
          '`optionRadius` and `optionPadding`.',
        ),
        const LivePreview(
          json: {
            'type': 'searchableDropdown',
            'id': 'styledCity',
            'label': 'Styled',
            'options': _cities,
            'style': {
              'variant': 'rounded',
              'fillColor': '#F1F8F7',
              'labelPosition': 'above',
              'activeColor': '#00796B',
              'selectedColor': '#D7EFEC',
              'optionRadius': 20,
            },
          },
        ),
        const H2('Every key'),
        const P(
          'Keys specific to the searchable dropdown. The common keys '
          '(`label`, `hint`, `required`, `validators`, `visibleWhen`, '
          '`style`…) work as on every field.',
        ),
        KeyTable(
          headers: const ['Key', 'Default', 'What it does', 'Use it for'],
          rows: [
            for (final (key, def, what, useFor) in searchableDropdownKeys)
              [key, def, what, useFor],
          ],
        ),
        const H2('In Dart'),
        const CodeBlock('''
FieldConfig(
  id: 'cities',
  type: FieldType.searchableDropdown,
  label: 'Cities',
  maxItems: 3,
  options: [OptionItem(label: 'Pune', value: 'pnq')],
  extra: {
    'multiple': true,
    'searchSource': 'cities',
    'pickerStyle': PickerStyle.dialog.name,
    'selectedDisplay': SelectedDisplay.chips.name,
  },
)'''),
      ],
    );
  }
}
