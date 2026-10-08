// Copy of the "Start a new app" code in FEATURES.md and the README. Run it
// with `flutter run -t lib/app_setup_start.dart`. A test keeps the docs and
// this file identical.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:services_rj/services_rj.dart';

Future<void> main() => AppSetup.run(
  features: const AppFeatures(sharedPref: true, theme: true, logger: true),
  themeConfig: const AppThemeConfig(
    seedColor: Colors.indigo,
    initialThemeMode: ThemeMode.system,
    borderRadius: 14,
  ),
  orientations: const [DeviceOrientation.portraitUp],
  onError: (error, stack) {
    // Send to your crash reporter.
  },
  app: const ServicesApp(title: 'My app', home: HomePage()),
);

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Settings')),
    body: const Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ThemeModeSelector(),
          SizedBox(height: 16),
          ThemeColorPicker(),
        ],
      ),
    ),
  );
}
