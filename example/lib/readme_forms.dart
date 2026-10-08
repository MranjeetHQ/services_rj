// The Dynamic Forms example from the README. Run it with
// `flutter run -t lib/readme_forms.dart`. A test keeps the README and this
// file identical.
import 'package:flutter/material.dart';
import 'package:services_rj/services_rj.dart';

enum MealChoice { vegetarian, vegan, nonVegetarian }

void main() {
  FormEnumRegistry.register('MealChoice', MealChoice.values);
  // Search-as-you-type source. Replace the body with your API call.
  FormSearchSources.register('venues', (query, formData) async {
    const venues = ['Riverside Hall', 'Rooftop Garden', 'Old Library'];
    return [
      for (final v in venues)
        if (v.toLowerCase().contains(query.toLowerCase()))
          OptionItem(label: v, value: v),
    ];
  });
  runApp(const MaterialApp(home: RsvpPage()));
}

const rsvpForm = {
  'padding': 'standard',
  'fields': [
    {
      'type': 'text',
      'id': 'name',
      'label': 'Your name',
      'validators': ['required'],
    },
    {
      'type': 'searchableDropdown', // searches the 'venues' source
      'id': 'venue',
      'label': 'Venue',
      'searchSource': 'venues',
    },
    {
      'type': 'repeater', // extendable section
      'id': 'guests',
      'itemLabel': 'Guest {index}',
      'addLabel': 'Add another guest',
      'minItems': 1,
      'maxItems': 4,
      'fields': [
        {'type': 'text', 'id': 'guestName', 'label': 'Guest name'},
        {
          'type': 'dropdown',
          'id': 'meal',
          'label': 'Meal',
          'enum': 'MealChoice',
        },
      ],
    },
    {
      'type': 'searchableDropdown',
      'id': 'topics',
      'label': 'Topics you like',
      'multiple': true, // value is a List
      'allowCustomOptions': true, // users can add their own
      'options': ['Web', 'Testing', 'Design'],
    },
    {
      'type': 'radioGroup',
      'id': 'seating',
      'label': 'Seating',
      'optionStyle': 'button', // standard | card | chip | button
      'options': ['Front', 'Middle', 'Back'],
      'style': {'activeColor': '#00897B'},
    },
  ],
};

class RsvpPage extends StatefulWidget {
  const RsvpPage({super.key});

  @override
  State<RsvpPage> createState() => _RsvpPageState();
}

class _RsvpPageState extends State<RsvpPage> {
  final controller = DynamicFormController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('RSVP')),
      body: DynamicForm(
        controller: controller,
        json: rsvpForm,
        showSubmitButton: true,
        // guests -> List<Map>, topics -> List, seating -> 'Front'
        onSubmit: (data) => ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('RSVP: $data'))),
      ),
    );
  }
}
