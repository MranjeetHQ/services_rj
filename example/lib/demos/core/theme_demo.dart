import 'package:flutter/material.dart';
import 'package:services_rj/services_rj.dart';

import '../../widgets/demo_widgets.dart';
import 'core_common.dart';

/// Live editor for [AppThemeConfig] plus the global [AppThemeController].
class ThemeDemo extends StatefulWidget {
  /// Creates the page.
  const ThemeDemo({super.key});

  @override
  State<ThemeDemo> createState() => _ThemeDemoState();
}

class _ThemeDemoState extends State<ThemeDemo> {
  static const _seeds = <String, Color>{
    'Blue': Colors.blue,
    'Teal': Colors.teal,
    'Indigo': Colors.indigo,
    'Orange': Colors.deepOrange,
    'Pink': Colors.pink,
    'Green': Colors.green,
  };

  Color _seed = Colors.teal;
  bool _material3 = true;
  double _radius = 12;
  bool _separateCard = false;
  double _cardRadius = 24;
  double _sideWidth = 1.5;
  Color? _sideColor;
  double _elevation = 2;
  Color? _iconColor;
  bool _boldButtons = false;
  bool _wideText = false;
  String? _font;

  AppThemeConfig get _config => AppThemeConfig(
    seedColor: _seed,
    useMaterial3: _material3,
    borderRadius: _radius,
    cardRadius: _separateCard ? _cardRadius : null,
    outlinedButtonSideWidth: _sideWidth,
    outlinedButtonSideColor: _sideColor,
    elevatedButtonElevation: _elevation,
    iconThemeColor: _iconColor,
    elevatedButtonTextStyle: _boldButtons
        ? const TextStyle(fontWeight: FontWeight.w800)
        : null,
    outlinedButtonTextStyle: _boldButtons
        ? const TextStyle(fontWeight: FontWeight.w600)
        : null,
    textButtonTextStyle: _wideText
        ? const TextStyle(letterSpacing: 1.5, fontSize: 15)
        : null,
    fontFamily: _font,
  );

  String get _code =>
      'AppThemeConfig(\n'
      '  seedColor: Color(0x${_seed.toARGB32().toRadixString(16)}),\n'
      '  useMaterial3: $_material3,\n'
      '  borderRadius: ${_radius.round()},\n'
      '${_separateCard ? '  cardRadius: ${_cardRadius.round()},\n' : ''}'
      '  outlinedButtonSideWidth: ${_sideWidth.toStringAsFixed(1)},\n'
      '  elevatedButtonElevation: ${_elevation.round()},\n'
      '${_font == null ? '' : "  fontFamily: '$_font',\n"}'
      ')\n'
      'MaterialApp(\n'
      '  theme: AppThemeManager.lightTheme(config),\n'
      '  darkTheme: AppThemeManager.darkTheme(config),\n'
      '  themeMode: AppThemeController.instance.themeMode,\n'
      ')';

  Widget _swatches({
    required Color? selected,
    required ValueChanged<Color?> onPick,
    bool allowDefault = false,
  }) => Wrap(
    spacing: 8,
    runSpacing: 8,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      if (allowDefault)
        ChoiceChip(
          label: const Text('Default'),
          selected: selected == null,
          onSelected: (_) => onPick(null),
        ),
      for (final e in _seeds.entries)
        Tooltip(
          message: e.key,
          child: GestureDetector(
            onTap: () => onPick(e.value),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: e.value,
                shape: BoxShape.circle,
                border: Border.all(
                  width: 3,
                  color: selected == e.value
                      ? Theme.of(context).colorScheme.onSurface
                      : Colors.transparent,
                ),
              ),
            ),
          ),
        ),
    ],
  );

  Widget _slider(
    String label,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged,
  ) => Row(
    children: [
      SizedBox(width: 130, child: Text('$label: ${value.toStringAsFixed(1)}')),
      Expanded(
        child: Slider(
          value: value,
          min: min,
          max: max,
          onChanged: (v) => setState(() => onChanged(v)),
        ),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final config = _config;
    final light = AppThemeManager.lightTheme(config);
    final dark = AppThemeManager.darkTheme(config);
    return DemoPage(
      title: 'Theme',
      intro:
          'AppThemeConfig describes your brand once; AppThemeManager turns it '
          'into light and dark ThemeData. The previews below are scoped and '
          'do not touch the rest of the app.',
      children: [
        DemoSection(
          title: 'Config editor',
          code: _code,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('seedColor'),
              const SizedBox(height: 8),
              _swatches(
                selected: _seed,
                onPick: (c) => setState(() => _seed = c ?? _seed),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('useMaterial3'),
                value: _material3,
                onChanged: (v) => setState(() => _material3 = v),
              ),
              _slider(
                'borderRadius',
                _radius,
                0,
                32,
                (v) => _radius = v.roundToDouble(),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Separate cardRadius'),
                subtitle: const Text('Off: cards use borderRadius.'),
                value: _separateCard,
                onChanged: (v) => setState(() => _separateCard = v),
              ),
              if (_separateCard)
                _slider(
                  'cardRadius',
                  _cardRadius,
                  0,
                  40,
                  (v) => _cardRadius = v.roundToDouble(),
                ),
              _slider(
                'outlined width',
                _sideWidth,
                0.5,
                6,
                (v) => _sideWidth = v,
              ),
              _slider(
                'elevation',
                _elevation,
                0,
                12,
                (v) => _elevation = v.roundToDouble(),
              ),
              const SizedBox(height: 8),
              const Text('outlinedButtonSideColor'),
              const SizedBox(height: 8),
              _swatches(
                selected: _sideColor,
                allowDefault: true,
                onPick: (c) => setState(() => _sideColor = c),
              ),
              const SizedBox(height: 12),
              const Text('iconThemeColor'),
              const SizedBox(height: 8),
              _swatches(
                selected: _iconColor,
                allowDefault: true,
                onPick: (c) => setState(() => _iconColor = c),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Bold elevated and outlined labels'),
                value: _boldButtons,
                onChanged: (v) => setState(() => _boldButtons = v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Wide text button labels'),
                value: _wideText,
                onChanged: (v) => setState(() => _wideText = v),
              ),
              DropdownButtonFormField<String?>(
                initialValue: _font,
                decoration: const InputDecoration(labelText: 'fontFamily'),
                items: const [
                  DropdownMenuItem(value: null, child: Text('Default')),
                  DropdownMenuItem(value: 'serif', child: Text('serif')),
                  DropdownMenuItem(
                    value: 'monospace',
                    child: Text('monospace'),
                  ),
                ],
                onChanged: (v) => setState(() => _font = v),
              ),
            ],
          ),
        ),
        DemoSection(
          title: 'Light and dark preview',
          subtitle:
              'Wrapped in Theme(data: AppThemeManager.lightTheme(config)).',
          child: LayoutBuilder(
            builder: (context, box) {
              final panes = [
                ThemePreviewPane(label: 'Light', data: light),
                ThemePreviewPane(label: 'Dark', data: dark),
              ];
              if (box.maxWidth < 560) {
                return Column(
                  children: [panes[0], const SizedBox(height: 16), panes[1]],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: panes[0]),
                  const SizedBox(width: 12),
                  Expanded(child: panes[1]),
                ],
              );
            },
          ),
        ),
        const _ThemeModeSection(),
      ],
    );
  }
}

/// A self-contained mock screen rendered with [data].
///
/// Shows every component [AppThemeManager] styles: buttons, card, inputs,
/// chips, dialog, app bar and bottom navigation.
class ThemePreviewPane extends StatefulWidget {
  /// Creates a pane.
  const ThemePreviewPane({super.key, required this.label, required this.data});

  /// Caption above the pane.
  final String label;

  /// Theme applied to the pane only.
  final ThemeData data;

  @override
  State<ThemePreviewPane> createState() => _ThemePreviewPaneState();
}

class _ThemePreviewPaneState extends State<ThemePreviewPane> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(widget.label, style: Theme.of(context).textTheme.labelLarge),
      const SizedBox(height: 6),
      Theme(
        data: widget.data,
        child: Builder(
          builder: (context) => ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 600,
              child: Scaffold(
                appBar: AppBar(title: Text('${widget.label} app bar')),
                body: ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ElevatedButton(
                          onPressed: () {},
                          child: const Text('Elevated'),
                        ),
                        OutlinedButton(
                          onPressed: () {},
                          child: const Text('Outlined'),
                        ),
                        TextButton(onPressed: () {}, child: const Text('Text')),
                        const Icon(Icons.favorite),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('A card using cardRadius'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const TextField(
                      decoration: InputDecoration(labelText: 'Email'),
                    ),
                    const SizedBox(height: 12),
                    const Wrap(
                      spacing: 8,
                      children: [
                        Chip(label: Text('Design')),
                        Chip(label: Text('Billing')),
                      ],
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () => showDialog<void>(
                        context: context,
                        builder: (ctx) => Theme(
                          data: widget.data,
                          child: AlertDialog(
                            title: const Text('Scoped dialog'),
                            content: const Text(
                              'Shape comes from dialogTheme in this preview.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(),
                                child: const Text('Close'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      child: const Text('Open dialog'),
                    ),
                  ],
                ),
                bottomNavigationBar: BottomNavigationBar(
                  currentIndex: _tab,
                  onTap: (i) => setState(() => _tab = i),
                  items: const [
                    BottomNavigationBarItem(
                      icon: Icon(Icons.home_outlined),
                      label: 'Home',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.search),
                      label: 'Search',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.person_outline),
                      label: 'Me',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ],
  );
}

class _ThemeModeSection extends StatelessWidget {
  const _ThemeModeSection();

  @override
  Widget build(BuildContext context) {
    final controller = AppThemeController.instance;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => DemoSection(
        title: 'AppThemeController',
        subtitle:
            'Global theme mode. Unlike the previews above, this changes the '
            'whole app. It is saved when sharedPref is on.',
        code:
            'await AppThemeController.instance.setThemeMode(ThemeMode.dark);\n'
            'await AppThemeController.instance.toggleTheme();\n'
            'const ThemeModeSwitcher();',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!AppController.instance.isReady(AppFeature.theme))
              const FeatureOffNotice(
                feature: 'theme',
                detail:
                    'The controller still works, but nothing persists it '
                    'and the app may not listen to it.',
              ),
            SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(value: ThemeMode.light, label: Text('Light')),
                ButtonSegment(value: ThemeMode.system, label: Text('System')),
                ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
              ],
              selected: {controller.themeMode},
              onSelectionChanged: (s) => controller.setThemeMode(s.first),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: controller.toggleTheme,
                  child: const Text('toggleTheme()'),
                ),
                const Text('ThemeModeSwitcher'),
                const ThemeModeSwitcher(),
              ],
            ),
            const SizedBox(height: 12),
            KeyValueRow('themeMode', controller.themeMode.name),
            KeyValueRow('isDarkMode', '${controller.isDarkMode}'),
            KeyValueRow('isLightMode', '${controller.isLightMode}'),
            KeyValueRow('isSystemMode', '${controller.isSystemMode}'),
          ],
        ),
      ),
    );
  }
}
