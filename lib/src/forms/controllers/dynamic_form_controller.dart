import 'package:flutter/widgets.dart';
import '../conditions/condition_evaluator.dart';
import '../localization/form_localizations.dart';
import '../models/country_dial_code.dart';
import '../models/field_config.dart';
import '../models/field_enums.dart';
import '../models/field_overrides.dart';
import '../models/field_type.dart';
import '../models/form_config.dart';
import '../models/option_item.dart';
import '../models/text_preset.dart';
import '../models/validator_config.dart';
import '../utils/field_utils.dart';
import '../validators/field_validator.dart';
import '../validators/validator_registry.dart';
import 'field_state.dart';

/// Controls a [DynamicForm]: values, validation, visibility, focus and
/// runtime mutation of the field list — analogous to a
/// [TextEditingController] but for the whole form.
///
/// The controller works standalone (no widget required) which makes it easy
/// to drive from Provider, Riverpod, Bloc or GetX.
class DynamicFormController extends ChangeNotifier {
  /// Creates a controller.
  ///
  /// [locale] selects built-in validation messages (`en`, `hi`, `ar`, `es`,
  /// `fr`, `de`). [optionsLoader] resolves `optionsUrl` / async options.
  DynamicFormController({
    String locale = 'en',
    this.optionsLoader,
    this.phoneFormat = PhoneFormat.combined,
    Map<String, CustomValidatorFn> customValidators = const {},
  }) : l10n = FormLocalizations(locale),
       _customValidators = Map.of(customValidators);

  /// How phone fields with a country code picker appear in
  /// [getFormData], `onChanged` and `onSubmit`: one `+919876543210` value
  /// ([PhoneFormat.combined], default) or the number and its code under two
  /// keys ([PhoneFormat.separate]). A field's own `phoneFormat` key wins over
  /// this, and [getFormData]'s `phoneFormat` argument wins over both.
  final PhoneFormat phoneFormat;

  /// Localized messages used by validators.
  final FormLocalizations l10n;

  /// Code-level customization per field id (see [FieldOverrides]).
  /// Usually set through `DynamicForm.fieldOverrides`.
  Map<String, FieldOverrides> fieldOverrides = const {};

  /// Code-level customization per field type.
  Map<FieldType, FieldOverrides> typeOverrides = const {};

  /// Effective overrides for [field] (type overrides, then id overrides).
  FieldOverrides? overridesFor(FieldConfig field) {
    // Repeater entries follow their parent form's overrides.
    final parent = _parent;
    if (parent != null) return parent.overridesFor(field);
    final byType = typeOverrides[field.type];
    final byId = fieldOverrides[field.id];
    if (byType == null) return byId;
    return byType.merge(byId);
  }

  /// Async loader for dynamic options.
  final OptionsLoader? optionsLoader;

  final Map<String, CustomValidatorFn> _customValidators;
  final Map<String, FieldRuntimeState> _states = {};
  final List<String> _order = [];

  /// Bumped whenever the *structure* changes (field added/removed, form
  /// attached). The [DynamicForm] listens to this — value changes never
  /// rebuild the whole list.
  final ValueNotifier<int> structureRevision = ValueNotifier<int>(0);

  /// Whether the form has unsaved changes relative to the last clean state
  /// (attach, [reset], [markClean] or a successful [submit]).
  final ValueNotifier<bool> dirty = ValueNotifier<bool>(false);

  Map<String, Object?> _cleanSnapshot = {};

  FormConfig? _config;
  bool _disposed = false;

  /// Called by [DynamicFormController.submit] after successful validation.
  void Function(Map<String, dynamic> data)? onSubmit;

  /// Called when any value changes.
  void Function(String fieldId, Object? value, Map<String, dynamic> data)?
  onChanged;

  /// Called after every [validate] with the current error map.
  void Function(Map<String, String> errors)? onValidation;

  /// Called when [submit] fails validation.
  void Function(Map<String, String> errors)? onError;

  /// Called when a field is added at runtime.
  void Function(FieldConfig field)? onFieldAdded;

  /// Called when a field is removed at runtime.
  void Function(String fieldId)? onFieldRemoved;

  /// Called when an option is added at runtime — by the user through
  /// `"allowCustomOptions"` or by [addOption]. Persist it here if needed.
  void Function(String fieldId, OptionItem option)? onOptionAdded;

  /// The attached form configuration.
  FormConfig? get config => _config;

  /// Field ids in render order.
  List<String> get fieldOrder => List.unmodifiable(_order);

  /// Runtime state for [id] (throws if unknown).
  FieldRuntimeState state(String id) {
    final s = _states[id];
    if (s == null) {
      throw ArgumentError(
        'Unknown field id "$id". Known: ${_order.join(', ')}',
      );
    }
    return s;
  }

  /// Whether [id] exists.
  bool hasField(String id) => _states.containsKey(id);

  // ---------------------------------------------------------------- attach

  /// Prefill record for edit-mode forms: field id → value. Merged from the
  /// JSON root `"data"` map and the `initialData` given to [attach] /
  /// [DynamicForm]. [reset] restores these values, and they form the clean
  /// baseline for dirty tracking (an untouched edit form is NOT dirty).
  Map<String, dynamic> get initialData => Map.unmodifiable(_initialData);
  Map<String, dynamic> _initialData = {};

  Object? _initialFor(FieldConfig config) {
    if (!_initialData.containsKey(config.id)) {
      return config.initialValue ?? config.defaultValue;
    }
    final value = _initialData[config.id];
    // Records may hold a phone as separate number + country code keys.
    return FieldUtils.hasCountryCode(config)
        ? _joinPhone(value, _initialData[FieldUtils.countryCodeKey(config)])
        : value;
  }

  /// `+<code><digits>` from a national [number] and a country [code]; the
  /// number unchanged when it already carries a code or there is none.
  static Object? _joinPhone(Object? number, Object? code) {
    final n = number?.toString();
    final c = code?.toString().trim();
    if (n == null || n.isEmpty || c == null || c.isEmpty) return number;
    if (n.trim().startsWith('+')) return number;
    final dial =
        CountryDialCodes.lookup(c)?.dial ?? (c.startsWith('+') ? c : '+$c');
    final digits = n.replaceAll(RegExp(r'[^\d]'), '');
    return digits.isEmpty ? null : '$dial$digits';
  }

  /// Attaches a parsed form, optionally prefilled with [initialData] (an
  /// existing record for edit mode). Safe to call again with new JSON —
  /// values *and* the dirty baseline of surviving field ids are preserved
  /// unless [preserveValues] is false.
  void attach(
    FormConfig config, {
    bool preserveValues = true,
    Map<String, dynamic>? initialData,
  }) {
    final oldValues = <String, Object?>{
      if (preserveValues)
        for (final id in _order) id: _states[id]!.value.value,
    };
    final oldBaseline = preserveValues
        ? Map<String, Object?>.of(_cleanSnapshot)
        : const <String, Object?>{};
    for (final s in _states.values) {
      s.dispose();
    }
    _states.clear();
    _order.clear();
    _config = config;
    _initialData = {...config.initialData, ...?initialData};
    for (final field in _flatten(config.allFields)) {
      _register(field);
      final s = _states[field.id];
      if (s == null) continue;
      final initial = oldValues.containsKey(field.id)
          ? oldValues[field.id]
          : _initialFor(field);
      if (field.type == FieldType.repeater) {
        _buildEntries(s, initial);
      } else {
        s.value.value = normalizeValue(initial);
      }
    }
    _reevaluateConditions();
    _loadAsyncOptions();
    // Surviving fields keep their previous baseline so a runtime JSON change
    // (restyle, added field) never silently swallows the dirty state.
    _cleanSnapshot = {
      for (final id in _order)
        id: oldBaseline.containsKey(id)
            ? oldBaseline[id]
            : _states[id]!.value.value,
    };
    _updateDirty();
    structureRevision.value++;
    notifyListeners();
  }

  // ----------------------------------------------------------------- dirty

  /// True when any value differs from the last clean snapshot.
  bool get isDirty => dirty.value;

  /// Takes the current values as the new clean baseline (e.g. after saving
  /// a draft). Called automatically on attach, [reset] and successful
  /// [submit].
  void markClean() {
    _cleanSnapshot = _valuesSnapshot();
    dirty.value = false;
  }

  Map<String, Object?> _valuesSnapshot() => {
    for (final id in _order) id: _states[id]!.value.value,
  };

  void _updateDirty() =>
      dirty.value = !_deepEquals(_valuesSnapshot(), _cleanSnapshot);

  static bool _deepEquals(Object? a, Object? b) {
    if (identical(a, b)) return true;
    if (a is Map && b is Map) {
      if (a.length != b.length) return false;
      for (final key in a.keys) {
        if (!b.containsKey(key) || !_deepEquals(a[key], b[key])) return false;
      }
      return true;
    }
    if (a is List && b is List) {
      if (a.length != b.length) return false;
      for (var i = 0; i < a.length; i++) {
        if (!_deepEquals(a[i], b[i])) return false;
      }
      return true;
    }
    return a == b;
  }

  Iterable<FieldConfig> _flatten(List<FieldConfig> fields) sync* {
    for (final f in fields) {
      yield f;
      // Repeater children live in each entry's own controller.
      if (f.type == FieldType.expansion || f.type == FieldType.group) {
        // Children of groups keep their own ids in the flat state map so the
        // whole controller API works on nested fields too.
        yield* _flatten(f.fields);
      }
    }
  }

  void _register(FieldConfig field) {
    if (field.id.isEmpty) return;
    _states[field.id] = FieldRuntimeState(field);
    _order.add(field.id);
  }

  // ---------------------------------------------------------------- values

  /// Returns the current value of [id].
  Object? getValue(String id) => _states[id]?.value.value;

  /// Sets the value of [id], re-evaluates conditional logic and fires
  /// [onChanged]. Set [validate] to true to validate the field immediately.
  ///
  /// Enum values are stored by `name` (lists of enums as lists of names), so
  /// `setValue('plan', Plan.pro)` works for enum-backed fields. For a
  /// repeater, pass a `List<Map<String, dynamic>>` to replace every entry.
  void setValue(String id, Object? value, {bool validate = false}) {
    final s = state(id);
    value = normalizeValue(value);
    if (s.config.type == FieldType.repeater) {
      _buildEntries(s, value);
      _afterRepeaterChange(s);
      return;
    }
    if (_deepEquals(s.value.value, value)) return;
    s.value.value = value;
    if (validate) {
      validateField(id);
    } else if (s.error.value != null) {
      // Live re-validation once a field has shown an error.
      validateField(id);
    }
    _reevaluateConditions();
    _reloadDependentOptions(id);
    _updateDirty();
    onChanged?.call(id, value, getFormData());
    notifyListeners();
  }

  /// Clears the value and error of [id].
  void clearField(String id) {
    final s = state(id);
    if (s.config.type == FieldType.repeater) {
      _buildEntries(s, const <Object?>[]);
    } else {
      s.value.value = null;
    }
    s.error.value = null;
    _reevaluateConditions();
    _updateDirty();
    notifyListeners();
  }

  /// Resets every field to its pristine value — the prefilled record value
  /// in edit mode, otherwise the config initial/default — clears errors and
  /// marks the form clean.
  void reset() {
    for (final s in _states.values) {
      if (s.config.type == FieldType.repeater) {
        _buildEntries(s, _initialFor(s.config));
      } else {
        s.value.value = normalizeValue(_initialFor(s.config));
      }
      s.error.value = null;
    }
    _reevaluateConditions();
    markClean();
    notifyListeners();
  }

  /// Current form data for **visible** fields (hidden-type fields included;
  /// conditionally hidden fields excluded). Pass [includeHidden] for all.
  ///
  /// [phoneFormat] overrides how phone fields with a country code picker are
  /// reported (see [DynamicFormController.phoneFormat]); by default each
  /// field's `phoneFormat` key, else the controller's, decides.
  Map<String, dynamic> getFormData({
    bool includeHidden = false,
    PhoneFormat? phoneFormat,
  }) {
    final data = <String, dynamic>{};
    for (final id in _order) {
      final s = _states[id]!;
      if (!_isDataField(s.config.type)) continue;
      if (includeHidden ||
          s.visible.value ||
          s.config.type == FieldType.hidden) {
        final key = s.config.name ?? id;
        var value = s.value.value;
        if (s.config.type == FieldType.repeater && phoneFormat != null) {
          value = [
            for (final e in s.entries.value)
              e.controller.getFormData(
                includeHidden: includeHidden,
                phoneFormat: phoneFormat,
              ),
          ];
        }
        final format =
            phoneFormat ??
            PhoneFormat.fromString(s.config.ex<String>('phoneFormat')) ??
            this.phoneFormat;
        if (format == PhoneFormat.separate &&
            FieldUtils.hasCountryCode(s.config)) {
          final parts = CountryDialCodes.split(value?.toString());
          data[key] = value == null ? null : parts.national;
          data[FieldUtils.countryCodeKey(s.config)] = parts.dial;
        } else {
          data[key] = value;
        }
      }
    }
    return data;
  }

  /// Bulk-sets values from a map (keys are field ids).
  ///
  /// Pass `asInitial: true` when loading an existing record for editing:
  /// the data becomes the pristine baseline — the form stays clean (no
  /// discard dialog until the user actually edits) and [reset] restores it.
  void setFormData(Map<String, dynamic> data, {bool asInitial = false}) {
    // Phone fields may arrive as separate number + country code keys.
    data = {
      ...data,
      for (final s in _states.values)
        if (FieldUtils.hasCountryCode(s.config) &&
            data.containsKey(s.config.id))
          s.config.id: _joinPhone(
            data[s.config.id],
            data[FieldUtils.countryCodeKey(s.config)],
          ),
    };
    data.forEach((id, value) {
      final s = _states[id];
      if (s == null) return;
      if (s.config.type == FieldType.repeater) {
        _buildEntries(s, value);
      } else {
        s.value.value = normalizeValue(value);
      }
    });
    if (asInitial) _initialData = {..._initialData, ...data};
    _reevaluateConditions();
    if (asInitial) {
      markClean();
    } else {
      _updateDirty();
    }
    notifyListeners();
  }

  static bool _isDataField(FieldType t) => !const {
    FieldType.label,
    FieldType.divider,
    FieldType.spacer,
    FieldType.sectionHeader,
  }.contains(t);

  // ------------------------------------------------------------ validation

  List<FieldValidator> _validatorsFor(FieldRuntimeState s) {
    final list = <FieldValidator>[];
    if (s.required.value) {
      list.add(
        RequiredValidator(
          s.config.validators.where((v) => v.type == 'required').firstOrNull ??
              const ValidatorConfig(type: 'required'),
        ),
      );
    }
    for (final cfg in s.config.validators) {
      if (cfg.type == 'required') continue;
      if (cfg.type == 'custom') {
        final fn = _customValidators[cfg.params['name'] ?? cfg.value];
        if (fn != null) list.add(CustomValidator(cfg, fn));
        continue;
      }
      final v = ValidatorRegistry.build(cfg);
      if (v != null) list.add(v);
    }
    if (s.config.minLength != null) {
      list.add(MinLengthValidator(_cfg('minLength', s.config.minLength)));
    }
    if (s.config.maxLength != null) {
      list.add(MaxLengthValidator(_cfg('maxLength', s.config.maxLength)));
    }
    if (s.config.regex != null) {
      list.add(
        RegexValidator(
          ValidatorConfig(
            type: 'regex',
            value: s.config.regex,
            // For `preset: custom` the regex is the preset's rule.
            message: TextPreset.tryParse(s.config.preset) == TextPreset.custom
                ? s.config.presetMessage
                : null,
          ),
        ),
      );
    }
    if (s.config.preset != null &&
        TextPresets.resolve(s.config.preset) != null) {
      list.add(
        PresetValidator(
          ValidatorConfig(
            type: 'preset',
            value: s.config.preset,
            message: s.config.presetMessage,
          ),
        ),
      );
    }
    if (s.config.minItems != null) {
      list.add(MinItemsValidator(_cfg('minItems', s.config.minItems)));
    }
    if (s.config.maxItems != null) {
      list.add(MaxItemsValidator(_cfg('maxItems', s.config.maxItems)));
    }
    return list;
  }

  static ValidatorConfig _cfg(String type, Object? value) =>
      ValidatorConfig(type: type, value: value);

  /// Validates one field; returns its error (null = valid).
  String? validateField(String id) {
    final s = state(id);
    if (!s.visible.value || !s.enabled.value) {
      s.error.value = null;
      return null;
    }
    final data = getFormData(
      includeHidden: true,
      phoneFormat: PhoneFormat.combined,
    );
    String? error;
    for (final v in _validatorsFor(s)) {
      error = v.validate(s.value.value, data, l10n);
      if (error != null) break;
    }
    if (s.config.type == FieldType.repeater) {
      // Validate every entry so their own field errors show.
      var entriesValid = true;
      for (final e in s.entries.value) {
        if (!e.controller.validate()) entriesValid = false;
      }
      if (error == null && !entriesValid) {
        error = l10n.message('entriesInvalid');
      }
    }
    s.error.value = error;
    return error;
  }

  /// Validates all fields; returns true when the form is valid.
  bool validate() {
    var valid = true;
    for (final id in _order) {
      if (validateField(id) != null) valid = false;
    }
    onValidation?.call(getErrors());
    return valid;
  }

  /// Validates, then either fires [onSubmit] with the data (returning it)
  /// or fires [onError] and returns null.
  Map<String, dynamic>? submit() {
    if (!validate()) {
      onError?.call(getErrors());
      final firstError = _order
          .where((id) => _states[id]!.error.value != null)
          .firstOrNull;
      if (firstError != null) focusField(firstError);
      return null;
    }
    final data = getFormData();
    markClean();
    onSubmit?.call(data);
    return data;
  }

  /// Current error map (field id → message).
  Map<String, String> getErrors() => {
    for (final id in _order)
      if (_states[id]!.error.value != null) id: _states[id]!.error.value!,
  };

  /// Clears all validation errors.
  void clearErrors() {
    for (final s in _states.values) {
      s.error.value = null;
    }
  }

  // ------------------------------------------------- structure mutation

  /// Adds a field at runtime (optionally at [index] in render order).
  void addField(FieldConfig field, {int? index}) {
    if (_states.containsKey(field.id)) {
      removeField(field.id);
    }
    final added = FieldRuntimeState(field);
    _states[field.id] = added;
    if (field.type == FieldType.repeater) _buildEntries(added, null);
    _order.insert(index?.clamp(0, _order.length) ?? _order.length, field.id);
    _cleanSnapshot[field.id] = _states[field.id]!.value.value;
    _reevaluateConditions();
    _loadOptionsFor(field.id);
    structureRevision.value++;
    onFieldAdded?.call(field);
    notifyListeners();
  }

  /// Removes a field at runtime.
  void removeField(String id) {
    final s = _states.remove(id);
    if (s == null) return;
    _order.remove(id);
    _cleanSnapshot.remove(id);
    s.dispose();
    _updateDirty();
    structureRevision.value++;
    onFieldRemoved?.call(id);
    notifyListeners();
  }

  /// Hides [id] (dynamic visibility, wins until conditions re-evaluate it).
  void hideField(String id) => state(id).visible.value = false;

  /// Shows [id].
  void showField(String id) => state(id).visible.value = true;

  /// Enables [id].
  void enableField(String id) => state(id).enabled.value = true;

  /// Disables [id].
  void disableField(String id) => state(id).enabled.value = false;

  /// Marks [id] required / not required at runtime.
  void setRequired(String id, {required bool required}) =>
      state(id).required.value = required;

  /// Replaces the options of a selection field at runtime.
  void setOptions(String id, List<OptionItem> options) =>
      state(id).options.value = options;

  /// Appends [option] to a selection field (ignored when an option with the
  /// same value exists). Pass [select] to also select it. Fires
  /// [onOptionAdded].
  void addOption(String id, OptionItem option, {bool select = false}) {
    final s = state(id);
    final exists = s.options.value.any((o) => o.value == option.value);
    if (!exists) {
      s.options.value = [...s.options.value, option];
      onOptionAdded?.call(id, option);
    }
    if (!select) return;
    final current = s.value.value;
    if (current is List) {
      if (!current.contains(option.value)) {
        setValue(id, [...current, option.value]);
      }
    } else if (_isMultiValue(s.config)) {
      setValue(id, [option.value]);
    } else {
      setValue(id, option.value);
    }
  }

  /// Removes the option with [value] (and deselects it).
  void removeOption(String id, Object? value) {
    final s = state(id);
    s.options.value = [
      for (final o in s.options.value)
        if (o.value != value) o,
    ];
    final current = s.value.value;
    if (current is List && current.contains(value)) {
      setValue(id, [...current]..remove(value));
    } else if (current == value) {
      setValue(id, null);
    }
  }

  /// Options the user added at runtime through `"allowCustomOptions"`.
  List<OptionItem> customOptions(String id) =>
      state(id).options.value.where((o) => o.isCustom).toList();

  static bool _isMultiValue(FieldConfig f) =>
      f.type == FieldType.multiselect ||
      f.type == FieldType.checkboxGroup ||
      ((f.type == FieldType.chips || f.type == FieldType.segmented) &&
          (f.ex<bool>('multiple') ?? false));

  // ------------------------------------------------------------ repeater

  int _entrySeq = 0;

  /// Set on repeater-entry controllers.
  DynamicFormController? _parent;

  /// Entries of the repeater field [id].
  List<RepeaterEntry> entriesOf(String id) =>
      List.unmodifiable(state(id).entries.value);

  /// Whether another entry may be added to repeater [id].
  bool canAddEntry(String id) {
    final s = state(id);
    final max = s.config.maxItems;
    return s.enabled.value && (max == null || s.entries.value.length < max);
  }

  /// Whether an entry may be removed from repeater [id].
  bool canRemoveEntry(String id) {
    final s = state(id);
    final min = s.config.minItems ?? 0;
    return s.enabled.value && s.entries.value.length > min;
  }

  /// Adds an entry to repeater [id], optionally prefilled with [data].
  /// Returns null when `maxItems` is reached.
  RepeaterEntry? addEntry(String id, {Map<String, dynamic>? data}) {
    final s = state(id);
    if (!canAddEntry(id)) return null;
    final entry = _newEntry(s, data);
    s.entries.value = [...s.entries.value, entry];
    _afterRepeaterChange(s);
    return entry;
  }

  /// Removes the entry at [index] from repeater [id]. Returns false when
  /// `minItems` would be violated.
  bool removeEntry(String id, int index) {
    final s = state(id);
    if (!canRemoveEntry(id) || index < 0 || index >= s.entries.value.length) {
      return false;
    }
    final list = [...s.entries.value];
    final removed = list.removeAt(index);
    s.entries.value = list;
    removed.controller.dispose();
    _afterRepeaterChange(s);
    return true;
  }

  /// Moves an entry of repeater [id] from [from] to [to].
  void moveEntry(String id, int from, int to) {
    final s = state(id);
    final list = [...s.entries.value];
    if (from < 0 || from >= list.length) return;
    final entry = list.removeAt(from);
    list.insert(to.clamp(0, list.length), entry);
    s.entries.value = list;
    _afterRepeaterChange(s);
  }

  RepeaterEntry _newEntry(
    FieldRuntimeState parent,
    Map<String, dynamic>? data,
  ) {
    final child = DynamicFormController(
      locale: l10n.locale,
      optionsLoader: optionsLoader,
      phoneFormat: phoneFormat,
      customValidators: _customValidators,
    ).._parent = this;
    child.attach(
      FormConfig(
        id: '${parent.config.id}[]',
        fields: parent.config.fields,
        style: _config?.style,
      ),
      initialData: data ?? const {},
    );
    child.addListener(() => _syncRepeater(parent));
    return RepeaterEntry(_entrySeq++, child);
  }

  /// Replaces every entry of [s] from a list of maps (null → the default
  /// number of blank entries). Does not notify.
  void _buildEntries(FieldRuntimeState s, Object? raw) {
    for (final e in s.entries.value) {
      e.controller.dispose();
    }
    final List<Map<String, dynamic>?> seeds;
    if (raw is List) {
      seeds = [
        for (final item in raw)
          item is Map ? Map<String, dynamic>.from(item) : null,
      ];
    } else {
      final count = s.config.initialItems ?? s.config.minItems ?? 1;
      seeds = List.filled(count, null);
    }
    s.entries.value = [for (final seed in seeds) _newEntry(s, seed)];
    s.value.value = [for (final e in s.entries.value) e.data];
  }

  void _syncRepeater(FieldRuntimeState s) {
    if (_disposed || !_states.containsKey(s.config.id)) return;
    final data = [for (final e in s.entries.value) e.data];
    if (_deepEquals(data, s.value.value)) return;
    s.value.value = data;
    _afterRepeaterChange(s, synced: true);
  }

  void _afterRepeaterChange(FieldRuntimeState s, {bool synced = false}) {
    if (!synced) s.value.value = [for (final e in s.entries.value) e.data];
    if (s.error.value != null) validateField(s.config.id);
    _reevaluateConditions();
    _updateDirty();
    onChanged?.call(s.config.id, s.value.value, getFormData());
    notifyListeners();
  }

  /// Converts enums to their `name` (recursively in lists / sets) so form
  /// data stays JSON-serializable.
  static Object? normalizeValue(Object? value) => switch (value) {
    Enum e => e.name,
    Set<Object?> set => [for (final v in set) normalizeValue(v)],
    List<Object?> list when list.any((v) => v is Enum) => [
      for (final v in list) normalizeValue(v),
    ],
    _ => value,
  };

  // ---------------------------------------------------------------- focus

  /// Requests focus on [id].
  void focusField(String id) => state(id).focusNode.requestFocus();

  /// Removes focus from all fields.
  void unfocus() {
    for (final s in _states.values) {
      s.focusNode.unfocus();
    }
  }

  // ------------------------------------------------------------ listening

  /// Listens to changes of one field's value. Returns a cancel function.
  VoidCallback listen(String id, void Function(Object? value) listener) {
    final s = state(id);
    void wrapped() => listener(s.value.value);
    s.value.addListener(wrapped);
    return () => s.value.removeListener(wrapped);
  }

  // ----------------------------------------------------------- conditions

  void _reevaluateConditions() {
    final data = getFormData(
      includeHidden: true,
      phoneFormat: PhoneFormat.combined,
    );
    for (final s in _states.values) {
      final c = s.config;
      if (c.visibleWhen != null) {
        s.visible.value = ConditionEvaluator.evaluate(c.visibleWhen!, data);
      }
      if (c.enabledWhen != null) {
        s.enabled.value = ConditionEvaluator.evaluate(c.enabledWhen!, data);
      }
      if (c.requiredWhen != null) {
        s.required.value = ConditionEvaluator.evaluate(c.requiredWhen!, data);
      }
    }
  }

  // -------------------------------------------------------- async options

  void _loadAsyncOptions() {
    for (final id in _order) {
      _loadOptionsFor(id);
    }
  }

  Future<void> _loadOptionsFor(String id) async {
    final s = _states[id];
    if (s == null || optionsLoader == null) return;
    final needsLoad =
        s.config.optionsUrl != null ||
        (s.config.options.isEmpty &&
            s.config.enumName == null &&
            _isSelection(s.config.type));
    if (!needsLoad) return;
    s.loadingOptions.value = true;
    try {
      final options = await optionsLoader!(
        id,
        getFormData(includeHidden: true, phoneFormat: PhoneFormat.combined),
      );
      if (!_disposed && _states.containsKey(id)) {
        s.options.value = options;
      }
    } finally {
      if (!_disposed && _states.containsKey(id)) {
        s.loadingOptions.value = false;
      }
    }
  }

  void _reloadDependentOptions(String changedId) {
    // Reload options of fields whose conditions reference the changed field
    // (country → state → city chains).
    for (final s in _states.values) {
      if (s.config.dependsOn.contains(changedId)) {
        s.value.value = null;
        _loadOptionsFor(s.config.id);
      }
    }
  }

  static bool _isSelection(FieldType t) => const {
    FieldType.dropdown,
    FieldType.multiselect,
    FieldType.country,
    FieldType.state,
    FieldType.city,
    FieldType.autocomplete,
    FieldType.typeahead,
    FieldType.radioGroup,
    FieldType.checkboxGroup,
    FieldType.chips,
    FieldType.segmented,
    FieldType.toggleButtons,
  }.contains(t);

  @override
  void dispose() {
    _disposed = true;
    for (final s in _states.values) {
      s.dispose();
    }
    _states.clear();
    structureRevision.dispose();
    dirty.dispose();
    super.dispose();
  }
}
