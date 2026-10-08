# Dynamic forms

`DynamicForm` renders a complete form from JSON (a `Map` or a JSON string). The interactive guide in [`form_guide_web/`](../form_guide_web/) documents every field type with live previews, and its Element builder lets you edit any element's JSON and see it render. This page is the short reference.

## Quick start

A complete app: paste it into `lib/main.dart` and run. `DynamicForm` is a scrolling list of fields, so put it in a `Scaffold` body (it needs a `Material` ancestor and a bounded height), not directly under `MaterialApp`. The same file is [`example/lib/quick_start.dart`](../example/lib/quick_start.dart).

```dart
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
        ).showSnackBar(SnackBar(content: Text('Saved: $data'))),
      ),
    );
  }
}
```

Every `DynamicForm` option, as used inside a `build` method:

```dart
DynamicForm(
  controller: controller,
  json: formJson,
  initialData: existingRecord,          // optional: edit mode
  showSubmitButton: true,
  onSubmit: (data) => save(data),
  onOptionAdded: (fieldId, option) => saveOption(fieldId, option),
  fieldOverrides: {...},                // per field id
  typeOverrides: {...},                 // per FieldType
  padding: const EdgeInsets.all(16),    // or "padding": "standard" in JSON
);
```

## Form JSON

| Key | Meaning |
|---|---|
| `fields` | Fields of a single-page form |
| `steps` | Wizard steps: `{title, subtitle, fields}`. Each step validates before moving on |
| `style` | Style for every field (fields can override) |
| `confirmDiscard`, `discardTitle`, `discardMessage` | Ask before leaving with unsaved changes |
| `data` / `initialData` | Record to prefill |
| `padding` | Space around the whole form: a number, a spacing name or a Map |
| `fieldSpacing` | Gap between fields (default 16) |
| `fieldPadding` | Default inner padding of every field |

**Spacing names.** Every padding, margin and spacing (`padding`, `margin`, `contentPadding`, `fieldSpacing`, `optionSpacing`, `optionPadding`, and the values inside a `{"horizontal": ..., "vertical": ...}` map) takes a number or a name: `none` (0), `compact` (8), `standard` (16), `comfortable` (24), `spacious` (32). `"padding": "standard"` gives the usual 16-pixel page margin. In code: `DynamicForm(padding: ...)`, or `DynamicFormThemeData(formPadding: ..., fieldPadding: ..., fieldSpacing: ...)` for every form.

## Required and optional fields

One rule drives validation: **a required field must have a value; an optional field may be left empty.**

A field is required when it has `"required": true`, a `"required"` validator, a `requiredWhen` condition that currently holds, or after `controller.setRequired(id, required: true)`. Hidden and disabled fields are never validated.

| Field state | Validation |
|---|---|
| Required, empty | "This field is required" (a checkbox must be ticked) |
| Required, has a value | Every validator runs |
| Optional, empty | Valid. Built-in format, length, range, preset and `minItems` checks are skipped |
| Optional, has a value | Every validator runs, so a half-typed email or one pick out of `minItems: 2` still fails |

Custom validators (`{"type": "custom"}` and `DynamicFormController(customValidators:)`) always run, so cross-field rules such as "phone or email" can see empty values. `matchField` passes when both fields are empty. A validator class of your own can opt in with `bool get checksEmpty => true`.

Labels show the rule. By default required fields get a red `*`, read as "required" by screen readers, and it updates live with `requiredWhen` and `setRequired`. Change it with the style key `requiredMark`, usually on the form `style` so it applies to every field:

| `requiredMark` | Shows |
|---|---|
| `asterisk` (default) | `Full name *` on required fields |
| `optional` | `Nickname (optional)` on optional fields; required ones stay plain. Suits forms where most fields are required |
| `both` | `*` on required and "(optional)" on optional fields |
| `none` | No mark |

```json
{
  "style": {"requiredMark": "both", "requiredMarkStyle": {"color": "#B00020"}},
  "fields": [
    {"type": "text", "id": "fullName", "label": "Full name", "required": true},
    {"type": "email", "id": "workEmail", "label": "Work email", "validators": ["email"]},
    {"type": "checkbox", "id": "business", "label": "Business purchase"},
    {"type": "text", "id": "gstin", "label": "GSTIN", "preset": "gst",
     "requiredWhen": {"field": "business", "operator": "isTrue"}}
  ]
}
```

Every field with a label and a value gets the mark (text, pickers, dropdowns, groups, toggles, sliders, media, repeaters). Display fields (`label`, `sectionHeader`, `divider`, `spacer`), containers (`group`, `expansion`), `hidden`, `readOnly` fields and fields with `"readOnly": true` never do. The "(optional)" text is localized (`optionalMark`); change it with `FormLocalizations.addTranslations`.

## Field types

Text: `text`, `textarea`, `password`, `email`, `number`, `decimal`, `phone`, `url`, `search`, `otp`, `pin`, `readOnly`, `hidden`.
Date and time: `date`, `time`, `datetime`.
Selection: `dropdown`, `searchableDropdown`, `multiselect`, `radioGroup`, `checkboxGroup`, `chips`, `segmented`, `toggleButtons`, `autocomplete`, `typeahead`.
Toggles: `checkbox`, `switch`, `radio`.
Numbers: `slider`, `rangeSlider`, `rating`, `stepper`, `colorPicker`.
Media: `image`, `camera`, `file`.
Location: `country`, `state`, `city`.
Layout: `label`, `sectionHeader`, `divider`, `spacer`, `group`, `expansion`.
Extendable: `repeater`.
Adapters (register with `FieldFactory.register`): `signature`, `qrScanner`, `barcodeScanner`, `richText`, `markdown`, `htmlEditor`, `custom`.

## Enums

Every string option has a Dart enum: `ValidatorType`, `ConditionOperator`, `KeyboardKind`, `InputActionKind`, `TextCase`, `TextPreset`, `PhoneFormat`, `OptionLayout`, `OptionStyle`, `RequiredMark`, `ControlShape`, `ControlPosition`, `PickerStyle`, `SelectedDisplay`, `FormSpacing`, `LabelBehavior`, `LabelPosition`, `FieldStyleVariant`, `MediaSource`. Each has a tolerant `fromString`.

Dart enums can supply options:

```dart
enum Plan { free, pro, team }
FormEnumRegistry.register('Plan', Plan.values, label: (p) => p.name.toUpperCase());

// JSON: {"type": "radioGroup", "id": "plan", "enum": "Plan"}
controller.setValue('plan', Plan.pro);          // stored as 'pro'
controller.getEnum('plan', Plan.values);        // Plan.pro
controller.getEnumList('addons', Addon.values); // multi-select
```

Typed configs serialize with `FormConfig.toJson()` / `FieldConfig.toJson()`:

```dart
FieldConfig(
  id: 'plan',
  type: FieldType.radioGroup,
  enumName: 'Plan',
  optionLayout: OptionLayout.horizontal,
  validators: [ValidatorConfig.required()],
  visibleWhen: Condition.when('signup', ConditionOperator.isTrue),
)
```

## Text presets

`"preset"` configures a text field for a common Indian identifier in one key: keyboard, allowed characters, capitalization, length limit, placeholder, icon and a format check.

| Preset | Rule |
|---|---|
| `name` | Letters of any script, spaces, `'`, `.`, `-` (2-60 characters) |
| `mobile` | 10 digits starting with 6-9 |
| `phone` | 7-15 digits, optional `+`, spaces, `-`, brackets |
| `pan` | `ABCPE1234F` (valid holder-type letter) |
| `aadhaar` | 12 digits, first digit 2-9, Verhoeff checksum (spaces allowed) |
| `gst` | 15 characters, valid state code, check character |
| `ifsc` | `HDFC0001234` |
| `pincode` | 6 digits, not starting with 0 |
| `vehicleNumber` | `MH12AB1234` |
| `voterId` | 3 letters and 7 digits |
| `passport` | Letter followed by 7 digits |
| `upiId` | `name@bank` |
| `custom` | Your own `regex`, reported with `presetMessage` |

```json
{"type": "text", "id": "pan", "label": "PAN", "preset": "pan", "required": true}
{"type": "text", "id": "empId", "preset": "custom", "regex": "^EMP-\\d{4}$",
 "presetMessage": "Use EMP-1234", "textCase": "upper", "maxLength": 8}
```

Empty values pass, so add `required` to make the field mandatory. The field's own `keyboardType`, `textCase`, `maxLength`, `hint` and `prefixIcon` win over the preset; `presetMessage` replaces the default error.

Reusable presets of your own:

```dart
TextPresets.register('employeeId', TextPresetSpec(
  message: 'Employee id looks like E-12345',
  pattern: r'^E-\d{5}$',
  textCase: TextCase.upper,
  maxLength: 7,
  check: (value) => true, // optional: checksums and other non-pattern rules
));
// JSON: {"type": "text", "id": "emp", "preset": "employeeId"}
```

### Phone numbers with a country code

Phone fields (`"type": "phone"`, or a text field with the `mobile` or `phone` preset) can offer an optional country code picker. It is off unless you set `countryCode`:

```json
{"type": "text", "id": "mobile", "label": "Mobile", "preset": "mobile", "countryCode": true}
{"type": "phone", "id": "office", "label": "Office", "countryCode": "+44", "countryCodes": ["IN", "US", "+44", "AE"]}
```

| Key | Meaning |
|---|---|
| `countryCode` | `true` (first country, India by default) or a default country as ISO code (`"US"`) or dial code (`"+44"`) |
| `countryCodes` | Optional list of ISO or dial codes the picker offers, in order |

The input holds only the national number. Internally the value is `+<code><digits>` (`+919876543210`), and you choose how it comes out of the controller:

| Option | Result |
|---|---|
| `PhoneFormat.combined` (default) | `{"mobile": "+919876543210"}` |
| `PhoneFormat.separate` | `{"mobile": "9876543210", "mobileCountryCode": "+91"}` |

Set it where it suits you, most specific first: `getFormData(phoneFormat: ...)` for one call, `"phoneFormat": "separate"` on a field (and `"countryCodeKey": "dial"` to rename the code key), or `DynamicFormController(phoneFormat: ...)` for every phone field. `onChanged`, `onSubmit` and repeater entries follow the same rule, while validation and conditions always see the combined value.

```dart
controller.getFormData(phoneFormat: PhoneFormat.separate);
controller.getPhoneNumber('mobile');   // '+919876543210'
controller.getCountryCode('mobile');   // '+91'
controller.getNationalNumber('mobile'); // '9876543210'
controller.getPhone('mobile');         // (dial: '+91', number: '9876543210')
controller.setPhone('mobile', dial: '+44', number: '7911 123456');
```

Prefill records (`initialData`, `setFormData`) accept either shape: `{"mobile": "+919876543210"}` or `{"mobile": "9876543210", "mobileCountryCode": "+91"}` (the code may also be an ISO code such as `"GB"`). `reset()` restores the prefilled country. `mobile` keeps the Indian rule (10 digits starting 6-9) for `+91` and accepts 6-14 digits for other countries. The picker is a searchable sheet that stays above the keyboard. Type a country name (`united`), a word inside it (`emirates`), an ISO code (`gb`) or a dial code with or without the plus (`+44`, `44`); the best matches come first. Each country shows its flag as an image (from the `country_flags` package, so it looks the same on every platform; the emoji `CountryDialCode.flag` is the fallback). `CountryDialCodes.all`, `lookup`, `resolve`, `search` and `split` expose the data.

## Searchable dropdown

`"type": "searchableDropdown"` opens a picker with a search box (a rounded bottom sheet by default). It needs no extra package.

**Do you need it?** Use radio buttons, `segmented` or `chips` for 2-5 choices, a plain `dropdown` for 5-10, and `searchableDropdown` when the list is longer, comes from an API, or users already know what to type. For several values, `checkboxGroup` or `chips` suit up to about 8 options; beyond that use `searchableDropdown` with `"multiple": true`.

Options come from one of three places:

| Source | Set up | Searching |
|---|---|---|
| Local list | `"options": [...]` or `"enum": "Name"` | Filtered on the device (label, description, value) |
| API, loaded once | `DynamicFormController(optionsLoader: (fieldId, formData) async => [...])`, no `options` in JSON | Filtered on the device; reloads when a `dependsOn` field changes |
| API, search as you type | `"searchSource": "cities"` + `FormSearchSources.register('cities', (query, formData) async => [...])` | Your function is called with the typed text (debounced) |

```dart
FormSearchSources.register('cities', (query, formData) async {
  final res = await ApiClient.instance.request(
    ApiRequest(endpoint: '/cities', method: ApiMethod.get, queryParameters: {'q': query}),
  );
  return [
    for (final c in res.data as List)
      OptionItem(label: c['name'] as String, value: c['id'], description: c['state'] as String?),
  ];
});
// Or for one form only: DynamicFormController(searchSources: {'cities': search})
```

```json
{"type": "searchableDropdown", "id": "city", "label": "City", "searchSource": "cities", "minSearchLength": 2}
{"type": "searchableDropdown", "id": "langs", "label": "Languages", "multiple": true, "showSelectAll": true,
 "maxItems": 3, "options": ["Gujarati", "Hindi", "Marathi", "Tamil", "Telugu"]}
```

| Key | Default | Meaning |
|---|---|---|
| `multiple` | `false` | Select several values; the value is a List. The picker shows checkboxes and Done; dismissing keeps the old selection |
| `searchSource` | | Name of a registered search function (see above) |
| `minSearchLength` | `0` | Characters before `searchSource` runs; until then the static `options` show |
| `debounceMs` | `350` | Wait after typing before calling `searchSource` |
| `showSearchBox` | `true` | Show the search field |
| `searchHint` | "Search" | Search field placeholder |
| `noResultsText` | "No results" | Text when nothing matches |
| `autofocusSearch` | `true` | Open the keyboard with the picker |
| `pickerStyle` | `bottomSheet` | `bottomSheet`, `dialog` (tablet, web) or `fullScreen` (very long lists) |
| `pickerHeight` | `0.75` | Bottom sheet height as a fraction of the screen (0.3-1) |
| `selectedDisplay` | `chips` | Closed multiple field: `chips` (removable), `text` or `count` |
| `showSelectAll` | `false` | Select all / Clear in a multiple picker (respects `maxItems`) |
| `showClear` | `true` | Clear button in the closed field |
| `minItems` / `maxItems` | | Limits for a multiple selection |
| `allowCustomOptions` | `false` | Offer "Add <typed text>" when nothing matches |

A search function that throws shows "Could not load results" with Retry. Picked API results are remembered so their labels stay visible; to prefill an API-backed field, also put the saved item in `options` so its label shows before the user searches. A plain `dropdown` with `"searchable": true`, `"multiple": true` or a `searchSource` uses the same picker (with `multiple` alone, the search box is off). The closed field follows the normal field style; picker rows use `activeColor`, `selectedColor`, `selectedTextStyle`, `optionRadius` and `optionPadding`.

## Radio and checkbox styles

`"optionStyle"` changes how `radioGroup`, `checkboxGroup` and a single `checkbox`, `radio` or `switch` look:

| `optionStyle` | Looks like | Default layout |
|---|---|---|
| `standard` | Material list tiles (default) | vertical |
| `card` | Each option in a bordered card; the selected one is tinted and outlined. Good with option `description` | vertical |
| `chip` | Compact pills | wrap |
| `button` | Boxes without a visible control; the selected one is filled | grid, up to 3 columns |

`controlShape` (`square`, `rounded`, `circle`) shapes checkboxes, and `controlPosition` (`leading`, `trailing`, `none`) moves the mark. Both also work with `standard`. Colours and sizes come from style keys: `activeColor`, `selectedColor`, `selectedBorderColor`, `optionBorderColor`, `optionRadius`, `optionSpacing`, `optionPadding`, `selectedTextStyle`. `optionLayout` and `columns` still apply.

```json
{"type": "radioGroup", "id": "plan", "label": "Plan", "optionStyle": "card",
 "options": [{"label": "Free", "value": "free", "description": "For trying out"},
             {"label": "Pro", "value": "pro", "description": "For teams"}]}
{"type": "checkboxGroup", "id": "days", "optionStyle": "button", "columns": 4,
 "options": ["Mon", "Tue", "Wed", "Thu"],
 "style": {"activeColor": "#6A1B9A", "optionRadius": 24, "optionSpacing": "compact"}}
```

## Extendable forms

**Repeater.** `fields` is the template for one entry. The value is `List<Map<String, dynamic>>`. Each entry validates on its own, and conditions inside an entry read that entry's data.

| Key | Meaning |
|---|---|
| `minItems` / `maxItems` | Entry limits; remove / add controls disable at the limits |
| `initialItems` | Blank entries for a new form (default `minItems`, else 1) |
| `itemLabel` | Entry title; `{index}` is the 1-based position |
| `addLabel` | Add button text |
| `reorderable` | Move up / down buttons |

Controller: `addEntry`, `removeEntry`, `moveEntry`, `canAddEntry`, `canRemoveEntry`, `entriesOf`, `getEntries`, and `setValue(id, listOfMaps)`.

**User-added options.** `"allowCustomOptions": true` on a dropdown, searchable dropdown, multiselect, radio group, checkbox group or chips adds an "Add option" control (the searchable dropdown offers "Add <typed text>"). `customOptionLabel` renames it. The new option is selected and `onOptionAdded` fires. From code: `addOption`, `removeOption`, `customOptions`.

**Item counts.** `minItems` / `maxItems` also limit multi-select fields; they are validators named `minItems` / `maxItems`. An optional field with nothing selected passes `minItems`; add `required` to demand a selection.

## Per-field customization

Field keys: `prefixText`, `suffixText`, `prefixIcon`, `suffixIcon`, `textCase` (`upper`, `lower`, `words`, `sentences`), `keyboardType`, `textInputAction`, `maxLines` (`rows`), `minLines`, `maxLength` + `showCounter`, `tooltip`, `optionLayout` (`vertical`, `horizontal`, `wrap`, `grid`) + `columns`, `optionStyle` (`standard`, `card`, `chip`, `button`), `padding`, `margin`, `width`, `height`. Options take `label`, `value`, `icon`, `description`, `enabled`.

`style` keys: `variant` (`outlined`, `rounded`, `filled`, `underline`, `none`), `borderRadius`, `fillColor`, `borderColor`, `focusedBorderColor`, `borderWidth`, `dense`, `contentPadding`, `labelBehavior`, `labelPosition` (`floating`, `above`, `hidden`), `textStyle`, `labelStyle`, `hintStyle`, `helperStyle`, `errorStyle`, `iconColor`, `activeColor`, `cursorColor`, `textAlign`, `containerColor`, `containerRadius`, `selectedColor`, `selectedBorderColor`, `optionBorderColor`, `optionRadius`, `optionSpacing`, `optionPadding`, `selectedTextStyle`, `requiredMark` (`asterisk`, `optional`, `both`, `none`), `requiredMarkStyle`.

Styles merge in this order, most specific last: `DynamicFormThemeData.defaultFieldStyle`, form `style`, field `style`, then `FieldOverrides.style`.

`FieldOverrides` options are `builder` (replace the widget), `style`, `decoration` (post-process the `InputDecoration`), `optionBuilder`, `wrapper`, and `label` / `hint` / `helperText`.

## Extension points

| API | Use |
|---|---|
| `FieldFactory.register(type, builder)` | Replace any built-in renderer or provide an adapter |
| `FieldFactory.registerCustom(name, builder)` | `{"type": "custom", "customType": name}` |
| `ValidatorRegistry.register(name, factory)` | New JSON validator type |
| `DynamicFormController(customValidators: {...})` | `{"type": "custom", "name": ...}` |
| `ConditionEvaluator.registerOperator(name, fn)` | New condition operator |
| `FieldUtils.registerIcon(name, icon)` | New icon name for JSON |
| `FormSearchSources.register(name, fn)` | Search-as-you-type source for `"searchSource"` |
| `FormLocalizations.addTranslations(locale, map)` | Messages (built in: en, hi, ar, es, fr, de) |
| `MediaPickerAdapter.instance` | Custom image / file picking |

## Credits

Based on [json_form_engine](https://github.com/rupeshrajak0285/json_form_engine) by Rupesh Rajak (MIT). See [THIRD_PARTY_NOTICES.md](../THIRD_PARTY_NOTICES.md).
