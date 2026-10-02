import 'package:flutter/widgets.dart';

import '../models/field_config.dart';
import '../models/form_enum_registry.dart';
import '../models/option_item.dart';
import 'dynamic_form_controller.dart';

/// One entry of a `repeater` field: its own sub-form controller plus a key
/// that stays stable while entries are added, removed or reordered.
class RepeaterEntry {
  /// Creates an entry.
  RepeaterEntry(this.key, this.controller);

  /// Stable widget key.
  final int key;

  /// Controller for this entry's fields.
  final DynamicFormController controller;

  /// This entry's data.
  Map<String, dynamic> get data => controller.getFormData();
}

/// Mutable runtime state of one field. Each aspect is its own
/// [ValueNotifier], so only widgets listening to the changed aspect rebuild.
class FieldRuntimeState {
  /// Creates runtime state from a config.
  FieldRuntimeState(this.config)
    : value = ValueNotifier<Object?>(
        config.initialValue ?? config.defaultValue,
      ),
      error = ValueNotifier<String?>(null),
      visible = ValueNotifier<bool>(config.visible),
      enabled = ValueNotifier<bool>(config.enabled),
      required = ValueNotifier<bool>(
        config.required || config.validators.any((v) => v.type == 'required'),
      ),
      options = ValueNotifier<List<OptionItem>>(initialOptions(config)),
      loadingOptions = ValueNotifier<bool>(false),
      entries = ValueNotifier<List<RepeaterEntry>>(const []),
      focusNode = FocusNode(debugLabel: config.id);

  /// Static options, else the options of the registered enum
  /// (`"enum": "Name"`), else empty.
  static List<OptionItem> initialOptions(FieldConfig config) {
    if (config.options.isNotEmpty) return config.options;
    final name = config.enumName;
    if (name == null) return const [];
    final fromEnum = FormEnumRegistry.options(name);
    assert(
      fromEnum != null,
      'Field "${config.id}" uses enum "$name" which is not registered. '
      'Call FormEnumRegistry.register("$name", YourEnum.values) first.',
    );
    return fromEnum ?? const [];
  }

  /// Static configuration.
  FieldConfig config;

  /// Current value.
  final ValueNotifier<Object?> value;

  /// Current validation error (null = valid / not yet validated).
  final ValueNotifier<String?> error;

  /// Dynamic visibility.
  final ValueNotifier<bool> visible;

  /// Dynamic enablement.
  final ValueNotifier<bool> enabled;

  /// Dynamic required-ness.
  final ValueNotifier<bool> required;

  /// Current options (static, enum, user-added or dynamically loaded).
  final ValueNotifier<List<OptionItem>> options;

  /// Whether async options are loading.
  final ValueNotifier<bool> loadingOptions;

  /// Entries of a `repeater` field (empty for every other type).
  final ValueNotifier<List<RepeaterEntry>> entries;

  /// Focus node for [DynamicFormController.focusField].
  final FocusNode focusNode;

  /// Releases all notifiers, entry controllers and the focus node.
  void dispose() {
    for (final e in entries.value) {
      e.controller.dispose();
    }
    value.dispose();
    error.dispose();
    visible.dispose();
    enabled.dispose();
    required.dispose();
    options.dispose();
    loadingOptions.dispose();
    entries.dispose();
    focusNode.dispose();
  }
}
