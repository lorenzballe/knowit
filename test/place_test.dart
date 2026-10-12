import 'dart:convert';
import 'dart:io';

import 'package:astuto/models/place.dart';
import 'package:flutter_test/flutter_test.dart';

/// Where a reader is, as much of it as is kept, and which cards belong
/// there. The fit cases are shared with the server (tool/places/), so the
/// phone and the server deal local cards the same way.
void main() {
  group('a place as the phone describes it', () {
    test('keeps the city and the region, and rounds the point', () {
      final Place place = Place.fromPhone(
        isoCountry: 'it',
        adminArea: 'Emilia-Romagna',
        locality: 'Formigine',
        lat: 44.57312,
        lon: 10.84651,
      );
      expect(place.country, 'IT');
      expect(place.region, 'IT-45');
      expect(place.city, 'Formigine');
      expect(place.lat, 44.6);
      expect(place.lon, 10.8);
      expect(place.key, 'IT-45/formigine');
    });

    test('names a region by any of its spellings', () {
      expect(regionCode('IT', 'Piedmont'), 'IT-21');
      expect(regionCode('IT', 'Piemonte'), 'IT-21');
      expect(regionCode('IT', 'Friuli Venezia Giulia'), 'IT-36');
      expect(regionCode('IT', 'Friuli-Venezia Giulia'), 'IT-36');
      expect(regionCode('IT', "Valle d'Aosta"), 'IT-23');
      expect(regionCode('IT', 'Aosta Valley'), 'IT-23');
      expect(regionCode('IT', 'Trentino-Alto Adige/Südtirol'), 'IT-32');
      expect(regionCode('IT', 'Apulia'), 'IT-75');
      expect(regionCode('it', 'sicily'), 'IT-82');
    });

    test('has every one of Italy\'s twenty regions', () {
      final Set<String> codes = {
        for (final String name in [
          'Abruzzo',
          'Basilicata',
          'Calabria',
          'Campania',
          'Emilia-Romagna',
          'Friuli-Venezia Giulia',
          'Lazio',
          'Liguria',
          'Lombardy',
          'Marche',
          'Molise',
          'Piedmont',
          'Apulia',
          'Sardinia',
          'Sicily',
          'Tuscany',
          'Trentino-Alto Adige',
          'Umbria',
          'Aosta Valley',
          'Veneto',
        ])
          regionCode('IT', name)!,
      };
      expect(codes, hasLength(20));
    });

    test('leaves a region it cannot name without a code', () {
      expect(regionCode('FR', "Provence-Alpes-Côte d'Azur"), isNull);
      expect(regionCode('IT', 'Atlantis'), isNull);
      final Place place = Place.fromPhone(
        isoCountry: 'FR',
        adminArea: 'Bretagne',
      );
      expect(place.region, isNull);
      expect(place.regionName, 'Bretagne');
      expect(place.key, 'FR');
    });

    test('travels as JSON and comes back the same', () {
      final Place place = Place.fromPhone(
        isoCountry: 'IT',
        adminArea: 'Piedmont',
        locality: 'Turin',
        lat: 45.0703,
        lon: 7.6869,
        at: DateTime.utc(2026, 10, 12, 9),
      );
      final Place? back = Place.fromJson(
        jsonDecode(jsonEncode(place.toJson())),
      );
      expect(back, isNotNull);
      expect(back!.samePlaceAs(place), isTrue);
      expect(back.lat, 45.1);
      expect(back.lon, 7.7);
      expect(back.at, DateTime.utc(2026, 10, 12, 9));
    });

    test('refuses a place with no country', () {
      expect(Place.fromJson({'city': 'Modena'}), isNull);
      expect(Place.fromJson({'country': 'Italy'}), isNull);
      expect(Place.fromJson('IT'), isNull);
    });

    test('makes handles out of names', () {
      expect(slug("Reggio nell'Emilia"), 'reggio-nell-emilia');
      expect(slug('Forlì'), 'forli');
      expect(slug('  San Donà di Piave '), 'san-dona-di-piave');
    });
  });

  group('which cards belong where a reader is', () {
    final Map<String, dynamic> shared = jsonDecode(
      File('tool/places/fit_cases.json').readAsStringSync(),
    );
    for (final Map<String, dynamic> c
        in (shared['cases'] as List).cast<Map<String, dynamic>>()) {
      test(c['name'], () {
        final CardPlace card = CardPlace.fromJson(c['card'])!;
        final Place? reader = Place.fromJson(c['reader']);
        expect(placeFit(card, reader).name, c['fit']);
      });
    }
  });

  test('measures distance along the ground', () {
    // Modena to Bologna, centre to centre: about 37 km.
    expect(distanceKm(44.647, 10.925, 44.494, 11.343), closeTo(37, 2));
    expect(distanceKm(45.0, 7.0, 45.0, 7.0), 0);
  });
}
