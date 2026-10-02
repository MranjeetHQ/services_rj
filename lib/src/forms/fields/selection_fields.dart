import 'package:flutter/material.dart';

import '../controllers/dynamic_form_controller.dart';
import '../controllers/field_state.dart';
import '../models/field_config.dart';
import '../models/field_enums.dart';
import '../models/field_type.dart';
import '../models/option_item.dart';
import '../theme/dynamic_form_theme.dart';
import '../utils/field_utils.dart';
import 'decoration_helper.dart';

/// Rebuild-scoped helper: listens to value+error+enabled+options of a field.
class _FieldScope extends StatelessWidget {
  const _FieldScope({required this.state, required this.builder});

  final FieldRuntimeState state;
  final Widget Function(
    BuildContext,
    Object?,
    String?,
    bool,
    List<OptionItem>,
    bool loading,
  )
  builder;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Object?>(
      valueListenable: state.value,
      builder: (context, value, _) => ValueListenableBuilder<String?>(
        valueListenable: state.error,
        builder: (context, error, _) => ValueListenableBuilder<bool>(
          valueListenable: state.enabled,
          builder: (context, enabled, _) =>
              ValueListenableBuilder<List<OptionItem>>(
                valueListenable: state.options,
                builder: (context, options, _) => ValueListenableBuilder<bool>(
                  valueListenable: state.loadingOptions,
                  builder: (context, loading, _) =>
                      builder(context, value, error, enabled, options, loading),
                ),
              ),
        ),
      ),
    );
  }
}

/// Asks the user for a new option label, adds it to [field] and selects it.
/// Used by every selection field with `"allowCustomOptions": true`.
Future<void> promptCustomOption(
  BuildContext context,
  FieldConfig field,
  DynamicFormController controller,
) async {
  final label = await showDialog<String>(
    context: context,
    builder: (context) => _CustomOptionDialog(
      title: field.customOptionLabel ?? controller.l10n.message('addOption'),
      controller: controller,
    ),
  );
  final trimmed = label?.trim() ?? '';
  if (trimmed.isEmpty) return;
  final existing = controller
      .state(field.id)
      .options
      .value
      .where((o) => o.label.toLowerCase() == trimmed.toLowerCase())
      .firstOrNull;
  controller.addOption(
    field.id,
    existing ?? OptionItem(label: trimmed, value: trimmed, isCustom: true),
    select: true,
  );
}

/// Owns its text controller so it outlives the dialog's exit animation.
class _CustomOptionDialog extends StatefulWidget {
  const _CustomOptionDialog({required this.title, required this.controller});

  final String title;
  final DynamicFormController controller;

  @override
  State<_CustomOptionDialog> createState() => _CustomOptionDialogState();
}

class _CustomOptionDialogState extends State<_CustomOptionDialog> {
  final _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.controller.l10n;
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _text,
        autofocus: true,
        decoration: InputDecoration(labelText: l10n.message('optionLabel')),
        onSubmitted: (v) => Navigator.pop(context, v),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.message('cancel')),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _text.text),
          child: Text(l10n.message('add')),
        ),
      ],
    );
  }
}

Widget? _optionIcon(OptionItem o) {
  final icon = FieldUtils.icon(o.icon);
  return icon == null ? null : Icon(icon, size: 20);
}

Widget _optionText(BuildContext context, OptionItem o) {
  if (o.description == null) return Text(o.label);
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(o.label),
      Text(o.description!, style: Theme.of(context).textTheme.bodySmall),
    ],
  );
}

/// Renderer for dropdown / multiselect / country / state / city fields.
class DynamicDropdownField extends StatelessWidget {
  /// Creates a dropdown field.
  const DynamicDropdownField({
    super.key,
    required this.field,
    required this.controller,
  });

  /// Field configuration.
  final FieldConfig field;

  /// Owning form controller.
  final DynamicFormController controller;

  static const Object _addSentinel = '__services_rj_add_option__';

  bool get _multi => field.type == FieldType.multiselect;

  Future<void> _pickMulti(
    BuildContext context,
    List<OptionItem> options,
    List<Object?> selected,
  ) async {
    final l10n = controller.l10n;
    final max = field.maxItems;
    final result = await showDialog<List<Object?>>(
      context: context,
      builder: (context) {
        final current = [...selected];
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: Text(field.label ?? l10n.message('select')),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final o in options)
                    CheckboxListTile(
                      value: current.contains(o.value),
                      title: Text(o.label),
                      subtitle: o.description != null
                          ? Text(o.description!)
                          : null,
                      secondary: _optionIcon(o),
                      enabled:
                          o.enabled &&
                          (current.contains(o.value) ||
                              max == null ||
                              current.length < max),
                      onChanged: (checked) => setState(() {
                        checked ?? false
                            ? current.add(o.value)
                            : current.remove(o.value);
                      }),
                    ),
                ],
              ),
            ),
            actions: [
              if (field.allowCustomOptions)
                TextButton.icon(
                  icon: const Icon(Icons.add),
                  label: Text(
                    field.customOptionLabel ?? l10n.message('addOption'),
                  ),
                  onPressed: () {
                    Navigator.pop(context, current);
                    promptCustomOption(context, field, controller);
                  },
                ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.message('cancel')),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, current),
                child: Text(l10n.message('ok')),
              ),
            ],
          ),
        );
      },
    );
    if (result != null) controller.setValue(field.id, result);
  }

  @override
  Widget build(BuildContext context) {
    final theme = DynamicFormTheme.of(context);
    final overrides = controller.overridesFor(field);
    return _FieldScope(
      state: controller.state(field.id),
      builder: (context, value, error, enabled, options, loading) {
        if (loading) {
          return theme.loadingBuilder?.call(context) ??
              const Padding(
                padding: EdgeInsets.all(12),
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              );
        }
        if (_multi) {
          final selected = List<Object?>.from(value as List? ?? const []);
          final labels = options
              .where((o) => selected.contains(o.value))
              .map((o) => o.label)
              .join(', ');
          return InkWell(
            onTap: enabled && !field.readOnly
                ? () => _pickMulti(context, options, selected)
                : null,
            child: InputDecorator(
              decoration: buildFieldDecoration(
                context,
                field,
                controller,
                errorText: error,
                suffix: const Icon(Icons.arrow_drop_down),
              ),
              isEmpty: selected.isEmpty,
              child: Text(labels),
            ),
          );
        }
        final validValue = options.any((o) => o.value == value) ? value : null;
        return DropdownButtonFormField<Object?>(
          key: ValueKey(Object.hash(options.length, validValue)),
          initialValue: validValue,
          isExpanded: true,
          focusNode: controller.state(field.id).focusNode,
          decoration: buildFieldDecoration(
            context,
            field,
            controller,
            errorText: error,
          ),
          items: [
            for (final o in options)
              DropdownMenuItem(
                value: o.value,
                enabled: o.enabled,
                child:
                    overrides?.optionBuilder?.call(
                      context,
                      o,
                      o.value == validValue,
                    ) ??
                    Row(
                      children: [
                        if (_optionIcon(o) != null) ...[
                          _optionIcon(o)!,
                          const SizedBox(width: 8),
                        ],
                        Flexible(child: Text(o.label)),
                      ],
                    ),
              ),
            if (field.allowCustomOptions)
              DropdownMenuItem(
                value: _addSentinel,
                child: Row(
                  children: [
                    const Icon(Icons.add, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      field.customOptionLabel ??
                          controller.l10n.message('addOption'),
                    ),
                  ],
                ),
              ),
          ],
          onChanged: enabled && !field.readOnly
              ? (v) {
                  if (v == _addSentinel) {
                    promptCustomOption(context, field, controller);
                    return;
                  }
                  controller.setValue(field.id, v);
                }
              : null,
        );
      },
    );
  }
}

/// Renderer for checkbox, switch and single radio fields (bool-valued).
class DynamicBoolField extends StatelessWidget {
  /// Creates a boolean field.
  const DynamicBoolField({
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
    final style = resolveFieldStyle(context, field, controller);
    final active = style.activeColor;
    return _FieldScope(
      state: state,
      builder: (context, value, error, enabled, options, loading) {
        final checked = value == true;
        final interactive = enabled && !field.readOnly;
        void toggle(bool? v) => controller.setValue(field.id, v ?? false);
        final title = Text(field.label ?? '', style: style.labelStyle);
        final subtitle = field.helperText != null
            ? Text(field.helperText!, style: style.helperStyle)
            : null;
        Widget tile;
        switch (field.type) {
          case FieldType.switchField:
            tile = SwitchListTile(
              value: checked,
              title: title,
              subtitle: subtitle,
              activeThumbColor: active,
              onChanged: interactive ? toggle : null,
              focusNode: state.focusNode,
              contentPadding: EdgeInsets.zero,
            );
          case FieldType.radio:
            tile = RadioListTile<bool>(
              value: true,
              // ignore: deprecated_member_use
              groupValue: checked ? true : null,
              title: title,
              subtitle: subtitle,
              activeColor: active,
              // ignore: deprecated_member_use
              onChanged: interactive ? (_) => toggle(!checked) : null,
              contentPadding: EdgeInsets.zero,
            );
          default:
            tile = CheckboxListTile(
              value: checked,
              title: title,
              subtitle: subtitle,
              activeColor: active,
              onChanged: interactive ? toggle : null,
              focusNode: state.focusNode,
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            tile,
            if (error != null)
              buildFieldError(context, field, controller, error),
          ],
        );
      },
    );
  }
}

/// Renderer for checkboxGroup, radioGroup, chips, toggleButtons, segmented.
///
/// Supports `"optionLayout"` (`vertical`, `horizontal`, `wrap`, `grid` +
/// `"columns"`), option `description` / `icon`, `"maxItems"` for multi
/// selection and `"allowCustomOptions"`.
class DynamicGroupField extends StatelessWidget {
  /// Creates a group selection field.
  const DynamicGroupField({
    super.key,
    required this.field,
    required this.controller,
  });

  /// Field configuration.
  final FieldConfig field;

  /// Owning form controller.
  final DynamicFormController controller;

  bool get _multi =>
      field.type == FieldType.checkboxGroup ||
      ((field.type == FieldType.chips ||
              field.type == FieldType.segmented ||
              field.type == FieldType.toggleButtons) &&
          (field.ex<bool>('multiple') ?? false));

  OptionLayout get _layout =>
      field.optionLayout ??
      (field.type == FieldType.chips
          ? OptionLayout.wrap
          : OptionLayout.vertical);

  Widget _arrange(List<Widget> items) {
    switch (_layout) {
      case OptionLayout.vertical:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: items,
        );
      case OptionLayout.horizontal:
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: items),
        );
      case OptionLayout.wrap:
        return Wrap(spacing: 8, runSpacing: 4, children: items);
      case OptionLayout.grid:
        final columns = (field.columns ?? 2).clamp(1, 12);
        return LayoutBuilder(
          builder: (context, constraints) {
            const spacing = 8.0;
            final width =
                (constraints.maxWidth - spacing * (columns - 1)) / columns;
            return Wrap(
              spacing: spacing,
              runSpacing: 4,
              children: [
                for (final item in items) SizedBox(width: width, child: item),
              ],
            );
          },
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = resolveFieldStyle(context, field, controller);
    final active = style.activeColor;
    final overrides = controller.overridesFor(field);
    final l10n = controller.l10n;
    return _FieldScope(
      state: controller.state(field.id),
      builder: (context, value, error, enabled, options, loading) {
        final interactive = enabled && !field.readOnly;
        final selected = _multi
            ? List<Object?>.from(value as List? ?? const [])
            : <Object?>[?value];
        final max = field.maxItems;
        bool canPick(OptionItem o) =>
            interactive &&
            o.enabled &&
            (!_multi ||
                selected.contains(o.value) ||
                max == null ||
                selected.length < max);

        void select(Object? v, bool nowSelected) {
          if (_multi) {
            final next = [...selected];
            nowSelected ? next.add(v) : next.remove(v);
            controller.setValue(field.id, next);
          } else {
            controller.setValue(field.id, nowSelected ? v : null);
          }
        }

        Widget label(OptionItem o) =>
            overrides?.optionBuilder?.call(
              context,
              o,
              selected.contains(o.value),
            ) ??
            _optionText(context, o);

        final compact = _layout != OptionLayout.vertical;
        Widget compactItem(Widget control, OptionItem o, VoidCallback? onTap) =>
            InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    control,
                    if (_optionIcon(o) != null) ...[
                      _optionIcon(o)!,
                      const SizedBox(width: 6),
                    ],
                    Flexible(child: label(o)),
                  ],
                ),
              ),
            );

        final addLabel = field.customOptionLabel ?? l10n.message('addOption');
        final canAddCustom = field.allowCustomOptions && interactive;

        Widget body;
        switch (field.type) {
          case FieldType.checkboxGroup:
            body = _arrange([
              for (final o in options)
                compact
                    ? compactItem(
                        Checkbox(
                          value: selected.contains(o.value),
                          activeColor: active,
                          onChanged: canPick(o)
                              ? (v) => select(o.value, v ?? false)
                              : null,
                        ),
                        o,
                        canPick(o)
                            ? () => select(o.value, !selected.contains(o.value))
                            : null,
                      )
                    : CheckboxListTile(
                        value: selected.contains(o.value),
                        title: label(o),
                        secondary: _optionIcon(o),
                        activeColor: active,
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        onChanged: canPick(o)
                            ? (v) => select(o.value, v ?? false)
                            : null,
                      ),
            ]);
          case FieldType.radioGroup:
            body = _arrange([
              for (final o in options)
                compact
                    ? compactItem(
                        Radio<Object?>(
                          value: o.value,
                          // ignore: deprecated_member_use
                          groupValue: value,
                          activeColor: active,
                          // ignore: deprecated_member_use
                          onChanged: canPick(o)
                              ? (v) => controller.setValue(field.id, v)
                              : null,
                        ),
                        o,
                        canPick(o)
                            ? () => controller.setValue(field.id, o.value)
                            : null,
                      )
                    : RadioListTile<Object?>(
                        value: o.value,
                        // ignore: deprecated_member_use
                        groupValue: value,
                        title: label(o),
                        secondary: _optionIcon(o),
                        activeColor: active,
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        // ignore: deprecated_member_use
                        onChanged: canPick(o)
                            ? (v) => controller.setValue(field.id, v)
                            : null,
                      ),
            ]);
          case FieldType.toggleButtons:
            body = SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ToggleButtons(
                isSelected: [
                  for (final o in options) selected.contains(o.value),
                ],
                selectedColor: active,
                fillColor: active?.withValues(alpha: 0.12),
                onPressed: interactive
                    ? (i) {
                        final o = options[i];
                        if (!canPick(o)) return;
                        select(o.value, !selected.contains(o.value));
                      }
                    : null,
                children: [
                  for (final o in options)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_optionIcon(o) != null) ...[
                            _optionIcon(o)!,
                            const SizedBox(width: 6),
                          ],
                          overrides?.optionBuilder?.call(
                                context,
                                o,
                                selected.contains(o.value),
                              ) ??
                              Text(o.label),
                        ],
                      ),
                    ),
                ],
              ),
            );
          case FieldType.segmented:
            body = SegmentedButton<Object?>(
              segments: [
                for (final o in options)
                  ButtonSegment(
                    value: o.value,
                    label:
                        overrides?.optionBuilder?.call(
                          context,
                          o,
                          selected.contains(o.value),
                        ) ??
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(o.label, maxLines: 1, softWrap: false),
                        ),
                    icon: _optionIcon(o),
                    enabled: o.enabled,
                  ),
              ],
              selected: selected.toSet(),
              multiSelectionEnabled: _multi,
              emptySelectionAllowed: true,
              style: active == null
                  ? null
                  : SegmentedButton.styleFrom(
                      selectedBackgroundColor: active.withValues(alpha: 0.18),
                      selectedForegroundColor: active,
                    ),
              onSelectionChanged: interactive
                  ? (set) {
                      if (_multi && max != null && set.length > max) return;
                      controller.setValue(
                        field.id,
                        _multi ? set.toList() : set.firstOrNull,
                      );
                    }
                  : null,
            );
          default: // chips
            body = _arrange([
              for (final o in options)
                FilterChip(
                  label: label(o),
                  avatar: _optionIcon(o),
                  selected: selected.contains(o.value),
                  selectedColor: active?.withValues(alpha: 0.2),
                  checkmarkColor: active,
                  onSelected: canPick(o) ? (v) => select(o.value, v) : null,
                ),
              if (canAddCustom)
                ActionChip(
                  avatar: const Icon(Icons.add, size: 18),
                  label: Text(addLabel),
                  onPressed: () =>
                      promptCustomOption(context, field, controller),
                ),
            ]);
        }

        final showAddButton = canAddCustom && field.type != FieldType.chips;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ?buildFieldLabel(context, field, controller),
            body,
            if (showAddButton)
              TextButton.icon(
                icon: const Icon(Icons.add),
                label: Text(addLabel),
                onPressed: () => promptCustomOption(context, field, controller),
              ),
            if (field.helperText != null && error == null)
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 4),
                child: Text(
                  field.helperText!,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.merge(style.helperStyle),
                ),
              ),
            if (error != null)
              buildFieldError(context, field, controller, error),
          ],
        );
      },
    );
  }
}

/// Renderer for autocomplete / typeahead fields.
class DynamicAutocompleteField extends StatelessWidget {
  /// Creates an autocomplete field.
  const DynamicAutocompleteField({
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
    return _FieldScope(
      state: state,
      builder: (context, value, error, enabled, options, loading) =>
          Autocomplete<OptionItem>(
            displayStringForOption: (o) => o.label,
            initialValue: TextEditingValue(
              text:
                  options.where((o) => o.value == value).firstOrNull?.label ??
                  value?.toString() ??
                  '',
            ),
            optionsBuilder: (text) {
              if (text.text.isEmpty) return const Iterable<OptionItem>.empty();
              final q = text.text.toLowerCase();
              return options.where((o) => o.label.toLowerCase().contains(q));
            },
            onSelected: (o) => controller.setValue(field.id, o.value),
            fieldViewBuilder: (context, textController, focusNode, onSubmit) =>
                TextField(
                  controller: textController,
                  focusNode: focusNode,
                  enabled: enabled,
                  readOnly: field.readOnly,
                  decoration: buildFieldDecoration(
                    context,
                    field,
                    controller,
                    errorText: error,
                    suffix: const Icon(Icons.arrow_drop_down),
                  ),
                  onChanged: (v) {
                    // Free text is kept until an option is chosen.
                    controller.setValue(field.id, v.isEmpty ? null : v);
                  },
                  onSubmitted: (_) => onSubmit(),
                ),
          ),
    );
  }
}
