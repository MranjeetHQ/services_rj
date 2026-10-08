import 'package:flutter/widgets.dart';

final RegExp _emailPattern = RegExp(
  r"^[\w.!#$%&'*+/=?^`{|}~-]+@[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?"
  r'(?:\.[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?)+$',
);
final RegExp _phonePattern = RegExp(r'^\+?\d{7,15}$');
final RegExp _phoneSeparators = RegExp(r'[\s\-().]');
final RegExp _letters = RegExp(r'^[\p{L}\p{M}]+$', unicode: true);
final RegExp _lettersAndDigits = RegExp(r'^[\p{L}\p{M}\p{N}]+$', unicode: true);
final RegExp _whitespace = RegExp(r'\s+');
final RegExp _nonDigits = RegExp(r'\D');
final RegExp _wordSeparators = RegExp(r'[\s_\-.]+');
final RegExp _camelBoundary = RegExp(r'([\p{Ll}\p{N}])(\p{Lu})', unicode: true);
final RegExp _word = RegExp(r'\S+');

/// Checks, conversions and formatting for [String].
///
/// Characters are counted as user-visible characters (grapheme clusters), so
/// emoji and scripts such as Hindi are not split in the middle.
///
/// If another package defines an extension member with the same name, hide
/// one of them: `import 'package:services_rj/services_rj.dart' hide
/// AppStringExtensions;`.
extension AppStringExtensions on String {
  // ── Checks ────────────────────────────────────────────────────────────────

  /// Empty or only whitespace.
  bool get isBlank => trim().isEmpty;

  /// Contains at least one non-whitespace character.
  bool get isNotBlank => !isBlank;

  /// A plausible email address: `name@domain.tld`.
  bool get isEmail => _emailPattern.hasMatch(trim());

  /// 7 to 15 digits with an optional leading `+`. Spaces, dashes, dots and
  /// brackets are ignored.
  bool get isPhone => _phonePattern.hasMatch(replaceAll(_phoneSeparators, ''));

  /// An absolute `http` or `https` URL with a host.
  bool get isUrl {
    final uri = Uri.tryParse(trim());
    return uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  }

  /// Parses as a number, such as `42`, `-3.5` or `1e3`.
  bool get isNumeric => double.tryParse(trim()) != null;

  /// Only letters, in any script (including vowel signs and accents).
  bool get isAlphabetic => _letters.hasMatch(this);

  /// Only letters and digits, in any script.
  bool get isAlphanumeric => _lettersAndDigits.hasMatch(this);

  /// Same text ignoring case.
  bool equalsIgnoreCase(String other) => toLowerCase() == other.toLowerCase();

  // ── Conversions ───────────────────────────────────────────────────────────

  /// The integer value, or null when this is not an integer.
  int? toIntOrNull() => int.tryParse(trim());

  /// The number value, or null when this is not a number.
  double? toDoubleOrNull() => double.tryParse(trim());

  /// `true` for `true`, `yes`, `y`, `on` and `1` (any case); `false`
  /// otherwise.
  bool toBool() =>
      const {'true', 'yes', 'y', 'on', '1'}.contains(trim().toLowerCase());

  // ── Case ──────────────────────────────────────────────────────────────────

  /// First character in upper case, the rest unchanged: `hello world` →
  /// `Hello world`.
  String capitalize() {
    if (isEmpty) return this;
    final chars = characters;
    return chars.first.toUpperCase() + chars.skip(1).toString();
  }

  /// Every word capitalized and the rest in lower case, keeping the
  /// original spacing: `hello WORLD` → `Hello World`.
  String toTitleCase() =>
      replaceAllMapped(_word, (m) => m[0]!.toLowerCase().capitalize());

  /// `user name`, `user_name`, `user-name` or `UserName` → `userName`.
  String toCamelCase() {
    final words = _words();
    if (words.isEmpty) return '';
    return words.first.toLowerCase() +
        words.skip(1).map((w) => w.toLowerCase().capitalize()).join();
  }

  /// `userName` or `User Name` → `user_name`.
  String toSnakeCase() => _words().map((w) => w.toLowerCase()).join('_');

  /// `userName` or `User Name` → `user-name`.
  String toKebabCase() => _words().map((w) => w.toLowerCase()).join('-');

  // ── Editing ───────────────────────────────────────────────────────────────

  /// Removes every whitespace character.
  String removeWhitespace() => replaceAll(_whitespace, '');

  /// Replaces runs of whitespace with one space and trims the ends.
  String collapseWhitespace() => trim().replaceAll(_whitespace, ' ');

  /// Keeps only the digits: `+91 98765-43210` → `919876543210`.
  String onlyDigits() => replaceAll(_nonDigits, '');

  /// The characters in reverse order.
  String reverse() => characters.toList().reversed.join();

  /// At most [maxLength] characters, including [ellipsis]:
  /// `'Hello world'.truncate(8)` → `Hello w…`.
  String truncate(int maxLength, {String ellipsis = '…'}) {
    final chars = characters;
    if (chars.length <= maxLength) return this;
    final keep = maxLength - ellipsis.characters.length;
    if (keep <= 0) return ellipsis.characters.take(maxLength).toString();
    return chars.take(keep).toString().trimRight() + ellipsis;
  }

  /// Hides all but [visibleStart] leading and [visibleEnd] trailing
  /// characters: `'9876543210'.mask()` → `••••••3210`. Returns the text
  /// unchanged when it is too short to hide anything.
  String mask({int visibleStart = 0, int visibleEnd = 4, String char = '•'}) {
    final chars = characters.toList();
    final hidden = chars.length - visibleStart - visibleEnd;
    if (hidden <= 0) return this;
    return chars.take(visibleStart).join() +
        char * hidden +
        chars.skip(chars.length - visibleEnd).join();
  }

  /// Upper-case first letters of the first and last word, for avatars:
  /// `Ranjit Kumar Makwana` → `RM`, `asha` → `A`.
  String get initials {
    final words = trim().split(_whitespace).where((w) => w.isNotEmpty);
    if (words.isEmpty) return '';
    final first = words.first.characters.first;
    if (words.length == 1) return first.toUpperCase();
    return (first + words.last.characters.first).toUpperCase();
  }

  List<String> _words() => replaceAllMapped(
    _camelBoundary,
    (m) => '${m[1]} ${m[2]}',
  ).split(_wordSeparators).where((w) => w.isNotEmpty).toList();
}

/// Helpers for a [String] that may be null.
extension AppNullableStringExtensions on String? {
  /// Null or `''`.
  bool get isNullOrEmpty => this?.isEmpty ?? true;

  /// Null, empty or only whitespace.
  bool get isNullOrBlank => this?.trim().isEmpty ?? true;

  /// This text, or `''` when null.
  String get orEmpty => this ?? '';

  /// This text, or [fallback] when it is null, empty or only whitespace.
  String or(String fallback) => isNullOrBlank ? fallback : this!;
}
