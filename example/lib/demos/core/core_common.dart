import 'package:flutter/material.dart';

/// Banner shown when a demo needs a package feature that is not running.
///
/// Tests (and apps that skip `AppController.initialize`) hit this path, so
/// every core demo renders it instead of throwing.
class FeatureOffNotice extends StatelessWidget {
  /// Creates a notice for [feature].
  const FeatureOffNotice({super.key, required this.feature, this.detail});

  /// Human readable feature name, for example `sharedPref`.
  final String feature;

  /// Extra explanation appended to the default text.
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.power_settings_new, color: scheme.onSecondaryContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'The "$feature" feature is off. Enable it in '
              'AppController.initialize(features: ...) to try this demo.'
              '${detail == null ? '' : ' $detail'}',
              style: TextStyle(color: scheme.onSecondaryContainer),
            ),
          ),
        ],
      ),
    );
  }
}

/// Small pill that reads green when [ok] and neutral otherwise.
class StatusPill extends StatelessWidget {
  /// Creates a pill.
  const StatusPill({super.key, required this.label, required this.ok});

  /// Text inside the pill.
  final String label;

  /// Whether the pill is in its positive state.
  final bool ok;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Chip(
      visualDensity: VisualDensity.compact,
      avatar: Icon(
        ok ? Icons.check_circle : Icons.remove_circle_outline,
        size: 16,
        color: ok ? Colors.green : scheme.outline,
      ),
      label: Text(label),
    );
  }
}

/// Label on the left, monospace value on the right.
class KeyValueRow extends StatelessWidget {
  /// Creates a row.
  const KeyValueRow(this.label, this.value, {super.key});

  /// Left text.
  final String label;

  /// Right text.
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: Text(label, style: Theme.of(context).textTheme.bodySmall),
        ),
        Expanded(
          child: SelectableText(
            value,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12.5),
          ),
        ),
      ],
    ),
  );
}

/// Asks the user to confirm an action. Returns true only on confirm.
Future<bool> confirmAction(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
  bool destructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      icon: destructive ? const Icon(Icons.warning_amber_rounded) : null,
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: destructive
              ? FilledButton.styleFrom(
                  backgroundColor: Theme.of(ctx).colorScheme.error,
                  foregroundColor: Theme.of(ctx).colorScheme.onError,
                )
              : null,
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}
