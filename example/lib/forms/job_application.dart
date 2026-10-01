/// Multi-step wizard with a repeatable work-history step.
const Map<String, dynamic> jobApplicationForm = {
  'id': 'job_application',
  'title': 'Apply: Senior Flutter Engineer',
  'confirmDiscard': true,
  'style': {'variant': 'filled', 'borderRadius': 10},
  'steps': [
    {
      'title': 'About you',
      'subtitle': 'Basic details',
      'fields': [
        {
          'type': 'text',
          'id': 'candidateName',
          'label': 'Full name',
          'prefixIcon': 'badge',
          'required': true,
        },
        {
          'type': 'phone',
          'id': 'mobile',
          'label': 'Mobile number',
          'prefixText': '+91 ',
          'validators': ['required', 'phone'],
        },
        {
          'type': 'url',
          'id': 'portfolio',
          'label': 'Portfolio or GitHub',
          'prefixIcon': 'link',
          'validators': ['url'],
        },
        {
          'type': 'radioGroup',
          'id': 'workMode',
          'label': 'Preferred way of working',
          'enum': 'WorkMode',
          'optionLayout': 'horizontal',
          'required': true,
        },
        {
          'type': 'text',
          'id': 'relocateCity',
          'label': 'Which city would you work from?',
          'prefixIcon': 'city',
          'visibleWhen': {
            'field': 'workMode',
            'operator': 'in',
            'value': ['onSite', 'hybrid'],
          },
        },
      ],
    },
    {
      'title': 'Experience',
      'subtitle': 'Add each role you have held',
      'fields': [
        {
          'type': 'repeater',
          'id': 'roles',
          'label': 'Work history',
          'itemLabel': 'Role {index}',
          'addLabel': 'Add a role',
          'minItems': 1,
          'maxItems': 6,
          'reorderable': true,
          'fields': [
            {
              'type': 'text',
              'id': 'company',
              'label': 'Company',
              'required': true,
            },
            {
              'type': 'text',
              'id': 'title',
              'label': 'Job title',
              'required': true,
            },
            {
              'type': 'dropdown',
              'id': 'kind',
              'label': 'Employment type',
              'enum': 'EmploymentKind',
            },
            {
              'type': 'stepper',
              'id': 'years',
              'label': 'Years in this role',
              'min': 0,
              'max': 30,
              'initialValue': 1,
            },
          ],
        },
        {
          'type': 'checkboxGroup',
          'id': 'stack',
          'label': 'Tools you use daily',
          'optionLayout': 'grid',
          'columns': 2,
          'minItems': 2,
          'allowCustomOptions': true,
          'customOptionLabel': 'Add a tool',
          'options': ['Riverpod', 'Bloc', 'GetX', 'Firebase', 'Dio', 'Isar'],
        },
      ],
    },
    {
      'title': 'Wrap up',
      'fields': [
        {
          'type': 'rating',
          'id': 'dartConfidence',
          'label': 'How confident are you with Dart?',
          'count': 5,
          'required': true,
        },
        {
          'type': 'textarea',
          'id': 'pitch',
          'label': 'Why this role?',
          'maxLines': 5,
          'maxLength': 400,
          'showCounter': true,
          'validators': [
            {
              'type': 'minLength',
              'value': 30,
              'message': 'Tell us a little more',
            },
          ],
        },
        {
          'type': 'file',
          'id': 'resume',
          'label': 'Résumé (PDF)',
          'extensions': ['pdf'],
        },
      ],
    },
  ],
};
