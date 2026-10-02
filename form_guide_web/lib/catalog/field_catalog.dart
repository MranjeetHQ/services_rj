import 'package:services_rj/services_rj.dart';

/// Documentation for one [FieldType].
///
/// KEEP IN SYNC: `test/catalog_sync_test.dart` fails when a [FieldType] has
/// no entry here, or when an example does not parse to its own type.
class FieldDoc {
  const FieldDoc({
    required this.type,
    required this.category,
    required this.summary,
    required this.valueType,
    required this.example,
    this.keys = const {},
    this.pluggable = false,
    this.aliases = const [],
  });

  final FieldType type;
  final FieldCategory category;
  final String summary;

  /// What `getFormData()` contains for this field.
  final String valueType;

  /// Type-specific JSON keys (beyond the common properties) → meaning.
  final Map<String, String> keys;

  /// A complete field JSON shown and rendered live in the guide.
  final Map<String, dynamic> example;

  /// Needs an adapter registered with `FieldFactory.register`.
  final bool pluggable;

  /// Other accepted `type` spellings.
  final List<String> aliases;
}

enum FieldCategory {
  text('Text input'),
  dateTime('Date & time'),
  selection('Selection'),
  toggle('Toggles'),
  numeric('Sliders & numbers'),
  media('Media & files'),
  location('Location pickers'),
  layout('Display & layout'),
  extendable('Extendable forms'),
  pluggable('Pluggable adapters');

  const FieldCategory(this.title);
  final String title;
}

const _choices = [
  {'label': 'Bronze', 'value': 'bronze'},
  {'label': 'Silver', 'value': 'silver'},
  {'label': 'Gold', 'value': 'gold'},
];

const List<FieldDoc> fieldCatalog = [
  // ------------------------------------------------------------- text
  FieldDoc(
    type: FieldType.text,
    category: FieldCategory.text,
    summary: 'Single-line text input. The default when `type` is missing.',
    valueType: 'String',
    example: {
      'type': 'text',
      'id': 'nickname',
      'label': 'Nickname',
      'hint': 'What should we call you?',
      'prefixIcon': 'person',
      'textCase': 'words',
      'validators': ['required'],
    },
  ),
  FieldDoc(
    type: FieldType.textarea,
    category: FieldCategory.text,
    summary: 'Multi-line text. `maxLines` (alias `rows`) defaults to 4.',
    valueType: 'String',
    example: {
      'type': 'textarea',
      'id': 'bio',
      'label': 'Short bio',
      'maxLines': 4,
      'maxLength': 200,
      'showCounter': true,
    },
  ),
  FieldDoc(
    type: FieldType.password,
    category: FieldCategory.text,
    summary: 'Obscured input with a show / hide toggle.',
    valueType: 'String',
    example: {
      'type': 'password',
      'id': 'secret',
      'label': 'Password',
      'prefixIcon': 'lock',
      'validators': ['required', 'passwordStrength'],
    },
  ),
  FieldDoc(
    type: FieldType.email,
    category: FieldCategory.text,
    summary: 'Email keyboard. Pair with the `email` validator.',
    valueType: 'String',
    example: {
      'type': 'email',
      'id': 'workEmail',
      'label': 'Work email',
      'prefixIcon': 'email',
      'validators': ['email'],
    },
  ),
  FieldDoc(
    type: FieldType.number,
    category: FieldCategory.text,
    summary: 'Integer input; digits only. Stored as `int` when it parses.',
    valueType: 'int',
    example: {
      'type': 'number',
      'id': 'seats',
      'label': 'Seats needed',
      'validators': [
        {'type': 'min', 'value': 1},
        {'type': 'max', 'value': 12},
      ],
    },
  ),
  FieldDoc(
    type: FieldType.decimal,
    category: FieldCategory.text,
    summary: 'Decimal input. Stored as `double` when it parses.',
    valueType: 'double',
    example: {
      'type': 'decimal',
      'id': 'weight',
      'label': 'Parcel weight',
      'suffixText': 'kg',
    },
  ),
  FieldDoc(
    type: FieldType.phone,
    category: FieldCategory.text,
    summary:
        'Phone keyboard; allows digits, `+`, spaces, dashes, brackets. Add '
        '`countryCode` for an optional country code picker.',
    valueType: 'String (`+<code><digits>` when `countryCode` is on)',
    keys: {
      'countryCode':
          '`true` or a default country (`"IN"`, `"+44"`) to show a country '
          'code picker, searchable by country name, ISO or dial code. The value becomes `+919876543210`; read it split '
          'with `controller.getPhone(id)`. Also works on text fields using '
          'the `mobile` or `phone` preset.',
      'countryCodes':
          'Limit the picker to these ISO or dial codes, in this order, e.g. '
          '`["IN", "US", "+44"]`.',
      'phoneFormat':
          '`combined` (default): one value `+919876543210`. `separate`: the '
          'number and its code under two keys, `mobile` and '
          '`mobileCountryCode`. Overrides the controller default.',
      'countryCodeKey':
          'Name of the code key in the `separate` format (default '
          '`<id>CountryCode`).',
    },
    example: {
      'type': 'phone',
      'id': 'mobile',
      'label': 'Mobile',
      'countryCode': 'IN',
      'countryCodes': ['IN', 'US', 'GB', 'AE', 'SG'],
      'validators': ['phone'],
    },
  ),
  FieldDoc(
    type: FieldType.url,
    category: FieldCategory.text,
    summary: 'URL keyboard. Pair with the `url` validator.',
    valueType: 'String',
    example: {
      'type': 'url',
      'id': 'site',
      'label': 'Website',
      'prefixIcon': 'link',
      'validators': ['url'],
    },
  ),
  FieldDoc(
    type: FieldType.search,
    category: FieldCategory.text,
    summary: 'Text input with the keyboard search action.',
    valueType: 'String',
    example: {
      'type': 'search',
      'id': 'query',
      'label': 'Search the catalogue',
      'prefixIcon': 'search',
      'style': {'variant': 'rounded'},
    },
  ),
  FieldDoc(
    type: FieldType.otp,
    category: FieldCategory.text,
    summary: 'Centered numeric one-time-password input.',
    valueType: 'String',
    keys: {'length': 'Number of digits (default 6).'},
    example: {
      'type': 'otp',
      'id': 'code',
      'label': 'Verification code',
      'length': 4,
    },
  ),
  FieldDoc(
    type: FieldType.pin,
    category: FieldCategory.text,
    summary: 'Like `otp`, but obscured.',
    valueType: 'String',
    keys: {'length': 'Number of digits (default 6).'},
    example: {'type': 'pin', 'id': 'pin', 'label': 'Card PIN', 'length': 4},
  ),
  FieldDoc(
    type: FieldType.readOnly,
    category: FieldCategory.text,
    summary: 'Displays a value the user cannot edit; still part of the data.',
    valueType: 'any',
    aliases: ['readonly'],
    example: {
      'type': 'readOnly',
      'id': 'orderId',
      'label': 'Order number',
      'initialValue': 'ORD-20931',
    },
  ),
  FieldDoc(
    type: FieldType.hidden,
    category: FieldCategory.text,
    summary: 'Renders nothing but is always included in the data.',
    valueType: 'any',
    example: {'type': 'hidden', 'id': 'source', 'initialValue': 'guide'},
  ),

  // -------------------------------------------------------- date/time
  FieldDoc(
    type: FieldType.date,
    category: FieldCategory.dateTime,
    summary: 'Date picker. Stored as `YYYY-MM-DD`.',
    valueType: 'String (ISO date)',
    keys: {
      'firstDate': 'Earliest selectable date (ISO).',
      'lastDate': 'Latest selectable date (ISO).',
    },
    example: {
      'type': 'date',
      'id': 'checkIn',
      'label': 'Check-in',
      'firstDate': '2026-01-01',
      'lastDate': '2027-12-31',
    },
  ),
  FieldDoc(
    type: FieldType.time,
    category: FieldCategory.dateTime,
    summary: 'Time picker. Stored as `HH:mm`.',
    valueType: 'String',
    example: {'type': 'time', 'id': 'pickupAt', 'label': 'Pickup time'},
  ),
  FieldDoc(
    type: FieldType.datetime,
    category: FieldCategory.dateTime,
    summary: 'Date then time. Stored as `YYYY-MM-DDTHH:mm`.',
    valueType: 'String',
    keys: {'firstDate': 'Earliest date.', 'lastDate': 'Latest date.'},
    example: {'type': 'datetime', 'id': 'slot', 'label': 'Appointment'},
  ),

  // -------------------------------------------------------- selection
  FieldDoc(
    type: FieldType.dropdown,
    category: FieldCategory.selection,
    summary: 'Single choice from a menu. Supports `allowCustomOptions`.',
    valueType: 'option value',
    example: {
      'type': 'dropdown',
      'id': 'membership',
      'label': 'Membership',
      'options': _choices,
      'allowCustomOptions': true,
    },
  ),
  FieldDoc(
    type: FieldType.multiselect,
    category: FieldCategory.selection,
    summary: 'Several choices picked in a dialog. Honors `maxItems`.',
    valueType: 'List',
    aliases: ['multiSelect', 'multi_select'],
    example: {
      'type': 'multiselect',
      'id': 'languages',
      'label': 'Languages spoken',
      'options': ['English', 'Hindi', 'Tamil', 'Marathi'],
      'maxItems': 3,
    },
  ),
  FieldDoc(
    type: FieldType.radioGroup,
    category: FieldCategory.selection,
    summary:
        'One choice from visible radio buttons. Supports every '
        '`optionLayout`.',
    valueType: 'option value',
    example: {
      'type': 'radioGroup',
      'id': 'delivery',
      'label': 'Delivery speed',
      'optionLayout': 'vertical',
      'options': [
        {'label': 'Standard', 'value': 'std', 'description': '3–5 days'},
        {'label': 'Express', 'value': 'exp', 'description': 'Next day'},
      ],
    },
  ),
  FieldDoc(
    type: FieldType.checkboxGroup,
    category: FieldCategory.selection,
    summary: 'Several choices as checkboxes. Supports `minItems`, `maxItems`.',
    valueType: 'List',
    example: {
      'type': 'checkboxGroup',
      'id': 'amenities',
      'label': 'Amenities',
      'optionLayout': 'grid',
      'columns': 2,
      'options': ['Wi-Fi', 'Parking', 'Breakfast', 'Pool'],
    },
  ),
  FieldDoc(
    type: FieldType.chips,
    category: FieldCategory.selection,
    summary: 'Filter chips. Single choice, or several with `multiple`.',
    valueType: 'option value, or List with `multiple`',
    keys: {'multiple': 'Allow several selections.'},
    aliases: ['multiSelectChips'],
    example: {
      'type': 'chips',
      'id': 'interests',
      'label': 'Interests',
      'multiple': true,
      'allowCustomOptions': true,
      'options': ['Hiking', 'Cooking', 'Chess'],
    },
  ),
  FieldDoc(
    type: FieldType.segmented,
    category: FieldCategory.selection,
    summary: 'Material 3 segmented button. Good with enums.',
    valueType: 'option value, or List with `multiple`',
    keys: {'multiple': 'Allow several selections.'},
    example: {
      'type': 'segmented',
      'id': 'unit',
      'label': 'Units',
      'options': [
        {'label': 'Metric', 'value': 'metric'},
        {'label': 'Imperial', 'value': 'imperial'},
      ],
    },
  ),
  FieldDoc(
    type: FieldType.toggleButtons,
    category: FieldCategory.selection,
    summary: 'A row of toggle buttons.',
    valueType: 'option value, or List with `multiple`',
    keys: {'multiple': 'Allow several selections.'},
    example: {
      'type': 'toggleButtons',
      'id': 'align',
      'label': 'Alignment',
      'options': ['Left', 'Center', 'Right'],
    },
  ),
  FieldDoc(
    type: FieldType.autocomplete,
    category: FieldCategory.selection,
    summary: 'Type to filter local options; free text is kept until picked.',
    valueType: 'option value or String',
    example: {
      'type': 'autocomplete',
      'id': 'airport',
      'label': 'Departure airport',
      'options': [
        {'label': 'Mumbai (BOM)', 'value': 'BOM'},
        {'label': 'Delhi (DEL)', 'value': 'DEL'},
        {'label': 'Bengaluru (BLR)', 'value': 'BLR'},
      ],
    },
  ),
  FieldDoc(
    type: FieldType.typeahead,
    category: FieldCategory.selection,
    summary: 'Autocomplete whose options usually come from `optionsLoader`.',
    valueType: 'option value or String',
    example: {
      'type': 'typeahead',
      'id': 'library',
      'label': 'Package',
      'options': ['dio', 'riverpod', 'go_router', 'freezed'],
    },
  ),

  // ----------------------------------------------------------- toggles
  FieldDoc(
    type: FieldType.checkbox,
    category: FieldCategory.toggle,
    summary: 'Single checkbox. `required` means it must be ticked.',
    valueType: 'bool',
    example: {
      'type': 'checkbox',
      'id': 'agree',
      'label': 'I accept the house rules',
      'required': true,
    },
  ),
  FieldDoc(
    type: FieldType.switchField,
    category: FieldCategory.toggle,
    summary: 'Material switch. Write it as `"switch"` in JSON.',
    valueType: 'bool',
    aliases: ['switch'],
    example: {
      'type': 'switch',
      'id': 'reminders',
      'label': 'Send reminders',
      'helperText': 'One day before',
      'style': {'activeColor': '#00897B'},
    },
  ),
  FieldDoc(
    type: FieldType.radio,
    category: FieldCategory.toggle,
    summary: 'A single radio button bound to a bool.',
    valueType: 'bool',
    example: {'type': 'radio', 'id': 'primary', 'label': 'Make this primary'},
  ),

  // ----------------------------------------------------------- numeric
  FieldDoc(
    type: FieldType.slider,
    category: FieldCategory.numeric,
    summary: 'Single-value slider.',
    valueType: 'double',
    keys: {
      'min': 'Minimum (0).',
      'max': 'Maximum (100).',
      'divisions': 'Steps.',
    },
    example: {
      'type': 'slider',
      'id': 'volume',
      'label': 'Volume',
      'min': 0,
      'max': 10,
      'divisions': 10,
      'initialValue': 4,
    },
  ),
  FieldDoc(
    type: FieldType.rangeSlider,
    category: FieldCategory.numeric,
    summary: 'Two-thumb range slider.',
    valueType: 'List [start, end]',
    keys: {'min': 'Minimum.', 'max': 'Maximum.', 'divisions': 'Steps.'},
    aliases: ['range'],
    example: {
      'type': 'rangeSlider',
      'id': 'budget',
      'label': 'Budget (thousands)',
      'min': 0,
      'max': 50,
      'divisions': 10,
    },
  ),
  FieldDoc(
    type: FieldType.rating,
    category: FieldCategory.numeric,
    summary: 'Star rating. Tapping the current star clears it.',
    valueType: 'int',
    keys: {'count': 'Number of stars (5).'},
    example: {
      'type': 'rating',
      'id': 'stars',
      'label': 'Rate the stay',
      'count': 5,
    },
  ),
  FieldDoc(
    type: FieldType.stepper,
    category: FieldCategory.numeric,
    summary: 'Numeric value with − / + buttons.',
    valueType: 'num',
    keys: {'min': 'Minimum.', 'max': 'Maximum.', 'step': 'Increment (1).'},
    example: {
      'type': 'stepper',
      'id': 'nights',
      'label': 'Nights',
      'min': 1,
      'max': 14,
      'initialValue': 2,
    },
  ),
  FieldDoc(
    type: FieldType.colorPicker,
    category: FieldCategory.numeric,
    summary: 'Pick from a palette. Stored as `#rrggbb`.',
    valueType: 'String',
    keys: {'colors': 'Custom palette as hex strings.'},
    example: {
      'type': 'colorPicker',
      'id': 'accent',
      'label': 'Accent colour',
      'colors': ['#00897B', '#5E35B1', '#F4511E', '#3949AB'],
    },
  ),

  // ------------------------------------------------------------- media
  FieldDoc(
    type: FieldType.image,
    category: FieldCategory.media,
    summary: 'Gallery and/or camera picker with thumbnails.',
    valueType: 'String path, or List with `multiple`',
    keys: {
      'source': '`gallery`, `camera` or `both` (default).',
      'multiple': 'Pick several images.',
      'maxImages': 'Cap for `multiple`.',
      'imageQuality': '0–100 compression.',
      'maxWidth': 'Downscale bound.',
      'maxHeight': 'Downscale bound.',
      'preferredCamera': '`front` or `rear`.',
      'video': 'Pick a video instead.',
      'maxDurationSeconds': 'Video length cap.',
      'previewSize': 'Thumbnail size (72).',
    },
    example: {
      'type': 'image',
      'id': 'photos',
      'label': 'Room photos',
      'source': 'gallery',
      'multiple': true,
      'maxImages': 3,
    },
  ),
  FieldDoc(
    type: FieldType.camera,
    category: FieldCategory.media,
    summary: 'Camera-only variant of `image`.',
    valueType: 'String path',
    keys: {'preferredCamera': '`front` or `rear`.'},
    example: {
      'type': 'camera',
      'id': 'selfie',
      'label': 'Selfie',
      'preferredCamera': 'front',
    },
  ),
  FieldDoc(
    type: FieldType.file,
    category: FieldCategory.media,
    summary: 'Document picker with extension / MIME filters.',
    valueType: 'String path, or List with `multiple`',
    keys: {
      'multiple': 'Pick several files.',
      'maxFiles': 'Cap for `multiple`.',
      'extensions': 'e.g. `["pdf", "docx"]`.',
      'mimeTypes': 'e.g. `["application/pdf"]`.',
    },
    example: {
      'type': 'file',
      'id': 'invoice',
      'label': 'Invoice',
      'extensions': ['pdf'],
    },
  ),

  // ---------------------------------------------------------- location
  FieldDoc(
    type: FieldType.country,
    category: FieldCategory.location,
    summary: 'Dropdown meant for countries; options or `optionsLoader`.',
    valueType: 'option value',
    example: {
      'type': 'country',
      'id': 'country',
      'label': 'Country',
      'options': [
        {'label': 'India', 'value': 'IN'},
        {'label': 'Nepal', 'value': 'NP'},
      ],
    },
  ),
  FieldDoc(
    type: FieldType.state,
    category: FieldCategory.location,
    summary:
        'Dropdown usually with `dependsOn: ["country"]`, so its value '
        'clears and options reload when the country changes.',
    valueType: 'option value',
    example: {
      'type': 'state',
      'id': 'region',
      'label': 'State',
      'dependsOn': ['country'],
      'options': ['Gujarat', 'Kerala', 'Punjab'],
    },
  ),
  FieldDoc(
    type: FieldType.city,
    category: FieldCategory.location,
    summary: 'Dropdown usually with `dependsOn: ["state"]`.',
    valueType: 'option value',
    example: {
      'type': 'city',
      'id': 'town',
      'label': 'City',
      'options': ['Surat', 'Kochi', 'Amritsar'],
    },
  ),

  // ------------------------------------------------------------ layout
  FieldDoc(
    type: FieldType.label,
    category: FieldCategory.layout,
    summary: 'Static text. Not part of the data.',
    valueType: '—',
    example: {
      'type': 'label',
      'id': 'note',
      'label': 'All prices include tax.',
    },
  ),
  FieldDoc(
    type: FieldType.sectionHeader,
    category: FieldCategory.layout,
    summary: 'Bold coloured heading between sections.',
    valueType: '—',
    aliases: ['section'],
    example: {'type': 'sectionHeader', 'id': 'h1', 'label': 'Billing details'},
  ),
  FieldDoc(
    type: FieldType.divider,
    category: FieldCategory.layout,
    summary: 'Horizontal rule.',
    valueType: '—',
    example: {'type': 'divider', 'id': 'line'},
  ),
  FieldDoc(
    type: FieldType.spacer,
    category: FieldCategory.layout,
    summary: 'Vertical gap; size it with `height` (16).',
    valueType: '—',
    example: {'type': 'spacer', 'id': 'gap', 'height': 24},
  ),
  FieldDoc(
    type: FieldType.group,
    category: FieldCategory.layout,
    summary:
        'Visual group of child `fields`. Children keep their own ids '
        'in the flat data. `containerColor` gives it a background.',
    valueType: '— (children are top-level keys)',
    example: {
      'type': 'group',
      'id': 'contact',
      'label': 'Emergency contact',
      'style': {'containerColor': '#EEF3FF'},
      'fields': [
        {'type': 'text', 'id': 'contactName', 'label': 'Name'},
        {'type': 'phone', 'id': 'contactPhone', 'label': 'Phone'},
      ],
    },
  ),
  FieldDoc(
    type: FieldType.expansion,
    category: FieldCategory.layout,
    summary: 'Collapsible tile with child `fields`.',
    valueType: '— (children are top-level keys)',
    keys: {'expanded': 'Start open.'},
    example: {
      'type': 'expansion',
      'id': 'advanced',
      'label': 'Advanced options',
      'expanded': true,
      'fields': [
        {'type': 'switch', 'id': 'beta', 'label': 'Join beta programme'},
      ],
    },
  ),

  // -------------------------------------------------------- extendable
  FieldDoc(
    type: FieldType.repeater,
    category: FieldCategory.extendable,
    summary:
        'Extendable section: users add, remove and reorder entries; '
        'each entry is a copy of the child `fields` with its own validation.',
    valueType: 'List<Map>',
    aliases: ['repeatable', 'list'],
    keys: {
      'fields': 'Template fields for one entry (alias `itemFields`).',
      'minItems': 'Minimum entries; remove is disabled at the minimum.',
      'maxItems': 'Maximum entries; add is hidden at the maximum.',
      'initialItems': 'Blank entries for a new form (minItems, else 1).',
      'itemLabel': 'Entry title; `{index}` is the 1-based position.',
      'addLabel': 'Add button text.',
      'reorderable': 'Show move up / down buttons.',
    },
    example: {
      'type': 'repeater',
      'id': 'children',
      'label': 'Children travelling',
      'itemLabel': 'Child {index}',
      'addLabel': 'Add a child',
      'minItems': 1,
      'maxItems': 3,
      'reorderable': true,
      'fields': [
        {'type': 'text', 'id': 'childName', 'label': 'Name', 'required': true},
        {'type': 'number', 'id': 'childAge', 'label': 'Age'},
      ],
    },
  ),

  // --------------------------------------------------------- pluggable
  FieldDoc(
    type: FieldType.signature,
    category: FieldCategory.pluggable,
    summary:
        'Signature pad. Register an adapter with '
        '`FieldFactory.register(FieldType.signature, builder)`.',
    valueType: 'adapter-defined',
    pluggable: true,
    example: {'type': 'signature', 'id': 'sign', 'label': 'Sign here'},
  ),
  FieldDoc(
    type: FieldType.qrScanner,
    category: FieldCategory.pluggable,
    summary: 'QR scanner adapter.',
    valueType: 'adapter-defined',
    pluggable: true,
    example: {'type': 'qrScanner', 'id': 'ticketQr', 'label': 'Scan ticket'},
  ),
  FieldDoc(
    type: FieldType.barcodeScanner,
    category: FieldCategory.pluggable,
    summary: 'Barcode scanner adapter.',
    valueType: 'adapter-defined',
    pluggable: true,
    example: {'type': 'barcodeScanner', 'id': 'sku', 'label': 'Scan SKU'},
  ),
  FieldDoc(
    type: FieldType.richText,
    category: FieldCategory.pluggable,
    summary: 'Rich text editor adapter; falls back to a textarea.',
    valueType: 'String (fallback)',
    pluggable: true,
    example: {'type': 'richText', 'id': 'article', 'label': 'Article body'},
  ),
  FieldDoc(
    type: FieldType.markdown,
    category: FieldCategory.pluggable,
    summary: 'Markdown editor adapter; falls back to a textarea.',
    valueType: 'String (fallback)',
    pluggable: true,
    example: {'type': 'markdown', 'id': 'readme', 'label': 'Release notes'},
  ),
  FieldDoc(
    type: FieldType.htmlEditor,
    category: FieldCategory.pluggable,
    summary: 'HTML editor adapter; falls back to a textarea.',
    valueType: 'String (fallback)',
    pluggable: true,
    aliases: ['html'],
    example: {'type': 'htmlEditor', 'id': 'emailBody', 'label': 'Email body'},
  ),
  FieldDoc(
    type: FieldType.custom,
    category: FieldCategory.pluggable,
    summary:
        'Your own widget: `FieldFactory.registerCustom("name", builder)` '
        'then `{"type": "custom", "customType": "name"}`. Unknown `type` '
        'strings also land here.',
    valueType: 'builder-defined',
    pluggable: true,
    keys: {'customType': 'Registered builder name (alias `widget`).'},
    example: {
      'type': 'custom',
      'id': 'mapPin',
      'label': 'Drop a pin',
      'customType': 'map_picker',
    },
  ),
];

FieldDoc docFor(FieldType type) =>
    fieldCatalog.firstWhere((d) => d.type == type);
