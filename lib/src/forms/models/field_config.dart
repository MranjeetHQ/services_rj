import 'package:flutter/services.dart' show TextInputAction;
import 'package:flutter/widgets.dart';

import 'condition.dart';
import 'field_enums.dart';
import 'field_style.dart';
import 'field_type.dart';
import 'option_item.dart';
import 'validator_config.dart';

/// Async loader signature for dynamic options (remote APIs, databases…).
///
/// Receives the field id and the current form data so dependent lookups
/// (state list depending on selected country) are possible.
typedef OptionsLoader =
    Future<List<OptionItem>> Function(
      String fieldId,
      Map<String, dynamic> formData,
    );

/// Immutable configuration of a single form field, parsed from JSON or
/// built in Dart with typed enums:
///
/// ```dart
/// FieldConfig(
///   id: 'plan',
///   type: FieldType.radioGroup,
///   label: 'Plan',
///   enumName: 'Plan',              // options from FormEnumRegistry
///   optionLayout: OptionLayout.horizontal,
///   validators: [ValidatorConfig.required()],
/// )
/// ```
class FieldConfig {
  /// Creates a field configuration.
  const FieldConfig({
    required this.id,
    required this.type,
    this.name,
    this.label,
    this.hint,
    this.helperText,
    this.tooltip,
    this.initialValue,
    this.defaultValue,
    this.required = false,
    this.enabled = true,
    this.readOnly = false,
    this.visible = true,
    this.autofocus = false,
    this.obscureText = false,
    this.maxLength,
    this.minLength,
    this.maxLines,
    this.minLines,
    this.showCounter = false,
    this.regex,
    this.preset,
    this.presetMessage,
    this.keyboardType,
    this.textInputAction,
    this.textCase,
    this.prefixIcon,
    this.suffixIcon,
    this.prefixText,
    this.suffixText,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.validators = const [],
    this.options = const [],
    this.optionsUrl,
    this.enumName,
    this.optionLayout,
    this.columns,
    this.allowCustomOptions = false,
    this.customOptionLabel,
    this.dependsOn = const [],
    this.visibleWhen,
    this.enabledWhen,
    this.requiredWhen,
    this.fields = const [],
    this.minItems,
    this.maxItems,
    this.initialItems,
    this.addLabel,
    this.itemLabel,
    this.reorderable = false,
    this.styleConfig,
    this.extra = const {},
  });

  /// Parses a field (and recursively its children) from JSON.
  factory FieldConfig.fromJson(Map<String, dynamic> json) {
    Condition? cond(Object? raw) =>
        raw is Map ? Condition.fromJson(Map<String, dynamic>.from(raw)) : null;

    // `decoration` and `style` maps are merged into one style config
    // (style wins on conflicts).
    final styleRaw = <String, dynamic>{
      if (json['decoration'] is Map)
        ...Map<String, dynamic>.from(json['decoration'] as Map),
      if (json['style'] is Map)
        ...Map<String, dynamic>.from(json['style'] as Map),
    };

    final rawFields = (json['fields'] ?? json['itemFields']) as List?;
    final rawDepends = json['dependsOn'];

    return FieldConfig(
      id: json['id']?.toString() ?? json['key']?.toString() ?? '',
      name: json['name']?.toString(),
      type: FieldType.fromString(json['type']?.toString() ?? 'text'),
      label: json['label'] as String?,
      hint: json['hint'] as String?,
      helperText: json['helperText'] as String?,
      tooltip: json['tooltip'] as String?,
      initialValue: json['initialValue'],
      defaultValue: json['defaultValue'],
      required: json['required'] as bool? ?? false,
      enabled: json['enabled'] as bool? ?? true,
      readOnly: json['readOnly'] as bool? ?? false,
      visible: json['visible'] as bool? ?? true,
      autofocus: json['autofocus'] as bool? ?? false,
      obscureText: json['obscureText'] as bool? ?? false,
      maxLength: (json['maxLength'] as num?)?.toInt(),
      minLength: (json['minLength'] as num?)?.toInt(),
      maxLines: ((json['maxLines'] ?? json['rows']) as num?)?.toInt(),
      minLines: (json['minLines'] as num?)?.toInt(),
      showCounter: json['showCounter'] as bool? ?? false,
      regex: json['regex'] as String?,
      preset: json['preset']?.toString(),
      presetMessage: json['presetMessage'] as String?,
      keyboardType: KeyboardKind.fromString(json['keyboardType']),
      textInputAction: InputActionKind.fromString(json['textInputAction']),
      textCase: TextCase.fromString(json['textCase']),
      prefixIcon: json['prefixIcon'] as String?,
      suffixIcon: json['suffixIcon'] as String?,
      prefixText: json['prefixText'] as String?,
      suffixText: json['suffixText'] as String?,
      padding: FieldStyleConfig.parseEdgeInsets(json['padding']),
      margin: FieldStyleConfig.parseEdgeInsets(json['margin']),
      width: (json['width'] as num?)?.toDouble(),
      height: (json['height'] as num?)?.toDouble(),
      validators: (json['validators'] as List? ?? const [])
          .map(ValidatorConfig.fromJson)
          .toList(),
      options: ((json['items'] ?? json['options']) as List? ?? const [])
          .map(OptionItem.fromJson)
          .toList(),
      optionsUrl: json['optionsUrl'] as String?,
      enumName: (json['enum'] ?? json['enumName']) as String?,
      optionLayout: OptionLayout.fromString(
        json['optionLayout'] ?? json['layout'],
      ),
      columns: (json['columns'] as num?)?.toInt(),
      allowCustomOptions:
          json['allowCustomOptions'] as bool? ??
          json['allowCustom'] as bool? ??
          false,
      customOptionLabel: json['customOptionLabel'] as String?,
      dependsOn: rawDepends is List
          ? [for (final d in rawDepends) d.toString()]
          : rawDepends is String
          ? [rawDepends]
          : const [],
      visibleWhen: cond(json['visibleWhen']),
      enabledWhen: cond(json['enabledWhen']),
      requiredWhen: cond(json['requiredWhen']),
      fields: (rawFields ?? const [])
          .map((e) => FieldConfig.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      minItems: (json['minItems'] as num?)?.toInt(),
      maxItems: (json['maxItems'] as num?)?.toInt(),
      initialItems: (json['initialItems'] as num?)?.toInt(),
      addLabel: json['addLabel'] as String?,
      itemLabel: json['itemLabel'] as String?,
      reorderable: json['reorderable'] as bool? ?? false,
      styleConfig: styleRaw.isEmpty
          ? null
          : FieldStyleConfig.fromJson(styleRaw),
      extra: Map<String, dynamic>.from(json)
        ..removeWhere((k, _) => knownKeys.contains(k)),
    );
  }

  /// Every JSON key [FieldConfig.fromJson] maps to a typed property. Any
  /// other key lands in [extra] (type-specific settings such as `min`,
  /// `max`, `divisions`, `multiple`, `source`…).
  static const Set<String> knownKeys = {
    'style',
    'decoration',
    'id',
    'key',
    'name',
    'type',
    'label',
    'hint',
    'helperText',
    'tooltip',
    'initialValue',
    'defaultValue',
    'required',
    'enabled',
    'readOnly',
    'visible',
    'autofocus',
    'obscureText',
    'maxLength',
    'minLength',
    'maxLines',
    'rows',
    'minLines',
    'showCounter',
    'regex',
    'preset',
    'presetMessage',
    'keyboardType',
    'textInputAction',
    'textCase',
    'prefixIcon',
    'suffixIcon',
    'prefixText',
    'suffixText',
    'padding',
    'margin',
    'width',
    'height',
    'validators',
    'items',
    'options',
    'optionsUrl',
    'enum',
    'enumName',
    'optionLayout',
    'layout',
    'columns',
    'allowCustomOptions',
    'allowCustom',
    'customOptionLabel',
    'dependsOn',
    'visibleWhen',
    'enabledWhen',
    'requiredWhen',
    'fields',
    'itemFields',
    'minItems',
    'maxItems',
    'initialItems',
    'addLabel',
    'itemLabel',
    'reorderable',
  };

  /// Unique field id — the key used in form data and the controller API.
  final String id;

  /// Optional form-submission name (defaults to [id]).
  final String? name;

  /// Rendered field type.
  final FieldType type;

  /// Floating label text.
  final String? label;

  /// Placeholder hint.
  final String? hint;

  /// Helper text under the field.
  final String? helperText;

  /// Tooltip shown on long-press / hover.
  final String? tooltip;

  /// Value shown when the form first builds (wins over [defaultValue]).
  final Object? initialValue;

  /// Value restored on [DynamicFormController.reset] when no initial
  /// value exists.
  final Object? defaultValue;

  /// Statically required (see also [requiredWhen]).
  final bool required;

  /// Statically enabled (see also [enabledWhen]).
  final bool enabled;

  /// Read-only rendering.
  final bool readOnly;

  /// Statically visible (see also [visibleWhen]).
  final bool visible;

  /// Autofocus on build.
  final bool autofocus;

  /// Obscure input (defaults to true for password/pin types).
  final bool obscureText;

  /// Maximum input length.
  final int? maxLength;

  /// Minimum input length (validated).
  final int? minLength;

  /// Maximum visible lines (JSON `maxLines` or `rows`; textarea default 4).
  final int? maxLines;

  /// Minimum visible lines for multiline fields.
  final int? minLines;

  /// Show the `12 / 140` character counter when [maxLength] is set.
  final bool showCounter;

  /// Regex pattern (validator shorthand).
  final String? regex;

  /// Text preset name (a `TextPreset` or one added with
  /// `TextPresets.register`): keyboard, allowed characters, case, length and
  /// a format check such as PAN, Aadhaar or GST.
  final String? preset;

  /// Error shown when the [preset] check (or, for `custom`, the [regex])
  /// fails. Defaults to the preset's own message.
  final String? presetMessage;

  /// Keyboard to show (falls back per field type).
  final KeyboardKind? keyboardType;

  /// [textInputAction] as a Flutter [TextInputAction].
  TextInputAction? get flutterInputAction => switch (textInputAction) {
    InputActionKind.next => TextInputAction.next,
    InputActionKind.done => TextInputAction.done,
    InputActionKind.search => TextInputAction.search,
    InputActionKind.send => TextInputAction.send,
    InputActionKind.go => TextInputAction.go,
    InputActionKind.newline => TextInputAction.newline,
    null => null,
  };

  /// Keyboard action button name.
  final InputActionKind? textInputAction;

  /// Letter-case handling for typed text.
  final TextCase? textCase;

  /// Material icon name for the prefix icon.
  final String? prefixIcon;

  /// Material icon name for the suffix icon.
  final String? suffixIcon;

  /// Fixed text before the input (`₹`, `+91`).
  final String? prefixText;

  /// Fixed text after the input (`kg`, `.com`).
  final String? suffixText;

  /// Inner padding around the field.
  final EdgeInsets? padding;

  /// Outer margin around the field.
  final EdgeInsets? margin;

  /// Fixed width.
  final double? width;

  /// Fixed height.
  final double? height;

  /// JSON-configured validators.
  final List<ValidatorConfig> validators;

  /// Static options for selection fields.
  final List<OptionItem> options;

  /// Remote options URL (resolved by the app's registered [OptionsLoader]).
  final String? optionsUrl;

  /// Name of an enum registered with `FormEnumRegistry`; its values become
  /// the options when [options] is empty.
  final String? enumName;

  /// Layout of radio / checkbox group and chip options.
  final OptionLayout? optionLayout;

  /// Column count for [OptionLayout.grid].
  final int? columns;

  /// Lets users add their own option ("Other…") at runtime.
  final bool allowCustomOptions;

  /// Label of the add-option affordance (default: localized "Add option").
  final String? customOptionLabel;

  /// Field ids whose change clears this field and reloads its options.
  final List<String> dependsOn;

  /// Condition controlling visibility.
  final Condition? visibleWhen;

  /// Condition controlling enablement.
  final Condition? enabledWhen;

  /// Condition controlling required-ness.
  final Condition? requiredWhen;

  /// Child fields (group, expansion, steps, repeater entry template).
  final List<FieldConfig> fields;

  /// Minimum entries (repeater) or selections (multi-select fields).
  final int? minItems;

  /// Maximum entries (repeater) or selections (multi-select fields).
  final int? maxItems;

  /// Repeater entries created for a new (empty) form. Defaults to
  /// [minItems], or 1 when no minimum is set.
  final int? initialItems;

  /// Repeater "add entry" button label.
  final String? addLabel;

  /// Repeater entry title; `{index}` is replaced with the 1-based position.
  final String? itemLabel;

  /// Show move-up / move-down controls on repeater entries.
  final bool reorderable;

  /// Per-field appearance override (parsed from `style` / `decoration`).
  final FieldStyleConfig? styleConfig;

  /// Type-specific extras (min, max, divisions, length, colors…).
  final Map<String, dynamic> extra;

  /// Convenience typed accessor into [extra].
  T? ex<T>(String key) {
    final v = extra[key];
    if (v is T) return v;
    if (T == double && v is num) return v.toDouble() as T;
    if (T == int && v is num) return v.toInt() as T;
    return null;
  }

  /// Serializes this field back to JSON — useful when forms are built in
  /// Dart and stored or sent to a server.
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    if (name != null) 'name': name,
    if (label != null) 'label': label,
    if (hint != null) 'hint': hint,
    if (helperText != null) 'helperText': helperText,
    if (tooltip != null) 'tooltip': tooltip,
    if (initialValue != null) 'initialValue': initialValue,
    if (defaultValue != null) 'defaultValue': defaultValue,
    if (required) 'required': true,
    if (!enabled) 'enabled': false,
    if (readOnly) 'readOnly': true,
    if (!visible) 'visible': false,
    if (autofocus) 'autofocus': true,
    if (obscureText) 'obscureText': true,
    if (maxLength != null) 'maxLength': maxLength,
    if (minLength != null) 'minLength': minLength,
    if (maxLines != null) 'maxLines': maxLines,
    if (minLines != null) 'minLines': minLines,
    if (showCounter) 'showCounter': true,
    if (regex != null) 'regex': regex,
    if (preset != null) 'preset': preset,
    if (presetMessage != null) 'presetMessage': presetMessage,
    if (keyboardType != null) 'keyboardType': keyboardType!.name,
    if (textInputAction != null) 'textInputAction': textInputAction!.name,
    if (textCase != null) 'textCase': textCase!.name,
    if (prefixIcon != null) 'prefixIcon': prefixIcon,
    if (suffixIcon != null) 'suffixIcon': suffixIcon,
    if (prefixText != null) 'prefixText': prefixText,
    if (suffixText != null) 'suffixText': suffixText,
    if (padding != null) 'padding': FieldStyleConfig.edgeInsetsToJson(padding!),
    if (margin != null) 'margin': FieldStyleConfig.edgeInsetsToJson(margin!),
    if (width != null) 'width': width,
    if (height != null) 'height': height,
    if (validators.isNotEmpty)
      'validators': [for (final v in validators) v.toJson()],
    if (options.isNotEmpty) 'options': [for (final o in options) o.toJson()],
    if (optionsUrl != null) 'optionsUrl': optionsUrl,
    if (enumName != null) 'enum': enumName,
    if (optionLayout != null) 'optionLayout': optionLayout!.name,
    if (columns != null) 'columns': columns,
    if (allowCustomOptions) 'allowCustomOptions': true,
    if (customOptionLabel != null) 'customOptionLabel': customOptionLabel,
    if (dependsOn.isNotEmpty) 'dependsOn': dependsOn,
    if (visibleWhen != null) 'visibleWhen': visibleWhen!.toJson(),
    if (enabledWhen != null) 'enabledWhen': enabledWhen!.toJson(),
    if (requiredWhen != null) 'requiredWhen': requiredWhen!.toJson(),
    if (fields.isNotEmpty) 'fields': [for (final f in fields) f.toJson()],
    if (minItems != null) 'minItems': minItems,
    if (maxItems != null) 'maxItems': maxItems,
    if (initialItems != null) 'initialItems': initialItems,
    if (addLabel != null) 'addLabel': addLabel,
    if (itemLabel != null) 'itemLabel': itemLabel,
    if (reorderable) 'reorderable': true,
    if (styleConfig != null && styleConfig!.isNotEmpty)
      'style': styleConfig!.toJson(),
    ...extra,
  };

  /// Copies this config overriding selected properties.
  FieldConfig copyWith({
    String? label,
    String? hint,
    String? helperText,
    bool? required,
    bool? enabled,
    bool? readOnly,
    bool? visible,
    List<OptionItem>? options,
    List<ValidatorConfig>? validators,
    List<FieldConfig>? fields,
    OptionLayout? optionLayout,
    bool? allowCustomOptions,
    int? minItems,
    int? maxItems,
    FieldStyleConfig? styleConfig,
    Map<String, dynamic>? extra,
  }) => FieldConfig(
    id: id,
    name: name,
    type: type,
    label: label ?? this.label,
    hint: hint ?? this.hint,
    helperText: helperText ?? this.helperText,
    tooltip: tooltip,
    initialValue: initialValue,
    defaultValue: defaultValue,
    required: required ?? this.required,
    enabled: enabled ?? this.enabled,
    readOnly: readOnly ?? this.readOnly,
    visible: visible ?? this.visible,
    autofocus: autofocus,
    obscureText: obscureText,
    maxLength: maxLength,
    minLength: minLength,
    maxLines: maxLines,
    minLines: minLines,
    showCounter: showCounter,
    regex: regex,
    preset: preset,
    presetMessage: presetMessage,
    keyboardType: keyboardType,
    textInputAction: textInputAction,
    textCase: textCase,
    prefixIcon: prefixIcon,
    suffixIcon: suffixIcon,
    prefixText: prefixText,
    suffixText: suffixText,
    padding: padding,
    margin: margin,
    width: width,
    height: height,
    validators: validators ?? this.validators,
    options: options ?? this.options,
    optionsUrl: optionsUrl,
    enumName: enumName,
    optionLayout: optionLayout ?? this.optionLayout,
    columns: columns,
    allowCustomOptions: allowCustomOptions ?? this.allowCustomOptions,
    customOptionLabel: customOptionLabel,
    dependsOn: dependsOn,
    visibleWhen: visibleWhen,
    enabledWhen: enabledWhen,
    requiredWhen: requiredWhen,
    fields: fields ?? this.fields,
    minItems: minItems ?? this.minItems,
    maxItems: maxItems ?? this.maxItems,
    initialItems: initialItems,
    addLabel: addLabel,
    itemLabel: itemLabel,
    reorderable: reorderable,
    styleConfig: styleConfig ?? this.styleConfig,
    extra: extra ?? this.extra,
  );
}
