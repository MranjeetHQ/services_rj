import 'package:flutter/material.dart';

import 'field_enums.dart';

/// Visual variant of an input field, selectable from JSON.
enum FieldStyleVariant {
  /// Classic outlined border (Material `OutlineInputBorder`).
  outlined,

  /// Pill-shaped outlined border (large corner radius).
  rounded,

  /// Filled background with no visible border.
  filled,

  /// Single underline (classic Material).
  underline,

  /// No border at all.
  none;

  /// Parses a variant name from JSON (`"rounded"`, `"filled"`, …).
  static FieldStyleVariant? fromString(String? raw) {
    if (raw == null) return null;
    for (final v in FieldStyleVariant.values) {
      if (v.name == raw.toLowerCase().trim()) return v;
    }
    return null;
  }
}

/// JSON-configurable field appearance. Can be set at four levels — app
/// theme ([DynamicFormThemeData.defaultFieldStyle]), form root
/// (`"style": {...}` in the form JSON), per field (`"style"` /
/// `"decoration"` on the field) and in code via `FieldOverrides.style` —
/// merged in that order, most specific wins.
///
/// ```json
/// {
///   "style": {
///     "variant": "rounded",
///     "fillColor": "#F1F3FF",
///     "borderColor": "#3F51B5",
///     "borderRadius": 24,
///     "activeColor": "#00897B",
///     "textAlign": "center",
///     "textStyle": {"fontSize": 16, "fontWeight": "w600"}
///   }
/// }
/// ```
class FieldStyleConfig {
  /// Creates a style config.
  const FieldStyleConfig({
    this.variant,
    this.borderRadius,
    this.fillColor,
    this.borderColor,
    this.focusedBorderColor,
    this.borderWidth,
    this.dense,
    this.contentPadding,
    this.labelBehavior,
    this.textStyle,
    this.labelStyle,
    this.hintStyle,
    this.helperStyle,
    this.errorStyle,
    this.iconColor,
    this.activeColor,
    this.cursorColor,
    this.textAlign,
    this.containerColor,
    this.containerRadius,
  });

  /// Parses a style config from a JSON map.
  factory FieldStyleConfig.fromJson(Map<String, dynamic> json) {
    return FieldStyleConfig(
      variant: FieldStyleVariant.fromString(
        (json['variant'] ?? json['type'])?.toString(),
      ),
      borderRadius: ((json['borderRadius'] ?? json['radius']) as num?)
          ?.toDouble(),
      fillColor: parseColor(json['fillColor']),
      borderColor: parseColor(json['borderColor']),
      focusedBorderColor: parseColor(json['focusedBorderColor']),
      borderWidth: (json['borderWidth'] as num?)?.toDouble(),
      dense: json['dense'] as bool?,
      contentPadding: parseEdgeInsets(json['contentPadding']),
      labelBehavior: LabelBehavior.fromString(json['labelBehavior']),
      textStyle: parseTextStyle(json['textStyle']),
      labelStyle: parseTextStyle(json['labelStyle']),
      hintStyle: parseTextStyle(json['hintStyle']),
      helperStyle: parseTextStyle(json['helperStyle']),
      errorStyle: parseTextStyle(json['errorStyle']),
      iconColor: parseColor(json['iconColor']),
      activeColor: parseColor(json['activeColor']),
      cursorColor: parseColor(json['cursorColor']),
      textAlign: parseTextAlign(json['textAlign']),
      containerColor: parseColor(json['containerColor']),
      containerRadius: (json['containerRadius'] as num?)?.toDouble(),
    );
  }

  /// Every JSON key [FieldStyleConfig.fromJson] reads (`type` and
  /// `radius` are aliases of `variant` and `borderRadius`).
  static const Set<String> knownKeys = {
    'variant',
    'type',
    'borderRadius',
    'radius',
    'fillColor',
    'borderColor',
    'focusedBorderColor',
    'borderWidth',
    'dense',
    'contentPadding',
    'labelBehavior',
    'textStyle',
    'labelStyle',
    'hintStyle',
    'helperStyle',
    'errorStyle',
    'iconColor',
    'activeColor',
    'cursorColor',
    'textAlign',
    'containerColor',
    'containerRadius',
  };

  /// Border/background variant.
  final FieldStyleVariant? variant;

  /// Corner radius (defaults per variant: outlined 8, filled 12, rounded 28).
  final double? borderRadius;

  /// Background fill color (implies `filled: true`).
  final Color? fillColor;

  /// Border color in the enabled state.
  final Color? borderColor;

  /// Border color when focused (defaults to the theme primary color).
  final Color? focusedBorderColor;

  /// Border stroke width.
  final double? borderWidth;

  /// Dense layout.
  final bool? dense;

  /// Inner content padding.
  final EdgeInsets? contentPadding;

  /// Where the floating label sits.
  final LabelBehavior? labelBehavior;

  /// Style of the entered text.
  final TextStyle? textStyle;

  /// Style of the label.
  final TextStyle? labelStyle;

  /// Style of the hint.
  final TextStyle? hintStyle;

  /// Style of the helper text.
  final TextStyle? helperStyle;

  /// Style of the error text.
  final TextStyle? errorStyle;

  /// Color of prefix / suffix icons.
  final Color? iconColor;

  /// Selected color for checkboxes, radios, switches, chips, sliders,
  /// ratings and segmented buttons.
  final Color? activeColor;

  /// Text cursor color.
  final Color? cursorColor;

  /// Alignment of the entered text.
  final TextAlign? textAlign;

  /// Background of container-like fields (group, repeater entries).
  final Color? containerColor;

  /// Corner radius of container-like fields.
  final double? containerRadius;

  /// Whether any property is set.
  bool get isNotEmpty => toJson().isNotEmpty;

  /// Merges [layers] left to right — later non-null properties win.
  static FieldStyleConfig merge(List<FieldStyleConfig?> layers) {
    var r = const FieldStyleConfig();
    for (final l in layers) {
      if (l == null) continue;
      r = FieldStyleConfig(
        variant: l.variant ?? r.variant,
        borderRadius: l.borderRadius ?? r.borderRadius,
        fillColor: l.fillColor ?? r.fillColor,
        borderColor: l.borderColor ?? r.borderColor,
        focusedBorderColor: l.focusedBorderColor ?? r.focusedBorderColor,
        borderWidth: l.borderWidth ?? r.borderWidth,
        dense: l.dense ?? r.dense,
        contentPadding: l.contentPadding ?? r.contentPadding,
        labelBehavior: l.labelBehavior ?? r.labelBehavior,
        textStyle: l.textStyle ?? r.textStyle,
        labelStyle: l.labelStyle ?? r.labelStyle,
        hintStyle: l.hintStyle ?? r.hintStyle,
        helperStyle: l.helperStyle ?? r.helperStyle,
        errorStyle: l.errorStyle ?? r.errorStyle,
        iconColor: l.iconColor ?? r.iconColor,
        activeColor: l.activeColor ?? r.activeColor,
        cursorColor: l.cursorColor ?? r.cursorColor,
        textAlign: l.textAlign ?? r.textAlign,
        containerColor: l.containerColor ?? r.containerColor,
        containerRadius: l.containerRadius ?? r.containerRadius,
      );
    }
    return r;
  }

  /// Serializes back to JSON (only set properties).
  Map<String, dynamic> toJson() => {
    if (variant != null) 'variant': variant!.name,
    if (borderRadius != null) 'borderRadius': borderRadius,
    if (fillColor != null) 'fillColor': colorToHex(fillColor!),
    if (borderColor != null) 'borderColor': colorToHex(borderColor!),
    if (focusedBorderColor != null)
      'focusedBorderColor': colorToHex(focusedBorderColor!),
    if (borderWidth != null) 'borderWidth': borderWidth,
    if (dense != null) 'dense': dense,
    if (contentPadding != null)
      'contentPadding': edgeInsetsToJson(contentPadding!),
    if (labelBehavior != null) 'labelBehavior': labelBehavior!.name,
    if (textStyle != null) 'textStyle': textStyleToJson(textStyle!),
    if (labelStyle != null) 'labelStyle': textStyleToJson(labelStyle!),
    if (hintStyle != null) 'hintStyle': textStyleToJson(hintStyle!),
    if (helperStyle != null) 'helperStyle': textStyleToJson(helperStyle!),
    if (errorStyle != null) 'errorStyle': textStyleToJson(errorStyle!),
    if (iconColor != null) 'iconColor': colorToHex(iconColor!),
    if (activeColor != null) 'activeColor': colorToHex(activeColor!),
    if (cursorColor != null) 'cursorColor': colorToHex(cursorColor!),
    if (textAlign != null) 'textAlign': textAlign!.name,
    if (containerColor != null) 'containerColor': colorToHex(containerColor!),
    if (containerRadius != null) 'containerRadius': containerRadius,
  };

  /// Parses `#RRGGBB`, `#AARRGGBB` or `0xAARRGGBB` color strings.
  static Color? parseColor(Object? raw) {
    if (raw == null) return null;
    if (raw is Color) return raw;
    var s = raw.toString().replaceFirst('#', '').replaceFirst('0x', '');
    if (s.length == 6) s = 'FF$s';
    final value = int.tryParse(s, radix: 16);
    return value == null ? null : Color(value);
  }

  /// Formats a color as `#RRGGBB` (or `#AARRGGBB` when not opaque).
  static String colorToHex(Color c) {
    final argb = c.toARGB32();
    final hex = argb.toRadixString(16).padLeft(8, '0').toUpperCase();
    return hex.startsWith('FF') ? '#${hex.substring(2)}' : '#$hex';
  }

  /// Parses `16` (all sides) or `{"left": 8, "top": 4, ...}`. Also accepts
  /// `{"horizontal": 12, "vertical": 8}`.
  static EdgeInsets? parseEdgeInsets(Object? raw) {
    if (raw is EdgeInsets) return raw;
    if (raw is num) return EdgeInsets.all(raw.toDouble());
    if (raw is Map) {
      final m = Map<String, dynamic>.from(raw);
      double d(String k) => (m[k] as num?)?.toDouble() ?? 0;
      final h = d('horizontal');
      final v = d('vertical');
      return EdgeInsets.fromLTRB(
        m.containsKey('left') ? d('left') : h,
        m.containsKey('top') ? d('top') : v,
        m.containsKey('right') ? d('right') : h,
        m.containsKey('bottom') ? d('bottom') : v,
      );
    }
    return null;
  }

  /// Serializes edge insets as a `{left, top, right, bottom}` map.
  static Object edgeInsetsToJson(EdgeInsets e) =>
      e.left == e.top && e.top == e.right && e.right == e.bottom
      ? e.left
      : {'left': e.left, 'top': e.top, 'right': e.right, 'bottom': e.bottom};

  /// Parses `left`, `right`, `center`, `start`, `end`, `justify`.
  static TextAlign? parseTextAlign(Object? raw) => raw == null
      ? null
      : TextAlign.values
            .where((a) => a.name == raw.toString().toLowerCase())
            .firstOrNull;

  /// Parses a text style map: `{"fontSize": 16, "color": "#333333",
  /// "fontWeight": "bold" | "w600", "italic": true, "letterSpacing": 1}`.
  static TextStyle? parseTextStyle(Object? raw) {
    if (raw is TextStyle) return raw;
    if (raw is! Map) return null;
    final m = Map<String, dynamic>.from(raw);
    FontWeight? weight;
    final w = m['fontWeight']?.toString();
    if (w != null) {
      weight = switch (w) {
        'bold' => FontWeight.bold,
        'normal' => FontWeight.normal,
        'w100' => FontWeight.w100,
        'w200' => FontWeight.w200,
        'w300' => FontWeight.w300,
        'w400' => FontWeight.w400,
        'w500' => FontWeight.w500,
        'w600' => FontWeight.w600,
        'w700' => FontWeight.w700,
        'w800' => FontWeight.w800,
        'w900' => FontWeight.w900,
        _ => FontWeight.normal,
      };
    }
    return TextStyle(
      fontSize: (m['fontSize'] as num?)?.toDouble(),
      color: parseColor(m['color']),
      fontWeight: weight,
      fontStyle: m['italic'] == true ? FontStyle.italic : null,
      letterSpacing: (m['letterSpacing'] as num?)?.toDouble(),
    );
  }

  /// Serializes the subset of [TextStyle] that [parseTextStyle] reads.
  static Map<String, dynamic> textStyleToJson(TextStyle s) => {
    if (s.fontSize != null) 'fontSize': s.fontSize,
    if (s.color != null) 'color': colorToHex(s.color!),
    if (s.fontWeight != null) 'fontWeight': 'w${s.fontWeight!.value}',
    if (s.fontStyle == FontStyle.italic) 'italic': true,
    if (s.letterSpacing != null) 'letterSpacing': s.letterSpacing,
  };
}
