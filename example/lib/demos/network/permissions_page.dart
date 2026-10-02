import 'package:flutter/material.dart';
import 'package:services_rj/services_rj.dart';

import '../../widgets/demo_widgets.dart';
import 'network_common.dart';

/// Lists every `AppPermission` with its live status and the full manager API.
class PermissionsPage extends StatelessWidget {
  /// Creates the page.
  const PermissionsPage({super.key});

  @override
  Widget build(BuildContext context) => const FeatureGate(
    title: 'Permissions',
    features: [AppFeature.permissions],
    builder: _build,
  );

  static Widget _build(BuildContext context) => const _PermissionsBody();
}

/// Colour and label for a status chip.
Color statusColor(AppPermissionStatus s) {
  if (s.isUsable) return Colors.green;
  if (s.canRequest) return Colors.orange;
  if (s.needsSettings) return Colors.red;
  return Colors.grey;
}

class _PermissionsBody extends StatefulWidget {
  const _PermissionsBody();

  @override
  State<_PermissionsBody> createState() => _PermissionsBodyState();
}

class _PermissionsBodyState extends State<_PermissionsBody>
    with WidgetsBindingObserver {
  final AppPermissionManager _manager = AppPermissionManager.instance;
  final EventLog _log = EventLog();
  final Map<AppPermission, AppPermissionStatus> _status = {};
  final Set<AppPermission> _selected = {};
  String _query = '';
  bool _checking = false;

  AppPermission _target = AppPermission.camera;
  AppPermissionStatus _a = AppPermissionStatus.granted;
  AppPermissionStatus _b = AppPermissionStatus.denied;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkAll();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _log.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _log.add('app resumed: re-checking every permission');
      _checkAll();
    }
  }

  Future<void> _guard(Future<void> Function() body) async {
    try {
      await body();
    } on StateError catch (e) {
      if (mounted) _log.add('StateError: ${e.message}');
    }
  }

  Future<void> _checkAll() => _guard(() async {
    if (_checking) return;
    setState(() => _checking = true);
    try {
      final result = await _manager.checkAll(AppPermission.values);
      if (!mounted) return;
      setState(() => _status.addAll(result));
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  });

  Future<void> _checkOne(AppPermission p) => _guard(() async {
    final s = await _manager.check(p);
    if (!mounted) return;
    setState(() => _status[p] = s);
    _log.add('check(${p.name}) -> ${s.name}');
  });

  Future<void> _requestOne(AppPermission p) => _guard(() async {
    final s = await _manager.request(p);
    if (!mounted) return;
    setState(() => _status[p] = s);
    _log.add('request(${p.name}) -> ${s.name}');
  });

  Future<void> _requestSelected() => _guard(() async {
    if (_selected.isEmpty) {
      _log.add('requestAll: select at least one permission first');
      return;
    }
    final result = await _manager.requestAll(_selected);
    if (!mounted) return;
    setState(() => _status.addAll(result));
    _log.add(
      'requestAll -> ${result.entries.map((e) => '${e.key.name}: ${e.value.name}').join(', ')}',
    );
  });

  Future<void> _ensure(AppPermission p, PermissionPrompts prompts) =>
      _guard(() async {
        final s = await _manager.ensure(p, prompts: prompts);
        if (!mounted) return;
        setState(() => _status[p] = s);
        _log.add('ensure(${p.name}) -> ${s.name}, isUsable: ${s.isUsable}');
      });

  /// Dialogs written for this app instead of `PermissionPrompts.material`.
  PermissionPrompts _customPrompts() => PermissionPrompts(
    onRationale: (p) async {
      if (!mounted) return false;
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.shield_outlined),
          title: Text('Before we ask: ${p.name}'),
          content: Text(
            'We use this to ${PermissionRegistry.of(p).description.toLowerCase()}. '
            'Nothing leaves your device in this demo.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Skip'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Got it'),
            ),
          ],
        ),
      );
      return ok ?? false;
    },
    onOpenSettings: (p) async {
      if (!mounted) return false;
      final ok = await showModalBottomSheet<bool>(
        context: context,
        builder: (ctx) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${p.name} is blocked',
                  style: Theme.of(ctx).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Only the system settings can turn it on now. Open them, '
                  'flip the switch and come back.',
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Not now'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Open settings'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
      return ok ?? false;
    },
  );

  Future<void> _openSettings() => _guard(() async {
    final opened = await _manager.openSettings();
    if (mounted) _log.add('openSettings -> $opened');
  });

  Future<void> _openSettingsAndWait() => _guard(() async {
    _log.add('openSettingsAndWait(${_target.name}): waiting for you to return');
    final s = await _manager.openSettingsAndWait(_target);
    if (!mounted) return;
    setState(() => _status[_target] = s);
    _log.add('openSettingsAndWait -> ${s.name}');
  });

  Future<void> _isGranted() => _guard(() async {
    final granted = await _manager.isGranted(_target);
    if (mounted) _log.add('isGranted(${_target.name}) -> $granted');
  });

  @override
  Widget build(BuildContext context) {
    final visible = [
      for (final p in AppPermission.values)
        if (p.name.toLowerCase().contains(_query.toLowerCase()) ||
            PermissionRegistry.of(
              p,
            ).description.toLowerCase().contains(_query.toLowerCase()))
          p,
    ];
    return DemoPage(
      title: 'Permissions',
      intro:
          'One AppPermission tag maps to the right native permissions for the '
          'platform and OS version. Statuses refresh when the app returns '
          'from the system settings.',
      actions: [
        IconButton(
          tooltip: 'Check all',
          onPressed: _checkAll,
          icon: const Icon(Icons.refresh),
        ),
      ],
      children: [
        DemoSection(
          title: 'Manager',
          subtitle: 'AppPermissionManager.instance',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              KeyValueTable([
                ('platform', _manager.platform.name),
                ('enabled', '${_manager.enabled}'),
                ('settingsLeaveTimeout', '${_manager.settingsLeaveTimeout}'),
                ('permissions known', '${AppPermission.values.length}'),
              ]),
              if (_manager.platform == PermissionPlatform.other)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'This platform has no runtime permissions, so every tag '
                    'reports notApplicable. Run the app on Android or iOS to '
                    'see real dialogs.',
                  ),
                ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('AppPermissionManager.enabled'),
                subtitle: const Text(
                  'While off, check, request and ensure throw a StateError. '
                  'AppController.setEnabled(AppFeature.permissions, ...) '
                  'flips the same switch.',
                ),
                value: _manager.enabled,
                onChanged: (v) => setState(() => _manager.enabled = v),
              ),
            ],
          ),
        ),
        DemoSection(
          title: 'All permissions',
          subtitle:
              'Tick several and use requestAll. Tap a row for its registry '
              'details and native permissions on this device.',
          code:
              "final status = await AppPermissionManager.instance.check(AppPermission.camera);\nfinal all = await AppPermissionManager.instance.requestAll({\n  AppPermission.camera,\n  AppPermission.microphone,\n});",
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  labelText: 'Search permissions',
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: _checking ? null : _checkAll,
                    icon: const Icon(Icons.fact_check, size: 18),
                    label: const Text('checkAll'),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: _requestSelected,
                    icon: const Icon(Icons.playlist_add_check, size: 18),
                    label: Text('requestAll (${_selected.length})'),
                  ),
                  OutlinedButton(
                    onPressed: () => setState(
                      () => _selected
                        ..clear()
                        ..addAll(visible),
                    ),
                    child: const Text('Select shown'),
                  ),
                  OutlinedButton(
                    onPressed: () => setState(_selected.clear),
                    child: const Text('Clear selection'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (visible.isEmpty) const Text('No permission matches.'),
              for (final p in visible)
                _PermissionTile(
                  permission: p,
                  status: _status[p],
                  selected: _selected.contains(p),
                  onSelected: (v) => setState(() {
                    v ? _selected.add(p) : _selected.remove(p);
                  }),
                  onCheck: () => _checkOne(p),
                  onRequest: () => _requestOne(p),
                  manager: _manager,
                ),
            ],
          ),
        ),
        DemoSection(
          title: 'ensure, settings and isGranted',
          subtitle:
              'ensure runs the whole flow: check, explain, request, and send '
              'the user to settings when only settings can help.',
          code:
              "final status = await AppPermissionManager.instance.ensure(\n  AppPermission.camera,\n  prompts: PermissionPrompts.material(context),\n);\nif (status.isUsable) openCamera();",
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButton<AppPermission>(
                value: _target,
                items: [
                  for (final p in AppPermission.values)
                    DropdownMenuItem(value: p, child: Text(p.name)),
                ],
                onChanged: (v) => setState(() => _target = v!),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton(
                    onPressed: () =>
                        _ensure(_target, PermissionPrompts.material(context)),
                    child: const Text('ensure (Material prompts)'),
                  ),
                  FilledButton.tonal(
                    onPressed: () => _ensure(_target, _customPrompts()),
                    child: const Text('ensure (custom prompts)'),
                  ),
                  OutlinedButton(
                    onPressed: () =>
                        _ensure(_target, const PermissionPrompts()),
                    child: const Text('ensure (no prompts)'),
                  ),
                  OutlinedButton(
                    onPressed: _isGranted,
                    child: const Text('isGranted'),
                  ),
                  OutlinedButton(
                    onPressed: _openSettings,
                    child: const Text('openSettings'),
                  ),
                  OutlinedButton(
                    onPressed: _openSettingsAndWait,
                    child: const Text('openSettingsAndWait'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Do not call request or ensure inside a prompt callback: '
                'requests are queued and the inner call would wait forever.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SubHeading('Log'),
              EventLogView(
                log: _log,
                emptyText: 'Run an action to see what the manager returned.',
              ),
            ],
          ),
        ),
        DemoSection(
          title: 'AppPermissionStatus helpers',
          subtitle:
              'isUsable, needsSettings and canRequest tell the UI what to do.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 20,
                  columns: const [
                    DataColumn(label: Text('Status')),
                    DataColumn(label: Text('isUsable')),
                    DataColumn(label: Text('needsSettings')),
                    DataColumn(label: Text('canRequest')),
                  ],
                  rows: [
                    for (final s in AppPermissionStatus.values)
                      DataRow(
                        cells: [
                          DataCell(Text(s.name)),
                          DataCell(Text('${s.isUsable}')),
                          DataCell(Text('${s.needsSettings}')),
                          DataCell(Text('${s.canRequest}')),
                        ],
                      ),
                  ],
                ),
              ),
              const SubHeading('AppPermissionStatus.combine'),
              Text(
                'Several native permissions behind one tag are combined: the '
                'most blocking status wins.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Wrap(
                spacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  DropdownButton<AppPermissionStatus>(
                    value: _a,
                    items: [
                      for (final s in AppPermissionStatus.values)
                        DropdownMenuItem(value: s, child: Text(s.name)),
                    ],
                    onChanged: (v) => setState(() => _a = v!),
                  ),
                  DropdownButton<AppPermissionStatus>(
                    value: _b,
                    items: [
                      for (final s in AppPermissionStatus.values)
                        DropdownMenuItem(value: s, child: Text(s.name)),
                    ],
                    onChanged: (v) => setState(() => _b = v!),
                  ),
                  Text(
                    '-> ${AppPermissionStatus.combine([_a, _b]).name}',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PermissionTile extends StatelessWidget {
  const _PermissionTile({
    required this.permission,
    required this.status,
    required this.selected,
    required this.onSelected,
    required this.onCheck,
    required this.onRequest,
    required this.manager,
  });

  final AppPermission permission;
  final AppPermissionStatus? status;
  final bool selected;
  final ValueChanged<bool> onSelected;
  final VoidCallback onCheck;
  final VoidCallback onRequest;
  final AppPermissionManager manager;

  @override
  Widget build(BuildContext context) {
    final spec = PermissionRegistry.of(permission);
    final s = status;
    return ExpansionTile(
      key: ValueKey(permission.name),
      tilePadding: EdgeInsets.zero,
      leading: Checkbox(
        value: selected,
        onChanged: (v) => onSelected(v ?? false),
      ),
      title: Text(permission.name),
      subtitle: Text(spec.description),
      trailing: s == null
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Chip(
              label: Text(s.name),
              backgroundColor: statusColor(s).withValues(alpha: 0.18),
              side: BorderSide(color: statusColor(s)),
              visualDensity: VisualDensity.compact,
            ),
      childrenPadding: const EdgeInsets.only(bottom: 12),
      expandedCrossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          children: [
            OutlinedButton(onPressed: onCheck, child: const Text('check')),
            FilledButton.tonal(
              onPressed: onRequest,
              child: const Text('request'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        FutureBuilder<List<Object>>(
          future: manager.nativePermissions(permission),
          builder: (context, snap) => KeyValueTable([
            (
              'native here',
              snap.hasData
                  ? (snap.data!.isEmpty
                        ? 'none (no runtime permission needed)'
                        : snap.data!.join(', '))
                  : '...',
            ),
            ('Android', spec.supportsAndroid ? 'supported' : 'not available'),
            ('iOS', spec.supportsIos ? 'supported' : 'not available'),
            ('sequential', '${spec.sequential}'),
            (
              'AndroidManifest',
              spec.androidManifest.isEmpty
                  ? '-'
                  : spec.androidManifest
                        .map(
                          (e) =>
                              '${e.name.split('.').last}'
                              '${e.maxSdkVersion == null ? '' : ' (max API ${e.maxSdkVersion})'}',
                        )
                        .join('\n'),
            ),
            (
              'Info.plist keys',
              spec.iosPlistKeys.isEmpty ? '-' : spec.iosPlistKeys.join('\n'),
            ),
            (
              'Podfile macros',
              spec.iosPodMacros.isEmpty ? '-' : spec.iosPodMacros.join('\n'),
            ),
            if (spec.notes.isNotEmpty) ('notes', spec.notes.join('\n')),
          ]),
        ),
      ],
    );
  }
}
