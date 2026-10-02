import 'package:flutter/material.dart';

import '../forms/lab_conditions.dart';
import '../forms/lab_controller.dart';
import '../forms/lab_localization.dart';
import '../forms/lab_multistep.dart';
import '../forms/lab_presets.dart';
import '../forms/lab_theme.dart';
import '../forms/lab_typed.dart';
import '../forms/lab_validators.dart';
import '../form_page.dart';
import '../widgets/demo_widgets.dart';

/// Labs for every form feature that is not a field type: validation,
/// conditions, localization, the controller API, theming, typed configs and
/// extendable / multi-step forms.
final List<DemoEntry> formLabDemos = [
  DemoEntry(
    icon: Icons.rule,
    title: 'Validators lab',
    subtitle: 'All 16 ValidatorTypes, custom and registered validators',
    builder: (_) => const ValidatorsLabPage(),
  ),
  DemoEntry(
    icon: Icons.account_tree_outlined,
    title: 'Conditional logic lab',
    subtitle: 'Every ConditionOperator, and/or/not, dependsOn',
    builder: (_) => const ConditionsLabPage(),
  ),
  DemoEntry(
    icon: Icons.translate,
    title: 'Localization lab',
    subtitle: 'en, hi, ar (RTL), es, fr, de plus a custom language',
    builder: (_) => const LocalizationLabPage(),
  ),
  DemoEntry(
    icon: Icons.tune,
    title: 'Controller playground',
    subtitle: 'Every DynamicFormController method with a live log',
    builder: (_) => const ControllerLabPage(),
  ),
  DemoEntry(
    icon: Icons.brush_outlined,
    title: 'Theme and customization lab',
    subtitle: 'DynamicFormTheme, overrides, style keys, field enums',
    builder: (_) => const ThemeLabPage(),
  ),
  DemoEntry(
    icon: Icons.data_object,
    title: 'Typed config and async options',
    subtitle: 'FormConfig in Dart, FormEnumRegistry, OptionItem, loaders',
    builder: (_) => const TypedLabPage(),
  ),
  DemoEntry(
    icon: Icons.linear_scale,
    title: 'Multi-step and extendable',
    subtitle: 'MultiStepForm, nested repeaters, edit mode, layout hooks',
    builder: (_) => const MultiStepLabPage(),
  ),
  DemoEntry(
    icon: Icons.badge_outlined,
    title: 'Text presets',
    subtitle: 'PAN, Aadhaar, GST, mobile, name, IFSC… plus custom presets',
    builder: (_) {
      registerLabPresets();
      return const FormPage(title: 'Text presets', json: textPresetsLabForm);
    },
  ),
];
