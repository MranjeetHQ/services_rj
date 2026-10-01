import 'dart:convert';

import '../models/form_config.dart';

/// Parses raw JSON (string or decoded map) into a [FormConfig].
class FormParser {
  const FormParser._();

  /// Parses a JSON string or `Map<String, dynamic>`.
  ///
  /// Throws [FormatException] with a descriptive message on invalid input.
  static FormConfig parse(Object source) {
    final Object? decoded = source is String ? jsonDecode(source) : source;
    if (decoded is! Map) {
      throw const FormatException(
        'Form JSON must be an object with a "fields" or "steps" list.',
      );
    }
    return FormConfig.fromJson(Map<String, dynamic>.from(decoded));
  }
}
