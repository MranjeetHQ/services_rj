import 'package:flutter/material.dart';

import '../controllers/dynamic_form_controller.dart';
import '../models/field_config.dart';
import '../models/field_type.dart';
import '../utils/field_utils.dart';
import 'decoration_helper.dart';

/// Renderer for every text-like field type (text, textarea, password, email,
/// number, decimal, phone, url, search, otp, pin, readOnly and the
/// rich-text fallbacks).
class DynamicTextField extends StatefulWidget {
  /// Creates a text field bound to [field] in [controller].
  const DynamicTextField({
    super.key,
    required this.field,
    required this.controller,
  });

  /// Field configuration.
  final FieldConfig field;

  /// Owning form controller.
  final DynamicFormController controller;

  @override
  State<DynamicTextField> createState() => _DynamicTextFieldState();
}

class _DynamicTextFieldState extends State<DynamicTextField> {
  late final TextEditingController _text;
  late final VoidCallback _cancelExternal;
  bool _obscured = true;

  FieldConfig get field => widget.field;

  @override
  void initState() {
    super.initState();
    _text = TextEditingController(
      text: widget.controller.getValue(field.id)?.toString() ?? '',
    );
    // External setValue / reset → sync into the text controller.
    _cancelExternal = widget.controller.listen(field.id, (value) {
      final s = value?.toString() ?? '';
      if (_text.text != s) _text.text = s;
    });
  }

  @override
  void dispose() {
    _cancelExternal();
    _text.dispose();
    super.dispose();
  }

  bool get _isObscure =>
      field.obscureText ||
      field.type == FieldType.password ||
      field.type == FieldType.pin;

  bool get _isOtp => field.type == FieldType.otp || field.type == FieldType.pin;

  @override
  Widget build(BuildContext context) {
    final state = widget.controller.state(field.id);
    final maxLines =
        field.type == FieldType.textarea ||
            field.type == FieldType.richText ||
            field.type == FieldType.markdown ||
            field.type == FieldType.htmlEditor
        ? (field.maxLines ?? 4)
        : (field.maxLines ?? 1);
    final otpLength = field.ex<int>('length') ?? 6;
    final style = resolveFieldStyle(context, field, widget.controller);

    return ValueListenableBuilder<String?>(
      valueListenable: state.error,
      builder: (context, error, _) => ValueListenableBuilder<bool>(
        valueListenable: state.enabled,
        builder: (context, enabled, _) => TextField(
          controller: _text,
          focusNode: state.focusNode,
          enabled: enabled,
          readOnly: field.readOnly || field.type == FieldType.readOnly,
          autofocus: field.autofocus,
          obscureText: _isObscure && _obscured,
          maxLines: _isObscure ? 1 : maxLines,
          minLines: _isObscure ? null : field.minLines,
          maxLength: _isOtp
              ? otpLength
              : (field.showCounter ? field.maxLength : null),
          textAlign:
              style.textAlign ?? (_isOtp ? TextAlign.center : TextAlign.start),
          textCapitalization: FieldUtils.capitalization(field),
          cursorColor: style.cursorColor,
          style:
              style.textStyle ??
              (_isOtp
                  ? const TextStyle(letterSpacing: 16, fontSize: 22)
                  : null),
          keyboardType: _isOtp
              ? TextInputType.number
              : FieldUtils.keyboardType(field),
          textInputAction: FieldUtils.inputAction(field),
          inputFormatters: FieldUtils.formatters(field),
          decoration: buildFieldDecoration(
            context,
            field,
            widget.controller,
            errorText: error,
            suffix: field.type == FieldType.password
                ? IconButton(
                    icon: Icon(
                      _obscured ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () => setState(() => _obscured = !_obscured),
                    tooltip: _obscured ? 'Show' : 'Hide',
                  )
                : null,
          ).copyWith(counterText: _isOtp ? '' : null),
          onChanged: (v) {
            Object? parsed = v;
            if (field.type == FieldType.number) parsed = int.tryParse(v) ?? v;
            if (field.type == FieldType.decimal) {
              parsed = double.tryParse(v) ?? v;
            }
            widget.controller.setValue(field.id, v.isEmpty ? null : parsed);
          },
          onSubmitted: (_) => state.focusNode.nextFocus(),
        ),
      ),
    );
  }
}
