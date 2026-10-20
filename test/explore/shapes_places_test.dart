// The country a stamp prints: only one that is true. The card's own place,
// then the section's word for it, then the country its question names
// within the part of the world it is set in — never an adjective, never a
// name that only holds a country's, and none when the question is about two
// parts of the world.
//
//   flutter test test/explore/shapes_places_test.dart
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:astuto/explore/blocks/shapes/places.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/models/place.dart';

/// A card asking [question], set in [region].
Pill _card(String question, {String region = 'europe', CardPlace? place}) =>
    Pill(
      id: 'test-card-1',
      topic: 'history',
      color: const Color(0xFF2E5E8C),
      ink: const Color(0xFFFFFFFF),
      tint: const Color(0xFF1B3A57),
      question: question,
      answer: '',
      barMove: '',
      source: '',
      region: region,
      place: place,
    );

void main() {
  test('a question that names a country is stamped with it', () {
    expect(stampCountry(_card('Why is Hungary’s parliament so big?')), 'HU');
    expect(stampCountry(_card('Why do Budapest’s baths stay hot?')), 'HU');
    expect(stampCountry(_card('Why does Japan bow?', region: 'asia')), 'JP');
    expect(
      stampCountry(_card('Who first mapped Peru?', region: 'americas')),
      'PE',
    );
  });

  test('the United Kingdom is UK, as the stamps have it', () {
    expect(stampCountry(_card('Why does London drive on the left?')), 'UK');
    expect(stampCountry(_card('Why is Scotland’s flag blue?')), 'UK');
    expect(
      stampCountry(
        _card(
          'Why is this street so narrow?',
          place: const CardPlace(country: 'GB'),
        ),
      ),
      'UK',
    );
  });

  test('the first country named is the one stamped', () {
    expect(
      stampCountry(
        _card(
          'Why is Minnesota colder than most of Canada?',
          region: 'americas',
        ),
      ),
      'US',
    );
    // New Mexico is a state, named before the Mexico inside it.
    expect(
      stampCountry(_card('Why is New Mexico so dry?', region: 'americas')),
      'US',
    );
  });

  test('a name that only holds a country’s is not the country', () {
    expect(
      stampCountry(_card('What did Isaiah Berlin mean by liberty?')),
      isNull,
    );
    expect(
      stampCountry(
        _card('What did the East India Company trade?', region: 'asia'),
      ),
      isNull,
    );
    expect(
      stampCountry(_card('Why is Latin America so young?', region: 'americas')),
      isNull,
    );
    for (final String phrase in kNotPlaces) {
      for (final String region in kStampCountries.keys) {
        expect(
          stampCountry(_card('Was $phrase what it seemed?', region: region)),
          isNull,
          reason: '$phrase, $region',
        );
      }
    }
  });

  test('a language is not a country', () {
    expect(stampCountry(_card('Why do we say “OK” in English?')), isNull);
    expect(stampCountry(_card('Is French harder than Italian?')), isNull);
  });

  test('a question about two parts of the world gets no stamp', () {
    expect(
      stampCountry(
        _card(
          'Why was lamb shipped from New Zealand to Britain?',
          region: 'oceania',
        ),
      ),
      isNull,
    );
    expect(
      stampCountry(
        _card('What did the Berlin Conference do to Kenya?', region: 'africa'),
      ),
      isNull,
    );
  });

  test('a country in two parts of the world is the card’s own in either', () {
    expect(
      stampCountry(
        _card('How much wheat does Egypt import?', region: 'africa'),
      ),
      'EG',
    );
    expect(
      stampCountry(
        _card('Why does Cairo flood so rarely?', region: 'middle_east'),
      ),
      'EG',
    );
    expect(
      stampCountry(
        _card('Why did Turkey ban sandblasting?', region: 'middle_east'),
      ),
      'TR',
    );
    expect(stampCountry(_card('Why are Istanbul’s ferries cheap?')), 'TR');
  });

  test('a card set nowhere in particular gets no stamp', () {
    expect(
      stampCountry(_card('Why is France so big?', region: 'world')),
      isNull,
    );
    expect(
      stampCountry(_card('Why is France so big?', region: 'none')),
      isNull,
    );
    expect(stampCountry(_card('Why is France so big?', region: '')), isNull);
  });

  test('the section names what the bank does not, in capitals', () {
    final Pill plain = _card('Why do the trams stop at midnight?');
    expect(stampCountry(plain), isNull);
    expect(stampCountry(plain, {'test-card-1': 'HU'}), 'HU');
    expect(stampCountry(plain, {'test-card-1': 'hu'}), isNull);
    expect(stampCountry(plain, {'test-card-1': 'HUNGARY'}), isNull);
    expect(stampCountry(plain, {'test-card-1': 7}), isNull);
    expect(stampCountry(plain, {'another-card': 'HU'}), isNull);
    // Over what the question names, and under the card's own place.
    expect(
      stampCountry(_card('Why is Hungary flat?'), {'test-card-1': 'AT'}),
      'AT',
    );
    expect(
      stampCountry(
        _card('Why is Hungary flat?', place: const CardPlace(country: 'it')),
        {'test-card-1': 'AT'},
      ),
      'IT',
    );
  });

  test('every country is a code a stamp can print', () {
    final Map<String, Set<String>> names = {};
    for (final region in kStampCountries.entries) {
      for (final country in region.value.entries) {
        expect(country.key, matches(RegExp(r'^[A-Z]{2,3}$')));
        expect(country.value, isNotEmpty);
        // A country in two parts of the world goes by a name in both.
        final Set<String>? before = names[country.key];
        if (before != null) {
          expect(
            before.intersection(country.value.toSet()),
            isNotEmpty,
            reason: country.key,
          );
        }
        (names[country.key] ??= {}).addAll(country.value);
      }
    }
    expect(names.containsKey('GB'), isFalse);
  });
}
