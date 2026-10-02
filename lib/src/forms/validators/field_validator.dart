import '../localization/form_localizations.dart';
import '../models/text_preset.dart';
import '../models/validator_config.dart';

/// Signature of a programmatic custom validator. Return an error message or
/// `null` when valid.
typedef CustomValidatorFn =
    String? Function(Object? value, Map<String, dynamic> formData);

/// Strategy interface: one validator = one rule.
abstract class FieldValidator {
  /// Creates a validator from its JSON config.
  const FieldValidator(this.config);

  /// The JSON config that produced this validator.
  final ValidatorConfig config;

  /// Validates [value]; [formData] enables cross-field rules; returns an
  /// error message or `null` when valid.
  String? validate(
    Object? value,
    Map<String, dynamic> formData,
    FormLocalizations l10n,
  );

  /// True when [value] counts as empty (non-required validators skip empties).
  static bool isEmpty(Object? value) =>
      value == null ||
      (value is String && value.trim().isEmpty) ||
      (value is Iterable && value.isEmpty) ||
      (value is Map && value.isEmpty);
}

/// `{"type": "required"}`
class RequiredValidator extends FieldValidator {
  /// Creates a required validator.
  const RequiredValidator(super.config);

  @override
  String? validate(
    Object? value,
    Map<String, dynamic> formData,
    FormLocalizations l10n,
  ) => FieldValidator.isEmpty(value) || value == false
      ? config.message ?? l10n.message('required')
      : null;
}

/// Base for regex-driven format validators.
abstract class _PatternValidator extends FieldValidator {
  const _PatternValidator(super.config);

  /// The pattern to match.
  RegExp get pattern;

  /// Localization key for the default message.
  String get messageKey;

  @override
  String? validate(
    Object? value,
    Map<String, dynamic> formData,
    FormLocalizations l10n,
  ) {
    if (FieldValidator.isEmpty(value)) return null;
    return pattern.hasMatch(value.toString())
        ? null
        : config.message ?? l10n.message(messageKey);
  }
}

/// `{"type": "email"}`
class EmailValidator extends _PatternValidator {
  /// Creates an email validator.
  const EmailValidator(super.config);
  @override
  RegExp get pattern => RegExp(r'^[\w.+-]+@[a-zA-Z\d-]+(\.[a-zA-Z\d-]+)+$');
  @override
  String get messageKey => 'email';
}

/// `{"type": "phone"}`
class PhoneValidator extends _PatternValidator {
  /// Creates a phone validator.
  const PhoneValidator(super.config);
  @override
  RegExp get pattern => RegExp(r'^\+?[\d\s\-()]{7,15}$');
  @override
  String get messageKey => 'phone';
}

/// `{"type": "url"}`
class UrlValidator extends _PatternValidator {
  /// Creates a URL validator.
  const UrlValidator(super.config);
  @override
  RegExp get pattern =>
      RegExp(r'^(https?://)?[\w-]+(\.[\w-]+)+([/?#][^\s]*)?$');
  @override
  String get messageKey => 'url';
}

/// `{"type": "number"}`
class NumberValidator extends FieldValidator {
  /// Creates an integer validator.
  const NumberValidator(super.config);
  @override
  String? validate(
    Object? value,
    Map<String, dynamic> formData,
    FormLocalizations l10n,
  ) {
    if (FieldValidator.isEmpty(value)) return null;
    if (value is int) return null;
    return int.tryParse(value.toString()) == null
        ? config.message ?? l10n.message('number')
        : null;
  }
}

/// `{"type": "decimal"}`
class DecimalValidator extends FieldValidator {
  /// Creates a decimal validator.
  const DecimalValidator(super.config);
  @override
  String? validate(
    Object? value,
    Map<String, dynamic> formData,
    FormLocalizations l10n,
  ) {
    if (FieldValidator.isEmpty(value)) return null;
    if (value is num) return null;
    return double.tryParse(value.toString()) == null
        ? config.message ?? l10n.message('decimal')
        : null;
  }
}

/// `{"type": "min", "value": 18}` — numeric minimum.
class MinValidator extends FieldValidator {
  /// Creates a min validator.
  const MinValidator(super.config);
  @override
  String? validate(
    Object? value,
    Map<String, dynamic> formData,
    FormLocalizations l10n,
  ) {
    if (FieldValidator.isEmpty(value)) return null;
    final n = value is num ? value : num.tryParse(value.toString());
    final min = config.value as num? ?? 0;
    return (n == null || n < min)
        ? config.message ?? l10n.message('min', value: min)
        : null;
  }
}

/// `{"type": "max", "value": 100}` — numeric maximum.
class MaxValidator extends FieldValidator {
  /// Creates a max validator.
  const MaxValidator(super.config);
  @override
  String? validate(
    Object? value,
    Map<String, dynamic> formData,
    FormLocalizations l10n,
  ) {
    if (FieldValidator.isEmpty(value)) return null;
    final n = value is num ? value : num.tryParse(value.toString());
    final max = config.value as num? ?? 0;
    return (n == null || n > max)
        ? config.message ?? l10n.message('max', value: max)
        : null;
  }
}

/// `{"type": "minLength", "value": 8}`
class MinLengthValidator extends FieldValidator {
  /// Creates a min-length validator.
  const MinLengthValidator(super.config);
  @override
  String? validate(
    Object? value,
    Map<String, dynamic> formData,
    FormLocalizations l10n,
  ) {
    if (FieldValidator.isEmpty(value)) return null;
    final len = (config.value as num?)?.toInt() ?? 0;
    return value.toString().length < len
        ? config.message ?? l10n.message('minLength', value: len)
        : null;
  }
}

/// `{"type": "maxLength", "value": 20}`
class MaxLengthValidator extends FieldValidator {
  /// Creates a max-length validator.
  const MaxLengthValidator(super.config);
  @override
  String? validate(
    Object? value,
    Map<String, dynamic> formData,
    FormLocalizations l10n,
  ) {
    if (FieldValidator.isEmpty(value)) return null;
    final len = (config.value as num?)?.toInt() ?? 0;
    return value.toString().length > len
        ? config.message ?? l10n.message('maxLength', value: len)
        : null;
  }
}

/// `{"type": "regex", "value": "^[A-Z]+$"}`
class RegexValidator extends FieldValidator {
  /// Creates a regex validator.
  const RegexValidator(super.config);
  @override
  String? validate(
    Object? value,
    Map<String, dynamic> formData,
    FormLocalizations l10n,
  ) {
    if (FieldValidator.isEmpty(value)) return null;
    return RegExp(config.value.toString()).hasMatch(value.toString())
        ? null
        : config.message ?? l10n.message('regex');
  }
}

/// `{"type": "matchField", "value": "password"}` — cross-field equality.
class MatchFieldValidator extends FieldValidator {
  /// Creates a match-field validator.
  const MatchFieldValidator(super.config);
  @override
  String? validate(
    Object? value,
    Map<String, dynamic> formData,
    FormLocalizations l10n,
  ) => value == formData[config.value.toString()]
      ? null
      : config.message ?? l10n.message('matchField');
}

/// `{"type": "passwordStrength"}` — upper + lower + digit + symbol, min 8.
class PasswordStrengthValidator extends FieldValidator {
  /// Creates a password-strength validator.
  const PasswordStrengthValidator(super.config);
  @override
  String? validate(
    Object? value,
    Map<String, dynamic> formData,
    FormLocalizations l10n,
  ) {
    if (FieldValidator.isEmpty(value)) return null;
    final s = value.toString();
    final minLen = (config.value as num?)?.toInt() ?? 8;
    final strong =
        s.length >= minLen &&
        RegExp('[A-Z]').hasMatch(s) &&
        RegExp('[a-z]').hasMatch(s) &&
        RegExp(r'\d').hasMatch(s) &&
        RegExp(r'[^\w\s]').hasMatch(s);
    return strong ? null : config.message ?? l10n.message('passwordStrength');
  }
}

int _count(Object? value) => switch (value) {
  null => 0,
  Iterable<Object?> i => i.length,
  Map<Object?, Object?> m => m.length,
  String s when s.isEmpty => 0,
  _ => 1,
};

/// `{"type": "minItems", "value": 2}` — at least N selections / entries.
/// Unlike most validators it also fails on an empty value.
class MinItemsValidator extends FieldValidator {
  /// Creates a min-items validator.
  const MinItemsValidator(super.config);
  @override
  String? validate(
    Object? value,
    Map<String, dynamic> formData,
    FormLocalizations l10n,
  ) {
    final min = (config.value as num?)?.toInt() ?? 0;
    return _count(value) < min
        ? config.message ?? l10n.message('minItems', value: min)
        : null;
  }
}

/// `{"type": "maxItems", "value": 3}` — at most N selections / entries.
class MaxItemsValidator extends FieldValidator {
  /// Creates a max-items validator.
  const MaxItemsValidator(super.config);
  @override
  String? validate(
    Object? value,
    Map<String, dynamic> formData,
    FormLocalizations l10n,
  ) {
    final max = (config.value as num?)?.toInt() ?? 0;
    return _count(value) > max
        ? config.message ?? l10n.message('maxItems', value: max)
        : null;
  }
}

/// Wraps a programmatic [CustomValidatorFn].
class CustomValidator extends FieldValidator {
  /// Creates a custom validator.
  const CustomValidator(super.config, this.fn);

  /// The validation function.
  final CustomValidatorFn fn;

  @override
  String? validate(
    Object? value,
    Map<String, dynamic> formData,
    FormLocalizations l10n,
  ) => fn(value, formData);
}

/// `{"type": "preset", "value": "pan"}` — format check of a text preset.
/// Added automatically for fields that set `preset`.
class PresetValidator extends FieldValidator {
  /// Creates a preset validator for the preset named in `config.value`.
  const PresetValidator(super.config);

  @override
  String? validate(
    Object? value,
    Map<String, dynamic> formData,
    FormLocalizations l10n,
  ) {
    if (FieldValidator.isEmpty(value)) return null;
    final spec = TextPresets.resolve(config.value?.toString());
    if (spec == null) return null; // `custom` is checked by `regex`.
    return spec.isValid(value.toString())
        ? null
        : config.message ?? spec.message;
  }
}
