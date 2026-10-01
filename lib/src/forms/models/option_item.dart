import 'form_enum_registry.dart';

/// A selectable option for dropdowns, radio groups, chips, etc.
class OptionItem {
  /// Creates an option.
  const OptionItem({
    required this.label,
    required this.value,
    this.enabled = true,
    this.icon,
    this.description,
    this.isCustom = false,
    this.extra = const {},
  });

  /// Parses an option from JSON. Accepts `{"label": ..., "value": ...}`
  /// or a bare scalar used as both label and value.
  factory OptionItem.fromJson(Object? json) {
    if (json is OptionItem) return json;
    if (json is Enum) {
      return OptionItem(
        label: FormEnumRegistry.humanize(json.name),
        value: json.name,
      );
    }
    if (json is Map) {
      final map = Map<String, dynamic>.from(json);
      return OptionItem(
        label: map['label']?.toString() ?? map['value']?.toString() ?? '',
        value: map['value'],
        enabled: map['enabled'] as bool? ?? true,
        icon: map['icon'] as String?,
        description: map['description'] as String?,
        isCustom: map['isCustom'] as bool? ?? false,
        extra: Map<String, dynamic>.from(map['extra'] as Map? ?? const {}),
      );
    }
    return OptionItem(label: json.toString(), value: json);
  }

  /// Builds one option per enum value. The stored value is the enum `name`.
  static List<OptionItem> fromEnum<T extends Enum>(
    List<T> values, {
    String Function(T value)? label,
    String? Function(T value)? description,
    String? Function(T value)? icon,
    bool Function(T value)? enabled,
  }) => [
    for (final v in values)
      OptionItem(
        label: label?.call(v) ?? FormEnumRegistry.humanize(v.name),
        value: v.name,
        description: description?.call(v),
        icon: icon?.call(v),
        enabled: enabled?.call(v) ?? true,
      ),
  ];

  /// Display label.
  final String label;

  /// Value written into form data when selected.
  final Object? value;

  /// Whether this option can be selected.
  final bool enabled;

  /// Optional Material icon name (see `FieldUtils.icon`).
  final String? icon;

  /// Optional secondary line shown under the label (radio / checkbox
  /// groups and dropdown menus).
  final String? description;

  /// True for options the user added at runtime through
  /// `"allowCustomOptions"`.
  final bool isCustom;

  /// Arbitrary extra data (e.g. country dial codes).
  final Map<String, dynamic> extra;

  /// Serializes this option back to JSON.
  Map<String, dynamic> toJson() => {
    'label': label,
    'value': value,
    if (!enabled) 'enabled': false,
    if (icon != null) 'icon': icon,
    if (description != null) 'description': description,
    if (isCustom) 'isCustom': true,
    if (extra.isNotEmpty) 'extra': extra,
  };

  @override
  bool operator ==(Object other) =>
      other is OptionItem && other.value == value && other.label == label;

  @override
  int get hashCode => Object.hash(label, value);
}
