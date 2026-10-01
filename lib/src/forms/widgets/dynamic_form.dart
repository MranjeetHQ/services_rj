import 'package:flutter/material.dart';

import '../controllers/dynamic_form_controller.dart';
import '../models/field_config.dart';
import '../models/field_overrides.dart';
import '../models/field_type.dart';
import '../models/form_config.dart';
import '../models/option_item.dart';
import '../parser/form_parser.dart';
import '../theme/dynamic_form_theme.dart';
import 'field_wrapper.dart';
import 'multi_step_form.dart';

/// The main entry widget: renders a complete form from JSON.
///
/// ```dart
/// DynamicForm(
///   controller: controller,
///   json: formJson, // String or Map<String, dynamic>
///   onSubmit: (data) => print(data),
///   onChanged: (data) => print(data),
/// )
/// ```
///
/// Performance notes:
/// * Fields are built lazily with [ListView.builder] (virtual scrolling) —
///   1000+ field forms only build what is on screen.
/// * Each field listens to its own [ValueNotifier]s; typing in one field
///   never rebuilds another.
/// * The list itself only rebuilds when the *structure* changes
///   (add/remove field, new JSON).
class DynamicForm extends StatefulWidget {
  /// Creates a dynamic form.
  const DynamicForm({
    super.key,
    required this.controller,
    required this.json,
    this.onSubmit,
    this.onChanged,
    this.onValidation,
    this.onError,
    this.shrinkWrap = false,
    this.physics,
    this.showSubmitButton = false,
    this.submitLabel,
    this.header,
    this.footer,
    this.confirmDiscard,
    this.initialData,
    this.fieldOverrides = const {},
    this.typeOverrides = const {},
    this.onOptionAdded,
  });

  /// The form controller (create once, dispose in your State's dispose).
  final DynamicFormController controller;

  /// Form definition: a JSON string or decoded `Map<String, dynamic>`.
  final Object json;

  /// Called with valid form data after [DynamicFormController.submit].
  final void Function(Map<String, dynamic> data)? onSubmit;

  /// Called on every value change with the full form data.
  final void Function(Map<String, dynamic> data)? onChanged;

  /// Called after each validation pass with the error map.
  final void Function(Map<String, String> errors)? onValidation;

  /// Called when a submit fails validation.
  final void Function(Map<String, String> errors)? onError;

  /// Embed in another scrollable.
  final bool shrinkWrap;

  /// Scroll physics.
  final ScrollPhysics? physics;

  /// Render a submit button after the last field.
  final bool showSubmitButton;

  /// Label for the built-in submit button.
  final String? submitLabel;

  /// Optional widget above the fields.
  final Widget? header;

  /// Optional widget below the fields.
  final Widget? footer;

  /// Guard against losing unsaved changes: when enabled, navigating back
  /// while the form is dirty shows a confirmation dialog. `null` (default)
  /// follows the JSON root `"confirmDiscard"` flag; pass `true`/`false` to
  /// override from code. Customize the dialog via
  /// [DynamicFormThemeData.discardDialogBuilder] or the JSON
  /// `discardTitle` / `discardMessage` strings.
  final bool? confirmDiscard;

  /// Prefill record for **edit mode**: field id → value. Wins over the JSON
  /// root `"data"` map and field-level `initialValue`s. The prefilled form
  /// starts clean (no discard dialog until the user edits) and
  /// [DynamicFormController.reset] restores these values. Passing a new map
  /// instance later re-prefills at runtime.
  final Map<String, dynamic>? initialData;

  /// Code-level customization per field id: custom widget, style layer,
  /// decoration hook, option renderer, wrapper, label/hint text.
  final Map<String, FieldOverrides> fieldOverrides;

  /// Code-level customization for every field of a type. Field-id
  /// overrides win.
  final Map<FieldType, FieldOverrides> typeOverrides;

  /// Called when the user adds an option to a field with
  /// `"allowCustomOptions": true`.
  final void Function(String fieldId, OptionItem option)? onOptionAdded;

  @override
  State<DynamicForm> createState() => _DynamicFormState();
}

class _DynamicFormState extends State<DynamicForm> {
  late FormConfig _config;

  @override
  void initState() {
    super.initState();
    _attach();
  }

  @override
  void didUpdateWidget(DynamicForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.json, widget.json)) {
      _attach(); // Runtime JSON change: re-parse, preserve matching values.
    } else if (!identical(oldWidget.initialData, widget.initialData) &&
        widget.initialData != null) {
      // New record loaded at runtime (e.g. edit target switched).
      widget.controller.setFormData(widget.initialData!, asInitial: true);
      _wire();
    } else {
      _wire();
    }
  }

  void _attach() {
    _config = FormParser.parse(widget.json);
    widget.controller
      ..fieldOverrides = widget.fieldOverrides
      ..typeOverrides = widget.typeOverrides;
    widget.controller.attach(_config, initialData: widget.initialData);
    _wire();
  }

  void _wire() {
    widget.controller
      ..fieldOverrides = widget.fieldOverrides
      ..typeOverrides = widget.typeOverrides
      ..onOptionAdded = widget.onOptionAdded
      ..onSubmit = widget.onSubmit
      ..onValidation = widget.onValidation
      ..onError = widget.onError
      ..onChanged = widget.onChanged == null
          ? null
          : (id, value, data) => widget.onChanged!(data);
  }

  Future<void> _handleBlockedPop(BuildContext context) async {
    final theme = DynamicFormTheme.of(context);
    final l10n = widget.controller.l10n;
    final navigator = Navigator.of(context);
    final bool? discard;
    if (theme.discardDialogBuilder != null) {
      discard = await theme.discardDialogBuilder!(context);
    } else {
      discard = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(_config.discardTitle ?? l10n.message('discardTitle')),
          content: Text(
            _config.discardMessage ?? l10n.message('discardMessage'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.message('cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.message('discard')),
            ),
          ],
        ),
      );
    }
    if (discard ?? false) {
      widget.controller.markClean();
      if (navigator.mounted) navigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = _config.steps.isNotEmpty
        ? MultiStepForm(
            controller: widget.controller,
            config: _config,
            onSubmit: widget.onSubmit,
          )
        : _buildFieldList();
    final guard = widget.confirmDiscard ?? _config.confirmDiscard;
    if (!guard) return body;
    return ValueListenableBuilder<bool>(
      valueListenable: widget.controller.dirty,
      builder: (context, isDirty, child) => PopScope(
        canPop: !isDirty,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          // Re-check instead of trusting the built canPop: a value change
          // in the same frame as the back action would otherwise race.
          if (!widget.controller.isDirty) {
            Navigator.of(context).pop();
          } else {
            _handleBlockedPop(context);
          }
        },
        child: child!,
      ),
      child: body,
    );
  }

  Widget _buildFieldList() {
    return ValueListenableBuilder<int>(
      valueListenable: widget.controller.structureRevision,
      builder: (context, _, __) {
        final order = widget.controller.fieldOrder;
        final topLevelIds = _config.fields
            .where((f) => order.contains(f.id))
            .map((f) => f.id)
            .toList();
        final extras = order
            .where((id) => !_config.allFields.any((f) => _containsId(f, id)))
            .toList();
        final ids = [...topLevelIds, ...extras];
        final itemCount =
            ids.length +
            (widget.header != null ? 1 : 0) +
            (widget.footer != null ? 1 : 0) +
            (widget.showSubmitButton ? 1 : 0);

        return ListView.builder(
          shrinkWrap: widget.shrinkWrap,
          physics: widget.physics,
          itemCount: itemCount,
          itemBuilder: (context, index) {
            var i = index;
            if (widget.header != null) {
              if (i == 0) return widget.header!;
              i--;
            }
            if (i < ids.length) {
              final field = widget.controller.state(ids[i]).config;
              return FieldWrapper(
                key: ValueKey(ids[i]),
                field: field,
                controller: widget.controller,
              );
            }
            i -= ids.length;
            if (widget.showSubmitButton && i == 0) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: FilledButton(
                  onPressed: widget.controller.submit,
                  child: Text(
                    widget.submitLabel ??
                        widget.controller.l10n.message('submit'),
                  ),
                ),
              );
            }
            return widget.footer!;
          },
        );
      },
    );
  }

  static bool _containsId(FieldConfig fieldConfig, String id) {
    if (fieldConfig.id == id) return true;
    for (final child in fieldConfig.fields) {
      if (_containsId(child, id)) return true;
    }
    return false;
  }
}
