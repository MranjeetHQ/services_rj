import 'package:services_rj/services_rj.dart';

/// One documented JSON key.
class KeyDoc {
  const KeyDoc(
    this.key,
    this.type,
    this.description, {
    this.aliasOf,
    this.group = 'Basics',
  });

  final String key;
  final String type;
  final String description;

  /// Set when this key is an alternative spelling of another key.
  final String? aliasOf;
  final String group;
}

/// Every common field property. KEEP IN SYNC with
/// `FieldConfig.knownKeys` (enforced by `test/catalog_sync_test.dart`).
const List<KeyDoc> fieldPropertyDocs = [
  KeyDoc('id', 'String', 'Unique key in form data and the controller API.'),
  KeyDoc('key', 'String', 'Alternative to `id`.', aliasOf: 'id'),
  KeyDoc(
    'type',
    'String',
    'Field type name — see Field types. Defaults to `text`.',
  ),
  KeyDoc('name', 'String', 'Key used in `getFormData()` instead of `id`.'),
  KeyDoc('label', 'String', 'Floating label / title.'),
  KeyDoc('hint', 'String', 'Placeholder text.'),
  KeyDoc('helperText', 'String', 'Small text under the field.'),
  KeyDoc('tooltip', 'String', 'Shown on hover / long-press.'),
  KeyDoc('initialValue', 'any', 'Value on first build.', group: 'Values'),
  KeyDoc(
    'defaultValue',
    'any',
    'Used when there is no initial value.',
    group: 'Values',
  ),
  KeyDoc(
    'required',
    'bool',
    'Must have a value (checkbox: must be ticked).',
    group: 'State',
  ),
  KeyDoc(
    'enabled',
    'bool',
    'Static enablement (default true).',
    group: 'State',
  ),
  KeyDoc('readOnly', 'bool', 'Shows the value, blocks edits.', group: 'State'),
  KeyDoc(
    'visible',
    'bool',
    'Static visibility (default true).',
    group: 'State',
  ),
  KeyDoc('autofocus', 'bool', 'Focus on first build.', group: 'State'),
  KeyDoc(
    'visibleWhen',
    'Condition',
    'Show only while the condition holds.',
    group: 'Conditions',
  ),
  KeyDoc(
    'enabledWhen',
    'Condition',
    'Enable only while the condition holds.',
    group: 'Conditions',
  ),
  KeyDoc(
    'requiredWhen',
    'Condition',
    'Required only while the condition holds.',
    group: 'Conditions',
  ),
  KeyDoc(
    'validators',
    'List',
    'Validator names or objects — see Validation.',
    group: 'Validation',
  ),
  KeyDoc(
    'minLength',
    'int',
    'Shorthand for a `minLength` validator.',
    group: 'Validation',
  ),
  KeyDoc(
    'maxLength',
    'int',
    'Limits typing and validates length.',
    group: 'Validation',
  ),
  KeyDoc(
    'regex',
    'String',
    'Shorthand for a `regex` validator.',
    group: 'Validation',
  ),
  KeyDoc(
    'preset',
    'String',
    'Ready-made text input: `name`, `mobile`, `phone`, `pan`, `aadhaar`, '
        '`gst`, `ifsc`, `pincode`, `vehicleNumber`, `voterId`, `passport`, '
        '`upiId`, `custom`, or a name added with `TextPresets.register`. Sets '
        'keyboard, allowed characters, case and length, and adds a format '
        'check. Your own `keyboardType`, `textCase`, `maxLength`, `hint` and '
        '`prefixIcon` win.',
    group: 'Validation',
  ),
  KeyDoc(
    'presetMessage',
    'String',
    'Error shown when the `preset` check fails (for `custom`, when `regex` '
        'does not match). Defaults to the preset message.',
    group: 'Validation',
  ),
  KeyDoc('obscureText', 'bool', 'Hide the typed text.', group: 'Text input'),
  KeyDoc(
    'maxLines',
    'int',
    'Visible lines (textarea default 4).',
    group: 'Text input',
  ),
  KeyDoc(
    'rows',
    'int',
    'Alternative to `maxLines`.',
    aliasOf: 'maxLines',
    group: 'Text input',
  ),
  KeyDoc('minLines', 'int', 'Minimum visible lines.', group: 'Text input'),
  KeyDoc(
    'showCounter',
    'bool',
    'Show `12 / 140` when `maxLength` is set.',
    group: 'Text input',
  ),
  KeyDoc(
    'keyboardType',
    'KeyboardKind',
    'Keyboard to show.',
    group: 'Text input',
  ),
  KeyDoc(
    'textInputAction',
    'InputActionKind',
    'Keyboard action button.',
    group: 'Text input',
  ),
  KeyDoc(
    'textCase',
    'TextCase',
    '`upper` / `lower` force the case; `words` / '
        '`sentences` set the keyboard capitalization.',
    group: 'Text input',
  ),
  KeyDoc(
    'prefixIcon',
    'icon name',
    'Leading icon — see Icons.',
    group: 'Decoration',
  ),
  KeyDoc('suffixIcon', 'icon name', 'Trailing icon.', group: 'Decoration'),
  KeyDoc(
    'prefixText',
    'String',
    'Fixed text before the input (`₹`, `+91`).',
    group: 'Decoration',
  ),
  KeyDoc(
    'suffixText',
    'String',
    'Fixed text after the input (`kg`).',
    group: 'Decoration',
  ),
  KeyDoc('style', 'Map', 'Per-field look — see Styling.', group: 'Decoration'),
  KeyDoc(
    'decoration',
    'Map',
    'Merged with `style` (style wins).',
    aliasOf: 'style',
    group: 'Decoration',
  ),
  KeyDoc('padding', 'number | Map', 'Inner padding.', group: 'Layout'),
  KeyDoc(
    'margin',
    'number | Map',
    'Outer margin (default: bottom gap).',
    group: 'Layout',
  ),
  KeyDoc('width', 'number', 'Fixed width.', group: 'Layout'),
  KeyDoc(
    'height',
    'number',
    'Fixed height (spacer: gap size).',
    group: 'Layout',
  ),
  KeyDoc(
    'options',
    'List',
    'Choices: `"Gold"` or `{label, value, icon, '
        'description, enabled}`.',
    group: 'Options',
  ),
  KeyDoc(
    'items',
    'List',
    'Alternative to `options`.',
    aliasOf: 'options',
    group: 'Options',
  ),
  KeyDoc(
    'enum',
    'String',
    'Use a registered Dart enum as the options.',
    group: 'Options',
  ),
  KeyDoc(
    'enumName',
    'String',
    'Alternative to `enum`.',
    aliasOf: 'enum',
    group: 'Options',
  ),
  KeyDoc(
    'optionsUrl',
    'String',
    'Passed to your `optionsLoader`.',
    group: 'Options',
  ),
  KeyDoc(
    'dependsOn',
    'List<String>',
    'When one of these fields changes, '
        'clear this value and reload its options.',
    group: 'Options',
  ),
  KeyDoc(
    'optionLayout',
    'OptionLayout',
    'How group / chip options are laid '
        'out.',
    group: 'Options',
  ),
  KeyDoc(
    'layout',
    'OptionLayout',
    'Alternative to `optionLayout`.',
    aliasOf: 'optionLayout',
    group: 'Options',
  ),
  KeyDoc(
    'columns',
    'int',
    'Columns for the `grid` layout (2).',
    group: 'Options',
  ),
  KeyDoc(
    'allowCustomOptions',
    'bool',
    'Users can add their own option.',
    group: 'Options',
  ),
  KeyDoc(
    'allowCustom',
    'bool',
    'Alternative to `allowCustomOptions`.',
    aliasOf: 'allowCustomOptions',
    group: 'Options',
  ),
  KeyDoc(
    'customOptionLabel',
    'String',
    'Text of the add-option control.',
    group: 'Options',
  ),
  KeyDoc(
    'minItems',
    'int',
    'Minimum selections or repeater entries.',
    group: 'Extendable',
  ),
  KeyDoc(
    'maxItems',
    'int',
    'Maximum selections or repeater entries.',
    group: 'Extendable',
  ),
  KeyDoc(
    'fields',
    'List',
    'Child fields (group, expansion, repeater, steps).',
    group: 'Extendable',
  ),
  KeyDoc(
    'itemFields',
    'List',
    'Alternative to `fields` for repeaters.',
    aliasOf: 'fields',
    group: 'Extendable',
  ),
  KeyDoc(
    'initialItems',
    'int',
    'Blank repeater entries for a new form.',
    group: 'Extendable',
  ),
  KeyDoc(
    'itemLabel',
    'String',
    'Repeater entry title; `{index}` = position.',
    group: 'Extendable',
  ),
  KeyDoc(
    'addLabel',
    'String',
    'Repeater add-button text.',
    group: 'Extendable',
  ),
  KeyDoc(
    'reorderable',
    'bool',
    'Repeater move up / down buttons.',
    group: 'Extendable',
  ),
];

/// Every style key. KEEP IN SYNC with `FieldStyleConfig.knownKeys`.
const List<KeyDoc> styleDocs = [
  KeyDoc(
    'variant',
    'outlined | rounded | filled | underline | none',
    'Border style.',
  ),
  KeyDoc('type', 'String', 'Alternative to `variant`.', aliasOf: 'variant'),
  KeyDoc(
    'borderRadius',
    'number',
    'Corner radius (outlined 8, filled 12, '
        'rounded 28).',
  ),
  KeyDoc(
    'radius',
    'number',
    'Alternative to `borderRadius`.',
    aliasOf: 'borderRadius',
  ),
  KeyDoc('fillColor', 'color', 'Background; turns filling on.'),
  KeyDoc('borderColor', 'color', 'Border colour.'),
  KeyDoc('focusedBorderColor', 'color', 'Border colour while focused.'),
  KeyDoc('borderWidth', 'number', 'Border width.'),
  KeyDoc('dense', 'bool', 'Compact height.'),
  KeyDoc(
    'contentPadding',
    'number | Map',
    'Inner padding; Map takes left/top/'
        'right/bottom or horizontal/vertical.',
  ),
  KeyDoc('labelBehavior', 'auto | always | never', 'Floating label behaviour.'),
  KeyDoc(
    'labelPosition',
    'floating | above | hidden',
    'Where the label shows: inside the border and floating (default), as a '
        'static label above the field, or hidden (the label text becomes the '
        'hint). Style it with `labelStyle`.',
  ),
  KeyDoc('textStyle', 'TextStyle', 'Typed text.'),
  KeyDoc('labelStyle', 'TextStyle', 'Label (also group / slider titles).'),
  KeyDoc('hintStyle', 'TextStyle', 'Hint.'),
  KeyDoc('helperStyle', 'TextStyle', 'Helper text.'),
  KeyDoc('errorStyle', 'TextStyle', 'Error text.'),
  KeyDoc('iconColor', 'color', 'Prefix / suffix icon colour.'),
  KeyDoc(
    'activeColor',
    'color',
    'Selected colour of checkboxes, radios, '
        'switches, chips, sliders, ratings and segments.',
  ),
  KeyDoc('cursorColor', 'color', 'Text cursor.'),
  KeyDoc(
    'textAlign',
    'left | right | center | start | end | justify',
    'Typed-text alignment.',
  ),
  KeyDoc('containerColor', 'color', 'Background of group / repeater entries.'),
  KeyDoc('containerRadius', 'number', 'Corner radius of those containers.'),
];

/// Built-in validators. KEEP IN SYNC with [ValidatorType].
const Map<ValidatorType, String> validatorDocs = {
  ValidatorType.required: 'Non-empty; `true` for checkboxes.',
  ValidatorType.email: 'Email format.',
  ValidatorType.phone: '7–15 digits, optional `+`, spaces, dashes.',
  ValidatorType.url: 'URL, with or without scheme.',
  ValidatorType.number: 'Whole number.',
  ValidatorType.decimal: 'Decimal number.',
  ValidatorType.min: 'Number ≥ `value`.',
  ValidatorType.max: 'Number ≤ `value`.',
  ValidatorType.minLength: 'At least `value` characters.',
  ValidatorType.maxLength: 'At most `value` characters.',
  ValidatorType.regex: 'Matches the pattern in `value` (alias `pattern`).',
  ValidatorType.matchField:
      'Equals the field named in `value` (alias `match`).',
  ValidatorType.passwordStrength:
      'Upper, lower, digit and symbol; length ≥ `value` (8).',
  ValidatorType.minItems:
      'At least `value` selections / entries. Fails on empty too.',
  ValidatorType.maxItems: 'At most `value` selections / entries.',
  ValidatorType.custom:
      'Function passed to the controller\'s '
      '`customValidators` under `name`.',
};

/// Condition operators. KEEP IN SYNC with [ConditionOperator].
const Map<ConditionOperator, String> operatorDocs = {
  ConditionOperator.equals: 'Equal (numbers compare numerically).',
  ConditionOperator.notEquals: 'Not equal.',
  ConditionOperator.greaterThan: 'Greater than.',
  ConditionOperator.greaterThanOrEqual: 'Greater than or equal.',
  ConditionOperator.lessThan: 'Less than.',
  ConditionOperator.lessThanOrEqual: 'Less than or equal.',
  ConditionOperator.contains: 'List contains value / text contains substring.',
  ConditionOperator.notContains: 'Opposite of `contains`.',
  ConditionOperator.startsWith: 'Text starts with value.',
  ConditionOperator.endsWith: 'Text ends with value.',
  ConditionOperator.isEmpty: 'Null, empty text or empty list.',
  ConditionOperator.isNotEmpty: 'Has a value.',
  ConditionOperator.isIn: 'Value is one of the list.',
  ConditionOperator.notIn: 'Value is none of the list.',
  ConditionOperator.isTrue: 'Value is `true`.',
  ConditionOperator.isFalse: 'Value is not `true`.',
};

/// The string-valued enums JSON accepts, with their allowed values.
final Map<String, List<String>> jsonEnumDocs = {
  'keyboardType (KeyboardKind)': [for (final v in KeyboardKind.values) v.name],
  'textInputAction (InputActionKind)': [
    for (final v in InputActionKind.values) v.name,
  ],
  'textCase (TextCase)': [for (final v in TextCase.values) v.name],
  'preset (TextPreset)': [for (final v in TextPreset.values) v.name],
  'phoneFormat (PhoneFormat)': [for (final v in PhoneFormat.values) v.name],
  'optionLayout (OptionLayout)': [for (final v in OptionLayout.values) v.name],
  'style.labelBehavior (LabelBehavior)': [
    for (final v in LabelBehavior.values) v.name,
  ],
  'style.labelPosition (LabelPosition)': [
    for (final v in LabelPosition.values) v.name,
  ],
  'style.variant (FieldStyleVariant)': [
    for (final v in FieldStyleVariant.values) v.name,
  ],
  'image source (MediaSource)': [for (final v in MediaSource.values) v.name],
};
