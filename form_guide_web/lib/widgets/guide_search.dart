import 'package:flutter/material.dart';
import 'package:services_rj/services_rj.dart';

import '../catalog/field_catalog.dart';
import '../catalog/reference_catalog.dart';

/// One searchable entry of the guide.
class GuideSearchEntry {
  const GuideSearchEntry(this.title, this.kind, this.summary, this.route);

  /// Key, type or validator name.
  final String title;

  /// "Element", "Property", "Style key"…
  final String kind;
  final String summary;

  /// Guide route the entry opens, such as `/elements/dropdown`.
  final String route;

  bool matches(String q) =>
      title.toLowerCase().contains(q) ||
      kind.toLowerCase().contains(q) ||
      summary.toLowerCase().contains(q);
}

/// Every element, property, style key, validator and operator.
final List<GuideSearchEntry> guideSearchIndex = [
  for (final d in fieldCatalog) ...[
    GuideSearchEntry(
      d.type.name,
      'Element',
      d.summary,
      '/elements/${d.type.name}',
    ),
    for (final a in d.aliases)
      GuideSearchEntry(
        a,
        'Element alias',
        'Same as `${d.type.name}`.',
        '/elements/${d.type.name}',
      ),
  ],
  for (final k in fieldPropertyDocs)
    GuideSearchEntry(k.key, 'Property', k.description, '/properties'),
  for (final k in styleDocs)
    GuideSearchEntry('style.${k.key}', 'Style key', k.description, '/styling'),
  for (final (key, _, what, _) in searchableDropdownKeys)
    GuideSearchEntry(key, 'Dropdown key', what, '/dropdowns'),
  for (final e in validatorDocs.entries)
    GuideSearchEntry(e.key.name, 'Validator', e.value, '/validation'),
  for (final e in operatorDocs.entries)
    GuideSearchEntry(e.key.name, 'Condition operator', e.value, '/conditions'),
];

/// Search box that finds any element or key and opens its page.
class GuideSearch extends StatefulWidget {
  const GuideSearch({super.key, this.maxResults = 8});

  final int maxResults;

  @override
  State<GuideSearch> createState() => _GuideSearchState();
}

class _GuideSearchState extends State<GuideSearch> {
  String _query = '';

  List<GuideSearchEntry> get _results {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    // Exact and prefix matches on the name first.
    int rank(GuideSearchEntry e) {
      final t = e.title.toLowerCase();
      if (t == q) return 0;
      if (t.startsWith(q)) return 1;
      if (t.contains(q)) return 2;
      return 3;
    }

    final hits = guideSearchIndex.where((e) => e.matches(q)).toList()
      ..sort((a, b) => rank(a).compareTo(rank(b)));
    return hits.take(widget.maxResults).toList();
  }

  @override
  Widget build(BuildContext context) {
    final results = _results;
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          key: const ValueKey('guide-search'),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search),
            hintText:
                'Search ${FieldType.values.length} elements, properties, '
                'style keys, validators…',
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(28),
              borderSide: BorderSide.none,
            ),
          ),
          onChanged: (v) => setState(() => _query = v),
        ),
        if (_query.trim().isNotEmpty)
          Card(
            margin: const EdgeInsets.only(top: 8),
            child: results.isEmpty
                ? const ListTile(title: Text('Nothing matches'))
                : Column(
                    children: [
                      for (final r in results)
                        ListTile(
                          dense: true,
                          leading: Icon(_icon(r.kind), color: scheme.primary),
                          title: Text(
                            r.title,
                            style: const TextStyle(fontFamily: 'monospace'),
                          ),
                          subtitle: Text(
                            '${r.kind} · ${r.summary.replaceAll('`', '')}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.of(
                            context,
                          ).pushReplacementNamed(r.route),
                        ),
                    ],
                  ),
          ),
      ],
    );
  }

  static IconData _icon(String kind) => switch (kind) {
    'Element' || 'Element alias' => Icons.widgets_outlined,
    'Style key' => Icons.palette_outlined,
    'Validator' => Icons.rule,
    'Condition operator' => Icons.call_split,
    _ => Icons.tune,
  };
}
