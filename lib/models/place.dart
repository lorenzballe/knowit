import 'dart:math' as math;

/// Where a reader is, as much of it as Astute keeps: a country, a region, a
/// city, and a point rounded to a tenth of a degree (about ten kilometres).
///
/// Never the street and never the exact position. The phone may know it,
/// and the app reads it once, names the place on the phone itself, and
/// throws the position away; only this leaves the phone. It is enough to
/// deal a card about the city a reader lives in, and too little to find
/// their door. See docs/PLACES.md.
class Place {
  const Place({
    required this.country,
    this.region,
    this.regionName,
    this.city,
    this.lat,
    this.lon,
    this.at,
  });

  /// ISO 3166-1 alpha-2, upper case: `IT`.
  final String country;

  /// ISO 3166-2, when the region is one this app can name: `IT-45`.
  final String? region;

  /// The region as the phone named it, in English: `Emilia-Romagna`.
  final String? regionName;

  /// The city, town or village, in English: `Modena`.
  final String? city;

  /// The point, rounded to one decimal: about eleven kilometres north to
  /// south. Enough to tell which city's cards are near, and no closer.
  final double? lat;
  final double? lon;

  /// When the phone said so.
  final DateTime? at;

  /// A place as the phone describes it, put into the shape that is kept:
  /// the country upper-cased, the region given its code where one is known,
  /// the point rounded.
  factory Place.fromPhone({
    required String isoCountry,
    String? adminArea,
    String? locality,
    double? lat,
    double? lon,
    DateTime? at,
  }) {
    final String country = isoCountry.trim().toUpperCase();
    final String? area = _blankToNull(adminArea);
    return Place(
      country: country,
      region: regionCode(country, area),
      regionName: area,
      city: _blankToNull(locality),
      lat: lat == null ? null : roundCoordinate(lat),
      lon: lon == null ? null : roundCoordinate(lon),
      at: at,
    );
  }

  /// The one-decimal rounding every kept coordinate goes through.
  static double roundCoordinate(double value) =>
      (value * 10).roundToDouble() / 10;

  /// A short handle for the place, most precise first: `IT-45/modena`,
  /// `IT-45`, or `IT`. For grouping and for the cards a place still lacks;
  /// matching a card goes through [placeFit], not through this.
  String get key {
    final String top = region ?? country;
    final String? c = city;
    return c == null ? top : '$top/${slug(c)}';
  }

  Map<String, Object?> toJson() => {
    'country': country,
    'region': ?region,
    'regionName': ?regionName,
    'city': ?city,
    'lat': ?lat,
    'lon': ?lon,
    if (at != null) 'at': at!.toUtc().toIso8601String(),
  };

  static Place? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final Object? country = raw['country'];
    if (country is! String || !RegExp(r'^[A-Z]{2}$').hasMatch(country)) {
      return null;
    }
    String? text(String key) {
      final Object? value = raw[key];
      return value is String && value.trim().isNotEmpty ? value : null;
    }

    double? number(String key) {
      final Object? value = raw[key];
      return value is num ? value.toDouble() : null;
    }

    final String? at = text('at');
    return Place(
      country: country,
      region: text('region'),
      regionName: text('regionName'),
      city: text('city'),
      lat: number('lat'),
      lon: number('lon'),
      at: at == null ? null : DateTime.tryParse(at),
    );
  }

  /// Whether [other] is the same place, ignoring when each was read.
  bool samePlaceAs(Place? other) =>
      other != null &&
      other.country == country &&
      other.region == region &&
      other.city == city;

  @override
  String toString() => 'Place($key)';
}

/// Where a card belongs, as its `place` says (tool/cards/schema.json).
///
/// A country card is for anyone in that country; a region card for anyone
/// in that region; a city card for anyone within [km] of its point, which
/// is how a card about Modena reaches a reader in Formigine, ten kilometres
/// out, without anybody listing every village around it.
class CardPlace {
  const CardPlace({
    required this.country,
    this.region,
    this.city,
    this.lat,
    this.lon,
    this.km,
  });

  final String country;
  final String? region;
  final String? city;
  final double? lat;
  final double? lon;
  final double? km;

  static CardPlace? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final Object? country = raw['country'];
    if (country is! String || country.isEmpty) return null;
    double? number(String key) {
      final Object? value = raw[key];
      return value is num ? value.toDouble() : null;
    }

    final Object? region = raw['region'];
    final Object? city = raw['city'];
    return CardPlace(
      country: country,
      region: region is String && region.isNotEmpty ? region : null,
      city: city is String && city.isNotEmpty ? city : null,
      lat: number('lat'),
      lon: number('lon'),
      km: number('km'),
    );
  }

  Map<String, Object?> toJson() => {
    'country': country,
    'region': ?region,
    'city': ?city,
    'lat': ?lat,
    'lon': ?lon,
    'km': ?km,
  };
}

/// How closely a card's place fits a reader's, nearest last so the order
/// can be compared: a city card beats a region card beats a country card.
enum PlaceFit { none, country, region, city }

/// How a card that belongs to [card] fits a reader who lives at [reader].
///
/// - A city card fits when the reader's point is within the card's `km` of
///   the card's point. Without both points it does not fit: a card about a
///   city is never dealt on a guess.
/// - A region card fits when the regions are the same.
/// - A country card fits anyone in the country.
///
/// A card in another country never fits.
PlaceFit placeFit(CardPlace card, Place? reader) {
  if (reader == null || card.country != reader.country) return PlaceFit.none;
  if (card.city != null) {
    final double? lat = card.lat, lon = card.lon, km = card.km;
    final double? rLat = reader.lat, rLon = reader.lon;
    if (lat == null || lon == null || km == null) return PlaceFit.none;
    if (rLat == null || rLon == null) return PlaceFit.none;
    return distanceKm(lat, lon, rLat, rLon) <= km
        ? PlaceFit.city
        : PlaceFit.none;
  }
  if (card.region != null) {
    return card.region == reader.region ? PlaceFit.region : PlaceFit.none;
  }
  return PlaceFit.country;
}

/// The distance along the ground between two points, in kilometres.
double distanceKm(double lat1, double lon1, double lat2, double lon2) {
  const double earthKm = 6371.0;
  double rad(double degrees) => degrees * math.pi / 180;
  final double dLat = rad(lat2 - lat1);
  final double dLon = rad(lon2 - lon1);
  final double a =
      math.pow(math.sin(dLat / 2), 2) +
      math.cos(rad(lat1)) *
          math.cos(rad(lat2)) *
          math.pow(math.sin(dLon / 2), 2);
  return 2 * earthKm * math.asin(math.min(1, math.sqrt(a)));
}

/// A name as a handle: lower case, plain letters, words joined by `-`.
/// `Reggio nell'Emilia` → `reggio-nell-emilia`.
String slug(String name) {
  final String plain = _fold(name.toLowerCase());
  return plain
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
}

/// The ISO 3166-2 code for a region the phone named, where this app knows
/// the country's regions; null otherwise. Phones name regions in their own
/// language and in more than one spelling, so every name a region goes by
/// is listed: `Piedmont`, `Piemonte`.
String? regionCode(String country, String? name) {
  if (name == null) return null;
  final Map<String, String>? regions = _regionsByName[country.toUpperCase()];
  if (regions == null) return null;
  return regions[_regionHandle(name)];
}

/// The regions this app can name, by every name they go by, folded the way
/// [_regionHandle] folds a phone's.
final Map<String, Map<String, String>> _regionsByName = {
  'IT': {
    for (final MapEntry<String, List<String>> region in _italy.entries)
      for (final String name in region.value) _regionHandle(name): region.key,
  },
};

/// Italy's twenty regions (ISO 3166-2:IT), with the names a phone, a map or
/// a person might give each: English, Italian, and the local ones.
const Map<String, List<String>> _italy = {
  'IT-65': ['Abruzzo', 'Abruzzi'],
  'IT-77': ['Basilicata', 'Lucania'],
  'IT-78': ['Calabria'],
  'IT-72': ['Campania'],
  'IT-45': ['Emilia-Romagna', 'Emilia Romagna'],
  'IT-36': ['Friuli-Venezia Giulia', 'Friuli Venezia Giulia', 'Friûl'],
  'IT-62': ['Lazio', 'Latium'],
  'IT-42': ['Liguria'],
  'IT-25': ['Lombardy', 'Lombardia'],
  'IT-57': ['Marche', 'The Marches', 'Marches'],
  'IT-67': ['Molise'],
  'IT-21': ['Piedmont', 'Piemonte'],
  'IT-75': ['Apulia', 'Puglia'],
  'IT-88': ['Sardinia', 'Sardegna'],
  'IT-82': ['Sicily', 'Sicilia'],
  'IT-52': ['Tuscany', 'Toscana'],
  'IT-32': [
    'Trentino-Alto Adige',
    'Trentino-South Tyrol',
    'Trentino-Alto Adige/Südtirol',
    'Trentino-Südtirol',
    'Trentino Alto Adige',
  ],
  'IT-55': ['Umbria'],
  'IT-23': ["Aosta Valley", "Valle d'Aosta", "Vallée d'Aoste", 'Valle dAosta'],
  'IT-34': ['Veneto'],
};

/// A region's name reduced to what two spellings of it share.
String _regionHandle(String name) =>
    _fold(name.toLowerCase())
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ');

/// Accented Latin letters to plain ones, for handles.
String _fold(String text) {
  const String from = 'àáâãäåèéêëìíîïòóôõöùúûüñçýÿ';
  const String to = 'aaaaaaeeeeiiiiooooouuuuncyy';
  final StringBuffer out = StringBuffer();
  for (final int rune in text.runes) {
    final String char = String.fromCharCode(rune);
    final int i = from.indexOf(char);
    out.write(i < 0 ? char : to[i]);
  }
  return out.toString();
}

String? _blankToNull(String? text) =>
    text == null || text.trim().isEmpty ? null : text.trim();
