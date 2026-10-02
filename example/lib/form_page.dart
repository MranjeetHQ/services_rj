import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:services_rj/services_rj.dart';

/// Hosts one JSON form and shows the submitted data.
class FormPage extends StatefulWidget {
  /// Creates a form page.
  const FormPage({
    super.key,
    required this.title,
    required this.json,
    this.initialData,
    this.fieldOverrides = const {},
    this.showSubmit = true,
  });

  /// App bar title.
  final String title;

  /// Form definition.
  final Map<String, dynamic> json;

  /// Prefill (edit mode).
  final Map<String, dynamic>? initialData;

  /// Code-level customization.
  final Map<String, FieldOverrides> fieldOverrides;

  /// Single-page forms show a submit button; wizards submit on the last step.
  final bool showSubmit;

  @override
  State<FormPage> createState() => _FormPageState();
}

class _FormPageState extends State<FormPage> {
  final _controller = DynamicFormController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showResult(Map<String, dynamic> data) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        builder: (context, scroll) => ListView(
          controller: scroll,
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Submitted data',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            SelectableText(
              const JsonEncoder.withIndent('  ').convert(data),
              style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            tooltip: 'Reset',
            icon: const Icon(Icons.restart_alt),
            onPressed: _controller.reset,
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DynamicForm(
              controller: _controller,
              json: widget.json,
              initialData: widget.initialData,
              fieldOverrides: widget.fieldOverrides,
              showSubmitButton: widget.showSubmit,
              submitLabel: 'Save',
              onSubmit: _showResult,
              onOptionAdded: (id, option) => AppSnackbar.success(
                context,
                'Added "${option.label}" to $id',
              ),
              header: const SizedBox(height: 12),
              footer: const SizedBox(height: 32),
            ),
          ),
        ),
      ),
    );
  }
}
