import 'package:services_rj/services_rj.dart';

enum Cuisine { northIndian, southIndian, chinese, continental }

enum ShirtSize { xs, s, m, l, xl }

enum Seniority { intern, junior, mid, senior, staff, principal }

const guideEnumNames = ['Cuisine', 'ShirtSize', 'Seniority'];

/// Enums the guide's live examples reference with `"enum"`.
void registerGuideEnums() {
  FormEnumRegistry.register('Cuisine', Cuisine.values);
  FormEnumRegistry.register(
    'ShirtSize',
    ShirtSize.values,
    label: (s) => s.name.toUpperCase(),
  );
  FormEnumRegistry.register('Seniority', Seniority.values);
}
