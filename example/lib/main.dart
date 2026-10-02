// Demo app for services_rj. The home screen lists every feature of the
// package: the JSON form builder (basics, field gallery, labs), the core
// utilities, networking with caching, and permissions.
import 'package:flutter/material.dart';
import 'package:services_rj/services_rj.dart';

import 'demo_enums.dart';
import 'demos/core_demos.dart';
import 'demos/forms_gallery.dart';
import 'demos/forms_labs.dart';
import 'demos/network_demos.dart';
import 'demos/pluggable_adapters.dart';
import 'form_page.dart';
import 'forms/event_rsvp.dart';
import 'forms/job_application.dart';
import 'forms/styling_lab.dart';
import 'widgets/demo_widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  registerDemoEnums();
  registerDemoAdapters();

  // Every feature is switched on so each demo page is live. A real app
  // enables only what it uses, e.g. `AppFeatures(sharedPref: true)`.
  try {
    await AppController.initialize(
      features: const AppFeatures(
        sharedPref: true,
        theme: true,
        network: true,
        apiCache: true,
        encryption: true,
        connectivity: true,
        logger: true,
        networkLogs: true,
        permissions: true,
      ),
      apiConfig: ApiConfig(
        baseUrl: 'https://jsonplaceholder.typicode.com',
        printLogs: true,
        tokenHeaderKey: 'Authorization',
        onUnauthorized: () async => demoNetworkEvents.add('onUnauthorized'),
        onSessionExpired: () async => demoNetworkEvents.add('onSessionExpired'),
        onUserBanned: (message) async =>
            demoNetworkEvents.add('onUserBanned: $message'),
        onError: (message) => demoNetworkEvents.add('onError: $message'),
      ),
      cacheConfig: const CacheConfig(defaultTtl: Duration(minutes: 2)),
    );
  } catch (e) {
    // Keep the demo usable (forms etc.) if a platform feature is missing.
    AppLogger.error('AppController.initialize failed: $e');
  }
  runApp(const FormsDemoApp());
}

/// Root demo app. Rebuilds when [AppThemeController] changes the theme mode.
class FormsDemoApp extends StatelessWidget {
  /// Creates the demo app.
  const FormsDemoApp({super.key});

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: AppThemeController.instance,
    builder: (context, _) => MaterialApp(
      title: 'services_rj demo',
      debugShowCheckedModeBanner: false,
      themeMode: AppThemeController.instance.themeMode,
      theme: AppThemeManager.lightTheme(
        const AppThemeConfig(seedColor: Colors.teal),
      ),
      darkTheme: AppThemeManager.darkTheme(
        const AppThemeConfig(seedColor: Colors.teal),
      ),
      home: const DemoHome(),
    ),
  );
}

void _open(BuildContext context, Widget page) =>
    Navigator.push(context, MaterialPageRoute<void>(builder: (_) => page));

final List<DemoEntry> _formBasics = [
  DemoEntry(
    icon: Icons.event_available,
    title: 'Meetup RSVP',
    subtitle:
        'Enum segmented tiers, a guest repeater (1–4), suggest-a-talk chips',
    builder: (_) => const FormPage(title: 'Meetup RSVP', json: eventRsvpForm),
  ),
  DemoEntry(
    icon: Icons.edit_calendar,
    title: 'Edit a saved RSVP',
    subtitle:
        'Same form prefilled with two guests — starts clean, reset restores',
    builder: (_) => const FormPage(
      title: 'Edit RSVP',
      json: eventRsvpForm,
      initialData: savedRsvp,
    ),
  ),
  DemoEntry(
    icon: Icons.work_outline,
    title: 'Job application wizard',
    subtitle:
        'Three steps, reorderable work history, grid checkboxes with add-a-tool',
    builder: (_) => const FormPage(
      title: 'Job application',
      json: jobApplicationForm,
      showSubmit: false,
    ),
  ),
  DemoEntry(
    icon: Icons.palette_outlined,
    title: 'Styling lab',
    subtitle: 'Variants, colours, prefix/suffix, text case and FieldOverrides',
    builder: (_) => FormPage(
      title: 'Styling lab',
      json: stylingLabForm,
      fieldOverrides: {
        'priority': FieldOverrides(
          style: const FieldStyleConfig(activeColor: Colors.deepOrange),
          optionBuilder: (context, option, selected) => Text(
            option.label.toUpperCase(),
            style: TextStyle(
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
        'remarks': FieldOverrides(
          wrapper: (context, field, child) => Card(
            child: Padding(padding: const EdgeInsets.all(12), child: child),
          ),
        ),
      },
    ),
  ),
];

/// The home screen sections, in display order.
final List<(String, List<DemoEntry>)> demoSections = [
  ('Forms — examples', _formBasics),
  ('Forms — every field type', galleryDemos),
  ('Forms — feature labs', formLabDemos),
  ('Core — controller, storage, theme, widgets, helpers', coreDemos),
  ('Networking, cache and permissions', networkDemos),
];

/// Lists the demos.
class DemoHome extends StatelessWidget {
  /// Creates the home screen.
  const DemoHome({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('services_rj playground'),
      actions: const [ThemeModeSwitcher(), SizedBox(width: 8)],
    ),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            for (final (heading, entries) in demoSections) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
                child: Text(
                  heading,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              for (final e in entries)
                Card(
                  child: ListTile(
                    leading: Icon(e.icon),
                    title: Text(e.title),
                    subtitle: Text(e.subtitle),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _open(context, Builder(builder: e.builder)),
                  ),
                ),
            ],
          ],
        ),
      ),
    ),
  );
}
