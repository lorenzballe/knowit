import 'package:flutter_test/flutter_test.dart';

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
}
