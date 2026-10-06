// Copy of the Getting started app in the docs. Run it with
// `flutter run -t lib/quick_start.dart`. A test in form_guide_web keeps the
// docs and this file identical.
import 'package:flutter/material.dart';
import 'package:services_rj/services_rj.dart';

void main() => runApp(const MaterialApp(home: ProfilePage()));

const profileForm = {
  'padding': 'standard',
  'fields': [
    {
      'type': 'text',
      'id': 'fullName',
      'label': 'Full name',
      'validators': ['required'],
    },
    {
      'type': 'searchableDropdown',
      'id': 'city',
      'label': 'City',
      'options': ['Ahmedabad', 'Bengaluru', 'Mumbai', 'Pune', 'Surat'],
    },
    {
      'type': 'radioGroup',
      'id': 'plan',
      'label': 'Plan',
      'optionStyle': 'card',
      'options': [
        {'label': 'Free', 'value': 'free', 'description': 'For trying out'},
        {'label': 'Pro', 'value': 'pro', 'description': 'For teams'},
      ],
    },
    {'type': 'switch', 'id': 'newsletter', 'label': 'Send me updates'},
  ],
};

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final controller = DynamicFormController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: DynamicForm(
        controller: controller,
        json: profileForm, // a Map, or the JSON string from your API
        showSubmitButton: true,
        onSubmit: (data) => ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Saved: $data'))),
      ),
    );
  }
}
