import 'package:flutter_test/flutter_test.dart';

import 'package:astuto/data/daily.dart';
import 'package:astuto/data/pills_data.dart';
import 'package:astuto/data/pills_repository.dart';
import 'package:astuto/models/pill.dart';

void main() {
  group('The five of the day', () {
    test('are the same five for everybody, and for the same day twice', () {
      final day = DateTime(2026, 10, 14);
      final a = sharedDeckFor(day).map((p) => p.id).toList();
      resetSharedDecks();
      final b = sharedDeckFor(day).map((p) => p.id).toList();
      expect(a, b);
      expect(a, hasLength(kPillsPerDay));
      expect(a.toSet(), hasLength(kPillsPerDay), reason: 'a card dealt twice');
    });

    test('editions count from the first day of the calendar', () {
      expect(editionOf(kEpoch), 1);
      expect(editionOf(kEpoch.add(const Duration(days: 9))), 10);
      expect(editionOf(DateTime(2026, 9, 10, 23, 59)), 10);
      expect(dateOfEdition(10), DateTime(2026, 9, 10));
      expect(editionOf(dateOfEdition(400)), 400);
    });

    test('a day is two that ask and three that tell', () {
      for (var e = 1; e <= 120; e++) {
        final deck = sharedDeckOfEdition(e);
        final asks = deck.where((p) => p.asksSomething).length;
        expect(asks, asksInADay(kPillsPerDay), reason: 'edition $e');
        expect(deck, hasLength(kPillsPerDay), reason: 'edition $e');
      }
    });

    test('opens on a read and never holds two opinions', () {
      for (var e = 1; e <= 120; e++) {
        final deck = sharedDeckOfEdition(e);
        expect(deck.first.asksSomething, isFalse, reason: 'edition $e');
        final debates = deck.where((p) => p.challenge is TakeASide).length;
        expect(debates, lessThanOrEqualTo(1), reason: 'edition $e');
        final graded = deck.where((p) => p.isGraded).length;
        expect(
          graded,
          greaterThanOrEqualTo(1),
          reason: 'edition $e measures nothing',
        );
      }
    });

    test('spreads the reading over subjects', () {
      for (var e = 1; e <= 120; e++) {
        final reads = sharedDeckOfEdition(e).where((p) => !p.asksSomething);
        expect(
          reads.map((p) => p.topic).toSet(),
          hasLength(reads.length),
          reason: 'edition $e read two cards from one shelf',
        );
      }
    });

    test('does not deal a card round again for weeks', () {
      // Three quarters of a lap of the pool between one meeting of a card
      // and the next, for each kind of card.
      final reads = kPillPool.where((p) => !p.asksSomething).length;
      final asks = kPillPool.where((p) => p.asksSomething).length;
      final int readGap = (reads / 3 * 0.75).floor();
      final int askGap = (asks / 2 * 0.75).floor();
      expect(readGap, greaterThanOrEqualTo(7), reason: 'the pool is thin');

      final lastSeen = <String, int>{};
      for (var e = 1; e <= 200; e++) {
        for (final p in sharedDeckOfEdition(e)) {
          final int? before = lastSeen[p.id];
          if (before != null) {
            final int gap = p.asksSomething ? askGap : readGap;
            expect(
              e - before,
              greaterThan(gap),
              reason: '${p.id} came back after ${e - before} days',
            );
          }
          lastSeen[p.id] = e;
        }
      }
    });

    test('days before the calendar still deal a full day', () {
      final deck = sharedDeckFor(DateTime(2026, 3, 4));
      expect(deck, hasLength(kPillsPerDay));
      expect(editionOf(DateTime(2026, 3, 4)), lessThan(1));
    });
  });
}
