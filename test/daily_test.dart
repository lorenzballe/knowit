import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:astuto/data/daily.dart';
import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/data/pills_repository.dart';
import 'package:astuto/data/topics.dart';
import 'package:astuto/models/pill.dart';

/// A day that is all the reader's own, as a list: the day the tags govern
/// every card of.
List<Pill> _whole({
  required DateTime date,
  Set<String>? topics,
  Set<String> genresOff = const {},
  Set<String> strandsOff = const {},
  Set<String> exclude = const {},
  Map<String, double> taste = const {},
}) => dealDay(
  date: date,
  topics: topics,
  genresOff: genresOff,
  strandsOff: strandsOff,
  exclude: exclude,
  taste: taste,
  own: kPillsPerDay,
).cards;

void main() {
  group('The question of the day', () {
    test('is the same question for everybody, and for the same day twice', () {
      final day = DateTime(2026, 10, 14);
      final a = questionOfTheDay(day).id;
      resetCalendar();
      expect(questionOfTheDay(day).id, a);
    });

    test('editions count from the first day of the calendar', () {
      expect(editionOf(kEpoch), 1);
      expect(editionOf(kEpoch.add(const Duration(days: 9))), 10);
      expect(editionOf(DateTime(2026, 9, 10, 23, 59)), 10);
      expect(dateOfEdition(10), DateTime(2026, 9, 10));
      expect(editionOf(dateOfEdition(400)), 400);
    });

    test('can always be marked — a debate would measure nothing', () {
      for (var e = 1; e <= 200; e++) {
        final q = questionOfEdition(e);
        expect(q.asksSomething, isTrue, reason: 'edition $e');
        expect(q.isGraded, isTrue, reason: 'edition $e');
      }
    });

    test('does not come round again for months', () {
      // The calendar is frozen in the bank, and the bundler keeps a
      // question out for three quarters of a lap of the graded pool and
      // never less than two months — so two months is what a phone may
      // rely on, whatever the pool has grown to since an edition was set.
      const gap = 60;
      final lastSeen = <String, int>{};
      for (var e = 1; e <= 300; e++) {
        final id = questionOfEdition(e).id;
        final int? before = lastSeen[id];
        if (before != null) {
          expect(
            e - before,
            greaterThanOrEqualTo(gap),
            reason: '$id came back after ${e - before} days',
          );
        }
        lastSeen[id] = e;
      }
    });

    test('is frozen in the bank a year ahead, and dealt past its end', () {
      expect(PillBank.editions.length, greaterThanOrEqualTo(400));
      for (var e = 1; e <= 400; e++) {
        expect(questionOfEdition(e).id, PillBank.editions[e], reason: '$e');
      }
      // Beyond the calendar the app chains on from where it left off.
      final beyond = PillBank.editions.keys.reduce(max) + 1;
      expect(questionOfEdition(beyond).isGraded, isTrue);
      expect(
        questionOfEdition(beyond).id,
        isNot(PillBank.editions[beyond - 1]),
      );
    });

    test('days before the calendar still have one', () {
      expect(editionOf(DateTime(2026, 3, 4)), lessThan(1));
      expect(questionOfTheDay(DateTime(2026, 3, 4)).isGraded, isTrue);
    });
  });

  group('A free day', () {
    test('is the question of the day, two of the edition\'s and two of the reader\'s own', () {
      final day = DateTime(2026, 10, 14);
      final deal = dealDay(date: day);
      final cards = deal.cards;
      expect(cards, hasLength(kPillsPerDay));
      expect(cards.map((p) => p.id).toSet(), hasLength(kPillsPerDay));
      expect(deal.question?.id, questionOfTheDay(day).id);
      expect(cards.map((p) => p.id), contains(questionOfTheDay(day).id));
      expect(deal.own, hasLength(kOwnCardsFree));
      expect(deal.own, isNot(contains(deal.question!.id)));
      // The other two are the edition's: the same for everybody, and they
      // tell rather than ask.
      final common = cards
          .where((p) => !deal.own.contains(p.id) && p.id != deal.question!.id)
          .toList();
      expect(common, hasLength(2));
      final edition = commonOfEdition(editionOf(day)).map((p) => p.id);
      for (final p in common) {
        expect(edition, contains(p.id));
        expect(p.asksSomething, isFalse, reason: p.id);
      }
      expect(
        cards.where((p) => p.asksSomething).length,
        asksInADay(kPillsPerDay),
      );
      expect(cards.first.asksSomething, isFalse, reason: 'opens on a read');
    });

    test('the mix governs the reader\'s own, and the rest ignores it', () {
      final day = DateTime(2026, 10, 14);
      final deal = dealDay(
        date: day,
        topics: {'space', 'history'},
        weights: const {'space': 1, 'history': 1},
      );
      // The card that asks lives under Thinking, whatever the mix; the
      // card that tells is the mix's entirely.
      for (final id in deal.own) {
        final Pill p = PillBank.byId(id)!;
        if (p.asksSomething) continue;
        expect(p.topic, anyOf('Space', 'History'), reason: id);
      }
      final question = questionOfTheDay(day);
      expect(deal.cards.map((p) => p.id), contains(question.id));
      expect(kTopics['thinking']!.name, question.topic);
    });

    test('a week kept makes three of the five the reader\'s own', () {
      expect(ownCardsFor(plus: false, streak: 0), kOwnCardsFree);
      expect(ownCardsFor(plus: false, streak: 6), kOwnCardsFree);
      expect(ownCardsFor(plus: false, streak: 7), kOwnCardsRewarded);
      expect(ownCardsFor(plus: false, streak: 8), kOwnCardsFree);
      expect(ownCardsFor(plus: false, streak: 14), kOwnCardsRewarded);
      expect(ownCardsFor(plus: true, streak: 0), kPillsPerDay);
      expect(ownCardsFor(plus: true, streak: 7), kPillsPerDay);

      final day = DateTime(2026, 10, 14);
      final deal = dealDay(date: day, own: kOwnCardsRewarded);
      expect(deal.cards, hasLength(kPillsPerDay));
      expect(deal.own, hasLength(kOwnCardsRewarded));
      expect(deal.cards.map((p) => p.id), contains(questionOfTheDay(day).id));
    });

    test(
      'the edition\'s cards are everybody\'s, and keep clear of yesterday\'s',
      () {
        final a = commonOfEdition(40).map((p) => p.id).toList();
        resetCalendar();
        expect(commonOfEdition(40).map((p) => p.id).toList(), a);
        expect(a, hasLength(kCommonSpares));
        // Never two of one subject, and never a question.
        final cards = commonOfEdition(40);
        expect(cards.map((p) => p.topic).toSet(), hasLength(cards.length));
        expect(cards.any((p) => p.asksSomething), isFalse);
        for (var e = 2; e <= 60; e++) {
          final today = commonOfEdition(e).map((p) => p.id).toSet();
          final yesterday = commonOfEdition(e - 1).map((p) => p.id).toSet();
          expect(today.intersection(yesterday), isEmpty, reason: 'edition $e');
        }
      },
    );

    test(
      'a reader who has read one of the edition\'s takes the next spare',
      () {
        final day = DateTime(2026, 10, 14);
        final edition = commonOfEdition(editionOf(day))
            .map((p) => p.id)
            .toList();
        final deal = dealDay(date: day, exclude: {edition.first});
        final ids = deal.cards.map((p) => p.id).toList();
        expect(ids, isNot(contains(edition.first)));
        expect(ids, contains(edition[1]));
        expect(ids, contains(edition[2]));
        expect(deal.cards, hasLength(kPillsPerDay));
      },
    );
  });

  group('A day that is all the reader\'s own', () {
    test('holds five from the mix and no question of the day', () {
      final day = DateTime(2026, 10, 14);
      final deal = dealDay(date: day, own: kPillsPerDay);
      expect(deal.question, isNull);
      expect(deal.cards, hasLength(kPillsPerDay));
      expect(deal.own, hasLength(kPillsPerDay));
      expect(
        deal.cards.map((p) => p.id),
        isNot(contains(questionOfTheDay(day).id)),
      );
      expect(
        deal.cards.where((p) => p.asksSomething).length,
        asksInADay(kPillsPerDay),
      );
      expect(
        deal.cards.first.asksSomething,
        isFalse,
        reason: 'opens on a read',
      );
    });

    test('a card that came due takes an asking slot, one at most', () {
      final day = DateTime(2026, 10, 14);
      final due = PillBank.cards
          .where((p) => p.isGraded && p.asksSomething)
          .take(2)
          .toList();
      final deck = dealDay(date: day, reviews: due, own: kPillsPerDay).cards;
      expect(deck.map((p) => p.id), contains(due.first.id));
      // The second waits: a day always has one question it has never asked.
      expect(deck.map((p) => p.id), isNot(contains(due.last.id)));
      expect(
        deck.where((p) => p.asksSomething).length,
        asksInADay(kPillsPerDay),
      );
      // On a free day the review is the reader's own, beside the question
      // of the day.
      final free = dealDay(date: day, reviews: due);
      expect(free.cards.map((p) => p.id), contains(due.first.id));
      expect(free.own, contains(due.first.id));
      expect(free.cards.map((p) => p.id), contains(questionOfTheDay(day).id));
      expect(free.cards.map((p) => p.id).toSet(), hasLength(kPillsPerDay));
    });

    test('is the same deal for the same date and history', () {
      final day = DateTime(2026, 10, 14);
      final seen = {PillBank.cards.first.id, PillBank.cards.last.id};
      for (final own in [kOwnCardsFree, kPillsPerDay]) {
        final a = dealDay(
          date: day,
          exclude: seen,
          own: own,
        ).cards.map((p) => p.id).toList();
        final b = dealDay(
          date: day,
          exclude: seen,
          own: own,
        ).cards.map((p) => p.id).toList();
        expect(a, b);
        expect(a, isNot(contains(PillBank.cards.first.id)));
      }
    });

    test('keeps two questions a day, whatever the pool and the plan', () {
      for (var d = 0; d < 60; d++) {
        final date = DateTime(2026, 9, 1).add(Duration(days: d));
        for (final own in [kOwnCardsFree, kOwnCardsRewarded, kPillsPerDay]) {
          final deck = dealDay(date: date, own: own).cards;
          final debates = deck.where((p) => p.challenge is TakeASide).length;
          expect(debates, lessThanOrEqualTo(1), reason: 'day $d own $own');
          expect(
            deck.where((p) => p.asksSomething).length,
            2,
            reason: 'day $d own $own',
          );
          expect(deck.map((p) => p.id).toSet(), hasLength(kPillsPerDay));
        }
      }
    });
  });

  group('What the tags let the dealer do', () {
    // A small bank with strands on every card: two reads each on tides,
    // moon dust, launch windows and event horizons, a third on event
    // horizons that builds on a tides card, one space question, and the
    // three thinking questions the calendar needs.
    Map<String, Object?> card(
      String id, {
      required String strand,
      String topic = 'space',
      List<String> buildsOn = const [],
      List<String> also = const [],
      bool asks = false,
    }) => {
      'id': id,
      'topic': topic,
      if (strand.isNotEmpty)
        'genre': strand.substring(0, strand.lastIndexOf('.')),
      if (strand.isNotEmpty) 'strand': strand,
      if (also.isNotEmpty) 'also': also,
      'kind': asks ? 'pickOne' : 'read',
      'difficulty': asks ? 'medium' : 'easy',
      'principle': asks ? 'baseRate' : 'none',
      'question': 'What is $id about?',
      if (asks) 'options': ['This', 'That'],
      if (asks) 'correct': 1,
      'answer': 'It is about $id, and that is all it is about.',
      'move': 'The move of $id.',
      if (asks) 'trap': 'Picking this.',
      'keywords': [id, 'tests', 'strands'],
      'era': 'timeless',
      'region': 'none',
      'hook': 'mechanism',
      'mood': 'sober',
      'numeracy': 0,
      'abstraction': 'concrete',
      'shelf_life': 'evergreen',
      'mature': false,
      'language': 'en',
      if (buildsOn.isNotEmpty) 'builds_on': buildsOn,
      'source': 'A source',
    };

    const tides = 'space.the_moon.tides';
    const dust = 'space.the_moon.moon_dust';
    const windows = 'space.rockets.launch_windows';
    const horizons = 'space.black_holes.event_horizons';
    final cards = [
      card('space-t1', strand: tides),
      card('space-t2', strand: tides),
      card('space-d1', strand: dust),
      card('space-d2', strand: dust),
      card('space-r1', strand: windows),
      card('space-r2', strand: windows),
      card('space-h1', strand: horizons, also: [tides]),
      card('space-h2', strand: horizons),
      card('space-b1', strand: horizons, buildsOn: ['space-t1']),
      card('space-a1', strand: 'space.rockets.fuel_chemistry', asks: true),
      card('thinking-q1', strand: '', topic: 'thinking', asks: true),
      card('thinking-q2', strand: '', topic: 'thinking', asks: true),
      card('thinking-q3', strand: '', topic: 'thinking', asks: true),
    ];

    setUp(() {
      PillBank.adopt(
        BankBundle.parse(
          jsonEncode({
            'format': 1,
            'version': 1,
            'built': '2026-09-20T03:00:00Z',
            'cards': cards,
            'editions': <String, String>{},
          }),
        ),
      );
      resetCalendar();
    });

    tearDown(() {
      PillBank.reset();
      resetCalendar();
    });

    List<Pill> reads(List<Pill> deck) =>
        deck.where((p) => !p.asksSomething).toList();

    test(
      'no two of the reader\'s cards share a strand while it can help it',
      () {
        for (var d = 0; d < 20; d++) {
          final deck = _whole(
            date: DateTime(2026, 10, 1).add(Duration(days: d)),
            topics: {'space'},
          );
          final strands = reads(deck).map((p) => p.strand).toList();
          expect(strands.toSet(), hasLength(strands.length), reason: 'day $d');
        }
      },
    );

    test('a genre turned off comes after everything that is on', () {
      final deck = _whole(
        date: DateTime(2026, 10, 14),
        topics: {'space'},
        genresOff: {'space.the_moon'},
      );
      expect(reads(deck), hasLength(3));
      for (final p in reads(deck)) {
        expect(p.genre, isNot('space.the_moon'), reason: p.id);
      }

      // Only event horizons left on: two cards, then the one that waits
      // for a tides card — which still comes before a strand turned off.
      final one = _whole(
        date: DateTime(2026, 10, 14),
        topics: {'space'},
        strandsOff: {tides, dust, windows},
      );
      expect(reads(one).map((p) => p.id), contains('space-b1'));
      // A reader who turned everything off still gets a full day.
      expect(one, hasLength(kPillsPerDay));
    });

    test('a card is on the mix through any strand it is also about', () {
      final h1 = PillBank.byId('space-h1')!;
      expect(h1.strands, [horizons, tides]);
      expect(h1.traits, contains('strand:$tides'));
      // Black holes and rockets off, moon dust off: tides is the one
      // strand on, and h1 is on through it while h2 is not.
      final deck = _whole(
        date: DateTime(2026, 10, 14),
        topics: {'space'},
        genresOff: {'space.black_holes', 'space.rockets'},
        strandsOff: {dust},
      );
      final ids = reads(deck).map((p) => p.id).toList();
      expect(ids, contains('space-h1'));
      expect(ids, isNot(contains('space-h2')));
    });

    test('a card waits for the card it builds on', () {
      final fresh = _whole(date: DateTime(2026, 10, 14), topics: {'space'});
      expect(fresh.map((p) => p.id), isNot(contains('space-b1')));
      final later = _whole(
        date: DateTime(2026, 10, 14),
        topics: {'space'},
        exclude: {
          'space-t1',
          'space-t2',
          'space-d1',
          'space-d2',
          'space-r1',
          'space-r2',
          'space-h1',
          'space-h2',
        },
      );
      expect(later.map((p) => p.id), contains('space-b1'));
    });

    test('the taste leans the draw without emptying the pool', () {
      final moon = PillBank.byId('space-t1')!;
      expect(leanOf(moon, const {}), 1);
      expect(leanOf(moon, const {'genre:space.the_moon': 0.5}), 1.5);
      expect(
        leanOf(moon, const {'hook:puzzle': 0.5}),
        1,
        reason: 'not its trait',
      );
      expect(leanOf(moon, const {'genre:space.the_moon': -5}), 0.2);
      expect(leanOf(moon, const {'strand:$tides': 5}), 3);

      int moonDays(Map<String, double> taste) {
        var n = 0;
        for (var d = 0; d < 40; d++) {
          final deck = _whole(
            date: DateTime(2026, 10, 1).add(Duration(days: d)),
            topics: {'space'},
            taste: taste,
          );
          n += reads(deck).where((p) => p.genre == 'space.the_moon').length;
        }
        return n;
      }

      final plain = moonDays(const {});
      final leaned = moonDays(const {'genre:space.the_moon': -3});
      expect(leaned, lessThan(plain));
      expect(leaned, greaterThan(0), reason: 'thrown down, not thrown out');
    });

    test('the search reads the keywords', () {
      expect(searchPills('strands').map((p) => p.id), contains('space-t1'));
      expect(searchPills('space-d2').map((p) => p.id), ['space-d2']);
    });
  });
}
