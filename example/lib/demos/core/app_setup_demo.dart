import 'package:flutter/material.dart';
import 'package:services_rj/services_rj.dart';

import '../../widgets/demo_widgets.dart';
import 'core_common.dart';

// Plain functions with no BuildContext, standing in for service or API
// callback code. They reach the UI through AppKeys.

/// Shows a snackbar from code without a context.
bool notifyFromService(String message) {
  final messenger = AppKeys.messenger;
  messenger?.showSnackBar(SnackBar(content: Text(message)));
  return messenger != null;
}

/// Opens a dialog from code without a context.
Future<bool> confirmFromService() async {
  final context = AppKeys.context;
  if (context == null) return false;
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Session expiring'),
      content: const Text('Opened with AppKeys.context from a service.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Sign out'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text('Stay signed in'),
        ),
      ],
    ),
  );
  return ok ?? false;
}

/// Pushes a page from code without a context.
bool openFromService() {
  final navigator = AppKeys.navigator;
  navigator?.push(
    MaterialPageRoute<void>(
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text('Pushed by AppKeys')),
        body: const Center(child: Text('AppKeys.navigator?.push(...)')),
      ),
    ),
  );
  return navigator != null;
}

/// Shows [AppSetup.run], [ServicesApp], [AppKeys] and a ready-made theme
/// settings screen.
class AppSetupDemo extends StatefulWidget {
  /// Creates the page.
  const AppSetupDemo({super.key});

  @override
  State<AppSetupDemo> createState() => _AppSetupDemoState();
}

class _AppSetupDemoState extends State<AppSetupDemo> {
  String _keysResult = '';

  void _report(String action, bool attached) => setState(
    () => _keysResult = attached
        ? '$action: done'
        : '$action: AppKeys are not attached (the app is not a ServicesApp)',
  );

  @override
  Widget build(BuildContext context) {
    final app = AppController.instance;
    final theme = AppThemeController.instance;
    final isServicesApp =
        context.findAncestorWidgetOfExactType<ServicesApp>() != null;

    return DemoPage(
      title: 'App setup',
      intro:
          'Everything a new app needs at start-up: one AppSetup.run call, '
          'a ServicesApp, global keys and a theme settings screen. This demo '
          'app starts exactly this way (see lib/main.dart).',
      children: [
        DemoSection(
          title: 'AppSetup.run',
          subtitle:
              'Runs in order: binding → error handlers (onError) → '
              'orientations and system bars → AppController.initialize → '
              'beforeRun → runApp.',
          code:
              'Future<void> main() => AppSetup.run(\n'
              '  features: const AppFeatures(sharedPref: true, theme: true),\n'
              '  themeConfig: const AppThemeConfig(seedColor: Colors.teal),\n'
              '  apiConfig: ApiConfig(baseUrl: ...),\n'
              '  cacheConfig: const CacheConfig(),\n'
              '  orientations: const [DeviceOrientation.portraitUp],\n'
              '  systemUiOverlayStyle: SystemUiOverlayStyle.dark,\n'
              '  beforeRun: () async => registerDemoEnums(),\n'
              '  onError: (error, stack) => crashReporter.record(error, stack),\n'
              '  app: const ServicesApp(title: "My app", home: HomePage()),\n'
              ');',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              KeyValueRow('AppController initialized', '${app.isInitialized}'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final f in AppFeature.values)
                    StatusPill(label: f.name, ok: app.isReady(f)),
                ],
              ),
              const SizedBox(height: 12),
              const _OptionTable(),
            ],
          ),
        ),
        DemoSection(
          title: 'ServicesApp',
          subtitle:
              'A MaterialApp that follows AppThemeController, attaches '
              'AppKeys and hides the debug banner. ServicesApp.router '
              'takes a RouterConfig (go_router etc.).',
          code:
              'ServicesApp(\n'
              '  title: "My app",\n'
              '  home: const HomePage(),          // or routes / onGenerateRoute\n'
              '  locale: const Locale("hi"),\n'
              '  localizationsDelegates: [...],\n'
              '  builder: (context, child) => child!,\n'
              '  // theme / darkTheme / themeMode override the controller\n'
              ')\n'
              'ServicesApp.router(routerConfig: router)',
          child: ListenableBuilder(
            listenable: theme,
            builder: (context, _) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StatusPill(
                  label: isServicesApp
                      ? 'This page runs inside a ServicesApp'
                      : 'Not inside a ServicesApp',
                  ok: isServicesApp,
                ),
                const SizedBox(height: 8),
                KeyValueRow('themeMode', theme.themeMode.name),
                KeyValueRow(
                  'seedColor',
                  '#${theme.seedColor.toARGB32().toRadixString(16)}',
                ),
                KeyValueRow(
                  'config.initialThemeMode',
                  theme.config.initialThemeMode.name,
                ),
              ],
            ),
          ),
        ),
        DemoSection(
          title: 'AppKeys',
          subtitle:
              'The buttons call plain functions with no BuildContext, the way '
              'a service or an API callback would.',
          code:
              'AppKeys.messenger?.showSnackBar(SnackBar(content: Text("Saved")));\n'
              'showDialog(context: AppKeys.context!, builder: ...);\n'
              'AppKeys.navigator?.push(MaterialPageRoute(builder: ...));',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StatusPill(
                label: AppKeys.navigator != null
                    ? 'Keys attached'
                    : 'Keys not attached',
                ok: AppKeys.navigator != null,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: () => _report(
                      'Snackbar',
                      notifyFromService('Profile saved (from a service)'),
                    ),
                    child: const Text('Snackbar via messenger'),
                  ),
                  OutlinedButton(
                    onPressed: () async {
                      final attached = AppKeys.context != null;
                      final stay = await confirmFromService();
                      _report(
                        attached ? 'Dialog (stay signed in: $stay)' : 'Dialog',
                        attached,
                      );
                    },
                    child: const Text('Dialog via context'),
                  ),
                  OutlinedButton(
                    onPressed: () => _report('Navigate', openFromService()),
                    child: const Text('Push via navigator'),
                  ),
                ],
              ),
              if (_keysResult.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(_keysResult),
              ],
            ],
          ),
        ),
        DemoSection(
          title: 'Theme settings screen',
          subtitle:
              'ThemeModeSelector and ThemeColorPicker are bound to '
              'AppThemeController and saved when sharedPref is on.',
          code:
              'ListTile(title: Text("Theme"), subtitle: ThemeModeSelector()),\n'
              'ListTile(title: Text("Accent"), subtitle: ThemeColorPicker()),\n'
              'TextButton(\n'
              '  onPressed: AppThemeController.instance.resetToDefaults,\n'
              '  child: Text("Reset"),\n'
              ')',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Theme'),
                subtitle: Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: ThemeModeSelector(),
                ),
              ),
              const ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Accent colour'),
                subtitle: Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: ThemeColorPicker(),
                ),
              ),
              TextButton.icon(
                icon: const Icon(Icons.restart_alt),
                label: const Text('Reset theme settings'),
                onPressed: theme.resetToDefaults,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OptionTable extends StatelessWidget {
  const _OptionTable();

  static const _options = [
    ('features', 'Which package features start'),
    ('themeConfig', 'AppThemeConfig applied by ServicesApp'),
    ('apiConfig / cacheConfig', 'Networking and the API cache'),
    ('encryptionKeyProvider', 'Your own encryption key source'),
    ('orientations', 'SystemChrome.setPreferredOrientations'),
    ('systemUiOverlayStyle', 'Status and navigation bar style'),
    ('beforeRun', 'Your async setup, after the package is ready'),
    ('onError', 'Framework, async and setup errors; app still starts'),
    ('app', 'The root widget, usually a ServicesApp'),
  ];

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (final (name, purpose) in _options) KeyValueRow(name, purpose),
    ],
  );
}
