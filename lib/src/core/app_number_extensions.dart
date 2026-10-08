import 'package:flutter/widgets.dart';

/// Helpers that only make sense for [double].
extension AppDoubleExtensions on double {
  /// Rounded to [places] decimal places: `3.14159.roundTo(2)` → `3.14`.
  double roundTo(int places) => double.parse(toStringAsFixed(places));

  /// Whether there is no fractional part: `3.0` → true.
  bool get isWhole => isFinite && this == truncateToDouble();

  /// At most [maxDecimals] decimals, without trailing zeros:
  /// `2.50` → `2.5`, `3.0` → `3`, `1.23456` → `1.23`.
  String toCleanString({int maxDecimals = 2}) {
    if (!isFinite) return toString();
    var text = toStringAsFixed(maxDecimals);
    if (text.contains('.')) {
      text = text.replaceFirst(RegExp(r'\.?0+$'), '');
    }
    return text == '-0' ? '0' : text;
  }
}

/// Helpers for a [double] that may be null.
extension AppNullableDoubleExtensions on double? {
  /// This value, or `0.0` when null.
  double get orZero => this ?? 0.0;
}

/// Formatting, range and layout helpers for numbers. Written on [num], so
/// they work on `double` values and on `int` literals alike: `1250.5` and
/// `16` both work.
///
/// If another package defines an extension member with the same name, hide
/// one of them: `import 'package:services_rj/services_rj.dart' hide
/// AppNumExtensions;`.
extension AppNumExtensions on num {
  // ── Formatting ────────────────────────────────────────────────────────────

  /// Thousands separators: `1234567.891.withSeparators(decimals: 2)` →
  /// `1,234,567.89`. With [indian] grouping: `12,34,567.89`.
  String withSeparators({
    int decimals = 0,
    String separator = ',',
    bool indian = false,
  }) {
    if (!isFinite) return toString();
    final fixed = abs().toStringAsFixed(decimals);
    final dot = fixed.indexOf('.');
    final whole = dot < 0 ? fixed : fixed.substring(0, dot);
    final fraction = dot < 0 ? '' : fixed.substring(dot);
    final isZero = double.parse(fixed) == 0;
    final sign = this < 0 && !isZero ? '-' : '';
    return '$sign${_group(whole, separator, indian)}$fraction';
  }

  /// Money with a currency [symbol] and separators:
  /// `1499.5.toCurrency('₹')` → `₹1,499.50`,
  /// `(-20).toCurrency('\$')` → `-$20.00`.
  String toCurrency(
    String symbol, {
    int decimals = 2,
    String separator = ',',
    bool indian = false,
  }) {
    final text = withSeparators(
      decimals: decimals,
      separator: separator,
      indian: indian,
    );
    return text.startsWith('-')
        ? '-$symbol${text.substring(1)}'
        : '$symbol$text';
  }

  /// Short form for large numbers: `1250` → `1.3K`, `3400000` → `3.4M`,
  /// then `B` and `T`. With [indian]: `150000` → `1.5L`, `25000000` →
  /// `2.5Cr`.
  String toCompact({int decimals = 1, bool indian = false}) {
    if (!isFinite) return toString();
    final units = indian ? _indianUnits : _shortUnits;
    final value = abs().toDouble();
    final sign = this < 0 ? '-' : '';
    for (var i = 0; i < units.length; i++) {
      final (size, suffix) = units[i];
      if (value < size) continue;
      final scaled = (value / size).roundTo(decimals);
      // 999950 rounds to 1000.0K; show 1M instead.
      if (i > 0 && scaled * size >= units[i - 1].$1) {
        final (biggerSize, biggerSuffix) = units[i - 1];
        return '$sign${(value / biggerSize).toCleanString(maxDecimals: decimals)}'
            '$biggerSuffix';
      }
      return '$sign${scaled.toCleanString(maxDecimals: decimals)}$suffix';
    }
    final small = value.toCleanString(maxDecimals: decimals);
    return small == '0' ? small : '$sign$small';
  }

  /// A fraction as a percentage: `0.256.toPercent()` → `26%`,
  /// `0.256.toPercent(decimals: 1)` → `25.6%`.
  String toPercent({int decimals = 0}) =>
      '${(this * 100).toStringAsFixed(decimals)}%';

  // ── Ranges ────────────────────────────────────────────────────────────────

  /// Whether [min] ≤ this ≤ [max].
  bool isBetween(num min, num max) => this >= min && this <= max;

  // ── Layout ────────────────────────────────────────────────────────────────

  /// A vertical gap: `16.heightBox` → `SizedBox(height: 16)`.
  SizedBox get heightBox => SizedBox(height: toDouble());

  /// A horizontal gap: `8.widthBox` → `SizedBox(width: 8)`.
  SizedBox get widthBox => SizedBox(width: toDouble());

  /// `EdgeInsets.all(this)`.
  EdgeInsets get allInsets => EdgeInsets.all(toDouble());

  /// `EdgeInsets.symmetric(horizontal: this)`.
  EdgeInsets get horizontalInsets =>
      EdgeInsets.symmetric(horizontal: toDouble());

  /// `EdgeInsets.symmetric(vertical: this)`.
  EdgeInsets get verticalInsets => EdgeInsets.symmetric(vertical: toDouble());

  /// `BorderRadius.circular(this)`.
  BorderRadius get borderRadius => BorderRadius.circular(toDouble());
}

const _shortUnits = [(1e12, 'T'), (1e9, 'B'), (1e6, 'M'), (1e3, 'K')];

const _indianUnits = [(1e7, 'Cr'), (1e5, 'L'), (1e3, 'K')];

String _group(String digits, String separator, bool indian) {
  if (digits.length <= 3) return digits;
  final groups = [digits.substring(digits.length - 3)];
  var rest = digits.substring(0, digits.length - 3);
  final size = indian ? 2 : 3;
  while (rest.length > size) {
    groups.insert(0, rest.substring(rest.length - size));
    rest = rest.substring(0, rest.length - size);
  }
  if (rest.isNotEmpty) groups.insert(0, rest);
  return groups.join(separator);
}
