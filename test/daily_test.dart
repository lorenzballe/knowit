import 'package:flutter_test/flutter_test.dart';

import 'package:astuto/data/daily.dart';
import 'package:astuto/data/pills_data.dart';
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
      final pool = kPillPool.where((p) => p.asksSomething && p.isGraded);
      final int window = (pool.length * 0.75).floor();
      expect(window, greaterThanOrEqualTo(30), reason: 'the pool is thin');
      final lastSeen = <String, int>{};
      for (var e = 1; e <= 300; e++) {
        final id = questionOfEdition(e).id;
        final int? before = lastSeen[id];
        if (before != null) {
          expect(
            e - before,
            greaterThan(window),
            reason: '$id came back after ${e - before} days',
          );
        }
        lastSeen[id] = e;
      }
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
      final due = kPillPool.firstWhere(
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
      final seen = {kPillPool.first.id, kPillPool.last.id};
      final a = dealDay(date: day, exclude: seen).map((p) => p.id).toList();
      final b = dealDay(date: day, exclude: seen).map((p) => p.id).toList();
      expect(a, b);
      expect(a, isNot(contains(kPillPool.first.id)));
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
}
