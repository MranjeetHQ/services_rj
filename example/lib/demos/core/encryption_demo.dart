import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:services_rj/services_rj.dart';

import '../../widgets/demo_widgets.dart';
import 'core_common.dart';

/// Demo of [AppEncryption]: text and bytes APIs, markers and key lifecycle.
class EncryptionDemo extends StatefulWidget {
  /// Creates the page.
  const EncryptionDemo({super.key});

  @override
  State<EncryptionDemo> createState() => _EncryptionDemoState();
}

class _EncryptionDemoState extends State<EncryptionDemo> {
  final _plain = TextEditingController(text: 'card ending 4242');
  final _cipher = TextEditingController();
  final _log = EventLog();
  String _bytesReport = 'Run the bytes round trip.';

  AppEncryption get _crypto => AppEncryption.instance;

  @override
  void dispose() {
    _plain.dispose();
    _cipher.dispose();
    _log.dispose();
    super.dispose();
  }

  void _try(String name, void Function() body) {
    try {
      body();
    } on StateError catch (e) {
      _log.add('$name: StateError - ${e.message}');
    } on FormatException catch (e) {
      _log.add('$name: FormatException - ${e.message}');
    } catch (e) {
      _log.add('$name: $e');
    }
    setState(() {});
  }

  void _encrypt() => _try('encrypt', () {
    _cipher.text = _crypto.encrypt(_plain.text);
    _log.add('encrypt -> ${_cipher.text.length} chars');
  });

  void _decrypt() => _try('decrypt', () {
    _log.add('decrypt -> "${_crypto.decrypt(_cipher.text)}"');
  });

  void _tamper() => _try('tamper', () {
    final c = _cipher.text;
    if (c.length < 12) {
      _log.add('Encrypt something first.');
      return;
    }
    final i = c.length - 4;
    _cipher.text = c.replaceRange(i, i + 1, c[i] == 'A' ? 'B' : 'A');
    _log.add('Flipped one character; decrypt now fails (GCM tag check).');
  });

  void _bytes() => _try('bytes', () {
    final input = Uint8List.fromList(utf8.encode(_plain.text));
    final sealed = _crypto.encryptBytes(input);
    final opened = _crypto.decryptBytes(sealed);
    _bytesReport =
        'plain: ${input.length} bytes\n'
        'sealed: ${sealed.length} bytes '
        '(12 nonce + ${input.length} data + 16 tag)\n'
        'first 12 (nonce): ${sealed.take(12).map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}\n'
        'round trip: "${utf8.decode(opened)}"';
  });

  Future<void> _destroy() async {
    final ok = await confirmAction(
      context,
      title: 'Destroy the encryption key?',
      message:
          'Anything stored with this key can never be decrypted again. '
          'Use this for sign-out on shared devices or a user-requested wipe.',
      confirmLabel: 'Destroy key',
      destructive: true,
    );
    if (!ok || !mounted) return;
    try {
      await _crypto.destroyKey();
      _log.add('destroyKey() done; isInitialized = ${_crypto.isInitialized}');
    } catch (e) {
      _log.add('destroyKey failed: $e');
    }
    if (mounted) setState(() {});
  }

  Future<void> _reinit() async {
    try {
      await _crypto.initialize();
      _log.add('initialize() created a fresh key');
    } catch (e) {
      _log.add('initialize failed: $e');
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final ready = _crypto.isInitialized;
    return DemoPage(
      title: 'Encryption',
      intro:
          'AES-256-GCM with a key kept in the platform secure store. '
          'Ciphertext starts with the "${AppEncryption.marker}" marker.',
      children: [
        if (!ready && !AppController.instance.isEnabled(AppFeature.encryption))
          const FeatureOffNotice(feature: 'encryption'),
        DemoSection(
          title: 'Status',
          code:
              'AppEncryption.instance.isInitialized\n'
              'AppEncryption.instance.isActive // enabled && key loaded',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                children: [
                  StatusPill(label: 'isInitialized', ok: _crypto.isInitialized),
                  StatusPill(label: 'isActive', ok: _crypto.isActive),
                  StatusPill(label: 'enabled', ok: _crypto.enabled),
                ],
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('enabled'),
                subtitle: const Text(
                  'Off: SharedPrefManager writes plain values again. '
                  'Existing ciphertext stays readable.',
                ),
                value: _crypto.enabled,
                onChanged: (v) => setState(() => _crypto.enabled = v),
              ),
            ],
          ),
        ),
        DemoSection(
          title: 'Text',
          code:
              'final sealed = AppEncryption.instance.encrypt(text);\n'
              'final back = AppEncryption.instance.decrypt(sealed);\n'
              'AppEncryption.isEncrypted(sealed); // true',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _plain,
                decoration: const InputDecoration(labelText: 'Plain text'),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _cipher,
                minLines: 1,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Ciphertext'),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 8),
              Text(
                'isEncrypted(ciphertext): '
                '${AppEncryption.isEncrypted(_cipher.text)}   '
                'isEncrypted(plain): ${AppEncryption.isEncrypted(_plain.text)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton(
                    onPressed: ready ? _encrypt : null,
                    child: const Text('Encrypt'),
                  ),
                  OutlinedButton(
                    onPressed: ready ? _decrypt : null,
                    child: const Text('Decrypt'),
                  ),
                  OutlinedButton(
                    onPressed: ready ? _tamper : null,
                    child: const Text('Tamper'),
                  ),
                ],
              ),
            ],
          ),
        ),
        DemoSection(
          title: 'Bytes',
          subtitle: 'Layout: nonce(12) | ciphertext | tag(16).',
          code:
              'final sealed = AppEncryption.instance.encryptBytes(bytes);\n'
              'final plain = AppEncryption.instance.decryptBytes(sealed);',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              OutlinedButton(
                onPressed: ready ? _bytes : null,
                child: const Text('Encrypt the plain text as bytes'),
              ),
              const SizedBox(height: 8),
              SelectableText(
                _bytesReport,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ],
          ),
        ),
        DemoSection(
          title: 'Key lifecycle',
          subtitle:
              'destroyKey() removes the key from memory and secure storage.',
          code: 'await AppEncryption.instance.destroyKey();',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Theme.of(context).colorScheme.onError,
                ),
                onPressed: ready ? _destroy : null,
                icon: const Icon(Icons.key_off),
                label: const Text('destroyKey()'),
              ),
              OutlinedButton(
                onPressed: !ready ? _reinit : null,
                child: const Text('initialize() with a new key'),
              ),
            ],
          ),
        ),
        DemoSection(
          title: 'Event log',
          child: EventLogView(log: _log, emptyText: 'Results appear here.'),
        ),
      ],
    );
  }
}
