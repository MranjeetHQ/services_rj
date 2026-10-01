import 'package:flutter/material.dart';

import '../controllers/dynamic_form_controller.dart';
import '../models/form_config.dart';
import 'field_wrapper.dart';

/// Wizard renderer used automatically when the JSON has a `steps` list.
///
/// Each step validates its own fields before advancing; the last step
/// submits the whole form.
class MultiStepForm extends StatefulWidget {
  /// Creates a multi-step form.
  const MultiStepForm({
    super.key,
    required this.controller,
    required this.config,
    this.onSubmit,
  });

  /// The form controller.
  final DynamicFormController controller;

  /// Parsed configuration containing [FormConfig.steps].
  final FormConfig config;

  /// Called with valid data when the last step submits.
  final void Function(Map<String, dynamic> data)? onSubmit;

  @override
  State<MultiStepForm> createState() => _MultiStepFormState();
}

class _MultiStepFormState extends State<MultiStepForm> {
  int _current = 0;

  bool _validateStep(int index) {
    var valid = true;
    for (final f in widget.config.steps[index].fields) {
      if (widget.controller.hasField(f.id) &&
          widget.controller.validateField(f.id) != null) {
        valid = false;
      }
    }
    return valid;
  }

  void _next() {
    if (!_validateStep(_current)) return;
    if (_current < widget.config.steps.length - 1) {
      setState(() => _current++);
    } else {
      widget.controller.submit();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.controller.l10n;
    return Stepper(
      currentStep: _current,
      onStepContinue: _next,
      onStepCancel: _current > 0 ? () => setState(() => _current--) : null,
      onStepTapped: (i) {
        // Allow going back freely; forward only through validation.
        if (i < _current) setState(() => _current = i);
      },
      controlsBuilder: (context, details) => Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Row(
          children: [
            FilledButton(
              onPressed: details.onStepContinue,
              child: Text(
                _current == widget.config.steps.length - 1
                    ? l10n.message('submit')
                    : l10n.message('next'),
              ),
            ),
            const SizedBox(width: 8),
            if (details.onStepCancel != null)
              TextButton(
                onPressed: details.onStepCancel,
                child: Text(l10n.message('back')),
              ),
          ],
        ),
      ),
      steps: [
        for (var i = 0; i < widget.config.steps.length; i++)
          Step(
            title: Text(widget.config.steps[i].title),
            subtitle: widget.config.steps[i].subtitle != null
                ? Text(widget.config.steps[i].subtitle!)
                : null,
            isActive: i <= _current,
            state: i < _current ? StepState.complete : StepState.indexed,
            content: Column(
              children: [
                for (final f in widget.config.steps[i].fields)
                  FieldWrapper(
                    key: ValueKey(f.id),
                    field: f,
                    controller: widget.controller,
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
