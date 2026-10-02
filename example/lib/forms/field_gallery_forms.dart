// JSON definitions for the field gallery: together they use every
// `FieldType` the package can render.

/// Text-like inputs: text, textarea, password, email, number, decimal,
/// phone, url, search, otp and pin.
const Map<String, dynamic> textInputsGalleryForm = {
  'id': 'gallery_text',
  'style': {'variant': 'outlined', 'borderRadius': 10},
  'fields': [
    {'type': 'sectionHeader', 'id': 'h_text', 'label': 'Typing fields'},
    {
      'type': 'text',
      'id': 'boatName',
      'label': 'Name your boat',
      'hint': 'e.g. Sea Biscuit',
      'prefixIcon': 'person',
      'textCase': 'words',
      'maxLength': 24,
      'showCounter': true,
      'validators': ['required'],
    },
    {
      'type': 'textarea',
      'id': 'voyageLog',
      'label': 'Voyage log',
      'helperText': 'Six lines max, 240 characters.',
      'maxLines': 6,
      'minLines': 3,
      'maxLength': 240,
      'showCounter': true,
    },
    {
      'type': 'password',
      'id': 'harbourPass',
      'label': 'Harbour password',
      'prefixIcon': 'lock',
      'validators': ['passwordStrength'],
    },
    {
      'type': 'email',
      'id': 'crewEmail',
      'label': 'Crew email',
      'prefixIcon': 'email',
      'validators': ['email'],
    },
    {
      'type': 'number',
      'id': 'lifejackets',
      'label': 'Lifejackets on board',
      'helperText': 'Integers only (1 to 20).',
      'validators': [
        {'type': 'min', 'value': 1},
        {'type': 'max', 'value': 20},
      ],
    },
    {
      'type': 'decimal',
      'id': 'draftDepth',
      'label': 'Hull draft',
      'suffixText': 'm',
    },
    {
      'type': 'phone',
      'id': 'dockPhone',
      'label': 'Dock office phone',
      'prefixText': '+44 ',
      'validators': ['phone'],
    },
    {
      'type': 'url',
      'id': 'tideSite',
      'label': 'Tide table website',
      'prefixIcon': 'link',
      'validators': ['url'],
    },
    {
      'type': 'search',
      'id': 'portSearch',
      'label': 'Search ports',
      'prefixIcon': 'search',
      'style': {'variant': 'rounded'},
    },
    {
      'type': 'otp',
      'id': 'gateCode',
      'label': 'Gate code (OTP boxes)',
      'length': 4,
    },
    {
      'type': 'pin',
      'id': 'lockerPin',
      'label': 'Locker PIN (obscured)',
      'length': 4,
    },
  ],
};

/// Date/time pickers plus sliders, rating, stepper and colour picker.
const Map<String, dynamic> dateNumericGalleryForm = {
  'id': 'gallery_date_numeric',
  'style': {'variant': 'outlined', 'borderRadius': 10},
  'fields': [
    {'type': 'sectionHeader', 'id': 'h_when', 'label': 'Date and time'},
    {
      'type': 'date',
      'id': 'sailDate',
      'label': 'Sail date',
      'firstDate': '2026-01-01',
      'lastDate': '2030-12-31',
    },
    {'type': 'time', 'id': 'castOff', 'label': 'Cast-off time'},
    {'type': 'datetime', 'id': 'returnBy', 'label': 'Back in port by'},
    {'type': 'sectionHeader', 'id': 'h_num', 'label': 'Numbers'},
    {
      'type': 'slider',
      'id': 'sailPower',
      'label': 'Sail trim',
      'min': 0,
      'max': 10,
      'divisions': 10,
      'initialValue': 4,
    },
    {
      'type': 'rangeSlider',
      'id': 'windWindow',
      'label': 'Comfortable wind (knots)',
      'min': 0,
      'max': 40,
      'divisions': 8,
      'initialValue': [8, 24],
    },
    {
      'type': 'rating',
      'id': 'harbourScore',
      'label': 'Rate the harbour',
      'count': 6,
    },
    {
      'type': 'stepper',
      'id': 'bunks',
      'label': 'Bunks needed',
      'min': 1,
      'max': 8,
      'step': 1,
      'initialValue': 2,
    },
    {
      'type': 'colorPicker',
      'id': 'hullColour',
      'label': 'Hull colour',
      'colors': ['#0B6E99', '#C2410C', '#4D7C0F', '#6D28D9', '#111827'],
    },
  ],
};

/// Every choice-style field: dropdowns, groups, chips, autocomplete and the
/// country / state / city trio.
const Map<String, dynamic> selectionGalleryForm = {
  'id': 'gallery_selection',
  'style': {'variant': 'outlined', 'borderRadius': 10},
  'fields': [
    {'type': 'sectionHeader', 'id': 'h_menus', 'label': 'Menus'},
    {
      'type': 'dropdown',
      'id': 'vesselClass',
      'label': 'Vessel class',
      'allowCustomOptions': true,
      'customOptionLabel': 'Other class...',
      'options': [
        {'label': 'Dinghy', 'value': 'dinghy', 'icon': 'sailing'},
        {'label': 'Catamaran', 'value': 'cat', 'icon': 'directions_boat'},
        {'label': 'Yacht', 'value': 'yacht', 'icon': 'star'},
      ],
    },
    {
      'type': 'multiselect',
      'id': 'skills',
      'label': 'Crew skills',
      'maxItems': 3,
      'options': ['Navigation', 'Knots', 'First aid', 'Radio', 'Cooking'],
    },
    {'type': 'sectionHeader', 'id': 'h_toggles', 'label': 'Toggles'},
    {
      'type': 'checkbox',
      'id': 'safetyBriefing',
      'label': 'I attended the safety briefing',
      'required': true,
    },
    {
      'type': 'switch',
      'id': 'weatherAlerts',
      'label': 'Weather alerts',
      'helperText': 'Push a warning when gusts pass 30 knots',
      'style': {'activeColor': '#0B6E99'},
    },
    {'type': 'radio', 'id': 'skipperFlag', 'label': 'I am the skipper'},
    {'type': 'sectionHeader', 'id': 'h_groups', 'label': 'Option groups'},
    {
      'type': 'radioGroup',
      'id': 'berth',
      'label': 'Berth type',
      'optionLayout': 'vertical',
      'initialValue': 'pontoon',
      'options': [
        {
          'label': 'Pontoon',
          'value': 'pontoon',
          'description': 'Walk-on access, power included',
          'icon': 'anchor',
        },
        {
          'label': 'Mooring buoy',
          'value': 'buoy',
          'description': 'Cheaper; tender required',
          'icon': 'sailing',
        },
      ],
    },
    {
      'type': 'checkboxGroup',
      'id': 'extras',
      'label': 'Extras',
      'optionLayout': 'grid',
      'columns': 2,
      'minItems': 1,
      'maxItems': 3,
      'options': ['Fuel', 'Fresh water', 'Shore power', 'Pump-out'],
    },
    {
      'type': 'chips',
      'id': 'tags',
      'label': 'Trip tags',
      'multiple': true,
      'allowCustomOptions': true,
      'options': ['Fishing', 'Racing', 'Family', 'Night sail'],
    },
    {
      'type': 'toggleButtons',
      'id': 'watch',
      'label': 'Watch shift',
      'options': ['Dawn', 'Day', 'Dusk', 'Night'],
    },
    {
      'type': 'segmented',
      'id': 'speedUnit',
      'label': 'Speed unit',
      'initialValue': 'kn',
      'options': [
        {'label': 'Knots', 'value': 'kn'},
        {'label': 'km/h', 'value': 'kmh'},
        {'label': 'mph', 'value': 'mph'},
      ],
    },
    {'type': 'sectionHeader', 'id': 'h_search', 'label': 'Type to find'},
    {
      'type': 'autocomplete',
      'id': 'homePort',
      'label': 'Home port',
      'options': [
        {'label': 'Falmouth', 'value': 'FAL'},
        {'label': 'Plymouth', 'value': 'PLY'},
        {'label': 'Portsmouth', 'value': 'POR'},
      ],
    },
    {
      'type': 'typeahead',
      'id': 'chartApp',
      'label': 'Chart plotter app',
      'options': ['SeaNav', 'WindRose', 'TideLine', 'BuoyFinder'],
    },
    {'type': 'sectionHeader', 'id': 'h_geo', 'label': 'Country, state, city'},
    {
      'type': 'country',
      'id': 'flagCountry',
      'label': 'Flag country',
      'options': [
        {'label': 'India', 'value': 'IN'},
        {'label': 'United Kingdom', 'value': 'GB'},
      ],
    },
    {
      'type': 'state',
      'id': 'flagState',
      'label': 'State / region',
      'dependsOn': ['flagCountry'],
      'options': ['Gujarat', 'Kerala', 'Cornwall', 'Devon'],
    },
    {
      'type': 'city',
      'id': 'flagCity',
      'label': 'City',
      'dependsOn': ['flagState'],
      'options': ['Surat', 'Kochi', 'Truro', 'Exeter'],
    },
  ],
};

/// Image, camera and file pickers (platform plugins; not exercised in tests).
const Map<String, dynamic> mediaGalleryForm = {
  'id': 'gallery_media',
  'style': {'variant': 'outlined', 'borderRadius': 10},
  'fields': [
    {
      'type': 'label',
      'id': 'media_note',
      'label': 'These use the device gallery, camera and file dialogs.',
    },
    {
      'type': 'image',
      'id': 'hullPhotos',
      'label': 'Hull photos',
      'source': 'gallery',
      'multiple': true,
      'maxImages': 4,
      'imageQuality': 80,
      'maxWidth': 1600,
      'previewSize': 80,
    },
    {
      'type': 'camera',
      'id': 'skipperSelfie',
      'label': 'Skipper selfie',
      'preferredCamera': 'front',
    },
    {
      'type': 'file',
      'id': 'insurance',
      'label': 'Insurance certificate',
      'extensions': ['pdf', 'png'],
    },
    {
      'type': 'file',
      'id': 'manuals',
      'label': 'Equipment manuals',
      'multiple': true,
      'maxFiles': 3,
      'extensions': ['pdf', 'docx', 'txt'],
    },
  ],
};

/// Display-only types and containers: label, divider, spacer, section
/// header, hidden, readOnly, expansion, group and repeater.
const Map<String, dynamic> layoutGalleryForm = {
  'id': 'gallery_layout',
  'style': {'variant': 'outlined', 'borderRadius': 10},
  'fields': [
    {'type': 'sectionHeader', 'id': 'h_display', 'label': 'Display only'},
    {
      'type': 'label',
      'id': 'intro',
      'label': 'Labels, dividers and spacers never appear in submitted data.',
    },
    {'type': 'divider', 'id': 'rule'},
    {'type': 'spacer', 'id': 'gap', 'height': 24},
    {
      'type': 'readOnly',
      'id': 'bookingRef',
      'label': 'Booking reference',
      'initialValue': 'HB-4821',
    },
    {'type': 'hidden', 'id': 'channel', 'initialValue': 'gallery'},
    {'type': 'sectionHeader', 'id': 'h_containers', 'label': 'Containers'},
    {
      'type': 'group',
      'id': 'emergency',
      'label': 'Shore contact',
      'style': {'containerColor': '#E6F0F5'},
      'fields': [
        {'type': 'text', 'id': 'shoreName', 'label': 'Name'},
        {'type': 'phone', 'id': 'shorePhone', 'label': 'Phone'},
      ],
    },
    {
      'type': 'expansion',
      'id': 'advanced',
      'label': 'Advanced settings',
      'expanded': true,
      'fields': [
        {'type': 'switch', 'id': 'autopilot', 'label': 'Autopilot allowed'},
        {
          'type': 'number',
          'id': 'maxHeel',
          'label': 'Max heel angle',
          'suffixText': 'deg',
        },
      ],
    },
    {
      'type': 'repeater',
      'id': 'waypoints',
      'label': 'Waypoints',
      'itemLabel': 'Waypoint {index}',
      'addLabel': 'Add waypoint',
      'minItems': 1,
      'maxItems': 4,
      'reorderable': true,
      'fields': [
        {
          'type': 'text',
          'id': 'wpName',
          'label': 'Name',
          'validators': ['required'],
        },
        {'type': 'decimal', 'id': 'wpDistance', 'label': 'Distance (nm)'},
      ],
    },
  ],
};

/// Pluggable types, rendered by the demo adapters in
/// `demos/pluggable_adapters.dart`.
const Map<String, dynamic> adaptersGalleryForm = {
  'id': 'gallery_adapters',
  'style': {'variant': 'outlined', 'borderRadius': 10},
  'fields': [
    {
      'type': 'signature',
      'id': 'captainSignature',
      'label': 'Captain signature',
      'validators': ['required'],
    },
    {'type': 'qrScanner', 'id': 'dockPass', 'label': 'Scan dock pass'},
    {'type': 'barcodeScanner', 'id': 'gearTag', 'label': 'Scan gear tag'},
    {'type': 'richText', 'id': 'tripStory', 'label': 'Trip story'},
    {'type': 'markdown', 'id': 'handoverNotes', 'label': 'Handover notes'},
    {'type': 'htmlEditor', 'id': 'inviteBody', 'label': 'Invite email body'},
    {
      'type': 'custom',
      'id': 'tripMood',
      'label': 'How was the trip?',
      'customType': 'mood_picker',
    },
  ],
};

/// Every gallery form, for tests and the gallery pages.
const List<Map<String, dynamic>> allGalleryForms = [
  textInputsGalleryForm,
  dateNumericGalleryForm,
  selectionGalleryForm,
  mediaGalleryForm,
  layoutGalleryForm,
  adaptersGalleryForm,
];
