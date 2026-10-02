import 'package:flutter/material.dart';
import 'package:services_rj/services_rj.dart';

import '../../widgets/demo_widgets.dart';

/// Events from the network demos: interceptor traces and the global
/// `ApiConfig` callbacks. `main()` writes to it from `onUnauthorized`,
/// `onSessionExpired`, `onUserBanned` and `onError`.
final EventLog demoNetworkEvents = EventLog();

/// Tells the reader a demo needs features that are switched off.
class FeatureOffNotice extends StatelessWidget {
  /// Creates a notice for the [missing] features.
  const FeatureOffNotice({super.key, required this.missing});

  /// Features that are not ready.
  final List<AppFeature> missing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.power_off, color: scheme.onErrorContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Feature off',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: scheme.onErrorContainer,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'This demo needs ${missing.map((f) => f.name).join(' and ')}. '
                    'Enable it on the AppController page and come back.',
                    style: TextStyle(color: scheme.onErrorContainer),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shows [builder] only while every feature in [features] is ready, and a
/// [FeatureOffNotice] otherwise. Rebuilds when [AppController] changes.
class FeatureGate extends StatelessWidget {
  /// Creates a gate.
  const FeatureGate({
    super.key,
    required this.title,
    required this.features,
    required this.builder,
    this.intro,
  });

  /// Title of the placeholder page.
  final String title;

  /// Intro of the placeholder page.
  final String? intro;

  /// Features the page needs.
  final List<AppFeature> features;

  /// Builds the real page.
  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: AppController.instance,
    builder: (context, _) {
      final missing = [
        for (final f in features)
          if (!AppController.instance.isReady(f)) f,
      ];
      if (missing.isEmpty) return builder(context);
      return DemoPage(
        title: title,
        intro: intro,
        children: [FeatureOffNotice(missing: missing)],
      );
    },
  );
}

/// Label and value rows in monospace, for showing live object state.
class KeyValueTable extends StatelessWidget {
  /// Creates a table.
  const KeyValueTable(this.rows, {super.key});

  /// Label and value pairs.
  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      children: [
        for (final (label, value) in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 150,
                  child: Text(
                    label,
                    style: text.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  child: SelectableText(
                    value,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// A [FilledButton] that disables itself and shows a spinner while its async
/// [onPressed] runs.
class BusyButton extends StatefulWidget {
  /// Creates a button.
  const BusyButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.tonal = false,
  });

  /// Button text.
  final String label;

  /// Optional leading icon.
  final IconData? icon;

  /// Use the tonal style.
  final bool tonal;

  /// Work to run. The button stays disabled until it completes.
  final Future<void> Function() onPressed;

  @override
  State<BusyButton> createState() => _BusyButtonState();
}

class _BusyButtonState extends State<BusyButton> {
  bool _busy = false;

  Future<void> _run() async {
    setState(() => _busy = true);
    try {
      await widget.onPressed();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final icon = _busy
        ? const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : (widget.icon == null ? null : Icon(widget.icon, size: 18));
    final onPressed = _busy ? null : _run;
    return widget.tonal
        ? FilledButton.tonalIcon(
            onPressed: onPressed,
            icon: icon ?? const SizedBox.shrink(),
            label: Text(widget.label),
          )
        : FilledButton.icon(
            onPressed: onPressed,
            icon: icon ?? const SizedBox.shrink(),
            label: Text(widget.label),
          );
  }
}

/// Small heading used inside a [DemoSection].
class SubHeading extends StatelessWidget {
  /// Creates a heading.
  const SubHeading(this.text, {super.key});

  /// Heading text.
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 12, bottom: 6),
    child: Text(text, style: Theme.of(context).textTheme.titleSmall),
  );
}
