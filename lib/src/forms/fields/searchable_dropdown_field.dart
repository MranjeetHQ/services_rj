import 'dart:async';

import 'package:flutter/material.dart';

import '../controllers/dynamic_form_controller.dart';
import '../controllers/field_state.dart';
import '../models/field_config.dart';
import '../models/field_enums.dart';
import '../models/field_style.dart';
import '../models/field_type.dart';
import '../models/form_search_sources.dart';
import '../models/option_item.dart';
import '../utils/field_utils.dart';
import 'decoration_helper.dart';

/// Renderer for `searchableDropdown` fields, and for `dropdown` fields with
/// `"searchable": true`, `"multiple": true` or a `"searchSource"`.
///
/// The closed field looks like any other input. Tapping it opens a picker
/// (bottom sheet, dialog or full-screen page, see `"pickerStyle"`) with a
/// search box and the options. Options come from:
///
/// * the field's `options` / `enum` (filtered locally as the user types),
/// * the controller's `optionsLoader` (an API list loaded once, then
///   filtered locally), or
/// * a `"searchSource"` registered with [FormSearchSources] (the API is
///   queried as the user types, debounced).
///
/// With `"multiple": true` the value is a list and the picker shows
/// checkboxes, "Select all" and a Done button.
class DynamicSearchableDropdownField extends StatelessWidget {
  /// Creates a searchable dropdown field.
  const DynamicSearchableDropdownField({
    super.key,
    required this.field,
    required this.controller,
  });

  /// Field configuration.
  final FieldConfig field;

  /// Owning form controller.
  final DynamicFormController controller;

  /// Whether this renderer draws [f]: every `searchableDropdown`, and a
  /// `dropdown` that asks for search, multiple selection or a search source.
  static bool handles(FieldConfig f) =>
      f.type == FieldType.searchableDropdown ||
      (f.ex<bool>('searchable') ?? false) ||
      (f.ex<bool>('multiple') ?? false) ||
      f.ex<String>('searchSource') != null;

  bool get _multi => field.ex<bool>('multiple') ?? false;

  String? get _sourceName => field.ex<String>('searchSource');

  bool get _showSearch =>
      field.ex<bool>('showSearchBox') ??
      (field.type == FieldType.searchableDropdown ||
          (field.ex<bool>('searchable') ?? false) ||
          _sourceName != null);

  List<Object?> _selectedValues(Object? value) => _multi
      ? List<Object?>.from(value as List? ?? const [])
      : (value == null ? const [] : [value]);

  static String _labelFor(List<OptionItem> options, Object? value) =>
      options.where((o) => o.value == value).firstOrNull?.label ??
      value?.toString() ??
      '';

  @override
  Widget build(BuildContext context) {
    final state = controller.state(field.id);
    return ListenableBuilder(
      listenable: Listenable.merge([
        state.value,
        state.error,
        state.enabled,
        state.options,
        state.loadingOptions,
      ]),
      builder: (context, _) => _buildField(context, state),
    );
  }

  Widget _buildField(BuildContext context, FieldRuntimeState state) {
    final l10n = controller.l10n;
    final style = resolveFieldStyle(context, field, controller);
    final options = state.options.value;
    final selected = _selectedValues(state.value.value);
    final loading = state.loadingOptions.value;
    final interactive = state.enabled.value && !field.readOnly && !loading;
    final hasValue = selected.isNotEmpty;
    final showClear = (field.ex<bool>('showClear') ?? true) && interactive;

    void clear() => controller.setValue(field.id, _multi ? <Object?>[] : null);

    final suffix = Padding(
      padding: const EdgeInsetsDirectional.only(end: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (loading)
            const Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else ...[
            if (showClear && hasValue)
              IconButton(
                key: ValueKey('${field.id}-clear'),
                tooltip: l10n.message('clearSelection'),
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.close_rounded, size: 18),
                onPressed: clear,
              ),
            Icon(Icons.keyboard_arrow_down_rounded, color: style.iconColor),
          ],
        ],
      ),
    );

    Widget content;
    if (!hasValue) {
      content = const SizedBox.shrink();
    } else if (!_multi) {
      content = Text(
        _labelFor(options, selected.first),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: style.textStyle,
      );
    } else {
      final display =
          SelectedDisplay.fromString(field.extra['selectedDisplay']) ??
          SelectedDisplay.chips;
      switch (display) {
        case SelectedDisplay.chips:
          content = Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final v in selected)
                InputChip(
                  label: Text(_labelFor(options, v)),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  deleteIcon: const Icon(Icons.close_rounded, size: 16),
                  onDeleted: interactive
                      ? () => controller.setValue(field.id, [
                          for (final s in selected)
                            if (s != v) s,
                        ])
                      : null,
                ),
            ],
          );
        case SelectedDisplay.text:
          content = Text(
            [for (final v in selected) _labelFor(options, v)].join(', '),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: style.textStyle,
          );
        case SelectedDisplay.count:
          content = Text(
            l10n.message('selectedCount', value: selected.length),
            style: style.textStyle,
          );
      }
    }

    final decoration = buildFieldDecoration(
      context,
      field,
      controller,
      errorText: state.error.value,
      suffix: suffix,
    ).copyWith(enabled: state.enabled.value);

    return InkWell(
      focusNode: state.focusNode,
      canRequestFocus: interactive,
      borderRadius: BorderRadius.circular(style.borderRadius ?? 8),
      onTap: interactive ? () => _open(context) : null,
      child: InputDecorator(
        decoration: decoration,
        isEmpty: !hasValue,
        child: content,
      ),
    );
  }

  Future<void> _open(BuildContext context) async {
    final state = controller.state(field.id);
    final style = resolveFieldStyle(context, field, controller);
    final sourceName = _sourceName;
    final source = sourceName == null
        ? null
        : controller.searchSourceFor(sourceName);
    assert(
      sourceName == null || source != null,
      'No search source "$sourceName". Register it with '
      'FormSearchSources.register or DynamicFormController(searchSources:).',
    );
    final pickerStyle =
        PickerStyle.fromString(field.extra['pickerStyle']) ??
        PickerStyle.bottomSheet;

    Widget picker({required bool showTitle}) => _SearchPicker(
      field: field,
      controller: controller,
      style: style,
      multi: _multi,
      showSearch: _showSearch,
      showTitle: showTitle,
      source: source,
      options: state.options.value,
      initial: _selectedValues(state.value.value),
    );

    final List<OptionItem>? result;
    switch (pickerStyle) {
      case PickerStyle.bottomSheet:
        final factor = (field.ex<double>('pickerHeight') ?? 0.75).clamp(
          0.3,
          1.0,
        );
        result = await showModalBottomSheet<List<OptionItem>>(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          showDragHandle: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (context) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: FractionallySizedBox(
              heightFactor: factor,
              child: picker(showTitle: true),
            ),
          ),
        );
      case PickerStyle.dialog:
        result = await showDialog<List<OptionItem>>(
          context: context,
          builder: (context) => Dialog(
            clipBehavior: Clip.antiAlias,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 520,
                maxHeight: MediaQuery.sizeOf(context).height * 0.8,
              ),
              child: Padding(
                padding: const EdgeInsets.only(top: 16),
                child: picker(showTitle: true),
              ),
            ),
          ),
        );
      case PickerStyle.fullScreen:
        result = await Navigator.of(context).push<List<OptionItem>>(
          MaterialPageRoute(
            fullscreenDialog: true,
            builder: (context) => Scaffold(
              appBar: AppBar(
                title: Text(field.label ?? controller.l10n.message('select')),
              ),
              body: SafeArea(child: picker(showTitle: false)),
            ),
          ),
        );
    }
    if (result == null) return;

    // Remember picked options so their labels stay known (remote results
    // and user-added options are not in the static list).
    for (final o in result) {
      final known = state.options.value.any((k) => k.value == o.value);
      if (known) continue;
      if (o.isCustom) {
        controller.addOption(field.id, o);
      } else {
        state.options.value = [...state.options.value, o];
      }
    }
    controller.setValue(
      field.id,
      _multi ? [for (final o in result) o.value] : result.firstOrNull?.value,
    );
  }
}

/// Picker content shared by the bottom sheet, dialog and full-screen page.
/// Pops with the chosen options, or nothing when dismissed.
class _SearchPicker extends StatefulWidget {
  const _SearchPicker({
    required this.field,
    required this.controller,
    required this.style,
    required this.multi,
    required this.showSearch,
    required this.showTitle,
    required this.source,
    required this.options,
    required this.initial,
  });

  final FieldConfig field;
  final DynamicFormController controller;
  final FieldStyleConfig style;
  final bool multi;
  final bool showSearch;
  final bool showTitle;
  final SearchOptionsFn? source;
  final List<OptionItem> options;
  final List<Object?> initial;

  @override
  State<_SearchPicker> createState() => _SearchPickerState();
}

class _SearchPickerState extends State<_SearchPicker> {
  final _query = TextEditingController();
  Timer? _debounce;
  int _requestId = 0;

  late List<OptionItem> _results = widget.options;
  late final List<OptionItem> _selected = [
    for (final v in widget.initial)
      widget.options.where((o) => o.value == v).firstOrNull ??
          OptionItem(label: v?.toString() ?? '', value: v),
  ];
  bool _loading = false;
  Object? _error;

  FieldConfig get _field => widget.field;
  int get _minLength => _field.ex<int>('minSearchLength') ?? 0;
  bool get _remote => widget.source != null;

  @override
  void initState() {
    super.initState();
    if (_remote && _minLength == 0) _search('');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    super.dispose();
  }

  void _onQuery(String q) {
    if (!_remote) {
      setState(() => _results = _filter(q));
      return;
    }
    _debounce?.cancel();
    if (q.trim().length < _minLength) {
      _requestId++;
      setState(() {
        _loading = false;
        _error = null;
        _results = q.trim().isEmpty ? widget.options : const [];
      });
      return;
    }
    _debounce = Timer(
      Duration(milliseconds: _field.ex<int>('debounceMs') ?? 350),
      () => _search(q.trim()),
    );
  }

  List<OptionItem> _filter(String q) {
    final needle = q.trim().toLowerCase();
    if (needle.isEmpty) return widget.options;
    return [
      for (final o in widget.options)
        if (o.label.toLowerCase().contains(needle) ||
            (o.description?.toLowerCase().contains(needle) ?? false) ||
            (o.value?.toString().toLowerCase().contains(needle) ?? false))
          o,
    ];
  }

  Future<void> _search(String q) async {
    final id = ++_requestId;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await widget.source!(q, widget.controller.getFormData());
      if (!mounted || id != _requestId) return;
      setState(() {
        _results = results;
        _loading = false;
      });
    } on Object catch (e) {
      if (!mounted || id != _requestId) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  bool _isSelected(OptionItem o) => _selected.any((s) => s.value == o.value);

  bool _canPick(OptionItem o) {
    if (!o.enabled) return false;
    final max = _field.maxItems;
    return !widget.multi ||
        _isSelected(o) ||
        max == null ||
        _selected.length < max;
  }

  void _tap(OptionItem o) {
    if (!widget.multi) {
      Navigator.pop(context, [o]);
      return;
    }
    setState(() {
      _isSelected(o)
          ? _selected.removeWhere((s) => s.value == o.value)
          : _selected.add(o);
    });
  }

  void _addCustom(String label) {
    final option = OptionItem(label: label, value: label, isCustom: true);
    if (!widget.multi) {
      Navigator.pop(context, [option]);
      return;
    }
    setState(() {
      _results = [option, ..._results];
      if (_canPick(option)) _selected.add(option);
    });
  }

  void _selectAll() {
    final max = _field.maxItems;
    setState(() {
      for (final o in _results) {
        if (max != null && _selected.length >= max) break;
        if (o.enabled && !_isSelected(o)) _selected.add(o);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.controller.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final query = _query.text.trim();
    final canAdd =
        _field.allowCustomOptions &&
        query.isNotEmpty &&
        !_loading &&
        !_results.any((o) => o.label.toLowerCase() == query.toLowerCase());
    final tooShort = _remote && query.length < _minLength;

    Widget body;
    if (_loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_error != null) {
      body = Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded, color: scheme.error, size: 32),
              const SizedBox(height: 8),
              Text(l10n.message('loadFailed'), textAlign: TextAlign.center),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => _search(query),
                child: Text(l10n.message('retry')),
              ),
            ],
          ),
        ),
      );
    } else if (_results.isEmpty && !canAdd) {
      body = Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            tooShort
                ? l10n.message('typeToSearch', value: _minLength)
                : _field.ex<String>('noResultsText') ??
                      l10n.message('noResults'),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    } else {
      body = ListView.builder(
        padding: const EdgeInsets.only(bottom: 8),
        itemCount: _results.length + (canAdd ? 1 : 0),
        itemBuilder: (context, i) {
          if (canAdd && i == 0) {
            return _OptionRow(
              key: ValueKey('${_field.id}-add'),
              label: l10n.message('addValue', value: query),
              icon: const Icon(Icons.add_rounded),
              selected: false,
              multi: false,
              style: widget.style,
              onTap: () => _addCustom(query),
            );
          }
          final o = _results[i - (canAdd ? 1 : 0)];
          final icon = FieldUtils.icon(o.icon);
          return _OptionRow(
            key: ValueKey('${_field.id}-option-${o.value}'),
            label: o.label,
            description: o.description,
            icon: icon == null ? null : Icon(icon, size: 20),
            selected: _isSelected(o),
            multi: widget.multi,
            style: widget.style,
            onTap: _canPick(o) ? () => _tap(o) : null,
          );
        },
      );
    }

    return Material(
      type: MaterialType.transparency,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.showTitle && _field.label != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(_field.label!, style: theme.textTheme.titleMedium),
            ),
          if (widget.showSearch)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: TextField(
                key: ValueKey('${_field.id}-search'),
                controller: _query,
                autofocus: _field.ex<bool>('autofocusSearch') ?? true,
                textInputAction: TextInputAction.search,
                onChanged: (q) {
                  _onQuery(q);
                  setState(() {}); // refresh the clear button
                },
                decoration: InputDecoration(
                  hintText:
                      _field.ex<String>('searchHint') ?? l10n.message('search'),
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _query.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: l10n.message('clearSelection'),
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () {
                            _query.clear();
                            _onQuery('');
                            setState(() {});
                          },
                        ),
                  filled: true,
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(28),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          if (widget.multi &&
              (_field.ex<bool>('showSelectAll') ?? false) &&
              _results.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  TextButton(
                    key: ValueKey('${_field.id}-select-all'),
                    onPressed: _selectAll,
                    child: Text(l10n.message('selectAll')),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _selected.isEmpty
                        ? null
                        : () => setState(_selected.clear),
                    child: Text(l10n.message('clearSelection')),
                  ),
                ],
              ),
            ),
          Expanded(child: body),
          if (widget.multi)
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.message('selectedCount', value: _selected.length),
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    FilledButton(
                      key: ValueKey('${_field.id}-done'),
                      onPressed: () => Navigator.pop(context, [..._selected]),
                      child: Text(l10n.message('done')),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// One row of the picker: rounded, tinted when selected, with a check mark
/// (single) or a checkbox icon (multiple).
class _OptionRow extends StatelessWidget {
  const _OptionRow({
    super.key,
    required this.label,
    this.description,
    this.icon,
    required this.selected,
    required this.multi,
    required this.style,
    required this.onTap,
  });

  final String label;
  final String? description;
  final Widget? icon;
  final bool selected;
  final bool multi;
  final FieldStyleConfig style;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final active = style.activeColor ?? scheme.primary;
    final disabled = onTap == null;
    final labelStyle = selected
        ? (theme.textTheme.bodyLarge
                  ?.copyWith(color: active, fontWeight: FontWeight.w600)
                  .merge(style.selectedTextStyle) ??
              style.selectedTextStyle)
        : theme.textTheme.bodyLarge?.copyWith(
            color: disabled ? theme.disabledColor : null,
          );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: selected
            ? style.selectedColor ?? active.withValues(alpha: 0.12)
            : Colors.transparent,
        clipBehavior: Clip.antiAlias,
        borderRadius: BorderRadius.circular(style.optionRadius ?? 12),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding:
                style.optionPadding ??
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                if (multi) ...[
                  Icon(
                    selected
                        ? Icons.check_box_rounded
                        : Icons.check_box_outline_blank_rounded,
                    color: selected ? active : scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 12),
                ],
                if (icon != null) ...[icon!, const SizedBox(width: 12)],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(label, style: labelStyle),
                      if (description != null)
                        Text(
                          description!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                if (!multi && selected)
                  Icon(Icons.check_rounded, size: 20, color: active),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
