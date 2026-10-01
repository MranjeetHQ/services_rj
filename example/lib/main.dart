// Demo app for the services_rj dynamic form builder: an event RSVP with an
// extendable guest list, a multi-step job application, and a styling lab.
import 'package:flutter/material.dart';
import 'package:services_rj/services_rj.dart';

import 'demo_enums.dart';
import 'form_page.dart';
import 'forms/event_rsvp.dart';
import 'forms/job_application.dart';
import 'forms/styling_lab.dart';

void main() {
  registerDemoEnums();
  runApp(const FormsDemoApp());
}

/// Root demo app.
class FormsDemoApp extends StatelessWidget {
  /// Creates the demo app.
  const FormsDemoApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'services_rj forms',
    debugShowCheckedModeBanner: false,
    theme: AppThemeManager.lightTheme(
      const AppThemeConfig(seedColor: Colors.teal),
    ),
    darkTheme: AppThemeManager.darkTheme(
      const AppThemeConfig(seedColor: Colors.teal),
    ),
    home: const DemoHome(),
  );
}

/// Lists the demos.
class DemoHome extends StatelessWidget {
  /// Creates the home screen.
  const DemoHome({super.key});

  void _open(BuildContext context, Widget page) =>
      Navigator.push(context, MaterialPageRoute<void>(builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    final demos = <(IconData, String, String, Widget)>[
      (
        Icons.event_available,
        'Meetup RSVP',
        'Enum segmented tiers, a guest repeater (1–4), suggest-a-talk chips',
        const FormPage(title: 'Meetup RSVP', json: eventRsvpForm),
      ),
      (
        Icons.edit_calendar,
        'Edit a saved RSVP',
        'Same form prefilled with two guests — starts clean, reset restores',
        const FormPage(
          title: 'Edit RSVP',
          json: eventRsvpForm,
          initialData: savedRsvp,
        ),
      ),
      (
        Icons.work_outline,
        'Job application wizard',
        'Three steps, reorderable work history, grid checkboxes with add-a-tool',
        const FormPage(
          title: 'Job application',
          json: jobApplicationForm,
          showSubmit: false,
        ),
      ),
      (
        Icons.palette_outlined,
        'Styling lab',
        'Variants, colours, prefix/suffix, text case and FieldOverrides',
        FormPage(
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
    return Scaffold(
      appBar: AppBar(title: const Text('JSON forms playground')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final (icon, title, subtitle, page) in demos)
            Card(
              child: ListTile(
                leading: Icon(icon),
                title: Text(title),
                subtitle: Text(subtitle),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _open(context, page),
              ),
            ),
        ],
      ),
    );
  }
}
