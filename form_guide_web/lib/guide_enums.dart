import 'package:services_rj/services_rj.dart';

enum Cuisine { northIndian, southIndian, chinese, continental }

enum ShirtSize { xs, s, m, l, xl }

enum Seniority { intern, junior, mid, senior, staff, principal }

const guideEnumNames = ['Cuisine', 'ShirtSize', 'Seniority'];

/// Search sources the guide's live examples reference with
/// `"searchSource"`. They answer from local data after a short delay, the
/// way a real API would.
const guideSearchSourceNames = ['guideCities', 'guideCitiesByState'];

const _citiesByState = {
  'Gujarat': ['Ahmedabad', 'Surat', 'Vadodara', 'Rajkot', 'Bhavnagar'],
  'Maharashtra': ['Mumbai', 'Pune', 'Nagpur', 'Nashik', 'Aurangabad'],
  'Karnataka': ['Bengaluru', 'Mysuru', 'Mangaluru', 'Hubballi'],
  'Tamil Nadu': ['Chennai', 'Coimbatore', 'Madurai', 'Tiruchirappalli'],
  'Rajasthan': ['Jaipur', 'Jodhpur', 'Udaipur', 'Kota', 'Ajmer'],
};

List<OptionItem> _match(Iterable<(String, String)> cities, String query) {
  final q = query.trim().toLowerCase();
  return [
    for (final (city, state) in cities)
      if (city.toLowerCase().contains(q))
        OptionItem(label: city, value: city, description: state),
  ];
}

/// Enums and search sources the guide's live examples use.
void registerGuideEnums() {
  FormEnumRegistry.register('Cuisine', Cuisine.values);
  FormEnumRegistry.register(
    'ShirtSize',
    ShirtSize.values,
    label: (s) => s.name.toUpperCase(),
  );
  FormEnumRegistry.register('Seniority', Seniority.values);

  final all = [
    for (final e in _citiesByState.entries)
      for (final city in e.value) (city, e.key),
  ];
  FormSearchSources.register('guideCities', (query, formData) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return _match(all, query);
  });
  FormSearchSources.register('guideCitiesByState', (query, formData) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final state = formData['state'] as String?;
    if (state == null) return const [];
    return _match([for (final c in _citiesByState[state]!) (c, state)], query);
  });
}

/// States offered by the dependent-dropdown example.
List<String> get guideStates => _citiesByState.keys.toList();
