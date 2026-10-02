/// Shows every per-field customization option side by side.
const Map<String, dynamic> stylingLabForm = {
  'id': 'styling_lab',
  'title': 'Field styling lab',
  'fields': [
    {
      'type': 'text',
      'id': 'outlinedField',
      'label': 'Outlined (default)',
      'hint': 'Plain outlined border',
    },
    {
      'type': 'text',
      'id': 'roundedField',
      'label': 'Rounded pill',
      'prefixIcon': 'search',
      'style': {
        'variant': 'rounded',
        'borderColor': '#7E57C2',
        'focusedBorderColor': '#4527A0',
        'iconColor': '#7E57C2',
      },
    },
    {
      'type': 'text',
      'id': 'filledField',
      'label': 'Filled, label always floating',
      'style': {
        'variant': 'filled',
        'fillColor': '#FFF3E0',
        'labelBehavior': 'always',
        'labelStyle': {'color': '#E65100', 'fontWeight': 'w600'},
      },
    },
    {
      'type': 'decimal',
      'id': 'price',
      'label': 'Underline with prefix and suffix',
      'prefixText': '₹ ',
      'suffixText': '/ month',
      'style': {'variant': 'underline', 'textAlign': 'end'},
    },
    {
      'type': 'text',
      'id': 'vehicle',
      'label': 'Uppercase vehicle number',
      'textCase': 'upper',
      'maxLength': 10,
      'showCounter': true,
      'style': {
        'textStyle': {'fontSize': 18, 'letterSpacing': 2, 'fontWeight': 'bold'},
        'cursorColor': '#D81B60',
      },
    },
    {
      'type': 'radioGroup',
      'id': 'size',
      'label': 'Wrap layout with descriptions',
      'optionLayout': 'wrap',
      'style': {'activeColor': '#2E7D32'},
      'options': [
        {'label': 'Small', 'value': 's', 'description': 'Up to 5 kg'},
        {'label': 'Medium', 'value': 'm', 'description': 'Up to 15 kg'},
        {'label': 'Large', 'value': 'l', 'description': 'Up to 30 kg'},
      ],
    },
    {
      'type': 'segmented',
      'id': 'priority',
      'label': 'Custom option renderer (FieldOverrides)',
      'options': ['low', 'normal', 'urgent'],
    },
    {
      'type': 'textarea',
      'id': 'remarks',
      'label': 'Remarks (card wrapper)',
      'maxLines': 3,
      'tooltip': 'Anything the courier should know',
    },
    {
      'type': 'group',
      'id': 'addressGroup',
      'label': 'Group with a container colour',
      'style': {'containerColor': '#E8F5E9', 'containerRadius': 16},
      'fields': [
        {'type': 'text', 'id': 'line1', 'label': 'Address line'},
        {
          'type': 'text',
          'id': 'pin',
          'label': 'PIN code',
          'keyboardType': 'number',
        },
      ],
    },
  ],
};
