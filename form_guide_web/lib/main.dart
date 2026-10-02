// Guide website for the services_rj dynamic form builder.
//
// Every live example renders with the real package (path dependency), and
// test/catalog_sync_test.dart fails when the package gains a field type,
// property, style key, validator or operator that is not documented here.
import 'package:flutter/material.dart';

import 'guide_enums.dart';
import 'pages/advanced_pages.dart';
import 'pages/basics_pages.dart';
import 'pages/elements_page.dart';

void main() {
  registerGuideEnums();
  runApp(const FormGuideApp());
}

class GuideSection {
  const GuideSection(this.slug, this.title, this.icon, this.builder);
  final String slug;
  final String title;
  final IconData icon;
  final WidgetBuilder builder;
}

final List<GuideSection> guideSections = [
  GuideSection(
    'start',
    'Getting started',
    Icons.rocket_launch_outlined,
    (_) => const GettingStartedPage(),
  ),
  GuideSection(
    'elements',
    'Element builder',
    Icons.view_quilt_outlined,
    (_) => const ElementsPage(),
  ),
  GuideSection(
    'fields',
    'Field types',
    Icons.widgets_outlined,
    (_) => const FieldTypesPage(),
  ),
  GuideSection(
    'properties',
    'Properties',
    Icons.tune,
    (_) => const PropertiesPage(),
  ),
  GuideSection(
    'validation',
    'Validation',
    Icons.rule,
    (_) => const ValidationPage(),
  ),
  GuideSection(
    'conditions',
    'Conditions',
    Icons.call_split,
    (_) => const ConditionsPage(),
  ),
  GuideSection('enums', 'Enums', Icons.list_alt, (_) => const EnumsPage()),
  GuideSection(
    'extendable',
    'Extendable forms',
    Icons.playlist_add,
    (_) => const ExtendablePage(),
  ),
  GuideSection(
    'styling',
    'Styling',
    Icons.palette_outlined,
    (_) => const StylingPage(),
  ),
  GuideSection(
    'wizard',
    'Steps & edit mode',
    Icons.linear_scale,
    (_) => const WizardPage(),
  ),
  GuideSection(
    'controller',
    'Controller API',
    Icons.settings_remote_outlined,
    (_) => const ControllerPage(),
  ),
  GuideSection(
    'playground',
    'Playground',
    Icons.science_outlined,
    (_) => const PlaygroundPage(),
  ),
];

class FormGuideApp extends StatefulWidget {
  const FormGuideApp({super.key});

  @override
  State<FormGuideApp> createState() => _FormGuideAppState();
}

class _FormGuideAppState extends State<FormGuideApp> {
  ThemeMode _mode = ThemeMode.system;

  @override
  Widget build(BuildContext context) {
    ThemeData theme(Brightness b) => ThemeData(
      colorSchemeSeed: const Color(0xFF00796B),
      brightness: b,
      useMaterial3: true,
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
    );
    return MaterialApp(
      title: 'services_rj form guide',
      debugShowCheckedModeBanner: false,
      theme: theme(Brightness.light),
      darkTheme: theme(Brightness.dark),
      themeMode: _mode,
      // `/#/fields` style deep links.
      onGenerateRoute: (settings) {
        final slug =
            (settings.name ?? '/')
                .split('/')
                .where((p) => p.isNotEmpty)
                .firstOrNull ??
            '';
        final index = guideSections.indexWhere((s) => s.slug == slug);
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => GuideShell(
            index: index < 0 ? 0 : index,
            onToggleTheme: () => setState(
              () => _mode = _mode == ThemeMode.dark
                  ? ThemeMode.light
                  : ThemeMode.dark,
            ),
          ),
        );
      },
    );
  }
}

class GuideShell extends StatelessWidget {
  const GuideShell({
    super.key,
    required this.index,
    required this.onToggleTheme,
  });

  final int index;
  final VoidCallback onToggleTheme;

  void _go(BuildContext context, int i) {
    if (i == index) return;
    Navigator.of(context).pushReplacementNamed('/${guideSections[i].slug}');
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final section = guideSections[index];
    final nav = NavigationRail(
      extended: true,
      minExtendedWidth: 220,
      selectedIndex: index,
      onDestinationSelected: (i) => _go(context, i),
      destinations: [
        for (final s in guideSections)
          NavigationRailDestination(icon: Icon(s.icon), label: Text(s.title)),
      ],
    );
    return Scaffold(
      appBar: AppBar(
        title: Text(wide ? 'services_rj · JSON form guide' : section.title),
        actions: [
          IconButton(
            tooltip: 'Toggle theme',
            icon: const Icon(Icons.brightness_6_outlined),
            onPressed: onToggleTheme,
          ),
        ],
      ),
      drawer: wide
          ? null
          : NavigationDrawer(
              selectedIndex: index,
              onDestinationSelected: (i) {
                Navigator.pop(context);
                _go(context, i);
              },
              children: [
                const SizedBox(height: 12),
                for (final s in guideSections)
                  NavigationDrawerDestination(
                    icon: Icon(s.icon),
                    label: Text(s.title),
                  ),
              ],
            ),
      body: wide
          ? Row(
              children: [
                SingleChildScrollView(child: IntrinsicHeight(child: nav)),
                const VerticalDivider(width: 1),
                Expanded(child: section.builder(context)),
              ],
            )
          : section.builder(context),
    );
  }
}
