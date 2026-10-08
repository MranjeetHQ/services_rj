import 'package:flutter/material.dart';
import 'package:services_rj/services_rj.dart';

import '../../widgets/demo_widgets.dart';
import 'core_common.dart';

/// Live playground for the String, double and number extensions.
class ExtensionsDemo extends StatefulWidget {
  /// Creates the page.
  const ExtensionsDemo({super.key});

  @override
  State<ExtensionsDemo> createState() => _ExtensionsDemoState();
}

class _ExtensionsDemoState extends State<ExtensionsDemo> {
  static const _textPresets = [
    'asha.patel@example.com',
    '+91 98765-43210',
    'https://example.com/docs',
    'ranjit kumar_makwana',
    'UserProfileScreen',
    '42.5',
    'नमस्ते दुनिया',
    'yes',
    '   ',
  ];

  static const _numberPresets = ['1234567.891', '999950', '0.256', '-20', '3'];

  final _text = TextEditingController(text: _textPresets.first);
  final _number = TextEditingController(text: _numberPresets.first);

  int _truncateTo = 10;
  int _maskStart = 0;
  int _maskEnd = 4;
  bool _isNull = false;
  int _decimals = 2;
  bool _indian = false;
  String _symbol = '₹';
  double _space = 12;

  @override
  void initState() {
    super.initState();
    _text.addListener(() => setState(() {}));
    _number.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _text.dispose();
    _number.dispose();
    super.dispose();
  }

  Widget _presets(List<String> values, TextEditingController controller) =>
      Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final v in values)
            ActionChip(
              label: Text(v.isBlank ? '(blank)' : v),
              onPressed: () => controller.text = v,
            ),
        ],
      );

  Widget _intSlider(
    String label,
    int value,
    int min,
    int max,
    ValueChanged<int> onChanged,
  ) => Row(
    children: [
      SizedBox(width: 140, child: Text('$label: $value')),
      Expanded(
        child: Slider(
          value: value.toDouble(),
          min: min.toDouble(),
          max: max.toDouble(),
          divisions: max - min,
          onChanged: (v) => setState(() => onChanged(v.round())),
        ),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final s = _text.text;
    final String? nullable = _isNull ? null : s;
    final parsed = _number.text.toDoubleOrNull();
    final n = parsed.orZero;

    return DemoPage(
      title: 'Extensions',
      intro:
          'Type or pick a value; every row is the extension called on it. '
          'Full reference: docs/extensions.md.',
      children: [
        DemoSection(
          title: 'String input',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _text,
                decoration: const InputDecoration(labelText: 'Text'),
              ),
              const SizedBox(height: 8),
              _presets(_textPresets, _text),
            ],
          ),
        ),
        DemoSection(
          title: 'String checks and conversions',
          code:
              "'a@b.com'.isEmail  '+91 98765-43210'.isPhone\n"
              "' 42 '.toIntOrNull()  'Yes'.toBool()",
          child: Column(
            children: [
              KeyValueRow('isBlank', '${s.isBlank}'),
              KeyValueRow('isNotBlank', '${s.isNotBlank}'),
              KeyValueRow('isEmail', '${s.isEmail}'),
              KeyValueRow('isPhone', '${s.isPhone}'),
              KeyValueRow('isUrl', '${s.isUrl}'),
              KeyValueRow('isNumeric', '${s.isNumeric}'),
              KeyValueRow('isAlphabetic', '${s.isAlphabetic}'),
              KeyValueRow('isAlphanumeric', '${s.isAlphanumeric}'),
              KeyValueRow(
                "equalsIgnoreCase('YES')",
                '${s.equalsIgnoreCase('YES')}',
              ),
              KeyValueRow('toIntOrNull()', '${s.toIntOrNull()}'),
              KeyValueRow('toDoubleOrNull()', '${s.toDoubleOrNull()}'),
              KeyValueRow('toBool()', '${s.toBool()}'),
            ],
          ),
        ),
        DemoSection(
          title: 'Case and editing',
          code:
              "'user_name'.toCamelCase()  'hello WORLD'.toTitleCase()\n"
              "'Hello world'.truncate(8)  '9876543210'.mask()",
          child: Column(
            children: [
              KeyValueRow('capitalize()', s.capitalize()),
              KeyValueRow('toTitleCase()', s.toTitleCase()),
              KeyValueRow('toCamelCase()', s.toCamelCase()),
              KeyValueRow('toSnakeCase()', s.toSnakeCase()),
              KeyValueRow('toKebabCase()', s.toKebabCase()),
              KeyValueRow('removeWhitespace()', s.removeWhitespace()),
              KeyValueRow('collapseWhitespace()', s.collapseWhitespace()),
              KeyValueRow('onlyDigits()', s.onlyDigits()),
              KeyValueRow('reverse()', s.reverse()),
              KeyValueRow('initials', s.initials),
              const Divider(),
              _intSlider(
                'truncate',
                _truncateTo,
                1,
                30,
                (v) => _truncateTo = v,
              ),
              KeyValueRow('truncate($_truncateTo)', s.truncate(_truncateTo)),
              _intSlider(
                'mask visibleStart',
                _maskStart,
                0,
                6,
                (v) => _maskStart = v,
              ),
              _intSlider(
                'mask visibleEnd',
                _maskEnd,
                0,
                6,
                (v) => _maskEnd = v,
              ),
              KeyValueRow(
                'mask(visibleStart: $_maskStart, visibleEnd: $_maskEnd)',
                s.mask(visibleStart: _maskStart, visibleEnd: _maskEnd),
              ),
            ],
          ),
        ),
        DemoSection(
          title: 'Nullable strings',
          subtitle: 'On String?, so no null check is needed first.',
          code: "nickname.or('Guest')  nickname.orEmpty",
          child: Column(
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Value is null'),
                value: _isNull,
                onChanged: (v) => setState(() => _isNull = v),
              ),
              KeyValueRow('isNullOrEmpty', '${nullable.isNullOrEmpty}'),
              KeyValueRow('isNullOrBlank', '${nullable.isNullOrBlank}'),
              KeyValueRow('orEmpty', "'${nullable.orEmpty}'"),
              KeyValueRow("or('Guest')", nullable.or('Guest')),
            ],
          ),
        ),
        DemoSection(
          title: 'Number input',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _number,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Number',
                  helperText: parsed == null
                      ? 'Not a number: parsed.orZero gives 0.0'
                      : null,
                ),
              ),
              const SizedBox(height: 8),
              _presets(_numberPresets, _number),
              _intSlider('decimals', _decimals, 0, 4, (v) => _decimals = v),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Indian grouping (lakh / crore)'),
                value: _indian,
                onChanged: (v) => setState(() => _indian = v),
              ),
              Wrap(
                spacing: 8,
                children: [
                  for (final symbol in ['₹', r'$', '€', '£'])
                    ChoiceChip(
                      label: Text(symbol),
                      selected: _symbol == symbol,
                      onSelected: (_) => setState(() => _symbol = symbol),
                    ),
                ],
              ),
            ],
          ),
        ),
        DemoSection(
          title: 'double and number formatting',
          code:
              "1499.5.toCurrency('₹')  1250.toCompact()  0.256.toPercent()\n"
              '3.14159.roundTo(2)  2.50.toCleanString()',
          child: Column(
            children: [
              KeyValueRow('orZero', '$n'),
              KeyValueRow('roundTo($_decimals)', '${n.roundTo(_decimals)}'),
              KeyValueRow('isWhole', '${n.isWhole}'),
              KeyValueRow(
                'toCleanString(maxDecimals: $_decimals)',
                n.toCleanString(maxDecimals: _decimals),
              ),
              KeyValueRow(
                'withSeparators',
                n.withSeparators(decimals: _decimals, indian: _indian),
              ),
              KeyValueRow(
                "toCurrency('$_symbol')",
                n.toCurrency(_symbol, decimals: _decimals, indian: _indian),
              ),
              KeyValueRow(
                'toCompact',
                n.toCompact(decimals: _decimals, indian: _indian),
              ),
              KeyValueRow(
                'toPercent(decimals: $_decimals)',
                n.toPercent(decimals: _decimals),
              ),
              KeyValueRow('isBetween(0, 100)', '${n.isBetween(0, 100)}'),
            ],
          ),
        ),
        DemoSection(
          title: 'Layout helpers',
          subtitle: 'On num, so int literals work: 16.heightBox.',
          code:
              'Column(children: [title, 8.heightBox, body])\n'
              'Container(padding: 16.allInsets,\n'
              '  decoration: BoxDecoration(borderRadius: 12.borderRadius))',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _intSlider(
                'value',
                _space.round(),
                0,
                32,
                (v) => _space = v.toDouble(),
              ),
              Container(
                padding: _space.allInsets,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: _space.borderRadius,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('allInsets + borderRadius = ${_space.round()}'),
                    _space.heightBox,
                    Row(
                      children: [
                        const Icon(Icons.swap_vert),
                        _space.widthBox,
                        const Text('heightBox above, widthBox left'),
                      ],
                    ),
                    _space.heightBox,
                    Container(
                      padding: _space.horizontalInsets,
                      color: Theme.of(context).colorScheme.surface,
                      child: const Text('horizontalInsets'),
                    ),
                    _space.heightBox,
                    Container(
                      padding: _space.verticalInsets,
                      color: Theme.of(context).colorScheme.surface,
                      child: const Text('verticalInsets'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
