import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:services_rj/services_rj.dart';
import 'package:services_rj_example/demo_enums.dart';
import 'package:services_rj_example/demos/forms_labs.dart';
import 'package:services_rj_example/forms/lab_common.dart';
import 'package:services_rj_example/forms/lab_conditions.dart';
import 'package:services_rj_example/forms/lab_controller.dart';
import 'package:services_rj_example/forms/lab_localization.dart';
import 'package:services_rj_example/forms/lab_multistep.dart';
import 'package:services_rj_example/forms/lab_theme.dart';
import 'package:services_rj_example/forms/lab_typed.dart';
import 'package:services_rj_example/forms/lab_validators.dart';

Iterable<FieldConfig> _all(FormConfig c) => labWalkFields(c.allFields);

void _conditionOps(
  Condition? c,
  Set<ConditionOperator> ops,
  Set<String> kinds,
) {
  if (c == null) return;
  if (c.and != null) {
    kinds.add('and');
    for (final child in c.and!) {
      _conditionOps(child, ops, kinds);
    }
  } else if (c.or != null) {
    kinds.add('or');
    for (final child in c.or!) {
      _conditionOps(child, ops, kinds);
    }
  } else if (c.not != null) {
    kinds.add('not');
    _conditionOps(c.not, ops, kinds);
  } else if (c.op != null) {
    ops.add(c.op!);
  }
}

Future<void> _settle() =>
    Future<void>.delayed(const Duration(milliseconds: 450));

void main() {
  setUp(() {
    registerDemoEnums();
    registerLabEnums();
    registerLabValidators();
    registerLabOperators();
    registerLabTranslations();
  });

  group('validators lab', () {
    DynamicFormController build() =>
        DynamicFormController(customValidators: labCustomValidators)
          ..attach(FormParser.parse(validatorsLabForm));

    test('every ValidatorType is used by the lab JSON', () {
      final used = {
        for (final f in _all(FormParser.parse(validatorsLabForm)))
          for (final v in f.validators) ?v.kind,
      };
      expect(used, containsAll(ValidatorType.values));
    });

    test('valid sample passes, invalid sample reports each rule', () {
      final c = build();
      c.setFormData(validatorsValidSample);
      expect(c.validate(), isTrue, reason: c.getErrors().toString());
      c.setFormData(validatorsInvalidSample);
      expect(c.validate(), isFalse);
      final errors = c.getErrors();
      for (final id in validatorsInvalidSample.keys) {
        if (id == 'badge') continue;
        expect(errors, contains(id), reason: id);
      }
      expect(errors['fullName'], 'Please tell us your name');
      expect(errors['email'], 'That email looks incomplete');
      expect(errors['seats'], 'We cap bookings at ten');
      expect(errors['handle'], 'Handles cannot contain spaces');
      expect(errors['lucky'], 'Lucky numbers here are even');
      c.dispose();
    });

    test('custom validators read other fields and clearErrors empties', () {
      final c = build();
      c.setValue('fullName', 'Asha');
      c.setValue('badge', 'Zed');
      expect(c.validateField('badge'), 'Badge text must start with "A"');
      c.setValue('badge', 'apple');
      expect(c.validateField('badge'), isNull);
      c.setValue('lucky', 3);
      expect(c.validateField('lucky'), isNotNull);
      c.setValue('lucky', 4);
      expect(c.validateField('lucky'), isNull);
      c.validate();
      expect(c.hasErrors, isTrue);
      c.clearErrors();
      expect(c.getErrors(), isEmpty);
      c.dispose();
    });

    test('onValidation and onError callbacks fire', () {
      final c = build();
      Map<String, String>? validation;
      Map<String, String>? error;
      c.onValidation = (e) => validation = e;
      c.onError = (e) => error = e;
      expect(c.submit(), isNull);
      expect(validation, isNotEmpty);
      expect(error, validation);
      c.dispose();
    });

    test('unregistered custom name is skipped without crashing', () {
      final c = DynamicFormController()
        ..attach(FormParser.parse(validatorsLabForm));
      c.setValue('handle', 'has space');
      expect(c.validateField('handle'), isNull);
      c.dispose();
    });
  });

  group('conditions lab', () {
    late DynamicFormController c;
    setUp(() {
      c = DynamicFormController(optionsLoader: labCityLoader)
        ..attach(FormParser.parse(buildConditionsLabForm()));
    });
    tearDown(() => c.dispose());

    test('every ConditionOperator and compound kind is used', () {
      final ops = <ConditionOperator>{};
      final kinds = <String>{};
      for (final f in _all(FormParser.parse(buildConditionsLabForm()))) {
        _conditionOps(f.visibleWhen, ops, kinds);
        _conditionOps(f.enabledWhen, ops, kinds);
        _conditionOps(f.requiredWhen, ops, kinds);
      }
      expect(ops, containsAll(ConditionOperator.values));
      expect(kinds, containsAll(['and', 'or', 'not']));
      expect(conditionRules, hasLength(ConditionOperator.values.length));
    });

    test('each operator target toggles with its control', () {
      for (final r in conditionRules) {
        c.setValue(r.field, r.matching);
        expect(
          c.state(r.targetId).visible.value,
          isTrue,
          reason: '${r.op.name} matching',
        );
        c.setValue(r.field, r.nonMatching);
        expect(
          c.state(r.targetId).visible.value,
          isFalse,
          reason: '${r.op.name} non-matching',
        );
      }
    });

    test('enabledWhen and requiredWhen follow their controls', () {
      c.setValue('age', 17);
      expect(c.state('licence').enabled.value, isFalse);
      c.setValue('age', 18);
      expect(c.state('licence').enabled.value, isTrue);
      expect(c.state('company').required.value, isFalse);
      c.setValue('plan', 'pro');
      expect(c.state('company').required.value, isTrue);
      expect(c.validateField('company'), isNotNull);
      c.setValue('plan', 'free');
      expect(c.state('coupon').enabled.value, isFalse);
      c.setValue('promo', 'X');
      expect(c.state('promoReason').required.value, isTrue);
    });

    test('compound, alias and custom operator conditions', () {
      c.setValue('plan', 'team');
      expect(c.state('both').visible.value, isFalse);
      c.setValue('age', 30);
      expect(c.state('both').visible.value, isTrue);
      expect(c.state('notFree').visible.value, isTrue);
      expect(c.state('nested').visible.value, isFalse);
      c.setValue('promo', 'CODE');
      expect(c.state('nested').visible.value, isTrue);
      expect(c.state('either').visible.value, isFalse);
      c.setValue('country', 'IN');
      expect(c.state('either').visible.value, isTrue);
      expect(c.state('aliases').visible.value, isTrue);
      c.setValue('quantity', 10);
      expect(c.state('custom_divisible').visible.value, isTrue);
      c.setValue('quantity', 7);
      expect(c.state('custom_divisible').visible.value, isFalse);
    });

    test('dependsOn reloads and clears the dependent field', () async {
      c.setValue('country', 'DE');
      await _settle();
      expect(c.state('city').options.value.map((o) => o.value), [
        'Berlin',
        'Leipzig',
        'Hamburg',
      ]);
      c.setValue('city', 'Berlin');
      c.setValue('country', 'US');
      expect(c.getValue('city'), isNull);
      await _settle();
      expect(c.state('city').options.value, hasLength(2));
    });
  });

  group('localization lab', () {
    test('messages differ across every built-in locale', () {
      final messages = {
        for (final l in labBuiltInLocales)
          l: FormLocalizations(l).message('required'),
      };
      expect(messages.values.toSet(), hasLength(labBuiltInLocales.length));
      expect(FormLocalizations('ar').isRtl, isTrue);
      expect(FormLocalizations('en').isRtl, isFalse);
    });

    test('controllers localize validation and interpolate values', () {
      final en = DynamicFormController()
        ..attach(FormParser.parse(localeLabForm));
      final de = DynamicFormController(locale: 'de')
        ..attach(FormParser.parse(localeLabForm));
      en.setValue('bio', 'short');
      de.setValue('bio', 'short');
      expect(en.validateField('bio'), 'Must be at least 10 characters');
      expect(de.validateField('bio'), 'Mindestens 10 Zeichen erforderlich');
      expect(en.validateField('name'), isNot(de.validateField('name')));
      en.dispose();
      de.dispose();
    });

    test('custom translations fall back to English for missing keys', () {
      final pt = FormLocalizations(labCustomLocale);
      expect(pt.message('required'), 'Este campo é obrigatório');
      expect(pt.message('minLength', value: 5), 'Use pelo menos 5 caracteres');
      expect(pt.message('url'), FormLocalizations('en').message('url'));
    });
  });

  group('controller playground', () {
    late DynamicFormController c;
    setUp(() {
      c = DynamicFormController()..attach(FormParser.parse(controllerLabForm));
    });
    tearDown(() => c.dispose());

    test('values, typed getters and enums', () {
      c.setValue('name', 'Asha');
      c.setValue('age', 30);
      c.setValue('plan', LabPlan.pro);
      c.setValue('topics', [LabTopic.testing, LabTopic.tooling]);
      c.setValue('agree', true);
      expect(c.getValue('name'), 'Asha');
      expect(c.getString('age'), '30');
      expect(c.getInt('age'), 30);
      expect(c.getDouble('age'), 30.0);
      expect(c.getBool('agree'), isTrue);
      expect(c.getList('topics'), ['testing', 'tooling']);
      expect(c.getEnum('plan', LabPlan.values), LabPlan.pro);
      expect(c.getEnumList('topics', LabTopic.values), [
        LabTopic.testing,
        LabTopic.tooling,
      ]);
      c.clearField('name');
      expect(c.getValue('name'), isNull);
    });

    test('form data, reset and asInitial', () {
      c.setFormData({'name': 'Ravi', 'age': 41});
      expect(c.isDirty, isTrue);
      c.reset();
      expect(c.getValue('name'), isNull);
      expect(c.isDirty, isFalse);
      c.setFormData({'name': 'Saved'}, asInitial: true);
      expect(c.isDirty, isFalse);
      c.setValue('name', 'Edited');
      expect(c.isDirty, isTrue);
      c.reset();
      expect(c.getValue('name'), 'Saved');
      c.hideField('notes');
      expect(c.getFormData().containsKey('notes'), isFalse);
      expect(c.getFormData(includeHidden: true).containsKey('notes'), isTrue);
    });

    test('validation and submit', () {
      Map<String, dynamic>? submitted;
      Map<String, String>? failed;
      c.onSubmit = (d) => submitted = d;
      c.onError = (e) => failed = e;
      expect(c.submit(), isNull);
      expect(failed, contains('name'));
      expect(c.getErrors()['name'], 'Name is required');
      expect(c.validateField('name'), 'Name is required');
      c.setValue('name', 'Asha');
      expect(c.validate(), isTrue);
      expect(c.hasErrors, isFalse);
      expect(c.submit(), isNotNull);
      expect(submitted!['name'], 'Asha');
      expect(c.isDirty, isFalse);
    });

    test('structure mutation fires callbacks', () {
      FieldConfig? added;
      String? removed;
      c.onFieldAdded = (f) => added = f;
      c.onFieldRemoved = (id) => removed = id;
      c.addField(labRuntimeField, index: 1);
      expect(added?.id, 'extra');
      expect(c.fieldOrder[1], 'extra');
      c.removeField('extra');
      expect(removed, 'extra');
      expect(c.hasField('extra'), isFalse);
      c.disableField('age');
      expect(c.state('age').enabled.value, isFalse);
      c.enableField('age');
      c.hideField('notes');
      expect(c.state('notes').visible.value, isFalse);
      c.showField('notes');
      c.setRequired('notes', required: true);
      expect(c.validateField('notes'), isNotNull);
      c.setRequired('notes', required: false);
      expect(c.validateField('notes'), isNull);
    });

    test('options API', () {
      OptionItem? added;
      c.onOptionAdded = (id, o) => added = o;
      c.setOptions('plan', const [OptionItem(label: 'A', value: 'a')]);
      expect(c.state('plan').options.value, hasLength(1));
      c.addOption(
        'topics',
        const OptionItem(label: 'Mine', value: 'mine', isCustom: true),
        select: true,
      );
      expect(added?.value, 'mine');
      expect(c.getList('topics'), contains('mine'));
      expect(c.customOptions('topics'), hasLength(1));
      c.removeOption('topics', 'mine');
      expect(c.getList('topics'), isNot(contains('mine')));
    });

    test('repeater entries respect limits', () {
      expect(c.entriesOf('guests'), hasLength(1));
      expect(c.canRemoveEntry('guests'), isFalse);
      expect(c.addEntry('guests', data: {'guestName': 'Meera'}), isNotNull);
      expect(c.addEntry('guests'), isNotNull);
      expect(c.canAddEntry('guests'), isFalse);
      expect(c.addEntry('guests'), isNull);
      c.moveEntry('guests', 1, 0);
      expect(c.getEntries('guests').first['guestName'], 'Meera');
      expect(c.removeEntry('guests', 0), isTrue);
      expect(c.entriesOf('guests'), hasLength(2));
      c.setValue('guests', [
        {'guestName': 'Ira'},
      ]);
      expect(c.getEntries('guests'), [
        {'guestName': 'Ira'},
      ]);
    });

    test('listen and dirty notifier', () {
      final seen = <Object?>[];
      final cancel = c.listen('name', seen.add);
      c.setValue('name', 'A');
      cancel();
      c.setValue('name', 'B');
      expect(seen, ['A']);
      expect(c.dirty.value, isTrue);
      c.markClean();
      expect(c.isDirty, isFalse);
      var changes = 0;
      c.onChanged = (id, value, data) => changes++;
      c.setValue('age', 5);
      expect(changes, 1);
      c.focusField('name');
      c.unfocus();
    });
  });

  group('theme lab', () {
    test('style lab uses every FieldStyleConfig key and variant', () {
      final json = buildStyleLabForm();
      final keys = <String>{...((json['style'] as Map).keys.cast<String>())};
      void walk(List<dynamic> fields) {
        for (final f in fields) {
          final m = f as Map<String, dynamic>;
          for (final k in ['style', 'decoration']) {
            if (m[k] is Map) keys.addAll((m[k] as Map).keys.cast<String>());
          }
          if (m['fields'] is List) walk(m['fields'] as List);
        }
      }

      walk(json['fields'] as List);
      expect(keys, containsAll(FieldStyleConfig.knownKeys));
      final cfg = FormParser.parse(json);
      final variants = {for (final f in _all(cfg)) f.styleConfig?.variant};
      expect(variants, containsAll(FieldStyleVariant.values));
    });

    test('enum lab shows every value of every field enum', () {
      final fields = _all(FormParser.parse(buildEnumsLabForm())).toList();
      expect({
        for (final f in fields) ?f.keyboardType,
      }, containsAll(KeyboardKind.values));
      expect({
        for (final f in fields) ?f.textInputAction,
      }, containsAll(InputActionKind.values));
      expect({
        for (final f in fields) ?f.optionLayout,
      }, containsAll(OptionLayout.values));
      expect({
        for (final f in fields) ?f.textCase,
      }, containsAll(TextCase.values));
      expect({
        for (final f in fields) ?f.styleConfig?.labelBehavior,
      }, containsAll(LabelBehavior.values));
      expect({
        for (final f in fields) ?f.styleConfig?.labelPosition,
      }, containsAll(LabelPosition.values));
      expect({
        for (final f in fields) ?MediaSource.fromString(f.ex<String>('source')),
      }, containsAll(MediaSource.values));
    });

    test('overrides cover every FieldOverrides property', () {
      final all = buildLabFieldOverrides().values.toList();
      expect(all.any((o) => o.builder != null), isTrue);
      expect(all.any((o) => o.style != null), isTrue);
      expect(all.any((o) => o.decoration != null), isTrue);
      expect(all.any((o) => o.optionBuilder != null), isTrue);
      expect(all.any((o) => o.wrapper != null), isTrue);
      expect(all.any((o) => o.label != null), isTrue);
      expect(all.any((o) => o.hint != null), isTrue);
      expect(all.any((o) => o.helperText != null), isTrue);
      expect(buildLabTypeOverrides(), contains(FieldType.phone));
    });

    test('theme form attaches and loads async teams', () async {
      final c = DynamicFormController(optionsLoader: labTeamLoader)
        ..attach(FormParser.parse(themeLabForm));
      expect(c.state('team').loadingOptions.value, isTrue);
      await Future<void>.delayed(const Duration(milliseconds: 1000));
      expect(c.state('team').options.value, hasLength(labTeams.length));
      c.validate();
      expect(c.getErrors().keys, containsAll(['comfort', 'extras']));
      c.dispose();
    });
  });

  group('typed config lab', () {
    test('FormConfig round-trips through JSON and attaches', () {
      final config = buildTypedConfig();
      final json = config.toJson();
      expect(labCompact(FormConfig.fromJson(json).toJson()), labCompact(json));
      final c = DynamicFormController(customValidators: labCustomValidators)
        ..attach(FormParser.parse(json));
      expect(c.fieldOrder, containsAll(['fullName', 'plan', 'guests']));
      expect(c.getEnum('plan', LabPlan.values), LabPlan.free);
      expect(c.state('newsletterEmail').visible.value, isFalse);
      c.setValue('newsletter', true);
      expect(c.state('newsletterEmail').visible.value, isTrue);
      c.setValue('handle', 'a b');
      expect(c.validateField('handle'), 'Handles cannot contain spaces');
      c.dispose();
    });

    test('copyWith produces a required phone field', () {
      final plain = buildTypedConfig().fields.firstWhere(
        (f) => f.id == 'phone',
      );
      final strict = buildTypedConfig(
        phoneRequired: true,
      ).fields.firstWhere((f) => f.id == 'phone');
      expect(plain.required, isFalse);
      expect(strict.required, isTrue);
      expect(strict.toJson()['required'], isTrue);
    });

    test('FormParser accepts JSON strings and rejects non-objects', () {
      expect(FormParser.parse('{"fields": []}').fields, isEmpty);
      expect(() => FormParser.parse('[1]'), throwsFormatException);
    });

    test('registry, decode and OptionItem helpers', () {
      expect(FormEnumRegistry.names, containsAll(['LabPlan', 'LabTopic']));
      final plans = FormEnumRegistry.options('LabPlan')!;
      expect(plans.first.description, 'Up to 3 seats');
      expect(plans.first.icon, 'tag');
      expect(
        FormEnumRegistry.options('LabTopic')!.where((o) => !o.enabled),
        hasLength(1),
      );
      expect(FormEnumRegistry.decode(LabPlan.values, 'team'), LabPlan.team);
      expect(FormEnumRegistry.humanize('inPerson'), 'In person');
      expect(OptionItem.fromJson('Delhi').value, 'Delhi');
      expect(OptionItem.fromJson(LabPlan.pro).label, 'Pro');
      final custom = OptionItem.fromJson({
        'label': 'X',
        'value': 1,
        'isCustom': true,
      });
      expect(custom.isCustom, isTrue);
      expect(OptionItem.fromJson(custom.toJson()), custom);
    });

    test('optionsLoader fills optionsUrl and dependsOn fields', () async {
      late DynamicFormController c;
      final urls = <String?>[];
      c = DynamicFormController(
        optionsLoader: (id, data) async {
          urls.add(c.state(id).config.optionsUrl);
          await Future<void>.delayed(const Duration(milliseconds: 50));
          return id == 'country'
              ? const [OptionItem(label: 'India', value: 'IN')]
              : [
                  for (final (l, v)
                      in labAsyncCities[data['country']] ??
                          const <(String, String)>[])
                    OptionItem(label: l, value: v),
                ];
        },
      );
      c.attach(FormParser.parse(labAsyncForm));
      await Future<void>.delayed(const Duration(milliseconds: 200));
      expect(c.state('country').options.value.single.value, 'IN');
      expect(urls, contains('https://api.example.invalid/countries'));
      c.setValue('country', 'US');
      await Future<void>.delayed(const Duration(milliseconds: 200));
      expect(c.state('city').options.value, hasLength(2));
      c.dispose();
    });
  });

  group('multi-step lab', () {
    test('wizard config parses into three steps', () {
      final config = FormParser.parse(multiStepLabJson);
      expect(config.steps, hasLength(3));
      final c = DynamicFormController()..attach(config);
      expect(c.entriesOf('travellers'), hasLength(2));
      final nested = c.entriesOf('travellers').first.controller;
      expect(nested.entriesOf('bags'), hasLength(1));
      expect(c.canAddEntry('travellers'), isTrue);
      c.addEntry('travellers');
      c.addEntry('travellers');
      expect(c.canAddEntry('travellers'), isFalse);
      nested.setValue('bags', [
        {'weight': 40},
      ]);
      expect(c.validateField('travellers'), isNotNull);
      c.dispose();
    });

    test('edit mode starts clean and reset restores the record', () {
      final c = DynamicFormController()
        ..attach(FormParser.parse(extendableLabForm), initialData: labRecordA);
      expect(c.isDirty, isFalse);
      expect(c.entriesOf('contacts'), hasLength(2));
      final first = c.entriesOf('contacts').first.controller;
      expect(first.entriesOf('phones'), hasLength(2));
      expect(first.getValue('street'), '4 Lake Road');
      c.addEntry('contacts');
      expect(c.isDirty, isTrue);
      c.reset();
      expect(c.entriesOf('contacts'), hasLength(2));
      expect(c.isDirty, isFalse);
      expect(c.getEntries('contacts').first['contactName'], 'Anil Mehta');
      c.dispose();
    });

    test('extendable form fires onOptionAdded', () {
      final c = DynamicFormController()
        ..attach(FormParser.parse(extendableLabForm));
      String? seen;
      c.onOptionAdded = (id, o) => seen = '$id:${o.label}';
      c.addOption('interests', const OptionItem(label: 'Sailing', value: 's'));
      expect(seen, 'interests:Sailing');
      c.dispose();
    });
  });

  group('lab pages', () {
    Future<void> pumpLab(WidgetTester tester, int index) async {
      tester.view.physicalSize = const Size(900, 9000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(home: Builder(builder: formLabDemos[index].builder)),
      );
      await tester.pump(const Duration(milliseconds: 100));
    }

    Future<void> drain(WidgetTester tester) async {
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpWidget(const SizedBox());
    }

    test('lab list has eight titled entries', () {
      expect(formLabDemos, hasLength(8));
      expect({for (final d in formLabDemos) d.title}, hasLength(8));
    });

    testWidgets('validators page shows custom messages', (tester) async {
      await pumpLab(tester, 0);
      await tester.tap(find.text('Fill invalid sample'));
      await tester.pump();
      await tester.tap(find.text('validate()'));
      await tester.pump();
      expect(find.text('That email looks incomplete'), findsOneWidget);
      expect(find.text('Lucky numbers here are even'), findsOneWidget);
      await tester.tap(find.text('clearErrors()'));
      await tester.pump();
      expect(find.text('That email looks incomplete'), findsNothing);
      await drain(tester);
    });

    testWidgets('conditions page toggles targets', (tester) async {
      await pumpLab(tester, 1);
      expect(find.text('equals: plan is Pro'), findsNothing);
      await tester.tap(find.text('Pro'));
      await tester.pumpAndSettle();
      expect(find.text('equals: plan is Pro'), findsOneWidget);
      await drain(tester);
    });

    testWidgets('localization page switches locale and direction', (
      tester,
    ) async {
      await pumpLab(tester, 2);
      await tester.tap(find.text('العربية'));
      await tester.pump();
      final arabic = FormLocalizations('ar').message('required');
      expect(find.text(arabic), findsWidgets);
      final context = tester.element(find.text(arabic).first);
      expect(Directionality.of(context), TextDirection.rtl);
      await tester.tap(find.text('Deutsch'));
      await tester.pump();
      expect(
        find.text(FormLocalizations('de').message('submit')),
        findsWidgets,
      );
      await tester.tap(find.text('Português (custom)'));
      await tester.pump();
      expect(find.text('Enviar'), findsWidgets);
      await drain(tester);
    });

    testWidgets('controller page runs a method', (tester) async {
      await pumpLab(tester, 3);
      await tester.tap(find.text('Values'));
      await tester.pumpAndSettle();
      await tester.tap(find.text("setValue('name', 'Asha')"));
      await tester.pump();
      expect(find.text('Asha'), findsWidgets);
      expect(find.textContaining('onChanged'), findsWidgets);
      await tester.tap(find.text('Validation'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('validate()'));
      await tester.pump();
      expect(find.text('validate() -> true'), findsOneWidget);
      await drain(tester);
    });

    testWidgets('theme page shows loading, errorBuilder and dialog', (
      tester,
    ) async {
      await pumpLab(tester, 4);
      expect(find.textContaining('Fetching teams'), findsOneWidget);
      await tester.pump(const Duration(seconds: 1));
      expect(find.textContaining('Fetching teams'), findsNothing);
      await tester.tap(find.text('errorBuilder'));
      await tester.pump();
      await tester.tap(find.text('dense'));
      await tester.pump();
      await tester.tap(find.text('Validate to see errorBuilder'));
      await tester.pump();
      expect(find.byIcon(Icons.error_outline), findsWidgets);
      await tester.tap(find.text('Reload teams (shows loadingBuilder)'));
      await tester.pump();
      expect(find.textContaining('Fetching teams'), findsOneWidget);
      await drain(tester);
    });

    testWidgets('typed page applies copyWith', (tester) async {
      await pumpLab(tester, 5);
      expect(find.text('Phone'), findsOneWidget);
      await tester.tap(
        find.widgetWithText(SwitchListTile, 'phone.copyWith(required: true)'),
      );
      await tester.pump();
      expect(find.text('Phone (required via copyWith)'), findsOneWidget);
      expect(find.textContaining('identical: true'), findsOneWidget);
      await drain(tester);
    });

    testWidgets('multi-step page loads a record', (tester) async {
      await pumpLab(tester, 6);
      expect(find.text('Destination'), findsOneWidget);
      expect(find.text('Contact 1'), findsOneWidget);
      await tester.tap(find.text('Edit household A'));
      await tester.pump();
      await tester.pump();
      expect(find.text('The Mehtas'), findsOneWidget);
      expect(find.text('Contact 2'), findsOneWidget);
      await drain(tester);
    });
  });
}
