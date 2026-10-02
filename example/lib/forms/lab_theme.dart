import 'package:flutter/material.dart';
import 'package:services_rj/services_rj.dart';

import '../widgets/demo_widgets.dart';

/// Form used by the theme section: it has a section header, a standalone
/// label, an async dropdown (loadingBuilder) and field types whose errors go
/// through `errorBuilder` (slider, checkbox group, repeater).
const Map<String, dynamic> themeLabForm = {
  'id': 'theme_lab',
  'fields': [
    {'type': 'sectionHeader', 'id': 'h', 'label': 'Trip request'},
    {
      'type': 'label',
      'id': 'intro',
      'label': 'Standalone label: styled by labelStyle',
    },
    {
      'type': 'text',
      'id': 'traveller',
      'label': 'Traveller',
      'prefixIcon': 'person',
      'required': true,
    },
    {
      'type': 'email',
      'id': 'contact',
      'label': 'Contact email (typeOverrides target)',
    },
    {
      'type': 'dropdown',
      'id': 'team',
      'label': 'Team (options load asynchronously)',
    },
    {
      'type': 'slider',
      'id': 'comfort',
      'label': 'Comfort level (required)',
      'required': true,
      'min': 1,
      'max': 5,
      'divisions': 4,
    },
    {
      'type': 'checkboxGroup',
      'id': 'extras',
      'label': 'Extras (required)',
      'required': true,
      'options': ['Window seat', 'Extra luggage', 'Meal'],
    },
    {
      'type': 'repeater',
      'id': 'stops',
      'label': 'Stops',
      'itemLabel': 'Stop {index}',
      'minItems': 1,
      'fields': [
        {'type': 'text', 'id': 'city', 'label': 'City', 'required': true},
      ],
    },
  ],
};

/// Teams returned by [labTeamLoader].
const List<String> labTeams = ['Platform', 'Growth', 'Payments'];

/// Slow fake loader so the `loadingBuilder` is visible. No network.
Future<List<OptionItem>> labTeamLoader(
  String fieldId,
  Map<String, dynamic> data,
) async {
  await Future<void>.delayed(const Duration(milliseconds: 900));
  return [for (final t in labTeams) OptionItem(label: t, value: t)];
}

/// Builds one field per [FieldStyleVariant] plus fields that between them use
/// every `style` key, and a form-level `style`.
Map<String, dynamic> buildStyleLabForm() => {
  'id': 'style_lab_all',
  // Form-level style: applies to every field, fields can override it.
  'style': {'borderRadius': 10, 'iconColor': '#00796B'},
  'fields': [
    {'type': 'sectionHeader', 'id': 'sv', 'label': 'FieldStyleVariant'},
    for (final v in FieldStyleVariant.values)
      {
        'type': 'text',
        'id': 'variant_${v.name}',
        'label': 'variant: ${v.name}',
        'prefixIcon': 'edit',
        'style': {
          'variant': v.name,
          if (v == FieldStyleVariant.filled) 'fillColor': '#E8EAF6',
        },
      },
    {'type': 'sectionHeader', 'id': 'sk', 'label': 'Every style key'},
    {
      'type': 'text',
      'id': 'all_keys',
      'label': 'Rounded, tinted, centred',
      'hint': 'Hint style',
      'helperText': 'Helper style',
      'prefixIcon': 'star',
      'required': true,
      'style': {
        'variant': 'rounded',
        'borderRadius': 22,
        'fillColor': '#F3EFFF',
        'borderColor': '#7E57C2',
        'focusedBorderColor': '#4527A0',
        'borderWidth': 2,
        'dense': true,
        'contentPadding': {'horizontal': 18, 'vertical': 10},
        'labelBehavior': 'always',
        'textStyle': {'fontSize': 16, 'fontWeight': 'w600', 'color': '#311B92'},
        'labelStyle': {'color': '#5E35B1', 'fontWeight': 'bold'},
        'hintStyle': {'color': '#9575CD', 'italic': true},
        'helperStyle': {'color': '#7E57C2'},
        'errorStyle': {'color': '#D50000', 'fontWeight': 'bold'},
        'iconColor': '#7E57C2',
        'cursorColor': '#D81B60',
        'textAlign': 'center',
      },
    },
    {
      'type': 'text',
      'id': 'aliases',
      'label': 'Style aliases: "type" and "radius"',
      'style': {'type': 'underline', 'radius': 4},
    },
    {
      'type': 'radioGroup',
      'id': 'active',
      'label': 'activeColor on a radio group',
      'options': ['Red', 'Green', 'Blue'],
      'initialValue': 'Green',
      'style': {'activeColor': '#2E7D32'},
    },
    {
      'type': 'group',
      'id': 'box',
      'label': 'containerColor and containerRadius',
      'style': {'containerColor': '#E0F2F1', 'containerRadius': 20},
      'fields': [
        {'type': 'text', 'id': 'box_a', 'label': 'Inside the container'},
      ],
    },
    {
      'type': 'text',
      'id': 'label_above',
      'label': 'Label above the field (labelPosition)',
      'hint': 'Never clipped, long labels stay readable',
      'style': {'labelPosition': 'above'},
    },
    {
      'type': 'text',
      'id': 'decoration_alias',
      'label': '"decoration" map merges into style',
      'decoration': {'variant': 'filled', 'fillColor': '#FFF8E1'},
    },
  ],
};

/// Builds the form that shows every value of the field enums
/// ([KeyboardKind], [InputActionKind], [OptionLayout], [TextCase],
/// [LabelBehavior], [LabelPosition], [MediaSource]).
Map<String, dynamic> buildEnumsLabForm() => {
  'id': 'enums_lab',
  'fields': [
    {
      'type': 'expansion',
      'id': 'kb',
      'label': 'KeyboardKind (${KeyboardKind.values.length})',
      'expanded': true,
      'fields': [
        for (final k in KeyboardKind.values)
          {
            'type': 'text',
            'id': 'kb_${k.name}',
            'label': 'keyboardType: ${k.name}',
            'keyboardType': k.name,
            if (k == KeyboardKind.multiline) 'maxLines': 2,
          },
      ],
    },
    {
      'type': 'expansion',
      'id': 'ia',
      'label': 'InputActionKind (${InputActionKind.values.length})',
      'fields': [
        for (final a in InputActionKind.values)
          {
            'type': 'text',
            'id': 'ia_${a.name}',
            'label': 'textInputAction: ${a.name}',
            'textInputAction': a.name,
          },
      ],
    },
    {
      'type': 'expansion',
      'id': 'ol',
      'label': 'OptionLayout (${OptionLayout.values.length})',
      'fields': [
        for (final l in OptionLayout.values)
          {
            'type': 'radioGroup',
            'id': 'ol_${l.name}',
            'label': 'optionLayout: ${l.name}',
            'optionLayout': l.name,
            if (l == OptionLayout.grid) 'columns': 2,
            'options': ['North', 'South', 'East', 'West'],
          },
      ],
    },
    {
      'type': 'expansion',
      'id': 'tc',
      'label': 'TextCase (${TextCase.values.length})',
      'fields': [
        for (final t in TextCase.values)
          {
            'type': 'text',
            'id': 'tc_${t.name}',
            'label': 'textCase: ${t.name}',
            'hint': 'Type "hello wORLD. nice day"',
            'textCase': t.name,
          },
      ],
    },
    {
      'type': 'expansion',
      'id': 'lb',
      'label': 'LabelBehavior (${LabelBehavior.values.length})',
      'fields': [
        for (final b in LabelBehavior.values)
          {
            'type': 'text',
            'id': 'lb_${b.name}',
            'label': 'labelBehavior: ${b.name}',
            'hint': 'Placeholder text',
            'style': {'labelBehavior': b.name},
          },
      ],
    },
    {
      'type': 'expansion',
      'id': 'lp',
      'label': 'LabelPosition (${LabelPosition.values.length})',
      'fields': [
        for (final p in LabelPosition.values)
          {
            'type': 'text',
            'id': 'lp_${p.name}',
            'label': 'Guest name (${p.name})',
            'hint': 'As on the ticket',
            'style': {'labelPosition': p.name},
          },
      ],
    },
    {
      'type': 'expansion',
      'id': 'ms',
      'label': 'MediaSource (${MediaSource.values.length})',
      'fields': [
        for (final m in MediaSource.values)
          {
            'type': 'image',
            'id': 'ms_${m.name}',
            'label': 'source: ${m.name}',
            'source': m.name,
          },
      ],
    },
  ],
};

/// Form for the `FieldOverrides` section.
const Map<String, dynamic> overridesLabForm = {
  'id': 'overrides_lab',
  'fields': [
    {'type': 'text', 'id': 'person', 'label': 'Name (style override)'},
    {
      'type': 'textarea',
      'id': 'remark',
      'label': 'JSON label (replaced)',
      'maxLines': 2,
    },
    {
      'type': 'segmented',
      'id': 'urgency',
      'label': 'Urgency (optionBuilder)',
      'options': ['low', 'normal', 'urgent'],
    },
    {'type': 'email', 'id': 'reply', 'label': 'Reply address (decoration)'},
    {'type': 'stepper', 'id': 'headcount', 'label': 'Headcount (builder)'},
    {'type': 'phone', 'id': 'mobile', 'label': 'Mobile (typeOverrides)'},
  ],
};

/// Every override kind, keyed by field id.
Map<String, FieldOverrides> buildLabFieldOverrides() => {
  'person': const FieldOverrides(
    style: FieldStyleConfig(
      variant: FieldStyleVariant.filled,
      fillColor: Color(0xFFFFF3E0),
      activeColor: Colors.deepOrange,
    ),
  ),
  'remark': FieldOverrides(
    label: 'Anything else? (label override)',
    hint: 'Hint from FieldOverrides.hint',
    helperText: 'Helper from FieldOverrides.helperText',
    wrapper: (context, field, child) => Card(
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: Padding(padding: const EdgeInsets.all(12), child: child),
    ),
  ),
  'urgency': FieldOverrides(
    optionBuilder: (context, option, selected) => Text(
      selected ? '[${option.label.toUpperCase()}]' : option.label,
      style: TextStyle(fontWeight: selected ? FontWeight.bold : null),
    ),
  ),
  'reply': FieldOverrides(
    decoration: (context, field, d) =>
        d.copyWith(prefixIcon: const Icon(Icons.reply), suffixText: '@work'),
  ),
  'headcount': FieldOverrides(
    builder: (context, field, controller) => ValueListenableBuilder<Object?>(
      valueListenable: controller.state(field.id).value,
      builder: (context, value, _) {
        final n = (value as num?)?.toInt() ?? 1;
        return Row(
          children: [
            Expanded(child: Text('${field.label}: $n')),
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: n > 1
                  ? () => controller.setValue(field.id, n - 1)
                  : null,
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () => controller.setValue(field.id, n + 1),
            ),
          ],
        );
      },
    ),
  ),
};

/// Overrides applied to every field of a type.
Map<FieldType, FieldOverrides> buildLabTypeOverrides() => {
  FieldType.phone: FieldOverrides(
    decoration: (context, field, d) =>
        d.copyWith(prefixText: '+91 ', helperText: 'typeOverrides: phone'),
  ),
};

/// Form pushed by the discard demo.
const Map<String, dynamic> discardLabForm = {
  'id': 'discard_lab',
  'confirmDiscard': true,
  'discardTitle': 'Leave without saving?',
  'discardMessage': 'Your draft note will be lost if you go back now.',
  'fields': [
    {'type': 'textarea', 'id': 'draft', 'label': 'Draft note', 'maxLines': 4},
  ],
};

/// Page for the theme and customization lab.
class ThemeLabPage extends StatefulWidget {
  /// Creates the page.
  const ThemeLabPage({super.key});

  @override
  State<ThemeLabPage> createState() => _ThemeLabPageState();
}

class _ThemeLabPageState extends State<ThemeLabPage> {
  final _themed = DynamicFormController(optionsLoader: labTeamLoader);
  final _styles = DynamicFormController();
  final _enums = DynamicFormController();
  final _overrides = DynamicFormController();
  late final Map<String, dynamic> _styleJson = buildStyleLabForm();
  late final Map<String, dynamic> _enumJson = buildEnumsLabForm();
  late final Map<String, FieldOverrides> _fieldOverrides =
      buildLabFieldOverrides();
  late final Map<FieldType, FieldOverrides> _typeOverrides =
      buildLabTypeOverrides();

  double _spacing = 16;
  bool _cupertino = false;
  bool _dense = false;
  bool _errorBuilder = false;
  bool _decoration = false;
  bool _textStyles = false;
  bool _defaultStyle = false;
  bool _typeOverridesOn = true;
  bool _customDiscard = false;

  @override
  void dispose() {
    for (final c in [_themed, _styles, _enums, _overrides]) {
      c.dispose();
    }
    super.dispose();
  }

  DynamicFormThemeData get _theme => DynamicFormThemeData(
    fieldSpacing: _spacing,
    useCupertino: _cupertino,
    dense: _dense,
    errorBuilder: _errorBuilder
        ? (context, message) => Container(
            margin: const EdgeInsets.only(top: 6),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 16),
                const SizedBox(width: 6),
                Flexible(child: Text(message)),
              ],
            ),
          )
        : null,
    loadingBuilder: (context) => const Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 12),
          Text('Fetching teams from the fake server...'),
        ],
      ),
    ),
    decorationBuilder: _decoration
        ? (context, field, d) => d.copyWith(
            labelText: d.labelText == null ? null : '* ${d.labelText}',
            floatingLabelStyle: const TextStyle(color: Colors.deepPurple),
          )
        : null,
    labelStyle: _textStyles
        ? const TextStyle(
            fontStyle: FontStyle.italic,
            color: Colors.teal,
            fontSize: 15,
          )
        : null,
    sectionHeaderStyle: _textStyles
        ? const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Colors.deepOrange,
          )
        : null,
    defaultFieldStyle: _defaultStyle
        ? const FieldStyleConfig(
            variant: FieldStyleVariant.filled,
            borderRadius: 16,
            fillColor: Color(0xFFE8F5E9),
          )
        : null,
  );

  Future<void> _openDiscardDemo() => Navigator.push(
    context,
    MaterialPageRoute<void>(
      builder: (_) => _DiscardDemoPage(customDialog: _customDiscard),
    ),
  );

  @override
  Widget build(BuildContext context) => DemoPage(
    title: 'Theme and customization lab',
    intro:
        'DynamicFormTheme, per-field and per-type overrides, every style key '
        'and every field enum.',
    children: [
      DemoSection(
        title: 'DynamicFormThemeData',
        subtitle:
            'Toggle options; the form below rebuilds with the new theme. '
            'errorBuilder shows on slider, checkbox group and repeater errors. '
            'useCupertino is exposed by the theme but no built-in field reads '
            'it yet.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _toggle('useCupertino', _cupertino, (v) => _cupertino = v),
                _toggle('dense', _dense, (v) => _dense = v),
                _toggle(
                  'errorBuilder',
                  _errorBuilder,
                  (v) => _errorBuilder = v,
                ),
                _toggle(
                  'decorationBuilder',
                  _decoration,
                  (v) => _decoration = v,
                ),
                _toggle('label + header styles', _textStyles, (v) {
                  _textStyles = v;
                }),
                _toggle(
                  'defaultFieldStyle',
                  _defaultStyle,
                  (v) => _defaultStyle = v,
                ),
                _toggle(
                  'typeOverrides (email)',
                  _typeOverridesOn,
                  (v) => _typeOverridesOn = v,
                ),
              ],
            ),
            Row(
              children: [
                Text('fieldSpacing ${_spacing.round()}'),
                Expanded(
                  child: Slider(
                    value: _spacing,
                    min: 0,
                    max: 40,
                    divisions: 20,
                    onChanged: (v) => setState(() => _spacing = v),
                  ),
                ),
              ],
            ),
            DynamicFormTheme(
              data: _theme,
              child: DynamicForm(
                controller: _themed,
                json: themeLabForm,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                showSubmitButton: true,
                submitLabel: 'Validate to see errorBuilder',
                typeOverrides: _typeOverridesOn
                    ? {
                        FieldType.email: FieldOverrides(
                          decoration: (context, field, d) => d.copyWith(
                            suffixIcon: const Icon(Icons.alternate_email),
                          ),
                          style: const FieldStyleConfig(
                            variant: FieldStyleVariant.underline,
                          ),
                        ),
                      }
                    : const {},
              ),
            ),
            TextButton.icon(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                _themed.addField(
                  const FieldConfig(
                    id: 'team',
                    type: FieldType.dropdown,
                    label: 'Team (options load asynchronously)',
                  ),
                  index: 4,
                );
              },
              label: const Text('Reload teams (shows loadingBuilder)'),
            ),
          ],
        ),
      ),
      DemoSection(
        title: 'Unsaved changes dialog',
        subtitle:
            'confirmDiscard, discardTitle and discardMessage live in the form '
            'JSON. Turn on discardDialogBuilder to replace the dialog.',
        child: Wrap(
          spacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _toggle(
              'custom discardDialogBuilder',
              _customDiscard,
              (v) => _customDiscard = v,
            ),
            FilledButton(
              onPressed: _openDiscardDemo,
              child: const Text('Open form, then go back'),
            ),
          ],
        ),
      ),
      DemoSection(
        title: 'FieldOverrides and typeOverrides',
        subtitle:
            'style, label, hint, helperText, wrapper, optionBuilder, '
            'decoration, builder, and a type-wide override on phone.',
        child: DynamicForm(
          controller: _overrides,
          json: overridesLabForm,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          fieldOverrides: _fieldOverrides,
          typeOverrides: _typeOverrides,
        ),
      ),
      DemoSection(
        title: 'FieldStyleConfig keys and variants',
        subtitle: 'Form-level style plus a field-level style per key.',
        child: DynamicForm(
          controller: _styles,
          json: _styleJson,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          showSubmitButton: true,
          submitLabel: 'Validate (shows errorStyle)',
        ),
      ),
      DemoSection(
        title: 'Field enums',
        subtitle:
            'KeyboardKind, InputActionKind, OptionLayout, TextCase, '
            'LabelBehavior and MediaSource: every value once.',
        child: DynamicForm(
          controller: _enums,
          json: _enumJson,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
        ),
      ),
    ],
  );

  Widget _toggle(String label, bool value, void Function(bool) set) =>
      FilterChip(
        label: Text(label),
        selected: value,
        onSelected: (v) => setState(() => set(v)),
      );
}

class _DiscardDemoPage extends StatefulWidget {
  const _DiscardDemoPage({required this.customDialog});

  final bool customDialog;

  @override
  State<_DiscardDemoPage> createState() => _DiscardDemoPageState();
}

class _DiscardDemoPageState extends State<_DiscardDemoPage> {
  final _c = DynamicFormController();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => DynamicFormTheme(
    data: DynamicFormThemeData(
      discardDialogBuilder: widget.customDialog
          ? (context) => showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                icon: const Icon(Icons.delete_outline),
                title: const Text('Custom discard dialog'),
                content: const Text('Built by discardDialogBuilder.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Keep editing'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Throw it away'),
                  ),
                ],
              ),
            )
          : null,
    ),
    child: Scaffold(
      appBar: AppBar(title: const Text('Type something, then go back')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: DynamicForm(controller: _c, json: discardLabForm),
      ),
    ),
  );
}
