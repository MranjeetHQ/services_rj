import '../controllers/dynamic_form_controller.dart';
import '../models/country_dial_code.dart';
import '../models/form_enum_registry.dart';

/// Ergonomic typed accessors on the controller.
extension DynamicFormControllerX on DynamicFormController {
  /// The full international number of a phone field with a country code
  /// picker, e.g. `+919876543210`. `null` when empty.
  String? getPhoneNumber(String id) => getString(id);

  /// The country code of a phone field, e.g. `+91`. `null` when the field is
  /// empty or has no country code.
  String? getCountryCode(String id) => getPhone(id)?.dial;

  /// The number of a phone field without its country code, e.g.
  /// `9876543210`. `null` when empty.
  String? getNationalNumber(String id) => getPhone(id)?.number;

  /// Sets a phone field from a country code and a national number, e.g.
  /// `setPhone('mobile', dial: '+91', number: '98765 43210')`. An empty
  /// number clears the field.
  void setPhone(String id, {required String dial, required String number}) {
    final digits = number.replaceAll(RegExp(r'[^\d]'), '');
    final code = CountryDialCodes.lookup(dial)?.dial ?? dial;
    setValue(id, digits.isEmpty ? null : '$code$digits');
  }

  /// A phone field's value split into its country code (`+91`, `null` when
  /// the field has no country code) and national number. `null` when empty.
  ({String? dial, String number})? getPhone(String id) {
    final v = getString(id);
    if (v == null || v.isEmpty) return null;
    final parts = CountryDialCodes.split(v);
    return (dial: parts.dial, number: parts.national);
  }

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
