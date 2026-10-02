import 'package:services_rj/services_rj.dart';

/// Adds the reusable `employeeId` preset used by [textPresetsLabForm].
/// Safe to call more than once.
void registerLabPresets() {
  TextPresets.register(
    'employeeId',
    const TextPresetSpec(
      message: 'Employee id looks like E-12345',
      pattern: r'^E-\d{5}$',
      textCase: TextCase.upper,
      maxLength: 7,
      hint: 'E-12345',
      icon: 'work',
    ),
  );
  TextPresets.register(
    'lotNumber',
    TextPresetSpec(
      message: 'Lot numbers are 6 digits whose digit sum is divisible by 3',
      pattern: r'^\d{6}$',
      // Rules a pattern cannot express go in `check`.
      check: (v) => v.split('').map(int.parse).reduce((a, b) => a + b) % 3 == 0,
      allowedChars: r'\d',
      keyboard: KeyboardKind.number,
      maxLength: 6,
      hint: '123456',
    ),
  );
}

/// Every [TextPreset], plus a `custom` pattern and two registered presets.
/// Valid samples are in each helper text so the checks are easy to try.
const Map<String, dynamic> textPresetsLabForm = {
  'id': 'text_presets_lab',
  'style': {'variant': 'outlined', 'borderRadius': 12},
  'fields': [
    {'type': 'sectionHeader', 'id': 'h_person', 'label': 'Person'},
    {
      'type': 'text',
      'id': 'fullName',
      'label': 'Full name',
      'preset': 'name',
      'required': true,
      'helperText': 'Letters in any script; digits are blocked while typing',
    },
    {
      'type': 'text',
      'id': 'mobile',
      'label': 'Mobile number',
      'preset': 'mobile',
      'required': true,
      'helperText': '10 digits starting 6-9, e.g. 9876543210',
    },
    {
      'type': 'text',
      'id': 'mobileIntl',
      'label': 'Mobile with country code',
      'preset': 'mobile',
      'countryCode': true,
      'helperText':
          'Optional picker; +91 keeps the 6-9 rule, others 6-14 digits',
    },
    {
      'type': 'phone',
      'id': 'officeIntl',
      'label': 'Office phone (limited countries)',
      'countryCode': 'GB',
      'countryCodes': ['IN', 'GB', 'US', 'AE', 'SG'],
      'phoneFormat': 'separate',
      'helperText': 'phoneFormat separate: number + CountryCode key',
    },
    {
      'type': 'text',
      'id': 'landline',
      'label': 'Phone number',
      'preset': 'phone',
      'helperText': '7-15 digits, + and spaces allowed',
    },
    {'type': 'sectionHeader', 'id': 'h_ids', 'label': 'Identity documents'},
    {
      'type': 'text',
      'id': 'pan',
      'label': 'PAN',
      'preset': 'pan',
      'helperText': 'Upper-cased as you type, e.g. ABCPE1234F',
    },
    {
      'type': 'text',
      'id': 'aadhaar',
      'label': 'Aadhaar number',
      'preset': 'aadhaar',
      'helperText': 'Checksum checked, e.g. 2345 6789 0124',
    },
    {
      'type': 'text',
      'id': 'voter',
      'label': 'Voter ID',
      'preset': 'voterId',
      'helperText': 'e.g. ABC1234567',
    },
    {
      'type': 'text',
      'id': 'passport',
      'label': 'Passport number',
      'preset': 'passport',
      'helperText': 'e.g. K1234567',
    },
    {'type': 'sectionHeader', 'id': 'h_biz', 'label': 'Business and bank'},
    {
      'type': 'text',
      'id': 'gstin',
      'label': 'GST number',
      'preset': 'gst',
      'presetMessage': 'That GSTIN does not look right',
      'helperText': 'Check character verified, 27AAPFU0939F1ZV',
    },
    {
      'type': 'text',
      'id': 'ifsc',
      'label': 'IFSC code',
      'preset': 'ifsc',
      'helperText': 'e.g. HDFC0001234',
    },
    {
      'type': 'text',
      'id': 'upi',
      'label': 'UPI id',
      'preset': 'upiId',
      'helperText': 'e.g. meera@okhdfcbank',
    },
    {'type': 'sectionHeader', 'id': 'h_addr', 'label': 'Address'},
    {
      'type': 'text',
      'id': 'pincode',
      'label': 'PIN code',
      'preset': 'pincode',
      'helperText': '6 digits, e.g. 400001',
    },
    {
      'type': 'text',
      'id': 'vehicle',
      'label': 'Vehicle number',
      'preset': 'vehicleNumber',
      'helperText': 'e.g. MH12AB1234',
    },
    {'type': 'sectionHeader', 'id': 'h_custom', 'label': 'Custom options'},
    {
      'type': 'text',
      'id': 'ticket',
      'label': 'Ticket reference',
      'preset': 'custom',
      'regex': r'^TKT-\d{4}$',
      'presetMessage': 'Use the format TKT-1234',
      'textCase': 'upper',
      'maxLength': 8,
      'prefixIcon': 'tag',
      'hint': 'TKT-1234',
      'helperText': 'preset custom: your regex and your message',
    },
    {
      'type': 'text',
      'id': 'employee',
      'label': 'Employee id',
      'preset': 'employeeId',
      'helperText': 'Registered once with TextPresets.register',
    },
    {
      'type': 'text',
      'id': 'lot',
      'label': 'Lot number',
      'preset': 'lotNumber',
      'helperText': 'Registered preset with a check function, e.g. 123456',
    },
    {
      'type': 'text',
      'id': 'panLower',
      'label': 'PAN, typed in lower case',
      'preset': 'pan',
      'textCase': 'lower',
      'helperText': 'Field settings win over the preset, rules still apply',
    },
  ],
};
