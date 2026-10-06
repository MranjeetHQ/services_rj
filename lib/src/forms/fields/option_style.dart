import 'package:flutter/material.dart';

import '../models/field_config.dart';
import '../models/field_enums.dart';
import '../models/field_style.dart';

/// Shape of the checkbox control for [field] (`"controlShape"`).
ControlShape? controlShapeOf(FieldConfig field) =>
    ControlShape.fromString(field.extra['controlShape']);

/// Position of the control for [field] (`"controlPosition"`).
ControlPosition? controlPositionOf(FieldConfig field) =>
    ControlPosition.fromString(field.extra['controlPosition']);

/// Flutter [OutlinedBorder] for a checkbox [shape], or null for the default.
OutlinedBorder? checkboxBorder(ControlShape? shape) => switch (shape) {
  ControlShape.square => const RoundedRectangleBorder(),
  ControlShape.rounded => RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(5),
  ),
  ControlShape.circle => const CircleBorder(),
  null => null,
};

/// One option drawn in the [OptionStyle.card], [OptionStyle.chip] or
/// [OptionStyle.button] style. Every colour, radius and padding comes from
/// the field style (`selectedColor`, `selectedBorderColor`,
/// `optionBorderColor`, `optionRadius`, `optionPadding`,
/// `selectedTextStyle`, `activeColor`).
class StyledOption extends StatelessWidget {
  /// Creates a styled option.
  const StyledOption({
    super.key,
    required this.optionStyle,
    required this.style,
    required this.label,
    required this.selected,
    required this.onTap,
    this.description,
    this.icon,
    this.radio = false,
    this.shape,
    this.position,
    this.trailing,
  });

  /// Card, chip or button.
  final OptionStyle optionStyle;

  /// Resolved field style.
  final FieldStyleConfig style;

  /// Option label.
  final Widget label;

  /// Optional second line.
  final String? description;

  /// Optional icon before the label.
  final Widget? icon;

  /// Whether the option is selected.
  final bool selected;

  /// Called on tap; null disables the option.
  final VoidCallback? onTap;

  /// Draw a radio mark instead of a checkbox mark.
  final bool radio;

  /// Checkbox mark shape (radio marks are always round).
  final ControlShape? shape;

  /// Where the mark sits; defaults per style (card: leading, chip and
  /// button: none).
  final ControlPosition? position;

  /// Replaces the mark (used for switches).
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final active = style.activeColor ?? scheme.primary;
    final isChip = optionStyle == OptionStyle.chip;
    final isButton = optionStyle == OptionStyle.button;
    final radius =
        style.optionRadius ??
        switch (optionStyle) {
          OptionStyle.chip => 100.0,
          OptionStyle.button => 10.0,
          _ => 12.0,
        };
    final padding =
        style.optionPadding ??
        switch (optionStyle) {
          OptionStyle.chip => const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 8,
          ),
          OptionStyle.button => const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          _ => const EdgeInsets.all(12),
        };
    final pos =
        position ??
        (optionStyle == OptionStyle.card
            ? ControlPosition.leading
            : ControlPosition.none);
    final mark =
        trailing ??
        _ControlMark(
          selected: selected,
          radio: radio,
          shape: shape,
          color: active,
          border: scheme.outline,
        );
    final textStyle =
        (selected
                ? theme.textTheme.bodyLarge?.copyWith(
                    color: isButton || isChip ? active : null,
                    fontWeight: FontWeight.w600,
                  )
                : theme.textTheme.bodyLarge)
            ?.merge(selected ? style.selectedTextStyle : null);

    final text = Column(
      crossAxisAlignment: isButton
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        DefaultTextStyle.merge(
          style: textStyle,
          textAlign: isButton ? TextAlign.center : null,
          child: label,
        ),
        if (description != null)
          Text(
            description!,
            textAlign: isButton ? TextAlign.center : null,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
      ],
    );

    final row = Row(
      mainAxisSize: isChip ? MainAxisSize.min : MainAxisSize.max,
      mainAxisAlignment: isButton
          ? MainAxisAlignment.center
          : MainAxisAlignment.start,
      children: [
        if (pos == ControlPosition.leading) ...[
          mark,
          const SizedBox(width: 10),
        ],
        if (isChip && selected && pos == ControlPosition.none) ...[
          Icon(Icons.check_rounded, size: 18, color: active),
          const SizedBox(width: 6),
        ],
        if (icon != null) ...[icon!, const SizedBox(width: 8)],
        if (isChip) text else Flexible(fit: FlexFit.tight, child: text),
        if (pos == ControlPosition.trailing) ...[
          const SizedBox(width: 10),
          mark,
        ],
      ],
    );

    final borderColor = selected
        ? style.selectedBorderColor ?? active
        : style.optionBorderColor ?? scheme.outlineVariant;
    return Opacity(
      opacity: onTap == null ? 0.5 : 1,
      child: Material(
        color: selected
            ? style.selectedColor ?? active.withValues(alpha: 0.10)
            : Colors.transparent,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
          side: BorderSide(color: borderColor, width: selected ? 1.5 : 1),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(padding: padding, child: row),
        ),
      ),
    );
  }
}

/// Checkbox or radio mark drawn without Material's control widgets, so the
/// shape and colour follow the field style.
class _ControlMark extends StatelessWidget {
  const _ControlMark({
    required this.selected,
    required this.radio,
    required this.shape,
    required this.color,
    required this.border,
  });

  final bool selected;
  final bool radio;
  final ControlShape? shape;
  final Color color;
  final Color border;

  @override
  Widget build(BuildContext context) {
    final round = radio || shape == ControlShape.circle;
    final radius = round
        ? 100.0
        : shape == ControlShape.square
        ? 2.0
        : 5.0;
    if (radio) {
      return AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: selected ? color : border, width: 2),
        ),
        alignment: Alignment.center,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: selected ? 10 : 0,
          height: selected ? 10 : 0,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      );
    }
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: selected ? color : Colors.transparent,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: selected ? color : border, width: 2),
      ),
      child: selected
          ? Icon(
              Icons.check_rounded,
              size: 14,
              color:
                  ThemeData.estimateBrightnessForColor(color) == Brightness.dark
                  ? Colors.white
                  : Colors.black,
            )
          : null,
    );
  }
}
