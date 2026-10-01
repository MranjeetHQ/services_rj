import 'option_item.dart';

/// Registry of app enums that JSON forms can use as option sources.
///
/// Register an enum once at startup, then reference it by name from any
/// selection field with `"enum": "<name>"`. The stored value is the enum's
/// `name`, so form data stays JSON-serializable, and
/// `controller.getEnum(id, Plan.values)` turns it back into the enum.
///
/// ```dart
/// enum Priority { low, medium, high, critical }
///
/// FormEnumRegistry.register('Priority', Priority.values,
///     label: (p) => p.name.toUpperCase());
///
/// // JSON
/// {"type": "segmented", "id": "priority", "enum": "Priority"}
/// ```
class FormEnumRegistry {
  const FormEnumRegistry._();

  static final Map<String, List<OptionItem>> _options = {};

  /// Registers [values] under [name]. Labels default to a humanized version
  /// of each enum name (`inPerson` → `In person`).
  static void register<T extends Enum>(
    String name,
    List<T> values, {
    String Function(T value)? label,
    String? Function(T value)? description,
    String? Function(T value)? icon,
    bool Function(T value)? enabled,
  }) {
    _options[name] = OptionItem.fromEnum(
      values,
      label: label,
      description: description,
      icon: icon,
      enabled: enabled,
    );
  }

  /// Removes a registered enum.
  static void unregister(String name) => _options.remove(name);

  /// Whether [name] is registered.
  static bool contains(String name) => _options.containsKey(name);

  /// Names of every registered enum.
  static Iterable<String> get names => _options.keys;

  /// Options for [name], or null when it is not registered.
  static List<OptionItem>? options(String name) => _options[name];

  /// Turns a stored value (an enum name, or the enum itself) back into [T].
  static T? decode<T extends Enum>(List<T> values, Object? raw) {
    if (raw is T) return raw;
    if (raw == null) return null;
    final s = raw.toString();
    for (final v in values) {
      if (v.name == s) return v;
    }
    return null;
  }

  /// Turns `camelCase` / `snake_case` enum names into `Sentence case`.
  static String humanize(String name) {
    final spaced = name
        .replaceAll('_', ' ')
        .replaceAllMapped(RegExp('([a-z0-9])([A-Z])'), (m) => '${m[1]} ${m[2]}')
        .trim();
    if (spaced.isEmpty) return spaced;
    // Keep acronyms (ICU, GST) intact.
    if (spaced == spaced.toUpperCase()) return spaced;
    final lower = spaced.toLowerCase();
    return lower[0].toUpperCase() + lower.substring(1);
  }
}
