import '../models/validator_config.dart';
import 'field_validator.dart';

/// Factory + registry turning [ValidatorConfig] JSON into [FieldValidator]
/// strategies. Register your own named validators for use from JSON:
///
/// ```dart
/// ValidatorRegistry.register('gstin', (cfg) => CustomValidator(cfg,
///     (v, _) => isValidGstin(v?.toString()) ? null : 'Invalid GSTIN'));
/// ```
class ValidatorRegistry {
  const ValidatorRegistry._();

  static final Map<String, FieldValidator Function(ValidatorConfig)>
  _factories = {
    'required': RequiredValidator.new,
    'email': EmailValidator.new,
    'phone': PhoneValidator.new,
    'url': UrlValidator.new,
    'number': NumberValidator.new,
    'decimal': DecimalValidator.new,
    'min': MinValidator.new,
    'max': MaxValidator.new,
    'minLength': MinLengthValidator.new,
    'maxLength': MaxLengthValidator.new,
    'regex': RegexValidator.new,
    'pattern': RegexValidator.new,
    'matchField': MatchFieldValidator.new,
    'match': MatchFieldValidator.new,
    'passwordStrength': PasswordStrengthValidator.new,
    'minItems': MinItemsValidator.new,
    'maxItems': MaxItemsValidator.new,
    'preset': PresetValidator.new,
  };

  /// Registers (or overrides) a validator factory usable from JSON by name.
  static void register(
    String type,
    FieldValidator Function(ValidatorConfig) factory,
  ) => _factories[type] = factory;

  /// Whether a validator named [type] is available.
  static bool isRegistered(String type) => _factories.containsKey(type);

  /// Names of every registered validator (built-in and custom).
  static Iterable<String> get names => _factories.keys;

  /// Builds a validator from config; unknown types return `null` and are
  /// skipped (logged via assert in debug mode).
  static FieldValidator? build(ValidatorConfig config) {
    final factory = _factories[config.type];
    assert(
      factory != null || config.type == 'custom',
      'Unknown validator type "${config.type}". Register it first.',
    );
    return factory?.call(config);
  }
}
