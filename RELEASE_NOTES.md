# services_rj 1.2.0 — build forms from JSON

This release adds a JSON-driven form builder. Describe a form as a JSON map (from your backend, a file or a Dart literal) and `DynamicForm` renders it, validates it and hands you the data.

## Highlights

- **53 field types** — text, password, email, phone with country code, date and time pickers, dropdowns, chips, radio, checkbox, switch, slider, rating, stepper, image and file pickers, location pickers, signature, and more.
- **Text presets** — one key (`"preset": "pan"`) sets the keyboard, allowed characters, case, length and format check. Built in: `name`, `mobile`, `phone`, `pan`, `aadhaar`, `gst`, `ifsc`, `pincode`, `vehicleNumber`, `voterId`, `passport`, `upiId`, `custom`.
- **Phone country code picker** — `"countryCode": true` adds a searchable picker with flags. The value is stored as `+919876543210`.
- **Validation** — built-in validators plus your own, declared in JSON.
- **Conditional logic** — `visibleWhen`, `requiredWhen`, `and` / `or` / `not`, and custom operators.
- **Extendable forms** — `repeater` field (add, remove, reorder rows) and `allowCustomOptions` so users can add their own choices.
- **Multi-step wizards, edit mode, dirty tracking** and `confirmDiscard`.
- **Styling and localisation** — per-form and per-field `style`, `labelPosition`, six built-in languages, and `FieldOverrides` to swap any widget.
- **Typed enums** for every string option, and `FormEnumRegistry` to feed Dart enums into JSON (`"enum": "Plan"`).

## Fixes

- Floating labels of outlined fields were cut off at the top.
- Segmented button labels no longer wrap mid-word.
- 2xx responses other than 200 and 201 were treated as errors; non-JSON error bodies and `ApiException` no longer crash the error handler.

## Docs and tooling

- **Form guide website** (`form_guide_web/`) with an **Element builder**: pick any of the 53 elements, edit its JSON, see it render, read its keys and copy the Dart snippet. Links like `/#/elements/dropdown` open one element directly.
- GitHub Actions CI: format, analyze, tests with coverage and a pub.dev publish dry-run on every push and pull request to `master`.
- The package is now analyzer-clean (`flutter analyze --fatal-infos`).

## Generate a UI from JSON

### 1. Install

```yaml
dependencies:
  services_rj: ^1.2.0
```

Only need forms? `import 'package:services_rj/forms.dart';`

### 2. Describe the form

A form is a map with a `fields` list. Each field needs an `id` and a `type`.

```json
{
  "title": "Create account",
  "fields": [
    { "type": "text", "id": "fullName", "label": "Full name", "validators": ["required"] },
    { "type": "text", "id": "pan", "label": "PAN", "preset": "pan" },
    { "type": "phone", "id": "mobile", "label": "Mobile", "countryCode": "IN", "required": true },
    {
      "type": "dropdown",
      "id": "plan",
      "label": "Plan",
      "options": [
        { "label": "Solo", "value": "solo" },
        { "label": "Team", "value": "team" }
      ]
    },
    {
      "type": "stepper",
      "id": "members",
      "label": "Team size",
      "min": 2,
      "max": 50,
      "visibleWhen": { "field": "plan", "operator": "equals", "value": "team" }
    }
  ]
}
```

### 3. Render it

```dart
import 'package:services_rj/services_rj.dart';

class SignUpForm extends StatefulWidget {
  const SignUpForm({super.key});

  @override
  State<SignUpForm> createState() => _SignUpFormState();
}

class _SignUpFormState extends State<SignUpForm> {
  final controller = DynamicFormController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => DynamicForm(
    controller: controller,
    json: signUpJson, // a Map, or the JSON string from your API
    showSubmitButton: true,
    onSubmit: (data) => api.createAccount(data),
  );
}
```

`onSubmit` only runs when every visible field passes validation. `data` is a plain map: `{fullName: ..., pan: ..., mobile: +919876543210, plan: team, members: 4}`.

### 4. Read and drive it from code

```dart
controller.getFormData();            // all values
controller.validate();               // true when valid, errors shown on screen
controller.getPhone('mobile');       // split into country code and number
controller.setValue('plan', 'solo'); // change a value
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
