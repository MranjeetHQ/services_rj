import 'package:flutter/material.dart';

import '../controllers/dynamic_form_controller.dart';
import '../models/field_config.dart';
import '../models/field_type.dart';
import 'decoration_helper.dart';

/// Renderer for date, time and datetime picker fields.
///
/// Values are stored as ISO-8601 strings (`2026-07-24`, `14:30`,
/// `2026-07-24T14:30`) so form data stays JSON-serializable.
class DynamicDateTimeField extends StatelessWidget {
  /// Creates a date/time field.
  const DynamicDateTimeField({
    super.key,
    required this.field,
    required this.controller,
  });

  /// Field configuration.
  final FieldConfig field;

  /// Owning form controller.
  final DynamicFormController controller;

  Future<void> _pick(BuildContext context) async {
    final now = DateTime.now();
    final current = DateTime.tryParse(
      controller.getValue(field.id)?.toString() ?? '',
    );
    final first =
        DateTime.tryParse(field.ex<String>('firstDate') ?? '') ??
        DateTime(now.year - 100);
    final last =
        DateTime.tryParse(field.ex<String>('lastDate') ?? '') ??
        DateTime(now.year + 100);

    String two(int n) => n.toString().padLeft(2, '0');

    if (field.type == FieldType.time) {
      final t = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (t != null) {
        controller.setValue(field.id, '${two(t.hour)}:${two(t.minute)}');
      }
      return;
    }

    final d = await showDatePicker(
      context: context,
      initialDate: current ?? now,
      firstDate: first,
      lastDate: last,
    );
    if (d == null) return;
    if (field.type == FieldType.date) {
      controller.setValue(field.id, '${d.year}-${two(d.month)}-${two(d.day)}');
      return;
    }
    if (!context.mounted) return;
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    final dt = DateTime(d.year, d.month, d.day, t?.hour ?? 0, t?.minute ?? 0);
    controller.setValue(
      field.id,
      '${dt.year}-${two(dt.month)}-${two(dt.day)}T${two(dt.hour)}:${two(dt.minute)}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = controller.state(field.id);
    final icon = field.type == FieldType.time
        ? Icons.access_time
        : Icons.calendar_today;

    return ValueListenableBuilder<Object?>(
      valueListenable: state.value,
      builder: (context, value, _) => ValueListenableBuilder<String?>(
        valueListenable: state.error,
        builder: (context, error, _) => ValueListenableBuilder<bool>(
          valueListenable: state.enabled,
          builder: (context, enabled, _) => TextField(
            focusNode: state.focusNode,
            readOnly: true,
            enabled: enabled,
            controller: TextEditingController(text: value?.toString() ?? ''),
            decoration: buildFieldDecoration(
              context,
              field,
              controller,
              errorText: error,
              suffix: Icon(icon),
            ),
            onTap: enabled && !field.readOnly ? () => _pick(context) : null,
          ),
        ),
      ),
    );
  }
}
