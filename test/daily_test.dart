import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:astuto/data/daily.dart';
import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/data/pills_repository.dart';
import 'package:astuto/data/topics.dart';
import 'package:astuto/models/pill.dart';

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

  group('A day dealt around it', () {
    test('holds the question of the day and four of the reader\'s own', () {
      final day = DateTime(2026, 10, 14);
      final deck = dealDay(date: day);
      expect(deck, hasLength(kPillsPerDay));
      expect(deck.map((p) => p.id).toSet(), hasLength(kPillsPerDay));
      expect(deck.map((p) => p.id), contains(questionOfTheDay(day).id));
      expect(
        deck.where((p) => p.asksSomething).length,
        asksInADay(kPillsPerDay),
      );
      expect(deck.first.asksSomething, isFalse, reason: 'opens on a read');
    });

    test('the mix governs the four, and the question ignores it', () {
      final day = DateTime(2026, 10, 14);
      final deck = dealDay(
        date: day,
        topics: {'space', 'history'},
        weights: const {'space': 1, 'history': 1},
      );
      final question = questionOfTheDay(day);
      for (final p in deck.where((p) => !p.asksSomething)) {
        expect(p.topic, anyOf('Space', 'History'), reason: p.id);
      }
      expect(deck.map((p) => p.id), contains(question.id));
      expect(kTopics['thinking']!.name, question.topic);
    });

    test('a card that came due takes the second asking slot', () {
      final day = DateTime(2026, 10, 14);
      final question = questionOfTheDay(day);
      final due = PillBank.cards.firstWhere(
        (p) => p.isGraded && p.asksSomething && p.id != question.id,
      );
      final deck = dealDay(date: day, reviews: [due]);
      expect(deck.map((p) => p.id), contains(due.id));
      expect(deck.map((p) => p.id), contains(question.id));
      // And no third question is dealt to make room for it.
      expect(
        deck.where((p) => p.asksSomething).length,
        asksInADay(kPillsPerDay),
      );
      // The question of the day coming due is not dealt twice.
      final twice = dealDay(date: day, reviews: [question]);
      expect(twice.map((p) => p.id).toSet(), hasLength(kPillsPerDay));
    });

    test('is the same deal for the same date and history', () {
      final day = DateTime(2026, 10, 14);
      final seen = {PillBank.cards.first.id, PillBank.cards.last.id};
      final a = dealDay(date: day, exclude: seen).map((p) => p.id).toList();
      final b = dealDay(date: day, exclude: seen).map((p) => p.id).toList();
      expect(a, b);
      expect(a, isNot(contains(PillBank.cards.first.id)));
    });

    test('keeps two questions a day, whatever the pool', () {
      for (var d = 0; d < 60; d++) {
        final deck = dealDay(date: DateTime(2026, 9, 1).add(Duration(days: d)));
        final debates = deck.where((p) => p.challenge is TakeASide).length;
        expect(debates, lessThanOrEqualTo(1), reason: 'day $d');
        expect(deck.where((p) => p.asksSomething).length, 2, reason: 'day $d');
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
          final deck = dealDay(
            date: DateTime(2026, 10, 1).add(Duration(days: d)),
            topics: {'space'},
          );
          final strands = reads(deck).map((p) => p.strand).toList();
          expect(strands.toSet(), hasLength(strands.length), reason: 'day $d');
        }
      },
    );

    test('a genre turned off comes after everything that is on', () {
      final deck = dealDay(
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
      final one = dealDay(
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
      final deck = dealDay(
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
      final fresh = dealDay(date: DateTime(2026, 10, 14), topics: {'space'});
      expect(fresh.map((p) => p.id), isNot(contains('space-b1')));
      final later = dealDay(
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
          final deck = dealDay(
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
