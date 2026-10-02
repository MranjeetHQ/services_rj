import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:services_rj/services_rj.dart';

import '../catalog/reference_catalog.dart';

const _encoder = JsonEncoder.withIndent('  ');

/// Pretty JSON for display.
String prettyJson(Object? value) => _encoder.convert(value);

/// Scrollable page body with a readable max width.
class DocPage extends StatelessWidget {
  const DocPage({
    super.key,
    required this.title,
    this.intro,
    required this.children,
  });

  final String title;
  final String? intro;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return SelectionArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 64),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 920),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(title, style: text.headlineMedium),
                  if (intro != null) ...[
                    const SizedBox(height: 8),
                    Text(intro!, style: text.bodyLarge),
                  ],
                  const SizedBox(height: 16),
                  ...children,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Section heading.
class H2 extends StatelessWidget {
  const H2(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 28, bottom: 8),
    child: Text(text, style: Theme.of(context).textTheme.titleLarge),
  );
}

/// Paragraph that renders `code` spans in monospace.
class P extends StatelessWidget {
  const P(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final parts = text.split('`');
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text.rich(
        TextSpan(
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
          children: [
            for (var i = 0; i < parts.length; i++)
              i.isOdd
                  ? TextSpan(
                      text: parts[i],
                      style: TextStyle(
                        fontFamily: 'monospace',
                        backgroundColor: scheme.surfaceContainerHighest,
                      ),
                    )
                  : TextSpan(text: parts[i]),
          ],
        ),
      ),
    );
  }
}

/// Monospace code with a copy button.
class CodeBlock extends StatelessWidget {
  const CodeBlock(this.code, {super.key, this.label});
  final String code;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Stack(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(14, 14, 48, 14),
            child: Text(
              code.trim(),
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                height: 1.45,
              ),
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: IconButton(
              tooltip: 'Copy',
              icon: const Icon(Icons.copy, size: 18),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: code.trim()));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Copied'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Simple wrapping table of rows.
class KeyTable extends StatelessWidget {
  const KeyTable({super.key, required this.headers, required this.rows});

  final List<String> headers;
  final List<List<String>> rows;

  /// Table of [KeyDoc]s.
  factory KeyTable.docs(List<KeyDoc> docs) => KeyTable(
    headers: const ['Key', 'Type', 'Description'],
    rows: [
      for (final d in docs)
        [
          d.key,
          d.type,
          d.aliasOf == null
              ? d.description
              : 'Alias of `${d.aliasOf}`. ${d.description}',
        ],
    ],
  );

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final mono = const TextStyle(fontFamily: 'monospace', fontSize: 13);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(10),
      ),
      clipBehavior: Clip.antiAlias,
      child: Table(
        columnWidths: headers.length == 3
            ? const {
                0: IntrinsicColumnWidth(flex: 1),
                1: IntrinsicColumnWidth(flex: 1),
                2: FlexColumnWidth(3),
              }
            : const {0: IntrinsicColumnWidth(), 1: FlexColumnWidth()},
        defaultVerticalAlignment: TableCellVerticalAlignment.top,
        children: [
          TableRow(
            decoration: BoxDecoration(color: scheme.surfaceContainerHigh),
            children: [
              for (final h in headers)
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Text(h, style: Theme.of(context).textTheme.labelLarge),
                ),
            ],
          ),
          for (final r in rows)
            TableRow(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: scheme.outlineVariant)),
              ),
              children: [
                for (var i = 0; i < r.length; i++)
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: i == 0 ? Text(r[i], style: mono) : P(r[i]),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

/// Renders a JSON form live, with tabs for the source JSON and the current
/// form data (updated as you type).
class LivePreview extends StatefulWidget {
  const LivePreview({
    super.key,
    required this.json,
    this.initialData,
    this.fieldOverrides = const {},
    this.dartCode,
    this.height,
  });

  /// A whole form (`fields` / `steps`) or a single field map.
  final Map<String, dynamic> json;
  final Map<String, dynamic>? initialData;
  final Map<String, FieldOverrides> fieldOverrides;

  /// Optional Dart snippet shown as an extra tab.
  final String? dartCode;
  final double? height;

  @override
  State<LivePreview> createState() => _LivePreviewState();
}

class _LivePreviewState extends State<LivePreview> {
  final _controller = DynamicFormController();
  int _tab = 0;
  Map<String, dynamic> _data = const {};
  Map<String, String> _errors = const {};

  // Built once: a new map each build would make DynamicForm re-attach.
  late Map<String, dynamic> _form = _wrap(widget.json);

  static Map<String, dynamic> _wrap(Map<String, dynamic> json) =>
      json.containsKey('fields') || json.containsKey('steps')
      ? json
      : {
          'fields': [json],
        };

  @override
  void initState() {
    super.initState();
    _controller.addListener(_sync);
  }

  @override
  void didUpdateWidget(LivePreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.json, widget.json)) _form = _wrap(widget.json);
  }

  void _sync() {
    if (!mounted) return;
    // attach() notifies while DynamicForm is first building.
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _sync());
      return;
    }
    setState(() {
      _data = _controller.getFormData();
      _errors = _controller.getErrors();
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_sync);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isSingle =
        !(widget.json.containsKey('fields') ||
            widget.json.containsKey('steps'));
    final tabs = ['Preview', 'JSON', if (widget.dartCode != null) 'Dart'];
    final preview = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: DynamicForm(
            controller: _controller,
            json: _form,
            initialData: widget.initialData,
            fieldOverrides: widget.fieldOverrides,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            onSubmit: (_) => _sync(),
          ),
        ),
        if (_form['steps'] == null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              children: [
                FilledButton.tonal(
                  onPressed: () {
                    _controller.validate();
                    _sync();
                  },
                  child: const Text('Validate'),
                ),
                TextButton(
                  onPressed: _controller.reset,
                  child: const Text('Reset'),
                ),
              ],
            ),
          ),
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'getFormData() → ${prettyJson(_data)}'
            '${_errors.isEmpty ? '' : '\n\ngetErrors() → ${prettyJson(_errors)}'}',
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        ),
      ],
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            child: SegmentedButton<int>(
              showSelectedIcon: false,
              segments: [
                for (var i = 0; i < tabs.length; i++)
                  ButtonSegment(value: i, label: Text(tabs[i])),
              ],
              selected: {_tab},
              onSelectionChanged: (s) => setState(() => _tab = s.first),
            ),
          ),
          // Keep the form alive across tabs so typed values survive.
          Offstage(offstage: _tab != 0, child: preview),
          if (_tab == 1)
            Padding(
              padding: const EdgeInsets.all(12),
              child: CodeBlock(prettyJson(isSingle ? widget.json : _form)),
            ),
          if (_tab == 2 && widget.dartCode != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: CodeBlock(widget.dartCode!),
            ),
        ],
      ),
    );
  }
}

/// Small coloured note.
class Callout extends StatelessWidget {
  const Callout(this.text, {super.key, this.icon = Icons.lightbulb_outline});
  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: scheme.onSecondaryContainer),
          const SizedBox(width: 10),
          Expanded(child: P(text)),
        ],
      ),
    );
  }
}
