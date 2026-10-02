import 'package:flutter/material.dart';
import 'package:services_rj/services_rj.dart';

import '../../widgets/demo_widgets.dart';

/// Demo of the UI helpers: snackbars, dialogs, responsive checks, context
/// extensions, [PrimaryLoader] and [AppScaffold].
class UiHelpersDemo extends StatefulWidget {
  /// Creates the page.
  const UiHelpersDemo({super.key});

  @override
  State<UiHelpersDemo> createState() => _UiHelpersDemoState();
}

class _UiHelpersDemoState extends State<UiHelpersDemo> {
  int _snackSeconds = 2;

  Future<void> _loading() async {
    final dialog = AppDialogs.showLoading(context);
    await Future<void>.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    Navigator.of(context).pop();
    await dialog;
    if (!mounted) return;
    AppSnackbar.success(context, 'Loading dialog closed after 2 seconds');
  }

  @override
  Widget build(BuildContext context) {
    final size = context.screenSize;
    return DemoPage(
      title: 'UI helpers',
      intro:
          'Small utilities every screen ends up needing. Resize the window '
          'to watch the responsive flags change.',
      children: [
        DemoSection(
          title: 'AppSnackbar',
          subtitle:
              'show() takes a colour and a duration; success() and '
              'error() are shortcuts.',
          code:
              'AppSnackbar.success(context, "Saved");\n'
              'AppSnackbar.show(context, message: "Hi", '
              'duration: Duration(seconds: 5));',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('Duration: $_snackSeconds s'),
                  Expanded(
                    child: Slider(
                      value: _snackSeconds.toDouble(),
                      min: 1,
                      max: 8,
                      divisions: 7,
                      onChanged: (v) =>
                          setState(() => _snackSeconds = v.round()),
                    ),
                  ),
                ],
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: () => AppSnackbar.show(
                      context,
                      message: 'Draft saved to this device',
                      duration: Duration(seconds: _snackSeconds),
                    ),
                    child: const Text('show'),
                  ),
                  OutlinedButton(
                    onPressed: () => AppSnackbar.show(
                      context,
                      message: 'Custom colour and duration',
                      backgroundColor: Colors.indigo,
                      duration: Duration(seconds: _snackSeconds),
                    ),
                    child: const Text('show (colour)'),
                  ),
                  FilledButton(
                    onPressed: () =>
                        AppSnackbar.success(context, 'Profile updated'),
                    child: const Text('success'),
                  ),
                  FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: Colors.red),
                    onPressed: () => AppSnackbar.error(
                      context,
                      'Could not reach the server',
                    ),
                    child: const Text('error'),
                  ),
                ],
              ),
            ],
          ),
        ),
        DemoSection(
          title: 'AppDialogs',
          code:
              'AppDialogs.showLoading(context);\n'
              '// ... later\n'
              'Navigator.pop(context);\n'
              'AppDialogs.showMessage(context, title: "Done", message: "...");',
          subtitle:
              'showLoading is not dismissible; close it yourself with '
              'Navigator.pop. This demo closes it after 2 seconds.',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton(
                onPressed: _loading,
                child: const Text('showLoading'),
              ),
              OutlinedButton(
                onPressed: () => AppDialogs.showMessage(
                  context,
                  title: 'Backup complete',
                  message: '128 items were copied to your account.',
                ),
                child: const Text('showMessage'),
              ),
            ],
          ),
        ),
        DemoSection(
          title: 'AppResponsive',
          subtitle: 'Mobile under 600, tablet 600-1023, desktop from 1024.',
          code: 'if (AppResponsive.isDesktop(context)) { ... }',
          child: Wrap(
            spacing: 8,
            children: [
              Chip(label: Text('isMobile ${AppResponsive.isMobile(context)}')),
              Chip(label: Text('isTablet ${AppResponsive.isTablet(context)}')),
              Chip(
                label: Text('isDesktop ${AppResponsive.isDesktop(context)}'),
              ),
            ],
          ),
        ),
        DemoSection(
          title: 'AppContextExtensions',
          code:
              'context.theme  context.colors  context.textTheme\n'
              'context.isDarkMode  context.screenSize',
          child: Column(
            children: [
              _row('isDarkMode', '${context.isDarkMode}'),
              _row(
                'screenSize',
                '${size.width.round()} x ${size.height.round()}',
              ),
              _row('screenWidth', context.screenWidth.toStringAsFixed(1)),
              _row('screenHeight', context.screenHeight.toStringAsFixed(1)),
              _row(
                'colors.primary',
                '#${context.colors.primary.toARGB32().toRadixString(16)}',
              ),
              _row(
                'textTheme.titleMedium',
                '${context.textTheme.titleMedium?.fontSize} sp',
              ),
              _row('theme.useMaterial3', '${context.theme.useMaterial3}'),
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    color: context.colors.primary,
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 28,
                    height: 28,
                    color: context.colors.secondary,
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 28,
                    height: 28,
                    color: context.colors.tertiary,
                  ),
                ],
              ),
            ],
          ),
        ),
        const DemoSection(
          title: 'PrimaryLoader',
          code: 'const PrimaryLoader(size: 48)',
          child: Row(
            children: [
              PrimaryLoader(size: 16),
              SizedBox(width: 20),
              PrimaryLoader(),
              SizedBox(width: 20),
              PrimaryLoader(size: 48),
              SizedBox(width: 20),
              PrimaryLoader(size: 72),
            ],
          ),
        ),
        DemoSection(
          title: 'AppScaffold',
          subtitle:
              'A Scaffold whose body is already inside a SafeArea, with '
              'optional app bar and floating action button.',
          code:
              'AppScaffold(\n'
              '  appBar: AppBar(title: Text("Inbox")),\n'
              '  floatingActionButton: FloatingActionButton(...),\n'
              '  body: ListView(...),\n'
              ')',
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const _ScaffoldPage()),
            ),
            child: const Text('Open an AppScaffold page'),
          ),
        ),
      ],
    );
  }

  Widget _row(String k, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      children: [
        SizedBox(width: 170, child: Text(k)),
        Expanded(
          child: Text(
            v,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12.5),
          ),
        ),
      ],
    ),
  );
}

class _ScaffoldPage extends StatefulWidget {
  const _ScaffoldPage();

  @override
  State<_ScaffoldPage> createState() => _ScaffoldPageState();
}

class _ScaffoldPageState extends State<_ScaffoldPage> {
  final List<String> _notes = ['Pick up the parcel', 'Renew passport'];

  @override
  Widget build(BuildContext context) => AppScaffold(
    appBar: AppBar(title: const Text('Reminders')),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: () =>
          setState(() => _notes.add('Reminder ${_notes.length + 1}')),
      icon: const Icon(Icons.add),
      label: const Text('Add'),
    ),
    body: ListView(
      children: [
        for (final n in _notes)
          ListTile(
            leading: const Icon(Icons.notifications_none),
            title: Text(n),
          ),
      ],
    ),
  );
}
