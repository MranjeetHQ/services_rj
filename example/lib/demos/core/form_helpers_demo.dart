import 'package:flutter/material.dart';
import 'package:services_rj/services_rj.dart';

import '../../widgets/demo_widgets.dart';

/// Demo of [AppValidators] and [AppDebouncer].
class FormHelpersDemo extends StatefulWidget {
  /// Creates the page.
  const FormHelpersDemo({super.key});

  @override
  State<FormHelpersDemo> createState() => _FormHelpersDemoState();
}

class _FormHelpersDemoState extends State<FormHelpersDemo> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  String _result = '';

  int _delay = 600;
  late AppDebouncer _debouncer = AppDebouncer(milliseconds: _delay);
  int _keystrokes = 0;
  int _calls = 0;
  String _lastQuery = '';

  @override
  void dispose() {
    _debouncer.dispose();
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    final ok = _formKey.currentState!.validate();
    setState(() => _result = ok ? 'All fields are valid.' : 'Fix the errors.');
  }

  void _typed(String text) {
    setState(() => _keystrokes++);
    _debouncer.run(() {
      if (!mounted) return;
      setState(() {
        _calls++;
        _lastQuery = text;
      });
    });
  }

  void _changeDelay(int ms) {
    _debouncer.dispose();
    setState(() {
      _delay = ms;
      _debouncer = AppDebouncer(milliseconds: ms);
    });
  }

  @override
  Widget build(BuildContext context) => DemoPage(
    title: 'Validators and debouncer',
    children: [
      DemoSection(
        title: 'AppValidators',
        subtitle:
            'Plain functions that fit any TextFormField.validator. '
            'requiredField trims whitespace; password needs 6+ characters.',
        code:
            'TextFormField(validator: AppValidators.email)\n'
            'TextFormField(validator: AppValidators.password)\n'
            'TextFormField(validator: AppValidators.requiredField)',
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Full name'),
                validator: AppValidators.requiredField,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: AppValidators.email,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _password,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
                validator: AppValidators.password,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  FilledButton(
                    onPressed: _submit,
                    child: const Text('Validate'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(_result)),
                ],
              ),
            ],
          ),
        ),
      ),
      DemoSection(
        title: 'AppDebouncer',
        subtitle:
            'run() cancels the previous timer, so the action fires once the '
            'user pauses. dispose() cancels a pending call.',
        code:
            'final debouncer = AppDebouncer(milliseconds: 500);\n'
            'onChanged: (q) => debouncer.run(() => search(q));\n'
            '// in dispose():\n'
            'debouncer.dispose();',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 300, label: Text('300 ms')),
                ButtonSegment(value: 600, label: Text('600 ms')),
                ButtonSegment(value: 1000, label: Text('1000 ms')),
              ],
              selected: {_delay},
              onSelectionChanged: (s) => _changeDelay(s.first),
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Search the catalogue',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: _typed,
            ),
            const SizedBox(height: 12),
            Text('Keystrokes: $_keystrokes'),
            Text('Debounced calls: $_calls'),
            Text('Last debounced value: "$_lastQuery"'),
            TextButton(
              onPressed: () => setState(() {
                _keystrokes = 0;
                _calls = 0;
                _lastQuery = '';
              }),
              child: const Text('Reset counters'),
            ),
          ],
        ),
      ),
    ],
  );
}
