/// The country a stamp prints: two letters, and only ones that are true.
///
/// The canvas stamped every card with a country, because its cards were
/// written for it. The bank's are not: a card is tagged with the part of
/// the world it is set in (`Pill.region`), and only a card about a reader's
/// own place carries a country (`Pill.place`). So a stamp says a country
/// when one is known, and is a stamp without one otherwise — an app about
/// not being fooled does not print a guess on a card.
///
/// Known means, in order: the card's own place; the section's word for the
/// card (`"codes": {"<card id>": "HU"}`), for the server to name what the
/// bank does not; or the country the question names, by its name or a
/// place in it and never by an adjective — "in English" is a language, not
/// England. Only a country in the part of the world the card is set in
/// counts, and none at all when the question names places in two parts of
/// it: a card about Africa that names the Berlin Conference is not German,
/// and lamb shipped from New Zealand to Britain is neither. Phrases that
/// hold a country's name without being it (Isaiah Berlin, the East India
/// Company, Latin America) are taken out before anything is looked for.
/// Every stamp this gives a card of the bank, 336 of them when it was
/// written, was read through by hand.
library;

import '../../../models/pill.dart';

/// The states of the United States, which a question names a place in the
/// country by as often as by the country itself.
const List<String> _kStates = [
  'Alabama',
  'Alaska',
  'Arizona',
  'Arkansas',
  'California',
  'Colorado',
  'Connecticut',
  'Delaware',
  'Florida',
  'Hawaii',
  'Idaho',
  'Illinois',
  'Indiana',
  'Iowa',
  'Kansas',
  'Kentucky',
  'Louisiana',
  'Maine',
  'Maryland',
  'Massachusetts',
  'Michigan',
  'Minnesota',
  'Mississippi',
  'Missouri',
  'Montana',
  'Nebraska',
  'Nevada',
  'New Hampshire',
  'New Jersey',
  'New Mexico',
  'New York',
  'North Carolina',
  'North Dakota',
  'Ohio',
  'Oklahoma',
  'Oregon',
  'Pennsylvania',
  'Rhode Island',
  'South Carolina',
  'South Dakota',
  'Tennessee',
  'Texas',
  'Utah',
  'Vermont',
  'Virginia',
  'Washington',
  'West Virginia',
  'Wisconsin',
  'Wyoming',
];

/// The names a question gives a country by, for each part of the world the
/// bank sets cards in.
///
/// The United Kingdom is `UK`, as the canvas and every European stamp
/// catalogue have it, rather than ISO's `GB`.
const Map<String, Map<String, List<String>>> kStampCountries = {
  'europe': {
    'AT': ['Austria', 'Vienna'],
    'BE': ['Belgium', 'Brussels'],
    'CH': ['Switzerland', 'Geneva', 'Zurich'],
    'CZ': ['Czechia', 'Czech Republic', 'Prague'],
    'DE': ['Germany', 'Berlin', 'Munich', 'Hamburg'],
    'DK': ['Denmark', 'Copenhagen'],
    'ES': ['Spain', 'Madrid', 'Barcelona', 'Seville'],
    'FI': ['Finland', 'Helsinki'],
    'FR': ['France', 'Paris', 'Lyon', 'Marseille'],
    'UK': [
      'Britain',
      'Great Britain',
      'United Kingdom',
      'England',
      'Scotland',
      'Wales',
      'Northern Ireland',
      'London',
      'Edinburgh',
      'Manchester',
    ],
    'GR': ['Greece', 'Athens'],
    'HU': ['Hungary', 'Budapest'],
    'IE': ['Ireland', 'Dublin'],
    'IS': ['Iceland', 'Reykjavik'],
    'IT': [
      'Italy',
      'Rome',
      'Venice',
      'Florence',
      'Milan',
      'Naples',
      'Sicily',
      'Turin',
      'Bologna',
    ],
    'NL': ['Netherlands', 'Holland', 'Amsterdam'],
    'NO': ['Norway', 'Oslo'],
    'PL': ['Poland', 'Warsaw', 'Krakow'],
    'PT': ['Portugal', 'Lisbon'],
    'RU': ['Russia', 'Moscow', 'St Petersburg', 'Soviet Union', 'USSR'],
    'SE': ['Sweden', 'Stockholm'],
    'UA': ['Ukraine', 'Kyiv'],
    'TR': ['Istanbul'],
  },
  'americas': {
    'US': [
      'United States',
      'USA',
      'America',
      'Chicago',
      'Los Angeles',
      'Hollywood',
      ..._kStates,
    ],
    'CA': [
      'Canada',
      'Toronto',
      'Montreal',
      'Quebec',
      'Ontario',
      'British Columbia',
      'Newfoundland',
    ],
    'MX': ['Mexico'],
    'BR': ['Brazil', 'Rio de Janeiro', 'Sao Paulo'],
    'AR': ['Argentina', 'Buenos Aires'],
    'PE': ['Peru'],
    'CL': ['Chile'],
    'CO': ['Colombia'],
    'CU': ['Cuba', 'Havana'],
  },
  'asia': {
    'JP': ['Japan', 'Tokyo', 'Kyoto'],
    'CN': ['China', 'Beijing', 'Shanghai'],
    'HK': ['Hong Kong'],
    'IN': ['India', 'Delhi', 'Mumbai'],
    'KR': ['South Korea', 'Korea', 'Seoul'],
    'SG': ['Singapore'],
    'ID': ['Indonesia'],
    'TH': ['Thailand', 'Bangkok'],
    'VN': ['Vietnam'],
  },
  'middle_east': {
    'IL': ['Israel', 'Jerusalem'],
    'IR': ['Iran', 'Tehran'],
    'IQ': ['Iraq', 'Baghdad'],
    'EG': ['Egypt', 'Cairo'],
    'SA': ['Saudi Arabia'],
    'TR': ['Turkey', 'Istanbul', 'Ankara'],
    'SY': ['Syria', 'Damascus'],
    'JO': ['Jordan'],
  },
  'africa': {
    'ZA': ['South Africa'],
    'NG': ['Nigeria'],
    'KE': ['Kenya'],
    'EG': ['Egypt', 'Cairo'],
    'ET': ['Ethiopia'],
    'GH': ['Ghana'],
  },
  'oceania': {
    'AU': ['Australia', 'Sydney', 'Melbourne'],
    'NZ': ['New Zealand'],
  },
};

/// Phrases that hold a country's name without being the country, taken out
/// of a question before any is looked for.
const List<String> kNotPlaces = [
  'Isaiah Berlin',
  'Irving Berlin',
  'East India',
  'West India',
  'Latin America',
  'South America',
  'Central America',
  'North America',
  'North Korea',
  'New South Wales',
  'New England',
  'Jordan Peterson',
];

/// Every name, ready to search for: one pattern per country, whole words
/// only, by part of the world.
final Map<String, Map<String, RegExp>> _patterns = {
  for (final region in kStampCountries.entries)
    region.key: {
      for (final country in region.value.entries)
        country.key: RegExp(
          '\\b(${country.value.map(RegExp.escape).join('|')})\\b',
        ),
    },
};

/// The country [p] is stamped with, or null when none is known: its own
/// place, then [codes] (the section's word, by card id), then the one its
/// question names within its own part of the world.
String? stampCountry(Pill p, [Map<String, Object?> codes = const {}]) {
  final String? own = p.place?.country;
  if (own != null && own.isNotEmpty) {
    final String upper = own.toUpperCase();
    return upper == 'GB' ? 'UK' : upper;
  }
  final Object? said = codes[p.id];
  if (said is String && RegExp(r'^[A-Z]{2,3}$').hasMatch(said)) return said;
  final Map<String, RegExp>? names = _patterns[p.region];
  if (names == null) return null;
  String question = p.question;
  for (final String phrase in kNotPlaces) {
    question = question.replaceAll(phrase, '');
  }
  // A question that names places in two parts of the world is about both,
  // or about neither, and its stamp would be a guess either way. A country
  // that lies in both (Egypt, Turkey) is the card's own, whichever part of
  // the world the other list puts it in.
  for (final MapEntry<String, Map<String, RegExp>> other in _patterns.entries) {
    if (other.key == p.region) continue;
    for (final MapEntry<String, RegExp> e in other.value.entries) {
      if (!names.containsKey(e.key) && e.value.hasMatch(question)) return null;
    }
  }
  String? found;
  int at = 1 << 30;
  for (final MapEntry<String, RegExp> e in names.entries) {
    final RegExpMatch? m = e.value.firstMatch(question);
    if (m != null && m.start < at) {
      at = m.start;
      found = e.key;
    }
  }
  return found;
}
