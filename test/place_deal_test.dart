import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astuto/data/card_json.dart';
import 'package:astuto/data/daily.dart';
import 'package:astuto/data/embedded_bank.dart';
import 'package:astuto/data/local_cards.dart';
import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/data/pills_repository.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/models/place.dart';
import 'package:astuto/state/app_state.dart';
import 'package:astuto/sync/served.dart';
import 'package:astuto/theme.dart';
import 'package:astuto/widgets/pill_card.dart';

/// Cards about where a reader lives go to the readers who live there and
/// nowhere else (docs/PLACES.md §5): at most one a day, nearest first, in
/// place of a card at random, and on Explore's "Where you live". The bank
/// has none yet, so these tests write some: copies of cards it holds, under
/// new ids, each given a place. The server is held to the same rules by
/// functions/src/place.test.ts, with the same cards.

const Map<String, Object> _modena = {
  'country': 'IT',
  'region': 'IT-45',
  'city': 'Modena',
  'lat': 44.647,
  'lon': 10.925,
  'km': 20,
};
const Map<String, Object> _bologna = {
  'country': 'IT',
  'region': 'IT-45',
  'city': 'Bologna',
  'lat': 44.494,
  'lon': 11.343,
  'km': 20,
};
const Map<String, Object> _emilia = {'country': 'IT', 'region': 'IT-45'};
const Map<String, Object> _lombardy = {'country': 'IT', 'region': 'IT-25'};
const Map<String, Object> _italy = {'country': 'IT'};
const Map<String, Object> _france = {'country': 'FR'};

/// The cards about places, as (the card copied, its new id, its place).
const List<(String, String, Map<String, Object>)> _local = [
  ('history-1', 'history-modena-1', _modena),
  ('history-1848-5', 'history-modena-2', _modena),
  ('history-british-1', 'history-modena-3', _modena),
  ('food-beer-1', 'food-bologna-1', _bologna),
  ('history-2', 'history-emilia-1', _emilia),
  ('history-1848-9', 'history-emilia-2', _emilia),
  ('food-beer-2', 'food-lombardy-1', _lombardy),
  ('history-6', 'history-italy-1', _italy),
  ('history-1848-10', 'history-italy-2', _italy),
  // Tempting every road for everybody: a Thinking question (the question
  // of the day's pool), reads (the edition's cards'), a debate.
  ('thinking-1', 'thinking-italy-1', _italy),
  ('food-beer-7', 'food-italy-1', _italy),
  ('history-clothes-10', 'history-italy-3', _italy),
  ('history-food-10', 'history-provence-1', _france),
];

final Set<String> _localIds = {for (final c in _local) c.$2};

/// The question only Modena's first card asks, for the search.
const String _ghirlandina = 'Why does the Ghirlandina lean the way it does?';

/// The bank the app ships with, and the cards about places beside it. Each
/// asks its own question, so a line that quotes one can be told from a line
/// that quotes the card it was copied from.
BankBundle _withPlaces() {
  final Map<String, Object?> doc =
      jsonDecode(kEmbeddedBank) as Map<String, Object?>;
  final List<Object?> cards = doc['cards'] as List<Object?>;
  final Map<String, Map<String, Object?>> byId = {
    for (final Object? c in cards)
      (c as Map<String, Object?>)['id'] as String: c,
  };
  doc['cards'] = [
    ...cards,
    for (final (base, id, place) in _local)
      {
        ...byId[base]!,
        'id': id,
        'place': place,
        'question': id == 'history-modena-1'
            ? _ghirlandina
            : '${byId[base]!['question']} ($id)',
      },
  ];
  doc['version'] = (doc['version'] as int) + 1;
  return BankBundle.parse(jsonEncode(doc));
}

final BankBundle _placed = _withPlaces();

Place _at(Map<String, Object> raw) => Place.fromJson(raw)!;

/// Formigine, ten kilometres out of Modena: in its reach, not Bologna's.
final Place _inModena = _at({
  'country': 'IT',
  'region': 'IT-45',
  'regionName': 'Emilia-Romagna',
  'city': 'Formigine',
  'lat': 44.6,
  'lon': 10.8,
});
final Place _inPiacenza = _at({
  'country': 'IT',
  'region': 'IT-45',
  'city': 'Piacenza',
  'lat': 45.1,
  'lon': 9.7,
});
final Place _inPalermo = _at({
  'country': 'IT',
  'region': 'IT-82',
  'city': 'Palermo',
  'lat': 38.1,
  'lon': 13.4,
});
final Place _inBerlin = _at({
  'country': 'DE',
  'city': 'Berlin',
  'lat': 52.5,
  'lon': 13.4,
});

final DateTime _monday = DateTime(2026, 10, 5);
final List<DateTime> _days = [
  for (var i = 0; i < 30; i++) DateTime(2026, 10, 5 + i),
];

/// [run] against the bank as it ships, then against the bank with the cards
/// about places in it.
(T, T) _both<T>(T Function() run) {
  PillBank.reset();
  resetCalendar();
  final T plain = run();
  PillBank.adopt(_placed);
  resetCalendar();
  return (plain, run());
}

List<String> _ids(Iterable<Pill> cards) => [for (final p in cards) p.id];

PlaceFit _fitOf(String id, Place? home) =>
    placeFit(PillBank.byId(id)!.place!, home);

void main() {
  setUp(() {
    PillBank.adopt(_placed);
    resetCalendar();
    SharedPreferences.setMockInitialValues({});
  });
  tearDown(() {
    PillBank.reset();
    resetCalendar();
  });

  group('the bank', () {
    test('keeps a card about a place out of everything dealt to everybody', () {
      expect(PillBank.cards.where((p) => p.isAboutAPlace), isEmpty);
      expect(_ids(PillBank.placeCards).toSet(), _localIds);
      expect(
        PillBank.live.length,
        PillBank.cards.length + PillBank.placeCards.length,
      );
      // Still known by id: a deck dealt with one still opens.
      expect(PillBank.byId('history-modena-1')?.place?.city, 'Modena');
      PillBank.reset();
      expect(PillBank.placeCards, isEmpty);
      expect(PillBank.live.length, PillBank.cards.length);
    });

    test('carries the place through JSON, and refuses one it cannot read', () {
      final Pill modena = PillBank.byId('history-modena-1')!;
      final Map<String, Object?> json = cardToJson(modena);
      expect(json['place'], _modena);
      expect(cardToJson(cardFromJson(json)), json);
      // Read as no place, a card about Modena would be everybody's.
      for (final Object bad in [
        {'region': 'IT-45'},
        {'country': 5},
        'IT',
      ]) {
        expect(
          () => cardFromJson({...json, 'place': bad}),
          throwsFormatException,
          reason: '$bad',
        );
      }
      final String text = jsonEncode({
        'version': 1,
        'cards': [
          {...json, 'place': 'IT'},
        ],
      });
      expect(() => BankBundle.parse(text), throwsFormatException);
    });
  });

  group('a card about a place goes nowhere but home', () {
    test('never the question of the day or an edition\'s card, '
        'even past the calendar', () {
      final int last = PillBank.editions.keys.reduce((a, b) => a > b ? a : b);
      final (plain, placed) = _both(
        () => [
          for (var e = 1; e <= last + 60; e++)
            [questionOfEdition(e).id, ..._ids(commonOfEdition(e))].join(','),
        ],
      );
      expect(placed, plain, reason: 'the calendar is what it was');
      for (final String edition in placed) {
        expect(edition.split(',').where(_localIds.contains), isEmpty);
      }
    });

    test('never at random, never as anybody\'s own, never for a reader '
        'with no place: their day is the day it always was', () {
      for (final int own in [kOwnCardsFree, kOwnCardsRewarded, kPillsPerDay]) {
        final (plain, placed) = _both(
          () => [
            for (final DateTime date in _days)
              _ids(dealDay(date: date, own: own).cards),
          ],
        );
        expect(placed, plain, reason: 'own $own');
      }
      for (final DateTime date in _days.take(5)) {
        for (final Pill p in [
          ...pillsForDate(date, count: 40),
          ...pillsAtRandom(date, count: 40, asking: 10),
        ]) {
          expect(p.isAboutAPlace, isFalse, reason: p.id);
        }
      }
    });

    test('never on a shelf for everybody', () {
      for (final Pill p in [
        ...pickedPills(seed: '2026-10-05', count: 400),
        ...pickedPills(seed: '2026-10', count: 200, topic: 'History'),
        ...askingPills(seed: allTimeSeed, count: 400),
      ]) {
        expect(p.isAboutAPlace, isFalse, reason: p.id);
      }
    });

    test('found by the search only for a reader who lives there', () {
      expect(_ids(searchPills('ghirlandina', home: _inModena)), [
        'history-modena-1',
      ]);
      expect(searchPills('ghirlandina', home: _inPalermo), isEmpty);
      expect(searchPills('ghirlandina'), isEmpty);
      // A reader with no place finds what they always found.
      final (plain, placed) = _both(() => _ids(searchPills('black hole')));
      expect(placed, plain);
      expect(searchPills(''), hasLength(PillBank.cards.length));
      expect(
        searchPills('', home: _inModena),
        hasLength(PillBank.cards.length + placeCardsFor(_inModena).length),
      );
    });

    test('never on a widget, a reminder or the lock screen', () async {
      SharedPreferences.setMockInitialValues({'knowit.onboarded': true});
      final AppState app = AppState(clock: () => DateTime(2026, 10, 12, 9))
        ..place = _inModena;
      await app.init();
      expect(
        app.todaysDeck.where((p) => p.isAboutAPlace),
        hasLength(1),
        reason: 'the day holds its card about home',
      );
      final Map<String, Object?> data = app.homeWidgetData();
      final Set<String> handed = {
        data['cardId'] as String,
        ...(data['aheadId'] as Map<String, String>).values,
        for (final String key in ['fiveJson', 'fiveTomorrowJson'])
          for (final Object? c in jsonDecode(data[key] as String) as List)
            (c as Map)['id'] as String,
        for (final String day in (data['shelf'] as Map<String, String>).values)
          for (final Object? c in jsonDecode(day) as List)
            (c as Map)['id'] as String,
      };
      expect(handed.intersection(_localIds), isEmpty);
      // The five widget shows the day's other four, and does not say all
      // five are read until they are.
      expect(jsonDecode(data['fiveJson'] as String) as List, hasLength(4));
      expect(data['fiveDone'], isNot('All five read'));
      for (final r in app.reminderPlan(now: DateTime(2026, 10, 12, 6))) {
        for (final String id in _localIds) {
          expect(r.body, isNot(contains(PillBank.byId(id)!.question)));
        }
      }
    });

    test('never on a shelf a server sends for everybody, whatever server '
        'sent it; only on the reader\'s own Where you live', () {
      Map<String, Object?> card(String id) => cardToJson(PillBank.byId(id)!);
      final List<Map<String, Object?>> mixed = [
        card('history-modena-1'),
        card('history-1'),
        card('history-italy-1'),
      ];
      final ServedExplore? got = ServedExplore.parse(
        {
          'day': '2026-10-12',
          'today': mixed,
          'asking': mixed,
          for (final String key in ['topWeek', 'topMonth', 'loved'])
            key: [
              for (final c in mixed) {'id': c['id'], 'readers': 9, 'card': c},
            ],
        },
        {'mine': mixed, 'forYou': mixed, 'local': mixed},
      );
      expect(got, isNotNull);
      for (final List<Pill> shelf in [
        got!.today,
        got.asking,
        got.mine,
        got.forYou,
        for (final List<ServedRank> ranked in [
          got.topWeek,
          got.topMonth,
          got.loved,
        ])
          [for (final r in ranked) r.pill],
      ]) {
        expect(_ids(shelf), ['history-1']);
      }
      expect(_ids(got.local), ['history-modena-1', 'history-italy-1']);
    });
  });

  group('the card about home in the day', () {
    test('nearest first: the city, then the region, then the country, '
        'never one read, then an ordinary day', () {
      final Set<String> seen = {};
      final List<String> order = [];
      for (var i = 0; i < 14; i++) {
        final Deal deal = dealDay(
          date: _monday,
          exclude: seen,
          home: _inModena,
        );
        final Pill? local = deal.local;
        if (local == null) break;
        expect(seen, isNot(contains(local.id)));
        expect(deal.cards.where((p) => p.isAboutAPlace), [local]);
        order.add(local.id);
        seen.add(local.id);
      }
      expect(
        [for (final id in order) _fitOf(id, _inModena)],
        [
          ...List.filled(3, PlaceFit.city),
          ...List.filled(2, PlaceFit.region),
          ...List.filled(5, PlaceFit.country),
        ],
      );
      // Formigine is in Modena's reach and not Bologna's; Lombardy and
      // France are not where the reader lives.
      expect(
        order.toSet().intersection({
          'food-bologna-1',
          'food-lombardy-1',
          'history-provence-1',
        }),
        isEmpty,
      );
      // Everything read: the day is the one a bank without them deals.
      final (plain, placed) = _both(
        () =>
            _ids(dealDay(date: _monday, exclude: seen, home: _inModena).cards),
      );
      expect(placed, plain);
    });

    test('takes a card at random\'s place, never one of the reader\'s own; '
        'on Astute+ the last of theirs', () {
      for (final DateTime date in _days) {
        final Deal free = dealDay(date: date, home: _inModena);
        expect(free.local, isNotNull);
        expect(free.cards, hasLength(kPillsPerDay));
        expect(free.own, hasLength(kOwnCardsFree));
        expect(free.own, isNot(contains(free.local!.id)));
        final int atRandom = free.cards
            .where((p) => !free.own.contains(p.id) && p != free.local)
            .length;
        expect(atRandom, kPillsPerDay - kOwnCardsFree - 1);
        // Still a day's shape: two that ask, a debate at most, and last.
        expect(free.cards.where((p) => p.asksSomething), hasLength(2));
        final debates = free.cards.where((p) => p.challenge is TakeASide);
        expect(debates.length, lessThanOrEqualTo(1));
        if (debates.isNotEmpty) expect(free.cards.last, debates.single);

        final Deal plus = dealDay(
          date: date,
          own: kPillsPerDay,
          home: _inModena,
        );
        expect(plus.local, isNotNull);
        expect(plus.own, hasLength(kPillsPerDay - 1));
        expect(
          {for (final p in plus.cards) p.id},
          {...plus.own, plus.local!.id},
        );
        expect(plus.cards.where((p) => p.asksSomething), hasLength(2));
      }
    });

    test('a debate about home is the day\'s only debate, and closes it', () {
      for (final DateTime date in _days) {
        final Deal deal = dealDay(
          date: date,
          own: kPillsPerDay,
          exclude: {'history-modena-1', 'history-modena-2'},
          home: _inModena,
        );
        expect(deal.local?.id, 'history-modena-3');
        expect(deal.cards.where((p) => p.challenge is TakeASide), hasLength(1));
        expect(deal.cards.last.id, 'history-modena-3');
      }
    });

    test('the date and what was read decide it, the same every time', () {
      final Set<String> picks = {};
      for (final DateTime date in _days) {
        final Pill? a = localCardFor(date, home: _inModena);
        final Pill? b = localCardFor(date, home: _inModena);
        expect(a?.id, b?.id);
        expect(dealDay(date: date, home: _inModena).local?.id, a?.id);
        picks.add(a!.id);
      }
      expect(picks.length, greaterThan(1));
      expect(picks.every((id) => id.startsWith('history-modena-')), isTrue);
    });

    test('a place with no card of its own takes its region\'s; one with '
        'nothing written for it is an ordinary day', () {
      expect(
        dealDay(date: _monday, home: _inPiacenza).local?.id,
        anyOf('history-emilia-1', 'history-emilia-2'),
      );
      for (final Place? home in [null, _inBerlin]) {
        final (plain, placed) = _both(
          () => _ids(dealDay(date: _monday, home: home).cards),
        );
        expect(placed, plain, reason: '$home');
        expect(dealDay(date: _monday, home: home).local, isNull);
      }
    });
  });

  group('Where you live', () {
    test('nearest first, read ones after their fit\'s unread, '
        'and nothing without a place', () {
      final List<Pill> shelf = whereYouLive(
        _inModena,
        read: {'history-modena-2'},
        seed: '2026-10',
      );
      expect(
        [for (final p in shelf) placeFit(p.place!, _inModena)],
        [
          ...List.filled(3, PlaceFit.city),
          ...List.filled(2, PlaceFit.region),
          ...List.filled(5, PlaceFit.country),
        ],
      );
      expect(shelf[2].id, 'history-modena-2');
      expect(shelf.length, lessThanOrEqualTo(kWhereYouLiveShelf));
      expect(whereYouLive(null, seed: '2026-10'), isEmpty);
      expect(whereYouLive(_inBerlin, seed: '2026-10'), isEmpty);
      // Palermo has nothing of its city's or region's yet: its country's.
      expect(_ids(whereYouLive(_inPalermo, seed: '2026-10')).toSet(), {
        'history-italy-1',
        'history-italy-2',
        'history-italy-3',
        'thinking-italy-1',
        'food-italy-1',
      });
    });
  });

  group('the line on the card', () {
    // The Today deck's card on the smallest and the largest phone designed
    // for (test/card_back_fit_test.dart measures them in the app).
    const Map<String, (Size, Size)> phones = {
      'small': (Size(360, 740), Size(324, 520)),
      'large': (Size(430, 932), Size(394, 712)),
    };

    Future<void> pump(
      WidgetTester tester,
      Pill pill, {
      required Size phone,
      required Size card,
      Place? home,
      bool flipped = false,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: buildAstutoTheme(Brightness.dark),
          home: MediaQuery(
            data: MediaQueryData(size: phone),
            child: Scaffold(
              body: Center(
                child: SizedBox.fromSize(
                  size: card,
                  child: PillCard(pill: pill, flipped: flipped, home: home),
                ),
              ),
            ),
          ),
        ),
      );
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    testWidgets('says why the card is there, quietly, on a small and a '
        'large phone', (tester) async {
      final Map<String, String> lines = {
        'history-modena-2': 'Near you · Modena',
        'history-emilia-1': 'Your region · Emilia-Romagna',
        'history-italy-3': 'Your country · Italy',
      };
      for (final (Size phone, Size card) in phones.values) {
        for (final MapEntry<String, String> e in lines.entries) {
          final Pill pill = PillBank.byId(e.key)!;
          await pump(tester, pill, phone: phone, card: card, home: _inModena);
          expect(tester.takeException(), isNull, reason: e.key);
          expect(find.byKey(const ValueKey('place-line')), findsOneWidget);
          expect(find.text(e.value), findsOneWidget, reason: e.key);
          // Under the subject, above the question: inside the card.
          final Rect line = tester.getRect(
            find.byKey(const ValueKey('place-line')),
          );
          final Rect face = tester.getRect(find.byType(PillCard));
          expect(face.contains(line.topLeft), isTrue);
          expect(face.contains(line.bottomRight), isTrue);
        }
      }
    });

    testWidgets('claims nothing it cannot: only the place, for a reader '
        'elsewhere; nothing on the back or on a card for everybody', (
      tester,
    ) async {
      final (Size phone, Size card) = phones['small']!;
      final Pill modena = PillBank.byId('history-modena-1')!;
      await pump(tester, modena, phone: phone, card: card, home: _inPalermo);
      expect(find.text('Modena'), findsOneWidget);
      expect(find.textContaining('Near you'), findsNothing);
      await pump(tester, modena, phone: phone, card: card);
      expect(find.text('Modena'), findsOneWidget);

      await pump(
        tester,
        modena,
        phone: phone,
        card: card,
        home: _inModena,
        flipped: true,
      );
      expect(find.byKey(const ValueKey('place-line')), findsNothing);

      await pump(
        tester,
        PillBank.byId('history-1')!,
        phone: phone,
        card: card,
        home: _inModena,
      );
      expect(find.byKey(const ValueKey('place-line')), findsNothing);
      expect(tester.takeException(), isNull);
    });

    test('names the region and the country from the card\'s codes', () {
      expect(regionDisplayName('IT-45'), 'Emilia-Romagna');
      expect(regionDisplayName('IT-25'), 'Lombardy');
      expect(regionDisplayName('IT-75'), 'Apulia');
      expect(regionDisplayName('FR-IDF'), isNull);
      expect(regionDisplayName('nonsense'), isNull);
      expect(countryDisplayName('IT'), 'Italy');
      expect(countryDisplayName('SM'), 'San Marino');
      expect(countryDisplayName('ZZ'), 'ZZ');
    });
  });
}
