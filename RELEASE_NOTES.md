# services_rj 1.2.0 — build forms from JSON

This release adds a JSON-driven form builder. Describe a form as a JSON map (from your backend, a file or a Dart literal) and `DynamicForm` renders it, validates it and hands you the data.

## Highlights

- **54 field types** — text, password, email, phone with country code, date and time pickers, dropdowns, searchable dropdowns, chips, radio, checkbox, switch, slider, rating, stepper, image and file pickers, location pickers, signature, and more.
- **Text presets** — one key (`"preset": "pan"`) sets the keyboard, allowed characters, case, length and format check. Built in: `name`, `mobile`, `phone`, `pan`, `aadhaar`, `gst`, `ifsc`, `pincode`, `vehicleNumber`, `voterId`, `passport`, `upiId`, `custom`.
- **Phone country code picker** — `"countryCode": true` adds a searchable picker with flags. The value is stored as `+919876543210`.
- **Validation** — built-in validators plus your own, declared in JSON. Required fields show a red `*` (or mark optional ones with `"requiredMark": "optional"`), and an optional field may be left empty while its format checks still apply to whatever is typed.
- **Conditional logic** — `visibleWhen`, `requiredWhen`, `and` / `or` / `not`, and custom operators.
- **Extendable forms** — `repeater` field (add, remove, reorder rows) and `allowCustomOptions` so users can add their own choices.
- **Multi-step wizards, edit mode, dirty tracking** and `confirmDiscard`.
- **Styling and localisation** — per-form and per-field `style`, `labelPosition`, six built-in languages, and `FieldOverrides` to swap any widget.
- **Searchable dropdown** — `searchableDropdown` opens a bottom sheet, dialog or full-screen picker with a search box. Options come from a local list, an API loaded once, or an API searched as you type (`"searchSource"` + `FormSearchSources.register`), with debounce, a minimum search length and Retry on errors. `"multiple": true` selects several values with chips, Select all and `maxItems`. No extra package needed.
- **Radio and checkbox styles** — `"optionStyle"`: `standard`, `card`, `chip` or `button`, plus `controlShape` and `controlPosition`. Colours, radius, spacing and padding are style keys (`selectedColor`, `selectedBorderColor`, `optionBorderColor`, `optionRadius`, `optionSpacing`, `optionPadding`, `selectedTextStyle`).
- **Standard padding** — every padding and spacing takes a number or a name (`compact` 8, `standard` 16, `comfortable` 24…). Form root keys `padding`, `fieldSpacing` and `fieldPadding`, and `DynamicForm(padding:)`.
- **Typed enums** for every string option, and `FormEnumRegistry` to feed Dart enums into JSON (`"enum": "Plan"`).

## Fixes

- Floating labels of outlined fields were cut off at the top.
- Segmented button labels no longer wrap mid-word.
- 2xx responses other than 200 and 201 were treated as errors; non-JSON error bodies and `ApiException` no longer crash the error handler.

## Docs and tooling

- **[Form guide website](https://mranjeethq.github.io/services_rj/)** (`form_guide_web/`) with an **Element builder**: pick any of the 54 elements, edit its JSON, see it render, read its keys and copy the Dart snippet. Links like `/#/elements/dropdown` open one element directly. Getting started has a **search box** that finds any element, property, style key or validator, and a new **Dropdowns & search** page explains when to use which dropdown and every key.
- Every code example in the README, this page and `docs/forms.md` is a complete app you can paste into `lib/main.dart`; tests run them.
- GitHub Actions CI: format, analyze, tests with coverage and a pub.dev publish dry-run on every push and pull request to `master`.
- The package is now analyzer-clean (`flutter analyze --fatal-infos`).

## Generate a UI from JSON

### 1. Install

```yaml
dependencies:
  services_rj: ^1.2.0
```

Only need forms? `import 'package:services_rj/forms.dart';`

### 2. Describe the form and render it

A form is a map with a `fields` list; each field needs an `id` and a `type`. The JSON can be a Dart map like below, or the string your API returns. This is a complete app: paste it into `lib/main.dart` and run. `DynamicForm` is a scrolling list of fields, so it goes in a `Scaffold` body (it needs a `Material` ancestor and a bounded height).

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

`onSubmit` only runs when every visible field passes validation. `data` is a plain map: `{fullName: Asha, city: Pune, plan: pro, newsletter: false}`.

### 3. Add more fields

Swap in any of the 54 field types. A few worth knowing:

```json
{"type": "text", "id": "pan", "label": "PAN", "preset": "pan"}
{"type": "phone", "id": "mobile", "label": "Mobile", "countryCode": "IN", "required": true}
{"type": "searchableDropdown", "id": "skills", "label": "Skills", "multiple": true,
 "showSelectAll": true, "maxItems": 3, "options": ["Dart", "Flutter", "Kotlin", "Swift"]}
{"type": "searchableDropdown", "id": "customer", "label": "Customer", "searchSource": "customers",
 "minSearchLength": 2}
{"type": "checkboxGroup", "id": "days", "label": "Days", "optionStyle": "button",
 "options": ["Mon", "Tue", "Wed"]}
{"type": "stepper", "id": "members", "label": "Team size", "min": 2, "max": 50,
 "visibleWhen": {"field": "plan", "operator": "equals", "value": "pro"}}
```

`searchSource` names a function you register once, for example in `main()`:

```dart
FormSearchSources.register('customers', (query, formData) async {
  final res = await ApiClient.instance.request(
    ApiRequest(endpoint: '/customers', method: ApiMethod.get, queryParameters: {'q': query}),
  );
  return [
    for (final c in res.data as List) OptionItem(label: c['name'] as String, value: c['id']),
  ];
});
```

### 4. Read and drive it from code

```dart
controller.getFormData();            // all values
controller.validate();               // true when valid, errors shown on screen
controller.getPhone('mobile');       // split into country code and number
controller.setValue('plan', 'free'); // change a value
```

### 5. Try it without writing code

Open the form guide website and use the **Element builder** or the **Playground** to paste JSON and see it render. Run it locally:

```sh
cd form_guide_web
flutter run -d chrome
```

## Upgrading

No breaking changes from 1.1.0. Forms are additive: existing `AppController`, networking, caching and theming APIs are unchanged.

Full details are in [CHANGELOG.md](CHANGELOG.md) and [docs/forms.md](docs/forms.md). The form engine is based on json_form_engine by Rupesh Rajak (MIT); see [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
