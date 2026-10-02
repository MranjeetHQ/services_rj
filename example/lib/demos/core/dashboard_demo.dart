import 'package:flutter/material.dart';
import 'package:services_rj/services_rj.dart';

import '../../widgets/demo_widgets.dart';
import 'core_common.dart';

/// Live view of [AppController]: features, readiness, accessors, lifecycle.
class AppControllerDemo extends StatefulWidget {
  /// Creates the page.
  const AppControllerDemo({super.key});

  @override
  State<AppControllerDemo> createState() => _AppControllerDemoState();
}

class _AppControllerDemoState extends State<AppControllerDemo> {
  final _log = EventLog();
  final Set<AppFeature> _picked = {AppFeature.sharedPref, AppFeature.theme};

  AppController get _c => AppController.instance;

  @override
  void dispose() {
    _log.dispose();
    super.dispose();
  }

  Future<void> _toggle(AppFeature feature, bool value) async {
    try {
      await _c.setEnabled(feature, value);
      _log.add('setEnabled(${feature.name}, $value) ok');
    } on StateError catch (e) {
      _log.add('StateError: ${e.message}');
    } catch (e) {
      _log.add('${feature.name} failed: $e');
    }
  }

  Future<void> _run(
    String name,
    Future<void> Function() action, {
    required String title,
    required String message,
    bool destructive = false,
    String confirmLabel = 'Confirm',
  }) async {
    final ok = await confirmAction(
      context,
      title: title,
      message: message,
      destructive: destructive,
      confirmLabel: confirmLabel,
    );
    if (!ok || !mounted) return;
    try {
      await action();
      _log.add('$name finished');
    } catch (e) {
      _log.add('$name failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _c,
    builder: (context, _) => DemoPage(
      title: 'AppController',
      intro:
          'One switchboard for every feature. This page listens to the '
          'controller, so it rebuilds when a feature is switched.',
      children: [
        if (!_c.isInitialized)
          const FeatureOffNotice(
            feature: 'AppController',
            detail: 'initialize() has not run, so nothing below is ready.',
          ),
        _featuresSection(),
        _accessorsSection(),
        _helpersSection(),
        _lifecycleSection(),
        DemoSection(
          title: 'Event log',
          child: EventLogView(log: _log, emptyText: 'Toggle a feature.'),
        ),
      ],
    ),
  );

  Widget _featuresSection() => DemoSection(
    title: 'Features',
    subtitle:
        'Enabled = asked for in AppFeatures. Ready = started successfully. '
        'Only ${runtimeToggleableFeatures.map((f) => f.name).join(', ')} '
        'can be switched at runtime.',
    code: 'await AppController.instance.setEnabled(AppFeature.logger, false);',
    child: Column(
      children: [
        for (final f in AppFeature.values)
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(f.name),
            subtitle: Text(
              '${_c.isEnabled(f) ? 'enabled' : 'disabled'} - '
              '${_c.isReady(f) ? 'ready' : 'not ready'}'
              '${runtimeToggleableFeatures.contains(f) ? '' : ' - fixed at initialize()'}',
            ),
            value: _c.isEnabled(f),
            onChanged: runtimeToggleableFeatures.contains(f)
                ? (v) => _toggle(f, v)
                : null,
          ),
        const SizedBox(height: 8),
        KeyValueRow('features', _c.features.toString()),
      ],
    ),
  );

  Widget _accessorsSection() {
    final accessors = <String, Object Function()>{
      'api': () => _c.api,
      'dio': () => _c.dio,
      'cache': () => _c.cache,
      'theme': () => _c.theme,
      'encryption': () => _c.encryption,
      'permissions': () => _c.permissions,
      'auth': () => _c.auth,
    };
    return DemoSection(
      title: 'Accessors',
      subtitle:
          'Each getter throws a StateError until its feature is ready. '
          'Green means the call returned an object.',
      code: 'final dio = AppController.instance.dio;',
      child: Wrap(
        spacing: 8,
        children: [
          for (final e in accessors.entries)
            StatusPill(label: e.key, ok: _available(e.value)),
        ],
      ),
    );
  }

  bool _available(Object Function() getter) {
    try {
      getter();
      return true;
    } on StateError {
      return false;
    }
  }

  Widget _helpersSection() {
    final only = AppFeatures.only(_picked);
    final enabledNames = only
        .toMap()
        .entries
        .where((e) => e.value)
        .map((e) => e.key.name)
        .toList();
    return DemoSection(
      title: 'AppFeatures helpers',
      subtitle: 'Pick features, then see what each helper computes.',
      code:
          'AppFeatures.none()\n'
          'AppFeatures.only({AppFeature.theme})\n'
          'features.copyWith(logger: true)\n'
          'features.withFeature(AppFeature.network, false)\n'
          'features.toMap()',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            children: [
              for (final f in AppFeature.values)
                FilterChip(
                  label: Text(f.name),
                  selected: _picked.contains(f),
                  onSelected: (on) =>
                      setState(() => on ? _picked.add(f) : _picked.remove(f)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          KeyValueRow(
            'none()',
            '${const AppFeatures.none().toMap().values.where((v) => v).length} enabled',
          ),
          KeyValueRow('only(picked)', enabledNames.join(', ').ifEmpty('-')),
          KeyValueRow(
            'copyWith(logger: true)',
            'logger -> ${only.copyWith(logger: true).logger}',
          ),
          KeyValueRow(
            'withFeature(network, !)',
            'network -> ${only.withFeature(AppFeature.network, !only.network).network}',
          ),
          KeyValueRow(
            'toMap()',
            only
                .toMap()
                .entries
                .map((e) => '${e.key.name}=${e.value}')
                .join('\n'),
          ),
          KeyValueRow('live features', _c.features.toString()),
        ],
      ),
    );
  }

  Widget _lifecycleSection() => DemoSection(
    title: 'Data lifecycle',
    subtitle:
        'logout() clears the auth session (or the API cache when sharedPref '
        'is off). wipeAllData() clears cache and preferences.',
    code:
        'await AppController.instance.logout();\n'
        'await AppController.instance.wipeAllData(destroyEncryptionKey: false);',
    child: Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        OutlinedButton.icon(
          icon: const Icon(Icons.logout),
          label: const Text('logout()'),
          onPressed: () => _run(
            'logout()',
            _c.logout,
            title: 'Log out?',
            message: 'Stored auth tokens and cached responses are removed.',
            confirmLabel: 'Log out',
          ),
        ),
        OutlinedButton.icon(
          icon: const Icon(Icons.delete_sweep_outlined),
          label: const Text('wipeAllData()'),
          onPressed: () => _run(
            'wipeAllData()',
            () => _c.wipeAllData(),
            title: 'Wipe all data?',
            message:
                'Clears the API cache and every stored preference, '
                'including the saved theme mode.',
            confirmLabel: 'Wipe',
            destructive: true,
          ),
        ),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
          ),
          icon: const Icon(Icons.key_off),
          label: const Text('wipe + destroy key'),
          onPressed: () async {
            final first = await confirmAction(
              context,
              title: 'Destroy the encryption key?',
              message:
                  'Everything encrypted with the current key becomes '
                  'permanently unreadable. A new key is created afterwards.',
              confirmLabel: 'Continue',
              destructive: true,
            );
            if (!first || !mounted) return;
            await _run(
              'wipeAllData(destroyEncryptionKey: true)',
              () => _c.wipeAllData(destroyEncryptionKey: true),
              title: 'Last warning',
              message:
                  'This cannot be undone. All stored data and the '
                  'encryption key will be deleted now.',
              confirmLabel: 'Destroy everything',
              destructive: true,
            );
          },
        ),
      ],
    ),
  );
}

extension on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}
