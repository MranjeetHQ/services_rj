/// Typed enums for every string-valued form option.
///
/// JSON keeps using plain strings (`"keyboardType": "email"`); Dart code can
/// use these enums instead so typos are compile errors. Every enum has a
/// tolerant `fromString` that accepts camelCase, snake_case and kebab-case.
library;

String _normalize(String raw) => raw
    .trim()
    .replaceAllMapped(
      RegExp('[-_ ]([a-zA-Z])'),
      (m) => m.group(1)!.toUpperCase(),
    )
    .toLowerCase();

T? _byName<T extends Enum>(
  List<T> values,
  Object? raw, [
  Map<String, T> aliases = const {},
]) {
  if (raw == null) return null;
  if (raw is T) return raw;
  final key = _normalize(raw.toString());
  for (final entry in aliases.entries) {
    if (_normalize(entry.key) == key) return entry.value;
  }
  for (final v in values) {
    if (v.name.toLowerCase() == key) return v;
  }
  return null;
}

/// Built-in validator types. Custom validators registered through
/// `ValidatorRegistry.register` use their own string names.
enum ValidatorType {
  /// Value must be non-empty (and `true` for checkboxes).
  required,

  /// Email format.
  email,

  /// Phone format (7–15 digits, optional `+`).
  phone,

  /// URL format.
  url,

  /// Integer.
  number,

  /// Decimal number.
  decimal,

  /// Numeric minimum (`value`).
  min,

  /// Numeric maximum (`value`).
  max,

  /// Minimum text length (`value`).
  minLength,

  /// Maximum text length (`value`).
  maxLength,

  /// Regular-expression match (`value` is the pattern).
  regex,

  /// Must equal another field (`value` is the other field id).
  matchField,

  /// Upper, lower, digit and symbol; minimum length `value` (default 8).
  passwordStrength,

  /// Minimum number of selected items / repeater entries (`value`).
  minItems,

  /// Maximum number of selected items / repeater entries (`value`).
  maxItems,

  /// Programmatic validator registered on the controller by `name`.
  custom;

  /// Parses a validator type name; null for unknown (custom) names.
  static ValidatorType? fromString(Object? raw) => _byName(values, raw, const {
    'pattern': ValidatorType.regex,
    'match': ValidatorType.matchField,
  });
}

/// Operators available in `visibleWhen` / `enabledWhen` / `requiredWhen`.
///
/// Extra operators can be added with `ConditionEvaluator.registerOperator`.
enum ConditionOperator {
  /// `actual == value` (numbers compare numerically).
  equals('equals', ['eq', '==']),

  /// `actual != value`.
  notEquals('notEquals', ['ne', '!=']),

  /// `actual > value`.
  greaterThan('greaterThan', ['gt', '>']),

  /// `actual >= value`.
  greaterThanOrEqual('greaterThanOrEqual', ['gte', '>=']),

  /// `actual < value`.
  lessThan('lessThan', ['lt', '<']),

  /// `actual <= value`.
  lessThanOrEqual('lessThanOrEqual', ['lte', '<=']),

  /// List contains value, or string contains substring.
  contains('contains', []),

  /// Negation of [contains].
  notContains('notContains', []),

  /// String starts with value.
  startsWith('startsWith', []),

  /// String ends with value.
  endsWith('endsWith', []),

  /// Null, empty string or empty list.
  isEmpty('isEmpty', []),

  /// Negation of [isEmpty].
  isNotEmpty('isNotEmpty', []),

  /// Actual is one of the values in a list.
  isIn('in', ['isIn', 'oneOf']),

  /// Actual is none of the values in a list.
  notIn('notIn', ['noneOf']),

  /// Actual is `true`.
  isTrue('isTrue', ['checked']),

  /// Actual is not `true`.
  isFalse('isFalse', ['unchecked']);

  const ConditionOperator(this.jsonName, this.aliases);

  /// Name written to JSON.
  final String jsonName;

  /// Alternative spellings accepted when parsing.
  final List<String> aliases;

  /// Parses an operator; null for unknown (possibly custom) operators.
  static ConditionOperator? fromString(Object? raw) {
    if (raw == null) return null;
    if (raw is ConditionOperator) return raw;
    final s = raw.toString().trim();
    for (final op in values) {
      if (op.jsonName == s || op.aliases.contains(s)) return op;
    }
    return _byName(values, s);
  }
}

/// Keyboard shown for text-like fields.
enum KeyboardKind {
  /// Default text keyboard.
  text,

  /// Digits only.
  number,

  /// Digits with a decimal separator.
  decimal,

  /// Phone pad.
  phone,

  /// Email keyboard.
  email,

  /// URL keyboard.
  url,

  /// Multiline text with a newline key.
  multiline;

  /// Parses a keyboard name.
  static KeyboardKind? fromString(Object? raw) => _byName(values, raw);
}

/// Keyboard action button for text-like fields.
enum InputActionKind {
  /// Move focus to the next field.
  next,

  /// Close the keyboard.
  done,

  /// Search.
  search,

  /// Send.
  send,

  /// Go.
  go,

  /// Insert a newline (multiline fields).
  newline;

  /// Parses an input action name.
  static InputActionKind? fromString(Object? raw) => _byName(values, raw);
}

/// How the options of a radio group, checkbox group or chips are laid out.
enum OptionLayout {
  /// One option per row (default for radio / checkbox groups).
  vertical,

  /// All options on one scrollable row.
  horizontal,

  /// Options wrap onto as many rows as needed (default for chips).
  wrap,

  /// Fixed-column grid; set the column count with `"columns"`.
  grid;

  /// Parses a layout name.
  static OptionLayout? fromString(Object? raw) => _byName(values, raw);
}

/// Letter-case handling for text input.
enum TextCase {
  /// Leave input as typed.
  none,

  /// Force UPPER CASE (e.g. codes, licence plates).
  upper,

  /// Force lower case (e.g. usernames).
  lower,

  /// Capitalize Each Word (keyboard hint only).
  words,

  /// Capitalize the first letter of sentences (keyboard hint only).
  sentences;

  /// Parses a text-case name.
  static TextCase? fromString(Object? raw) => _byName(values, raw, const {
    'uppercase': TextCase.upper,
    'lowercase': TextCase.lower,
  });
}

/// Where a floating label sits.
enum LabelBehavior {
  /// Floats when focused or filled.
  auto,

  /// Always floats above the field.
  always,

  /// Never floats; acts as a placeholder.
  never;

  /// Parses a label behavior name.
  static LabelBehavior? fromString(Object? raw) => _byName(values, raw);
}

/// Where a field's label is shown (style key `labelPosition`).
enum LabelPosition {
  /// Inside the field border, floating up when focused or filled (default).
  floating,

  /// A static label above the field. Never clipped or animated, which also
  /// suits dense layouts and long labels.
  above,

  /// No label. The label text becomes the hint so the field stays
  /// understandable (and keeps its accessibility label).
  hidden;

  /// Parses a label position name.
  static LabelPosition? fromString(Object? raw) => _byName(values, raw);
}

/// How the controller reports a phone field that has a country code picker
/// (`getFormData`, `onChanged`, `onSubmit`).
enum PhoneFormat {
  /// One value with the code in front: `{"mobile": "+919876543210"}`.
  combined,

  /// Two values: `{"mobile": "9876543210", "mobileCountryCode": "+91"}`.
  separate;

  /// Parses a phone format name.
  static PhoneFormat? fromString(Object? raw) => _byName(values, raw);
}

/// Where an `image` field picks from.
enum MediaSource {
  /// Photo library only.
  gallery,

  /// Camera only.
  camera,

  /// Ask the user each time.
  both;

  /// Parses a media source name.
  static MediaSource? fromString(Object? raw) => _byName(values, raw);
}

/// Which mark a field label shows (style key `requiredMark`).
enum RequiredMark {
  /// A red `*` after the label of required fields (default).
  asterisk,

  /// "(optional)" after the label of optional fields; required fields stay
  /// plain. Suits forms where most fields are required.
  optional,

  /// `*` on required fields and "(optional)" on the others.
  both,

  /// No mark.
  none;

  /// Parses a required mark name.
  static RequiredMark? fromString(Object? raw) => _byName(values, raw, const {
    'star': RequiredMark.asterisk,
    'required': RequiredMark.asterisk,
  });
}

/// How the options of a radio group, checkbox group, or a single checkbox /
/// radio / switch are drawn (field key `optionStyle`).
enum OptionStyle {
  /// Plain list tiles with the control in front (default).
  standard,

  /// Each option in its own bordered card; the selected card is tinted and
  /// outlined. Good for options with a description.
  card,

  /// Compact pill per option. Wraps onto several rows by default.
  chip,

  /// Button-like boxes without a visible control; the selected box is
  /// filled. Good for short labels in a row or grid.
  button;

  /// Parses an option style name.
  static OptionStyle? fromString(Object? raw) => _byName(values, raw, const {
    'default': OptionStyle.standard,
    'pill': OptionStyle.chip,
    'tile': OptionStyle.card,
  });
}

/// Shape of checkbox controls (field key `controlShape`).
enum ControlShape {
  /// Square corners.
  square,

  /// Slightly rounded corners (Material default).
  rounded,

  /// Round checkbox.
  circle;

  /// Parses a control shape name.
  static ControlShape? fromString(Object? raw) => _byName(values, raw);
}

/// Where the checkbox / radio control sits in an option (field key
/// `controlPosition`).
enum ControlPosition {
  /// Before the label (default).
  leading,

  /// After the label.
  trailing,

  /// Hidden; the option's background and border show the selection.
  none;

  /// Parses a control position name.
  static ControlPosition? fromString(Object? raw) => _byName(values, raw);
}

/// How the searchable dropdown's list opens (field key `pickerStyle`).
enum PickerStyle {
  /// Rounded modal bottom sheet with a drag handle (default).
  bottomSheet,

  /// Centered dialog. Suits tablets, desktop and web.
  dialog,

  /// Full-screen page. Suits very long lists on phones.
  fullScreen;

  /// Parses a picker style name.
  static PickerStyle? fromString(Object? raw) => _byName(values, raw, const {
    'sheet': PickerStyle.bottomSheet,
    'modal': PickerStyle.bottomSheet,
    'page': PickerStyle.fullScreen,
  });
}

/// How a multi-select dropdown shows its selection when closed (field key
/// `selectedDisplay`).
enum SelectedDisplay {
  /// Removable chips (default).
  chips,

  /// Labels joined with commas.
  text,

  /// "3 selected".
  count;

  /// Parses a selected display name.
  static SelectedDisplay? fromString(Object? raw) => _byName(values, raw);
}

/// Named spacing values accepted wherever the JSON takes a padding, margin
/// or spacing (`"padding": "standard"`).
enum FormSpacing {
  /// 0 logical pixels.
  none(0),

  /// 8 logical pixels.
  compact(8),

  /// 16 logical pixels, the Material standard page margin.
  standard(16),

  /// 24 logical pixels.
  comfortable(24),

  /// 32 logical pixels.
  spacious(32);

  const FormSpacing(this.value);

  /// Size in logical pixels.
  final double value;

  /// Parses a spacing name.
  static FormSpacing? fromString(Object? raw) => _byName(values, raw, const {
    'small': FormSpacing.compact,
    'medium': FormSpacing.standard,
    'large': FormSpacing.comfortable,
  });

  /// Reads a number or a spacing name (`16`, `"standard"`).
  static double? parse(Object? raw) {
    if (raw is num) return raw.toDouble();
    return fromString(raw)?.value;
  }
}

/// Shared parsing helper for any app-defined enum.
///
/// ```dart
/// enum Plan { free, pro }
/// enumFromString(Plan.values, 'PRO'); // Plan.pro
/// ```
T? enumFromString<T extends Enum>(List<T> values, Object? raw) =>
    _byName(values, raw);
