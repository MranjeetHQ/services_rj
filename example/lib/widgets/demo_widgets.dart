import 'package:flutter/material.dart';

/// One tile on the home screen.
class DemoEntry {
  /// Creates an entry.
  const DemoEntry({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.builder,
  });

  /// Leading icon.
  final IconData icon;

  /// Tile title.
  final String title;

  /// One line saying what the demo shows.
  final String subtitle;

  /// Builds the demo page.
  final WidgetBuilder builder;
}

/// Scrollable, width-constrained page used by every non-form demo.
class DemoPage extends StatelessWidget {
  /// Creates a page.
  const DemoPage({
    super.key,
    required this.title,
    required this.children,
    this.intro,
    this.actions,
  });

  /// App bar title.
  final String title;

  /// Short description shown above the content.
  final String? intro;

  /// Page content.
  final List<Widget> children;

  /// App bar actions.
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title), actions: actions),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (intro != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  intro!,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ...children,
            const SizedBox(height: 32),
          ],
        ),
      ),
    ),
  );
}

/// A titled card that groups one feature.
class DemoSection extends StatelessWidget {
  /// Creates a section.
  const DemoSection({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.code,
  });

  /// Section heading.
  final String title;

  /// What this section demonstrates.
  final String? subtitle;

  /// Optional code shown under the content.
  final String? code;

  /// Live demo content.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: text.titleMedium),
            if (subtitle != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(subtitle!, style: text.bodySmall),
              ),
            const SizedBox(height: 12),
            child,
            if (code != null) ...[
              const SizedBox(height: 12),
              CodeSnippet(code!),
            ],
          ],
        ),
      ),
    );
  }
}

/// Monospace, selectable code block.
class CodeSnippet extends StatelessWidget {
  /// Creates a snippet.
  const CodeSnippet(this.code, {super.key});

  /// Source text.
  final String code;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(8),
    ),
    child: SelectableText(
      code,
      style: const TextStyle(fontFamily: 'monospace', fontSize: 12.5),
    ),
  );
}

/// Append-only list of messages, so a demo can show what just happened.
class EventLog extends ChangeNotifier {
  final List<String> _lines = [];

  /// Newest first.
  List<String> get lines => List.unmodifiable(_lines);

  /// Adds a line.
  void add(String line) {
    _lines.insert(0, line);
    if (_lines.length > 50) _lines.removeLast();
    notifyListeners();
  }

  /// Removes everything.
  void clear() {
    _lines.clear();
    notifyListeners();
  }
}

/// Renders an [EventLog].
class EventLogView extends StatelessWidget {
  /// Creates a view.
  const EventLogView({
    super.key,
    required this.log,
    this.emptyText = 'Nothing yet.',
  });

  /// Source log.
  final EventLog log;

  /// Shown while the log is empty.
  final String emptyText;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: log,
    builder: (context, _) => Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 48, maxHeight: 220),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: log.lines.isEmpty
          ? Text(emptyText, style: Theme.of(context).textTheme.bodySmall)
          : ListView(
              shrinkWrap: true,
              children: [
                for (final l in log.lines)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: SelectableText(
                      l,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
    ),
  );
}
