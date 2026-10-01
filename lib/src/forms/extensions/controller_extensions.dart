import '../controllers/dynamic_form_controller.dart';
import '../models/form_enum_registry.dart';

/// Ergonomic typed accessors on the controller.
extension DynamicFormControllerX on DynamicFormController {
  /// Value of [id] as a String (null-safe).
  String? getString(String id) => getValue(id)?.toString();

  /// Value of [id] as an int, parsing strings when needed.
  int? getInt(String id) {
    final v = getValue(id);
    if (v is int) return v;
    return int.tryParse(v?.toString() ?? '');
  }

  /// Value of [id] as a double, parsing strings when needed.
  double? getDouble(String id) {
    final v = getValue(id);
    if (v is double) return v;
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '');
  }

  /// Value of [id] as a bool (defaults to false).
  bool getBool(String id) => getValue(id) == true;

  /// Value of [id] as a list.
  List<Object?> getList(String id) =>
      List<Object?>.from(getValue(id) as List? ?? const []);

  /// Value of [id] decoded into an enum (values are stored by `name`).
  ///
  /// ```dart
  /// final plan = controller.getEnum('plan', Plan.values); // Plan?
  /// ```
  T? getEnum<T extends Enum>(String id, List<T> values) =>
      FormEnumRegistry.decode(values, getValue(id));

  /// Multi-select value of [id] decoded into a list of enums.
  List<T> getEnumList<T extends Enum>(String id, List<T> values) => [
    for (final raw in getList(id)) ?FormEnumRegistry.decode(values, raw),
  ];

  /// Entries of repeater [id] as plain maps.
  List<Map<String, dynamic>> getEntries(String id) => [
    for (final e in entriesOf(id)) e.data,
  ];

  /// Whether the form currently has any errors.
  bool get hasErrors => getErrors().isNotEmpty;
}
