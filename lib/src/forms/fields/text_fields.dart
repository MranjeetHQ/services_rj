import 'package:country_flags/country_flags.dart';
import 'package:flutter/material.dart';

import '../controllers/dynamic_form_controller.dart';
import '../models/country_dial_code.dart';
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

  /// Countries offered by the optional country code picker.
  late final List<CountryDialCode> _countries;

  /// Selected country; only used when [_countryCodeOn].
  late CountryDialCode _country;

  FieldConfig get field => widget.field;

  /// Phone fields (`phone` type, or the `mobile` / `phone` presets) can show
  /// a country code picker with `"countryCode": true` (or a default such as
  /// `"IN"` / `"+44"`). The value is then stored as `+<code><digits>`.
  bool get _countryCodeOn => FieldUtils.hasCountryCode(field);

  static String _digits(String s) => s.replaceAll(RegExp(r'[^\d]'), '');

  /// Text shown in the input for [value]: the national number when the
  /// value carries a country code that is in [_countries].
  String _textFor(Object? value) {
    final s = value?.toString() ?? '';
    if (!_countryCodeOn) return s;
    final parts = CountryDialCodes.split(s, among: _countries);
    return parts.dial == null ? s : parts.national;
  }

  /// Keeps [_country] in step with the dial code inside [value].
  void _syncCountry(Object? value) {
    final dial = CountryDialCodes.split(
      value?.toString(),
      among: _countries,
    ).dial;
    final match = CountryDialCodes.lookup(dial, among: _countries);
    if (match != null && match.dial != _country.dial) _country = match;
  }

  /// Writes `+<code><digits>` (or null when empty) into the form value.
  void _publishPhone() {
    final digits = _digits(_text.text);
    widget.controller.setValue(
      field.id,
      digits.isEmpty ? null : '${_country.dial}$digits',
    );
  }

  Future<void> _pickCountry() async {
    final l10n = widget.controller.l10n;
    final picked = await showModalBottomSheet<CountryDialCode>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        var query = '';
        return StatefulBuilder(
          builder: (context, setSheet) {
            final shown = CountryDialCodes.search(query, among: _countries);
            final media = MediaQuery.of(context);
            return SafeArea(
              // Lift the sheet above the keyboard so results stay visible
              // while typing.
              child: Padding(
                padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
                child: SizedBox(
                  height: media.size.height * 0.6,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        child: TextField(
                          autofocus: false,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.search),
                            hintText: l10n.message('searchCountry'),
                          ),
                          onChanged: (v) => setSheet(() => query = v),
                        ),
                      ),
                      Expanded(
                        child: shown.isEmpty
                            ? Center(child: Text(l10n.message('noResults')))
                            : ListView.builder(
                                itemCount: shown.length,
                                itemBuilder: (context, i) {
                                  final c = shown[i];
                                  return ListTile(
                                    leading: _flag(c, width: 32),
                                    title: Text(c.name),
                                    trailing: Text(c.dial),
                                    selected: c == _country,
                                    onTap: () => Navigator.pop(sheetContext, c),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
    if (picked == null || !mounted) return;
    setState(() => _country = picked);
    _publishPhone();
  }

  /// Flag picture for [c]; falls back to the emoji flag if it cannot be built.
  static Widget _flag(CountryDialCode c, {double width = 28}) {
    try {
      return CountryFlag.fromCountryCode(
        c.iso,
        theme: ImageTheme(
          width: width,
          height: width * 0.72,
          shape: const RoundedRectangle(3),
        ),
      );
    } catch (_) {
      return Text(c.flag, style: TextStyle(fontSize: width * 0.8));
    }
  }

  Widget _countryButton(bool interactive) => InkWell(
    key: ValueKey('${field.id}_country'),
    onTap: interactive ? _pickCountry : null,
    borderRadius: BorderRadius.circular(8),
    child: Padding(
      padding: const EdgeInsetsDirectional.only(start: 12, end: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _flag(_country, width: 26),
          const SizedBox(width: 6),
          Text(_country.dial),
          Icon(
            Icons.arrow_drop_down,
            color: interactive ? null : Theme.of(context).disabledColor,
          ),
        ],
      ),
    ),
  );

  @override
  void initState() {
    super.initState();
    _countries = CountryDialCodes.resolve(field.ex<List>('countryCodes'));
    final wanted = field.ex<Object>('countryCode');
    _country =
        (wanted is String
            ? CountryDialCodes.lookup(wanted, among: _countries)
            : null) ??
        _countries.first;
    final initial = widget.controller.getValue(field.id);
    if (_countryCodeOn) _syncCountry(initial);
    _text = TextEditingController(text: _textFor(initial));
    // External setValue / reset → sync into the text controller.
    _cancelExternal = widget.controller.listen(field.id, (value) {
      if (_countryCodeOn) {
        final before = _country;
        _syncCountry(value);
        if (before != _country && mounted) setState(() {});
        // Compare digits only so typed spaces or dashes are not wiped.
        final national = _textFor(value);
        if (_digits(_text.text) != _digits(national)) _text.text = national;
        return;
      }
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
            prefix: _countryCodeOn
                ? _countryButton(enabled && !field.readOnly)
                : null,
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
            if (_countryCodeOn) return _publishPhone();
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
