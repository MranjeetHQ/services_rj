import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:services_rj/services_rj.dart';

import '../catalog/field_catalog.dart';
import '../widgets/doc_widgets.dart';

/// Widgetbook-style browser: pick an element on the left, edit its JSON and
/// see it render, with its keys and value type next to it.
///
/// Deep link: `/#/elements/<type>` (for example `/#/elements/dropdown`).
class ElementsPage extends StatefulWidget {
  const ElementsPage({super.key});

  @override
  State<ElementsPage> createState() => _ElementsPageState();
}

class _ElementsPageState extends State<ElementsPage> {
  late FieldDoc _doc = fieldCatalog.first;
  String _query = '';
  bool _routeRead = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_routeRead) return;
    _routeRead = true;
    final name = ModalRoute.of(context)?.settings.name ?? '';
    final parts = name.split('/').where((p) => p.isNotEmpty).toList();
    if (parts.length > 1) {
      final match = fieldCatalog.where((d) => d.type.name == parts[1]);
      if (match.isNotEmpty) _doc = match.first;
    }
  }

  void _select(FieldDoc doc) {
    setState(() => _doc = doc);
    // Keeps the browser URL shareable without a page transition.
    SystemNavigator.routeInformationUpdated(
      uri: Uri.parse('/elements/${doc.type.name}'),
    );
  }

  List<FieldDoc> get _filtered {
    final q = _query.toLowerCase();
    return [
      for (final d in fieldCatalog)
        if (q.isEmpty ||
            d.type.name.toLowerCase().contains(q) ||
            d.aliases.any((a) => a.toLowerCase().contains(q)))
          d,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final detail = _ElementDetail(key: ValueKey(_doc.type), doc: _doc);
    return LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth < 760) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: DropdownButtonFormField<FieldDoc>(
                  initialValue: _doc,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Element'),
                  items: [
                    for (final d in fieldCatalog)
                      DropdownMenuItem(value: d, child: Text(d.type.name)),
                  ],
                  onChanged: (d) => d == null ? null : _select(d),
                ),
              ),
              Expanded(child: detail),
            ],
          );
        }
        final scheme = Theme.of(context).colorScheme;
        final list = _filtered;
        return Row(
          children: [
            SizedBox(
              width: 250,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: TextField(
                      decoration: const InputDecoration(
                        isDense: true,
                        prefixIcon: Icon(Icons.search),
                        hintText: 'Search elements',
                      ),
                      onChanged: (v) => setState(() => _query = v),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      children: [
                        for (final cat in FieldCategory.values)
                          if (list.any((d) => d.category == cat)) ...[
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                              child: Text(
                                cat.title.toUpperCase(),
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(color: scheme.primary),
                              ),
                            ),
                            for (final d in list.where(
                              (d) => d.category == cat,
                            ))
                              ListTile(
                                dense: true,
                                selected: d == _doc,
                                title: Text(
                                  d.type.name,
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                  ),
                                ),
                                onTap: () => _select(d),
                              ),
                          ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const VerticalDivider(width: 1),
            Expanded(child: detail),
          ],
        );
      },
    );
  }
}

class _ElementDetail extends StatefulWidget {
  const _ElementDetail({super.key, required this.doc});
  final FieldDoc doc;

  @override
  State<_ElementDetail> createState() => _ElementDetailState();
}

class _ElementDetailState extends State<_ElementDetail> {
  late Map<String, dynamic> _json = _copy(widget.doc.example);
  late final TextEditingController _source = TextEditingController(
    text: prettyJson(_json),
  );
  String? _error;
  int _revision = 0;

  static Map<String, dynamic> _copy(Map<String, dynamic> m) =>
      jsonDecode(jsonEncode(m)) as Map<String, dynamic>;

  void _setJson(Map<String, dynamic> json) {
    setState(() {
      _json = json;
      _source.text = prettyJson(json);
      _error = null;
      _revision++;
    });
  }

  void _apply() {
    try {
      final decoded = jsonDecode(_source.text);
      if (decoded is! Map) throw const FormatException('Expected an object');
      final map = Map<String, dynamic>.from(decoded);
      FieldConfig.fromJson(map);
      setState(() {
        _json = map;
        _error = null;
        _revision++;
      });
    } on Object catch (e) {
      setState(() => _error = '$e');
    }
  }

  void _toggle(String key, bool on) {
    final next = _copy(_json);
    if (on) {
      next[key] = true;
    } else {
      next.remove(key);
    }
    _setJson(next);
  }

  void _setVariant(String? variant) {
    final next = _copy(_json);
    final style = Map<String, dynamic>.from((next['style'] as Map?) ?? {});
    if (variant == null) {
      style.remove('variant');
    } else {
      style['variant'] = variant;
    }
    if (style.isEmpty) {
      next.remove('style');
    } else {
      next['style'] = style;
    }
    _setJson(next);
  }

  @override
  void dispose() {
    _source.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final doc = widget.doc;
    final text = Theme.of(context).textTheme;
    final variant = (_json['style'] as Map?)?['variant'] as String?;
    final editor = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _source,
          maxLines: 14,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
          decoration: InputDecoration(errorText: _error, errorMaxLines: 4),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: Wrap(
            spacing: 8,
            children: [
              FilledButton.icon(
                icon: const Icon(Icons.play_arrow),
                label: const Text('Render'),
                onPressed: _apply,
              ),
              TextButton(
                onPressed: () => _setJson(_copy(doc.example)),
                child: const Text('Reset'),
              ),
            ],
          ),
        ),
      ],
    );
    final preview = LivePreview(key: ValueKey(_revision), json: _json);
    return DocPage(
      title: '"${doc.type.name}"',
      intro: doc.summary,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Chip(
              label: Text(doc.category.title),
              visualDensity: VisualDensity.compact,
            ),
            if (doc.pluggable)
              const Chip(
                avatar: Icon(Icons.extension, size: 16),
                label: Text('needs an adapter'),
                visualDensity: VisualDensity.compact,
              ),
            for (final a in doc.aliases)
              Chip(label: Text(a), visualDensity: VisualDensity.compact),
          ],
        ),
        const SizedBox(height: 8),
        P('Value in `getFormData()`: `${doc.valueType}`'),
        const H2('Try it'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            FilterChip(
              label: const Text('required'),
              selected: _json['required'] == true,
              onSelected: (v) => _toggle('required', v),
            ),
            FilterChip(
              label: const Text('readOnly'),
              selected: _json['readOnly'] == true,
              onSelected: (v) => _toggle('readOnly', v),
            ),
            for (final v in FieldStyleVariant.values.map((v) => v.name))
              ChoiceChip(
                label: Text(v),
                selected: variant == v,
                onSelected: (on) => _setVariant(on ? v : null),
              ),
          ],
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, c) => c.maxWidth > 760
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: editor),
                    const SizedBox(width: 16),
                    Expanded(child: preview),
                  ],
                )
              : Column(children: [editor, const SizedBox(height: 16), preview]),
        ),
        if (doc.keys.isNotEmpty) ...[
          const H2('Extra keys for this element'),
          KeyTable(
            headers: const ['Key', 'Meaning'],
            rows: [
              for (final e in doc.keys.entries) [e.key, e.value],
            ],
          ),
        ],
        const H2('Use it in code'),
        CodeBlock('''
DynamicForm(
  controller: controller,
  json: {
    'fields': [
${const JsonEncoder.withIndent('  ').convert(doc.example).split('\n').map((l) => '      $l').join('\n')},
    ],
  },
  onSubmit: (data) => print(data['${doc.example['id']}']),
);'''),
        Text(
          'Common keys (label, hint, validators, visibleWhen, style…) are on '
          'the Properties page.',
          style: text.bodySmall,
        ),
      ],
    );
  }
}
