import 'package:flutter/material.dart';

import '../form_page.dart';
import '../forms/field_gallery_forms.dart';
import '../widgets/demo_widgets.dart';
import 'pluggable_adapters.dart';

Widget _page(String title, Map<String, dynamic> json) {
  registerDemoAdapters();
  return FormPage(title: title, json: json);
}

/// Home-screen entries of the field gallery: every `FieldType`, grouped.
final List<DemoEntry> galleryDemos = [
  DemoEntry(
    icon: Icons.text_fields,
    title: 'Gallery: text inputs',
    subtitle: 'text, textarea, password, email, number, phone, otp, pin...',
    builder: (_) => _page('Text inputs', textInputsGalleryForm),
  ),
  DemoEntry(
    icon: Icons.tune,
    title: 'Gallery: dates and numbers',
    subtitle: 'date, time, slider, range, rating, stepper, colour',
    builder: (_) => _page('Dates and numbers', dateNumericGalleryForm),
  ),
  DemoEntry(
    icon: Icons.checklist,
    title: 'Gallery: selection and toggles',
    subtitle: 'dropdowns, radios, chips, autocomplete, country/state/city',
    builder: (_) => _page('Selection and toggles', selectionGalleryForm),
  ),
  DemoEntry(
    icon: Icons.perm_media_outlined,
    title: 'Gallery: media and files',
    subtitle: 'image, camera and file pickers',
    builder: (_) => _page('Media and files', mediaGalleryForm),
  ),
  DemoEntry(
    icon: Icons.view_agenda_outlined,
    title: 'Gallery: layout and containers',
    subtitle: 'label, divider, spacer, group, expansion, repeater, hidden',
    builder: (_) => _page('Layout and containers', layoutGalleryForm),
  ),
  DemoEntry(
    icon: Icons.extension_outlined,
    title: 'Gallery: pluggable adapters',
    subtitle: 'signature, scanners, editors and a custom mood picker',
    builder: (_) => _page('Pluggable adapters', adaptersGalleryForm),
  ),
];
