import 'package:flutter/widgets.dart';

import '../controllers/dynamic_form_controller.dart';
import '../models/field_config.dart';
import '../models/field_type.dart';

/// Builds the widget for one field.
typedef FieldBuilder =
    Widget Function(
      BuildContext context,
      FieldConfig field,
      DynamicFormController controller,
    );

/// Factory + registry mapping [FieldType] to widget builders.
///
/// Every built-in renderer is registered here, and every one can be
/// **overridden** — this is also how pluggable types (image, camera, file,
/// signature, QR/barcode, rich text) get their real implementation:
///
/// ```dart
/// FieldFactory.register(FieldType.signature, (context, field, controller) {
///   return MySignaturePad(
///     onDone: (bytes) => controller.setValue(field.id, bytes),
///   );
/// });
/// ```
///
/// Custom JSON types use [registerCustom]:
/// ```dart
/// FieldFactory.registerCustom('map_picker', builder);
/// // JSON: {"type": "custom", "customType": "map_picker", ...}
/// ```
class FieldFactory {
  const FieldFactory._();

  static final Map<FieldType, FieldBuilder> _builders = {};
  static final Map<String, FieldBuilder> _customBuilders = {};

  /// Registers/overrides the builder for a field type.
  static void register(FieldType type, FieldBuilder builder) =>
      _builders[type] = builder;

  /// Registers a named custom builder for `{"type": "custom"}` fields.
  static void registerCustom(String name, FieldBuilder builder) =>
      _customBuilders[name] = builder;

  /// Resolves the builder for [field]; null when nothing is registered.
  static FieldBuilder? resolve(FieldConfig field) {
    if (field.type == FieldType.custom) {
      final name = field.ex<String>('customType') ?? field.ex<String>('widget');
      return name != null ? _customBuilders[name] : null;
    }
    return _builders[field.type];
  }

  /// Registers the built-in renderers (called once by [DynamicForm]).
  static void registerDefaults(Map<FieldType, FieldBuilder> defaults) {
    for (final entry in defaults.entries) {
      _builders.putIfAbsent(entry.key, () => entry.value);
    }
  }
}
