import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:services_rj/services_rj.dart';

import '../../widgets/demo_widgets.dart';
import 'network_common.dart';

/// The snippet formats `PermissionSetup` can generate.
enum SetupFormat {
  /// `<uses-permission>` lines.
  androidManifest('AndroidManifest.xml'),

  /// Info.plist keys.
  iosInfoPlist('Info.plist'),

  /// Podfile `post_install` block.
  iosPodfile('Podfile'),

  /// Markdown table of every permission.
  markdown('Markdown');

  const SetupFormat(this.label);

  /// Button label.
  final String label;
}

/// Generates the snippet for [format] from the chosen [permissions].
String generateSetup(SetupFormat format, Set<AppPermission> permissions) =>
    switch (format) {
      SetupFormat.androidManifest => PermissionSetup.androidManifest(
        permissions,
      ),
      SetupFormat.iosInfoPlist => PermissionSetup.iosInfoPlist(permissions),
      SetupFormat.iosPodfile => PermissionSetup.iosPodfile(permissions),
      SetupFormat.markdown => PermissionSetup.markdownReference(),
    };

/// Builds the native setup snippets for a chosen set of permissions.
class PermissionSetupPage extends StatefulWidget {
  /// Creates the page.
  const PermissionSetupPage({super.key});

  @override
  State<PermissionSetupPage> createState() => _PermissionSetupPageState();
}

class _PermissionSetupPageState extends State<PermissionSetupPage> {
  final Set<AppPermission> _selected = {
    AppPermission.camera,
    AppPermission.location,
  };
  SetupFormat _format = SetupFormat.androidManifest;

  Future<void> _copy(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Copied to the clipboard')));
  }

  @override
  Widget build(BuildContext context) {
    final output = generateSetup(_format, _selected);
    final spec = _selected.isEmpty
        ? null
        : PermissionRegistry.of(_selected.first);
    return DemoPage(
      title: 'Permission setup generator',
      intro:
          'PermissionSetup builds the native setup from PermissionRegistry, so '
          'the snippets always match the code. Pick the permissions your app '
          'uses and paste the result into your project.',
      children: [
        DemoSection(
          title: 'Choose permissions',
          code:
              "PermissionSetup.androidManifest({AppPermission.camera});\nPermissionSetup.iosInfoPlist({AppPermission.camera});\nPermissionSetup.iosPodfile({AppPermission.camera});\nPermissionSetup.markdownReference();",
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final p in AppPermission.values)
                    FilterChip(
                      label: Text(p.name),
                      selected: _selected.contains(p),
                      onSelected: (v) => setState(() {
                        v ? _selected.add(p) : _selected.remove(p);
                      }),
                    ),
                ],
              ),
              Row(
                children: [
                  TextButton(
                    onPressed: () =>
                        setState(() => _selected.addAll(AppPermission.values)),
                    child: const Text('Select all'),
                  ),
                  TextButton(
                    onPressed: () => setState(_selected.clear),
                    child: const Text('Select none'),
                  ),
                ],
              ),
            ],
          ),
        ),
        DemoSection(
          title: 'Generated output',
          subtitle: _selected.isEmpty && _format != SetupFormat.markdown
              ? 'Nothing selected.'
              : '${_selected.length} permission(s) selected.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SegmentedButton<SetupFormat>(
                showSelectedIcon: false,
                segments: [
                  for (final f in SetupFormat.values)
                    ButtonSegment(value: f, label: Text(f.label)),
                ],
                selected: {_format},
                onSelectionChanged: (s) => setState(() => _format = s.first),
              ),
              const SizedBox(height: 12),
              CodeSnippet(output.isEmpty ? '(empty)' : output),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: output.isEmpty ? null : () => _copy(output),
                icon: const Icon(Icons.copy, size: 18),
                label: const Text('Copy'),
              ),
              if (_format == SetupFormat.iosInfoPlist)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Replace every TODO with a real, specific reason. App '
                    'Review rejects vague usage descriptions.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
            ],
          ),
        ),
        if (spec != null)
          DemoSection(
            title: 'PermissionRegistry: ${spec.permission.name}',
            subtitle:
                'PermissionRegistry.of(permission) is the single source of '
                'truth behind the output above (first selected tag shown).',
            child: KeyValueTable([
              ('description', spec.description),
              ('supportsAndroid', '${spec.supportsAndroid}'),
              ('supportsIos', '${spec.supportsIos}'),
              ('sequential', '${spec.sequential}'),
              ('Android API 28', _natives(spec, 28)),
              ('Android API 33', _natives(spec, 33)),
              ('iOS', spec.ios.isEmpty ? 'none' : spec.ios.join(', ')),
              ('notes', spec.notes.isEmpty ? '-' : spec.notes.join('\n')),
            ]),
          ),
      ],
    );
  }

  String _natives(PermissionSpec spec, int sdk) {
    final list = PermissionRegistry.resolve(
      spec.permission,
      PermissionPlatform.android,
      androidSdkInt: sdk,
    );
    return list.isEmpty ? 'none' : list.join(', ');
  }
}
