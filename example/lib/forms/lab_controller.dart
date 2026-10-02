import 'package:flutter/material.dart';
import 'package:services_rj/services_rj.dart';

import '../widgets/demo_widgets.dart';
import 'lab_common.dart';

/// Form driven by the controller playground.
const Map<String, dynamic> controllerLabForm = {
  'id': 'controller_lab',
  'fields': [
    {
      'type': 'text',
      'id': 'name',
      'label': 'Name',
      'validators': [
        {'type': 'required', 'message': 'Name is required'},
      ],
    },
    {'type': 'number', 'id': 'age', 'label': 'Age'},
    {'type': 'dropdown', 'id': 'plan', 'label': 'Plan', 'enum': 'LabPlan'},
    {
      'type': 'multiselect',
      'id': 'topics',
      'label': 'Topics',
      'enum': 'LabTopic',
      'allowCustomOptions': true,
    },
    {'type': 'switch', 'id': 'agree', 'label': 'I agree'},
    {'type': 'textarea', 'id': 'notes', 'label': 'Notes', 'maxLines': 2},
    {
      'type': 'repeater',
      'id': 'guests',
      'label': 'Guests',
      'itemLabel': 'Guest {index}',
      'minItems': 1,
      'maxItems': 3,
      'reorderable': true,
      'fields': [
        {'type': 'text', 'id': 'guestName', 'label': 'Guest name'},
      ],
    },
  ],
};

/// The field added and removed at runtime by the playground.
const FieldConfig labRuntimeField = FieldConfig(
  id: 'extra',
  type: FieldType.text,
  label: 'Extra note (added at runtime)',
);

/// Page for the controller playground.
class ControllerLabPage extends StatefulWidget {
  /// Creates the page.
  const ControllerLabPage({super.key});

  @override
  State<ControllerLabPage> createState() => _ControllerLabPageState();
}

class _ControllerLabPageState extends State<ControllerLabPage> {
  final _log = EventLog();
  final _c = DynamicFormController();
  VoidCallback? _cancelListen;
  int _optionSeq = 0;

  @override
  void initState() {
    super.initState();
    registerLabEnums();
    _c.onFieldAdded = (f) => _log.add('onFieldAdded: ${f.id}');
    _c.onFieldRemoved = (id) => _log.add('onFieldRemoved: $id');
  }

  @override
  void dispose() {
    _cancelListen?.call();
    _c.dispose();
    _log.dispose();
    super.dispose();
  }

  void _do(String label, Object? Function() fn) {
    try {
      final result = fn();
      _log.add(result == null ? label : '$label -> ${labCompact(result)}');
    } catch (e) {
      _log.add('$label threw $e');
    }
  }

  Widget _group(String title, Map<String, Object? Function()> calls) =>
      ExpansionTile(
        title: Text(title),
        childrenPadding: const EdgeInsets.only(bottom: 12),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LabActions(
            actions: {
              for (final e in calls.entries) e.key: () => _do(e.key, e.value),
            },
          ),
        ],
      );

  @override
  Widget build(BuildContext context) => DemoPage(
    title: 'Controller playground',
    intro:
        'Every public DynamicFormController method and extension. Run one '
        'and read the result in the log at the bottom.',
    children: [
      DemoSection(
        title: 'Form',
        child: Column(
          children: [
            ValueListenableBuilder<bool>(
              valueListenable: _c.dirty,
              builder: (context, dirty, _) => Align(
                alignment: Alignment.centerLeft,
                child: Chip(
                  avatar: Icon(dirty ? Icons.edit : Icons.check, size: 16),
                  label: Text(dirty ? 'dirty' : 'clean'),
                ),
              ),
            ),
            DynamicForm(
              controller: _c,
              json: controllerLabForm,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              onChanged: (d) => _log.add('onChanged: ${labCompact(d)}'),
              onValidation: (e) => _log.add('onValidation: ${labCompact(e)}'),
              onError: (e) => _log.add('onError: ${labCompact(e)}'),
              onSubmit: (d) => _log.add('onSubmit: ${labCompact(d)}'),
              onOptionAdded: (id, o) =>
                  _log.add('onOptionAdded: $id += ${o.label}'),
            ),
          ],
        ),
      ),
      DemoSection(
        title: 'Log',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            EventLogView(log: _log),
            TextButton(onPressed: _log.clear, child: const Text('Clear log')),
          ],
        ),
      ),
      DemoSection(
        title: 'Methods',
        child: Column(
          children: [
            _group('Values', {
              "setValue('name', 'Asha')": () => _c.setValue('name', 'Asha'),
              'setValue(plan, LabPlan.pro)': () =>
                  _c.setValue('plan', LabPlan.pro),
              "setValue('age', 30, validate: true)": () =>
                  _c.setValue('age', 30, validate: true),
              "clearField('name')": () => _c.clearField('name'),
              'reset()': () {
                _c.reset();
                return null;
              },
              'setFormData({...})': () {
                _c.setFormData({
                  'name': 'Ravi',
                  'age': 41,
                  'plan': 'team',
                  'topics': ['testing', 'tooling'],
                  'agree': true,
                });
                return null;
              },
              'setFormData(asInitial: true)': () {
                _c.setFormData({
                  'name': 'Saved Sam',
                  'age': 52,
                }, asInitial: true);
                return 'isDirty=${_c.isDirty}';
              },
              'getFormData()': _c.getFormData,
              'getFormData(includeHidden: true)': () =>
                  _c.getFormData(includeHidden: true),
              "getValue('name')": () => _c.getValue('name'),
              'initialData': () => _c.initialData,
              'fieldOrder': () => _c.fieldOrder,
              "hasField('plan')": () => _c.hasField('plan'),
              'normalizeValue(LabPlan.team)': () =>
                  DynamicFormController.normalizeValue(LabPlan.team),
            }),
            _group('Typed getters', {
              "getString('name')": () => _c.getString('name'),
              "getInt('age')": () => _c.getInt('age'),
              "getDouble('age')": () => _c.getDouble('age'),
              "getBool('agree')": () => _c.getBool('agree'),
              "getList('topics')": () => _c.getList('topics'),
              "getEnum('plan', LabPlan.values)": () =>
                  _c.getEnum('plan', LabPlan.values)?.name,
              "getEnumList('topics', LabTopic.values)": () => [
                for (final t in _c.getEnumList('topics', LabTopic.values))
                  t.name,
              ],
              "getEntries('guests')": () => _c.getEntries('guests'),
            }),
            _group('Validation', {
              'validate()': _c.validate,
              "validateField('name')": () => _c.validateField('name'),
              'getErrors()': _c.getErrors,
              'hasErrors': () => _c.hasErrors,
              'clearErrors()': () {
                _c.clearErrors();
                return null;
              },
              'submit()': _c.submit,
            }),
            _group('Structure', {
              'addField(extra)': () {
                _c.addField(labRuntimeField, index: 1);
                return null;
              },
              "removeField('extra')": () {
                _c.removeField('extra');
                return null;
              },
              "hideField('notes')": () {
                _c.hideField('notes');
                return null;
              },
              "showField('notes')": () {
                _c.showField('notes');
                return null;
              },
              "disableField('age')": () {
                _c.disableField('age');
                return null;
              },
              "enableField('age')": () {
                _c.enableField('age');
                return null;
              },
              "setRequired('notes', true)": () {
                _c.setRequired('notes', required: true);
                return null;
              },
              "setRequired('notes', false)": () {
                _c.setRequired('notes', required: false);
                return null;
              },
              "state('notes') flags": () {
                final s = _c.state('notes');
                return {
                  'visible': s.visible.value,
                  'enabled': s.enabled.value,
                  'required': s.required.value,
                };
              },
            }),
            _group('Options', {
              "setOptions('plan', [Starter, Scale])": () {
                _c.setOptions('plan', const [
                  OptionItem(label: 'Starter', value: 'starter'),
                  OptionItem(label: 'Scale', value: 'scale', icon: 'star'),
                ]);
                return null;
              },
              "addOption('topics', select: true)": () {
                final n = ++_optionSeq;
                _c.addOption(
                  'topics',
                  OptionItem(label: 'Extra $n', value: 'extra$n'),
                  select: true,
                );
                return null;
              },
              "removeOption('topics', 'testing')": () {
                _c.removeOption('topics', 'testing');
                return null;
              },
              "customOptions('topics')": () => [
                for (final o in _c.customOptions('topics')) o.label,
              ],
            }),
            _group('Repeater entries', {
              "entriesOf('guests')": () => _c.entriesOf('guests').length,
              "canAddEntry('guests')": () => _c.canAddEntry('guests'),
              "canRemoveEntry('guests')": () => _c.canRemoveEntry('guests'),
              "addEntry('guests', data: ...)": () {
                final e = _c.addEntry('guests', data: {'guestName': 'Meera'});
                return e == null ? 'max reached' : 'added entry ${e.key}';
              },
              "removeEntry('guests', 0)": () => _c.removeEntry('guests', 0),
              "moveEntry('guests', 0, 1)": () {
                _c.moveEntry('guests', 0, 1);
                return null;
              },
              "setValue('guests', [two maps])": () {
                _c.setValue('guests', [
                  {'guestName': 'Ira'},
                  {'guestName': 'Neel'},
                ]);
                return null;
              },
            }),
            _group('Focus and listening', {
              "focusField('name')": () {
                _c.focusField('name');
                return null;
              },
              'unfocus()': () {
                _c.unfocus();
                return null;
              },
              "listen('name')": () {
                _cancelListen?.call();
                _cancelListen = _c.listen(
                  'name',
                  (v) => _log.add('listener: name = $v'),
                );
                return 'listening';
              },
              'cancel listener': () {
                _cancelListen?.call();
                _cancelListen = null;
                return 'cancelled';
              },
            }),
            _group('Dirty tracking', {
              'isDirty': () => _c.isDirty,
              'markClean()': () {
                _c.markClean();
                return 'isDirty=${_c.isDirty}';
              },
              'config?.id': () => _c.config?.id,
              'structureRevision': () => _c.structureRevision.value,
            }),
          ],
        ),
      ),
    ],
  );
}
