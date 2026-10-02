import 'package:flutter/material.dart';
import 'package:services_rj/services_rj.dart';

import '../../widgets/demo_widgets.dart';

/// Demo of [AppButtons]: every type, every factory and every prop.
class ButtonsDemo extends StatefulWidget {
  /// Creates the page.
  const ButtonsDemo({super.key});

  @override
  State<ButtonsDemo> createState() => _ButtonsDemoState();
}

class _ButtonsDemoState extends State<ButtonsDemo> {
  final _log = EventLog();
  bool _enabled = true;
  String _customError = '';

  @override
  void dispose() {
    _log.dispose();
    super.dispose();
  }

  VoidCallback _tap(String what) =>
      () => _log.add('onPressed: $what');

  VoidCallback _hold(String what) =>
      () => _log.add('onLongPress: $what');

  void _missingBuilder() {
    try {
      const AppButtons(type: AppButtonType.custom, label: 'x').build(context);
    } on ArgumentError catch (e) {
      setState(() => _customError = e.message.toString());
    }
  }

  Widget _labelled(String label, Widget child) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      child,
      const SizedBox(height: 4),
      Text(label, style: Theme.of(context).textTheme.labelSmall),
    ],
  );

  @override
  Widget build(BuildContext context) => DemoPage(
    title: 'Buttons',
    intro:
        'AppButtons wraps the Material buttons behind one widget. Pick a '
        'type, or use a named factory for the common cases.',
    children: [
      DemoSection(
        title: 'Enabled switch',
        subtitle: 'isEnabled: false disables onPressed and onLongPress.',
        child: SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('isEnabled'),
          value: _enabled,
          onChanged: (v) => setState(() => _enabled = v),
        ),
      ),
      DemoSection(
        title: 'AppButtonType',
        subtitle: 'Long-press any button to see onLongPress.',
        code:
            'AppButtons(\n'
            '  type: AppButtonType.filled,\n'
            "  label: 'Save',\n"
            '  onPressed: save,\n'
            ')',
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.end,
          children: [
            for (final t in [
              AppButtonType.elevated,
              AppButtonType.filled,
              AppButtonType.outlined,
              AppButtonType.text,
              AppButtonType.tonal,
            ])
              AppButtons(
                type: t,
                label: t.name,
                isEnabled: _enabled,
                onPressed: _tap(t.name),
                onLongPress: _hold(t.name),
              ),
            AppButtons(
              type: AppButtonType.icon,
              label: 'icon',
              icon: const Icon(Icons.share),
              isEnabled: _enabled,
              onPressed: _tap('icon'),
              onLongPress: _hold('icon'),
            ),
            AppButtons(
              type: AppButtonType.floatingAction,
              label: 'type-fab',
              icon: const Icon(Icons.add),
              isEnabled: _enabled,
              onPressed: _tap('floatingAction'),
            ),
            AppButtons(
              type: AppButtonType.extendedFloatingAction,
              label: 'extendedFloatingAction',
              icon: const Icon(Icons.edit),
              isEnabled: _enabled,
              onPressed: _tap('extendedFloatingAction'),
            ),
            AppButtons(
              type: AppButtonType.custom,
              label: 'custom',
              customBuilder: (context) => ActionChip(
                avatar: const Icon(Icons.auto_awesome, size: 18),
                label: const Text('custom builder'),
                onPressed: _enabled ? _tap('custom') : null,
              ),
            ),
          ],
        ),
      ),
      DemoSection(
        title: 'Named factories',
        code:
            "AppButtons.filled(label: 'Continue', onPressed: next);\n"
            'AppButtons.iconOnly(icon: Icon(Icons.close), onPressed: close);\n'
            'AppButtons.fab(icon: Icon(Icons.add), onPressed: add);',
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.end,
          children: [
            AppButtons.elevated(
              label: 'Elevated',
              isEnabled: _enabled,
              onPressed: _tap('elevated()'),
              onLongPress: _hold('elevated()'),
            ),
            AppButtons.filled(
              label: 'Filled',
              isEnabled: _enabled,
              onPressed: _tap('filled()'),
            ),
            AppButtons.outlined(
              label: 'Outlined',
              isEnabled: _enabled,
              onPressed: _tap('outlined()'),
            ),
            AppButtons.text(
              label: 'Text',
              isEnabled: _enabled,
              onPressed: _tap('text()'),
            ),
            AppButtons.tonal(
              label: 'Tonal',
              isEnabled: _enabled,
              onPressed: _tap('tonal()'),
            ),
            AppButtons.iconOnly(
              icon: const Icon(Icons.favorite_border),
              isEnabled: _enabled,
              onPressed: _tap('iconOnly()'),
              onLongPress: _hold('iconOnly()'),
            ),
            AppButtons.fab(
              icon: const Icon(Icons.add),
              isEnabled: _enabled,
              onPressed: _tap('fab()'),
            ),
            AppButtons.extendedFab(
              label: 'Extended FAB',
              icon: const Icon(Icons.navigation),
              isEnabled: _enabled,
              onPressed: _tap('extendedFab()'),
            ),
          ],
        ),
      ),
      DemoSection(
        title: 'style',
        subtitle:
            'A ButtonStyle is passed through to elevated, filled, outlined, '
            'text, tonal and icon buttons (not to the FABs).',
        code:
            'AppButtons.filled(\n'
            "  label: 'Pill',\n"
            '  style: FilledButton.styleFrom(shape: StadiumBorder()),\n'
            ')',
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            AppButtons.filled(
              label: 'Pill',
              isEnabled: _enabled,
              style: FilledButton.styleFrom(
                shape: const StadiumBorder(),
                backgroundColor: Colors.deepPurple,
              ),
              onPressed: _tap('styled filled'),
            ),
            AppButtons.outlined(
              label: 'Square',
              isEnabled: _enabled,
              style: OutlinedButton.styleFrom(
                shape: const RoundedRectangleBorder(),
                side: const BorderSide(color: Colors.orange, width: 2),
                foregroundColor: Colors.orange,
              ),
              onPressed: _tap('styled outlined'),
            ),
            AppButtons.elevated(
              label: 'Tall',
              isEnabled: _enabled,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 22,
                ),
              ),
              onPressed: _tap('styled elevated'),
            ),
            AppButtons(
              type: AppButtonType.icon,
              label: '',
              icon: const Icon(Icons.bookmark_border),
              isEnabled: _enabled,
              style: IconButton.styleFrom(
                backgroundColor: Colors.amber.shade200,
                foregroundColor: Colors.black87,
              ),
              onPressed: _tap('styled icon'),
            ),
          ],
        ),
      ),
      DemoSection(
        title: 'customBuilder',
        subtitle:
            'AppButtonType.custom hands rendering to your builder. Without '
            'one it throws an ArgumentError.',
        code:
            'AppButtons(\n'
            '  type: AppButtonType.custom,\n'
            "  label: 'ignored',\n"
            '  customBuilder: (context) => MyBrandButton(),\n'
            ')',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            OutlinedButton(
              onPressed: _missingBuilder,
              child: const Text('Build custom without a builder'),
            ),
            if (_customError.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _customError,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
          ],
        ),
      ),
      DemoSection(
        title: 'Accepted but not applied yet',
        subtitle:
            'size, isSelected and onSelectionChanged exist on AppButtons '
            '(documented for icon sizing and segmented use) but the current '
            'build methods ignore them, as does icon on text-style buttons. '
            'The pairs below render identically.',
        child: Wrap(
          spacing: 16,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.end,
          children: [
            _labelled(
              'size: 48',
              AppButtons(
                type: AppButtonType.icon,
                label: '',
                icon: const Icon(Icons.star),
                size: 48,
                onPressed: _tap('size 48'),
              ),
            ),
            _labelled(
              'no size',
              AppButtons(
                type: AppButtonType.icon,
                label: '',
                icon: const Icon(Icons.star),
                onPressed: _tap('no size'),
              ),
            ),
            _labelled(
              'isSelected {0}',
              AppButtons(
                type: AppButtonType.elevated,
                label: 'Segment',
                isSelected: const {0},
                onSelectionChanged: (s) => _log.add('selection: $s'),
                onPressed: _tap('selection props'),
              ),
            ),
            _labelled(
              'wrap in SizedBox for size',
              SizedBox(
                width: 160,
                child: AppButtons.filled(
                  label: 'Full width',
                  onPressed: _tap('sized'),
                ),
              ),
            ),
          ],
        ),
      ),
      DemoSection(
        title: 'Event log',
        child: EventLogView(log: _log, emptyText: 'Tap a button.'),
      ),
    ],
  );
}
