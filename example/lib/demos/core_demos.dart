import 'package:flutter/material.dart';

import '../widgets/demo_widgets.dart';
import 'core/app_setup_demo.dart';
import 'core/buttons_demo.dart';
import 'core/dashboard_demo.dart';
import 'core/diagnostics_demo.dart';
import 'core/encryption_demo.dart';
import 'core/extensions_demo.dart';
import 'core/form_helpers_demo.dart';
import 'core/storage_demo.dart';
import 'core/theme_demo.dart';
import 'core/ui_helpers_demo.dart';

/// Home-screen entries for the core (non-networking, non-form) features.
final List<DemoEntry> coreDemos = [
  DemoEntry(
    icon: Icons.rocket_launch_outlined,
    title: 'App setup',
    subtitle: 'AppSetup.run, ServicesApp, AppKeys and a theme settings screen.',
    builder: (_) => const AppSetupDemo(),
  ),
  DemoEntry(
    icon: Icons.tune,
    title: 'AppController',
    subtitle: 'Features, readiness, accessors, logout and wipe.',
    builder: (_) => const AppControllerDemo(),
  ),
  DemoEntry(
    icon: Icons.storage_outlined,
    title: 'Storage',
    subtitle: 'SharedPrefManager: typed values, keys, migration.',
    builder: (_) => const StorageDemo(),
  ),
  DemoEntry(
    icon: Icons.lock_outline,
    title: 'Encryption',
    subtitle: 'AppEncryption text and bytes API, key lifecycle.',
    builder: (_) => const EncryptionDemo(),
  ),
  DemoEntry(
    icon: Icons.palette_outlined,
    title: 'Theme',
    subtitle:
        'Every AppThemeConfig option, previews, apply to app, mode and accent.',
    builder: (_) => const ThemeDemo(),
  ),
  DemoEntry(
    icon: Icons.smart_button_outlined,
    title: 'Buttons',
    subtitle: 'Every AppButtons type, factory and prop.',
    builder: (_) => const ButtonsDemo(),
  ),
  DemoEntry(
    icon: Icons.widgets_outlined,
    title: 'UI helpers',
    subtitle: 'Snackbar, dialogs, responsive, extensions, scaffold.',
    builder: (_) => const UiHelpersDemo(),
  ),
  DemoEntry(
    icon: Icons.text_fields,
    title: 'Extensions',
    subtitle: 'String, double and number extensions with live input.',
    builder: (_) => const ExtensionsDemo(),
  ),
  DemoEntry(
    icon: Icons.rule,
    title: 'Validators and debouncer',
    subtitle: 'AppValidators in a form, AppDebouncer in a search box.',
    builder: (_) => const FormHelpersDemo(),
  ),
  DemoEntry(
    icon: Icons.wifi_find_outlined,
    title: 'Logger and connectivity',
    subtitle: 'AppLogger levels and live AppConnectivity.',
    builder: (_) => const DiagnosticsDemo(),
  ),
];
