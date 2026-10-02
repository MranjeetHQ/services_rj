import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:services_rj/services_rj.dart';

import '../../widgets/demo_widgets.dart';
import 'core_common.dart';

/// App specific preference keys.
///
/// [SharedPrefKeys] is an `abstract final class`, so it cannot be extended
/// from another library. Define your own holder next to it instead.
abstract final class DemoPrefKeys {
  /// Last tab the user opened (int).
  static const String lastTab = 'DEMO_LAST_TAB';

  /// Favourite tags (List of String).
  static const String tags = 'DEMO_TAGS';

  /// Layout preferences (Map).
  static const String layout = 'DEMO_LAYOUT';

  /// Rating given to the demo (double).
  static const String rating = 'DEMO_RATING';
}

enum _ValueKind { string, integer, decimal, boolean, stringList, map }

extension on _ValueKind {
  String get label => switch (this) {
    _ValueKind.string => 'String',
    _ValueKind.integer => 'int',
    _ValueKind.decimal => 'double',
    _ValueKind.boolean => 'bool',
    _ValueKind.stringList => 'List<String>',
    _ValueKind.map => 'Map<String, dynamic>',
  };

  String get sample => switch (this) {
    _ValueKind.string => 'Asha Verma',
    _ValueKind.integer => '42',
    _ValueKind.decimal => '4.5',
    _ValueKind.boolean => 'true',
    _ValueKind.stringList => 'travel, food, music',
    _ValueKind.map => '{"compact": true, "columns": 2}',
  };

  /// Parses user text into the Dart type this kind stores.
  Object parse(String text) => switch (this) {
    _ValueKind.string => text,
    _ValueKind.integer => int.parse(text.trim()),
    _ValueKind.decimal => double.parse(text.trim()),
    _ValueKind.boolean => text.trim().toLowerCase() == 'true',
    _ValueKind.stringList =>
      text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
    _ValueKind.map => Map<String, dynamic>.from(jsonDecode(text) as Map),
  };

  /// Reads the value back with the matching generic type argument.
  Object? read(String key) => switch (this) {
    _ValueKind.string => SharedPrefManager.getData<String>(key),
    _ValueKind.integer => SharedPrefManager.getData<int>(key),
    _ValueKind.decimal => SharedPrefManager.getData<double>(key),
    _ValueKind.boolean => SharedPrefManager.getData<bool>(key),
    _ValueKind.stringList => SharedPrefManager.getData<List<String>>(key),
    _ValueKind.map => SharedPrefManager.getData<Map<String, dynamic>>(key),
  };
}

/// Demo of [SharedPrefManager]: typed save/read, keys, migration, wipe.
class StorageDemo extends StatefulWidget {
  /// Creates the page.
  const StorageDemo({super.key});

  @override
  State<StorageDemo> createState() => _StorageDemoState();
}

class _StorageDemoState extends State<StorageDemo> {
  final _log = EventLog();
  final _key = TextEditingController(text: 'demo_value');
  final _value = TextEditingController(text: _ValueKind.string.sample);
  _ValueKind _kind = _ValueKind.string;

  @override
  void dispose() {
    _log.dispose();
    _key.dispose();
    _value.dispose();
    super.dispose();
  }

  Future<void> _guard(String name, Future<void> Function() body) async {
    try {
      await body();
    } catch (e) {
      _log.add('$name failed: $e');
    }
    if (mounted) setState(() {});
  }

  Future<void> _save() => _guard('saveData', () async {
    final parsed = _kind.parse(_value.text);
    final ok = await SharedPrefManager.saveData(_key.text, parsed);
    _log.add(
      'saveData("${_key.text}", ${parsed.runtimeType}) -> $ok'
      '${AppEncryption.instance.isActive ? ' (encrypted)' : ' (plain)'}',
    );
  });

  Future<void> _read() => _guard('getData', () async {
    final v = _kind.read(_key.text);
    _log.add(
      'getData<${_kind.label}>("${_key.text}") -> $v'
      '${v == null ? '' : ' (${v.runtimeType})'}',
    );
  });

  Future<void> _seed() => _guard('seed', () async {
    await SharedPrefManager.saveData(SharedPrefKeys.fullName, 'Asha Verma');
    await SharedPrefManager.saveData(SharedPrefKeys.isDemoUser, true);
    await SharedPrefManager.saveData(DemoPrefKeys.lastTab, 3);
    await SharedPrefManager.saveData(DemoPrefKeys.rating, 4.5);
    await SharedPrefManager.saveData(DemoPrefKeys.tags, ['travel', 'food']);
    await SharedPrefManager.saveData(DemoPrefKeys.layout, {
      'compact': true,
      'columns': 2,
    });
    _log.add('Saved six values under SharedPrefKeys and DemoPrefKeys.');
  });

  Future<void> _savePlain() => _guard('plain save', () async {
    final crypto = AppEncryption.instance;
    final was = crypto.enabled;
    crypto.enabled = false;
    try {
      await SharedPrefManager.saveData(
        'legacy_note',
        'written before encryption',
      );
      await SharedPrefManager.saveData('legacy_count', 7);
    } finally {
      crypto.enabled = was;
    }
    _log.add('Saved legacy_note and legacy_count as plain text.');
  });

  Future<void> _migrate() => _guard('migrateToEncrypted', () async {
    final n = await SharedPrefManager.migrateToEncrypted();
    _log.add('migrateToEncrypted() -> $n value(s) encrypted');
  });

  Future<void> _clearAll() async {
    final ok = await confirmAction(
      context,
      title: 'Clear all preferences?',
      message:
          'Removes every stored key, including the saved theme mode and '
          'any auth token.',
      confirmLabel: 'Clear',
      destructive: true,
    );
    if (!ok || !mounted) return;
    await _guard('clearAllSharedPrefData', () async {
      final done = await SharedPrefManager.clearAllSharedPrefData();
      _log.add('clearAllSharedPrefData() -> $done');
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!SharedPrefManager.isInitialized) {
      return const DemoPage(
        title: 'Storage',
        children: [FeatureOffNotice(feature: 'sharedPref')],
      );
    }
    final crypto = AppEncryption.instance;
    return DemoPage(
      title: 'Storage',
      intro:
          'SharedPrefManager stores typed values. When encryption is active '
          'every value is encrypted at rest and the original type is '
          'restored on read.',
      children: [
        DemoSection(
          title: 'Encryption at rest',
          child: Wrap(
            spacing: 8,
            children: [
              StatusPill(label: 'key loaded', ok: crypto.isInitialized),
              StatusPill(label: 'active', ok: crypto.isActive),
            ],
          ),
        ),
        DemoSection(
          title: 'Save and read',
          subtitle: 'Supported: String, int, double, bool, List<String>, Map.',
          code:
              "await SharedPrefManager.saveData('age', 42);\n"
              "final age = SharedPrefManager.getData<int>('age');",
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<_ValueKind>(
                initialValue: _kind,
                decoration: const InputDecoration(labelText: 'Type'),
                items: [
                  for (final k in _ValueKind.values)
                    DropdownMenuItem(value: k, child: Text(k.label)),
                ],
                onChanged: (k) => setState(() {
                  _kind = k!;
                  _value.text = k.sample;
                }),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _key,
                decoration: const InputDecoration(labelText: 'Key'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _value,
                decoration: const InputDecoration(labelText: 'Value'),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton(onPressed: _save, child: const Text('saveData')),
                  OutlinedButton(
                    onPressed: _read,
                    child: const Text('getData'),
                  ),
                  OutlinedButton(
                    onPressed: () => _guard('containsKey', () async {
                      _log.add(
                        'containsKey("${_key.text}") -> '
                        '${SharedPrefManager.containsKey(_key.text)}',
                      );
                    }),
                    child: const Text('containsKey'),
                  ),
                  OutlinedButton(
                    onPressed: () => _guard('delete', () async {
                      final ok = await SharedPrefManager.delete(_key.text);
                      _log.add('delete("${_key.text}") -> $ok');
                    }),
                    child: const Text('delete'),
                  ),
                  OutlinedButton(
                    onPressed: () => _guard('reload', () async {
                      await SharedPrefManager.reload();
                      _log.add('reload() done');
                    }),
                    child: const Text('reload'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              EventLogView(log: _log, emptyText: 'Results appear here.'),
            ],
          ),
        ),
        DemoSection(
          title: 'Keys',
          subtitle:
              'SharedPrefKeys ships common names. Add your own in a '
              'separate class (SharedPrefKeys is final).',
          code:
              'abstract final class DemoPrefKeys {\n'
              "  static const String lastTab = 'DEMO_LAST_TAB';\n"
              '}',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const KeyValueRow('userToken', SharedPrefKeys.userToken),
              const KeyValueRow('refreshToken', SharedPrefKeys.refreshToken),
              const KeyValueRow('fullName', SharedPrefKeys.fullName),
              const KeyValueRow('isDemoUser', SharedPrefKeys.isDemoUser),
              const KeyValueRow('themeMode', SharedPrefKeys.themeMode),
              const KeyValueRow('DemoPrefKeys.lastTab', DemoPrefKeys.lastTab),
              const KeyValueRow('DemoPrefKeys.tags', DemoPrefKeys.tags),
              const KeyValueRow('DemoPrefKeys.layout', DemoPrefKeys.layout),
              const KeyValueRow('DemoPrefKeys.rating', DemoPrefKeys.rating),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _seed,
                icon: const Icon(Icons.dataset_outlined),
                label: const Text('Save a value under each key'),
              ),
            ],
          ),
        ),
        DemoSection(
          title: 'Stored keys',
          subtitle:
              'getKeys() with each value as returned by getData '
              '(already decrypted).',
          code: 'final keys = SharedPrefManager.getKeys();',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final k in SharedPrefManager.getKeys().toList()..sort())
                KeyValueRow(k, '${SharedPrefManager.getData<Object>(k)}'),
              if (SharedPrefManager.getKeys().isEmpty)
                const Text('No keys stored yet.'),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () => setState(() {}),
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
              ),
            ],
          ),
        ),
        DemoSection(
          title: 'Migrate plain values',
          subtitle:
              'Apps that adopt encryption later can encrypt what is already '
              'stored. Save plain values first, then migrate.',
          code: 'final n = await SharedPrefManager.migrateToEncrypted();',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton(
                onPressed: crypto.isInitialized ? _savePlain : null,
                child: const Text('Save plain legacy values'),
              ),
              FilledButton(
                onPressed: crypto.isActive ? _migrate : null,
                child: const Text('migrateToEncrypted()'),
              ),
              if (!crypto.isActive)
                const Text('Needs the encryption feature to be active.'),
            ],
          ),
        ),
        DemoSection(
          title: 'Danger zone',
          child: OutlinedButton.icon(
            onPressed: _clearAll,
            icon: const Icon(Icons.delete_forever_outlined),
            label: const Text('clearAllSharedPrefData()'),
          ),
        ),
      ],
    );
  }
}
