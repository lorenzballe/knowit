import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:astuto/data/explore_mix.dart';
import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/data/themed_shelves.dart';
import 'package:astuto/data/topics.dart';
import 'package:astuto/models/pill.dart';

void main() {
  final List<Pill> bank = PillBank.cards;

  List<String> idsOf(ExploreMix m) => [
    ...m.month.map((p) => p.id),
    ...?m.myths?.pills.map((p) => p.id),
    ...?m.numbers?.pills.map((p) => p.id),
    ...?m.trueFalse?.pills.map((p) => p.id),
    ...?m.practical?.pills.map((p) => p.id),
    ...?m.debates?.pills.map((p) => p.id),
    ...m.work.cards.map((p) => p.id),
    for (final (_, cards) in m.eras) ...cards.map((p) => p.id),
    ...?m.stories?.pills.map((p) => p.id),
    ...?m.sharpest?.pills.map((p) => p.id),
    ...m.didYouKnow.map((p) => p.id),
    ...m.compared.map((p) => p.id),
    ...?m.seen?.pills.map((p) => p.id),
    ...m.sampling.map((p) => p.id),
    for (final s in m.series) ...s.cards.map((p) => p.id),
    ...?m.origins?.pills.map((p) => p.id),
    ...m.whatIf.map((p) => p.id),
    ...m.howSure.map((p) => p.id),
  ];

  group('the subject of the month', () {
    test('is Pop culture in October 2026 and turns on the first', () {
      expect(monthSubject(DateTime(2026, 10, 1)), 'pop_culture');
      expect(monthSubject(DateTime(2026, 10, 31)), 'pop_culture');
      expect(monthSubject(DateTime(2026, 11, 1)), isNot('pop_culture'));
    });

    test('comes round every subject but Thinking before it repeats', () {
      final seen = <String>{
        for (int m = 0; m < kMonthSubjects.length; m++)
          monthSubject(DateTime(2026, 10 + m, 1)),
      };
      expect(seen, hasLength(kMonthSubjects.length));
      expect(seen, isNot(contains('thinking')));
      for (final key in seen) {
        expect(kTopics.containsKey(key), isTrue, reason: key);
      }
      // And before 2026 too: no month is without a subject.
      expect(kMonthSubjects, contains(monthSubject(DateTime(2025, 3, 1))));
    });
  });

  group('the whole mix', () {
    final mix = dealExploreMix(
      bank: bank,
      pool: bank,
      day: 20735,
      on: DateTime(2026, 10, 9),
    );

    test('no card is on two shelves', () {
      final ids = idsOf(mix);
      expect(ids.toSet().length, ids.length);
      // The round is everybody's, and the shelves leave its eight alone.
      expect(
        ids.toSet().intersection(mix.sixty.map((p) => p.id).toSet()),
        isEmpty,
      );
    });

    test('every shelf holds what it says it holds', () {
      expect(mix.month, isNotEmpty);
      for (final p in mix.month) {
        expect(p.topic, kTopics[mix.monthSubjectKey]!.name, reason: p.id);
      }
      expect(mix.sixty, hasLength(8));
      expect(mix.sixty.every(isTrueOrFalse), isTrue);
      expect(mix.sixty.map((p) => p.topic).toSet(), hasLength(8));
      for (final p in mix.trueFalse!.pills) {
        expect(isTrueOrFalse(p), isTrue, reason: p.id);
      }
      for (final p in mix.myths!.pills) {
        expect(p.hook, 'misconception', reason: p.id);
      }
      for (final p in mix.sharpest!.pills) {
        expect(p.difficulty, Difficulty.hard, reason: p.id);
      }
      for (final p in mix.compared) {
        expect(p.principle, Principle.counterfactual, reason: p.id);
      }
      for (final p in mix.sampling) {
        expect(p.principle, Principle.sampling, reason: p.id);
      }
      for (final p in mix.didYouKnow) {
        expect(p.challenge, isA<NoChallenge>(), reason: p.id);
      }
      for (final p in mix.unmask) {
        expect(canUnmask(p), isTrue, reason: p.id);
      }
      for (final p in mix.whatIf) {
        expect(p.ask, isNotEmpty, reason: p.id);
      }
      for (final (era, cards) in mix.eras) {
        expect(kEras, contains(era));
        for (final p in cards) {
          expect(p.era, era, reason: p.id);
        }
      }
      expect(mix.front, isNotNull);
    });

    test('is the same for everybody on a day, and dealt afresh the next', () {
      final again = dealExploreMix(
        bank: List.of(bank.reversed),
        pool: List.of(bank.reversed),
        day: 20735,
        on: DateTime(2026, 10, 9),
      );
      expect(idsOf(again), idsOf(mix));
      final tomorrow = dealExploreMix(
        bank: bank,
        pool: bank,
        day: 20736,
        on: DateTime(2026, 10, 10),
      );
      expect(idsOf(tomorrow), isNot(idsOf(mix)));
    });

    test('a card read is never dealt to a shelf for finding things', () {
      final read = {for (final p in bank.take(1500)) p.id};
      final unread = bank.where((p) => !read.contains(p.id)).toList();
      final m = dealExploreMix(
        bank: bank,
        pool: unread,
        day: 20735,
        on: DateTime(2026, 10, 9),
      );
      final ids = idsOf(m);
      // The charts are the one exception: there are few of them, and
      // unmasking one is not reading it.
      final unmask = m.unmask.map((p) => p.id).toSet();
      expect(
        ids.where((id) => read.contains(id) && !unmask.contains(id)),
        isEmpty,
      );
    });

    test('a subject chosen narrows every shelf to it', () {
      final space = bank.where((p) => p.topic == 'Space').toList();
      final m = dealExploreMix(
        bank: space,
        pool: space,
        day: 20735,
        on: DateTime(2026, 10, 9),
      );
      for (final id in idsOf(m)) {
        expect(PillBank.byId(id)!.topic, 'Space', reason: id);
      }
      // Pop culture's month has nothing to show in Space.
      expect(m.month, isEmpty);
    });
  });

  group('working a number out', () {
    final work = workItOut(bank, day: 20735);

    test('every way of playing has cards, and no card is in two', () {
      expect(work.pick, isNotEmpty);
      expect(work.slide, isNotEmpty);
      expect(work.closer, isNotEmpty);
      expect(work.bigger, isNotEmpty);
      expect(work.range, isNotEmpty);
      expect(work.stake, isNotEmpty);
      final ids = work.cards.map((p) => p.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('one row holds every card dealt, each once, two of each way', () {
      int count(WorkKind k) => switch (k) {
        WorkKind.pick => work.pick.length,
        WorkKind.slide => work.slide.length,
        WorkKind.closer => work.closer.length,
        WorkKind.bigger => work.bigger.length,
        WorkKind.range => work.range.length,
        WorkKind.stake => work.stake.length,
      };
      for (final k in WorkKind.values) {
        expect(count(k), kWorkEach, reason: k.name);
      }
      expect(work.row.toSet(), {
        for (final k in WorkKind.values)
          for (int i = 0; i < count(k); i++) (k, i),
      });
      expect(work.row, hasLength(work.row.toSet().length));
    });

    test('the row is mixed: every way in the first round, never two '
        'side by side', () {
      for (int day = 20730; day < 20760; day++) {
        final row = workRow({
          for (final k in WorkKind.values) k: kWorkEach,
        }, day: day);
        expect(row, hasLength(WorkKind.values.length * kWorkEach));
        expect(
          row.take(WorkKind.values.length).map((e) => e.$1).toSet(),
          WorkKind.values.toSet(),
          reason: 'day $day',
        );
        for (int i = 1; i < row.length; i++) {
          expect(row[i].$1, isNot(row[i - 1].$1), reason: 'day $day: $row');
        }
      }
    });

    test('the row holds still all day and is drawn afresh the next', () {
      final counts = {for (final k in WorkKind.values) k: kWorkEach};
      expect(workRow(counts, day: 20735), workRow(counts, day: 20735));
      final days = {
        for (int day = 20735; day < 20745; day++)
          workRow(counts, day: day).map((e) => e.$1.name).join(','),
      };
      expect(days.length, greaterThan(5));
      // A way with fewer cards drops out of the later rounds, and the rest
      // still never sit side by side.
      final short = workRow({
        WorkKind.pick: 3,
        WorkKind.slide: 1,
        WorkKind.closer: 3,
      }, day: 20735);
      expect(short, hasLength(7));
      for (int i = 1; i < short.length; i++) {
        expect(short[i].$1, isNot(short[i - 1].$1), reason: '$short');
      }
    });

    test('a share is the card\'s own answer, from 0 to 100', () {
      for (final c in [...work.slide, ...work.closer, ...work.range]) {
        expect(c.value, inInclusiveRange(0, 100), reason: c.pill.id);
        expect(percentOf(c.pill)!.value, c.value);
      }
    });

    test('the two figures to compare are far apart, and from two subjects', () {
      for (final (a, b) in work.bigger) {
        expect((a.value - b.value).abs(), greaterThanOrEqualTo(8));
        expect(a.pill.topic, isNot(b.pill.topic));
      }
    });

    test('a share is read from the options or from the unit', () {
      Pill card(Challenge c) => Pill(
        id: 't',
        topic: 'Science',
        color: const Color(0xFF00E5A0),
        ink: const Color(0xFF10100C),
        tint: const Color(0xFF00E5A0),
        question: 'q',
        answer: 'a',
        barMove: '',
        source: '',
        challenge: c,
      );
      expect(
        percentOf(
          card(
            const PickOne(
              options: ['About 13%', 'About 30%', 'About 45%'],
              correct: 1,
            ),
          ),
        )!.value,
        30,
      );
      expect(
        percentOf(card(const TypeNumber(answer: 28, unit: 'percent')))!.value,
        28,
      );
      expect(
        percentOf(card(const TypeNumber(answer: 28, unit: 'years'))),
        isNull,
      );
      expect(
        percentOf(
          card(
            const PickOne(
              options: ['1 in 6', '1 in 11', '1 in 36'],
              correct: 1,
            ),
          ),
        ),
        isNull,
      );
    });
  });

  group('the smaller pieces', () {
    test('a claim is the question without its "True or false:"', () {
      final p = bank.firstWhere(isTrueOrFalse);
      expect(claimOf(p).toLowerCase(), isNot(startsWith('true or false')));
      expect(claimOf(p), isNot(endsWith('?')));
    });

    test('a year is read from the question only', () {
      final p = bank.firstWhere(
        (p) => RegExp(r'\b1[5-9]\d\d\b').hasMatch(p.question),
      );
      expect(questionYear(p), isNotNull);
      expect(p.question, contains(questionYear(p)!.replaceAll('s', '')));
    });

    test('the first lines of an answer stop at a sentence or a word', () {
      const long =
          'About 20 million, nearly half the population. Many believed they '
          'were watching men die. But the best-known sequence was filmed at a '
          'training ground behind the lines, and the image the country kept '
          'of the battle had been rehearsed for the camera that day.';
      expect(firstLines(long), startsWith('About 20 million'));
      expect(firstLines(long).length, lessThanOrEqualTo(181));
      expect(firstLines('Short. Then more.'), 'Short. Then more.');
    });

    test('a name reads inside a sentence, an acronym keeps its capital', () {
      expect(inSentence('Physics'), 'physics');
      expect(inSentence('What makes it valuable'), 'what makes it valuable');
      expect(inSentence('AI'), 'AI');
      expect(inSentence('About 42%'), 'about 42%');
    });

    test('the time there is is never overspent', () {
      for (final tone in Tone.values) {
        for (final minutes in kMinutesYouHave) {
          final cards = forTheTime(bank, tone: tone, minutes: minutes, day: 9);
          final spent = cards.fold(0, (s, p) => s + minutesFor(p));
          expect(spent, lessThanOrEqualTo(minutes), reason: '$tone $minutes');
          expect(cards, isNotEmpty, reason: '$tone $minutes');
        }
      }
    });

    test('a series is a handful of cards, easiest first', () {
      final series = seriesOfTheDay(bank, day: 20735);
      expect(series.length, inInclusiveRange(1, 3));
      for (final s in series) {
        expect(s.cards.length, inInclusiveRange(3, 4), reason: s.key);
        final ranks = s.cards.map((p) => p.difficulty.index).toList();
        expect(ranks, [...ranks]..sort(), reason: s.key);
      }
    });

    test('the front page is the same however the bank is ordered', () {
      final a = frontPage(bank, day: 20735)!;
      final b = frontPage(List.of(bank.reversed), day: 20735)!;
      expect(b.cards.map((p) => p.id), a.cards.map((p) => p.id));
      expect(a.numbers.every((p) => shelfFigure(p) != null), isTrue);
      expect(a.columns.map((p) => p.topic), isNot(contains(a.lead.topic)));
    });
  });
}
