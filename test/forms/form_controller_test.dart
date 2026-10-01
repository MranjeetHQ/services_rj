import 'package:flutter_test/flutter_test.dart';
import 'package:services_rj/services_rj.dart';

FormConfig _config() => FormParser.parse({
  'id': 'f',
  'fields': [
    {
      'type': 'text',
      'id': 'name',
      'defaultValue': 'anon',
      'validators': ['required'],
    },
    {
      'type': 'email',
      'id': 'email',
      'validators': ['required', 'email'],
    },
    {
      'type': 'dropdown',
      'id': 'country',
      'items': [
        {'label': 'India', 'value': 'IN'},
        {'label': 'USA', 'value': 'US'},
      ],
    },
    {
      'type': 'dropdown',
      'id': 'state',
      'visibleWhen': {'field': 'country', 'operator': 'equals', 'value': 'IN'},
    },
    {'type': 'number', 'id': 'age'},
    {
      'type': 'text',
      'id': 'license',
      'enabledWhen': {
        'field': 'age',
        'operator': 'greaterThanOrEqual',
        'value': 18,
      },
    },
    {'type': 'hidden', 'id': 'source', 'initialValue': 'mobile'},
  ],
});

void main() {
  late DynamicFormController c;

  setUp(() {
    c = DynamicFormController();
    c.attach(_config());
  });

  tearDown(() => c.dispose());

  group('values', () {
    test('get/set/clear/reset', () {
      expect(c.getValue('name'), 'anon');
      c.setValue('name', 'John');
      expect(c.getValue('name'), 'John');
      c.clearField('name');
      expect(c.getValue('name'), isNull);
      c.reset();
      expect(c.getValue('name'), 'anon');
    });

    test('getFormData excludes conditionally hidden, includes hidden type', () {
      final data = c.getFormData();
      expect(data.containsKey('state'), isFalse, reason: 'country != IN');
      expect(data['source'], 'mobile');
      c.setValue('country', 'IN');
      expect(c.getFormData().containsKey('state'), isTrue);
    });

    test('setFormData bulk-applies', () {
      c.setFormData({'name': 'A', 'email': 'a@b.com', 'age': 30});
      expect(c.getValue('email'), 'a@b.com');
      expect(c.getValue('age'), 30);
    });
  });

  group('conditional logic', () {
    test('visibility follows country', () {
      expect(c.state('state').visible.value, isFalse);
      c.setValue('country', 'IN');
      expect(c.state('state').visible.value, isTrue);
      c.setValue('country', 'US');
      expect(c.state('state').visible.value, isFalse);
    });

    test('enablement follows age', () {
      expect(c.state('license').enabled.value, isFalse);
      c.setValue('age', 18);
      expect(c.state('license').enabled.value, isTrue);
      c.setValue('age', 17);
      expect(c.state('license').enabled.value, isFalse);
    });
  });

  group('validation', () {
    test('validate reports all errors, hidden fields skipped', () {
      c.setValue('name', null);
      expect(c.validate(), isFalse);
      final errors = c.getErrors();
      expect(errors, contains('name'));
      expect(errors, contains('email'));
      expect(errors.containsKey('state'), isFalse);
      c.clearErrors();
      expect(c.getErrors(), isEmpty);
    });

    test('submit returns data when valid and calls onSubmit', () {
      Map<String, dynamic>? submitted;
      c.onSubmit = (d) => submitted = d;
      c.setValue('name', 'John');
      c.setValue('email', 'j@d.com');
      final result = c.submit();
      expect(result, isNotNull);
      expect(submitted!['email'], 'j@d.com');
    });

    test('submit returns null and calls onError when invalid', () {
      Map<String, String>? errs;
      c.onError = (e) => errs = e;
      c.setValue('email', 'bad');
      expect(c.submit(), isNull);
      expect(errs, isNotNull);
    });

    test('error revalidates live after first failure', () {
      c.setValue('email', 'bad');
      c.validateField('email');
      expect(c.state('email').error.value, isNotNull);
      c.setValue('email', 'good@x.com');
      expect(c.state('email').error.value, isNull);
    });
  });

  group('structure mutation', () {
    test('addField / removeField fire events and update order', () {
      FieldConfig? added;
      String? removed;
      c.onFieldAdded = (f) => added = f;
      c.onFieldRemoved = (id) => removed = id;
      c.addField(
        FieldConfig.fromJson({'type': 'text', 'id': 'nick'}),
        index: 1,
      );
      expect(added!.id, 'nick');
      expect(c.fieldOrder[1], 'nick');
      final rev = c.structureRevision.value;
      c.removeField('nick');
      expect(removed, 'nick');
      expect(c.hasField('nick'), isFalse);
      expect(c.structureRevision.value, rev + 1);
    });

    test('hide/show/enable/disable', () {
      c.hideField('name');
      expect(c.state('name').visible.value, isFalse);
      c.showField('name');
      expect(c.state('name').visible.value, isTrue);
      c.disableField('name');
      expect(c.state('name').enabled.value, isFalse);
      c.enableField('name');
      expect(c.state('name').enabled.value, isTrue);
    });
  });

  group('listen', () {
    test('listener fires and cancels', () {
      final seen = <Object?>[];
      final cancel = c.listen('name', seen.add);
      c.setValue('name', 'x');
      expect(seen, ['x']);
      cancel();
      c.setValue('name', 'y');
      expect(seen, ['x']);
    });
  });

  group('async options', () {
    test('optionsLoader populates dropdown options', () async {
      final loaderCalls = <String>[];
      final ctrl = DynamicFormController(
        optionsLoader: (id, data) async {
          loaderCalls.add(id);
          return [const OptionItem(label: 'Delhi', value: 'DL')];
        },
      );
      ctrl.attach(
        FormParser.parse({
          'fields': [
            {'type': 'dropdown', 'id': 'city', 'optionsUrl': '/api/cities'},
          ],
        }),
      );
      await Future<void>.delayed(Duration.zero);
      expect(loaderCalls, contains('city'));
      expect(ctrl.state('city').options.value.single.value, 'DL');
      ctrl.dispose();
    });

    test('dependsOn clears value and reloads', () async {
      var round = 0;
      final ctrl = DynamicFormController(
        optionsLoader: (id, data) async => [
          OptionItem(label: 'opt${++round}', value: round),
        ],
      );
      ctrl.attach(
        FormParser.parse({
          'fields': [
            {
              'type': 'dropdown',
              'id': 'country',
              'items': [
                {'label': 'India', 'value': 'IN'},
              ],
            },
            {
              'type': 'dropdown',
              'id': 'state',
              'optionsUrl': '/api/states',
              'dependsOn': ['country'],
            },
          ],
        }),
      );
      await Future<void>.delayed(Duration.zero);
      ctrl.setValue('state', 1);
      ctrl.setValue('country', 'IN');
      await Future<void>.delayed(Duration.zero);
      expect(ctrl.getValue('state'), isNull, reason: 'cleared on dependency');
      ctrl.dispose();
    });
  });

  group('runtime JSON change', () {
    test('attach preserves surviving values', () {
      c.setValue('name', 'keepme');
      c.attach(_config());
      expect(c.getValue('name'), 'keepme');
    });
  });
}
