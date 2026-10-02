# Dynamic forms

`DynamicForm` renders a complete form from JSON (a `Map` or a JSON string). The interactive guide in [`form_guide_web/`](../form_guide_web/) documents every field type with live previews, and its Element builder lets you edit any element's JSON and see it render. This page is the short reference.

```dart
import 'package:services_rj/services_rj.dart'; // or package:services_rj/forms.dart

final controller = DynamicFormController();

DynamicForm(
  controller: controller,
  json: formJson,
  initialData: existingRecord,          // optional: edit mode
  showSubmitButton: true,
  onSubmit: (data) => save(data),
  onOptionAdded: (fieldId, option) => saveOption(fieldId, option),
  fieldOverrides: {...},                // per field id
  typeOverrides: {...},                 // per FieldType
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

## Field types

Text: `text`, `textarea`, `password`, `email`, `number`, `decimal`, `phone`, `url`, `search`, `otp`, `pin`, `readOnly`, `hidden`.
Date and time: `date`, `time`, `datetime`.
Selection: `dropdown`, `multiselect`, `radioGroup`, `checkboxGroup`, `chips`, `segmented`, `toggleButtons`, `autocomplete`, `typeahead`.
Toggles: `checkbox`, `switch`, `radio`.
Numbers: `slider`, `rangeSlider`, `rating`, `stepper`, `colorPicker`.
Media: `image`, `camera`, `file`.
Location: `country`, `state`, `city`.
Layout: `label`, `sectionHeader`, `divider`, `spacer`, `group`, `expansion`.
Extendable: `repeater`.
Adapters (register with `FieldFactory.register`): `signature`, `qrScanner`, `barcodeScanner`, `richText`, `markdown`, `htmlEditor`, `custom`.

## Enums

Every string option has a Dart enum: `ValidatorType`, `ConditionOperator`, `KeyboardKind`, `InputActionKind`, `TextCase`, `TextPreset`, `PhoneFormat`, `OptionLayout`, `LabelBehavior`, `LabelPosition`, `FieldStyleVariant`, `MediaSource`. Each has a tolerant `fromString`.

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

**User-added options.** `"allowCustomOptions": true` on a dropdown, multiselect, radio group, checkbox group or chips adds an "Add option" control. `customOptionLabel` renames it. The new option is selected and `onOptionAdded` fires. From code: `addOption`, `removeOption`, `customOptions`.

**Item counts.** `minItems` / `maxItems` also limit multi-select fields; they are validators named `minItems` / `maxItems`.

## Per-field customization

Field keys: `prefixText`, `suffixText`, `prefixIcon`, `suffixIcon`, `textCase` (`upper`, `lower`, `words`, `sentences`), `keyboardType`, `textInputAction`, `maxLines` (`rows`), `minLines`, `maxLength` + `showCounter`, `tooltip`, `optionLayout` (`vertical`, `horizontal`, `wrap`, `grid`) + `columns`, `padding`, `margin`, `width`, `height`. Options take `label`, `value`, `icon`, `description`, `enabled`.

`style` keys: `variant` (`outlined`, `rounded`, `filled`, `underline`, `none`), `borderRadius`, `fillColor`, `borderColor`, `focusedBorderColor`, `borderWidth`, `dense`, `contentPadding`, `labelBehavior`, `labelPosition` (`floating`, `above`, `hidden`), `textStyle`, `labelStyle`, `hintStyle`, `helperStyle`, `errorStyle`, `iconColor`, `activeColor`, `cursorColor`, `textAlign`, `containerColor`, `containerRadius`.

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
| `FormLocalizations.addTranslations(locale, map)` | Messages (built in: en, hi, ar, es, fr, de) |
| `MediaPickerAdapter.instance` | Custom image / file picking |

## Credits

Based on [json_form_engine](https://github.com/rupeshrajak0285/json_form_engine) by Rupesh Rajak (MIT). See [THIRD_PARTY_NOTICES.md](../THIRD_PARTY_NOTICES.md).
