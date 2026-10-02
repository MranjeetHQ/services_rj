import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/field_config.dart';
import '../models/field_enums.dart';
import '../models/field_type.dart';
import '../models/text_preset.dart';

/// Shared helpers mapping JSON strings to Flutter types.
class FieldUtils {
  const FieldUtils._();

  /// Resolves a keyboard type from JSON (falls back per field type).
  static TextInputType keyboardType(FieldConfig f) {
    switch (f.keyboardType ?? TextPresets.resolve(f.preset)?.keyboard) {
      case KeyboardKind.number:
        return TextInputType.number;
      case KeyboardKind.decimal:
        return const TextInputType.numberWithOptions(decimal: true);
      case KeyboardKind.phone:
        return TextInputType.phone;
      case KeyboardKind.email:
        return TextInputType.emailAddress;
      case KeyboardKind.url:
        return TextInputType.url;
      case KeyboardKind.multiline:
        return TextInputType.multiline;
      case KeyboardKind.text:
        return TextInputType.text;
      case null:
        break;
    }
    switch (f.type) {
      case FieldType.email:
        return TextInputType.emailAddress;
      case FieldType.number:
        return TextInputType.number;
      case FieldType.decimal:
        return const TextInputType.numberWithOptions(decimal: true);
      case FieldType.phone:
        return TextInputType.phone;
      case FieldType.url:
        return TextInputType.url;
      case FieldType.textarea:
      case FieldType.richText:
      case FieldType.markdown:
      case FieldType.htmlEditor:
        return TextInputType.multiline;
      default:
        return TextInputType.text;
    }
  }

  /// Resolves the input action from JSON.
  static TextInputAction? inputAction(FieldConfig f) =>
      f.flutterInputAction ??
      (f.type == FieldType.search ? TextInputAction.search : null);

  /// Keyboard capitalization hint from [FieldConfig.textCase].
  static TextCapitalization capitalization(FieldConfig f) =>
      switch (f.textCase ?? TextPresets.resolve(f.preset)?.textCase) {
        TextCase.upper => TextCapitalization.characters,
        TextCase.words => TextCapitalization.words,
        TextCase.sentences => TextCapitalization.sentences,
        _ => TextCapitalization.none,
      };

  /// Input formatters per field type.
  static List<TextInputFormatter> formatters(FieldConfig f) {
    final preset = TextPresets.resolve(f.preset);
    final textCase = f.textCase ?? preset?.textCase;
    final maxLength = f.maxLength ?? preset?.maxLength;
    return [
      if (preset?.allowedChars != null)
        FilteringTextInputFormatter.allow(
          RegExp('[${preset!.allowedChars}]', unicode: preset.unicode),
        ),
      ..._typeFormatters(f),
      if (maxLength != null) LengthLimitingTextInputFormatter(maxLength),
      if (textCase == TextCase.upper) _CaseFormatter(upper: true),
      if (textCase == TextCase.lower) _CaseFormatter(upper: false),
    ];
  }

  static List<TextInputFormatter> _typeFormatters(FieldConfig f) => [
    if (f.type == FieldType.number)
      FilteringTextInputFormatter.allow(RegExp(r'[\d-]')),
    if (f.type == FieldType.decimal)
      FilteringTextInputFormatter.allow(RegExp(r'[\d.\-]')),
    if (f.type == FieldType.phone)
      FilteringTextInputFormatter.allow(RegExp(r'[\d+\-\s()]')),
  ];

  static final Map<String, IconData> _customIcons = {};

  /// Makes [icon] usable from JSON as `"prefixIcon": "<name>"` (also for
  /// option icons).
  static void registerIcon(String name, IconData icon) =>
      _customIcons[name] = icon;

  /// Every icon name usable from JSON.
  static Iterable<String> get iconNames => {
    ..._builtInIcons.keys,
    ..._customIcons.keys,
  };

  /// Resolves a Material icon by name: registered icons first, then the
  /// built-in set.
  static IconData? icon(String? name) {
    if (name == null) return null;
    return _customIcons[name] ?? _builtInIcons[name];
  }

  static const Map<String, IconData> _builtInIcons = {
    'person': Icons.person,
    'email': Icons.email,
    'phone': Icons.phone,
    'lock': Icons.lock,
    'search': Icons.search,
    'calendar': Icons.calendar_today,
    'time': Icons.access_time,
    'link': Icons.link,
    'location': Icons.location_on,
    'home': Icons.home,
    'visibility': Icons.visibility,
    'star': Icons.star,
    'camera': Icons.camera_alt,
    'image': Icons.image,
    'file': Icons.attach_file,
    'edit': Icons.edit,
    'money': Icons.attach_money,
    'flag': Icons.flag,
    'city': Icons.location_city,
    'qr': Icons.qr_code_scanner,
    'barcode': Icons.barcode_reader,
    'color': Icons.palette,
    'check': Icons.check,
    'work': Icons.work_outline,
    'school': Icons.school_outlined,
    'event': Icons.event,
    'note': Icons.sticky_note_2_outlined,
    'people': Icons.people_outline,
    'badge': Icons.badge_outlined,
    'pets': Icons.pets,
    'health': Icons.health_and_safety_outlined,
    'car': Icons.directions_car_outlined,
    'info': Icons.info_outline,
    'tag': Icons.sell_outlined,
    'percent': Icons.percent,
    'web': Icons.language,
  };
}

class _CaseFormatter extends TextInputFormatter {
  _CaseFormatter({required this.upper});

  final bool upper;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) => newValue.copyWith(
    text: upper ? newValue.text.toUpperCase() : newValue.text.toLowerCase(),
  );
}
