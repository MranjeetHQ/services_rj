/// A country with its international dial code, used by the optional country
/// code picker of phone fields (`"countryCode": true`).
class CountryDialCode {
  /// Creates an entry.
  const CountryDialCode(this.iso, this.name, this.dial);

  /// ISO 3166-1 alpha-2 code, e.g. `IN`.
  final String iso;

  /// English country name.
  final String name;

  /// Dial code with a leading `+`, e.g. `+91`.
  final String dial;

  /// Flag emoji built from [iso].
  String get flag => String.fromCharCodes([
    for (final c in iso.toUpperCase().codeUnits) 0x1F1E6 + c - 0x41,
  ]);

  @override
  bool operator ==(Object other) =>
      other is CountryDialCode && other.iso == iso;

  @override
  int get hashCode => iso.hashCode;

  @override
  String toString() => '$iso $dial';
}

/// Dial code lookups for phone fields.
class CountryDialCodes {
  const CountryDialCodes._();

  /// Every supported country, most commonly used first.
  static const List<CountryDialCode> all = [
    CountryDialCode('IN', 'India', '+91'),
    CountryDialCode('US', 'United States', '+1'),
    CountryDialCode('CA', 'Canada', '+1'),
    CountryDialCode('GB', 'United Kingdom', '+44'),
    CountryDialCode('AE', 'United Arab Emirates', '+971'),
    CountryDialCode('SA', 'Saudi Arabia', '+966'),
    CountryDialCode('SG', 'Singapore', '+65'),
    CountryDialCode('AU', 'Australia', '+61'),
    CountryDialCode('NZ', 'New Zealand', '+64'),
    CountryDialCode('DE', 'Germany', '+49'),
    CountryDialCode('FR', 'France', '+33'),
    CountryDialCode('ES', 'Spain', '+34'),
    CountryDialCode('IT', 'Italy', '+39'),
    CountryDialCode('NL', 'Netherlands', '+31'),
    CountryDialCode('BE', 'Belgium', '+32'),
    CountryDialCode('CH', 'Switzerland', '+41'),
    CountryDialCode('AT', 'Austria', '+43'),
    CountryDialCode('SE', 'Sweden', '+46'),
    CountryDialCode('NO', 'Norway', '+47'),
    CountryDialCode('DK', 'Denmark', '+45'),
    CountryDialCode('FI', 'Finland', '+358'),
    CountryDialCode('IE', 'Ireland', '+353'),
    CountryDialCode('PT', 'Portugal', '+351'),
    CountryDialCode('PL', 'Poland', '+48'),
    CountryDialCode('CZ', 'Czechia', '+420'),
    CountryDialCode('GR', 'Greece', '+30'),
    CountryDialCode('TR', 'Turkey', '+90'),
    CountryDialCode('RU', 'Russia', '+7'),
    CountryDialCode('UA', 'Ukraine', '+380'),
    CountryDialCode('RO', 'Romania', '+40'),
    CountryDialCode('HU', 'Hungary', '+36'),
    CountryDialCode('BG', 'Bulgaria', '+359'),
    CountryDialCode('RS', 'Serbia', '+381'),
    CountryDialCode('HR', 'Croatia', '+385'),
    CountryDialCode('IL', 'Israel', '+972'),
    CountryDialCode('EG', 'Egypt', '+20'),
    CountryDialCode('ZA', 'South Africa', '+27'),
    CountryDialCode('NG', 'Nigeria', '+234'),
    CountryDialCode('KE', 'Kenya', '+254'),
    CountryDialCode('GH', 'Ghana', '+233'),
    CountryDialCode('ET', 'Ethiopia', '+251'),
    CountryDialCode('TZ', 'Tanzania', '+255'),
    CountryDialCode('UG', 'Uganda', '+256'),
    CountryDialCode('MA', 'Morocco', '+212'),
    CountryDialCode('DZ', 'Algeria', '+213'),
    CountryDialCode('TN', 'Tunisia', '+216'),
    CountryDialCode('QA', 'Qatar', '+974'),
    CountryDialCode('KW', 'Kuwait', '+965'),
    CountryDialCode('BH', 'Bahrain', '+973'),
    CountryDialCode('OM', 'Oman', '+968'),
    CountryDialCode('JO', 'Jordan', '+962'),
    CountryDialCode('LB', 'Lebanon', '+961'),
    CountryDialCode('IQ', 'Iraq', '+964'),
    CountryDialCode('IR', 'Iran', '+98'),
    CountryDialCode('PK', 'Pakistan', '+92'),
    CountryDialCode('BD', 'Bangladesh', '+880'),
    CountryDialCode('LK', 'Sri Lanka', '+94'),
    CountryDialCode('NP', 'Nepal', '+977'),
    CountryDialCode('BT', 'Bhutan', '+975'),
    CountryDialCode('MV', 'Maldives', '+960'),
    CountryDialCode('AF', 'Afghanistan', '+93'),
    CountryDialCode('MM', 'Myanmar', '+95'),
    CountryDialCode('TH', 'Thailand', '+66'),
    CountryDialCode('VN', 'Vietnam', '+84'),
    CountryDialCode('MY', 'Malaysia', '+60'),
    CountryDialCode('ID', 'Indonesia', '+62'),
    CountryDialCode('PH', 'Philippines', '+63'),
    CountryDialCode('KH', 'Cambodia', '+855'),
    CountryDialCode('LA', 'Laos', '+856'),
    CountryDialCode('CN', 'China', '+86'),
    CountryDialCode('HK', 'Hong Kong', '+852'),
    CountryDialCode('MO', 'Macao', '+853'),
    CountryDialCode('TW', 'Taiwan', '+886'),
    CountryDialCode('JP', 'Japan', '+81'),
    CountryDialCode('KR', 'South Korea', '+82'),
    CountryDialCode('MN', 'Mongolia', '+976'),
    CountryDialCode('KZ', 'Kazakhstan', '+7'),
    CountryDialCode('UZ', 'Uzbekistan', '+998'),
    CountryDialCode('MX', 'Mexico', '+52'),
    CountryDialCode('BR', 'Brazil', '+55'),
    CountryDialCode('AR', 'Argentina', '+54'),
    CountryDialCode('CL', 'Chile', '+56'),
    CountryDialCode('CO', 'Colombia', '+57'),
    CountryDialCode('PE', 'Peru', '+51'),
    CountryDialCode('VE', 'Venezuela', '+58'),
    CountryDialCode('EC', 'Ecuador', '+593'),
    CountryDialCode('UY', 'Uruguay', '+598'),
    CountryDialCode('PY', 'Paraguay', '+595'),
    CountryDialCode('BO', 'Bolivia', '+591'),
    CountryDialCode('CR', 'Costa Rica', '+506'),
    CountryDialCode('PA', 'Panama', '+507'),
    CountryDialCode('GT', 'Guatemala', '+502'),
    CountryDialCode('DO', 'Dominican Republic', '+1'),
    CountryDialCode('JM', 'Jamaica', '+1'),
    CountryDialCode('CU', 'Cuba', '+53'),
    CountryDialCode('MU', 'Mauritius', '+230'),
    CountryDialCode('FJ', 'Fiji', '+679'),
    CountryDialCode('IS', 'Iceland', '+354'),
    CountryDialCode('LU', 'Luxembourg', '+352'),
    CountryDialCode('MT', 'Malta', '+356'),
    CountryDialCode('CY', 'Cyprus', '+357'),
    CountryDialCode('EE', 'Estonia', '+372'),
    CountryDialCode('LV', 'Latvia', '+371'),
    CountryDialCode('LT', 'Lithuania', '+370'),
    CountryDialCode('SK', 'Slovakia', '+421'),
    CountryDialCode('SI', 'Slovenia', '+386'),
    CountryDialCode('BA', 'Bosnia and Herzegovina', '+387'),
    CountryDialCode('AL', 'Albania', '+355'),
    CountryDialCode('MK', 'North Macedonia', '+389'),
    CountryDialCode('GE', 'Georgia', '+995'),
    CountryDialCode('AM', 'Armenia', '+374'),
    CountryDialCode('AZ', 'Azerbaijan', '+994'),
    CountryDialCode('ZW', 'Zimbabwe', '+263'),
    CountryDialCode('ZM', 'Zambia', '+260'),
    CountryDialCode('BW', 'Botswana', '+267'),
    CountryDialCode('NA', 'Namibia', '+264'),
    CountryDialCode('MZ', 'Mozambique', '+258'),
    CountryDialCode('AO', 'Angola', '+244'),
    CountryDialCode('SN', 'Senegal', '+221'),
    CountryDialCode('CI', 'Ivory Coast', '+225'),
    CountryDialCode('CM', 'Cameroon', '+237'),
    CountryDialCode('RW', 'Rwanda', '+250'),
    CountryDialCode('SD', 'Sudan', '+249'),
    CountryDialCode('LY', 'Libya', '+218'),
    CountryDialCode('YE', 'Yemen', '+967'),
    CountryDialCode('SY', 'Syria', '+963'),
    CountryDialCode('PS', 'Palestine', '+970'),
  ];

  /// The first country with this ISO code (`IN`) or dial code (`+91`, `91`);
  /// `null` when unknown. Dial codes shared by several countries (`+1`,
  /// `+7`) resolve to the first listed.
  static CountryDialCode? lookup(
    String? isoOrDial, {
    Iterable<CountryDialCode>? among,
  }) {
    if (isoOrDial == null || isoOrDial.trim().isEmpty) return null;
    final key = isoOrDial.trim();
    final dial = key.startsWith('+') ? key : '+$key';
    final iso = key.toUpperCase();
    for (final c in among ?? all) {
      if (c.iso == iso || c.dial == dial) return c;
    }
    return null;
  }

  /// Resolves a list of ISO or dial codes into countries, keeping the order
  /// given. An empty or null [codes] means [all].
  static List<CountryDialCode> resolve(Iterable<Object?>? codes) {
    if (codes == null) return all;
    final list = <CountryDialCode>[
      for (final c in codes) ?lookup(c?.toString()),
    ];
    return list.isEmpty ? all : list.toSet().toList();
  }

  /// Countries matching [query], best matches first.
  ///
  /// Matches the country name (anywhere, word starts and prefixes rank
  /// higher), the ISO code (`gb`) and the dial code with or without the
  /// plus (`+44`, `44`). A numeric query matches dial codes that start with
  /// it. An empty query returns everything.
  static List<CountryDialCode> search(
    String query, {
    Iterable<CountryDialCode>? among,
  }) {
    final list = (among ?? all).toList();
    final q = query.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    if (q.isEmpty) return list;
    final digits = q.startsWith('+') ? q.substring(1) : q;
    final numeric = RegExp(r'^\d+$').hasMatch(digits);

    int? rank(CountryDialCode c) {
      final name = c.name.toLowerCase();
      final dial = c.dial.substring(1);
      if (numeric) {
        if (dial == digits) return 0;
        return dial.startsWith(digits) ? 2 : null;
      }
      if (c.iso.toLowerCase() == q) return 0;
      if (name == q) return 0;
      if (name.startsWith(q)) return 1;
      if (name.split(' ').any((w) => w.startsWith(q))) return 3;
      if (name.contains(q)) return 4;
      return null;
    }

    final ranked =
        <(int, int, CountryDialCode)>[
          for (var i = 0; i < list.length; i++)
            if (rank(list[i]) case final r?) (r, i, list[i]),
        ]..sort(
          (a, b) => a.$1 != b.$1 ? a.$1.compareTo(b.$1) : a.$2.compareTo(b.$2),
        );
    return [for (final r in ranked) r.$3];
  }

  /// Splits `+919876543210` into dial code and national number using the
  /// longest matching dial code. A value without `+` has no dial code.
  static ({String? dial, String national}) split(
    String? value, {
    Iterable<CountryDialCode>? among,
  }) {
    final v = (value ?? '').trim();
    if (!v.startsWith('+')) return (dial: null, national: v);
    final digits = v.substring(1).replaceAll(RegExp(r'[^\d]'), '');
    final candidates = {for (final c in among ?? all) c.dial}.toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    for (final dial in candidates) {
      final d = dial.substring(1);
      if (digits.startsWith(d)) {
        return (dial: dial, national: digits.substring(d.length));
      }
    }
    return (dial: null, national: digits);
  }
}
