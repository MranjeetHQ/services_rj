import 'field_enums.dart';

/// JSON-configurable validator description.
///
/// ```json
/// {"type": "minLength", "value": 8, "message": "Too short"}
/// ```
///
/// In Dart, prefer the typed constructors:
/// ```dart
/// ValidatorConfig.of(ValidatorType.minLength, value: 8)
/// ValidatorConfig.required(message: 'Tell us your name')
/// ```
class ValidatorConfig {
  /// Creates a validator config from a type name (built-in or registered).
  const ValidatorConfig({
    required this.type,
    this.value,
    this.message,
    this.params = const {},
  });

  /// Creates a validator config from a built-in [ValidatorType].
  ValidatorConfig.of(
    ValidatorType kind, {
    this.value,
    this.message,
    this.params = const {},
  }) : type = kind.name;

  /// Shorthand for `ValidatorConfig.of(ValidatorType.required)`.
  const ValidatorConfig.required({this.message})
    : type = 'required',
      value = null,
      params = const {};

  /// Programmatic validator registered on the controller under [name].
  ValidatorConfig.custom(String name, {this.message})
    : type = 'custom',
      value = name,
      params = {'name': name};

  /// Parses a validator from JSON. Accepts a map or a bare string
  /// (`"required"` is shorthand for `{"type": "required"}`).
  factory ValidatorConfig.fromJson(Object? json) {
    if (json is ValidatorConfig) return json;
    if (json is ValidatorType) return ValidatorConfig(type: json.name);
    if (json is String) return ValidatorConfig(type: json);
    final map = Map<String, dynamic>.from(json as Map? ?? const {});
    return ValidatorConfig(
      type: map['type']?.toString() ?? 'custom',
      value: map['value'],
      message: map['message'] as String?,
      params: Map<String, dynamic>.from(map)
        ..remove('type')
        ..remove('value')
        ..remove('message'),
    );
  }

  /// Validator type name: a [ValidatorType] name or a registered custom name.
  final String type;

  /// Primary parameter (e.g. the minimum for `min`).
  final Object? value;

  /// Custom error message overriding the localized default.
  final String? message;

  /// Additional named parameters.
  final Map<String, dynamic> params;

  /// The built-in type, or null for registered custom names.
  ValidatorType? get kind => ValidatorType.fromString(type);

  /// Serializes back to JSON.
  Map<String, dynamic> toJson() => {
    'type': type,
    if (value != null) 'value': value,
    if (message != null) 'message': message,
    ...params,
  };
}
