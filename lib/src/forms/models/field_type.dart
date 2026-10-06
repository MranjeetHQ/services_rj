/// Every field type the package can render from JSON.
///
/// The guide website (`form_guide_web/`) documents every value of this enum;
/// a test there fails when a new type is added without documentation.
///
/// Types marked *pluggable* (signature, qrScanner, barcodeScanner,
/// richText, markdown, htmlEditor) render a registered adapter widget —
/// see `FieldFactory.register` — so the core package stays
/// dependency-free. Image, camera and file picking are built in (powered
/// by Flutter's official `image_picker` / `file_selector` plugins) and
/// can still be overridden the same way.
enum FieldType {
  /// Single line text input.
  text,

  /// Multiline text area.
  textarea,

  /// Obscured password input.
  password,

  /// Email input with email keyboard.
  email,

  /// Integer number input.
  number,

  /// Decimal number input.
  decimal,

  /// Phone number input.
  phone,

  /// URL input.
  url,

  /// Search input with search action.
  search,

  /// Date picker field.
  date,

  /// Time picker field.
  time,

  /// Combined date and time picker.
  datetime,

  /// Single-select dropdown.
  dropdown,

  /// Multi-select dropdown (checkbox list in a dialog).
  multiselect,

  /// Dropdown with a search box in a bottom sheet, dialog or full-screen
  /// picker. Options come from a local list, an API loaded once, or a
  /// search-as-you-type API source; `"multiple": true` selects several.
  searchableDropdown,

  /// Single checkbox.
  checkbox,

  /// Group of checkboxes bound to a list value.
  checkboxGroup,

  /// Single radio button.
  radio,

  /// Group of radio buttons.
  radioGroup,

  /// Material switch.
  switchField,

  /// Single value slider.
  slider,

  /// Range slider bound to a two-element list value.
  rangeSlider,

  /// Choice chips (single or multi via `extra.multiple`).
  chips,

  /// Toggle buttons row.
  toggleButtons,

  /// Material 3 segmented button.
  segmented,

  /// Star rating field.
  rating,

  /// Numeric stepper with +/- buttons.
  stepper,

  /// Color picker (preset palette dialog).
  colorPicker,

  /// Image picker — built-in gallery/camera picking with previews.
  image,

  /// Camera capture — built-in, camera-only variant of [image].
  camera,

  /// File picker — built-in document picking with extension filters.
  file,

  /// Signature pad — pluggable adapter.
  signature,

  /// One-time-password boxes.
  otp,

  /// Pin code boxes (obscured OTP).
  pin,

  /// Country picker (dropdown fed by options / async loader).
  country,

  /// State picker (usually conditional on country).
  state,

  /// City picker (usually conditional on state).
  city,

  /// Autocomplete over local options.
  autocomplete,

  /// Debounced async autocomplete.
  typeahead,

  /// QR scanner — pluggable adapter.
  qrScanner,

  /// Barcode scanner — pluggable adapter.
  barcodeScanner,

  /// Rich text editor — pluggable adapter (falls back to textarea).
  richText,

  /// Markdown editor — pluggable adapter (falls back to textarea).
  markdown,

  /// HTML editor — pluggable adapter (falls back to textarea).
  htmlEditor,

  /// Hidden field: participates in data, renders nothing.
  hidden,

  /// Read-only display of a value.
  readOnly,

  /// Static label (display only).
  label,

  /// Horizontal divider (display only).
  divider,

  /// Vertical spacer (display only).
  spacer,

  /// Section header (display only).
  sectionHeader,

  /// Expansion tile containing child fields.
  expansion,

  /// Visual grouping of child fields (children keep their own ids in the
  /// flat form data).
  group,

  /// Extendable section: a list of entries, each a copy of the child
  /// `fields`, that users add and remove at runtime. Stored as a
  /// `List<Map<String, dynamic>>`.
  repeater,

  /// Developer-registered custom widget.
  custom;

  /// Parses a JSON type string (snake_case, kebab-case or camelCase).
  static FieldType fromString(String raw) {
    final normalized = raw
        .replaceAllMapped(
          RegExp('[-_]([a-z])'),
          (m) => m.group(1)!.toUpperCase(),
        )
        .trim();
    const aliases = <String, FieldType>{
      'switch': FieldType.switchField,
      'readonly': FieldType.readOnly,
      'multiSelect': FieldType.multiselect,
      'range': FieldType.rangeSlider,
      'section': FieldType.sectionHeader,
      'html': FieldType.htmlEditor,
      'repeatable': FieldType.repeater,
      'list': FieldType.repeater,
      'multiSelectChips': FieldType.chips,
      'searchable': FieldType.searchableDropdown,
      'dropdownSearch': FieldType.searchableDropdown,
      'searchSelect': FieldType.searchableDropdown,
    };
    return aliases[normalized] ??
        FieldType.values.firstWhere(
          (t) => t.name.toLowerCase() == normalized.toLowerCase(),
          orElse: () => FieldType.custom,
        );
  }
}
