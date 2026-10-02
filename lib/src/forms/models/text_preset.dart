import 'country_dial_code.dart';
import 'field_enums.dart';

/// Ready-made behaviour for a text input: keyboard, allowed characters,
/// capitalization, length limit and a format check.
///
/// Set it on a field with `"preset": "pan"` (the enum name, or a name added
/// with [TextPresets.register]). Anything the field sets itself
/// (`keyboardType`, `textCase`, `maxLength`, `hint`, `prefixIcon`) wins over
/// the preset; the format check is always added. Empty values pass, so
/// combine with `"required": true` to make the field mandatory.
///
/// [custom] has no rules of its own: it takes the field's own `regex`,
/// `keyboardType`, `textCase` and `maxLength`, and reports `presetMessage`
/// when the pattern does not match.
enum TextPreset {
  /// Person name: letters (any script), spaces, apostrophes, dots, hyphens.
  name,

  /// Indian mobile number: 10 digits starting with 6-9.
  mobile,

  /// Landline or international number: 7-15 digits, optional `+`.
  phone,

  /// Indian PAN: `ABCPE1234F`.
  pan,

  /// Aadhaar number: 12 digits, first digit 2-9, Verhoeff checksum.
  aadhaar,

  /// GSTIN: 15 characters with a valid state code and check character.
  gst,

  /// Bank IFSC code: `HDFC0001234`.
  ifsc,

  /// Indian PIN code: 6 digits, not starting with 0.
  pincode,

  /// Vehicle registration number: `MH12AB1234`.
  vehicleNumber,

  /// Voter ID (EPIC): 3 letters and 7 digits.
  voterId,

  /// Indian passport number: letter followed by 7 digits.
  passport,

  /// UPI id: `name@bank`.
  upiId,

  /// Your own pattern: set `regex` (and optionally `presetMessage`).
  custom;

  /// Parses a JSON preset name; `null` when it is not a built-in preset.
  static TextPreset? tryParse(Object? raw) {
    if (raw is TextPreset) return raw;
    final key = raw?.toString().replaceAll(RegExp('[-_ ]'), '').toLowerCase();
    for (final p in values) {
      if (p.name.toLowerCase() == key) return p;
    }
    return null;
  }
}

/// What a preset contributes to a text input.
class TextPresetSpec {
  /// Creates a spec. [pattern] is matched against the value after
  /// [normalize]; [check] runs afterwards for rules a pattern cannot express
  /// (checksums).
  const TextPresetSpec({
    required this.message,
    this.pattern,
    this.check,
    this.normalize,
    this.hint,
    this.icon,
    this.keyboard,
    this.textCase,
    this.maxLength,
    this.allowedChars,
    this.unicode = false,
    this.nationalPatterns,
    this.otherNationalPattern,
    this.otherMessage,
  });

  /// Error shown when the value is invalid.
  final String message;

  /// Pattern the whole value must match.
  final String? pattern;

  /// Extra check on the normalized value; return `false` when invalid.
  final bool Function(String value)? check;

  /// Cleans the value before validation (e.g. strips spaces).
  final String Function(String value)? normalize;

  /// Placeholder shown when the field has no `hint`.
  final String? hint;

  /// JSON icon name used when the field has no `prefixIcon`.
  final String? icon;

  /// Keyboard used when the field sets no `keyboardType`.
  final KeyboardKind? keyboard;

  /// Capitalization used when the field sets no `textCase`.
  final TextCase? textCase;

  /// Length limit used when the field sets no `maxLength`.
  final int? maxLength;

  /// Single-character class (regex source, no brackets) that typing is
  /// restricted to; `null` allows any character.
  final String? allowedChars;

  /// Compile [pattern] and [allowedChars] with Unicode support.
  final bool unicode;

  /// For numbers stored with a country code (`+919876543210`): the national
  /// number pattern per dial code. Codes not listed use
  /// [otherNationalPattern].
  final Map<String, String>? nationalPatterns;

  /// National number pattern for dial codes missing from
  /// [nationalPatterns]; `null` accepts any national number.
  final String? otherNationalPattern;

  /// Error for a number with another country's code. Defaults to [message].
  final String? otherMessage;

  /// True when [value] carries a country code this spec has rules for.
  bool _isInternational(String value) =>
      nationalPatterns != null && value.trim().startsWith('+');

  /// The message to show for the invalid [value].
  String messageFor(String value) {
    if (_isInternational(value)) {
      final dial = CountryDialCodes.split(value).dial;
      if (dial != null && nationalPatterns!.containsKey(dial)) return message;
      return otherMessage ?? message;
    }
    return message;
  }

  /// Whether [value] satisfies this spec. Empty values are valid.
  bool isValid(String value) {
    if (_isInternational(value)) {
      final parts = CountryDialCodes.split(value);
      final pattern = nationalPatterns![parts.dial] ?? otherNationalPattern;
      return pattern == null || RegExp(pattern).hasMatch(parts.national);
    }
    var v = (normalize?.call(value) ?? value).trim();
    if (textCase == TextCase.upper) v = v.toUpperCase();
    if (textCase == TextCase.lower) v = v.toLowerCase();
    if (v.isEmpty) return true;
    if (pattern != null && !RegExp(pattern!, unicode: unicode).hasMatch(v)) {
      return false;
    }
    return check?.call(v) ?? true;
  }
}

/// Registry of text presets. Built-in presets can be looked up by
/// [TextPreset]; add your own reusable ones with [register].
class TextPresets {
  const TextPresets._();

  static final Map<String, TextPresetSpec> _custom = {};
  static final Map<String, String> _customNames = {};

  /// Adds a named preset usable as `"preset": "<name>"`. A name equal to a
  /// built-in preset replaces its behaviour everywhere.
  static void register(String name, TextPresetSpec spec) {
    _custom[_key(name)] = spec;
    _customNames[_key(name)] = name;
  }

  /// Every usable preset name: built-ins plus registered ones.
  static Iterable<String> get names => {
    for (final p in TextPreset.values) p.name,
    ..._customNames.values,
  };

  /// The spec for a JSON preset name, or `null` for unknown names and for
  /// [TextPreset.custom] (which has no built-in rules).
  static TextPresetSpec? resolve(String? name) {
    if (name == null) return null;
    final registered = _custom[_key(name)];
    if (registered != null) return registered;
    final preset = TextPreset.tryParse(name);
    return preset == null ? null : builtIn[preset];
  }

  static String _key(String name) =>
      name.replaceAll(RegExp('[-_ ]'), '').toLowerCase();

  static String _stripSpaces(String v) => v.replaceAll(RegExp(r'[\s-]'), '');

  /// Built-in specs.
  static final Map<TextPreset, TextPresetSpec> builtIn = {
    TextPreset.name: const TextPresetSpec(
      message: 'Enter a valid name',
      pattern: r"^\p{L}[\p{L}\p{M} .'\-]{1,59}$",
      unicode: true,
      allowedChars: r"\p{L}\p{M} .'\-",
      keyboard: KeyboardKind.text,
      textCase: TextCase.words,
      maxLength: 60,
      icon: 'person',
      hint: 'As on your ID',
    ),
    TextPreset.mobile: const TextPresetSpec(
      message: 'Enter a 10-digit mobile number starting with 6-9',
      pattern: r'^[6-9]\d{9}$',
      nationalPatterns: {'+91': r'^[6-9]\d{9}$'},
      otherNationalPattern: r'^\d{6,14}$',
      otherMessage: 'Enter a valid mobile number',
      allowedChars: r'\d',
      keyboard: KeyboardKind.phone,
      maxLength: 10,
      icon: 'phone',
      hint: '9876543210',
    ),
    TextPreset.phone: TextPresetSpec(
      message: 'Enter a valid phone number (7-15 digits)',
      pattern: r'^\+?[\d\s\-()]+$',
      check: (v) {
        final digits = v.replaceAll(RegExp(r'\D'), '').length;
        return digits >= 7 && digits <= 15;
      },
      allowedChars: r'\d+\-\s()',
      keyboard: KeyboardKind.phone,
      maxLength: 18,
      icon: 'phone',
      hint: '+91 22 1234 5678',
    ),
    TextPreset.pan: const TextPresetSpec(
      message: 'Enter a valid PAN, e.g. ABCPE1234F',
      pattern: r'^[A-Z]{3}[ABCFGHLJPT][A-Z]\d{4}[A-Z]$',
      allowedChars: r'A-Za-z0-9',
      keyboard: KeyboardKind.text,
      textCase: TextCase.upper,
      maxLength: 10,
      icon: 'badge',
      hint: 'ABCPE1234F',
    ),
    TextPreset.aadhaar: TextPresetSpec(
      message: 'Enter a valid 12-digit Aadhaar number',
      pattern: r'^[2-9]\d{11}$',
      check: _verhoeff,
      normalize: _stripSpaces,
      allowedChars: r'\d\s',
      keyboard: KeyboardKind.number,
      maxLength: 14,
      icon: 'badge',
      hint: '2345 6789 0124',
    ),
    TextPreset.gst: TextPresetSpec(
      message: 'Enter a valid 15-character GSTIN',
      pattern: r'^(0[1-9]|[12]\d|3[0-8])[A-Z]{5}\d{4}[A-Z][1-9A-Z]Z[0-9A-Z]$',
      check: _gstChecksum,
      allowedChars: r'A-Za-z0-9',
      keyboard: KeyboardKind.text,
      textCase: TextCase.upper,
      maxLength: 15,
      icon: 'tag',
      hint: '22AAAAA0000A1ZC',
    ),
    TextPreset.ifsc: const TextPresetSpec(
      message: 'Enter a valid IFSC, e.g. HDFC0001234',
      pattern: r'^[A-Z]{4}0[A-Z0-9]{6}$',
      allowedChars: r'A-Za-z0-9',
      keyboard: KeyboardKind.text,
      textCase: TextCase.upper,
      maxLength: 11,
      icon: 'home',
      hint: 'HDFC0001234',
    ),
    TextPreset.pincode: const TextPresetSpec(
      message: 'Enter a valid 6-digit PIN code',
      pattern: r'^[1-9]\d{5}$',
      allowedChars: r'\d',
      keyboard: KeyboardKind.number,
      maxLength: 6,
      icon: 'location',
      hint: '400001',
    ),
    TextPreset.vehicleNumber: const TextPresetSpec(
      message: 'Enter a valid vehicle number, e.g. MH12AB1234',
      pattern: r'^[A-Z]{2}\d{1,2}[A-Z]{0,3}\d{4}$',
      normalize: _stripSpaces,
      allowedChars: r'A-Za-z0-9\s\-',
      keyboard: KeyboardKind.text,
      textCase: TextCase.upper,
      maxLength: 13,
      icon: 'car',
      hint: 'MH12AB1234',
    ),
    TextPreset.voterId: const TextPresetSpec(
      message: 'Enter a valid voter ID, e.g. ABC1234567',
      pattern: r'^[A-Z]{3}\d{7}$',
      allowedChars: r'A-Za-z0-9',
      keyboard: KeyboardKind.text,
      textCase: TextCase.upper,
      maxLength: 10,
      icon: 'badge',
      hint: 'ABC1234567',
    ),
    TextPreset.passport: const TextPresetSpec(
      message: 'Enter a valid passport number, e.g. K1234567',
      pattern: r'^[A-PR-WY][1-9]\d{5}[1-9]$',
      allowedChars: r'A-Za-z0-9',
      keyboard: KeyboardKind.text,
      textCase: TextCase.upper,
      maxLength: 8,
      icon: 'flag',
      hint: 'K1234567',
    ),
    TextPreset.upiId: const TextPresetSpec(
      message: 'Enter a valid UPI id, e.g. name@bank',
      pattern: r'^[A-Za-z0-9.\-_]{2,64}@[A-Za-z]{2,32}$',
      allowedChars: r'A-Za-z0-9.\-_@',
      keyboard: KeyboardKind.email,
      textCase: TextCase.lower,
      maxLength: 100,
      icon: 'money',
      hint: 'name@bank',
    ),
  };

  // ------------------------------------------------------------ checksums

  static const List<List<int>> _d = [
    [0, 1, 2, 3, 4, 5, 6, 7, 8, 9],
    [1, 2, 3, 4, 0, 6, 7, 8, 9, 5],
    [2, 3, 4, 0, 1, 7, 8, 9, 5, 6],
    [3, 4, 0, 1, 2, 8, 9, 5, 6, 7],
    [4, 0, 1, 2, 3, 9, 5, 6, 7, 8],
    [5, 9, 8, 7, 6, 0, 4, 3, 2, 1],
    [6, 5, 9, 8, 7, 1, 0, 4, 3, 2],
    [7, 6, 5, 9, 8, 2, 1, 0, 4, 3],
    [8, 7, 6, 5, 9, 3, 2, 1, 0, 4],
    [9, 8, 7, 6, 5, 4, 3, 2, 1, 0],
  ];

  static const List<List<int>> _p = [
    [0, 1, 2, 3, 4, 5, 6, 7, 8, 9],
    [1, 5, 7, 6, 2, 8, 3, 0, 9, 4],
    [5, 8, 0, 3, 7, 9, 6, 1, 4, 2],
    [8, 9, 1, 6, 0, 4, 3, 5, 2, 7],
    [9, 4, 5, 3, 1, 2, 6, 8, 7, 0],
    [4, 2, 8, 6, 5, 7, 3, 9, 0, 1],
    [2, 7, 9, 3, 8, 0, 6, 4, 1, 5],
    [7, 0, 4, 6, 9, 1, 3, 2, 5, 8],
  ];

  /// Verhoeff checksum, used by Aadhaar numbers.
  static bool _verhoeff(String digits) {
    var c = 0;
    final reversed = digits.split('').reversed.toList();
    for (var i = 0; i < reversed.length; i++) {
      c = _d[c][_p[i % 8][int.parse(reversed[i])]];
    }
    return c == 0;
  }

  /// GSTIN check character (position 15, base-36 weighted sum).
  static bool _gstChecksum(String gstin) {
    const chars = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    var sum = 0;
    for (var i = 0; i < 14; i++) {
      final code = chars.indexOf(gstin[i]);
      if (code < 0) return false;
      final product = code * (i.isEven ? 1 : 2);
      sum += product ~/ 36 + product % 36;
    }
    return chars[(36 - sum % 36) % 36] == gstin[14];
  }
}
