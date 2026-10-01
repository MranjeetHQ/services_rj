import 'field_config.dart';
import 'field_style.dart';

/// One step of a multi-step / wizard form.
class FormStep {
  /// Creates a step.
  const FormStep({required this.title, this.subtitle, required this.fields});

  /// Parses a step from JSON.
  factory FormStep.fromJson(Map<String, dynamic> json) => FormStep(
    title: json['title']?.toString() ?? '',
    subtitle: json['subtitle'] as String?,
    fields: (json['fields'] as List? ?? const [])
        .map((e) => FieldConfig.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(),
  );

  /// Step title.
  final String title;

  /// Optional subtitle.
  final String? subtitle;

  /// Fields inside this step.
  final List<FieldConfig> fields;

  /// Serializes back to JSON.
  Map<String, dynamic> toJson() => {
    'title': title,
    if (subtitle != null) 'subtitle': subtitle,
    'fields': [for (final f in fields) f.toJson()],
  };
}

/// Root configuration of a form, parsed from JSON.
class FormConfig {
  /// Creates a form configuration.
  const FormConfig({
    this.id = '',
    this.title,
    this.description,
    this.fields = const [],
    this.steps = const [],
    this.style,
    this.confirmDiscard = false,
    this.discardTitle,
    this.discardMessage,
    this.initialData = const {},
  });

  /// Parses a form from JSON.
  factory FormConfig.fromJson(Map<String, dynamic> json) => FormConfig(
    id: json['id']?.toString() ?? '',
    title: json['title'] as String?,
    description: json['description'] as String?,
    fields: (json['fields'] as List? ?? const [])
        .map((e) => FieldConfig.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(),
    steps: (json['steps'] as List? ?? const [])
        .map((e) => FormStep.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(),
    style: json['style'] is Map
        ? FieldStyleConfig.fromJson(
            Map<String, dynamic>.from(json['style'] as Map),
          )
        : null,
    confirmDiscard: json['confirmDiscard'] as bool? ?? false,
    discardTitle: json['discardTitle'] as String?,
    discardMessage: json['discardMessage'] as String?,
    initialData: Map<String, dynamic>.from(
      (json['data'] ?? json['initialData']) as Map? ?? const {},
    ),
  );

  /// Form id.
  final String id;

  /// Form title.
  final String? title;

  /// Form description.
  final String? description;

  /// Flat fields (single-page form).
  final List<FieldConfig> fields;

  /// Steps (multi-step / wizard form). When non-empty, [fields] is ignored
  /// by [DynamicForm] and the step fields are flattened into the controller.
  final List<FormStep> steps;

  /// Form-wide field appearance (`"style": {"variant": "rounded", ...}`),
  /// overridable per field.
  final FieldStyleConfig? style;

  /// When true, navigating back with unsaved changes shows a confirmation
  /// dialog (`"confirmDiscard": true`). Off by default.
  final bool confirmDiscard;

  /// Custom title for the discard dialog (falls back to localized default).
  final String? discardTitle;

  /// Custom message for the discard dialog.
  final String? discardMessage;

  /// Prefill record for edit-mode forms, from the JSON root `"data"` (or
  /// `"initialData"`) map: field id → value. Lets the server ship the form
  /// definition and the record being edited in one payload.
  final Map<String, dynamic> initialData;

  /// All fields across steps and the flat list.
  List<FieldConfig> get allFields =>
      steps.isEmpty ? fields : [for (final s in steps) ...s.fields];

  /// Serializes back to JSON (round-trips through [FormConfig.fromJson]).
  Map<String, dynamic> toJson() => {
    if (id.isNotEmpty) 'id': id,
    if (title != null) 'title': title,
    if (description != null) 'description': description,
    if (fields.isNotEmpty) 'fields': [for (final f in fields) f.toJson()],
    if (steps.isNotEmpty) 'steps': [for (final s in steps) s.toJson()],
    if (style != null && style!.isNotEmpty) 'style': style!.toJson(),
    if (confirmDiscard) 'confirmDiscard': true,
    if (discardTitle != null) 'discardTitle': discardTitle,
    if (discardMessage != null) 'discardMessage': discardMessage,
    if (initialData.isNotEmpty) 'data': initialData,
  };
}
