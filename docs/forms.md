# Dynamic forms

`DynamicForm` renders a complete form from JSON (a `Map` or a JSON string). The interactive guide in [`form_guide_web/`](../form_guide_web/) documents every field type with live previews. This page is the short reference.

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

Every string option has a Dart enum: `ValidatorType`, `ConditionOperator`, `KeyboardKind`, `InputActionKind`, `TextCase`, `OptionLayout`, `LabelBehavior`, `FieldStyleVariant`, `MediaSource`. Each has a tolerant `fromString`.

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

`style` keys: `variant` (`outlined`, `rounded`, `filled`, `underline`, `none`), `borderRadius`, `fillColor`, `borderColor`, `focusedBorderColor`, `borderWidth`, `dense`, `contentPadding`, `labelBehavior`, `textStyle`, `labelStyle`, `hintStyle`, `helperStyle`, `errorStyle`, `iconColor`, `activeColor`, `cursorColor`, `textAlign`, `containerColor`, `containerRadius`.

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
