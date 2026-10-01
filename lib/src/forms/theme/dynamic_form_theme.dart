import 'package:flutter/material.dart';

import '../models/field_style.dart';

/// Visual + behavioral customization for a [DynamicForm] subtree.
///
/// Wrap your form (or app) in a [DynamicFormTheme] to override spacing,
/// decorations, and the error/loading widgets:
///
/// ```dart
/// DynamicFormTheme(
///   data: DynamicFormThemeData(
///     fieldSpacing: 20,
///     decorationBuilder: (context, field, decoration) =>
///         decoration.copyWith(border: const OutlineInputBorder()),
///   ),
///   child: DynamicForm(...),
/// )
/// ```
class DynamicFormTheme extends InheritedWidget {
  /// Creates a form theme.
  const DynamicFormTheme({super.key, required this.data, required super.child});

  /// The theme data.
  final DynamicFormThemeData data;

  /// Resolves the nearest theme (falls back to defaults).
  static DynamicFormThemeData of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<DynamicFormTheme>()?.data ??
      const DynamicFormThemeData();

  @override
  bool updateShouldNotify(DynamicFormTheme oldWidget) => data != oldWidget.data;
}

/// Builder that lets apps post-process the auto-generated decoration.
typedef DecorationBuilder =
    InputDecoration Function(
      BuildContext context,
      Object fieldConfig,
      InputDecoration decoration,
    );

/// Immutable form theme values.
class DynamicFormThemeData {
  /// Creates theme data.
  const DynamicFormThemeData({
    this.fieldSpacing = 16,
    this.useCupertino = false,
    this.dense = false,
    this.errorBuilder,
    this.loadingBuilder,
    this.decorationBuilder,
    this.labelStyle,
    this.sectionHeaderStyle,
    this.defaultFieldStyle,
    this.discardDialogBuilder,
  });

  /// Vertical gap between fields.
  final double fieldSpacing;

  /// Render pickers with Cupertino styling where applicable.
  final bool useCupertino;

  /// Dense input decorations.
  final bool dense;

  /// Custom error widget below fields.
  final Widget Function(BuildContext context, String message)? errorBuilder;

  /// Custom loading widget (async options).
  final WidgetBuilder? loadingBuilder;

  /// Hook to customize every field's [InputDecoration].
  final DecorationBuilder? decorationBuilder;

  /// Style for standalone labels.
  final TextStyle? labelStyle;

  /// Style for section headers.
  final TextStyle? sectionHeaderStyle;

  /// App-wide default field appearance; overridden by the form JSON `style`
  /// and per-field `style` / `decoration`.
  final FieldStyleConfig? defaultFieldStyle;

  /// Custom unsaved-changes dialog. Return `true` to discard and leave,
  /// `false`/`null` to stay. Falls back to a localized [AlertDialog].
  final Future<bool?> Function(BuildContext context)? discardDialogBuilder;
}
