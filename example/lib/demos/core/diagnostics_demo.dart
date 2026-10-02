import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:services_rj/services_rj.dart';

import '../../widgets/demo_widgets.dart';
import 'core_common.dart';

/// Demo of [AppLogger] and [AppConnectivity].
class DiagnosticsDemo extends StatefulWidget {
  /// Creates the page.
  const DiagnosticsDemo({super.key});

  @override
  State<DiagnosticsDemo> createState() => _DiagnosticsDemoState();
}

class _DiagnosticsDemoState extends State<DiagnosticsDemo> {
  final _sent = EventLog();
  final _events = EventLog();
  final _message = TextEditingController(text: 'Checkout started');
  StreamSubscription<dynamic>? _sub;
  bool? _lastCheck;

  @override
  void initState() {
    super.initState();
    _listen();
  }

  /// Subscribes only when the connectivity plugin is running; without it the
  /// platform channel does not exist (tests, unsupported platforms).
  void _listen() {
    _sub?.cancel();
    _sub = null;
    if (!AppController.instance.isReady(AppFeature.connectivity)) return;
    _sub = AppConnectivity.stream.listen((results) {
      _events.add('stream: ${results.map((r) => r.name).join(', ')}');
      if (mounted) setState(() {});
    }, onError: (Object e) => _events.add('stream error: $e'));
  }

  @override
  void dispose() {
    _sub?.cancel();
    _message.dispose();
    _sent.dispose();
    _events.dispose();
    super.dispose();
  }

  void _logLine(String level, void Function(String) fn) {
    fn(_message.text);
    _sent.add(
      '$level: "${_message.text}"'
      '${AppLogger.enabled && kDebugMode ? '' : '  (suppressed)'}',
    );
  }

  Future<void> _guard(String name, Future<void> Function() body) async {
    try {
      await body();
    } catch (e) {
      _events.add('$name failed: $e');
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final connectivityReady = AppController.instance.isReady(
      AppFeature.connectivity,
    );
    return DemoPage(
      title: 'Logger and connectivity',
      children: [
        DemoSection(
          title: 'AppLogger',
          subtitle:
              'Writes to dart:developer log (visible in the IDE console and '
              'DevTools Logging). Silent in profile and release builds.',
          code:
              'AppLogger.info("hello");\n'
              'AppLogger.warning("careful");\n'
              'AppLogger.error("boom", stackTrace: st);\n'
              'AppLogger.enabled = false;',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('AppLogger.enabled'),
                subtitle: Text('Debug build: $kDebugMode'),
                value: AppLogger.enabled,
                onChanged: (v) => setState(() => AppLogger.enabled = v),
              ),
              TextField(
                controller: _message,
                decoration: const InputDecoration(labelText: 'Message'),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: () => _logLine('info', AppLogger.info),
                    child: const Text('info'),
                  ),
                  OutlinedButton(
                    onPressed: () => _logLine('warning', AppLogger.warning),
                    child: const Text('warning'),
                  ),
                  OutlinedButton(
                    onPressed: () => _logLine(
                      'error',
                      (m) => AppLogger.error(m, stackTrace: StackTrace.current),
                    ),
                    child: const Text('error'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              EventLogView(
                log: _sent,
                emptyText: 'Sent log lines appear here.',
              ),
            ],
          ),
        ),
        DemoSection(
          title: 'AppConnectivity',
          subtitle:
              'Tracks reachability of any network. It reports a network '
              'interface, not proof that a server is reachable.',
          code:
              'final online = await AppConnectivity.hasInternet();\n'
              'AppConnectivity.stream.listen((results) { ... });\n'
              'AppConnectivity.enabled = false;',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!connectivityReady)
                const FeatureOffNotice(
                  feature: 'connectivity',
                  detail: 'Live updates are disabled.',
                ),
              Wrap(
                spacing: 8,
                children: [
                  StatusPill(
                    label: 'isOnline: ${AppConnectivity.isOnline}',
                    ok: AppConnectivity.isOnline ?? false,
                  ),
                  StatusPill(
                    label: 'isKnownOffline: ${AppConnectivity.isKnownOffline}',
                    ok: !AppConnectivity.isKnownOffline,
                  ),
                  StatusPill(
                    label: 'enabled: ${AppConnectivity.enabled}',
                    ok: AppConnectivity.enabled,
                  ),
                ],
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('AppConnectivity.enabled'),
                subtitle: const Text(
                  'Off stops monitoring, clears the cached state and '
                  'makes hasInternet() return true.',
                ),
                value: AppConnectivity.enabled,
                onChanged: connectivityReady
                    ? (v) => setState(() {
                        AppConnectivity.enabled = v;
                        _listen();
                      })
                    : null,
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton(
                    onPressed: () => _guard('hasInternet', () async {
                      _lastCheck = await AppConnectivity.hasInternet();
                      _events.add('hasInternet() -> $_lastCheck');
                    }),
                    child: const Text('hasInternet()'),
                  ),
                  OutlinedButton(
                    onPressed: () => _guard('startMonitoring', () async {
                      await AppConnectivity.startMonitoring();
                      _events.add('startMonitoring() done');
                    }),
                    child: const Text('startMonitoring'),
                  ),
                  OutlinedButton(
                    onPressed: () => _guard('stopMonitoring', () async {
                      await AppConnectivity.stopMonitoring();
                      _events.add('stopMonitoring() done');
                    }),
                    child: const Text('stopMonitoring'),
                  ),
                ],
              ),
              if (_lastCheck != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text('Last hasInternet(): $_lastCheck'),
                ),
              const SizedBox(height: 12),
              EventLogView(
                log: _events,
                emptyText: 'Switch Wi-Fi off and on to see stream events.',
              ),
            ],
          ),
        ),
      ],
    );
  }
}
