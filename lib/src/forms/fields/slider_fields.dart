import 'package:flutter/material.dart';

import '../controllers/dynamic_form_controller.dart';
import '../models/field_config.dart';
import '../models/field_type.dart';
import 'decoration_helper.dart';

/// Renderer for slider, rangeSlider, rating and stepper fields.
class DynamicSliderField extends StatelessWidget {
  /// Creates a slider-family field.
  const DynamicSliderField({
    super.key,
    required this.field,
    required this.controller,
  });

  /// Field configuration.
  final FieldConfig field;

  /// Owning form controller.
  final DynamicFormController controller;

  @override
  Widget build(BuildContext context) {
    final state = controller.state(field.id);
    final active = resolveFieldStyle(context, field, controller).activeColor;
    final min = field.ex<double>('min') ?? 0;
    final max = field.ex<double>('max') ?? 100;
    final divisions = field.ex<int>('divisions');

    return ValueListenableBuilder<Object?>(
      valueListenable: state.value,
      builder: (context, value, _) => ValueListenableBuilder<bool>(
        valueListenable: state.enabled,
        builder: (context, isEnabled, _) => ValueListenableBuilder<String?>(
          valueListenable: state.error,
          builder: (context, error, _) {
            final enabled = isEnabled && !field.readOnly;
            Widget body;
            switch (field.type) {
              case FieldType.rangeSlider:
                final list = value as List? ?? [min, max];
                final range = RangeValues(
                  (list.first as num?)?.toDouble() ?? min,
                  (list.last as num?)?.toDouble() ?? max,
                );
                body = RangeSlider(
                  values: range,
                  min: min,
                  max: max,
                  divisions: divisions,
                  activeColor: active,
                  labels: RangeLabels(
                    '${range.start.round()}',
                    '${range.end.round()}',
                  ),
                  onChanged: enabled
                      ? (v) => controller.setValue(field.id, [v.start, v.end])
                      : null,
                );
              case FieldType.rating:
                final count = field.ex<int>('count') ?? 5;
                final rating = (value as num?)?.toInt() ?? 0;
                body = Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 1; i <= count; i++)
                      IconButton(
                        icon: Icon(
                          i <= rating ? Icons.star : Icons.star_border,
                          color: i <= rating ? (active ?? Colors.amber) : null,
                        ),
                        tooltip: '$i',
                        onPressed: enabled
                            ? () => controller.setValue(
                                field.id,
                                i == rating ? null : i,
                              )
                            : null,
                      ),
                  ],
                );
              case FieldType.stepper:
                final step = field.ex<num>('step') ?? 1;
                final n = (value as num?) ?? (field.ex<num>('min') ?? 0);
                body = Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton.outlined(
                      icon: const Icon(Icons.remove),
                      onPressed: enabled && n - step >= min
                          ? () => controller.setValue(field.id, n - step)
                          : null,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        '$n',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    IconButton.outlined(
                      icon: const Icon(Icons.add),
                      onPressed: enabled && n + step <= max
                          ? () => controller.setValue(field.id, n + step)
                          : null,
                    ),
                  ],
                );
              default: // slider
                final v = ((value as num?)?.toDouble() ?? min).clamp(min, max);
                body = Slider(
                  value: v,
                  min: min,
                  max: max,
                  divisions: divisions,
                  activeColor: active,
                  label: '${v.round()}',
                  onChanged: enabled
                      ? (nv) => controller.setValue(field.id, nv)
                      : null,
                );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ?buildFieldLabel(context, field, controller),
                body,
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
