import 'package:flutter/material.dart';
import 'package:services_rj/services_rj.dart';

import '../../widgets/demo_widgets.dart';
import 'core_common.dart';

/// A design token carried by the theme through [AppThemeConfig.extensions].
class DemoBrand extends ThemeExtension<DemoBrand> {
  /// Creates the token.
  const DemoBrand({required this.badgeColor});

  /// Background of the brand badge in the preview.
  final Color badgeColor;

  @override
  DemoBrand copyWith({Color? badgeColor}) =>
      DemoBrand(badgeColor: badgeColor ?? this.badgeColor);

  @override
  DemoBrand lerp(DemoBrand? other, double t) => other == null
      ? this
      : DemoBrand(badgeColor: Color.lerp(badgeColor, other.badgeColor, t)!);
}

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
  ThemeMode _initialMode = ThemeMode.system;
  bool _exactScheme = false;
  bool _largeText = false;
  bool _compact = false;
  bool _centerTitle = true;
  double _appBarElevation = 0;
  bool _inputFilled = true;
  Color _badgeColor = Colors.deepOrange;
  bool _thickDividers = false;

  /// The app's config when the page opened, for "Restore app config".
  late final AppThemeConfig _appConfig;
  bool _appliedToApp = false;

  @override
  void initState() {
    super.initState();
    _appConfig = AppThemeController.instance.config;
  }

  static ThemeData _thickDividerTheme(ThemeData theme, Brightness _) =>
      theme.copyWith(
        dividerTheme: DividerThemeData(
          thickness: 3,
          color: theme.colorScheme.primary,
        ),
      );

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
    initialThemeMode: _initialMode,
    lightColorScheme: _exactScheme
        ? const ColorScheme.light(
            primary: Color(0xFF5B2A86),
            secondary: Color(0xFFE07A5F),
          )
        : null,
    darkColorScheme: _exactScheme
        ? const ColorScheme.dark(
            primary: Color(0xFFD0B3FF),
            secondary: Color(0xFFF2A88F),
          )
        : null,
    textTheme: _largeText
        ? const TextTheme(
            bodyMedium: TextStyle(fontSize: 17),
            bodyLarge: TextStyle(fontSize: 19),
          )
        : null,
    visualDensity: _compact ? VisualDensity.compact : null,
    appBarCenterTitle: _centerTitle,
    appBarElevation: _appBarElevation,
    inputFilled: _inputFilled,
    extensions: [DemoBrand(badgeColor: _badgeColor)],
    customize: _thickDividers ? _thickDividerTheme : null,
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
      '  initialThemeMode: ThemeMode.${_initialMode.name},\n'
      '${_exactScheme ? '  lightColorScheme: ColorScheme.light(...),\n'
                '  darkColorScheme: ColorScheme.dark(...),\n' : ''}'
      '${_largeText ? '  textTheme: TextTheme(bodyMedium: TextStyle(fontSize: 17)),\n' : ''}'
      '${_compact ? '  visualDensity: VisualDensity.compact,\n' : ''}'
      '  appBarCenterTitle: $_centerTitle,\n'
      '  appBarElevation: ${_appBarElevation.round()},\n'
      '  inputFilled: $_inputFilled,\n'
      '  extensions: [DemoBrand(badgeColor: ...)],\n'
      '${_thickDividers ? '  customize: (theme, brightness) => theme.copyWith(\n'
                '    dividerTheme: DividerThemeData(thickness: 3),\n'
                '  ),\n' : ''}'
      ')\n'
      '// Pass it once at start-up; ServicesApp applies it.\n'
      'AppSetup.run(themeConfig: config, app: ServicesApp(home: ...));\n'
      '// Or build the themes yourself:\n'
      'MaterialApp(\n'
      '  theme: AppThemeManager.lightTheme(config),\n'
      '  darkTheme: AppThemeManager.darkTheme(config),\n'
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
              const SizedBox(height: 16),
              const Text('initialThemeMode (first launch only)'),
              const SizedBox(height: 8),
              SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment(value: ThemeMode.light, label: Text('light')),
                  ButtonSegment(value: ThemeMode.system, label: Text('system')),
                  ButtonSegment(value: ThemeMode.dark, label: Text('dark')),
                ],
                selected: {_initialMode},
                onSelectionChanged: (v) =>
                    setState(() => _initialMode = v.first),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Exact colour schemes'),
                subtitle: const Text(
                  'lightColorScheme / darkColorScheme replace the seed.',
                ),
                value: _exactScheme,
                onChanged: (v) => setState(() => _exactScheme = v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Larger body text (textTheme)'),
                value: _largeText,
                onChanged: (v) => setState(() => _largeText = v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Compact visualDensity'),
                value: _compact,
                onChanged: (v) => setState(() => _compact = v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('appBarCenterTitle'),
                value: _centerTitle,
                onChanged: (v) => setState(() => _centerTitle = v),
              ),
              _slider(
                'appBarElevation',
                _appBarElevation,
                0,
                8,
                (v) => _appBarElevation = v.roundToDouble(),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('inputFilled'),
                value: _inputFilled,
                onChanged: (v) => setState(() => _inputFilled = v),
              ),
              const SizedBox(height: 8),
              const Text('extensions: DemoBrand badge colour'),
              const SizedBox(height: 8),
              _swatches(
                selected: _badgeColor,
                onPick: (c) => setState(() => _badgeColor = c ?? _badgeColor),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('customize: thick primary dividers'),
                subtitle: const Text('A hook for anything the config lacks.'),
                value: _thickDividers,
                onChanged: (v) => setState(() => _thickDividers = v),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    icon: const Icon(Icons.public),
                    label: const Text('Apply to whole app'),
                    onPressed: () {
                      AppThemeController.instance.setConfig(config);
                      setState(() => _appliedToApp = true);
                    },
                  ),
                  OutlinedButton(
                    onPressed: _appliedToApp
                        ? () {
                            AppThemeController.instance.setConfig(_appConfig);
                            setState(() => _appliedToApp = false);
                          }
                        : null,
                    child: const Text('Restore app config'),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Uses AppThemeController.instance.setConfig(config); '
                'ServicesApp rebuilds with it.',
                style: Theme.of(context).textTheme.bodySmall,
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
                    const Divider(height: 24),
                    Builder(
                      builder: (context) {
                        final brand = Theme.of(context).extension<DemoBrand>();
                        if (brand == null) return const SizedBox.shrink();
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: brand.badgeColor,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'ThemeExtension badge',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        );
                      },
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
            'Global theme mode and accent colour. Unlike the previews above, '
            'these change the whole app. They are saved when sharedPref is on.',
        code:
            'const ThemeModeSelector();\n'
            'const ThemeColorPicker();\n'
            'await AppThemeController.instance.setThemeMode(ThemeMode.dark);\n'
            'await AppThemeController.instance.setSeedColor(Colors.pink);\n'
            'await AppThemeController.instance.resetToDefaults();',
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
            const ThemeModeSelector(),
            const SizedBox(height: 16),
            const Text('Accent colour (ThemeColorPicker)'),
            const SizedBox(height: 8),
            const ThemeColorPicker(),
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
                OutlinedButton(
                  onPressed: controller.resetToDefaults,
                  child: const Text('resetToDefaults()'),
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
            KeyValueRow(
              'seedColor',
              '#${controller.seedColor.toARGB32().toRadixString(16)}'
                  '${controller.hasCustomSeedColor ? ' (user)' : ' (config)'}',
            ),
          ],
        ),
      ),
    );
  }
}
