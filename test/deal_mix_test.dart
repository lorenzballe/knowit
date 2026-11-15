import 'package:flutter_test/flutter_test.dart';

import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/data/pills_repository.dart';
import 'package:astuto/data/topics.dart';
import 'package:astuto/models/pill.dart';

/// The phone deals a day as the server does (functions/src/deal.ts), and
/// keeps the same two rules the bank's free cards brought out.
void main() {
  test('cards at random follow the mix as it was set: a subject picked but '
      'given no weight waits until the weighted ones run out', () {
    final Set<String> mix = {kTopics['space']!.name, kTopics['science']!.name};
    for (int i = 0; i < 20; i++) {
      final List<String> topics = [
        for (final p in pillsAtRandom(
          DateTime(2026, 11, 3).add(Duration(days: i)),
          count: 3,
          topics: {'space', 'science', 'thinking'},
          weights: {'space': 1, 'science': 0.5},
        ))
          p.topic,
      ];
      expect(topics, hasLength(3));
      expect(mix.containsAll(topics), isTrue, reason: '$topics');
    }
  });

  test('a Thinking card that only tells waits at random until the mix '
      'runs out: Thinking is on every deck for its cards that ask', () {
    for (int i = 0; i < 30; i++) {
      final List<Pill> cards = pillsAtRandom(
        DateTime(2026, 10, 14).add(Duration(days: i)),
        count: 3,
        topics: {'space', 'thinking'},
      );
      expect(cards, hasLength(3));
      for (final Pill p in cards) {
        expect(
          p.topic != kTopics['thinking']!.name || p.asksSomething,
          isTrue,
          reason: 'day $i: ${p.id}',
        );
      }
    }
  });

  test('a day that asks holds a question its page marks', () {
    for (int i = 0; i < 40; i++) {
      final day = pillsForDate(
        DateTime(2026, 11, 3).add(Duration(days: i)),
        count: 5,
        asking: 2,
      );
      expect(
        day.where((p) => p.asksSomething && p.isGraded),
        isNotEmpty,
        reason: 'day $i: ${day.map((p) => p.id)}',
      );
    }
  });

  // Drawn cards: the app at its best, first — as the server deals them.

  test('a drawn card weighs more inside its subject, and the subject no '
      'more than it did', () {
    final String science = kTopics['science']!.name;
    final String music = kTopics['music']!.name;
    final List<Pill> cards = [
      for (final p in PillBank.cards)
        if (p.topic == science || p.topic == music) p,
    ];
    expect(cards.any((p) => p.topic == science && p.hasPage), isTrue);
    expect(cards.any((p) => p.topic == science && !p.hasPage), isTrue);
    for (final (int? day, double boost) in [
      (0, kShowcaseWeight),
      (kShowcaseDays - 1, kShowcaseWeight),
      (kShowcaseDays, kDrawnWeight),
      (null, kDrawnWeight),
    ]) {
      final double Function(Pill) w = drawnWeights(cards, day);
      for (final String topic in [science, music]) {
        final List<Pill> own = [
          for (final p in cards)
            if (p.topic == topic) p,
        ];
        final double total = own.fold(0, (sum, p) => sum + w(p));
        expect(total, closeTo(own.length, 1e-9), reason: '$topic on $day');
      }
      final Pill drawn = cards.firstWhere(
        (p) => p.topic == science && p.hasPage,
      );
      final Pill plain = cards.firstWhere(
        (p) => p.topic == science && !p.hasPage,
      );
      expect(w(drawn) / w(plain), closeTo(boost, 1e-9), reason: 'day $day');
    }
  });

  test('the first week leans to the drawn cards; the mix stays the '
      "reader's", () {
    int drawnOn(int day) {
      int n = 0;
      for (int i = 0; i < 30; i++) {
        n += pillsAtRandom(
          DateTime(2026, 11, 3).add(Duration(days: i)),
          count: 3,
          topics: {'science', 'space', 'history', 'thinking'},
          weights: {'science': 1, 'space': 0.8, 'history': 0.6},
          day: day,
        ).where((p) => p.hasPage).length;
      }
      return n;
    }

    final int first = drawnOn(0);
    final int later = drawnOn(kShowcaseDays);
    expect(first, greaterThan(later), reason: '$first against $later');
    expect(first, greaterThanOrEqualTo(60), reason: '$first of 90');

    int musicOn(int day) {
      int n = 0;
      for (int i = 0; i < 40; i++) {
        n += pillsForDate(
          DateTime(2026, 11, 3).add(Duration(days: i)),
          topics: {'science', 'music', 'thinking'},
          weights: {'science': 1, 'music': 1},
          day: day,
        ).where((p) => p.topic == kTopics['music']!.name).length;
      }
      return n;
    }

    final int early = musicOn(0);
    final int past = musicOn(kShowcaseDays);
    expect(
      (early - past).abs(),
      lessThanOrEqualTo(12),
      reason: '$early, $past',
    );
  });

  test('a day is arranged with its drawn read first', () {
    final Pill plain = PillBank.cards.firstWhere(
      (p) => !p.asksSomething && !p.hasPage,
    );
    final Pill drawing = PillBank.cards.firstWhere(
      (p) => !p.asksSomething && p.hasPage,
    );
    final Pill question = PillBank.cards.firstWhere(
      (p) => p.asksSomething && p.challenge is! TakeASide,
    );
    final List<Pill> day = arrangeDay([plain, question, drawing]);
    expect(day.first.id, drawing.id);
    expect(day.last.id, plain.id);
  });
}
