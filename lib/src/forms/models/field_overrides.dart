import 'package:flutter/material.dart';

import '../builders/field_factory.dart';
import 'field_config.dart';
import 'field_style.dart';
import 'option_item.dart';

/// Renders one option of a selection field.
typedef OptionWidgetBuilder =
    Widget Function(BuildContext context, OptionItem option, bool selected);

/// Wraps the rendered field widget (add a card, a badge, an info button…).
typedef FieldWidgetWrapper =
    Widget Function(BuildContext context, FieldConfig field, Widget child);

/// Code-level customization for one field (by id) or every field of a type,
/// for the things JSON cannot express.
///
/// ```dart
/// DynamicForm(
///   controller: controller,
///   json: formJson,
///   fieldOverrides: {
///     'priority': FieldOverrides(
///       style: FieldStyleConfig(activeColor: Colors.deepOrange),
///       optionBuilder: (context, option, selected) => Row(children: [
///         Icon(selected ? Icons.flag : Icons.outlined_flag),
///         Text(option.label),
///       ]),
///     ),
///     'notes': FieldOverrides(
///       wrapper: (context, field, child) => Card(child: child),
///     ),
///   },
///   typeOverrides: {
///     FieldType.email: FieldOverrides(
///       decoration: (context, field, d) => d.copyWith(suffixText: '@work'),
///     ),
///   },
/// )
/// ```
///
/// Precedence: id overrides win over type overrides, which win over JSON.
class FieldOverrides {
  /// Creates field overrides.
  const FieldOverrides({
    this.builder,
    this.style,
    this.decoration,
    this.optionBuilder,
    this.wrapper,
    this.label,
    this.hint,
    this.helperText,
  });

  /// Replaces the whole field widget.
  final FieldBuilder? builder;

  /// Highest-precedence style layer (merged over theme, form and field
  /// JSON styles).
  final FieldStyleConfig? style;

  /// Final post-processing of the generated [InputDecoration].
  final InputDecoration Function(
    BuildContext context,
    FieldConfig field,
    InputDecoration decoration,
  )?
  decoration;

  /// Custom rendering of each option (radio / checkbox groups, chips,
  /// segmented, toggle buttons and dropdown menu items).
  final OptionWidgetBuilder? optionBuilder;

  /// Wraps the rendered field.
  final FieldWidgetWrapper? wrapper;

  /// Replaces the JSON label (e.g. a translated string).
  final String? label;

  /// Replaces the JSON hint.
  final String? hint;

  /// Replaces the JSON helper text.
  final String? helperText;

  /// Combines two overrides; properties of [other] win.
  FieldOverrides merge(FieldOverrides? other) {
    if (other == null) return this;
    return FieldOverrides(
      builder: other.builder ?? builder,
      style: FieldStyleConfig.merge([style, other.style]),
      decoration: other.decoration ?? decoration,
      optionBuilder: other.optionBuilder ?? optionBuilder,
      wrapper: other.wrapper ?? wrapper,
      label: other.label ?? label,
      hint: other.hint ?? hint,
      helperText: other.helperText ?? helperText,
    );
  }

  /// Applies the text overrides to [field].
  FieldConfig apply(FieldConfig field) =>
      label == null && hint == null && helperText == null
      ? field
      : field.copyWith(label: label, hint: hint, helperText: helperText);
}
