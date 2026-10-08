import 'package:flutter/material.dart';

import '../controllers/dynamic_form_controller.dart';
import '../models/field_config.dart';
import '../models/field_enums.dart';
import '../models/field_style.dart';
import '../models/field_type.dart';
import '../models/text_preset.dart';
import '../theme/dynamic_form_theme.dart';
import '../utils/field_utils.dart';

/// Resolves the effective [FieldStyleConfig] for a field by merging, in
/// order of increasing precedence: the app theme default, the form-level
/// `style`, the field's own `style` / `decoration`, and the code-level
/// `FieldOverrides.style`.
FieldStyleConfig resolveFieldStyle(
  BuildContext context,
  FieldConfig field,
  DynamicFormController controller,
) {
  final theme = DynamicFormTheme.of(context);
  return FieldStyleConfig.merge([
    theme.defaultFieldStyle,
    controller.config?.style,
    field.styleConfig,
    controller.overridesFor(field)?.style,
  ]);
}

InputBorder _border(
  FieldStyleVariant variant,
  double radius,
  Color? color,
  double width,
) {
  final side = color == null
      ? BorderSide(width: width)
      : BorderSide(color: color, width: width);
  switch (variant) {
    case FieldStyleVariant.underline:
      return UnderlineInputBorder(borderSide: side);
    case FieldStyleVariant.filled:
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: BorderSide.none,
      );
    case FieldStyleVariant.none:
      return InputBorder.none;
    case FieldStyleVariant.outlined:
    case FieldStyleVariant.rounded:
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: side,
      );
  }
}

/// Builds the standard [InputDecoration] for a field, honoring JSON props,
/// JSON style variants and the app-level
/// [DynamicFormThemeData.decorationBuilder] hook.
InputDecoration buildFieldDecoration(
  BuildContext context,
  FieldConfig field,
  DynamicFormController controller, {
  String? errorText,
  Widget? suffix,

  /// Replaces the prefix icon and `prefixText` (used by the country code
  /// picker of phone fields).
  Widget? prefix,
}) {
  final theme = DynamicFormTheme.of(context);
  final style = resolveFieldStyle(context, field, controller);
  final preset = TextPresets.resolve(field.preset);
  final prefixIcon = field.prefixIcon ?? preset?.icon;

  final position = style.labelPosition ?? LabelPosition.floating;
  // `above` draws the label outside the field (see FieldWrapper); `hidden`
  // shows the label text as the hint instead.
  final hint = field.hint ?? preset?.hint;
  final marked = FieldLabel.showsMark(context, field, controller);

  var decoration = InputDecoration(
    labelText: position == LabelPosition.floating && !marked
        ? field.label
        : null,
    // A marked label is a widget so the `*` can be coloured and follow
    // `requiredWhen` without rebuilding the field.
    label: position == LabelPosition.floating && marked
        ? FieldLabel(field: field, controller: controller)
        : null,
    hintText: position == LabelPosition.hidden
        ? hint ?? FieldLabel.plainText(field, controller, context)
        : hint,
    helperText: field.helperText,
    errorText: errorText,
    isDense: style.dense ?? theme.dense,
    prefixText: prefix != null ? null : field.prefixText,
    suffixText: field.suffixText,
    prefixIcon:
        prefix ??
        (FieldUtils.icon(prefixIcon) != null
            ? Icon(FieldUtils.icon(prefixIcon))
            : null),
    prefixIconConstraints: prefix != null
        ? const BoxConstraints(minWidth: 0, minHeight: 0)
        : null,
    suffixIcon:
        suffix ??
        (FieldUtils.icon(field.suffixIcon) != null
            ? Icon(FieldUtils.icon(field.suffixIcon))
            : null),
    counterText: field.showCounter ? null : '',
  );

  if (style.isNotEmpty) {
    final variant = style.variant;
    if (variant != null) {
      final radius =
          style.borderRadius ??
          switch (variant) {
            FieldStyleVariant.rounded => 28.0,
            FieldStyleVariant.filled => 12.0,
            _ => 8.0,
          };
      final width = style.borderWidth ?? 1;
      final base = _border(variant, radius, style.borderColor, width);
      final focused = _border(
        variant,
        radius,
        style.focusedBorderColor ?? Theme.of(context).colorScheme.primary,
        width + 1,
      );
      final error = _border(
        variant,
        radius,
        Theme.of(context).colorScheme.error,
        width,
      );
      decoration = decoration.copyWith(
        border: base,
        enabledBorder: base,
        focusedBorder: variant == FieldStyleVariant.none
            ? InputBorder.none
            : focused,
        errorBorder: variant == FieldStyleVariant.none
            ? InputBorder.none
            : error,
        focusedErrorBorder: variant == FieldStyleVariant.none
            ? InputBorder.none
            : error,
        filled: variant == FieldStyleVariant.filled || style.fillColor != null,
      );
    }
    decoration = decoration.copyWith(
      fillColor: style.fillColor,
      filled: style.fillColor != null ? true : decoration.filled,
      contentPadding: style.contentPadding,
      labelStyle: style.labelStyle,
      hintStyle: style.hintStyle,
      helperStyle: style.helperStyle,
      errorStyle: style.errorStyle,
      prefixIconColor: style.iconColor,
      suffixIconColor: style.iconColor,
      floatingLabelBehavior: switch (style.labelBehavior) {
        LabelBehavior.always => FloatingLabelBehavior.always,
        LabelBehavior.never => FloatingLabelBehavior.never,
        LabelBehavior.auto => FloatingLabelBehavior.auto,
        null => null,
      },
    );
  }

  if (theme.decorationBuilder != null) {
    decoration = theme.decorationBuilder!(context, field, decoration);
  }
  final override = controller.overridesFor(field)?.decoration;
  if (override != null) decoration = override(context, field, decoration);
  return decoration;
}

/// Error line used by non-input fields (groups, sliders, repeaters).
Widget buildFieldError(
  BuildContext context,
  FieldConfig field,
  DynamicFormController controller,
  String error,
) {
  final theme = DynamicFormTheme.of(context);
  final custom = theme.errorBuilder?.call(context, error);
  if (custom != null) return custom;
  final style = resolveFieldStyle(context, field, controller).errorStyle;
  return Padding(
    padding: const EdgeInsets.only(top: 4, left: 4),
    child: Text(
      error,
      style: TextStyle(
        color: Theme.of(context).colorScheme.error,
        fontSize: 12,
      ).merge(style),
    ),
  );
}

/// Standalone label used by non-input fields (groups, sliders, repeaters).
Widget? buildFieldLabel(
  BuildContext context,
  FieldConfig field,
  DynamicFormController controller,
) {
  if (field.label == null) return null;
  final theme = DynamicFormTheme.of(context);
  final style = resolveFieldStyle(context, field, controller).labelStyle;
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: FieldLabel(
      field: field,
      controller: controller,
      style: (theme.labelStyle ?? Theme.of(context).textTheme.titleSmall)
          ?.merge(style),
    ),
  );
}

/// A field's label followed by its required / optional mark (style key
/// `requiredMark`): a red `*` on required fields by default, or
/// "(optional)" on the others. Listens to the field's required state, so
/// `requiredWhen` and `DynamicFormController.setRequired` update the mark
/// at once. Screen readers hear "required" instead of "star".
class FieldLabel extends StatelessWidget {
  /// Creates a label for [field].
  const FieldLabel({
    super.key,
    required this.field,
    required this.controller,
    this.style,
  });

  /// Field whose label is shown.
  final FieldConfig field;

  /// Owning form controller.
  final DynamicFormController controller;

  /// Text style of the label (the mark merges `requiredMarkStyle`).
  final TextStyle? style;

  /// Field types that hold a value the user enters, so required / optional
  /// means something. Display, container and hidden fields never get a mark.
  static bool canBeMarked(FieldConfig field) =>
      field.label != null &&
      !field.readOnly &&
      !const {
        FieldType.hidden,
        FieldType.readOnly,
        FieldType.label,
        FieldType.divider,
        FieldType.spacer,
        FieldType.sectionHeader,
        FieldType.group,
        FieldType.expansion,
      }.contains(field.type);

  /// Whether [field]'s label may show a mark in this form.
  static bool showsMark(
    BuildContext context,
    FieldConfig field,
    DynamicFormController controller,
  ) =>
      canBeMarked(field) &&
      controller.hasField(field.id) &&
      _mode(context, field, controller) != RequiredMark.none;

  static RequiredMark _mode(
    BuildContext context,
    FieldConfig field,
    DynamicFormController controller,
  ) =>
      resolveFieldStyle(context, field, controller).requiredMark ??
      RequiredMark.asterisk;

  /// The label and mark as plain text (`Full name *`), for hints.
  static String? plainText(
    FieldConfig field,
    DynamicFormController controller,
    BuildContext context,
  ) {
    final label = field.label;
    if (label == null || !showsMark(context, field, controller)) return label;
    final mark = _markText(
      _mode(context, field, controller),
      controller.state(field.id).required.value,
      controller,
    );
    return mark == null ? label : '$label $mark';
  }

  static String? _markText(
    RequiredMark mode,
    bool required,
    DynamicFormController controller,
  ) {
    if (required &&
        (mode == RequiredMark.asterisk || mode == RequiredMark.both)) {
      return '*';
    }
    if (!required &&
        (mode == RequiredMark.optional || mode == RequiredMark.both)) {
      return controller.l10n.message('optionalMark');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final label = field.label ?? '';
    if (!showsMark(context, field, controller)) {
      return Text(label, style: style);
    }
    final mode = _mode(context, field, controller);
    final markStyle = resolveFieldStyle(
      context,
      field,
      controller,
    ).requiredMarkStyle;
    final scheme = Theme.of(context).colorScheme;
    return ValueListenableBuilder<bool>(
      valueListenable: controller.state(field.id).required,
      builder: (context, required, _) {
        final mark = _markText(mode, required, controller);
        return Text.rich(
          TextSpan(
            text: label,
            children: [
              if (mark != null)
                TextSpan(
                  text: ' $mark',
                  semanticsLabel: required
                      ? ', ${controller.l10n.message('requiredMark')}'
                      : null,
                  style: TextStyle(
                    color: required ? scheme.error : scheme.onSurfaceVariant,
                    fontWeight: required ? null : FontWeight.normal,
                  ).merge(markStyle),
                ),
            ],
          ),
          style: style,
        );
      },
    );
  }
}
