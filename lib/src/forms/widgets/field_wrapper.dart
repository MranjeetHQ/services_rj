import 'package:flutter/material.dart';

import '../builders/field_factory.dart';
import '../controllers/dynamic_form_controller.dart';
import '../fields/date_time_fields.dart';
import '../fields/decoration_helper.dart';
import '../fields/media_fields.dart';
import '../fields/misc_fields.dart';
import '../fields/repeater_field.dart';
import '../fields/selection_fields.dart';
import '../fields/slider_fields.dart';
import '../fields/text_fields.dart';
import '../models/field_config.dart';
import '../models/field_enums.dart';
import '../models/field_type.dart';
import '../theme/dynamic_form_theme.dart';

/// Wraps a single field: resolves its renderer, applies visibility (with a
/// fade/size animation), margin/padding/size, and semantic labels.
///
/// Listens **only** to this field's notifiers — sibling fields never rebuild.
class FieldWrapper extends StatelessWidget {
  /// Creates a wrapper for [field].
  const FieldWrapper({
    super.key,
    required this.field,
    required this.controller,
  });

  /// Field configuration.
  final FieldConfig field;

  /// Owning form controller.
  final DynamicFormController controller;

  Widget _buildInner(BuildContext context, FieldConfig field) {
    final overrideBuilder = controller.overridesFor(field)?.builder;
    if (overrideBuilder != null) {
      return overrideBuilder(context, field, controller);
    }
    final custom = FieldFactory.resolve(field);
    if (custom != null) return custom(context, field, controller);

    switch (field.type) {
      case FieldType.text:
      case FieldType.textarea:
      case FieldType.password:
      case FieldType.email:
      case FieldType.number:
      case FieldType.decimal:
      case FieldType.phone:
      case FieldType.url:
      case FieldType.search:
      case FieldType.otp:
      case FieldType.pin:
      case FieldType.readOnly:
      case FieldType.richText:
      case FieldType.markdown:
      case FieldType.htmlEditor:
        return DynamicTextField(field: field, controller: controller);
      case FieldType.date:
      case FieldType.time:
      case FieldType.datetime:
        return DynamicDateTimeField(field: field, controller: controller);
      case FieldType.dropdown:
      case FieldType.multiselect:
      case FieldType.country:
      case FieldType.state:
      case FieldType.city:
        return DynamicDropdownField(field: field, controller: controller);
      case FieldType.checkbox:
      case FieldType.switchField:
      case FieldType.radio:
        return DynamicBoolField(field: field, controller: controller);
      case FieldType.checkboxGroup:
      case FieldType.radioGroup:
      case FieldType.chips:
      case FieldType.toggleButtons:
      case FieldType.segmented:
        return DynamicGroupField(field: field, controller: controller);
      case FieldType.slider:
      case FieldType.rangeSlider:
      case FieldType.rating:
      case FieldType.stepper:
        return DynamicSliderField(field: field, controller: controller);
      case FieldType.autocomplete:
      case FieldType.typeahead:
        return DynamicAutocompleteField(field: field, controller: controller);
      case FieldType.colorPicker:
        return DynamicColorField(field: field, controller: controller);
      case FieldType.hidden:
        return const SizedBox.shrink();
      case FieldType.label:
        return DynamicDisplayField(field: field, kind: 'label');
      case FieldType.divider:
        return DynamicDisplayField(field: field, kind: 'divider');
      case FieldType.spacer:
        return DynamicDisplayField(field: field, kind: 'spacer');
      case FieldType.sectionHeader:
        return DynamicDisplayField(field: field, kind: 'sectionHeader');
      case FieldType.expansion:
        return ExpansionTile(
          title: Text(field.label ?? ''),
          initiallyExpanded: field.ex<bool>('expanded') ?? false,
          childrenPadding: const EdgeInsets.only(left: 8, bottom: 8),
          children: [
            for (final child in field.fields)
              FieldWrapper(field: child, controller: controller),
          ],
        );
      case FieldType.group:
        final style = resolveFieldStyle(context, field, controller);
        final group = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ?buildFieldLabel(context, field, controller),
            for (final child in field.fields)
              FieldWrapper(field: child, controller: controller),
          ],
        );
        if (style.containerColor == null) return group;
        return Container(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          decoration: BoxDecoration(
            color: style.containerColor,
            borderRadius: BorderRadius.circular(style.containerRadius ?? 12),
          ),
          child: group,
        );
      case FieldType.repeater:
        return DynamicRepeaterField(field: field, controller: controller);
      case FieldType.image:
      case FieldType.camera:
        return DynamicImageField(field: field, controller: controller);
      case FieldType.file:
        return DynamicFileField(field: field, controller: controller);
      case FieldType.signature:
      case FieldType.qrScanner:
      case FieldType.barcodeScanner:
      case FieldType.custom:
        return MissingAdapterField(field: field);
    }
  }

  /// Field types drawn with an `InputDecoration`, whose label can be moved
  /// above the field.
  static bool _hasInputDecoration(FieldType type) => const {
    FieldType.text,
    FieldType.textarea,
    FieldType.password,
    FieldType.email,
    FieldType.number,
    FieldType.decimal,
    FieldType.phone,
    FieldType.url,
    FieldType.search,
    FieldType.otp,
    FieldType.pin,
    FieldType.readOnly,
    FieldType.richText,
    FieldType.markdown,
    FieldType.htmlEditor,
    FieldType.date,
    FieldType.time,
    FieldType.datetime,
    FieldType.dropdown,
    FieldType.multiselect,
    FieldType.country,
    FieldType.state,
    FieldType.city,
    FieldType.autocomplete,
    FieldType.typeahead,
  }.contains(type);

  @override
  Widget build(BuildContext context) {
    if (field.type == FieldType.hidden || field.id.isEmpty) {
      return const SizedBox.shrink();
    }
    final theme = DynamicFormTheme.of(context);
    final state = controller.state(field.id);
    final overrides = controller.overridesFor(field);
    final effective = overrides?.apply(field) ?? field;
    Widget inner = _buildInner(context, effective);
    if (_hasInputDecoration(effective.type) &&
        resolveFieldStyle(context, effective, controller).labelPosition ==
            LabelPosition.above) {
      final label = buildFieldLabel(context, effective, controller);
      if (label != null) {
        inner = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [label, inner],
        );
      }
    }
    if (effective.tooltip != null) {
      inner = Tooltip(message: effective.tooltip, child: inner);
    }
    if (overrides?.wrapper != null) {
      inner = overrides!.wrapper!(context, effective, inner);
    }
    return ValueListenableBuilder<bool>(
      valueListenable: state.visible,
      builder: (context, visible, child) => AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: _RevealTransition(sizeFactor: animation, child: child),
        ),
        child: visible ? child : const SizedBox.shrink(),
      ),
      child: Semantics(
        label: field.label,
        textField: false,
        child: Container(
          width: field.width,
          height: field.height,
          margin: field.margin ?? EdgeInsets.only(bottom: theme.fieldSpacing),
          padding: field.padding,
          child: inner,
        ),
      ),
    );
  }
}

/// Grows a child from zero height, like [SizeTransition], but clips only
/// while the animation runs. A settled child is never clipped, so an outlined
/// field's floating label (which sits half above its box) stays fully visible.
class _RevealTransition extends AnimatedWidget {
  const _RevealTransition({required this.sizeFactor, required this.child})
    : super(listenable: sizeFactor);

  final Animation<double> sizeFactor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final settled = sizeFactor.value >= 1;
    final aligned = Align(
      alignment: Alignment.topCenter,
      heightFactor: sizeFactor.value.clamp(0.0, 1.0),
      child: child,
    );
    return settled ? aligned : ClipRect(child: aligned);
  }
}
