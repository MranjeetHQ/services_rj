import 'package:flutter/material.dart';

import '../core/app_theme_controller.dart';

/// Light / System / Dark selector bound to [AppThemeController]. The choice
/// is saved when shared preferences are on.
class ThemeModeSelector extends StatelessWidget {
  const ThemeModeSelector({
    super.key,
    this.lightLabel = 'Light',
    this.systemLabel = 'System',
    this.darkLabel = 'Dark',
    this.showIcons = true,
    this.showLabels = true,
  });

  final String lightLabel;
  final String systemLabel;
  final String darkLabel;
  final bool showIcons;
  final bool showLabels;

  @override
  Widget build(BuildContext context) {
    final controller = AppThemeController.instance;
    ButtonSegment<ThemeMode> segment(
      ThemeMode mode,
      String label,
      IconData icon,
    ) => ButtonSegment(
      value: mode,
      tooltip: showLabels ? null : label,
      icon: showIcons ? Icon(icon) : null,
      label: showLabels ? Text(label) : null,
    );

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => SegmentedButton<ThemeMode>(
        showSelectedIcon: false,
        segments: [
          segment(ThemeMode.light, lightLabel, Icons.light_mode_outlined),
          segment(ThemeMode.system, systemLabel, Icons.brightness_auto),
          segment(ThemeMode.dark, darkLabel, Icons.dark_mode_outlined),
        ],
        selected: {controller.themeMode},
        onSelectionChanged: (s) => controller.setThemeMode(s.first),
      ),
    );
  }
}

/// Accent colour swatches bound to [AppThemeController.setSeedColor]. The
/// first swatch ("Default") returns to [AppThemeConfig.seedColor].
class ThemeColorPicker extends StatelessWidget {
  const ThemeColorPicker({
    super.key,
    this.colors = defaultColors,
    this.showDefault = true,
    this.defaultLabel = 'Default',
    this.size = 36,
    this.spacing = 10,
  });

  /// A spread of Material accents.
  static const List<Color> defaultColors = [
    Colors.blue,
    Colors.indigo,
    Colors.deepPurple,
    Colors.pink,
    Colors.red,
    Colors.deepOrange,
    Colors.amber,
    Colors.green,
    Colors.teal,
    Colors.cyan,
    Colors.brown,
    Colors.blueGrey,
  ];

  final List<Color> colors;

  /// Shows a swatch that resets to the config's colour.
  final bool showDefault;
  final String defaultLabel;
  final double size;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final controller = AppThemeController.instance;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final current = controller.hasCustomSeedColor
            ? controller.seedColor.toARGB32()
            : null;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            if (showDefault)
              _Swatch(
                color: controller.config.seedColor,
                label: defaultLabel,
                size: size,
                selected: current == null,
                icon: Icons.restart_alt,
                onTap: () => controller.setSeedColor(null),
              ),
            for (final color in colors)
              _Swatch(
                color: color,
                label: '#${color.toARGB32().toRadixString(16).substring(2)}',
                size: size,
                selected: current == color.toARGB32(),
                onTap: () => controller.setSeedColor(color),
              ),
          ],
        );
      },
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.color,
    required this.label,
    required this.size,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final Color color;
  final String label;
  final double size;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final onColor =
        ThemeData.estimateBrightnessForColor(color) == Brightness.dark
        ? Colors.white
        : Colors.black;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Tooltip(
        message: label,
        child: InkResponse(
          onTap: onTap,
          radius: size / 2 + 4,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                width: 3,
                color: selected
                    ? Theme.of(context).colorScheme.onSurface
                    : Colors.transparent,
              ),
            ),
            child: selected
                ? Icon(Icons.check, size: size * 0.5, color: onColor)
                : icon == null
                ? null
                : Icon(icon, size: size * 0.5, color: onColor),
          ),
        ),
      ),
    );
  }
}
