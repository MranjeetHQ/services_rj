/// JSON-driven dynamic forms for Flutter.
///
/// Builds validated, conditional, multi-step and repeatable forms from JSON
/// (or from typed Dart configs that use enums instead of strings).
///
/// Ported from json_form_engine by Rupesh Rajak (MIT License,
/// https://github.com/rupeshrajak0285/json_form_engine) and extended with
/// enum-driven options, repeatable sections, user-addable options and
/// per-field overrides.
library;

export 'src/forms/builders/field_factory.dart';
export 'src/forms/conditions/condition_evaluator.dart';
export 'src/forms/controllers/dynamic_form_controller.dart';
export 'src/forms/controllers/field_state.dart';
export 'src/forms/extensions/controller_extensions.dart';
export 'src/forms/fields/date_time_fields.dart';
export 'src/forms/fields/media_fields.dart';
export 'src/forms/fields/misc_fields.dart';
export 'src/forms/fields/repeater_field.dart';
export 'src/forms/fields/selection_fields.dart';
export 'src/forms/fields/slider_fields.dart';
export 'src/forms/fields/text_fields.dart';
export 'src/forms/localization/form_localizations.dart';
export 'src/forms/models/condition.dart';
export 'src/forms/models/country_dial_code.dart';
export 'src/forms/models/field_config.dart';
export 'src/forms/models/field_enums.dart';
export 'src/forms/models/field_overrides.dart';
export 'src/forms/models/field_style.dart';
export 'src/forms/models/field_type.dart';
export 'src/forms/models/form_config.dart';
export 'src/forms/models/form_enum_registry.dart';
export 'src/forms/models/option_item.dart';
export 'src/forms/models/text_preset.dart';
export 'src/forms/models/validator_config.dart';
export 'src/forms/parser/form_parser.dart';
export 'src/forms/theme/dynamic_form_theme.dart';
export 'src/forms/utils/field_utils.dart';
export 'src/forms/validators/field_validator.dart';
export 'src/forms/validators/validator_registry.dart';
export 'src/forms/widgets/dynamic_form.dart';
export 'src/forms/widgets/field_wrapper.dart';
export 'src/forms/widgets/multi_step_form.dart';
