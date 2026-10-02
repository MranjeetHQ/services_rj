import 'package:flutter/material.dart';

import '../controllers/dynamic_form_controller.dart';
import '../controllers/field_state.dart';
import '../models/field_config.dart';
import '../widgets/field_wrapper.dart';
import 'decoration_helper.dart';

/// Renderer for the `repeater` field type: an extendable list of entries,
/// each a copy of the child `fields`, with add / remove (and optional
/// reorder) controls.
///
/// ```json
/// {
///   "type": "repeater",
///   "id": "guests",
///   "label": "Guests",
///   "itemLabel": "Guest {index}",
///   "addLabel": "Add another guest",
///   "minItems": 1,
///   "maxItems": 5,
///   "reorderable": true,
///   "fields": [
///     {"type": "text", "id": "fullName", "label": "Name", "required": true},
///     {"type": "dropdown", "id": "meal", "label": "Meal", "enum": "Meal"}
///   ]
/// }
/// ```
///
/// Stored value: `List<Map<String, dynamic>>`, one map per entry. Each entry
/// validates on its own; conditions inside an entry read that entry's data.
class DynamicRepeaterField extends StatelessWidget {
  /// Creates a repeater field.
  const DynamicRepeaterField({
    super.key,
    required this.field,
    required this.controller,
  });

  /// Field configuration.
  final FieldConfig field;

  /// Owning form controller.
  final DynamicFormController controller;

  String _title(int index) =>
      (field.itemLabel ?? controller.l10n.message('entry'))
          .replaceAll('{index}', '${index + 1}')
          .replaceAll('{value}', '${index + 1}');

  @override
  Widget build(BuildContext context) {
    final state = controller.state(field.id);
    final style = resolveFieldStyle(context, field, controller);
    final l10n = controller.l10n;
    final scheme = Theme.of(context).colorScheme;

    return ValueListenableBuilder<List<RepeaterEntry>>(
      valueListenable: state.entries,
      builder: (context, entries, _) => ValueListenableBuilder<bool>(
        valueListenable: state.enabled,
        builder: (context, enabled, _) => ValueListenableBuilder<String?>(
          valueListenable: state.error,
          builder: (context, error, _) {
            final interactive = enabled && !field.readOnly;
            final canAdd = interactive && controller.canAddEntry(field.id);
            final canRemove =
                interactive && controller.canRemoveEntry(field.id);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ?buildFieldLabel(context, field, controller),
                if (field.helperText != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      field.helperText!,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.merge(style.helperStyle),
                    ),
                  ),
                for (var i = 0; i < entries.length; i++)
                  Padding(
                    key: ValueKey(entries[i].key),
                    padding: const EdgeInsets.only(bottom: 12),
                    // A Material (not a decorated Container) so ListTiles
                    // inside paint their ink and background correctly.
                    child: Material(
                      color: style.containerColor ?? scheme.surfaceContainerLow,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          style.containerRadius ?? 12,
                        ),
                        side: BorderSide(color: scheme.outlineVariant),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 4, 4, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _title(i),
                                    style: Theme.of(
                                      context,
                                    ).textTheme.labelLarge,
                                  ),
                                ),
                                if (field.reorderable && interactive) ...[
                                  IconButton(
                                    icon: const Icon(
                                      Icons.arrow_upward,
                                      size: 18,
                                    ),
                                    tooltip: l10n.message('moveUp'),
                                    onPressed: i == 0
                                        ? null
                                        : () => controller.moveEntry(
                                            field.id,
                                            i,
                                            i - 1,
                                          ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.arrow_downward,
                                      size: 18,
                                    ),
                                    tooltip: l10n.message('moveDown'),
                                    onPressed: i == entries.length - 1
                                        ? null
                                        : () => controller.moveEntry(
                                            field.id,
                                            i,
                                            i + 1,
                                          ),
                                  ),
                                ],
                                IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  tooltip: l10n.message('removeEntry'),
                                  onPressed: canRemove
                                      ? () =>
                                            controller.removeEntry(field.id, i)
                                      : null,
                                ),
                              ],
                            ),
                            for (final child in field.fields)
                              FieldWrapper(
                                key: ValueKey('${entries[i].key}.${child.id}'),
                                field: child,
                                controller: entries[i].controller,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                if (canAdd)
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.add),
                      label: Text(field.addLabel ?? l10n.message('addEntry')),
                      onPressed: () => controller.addEntry(field.id),
                    ),
                  ),
                if (error != null)
                  buildFieldError(context, field, controller, error),
              ],
            );
          },
        ),
      ),
    );
  }
}
