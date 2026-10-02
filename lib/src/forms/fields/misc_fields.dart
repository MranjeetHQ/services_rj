import 'package:flutter/material.dart';

import '../builders/field_factory.dart';
import '../controllers/dynamic_form_controller.dart';
import '../models/field_config.dart';
import '../theme/dynamic_form_theme.dart';
import 'decoration_helper.dart';

/// Renderer for the color picker field (preset palette dialog, no deps).
class DynamicColorField extends StatelessWidget {
  /// Creates a color picker field.
  const DynamicColorField({
    super.key,
    required this.field,
    required this.controller,
  });

  /// Field configuration.
  final FieldConfig field;

  /// Owning form controller.
  final DynamicFormController controller;

  static const List<Color> _palette = [
    Colors.red,
    Colors.pink,
    Colors.purple,
    Colors.deepPurple,
    Colors.indigo,
    Colors.blue,
    Colors.lightBlue,
    Colors.cyan,
    Colors.teal,
    Colors.green,
    Colors.lightGreen,
    Colors.lime,
    Colors.yellow,
    Colors.amber,
    Colors.orange,
    Colors.deepOrange,
    Colors.brown,
    Colors.grey,
    Colors.blueGrey,
    Colors.black,
  ];

  List<Color> _colors() {
    final custom = field.ex<List<dynamic>>('colors');
    if (custom == null) return _palette;
    return custom
        .map(
          (c) => Color(
            int.parse(c.toString().replaceFirst('#', ''), radix: 16) |
                0xFF000000,
          ),
        )
        .toList();
  }

  Future<void> _pick(BuildContext context) async {
    final picked = await showDialog<Color>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(field.label ?? 'Color'),
        content: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final c in _colors())
              InkWell(
                onTap: () => Navigator.pop(context, c),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black26),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
    if (picked != null) {
      final argb = picked.toARGB32();
      controller.setValue(
        field.id,
        '#${(argb & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = controller.state(field.id);
    return ValueListenableBuilder<Object?>(
      valueListenable: state.value,
      builder: (context, value, _) {
        final hex = value?.toString();
        final color = hex == null
            ? null
            : Color(
                int.parse(hex.replaceFirst('#', ''), radix: 16) | 0xFF000000,
              );
        return InkWell(
          onTap: () => _pick(context),
          child: InputDecorator(
            decoration: buildFieldDecoration(
              context,
              field,
              controller,
              suffix: const Icon(Icons.palette),
            ),
            isEmpty: hex == null,
            child: Row(
              children: [
                if (color != null)
                  Container(
                    width: 20,
                    height: 20,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                Text(hex ?? ''),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Renderer for display-only fields: label, divider, spacer, sectionHeader.
class DynamicDisplayField extends StatelessWidget {
  /// Creates a display field.
  const DynamicDisplayField({
    super.key,
    required this.field,
    required this.kind,
  });

  /// Field configuration.
  final FieldConfig field;

  /// One of `label`, `divider`, `spacer`, `sectionHeader`.
  final String kind;

  @override
  Widget build(BuildContext context) {
    final theme = DynamicFormTheme.of(context);
    switch (kind) {
      case 'divider':
        return const Divider();
      case 'spacer':
        return SizedBox(height: field.height ?? 16);
      case 'sectionHeader':
        return Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 4),
          child: Text(
            field.label ?? '',
            style:
                theme.sectionHeaderStyle ??
                Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        );
      default:
        return Text(
          field.label ?? '',
          style: theme.labelStyle ?? Theme.of(context).textTheme.bodyMedium,
        );
    }
  }
}

/// Renderer shown for pluggable field types (signature, QR/barcode,
/// custom…) when no adapter has been registered via
/// [FieldFactory.register]. Keeps forms functional and tells the developer
/// exactly what to do.
class MissingAdapterField extends StatelessWidget {
  /// Creates the placeholder.
  const MissingAdapterField({super.key, required this.field});

  /// Field configuration.
  final FieldConfig field;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outline),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.extension_outlined),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${field.label ?? field.id}: no adapter registered for '
              '"${field.type.name}". Call FieldFactory.register('
              'FieldType.${field.type.name}, builder) at app startup.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
