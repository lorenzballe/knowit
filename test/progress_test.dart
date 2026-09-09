import 'package:flutter_test/flutter_test.dart';

import 'package:astuto/models/pill.dart';
import 'package:astuto/data/pills_data.dart';
import 'package:astuto/data/pills_repository.dart';
import 'package:astuto/data/topics.dart';
import 'package:astuto/state/progress.dart';

Judgement said(
  int confidence, {
  required bool right,
  String? on,
  String? pill,
}) => Judgement(confidence, correct: right, on: on, pillId: pill);

Standing standing({
  int read = 0,
  int answered = 0,
  int judged = 0,
  int held = 0,
  double? gap,
}) => Standing(
  read: read,
  answered: answered,
  judged: judged,
  held: held,
  gap: gap,
);

String key(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

void main() {
  group('The ladder', () {
    test('a fresh reader stands on the first rung', () {
      final s = standing();
      expect(s.at, 0);
      expect(s.rung.id, 'day_one');
      expect(s.next!.id, 'reading');
      expect(s.step!.kind, StepKind.read);
      expect(s.step!.n, 20);
    });

    test('it climbs on what the reader has actually done', () {
      expect(standing(read: 25).rung.id, 'reading');
      expect(standing(read: 45, answered: 22).rung.id, 'answering');
      expect(
        standing(read: 80, answered: 45, judged: 33).rung.id,
        'saying_how_sure',
      );
    });

    test('a rung that asks for calibration waits for the confidence', () {
      // Everything else cleared, but nothing to judge the confidence on.
      final blind = standing(read: 200, answered: 150, judged: 60, held: 30);
      expect(blind.rung.id, 'saying_how_sure');
      expect(blind.step!.kind, StepKind.beforeJudged);

      // The same reader, now measurably calibrated.
      final sharp = standing(
        read: 200,
        answered: 150,
        judged: 60,
        held: 30,
        gap: 9,
      );
      expect(sharp.rung.id, 'calibrated');
    });

    test('a wide gap holds the reader on the rung below', () {
      final loud = standing(
        read: 200,
        answered: 150,
        judged: 60,
        held: 30,
        gap: 28,
      );
      expect(loud.rung.id, 'saying_how_sure');
      expect(loud.step!.kind, StepKind.gap);
      expect(loud.step!.n, 28);
    });

    test('the bar follows the thing that is furthest behind', () {
      // Halfway on reading, nowhere on answering: the bar shows the worse.
      final s = standing(read: 30, answered: 0);
      expect(s.rung.id, 'reading');
      expect(s.toNext, lessThan(0.1));
      expect(s.step!.kind, StepKind.answer);
    });

    test('the top of the ladder asks for nothing more', () {
      final s = standing(
        read: 400,
        answered: 300,
        judged: 200,
        held: 100,
        gap: 4,
      );
      expect(s.rung.id, 'sharp');
      expect(s.next, isNull);
      expect(s.step, isNull);
      expect(s.toNext, 1);
    });
  });

  group('Weeks kept', () {
    // A Wednesday, so both ends of the week are in play.
    final today = DateTime(2026, 9, 9);
    final monday = DateTime(2026, 9, 7);

    Set<String> days(List<int> offsets) => {
      for (final o in offsets) key(monday.add(Duration(days: o))),
    };

    test('a week under five days is not kept', () {
      expect(weeksKept(days([0, 1, 2, 3]), today), 0);
    });

    test('five days keeps the week', () {
      expect(weeksKept(days([0, 1, 2, 3, 4]), today), 1);
    });

    test('the week in hand never breaks the count', () {
      // Two days so far this week — not kept yet, and not a break either:
      // last week's five still stands.
      final last = <String>{
        for (var i = 1; i <= 5; i++) key(monday.subtract(Duration(days: i))),
      };
      expect(
        weeksKept({
          ...days([0, 1]),
          ...last,
        }, today),
        1,
      );
    });

    test('it counts back as far as the weeks hold', () {
      final all = <String>{};
      for (var w = 0; w < 4; w++) {
        for (var d = 0; d < 5; d++) {
          all.add(key(monday.subtract(Duration(days: w * 7 - d))));
        }
      }
      expect(weeksKept(all, today), 4);
    });
  });

  group('The week read back', () {
    final today = DateTime(2026, 9, 9);
    final monday = DateTime(2026, 9, 7);
    final before = monday.subtract(const Duration(days: 7));

    test('it counts only what is dated inside the week', () {
      final report = weekReport(
        judgements: [
          said(90, right: false, on: key(monday)),
          said(90, right: true, on: key(monday)),
          said(50, right: true, on: key(before)),
          // Undated, from before the app dated anything: not this week.
          said(80, right: true),
        ],
        completedDates: [key(monday), key(monday.add(const Duration(days: 1)))],
        today: today,
      );
      expect(report.days, 2);
      expect(report.answered, 2);
      expect(report.right, 1);
      expect(report.kept, isFalse);
    });

    test('a week too thin to judge says nothing about the gap', () {
      final report = weekReport(
        judgements: [said(90, right: true, on: key(monday))],
        completedDates: [key(monday)],
        today: today,
      );
      expect(report.gap, isNull);
      expect(report.closing, isNull);
    });

    test('it says which way the gap moved', () {
      // Last week: sure and wrong. This week: sure and right.
      final report = weekReport(
        judgements: [
          for (var i = 0; i < 8; i++) said(90, right: false, on: key(before)),
          for (var i = 0; i < 8; i++) said(90, right: true, on: key(monday)),
        ],
        completedDates: const [],
        today: today,
      );
      expect(report.gapBefore!.round(), 90);
      expect(report.gap!.round(), 10);
      expect(report.closing, isTrue);
    });

    test('the misses are the ones said with certainty', () {
      final report = weekReport(
        judgements: [
          said(90, right: false, on: key(monday), pill: kPillPool.first.id),
          // Wrong, but nobody claimed to know.
          said(50, right: false, on: key(monday), pill: kPillPool.first.id),
        ],
        completedDates: const [],
        today: today,
      );
      expect(report.misses, hasLength(1));
      expect(report.misses.single.confidence, 90);
    });
  });

  group('What the reader knows leans the deal', () {
    // The lean only shows on a subject that holds both kinds of card —
    // some that ask and some that only tell — so the test finds one in the
    // pool rather than assuming which it is.
    late final String key;
    late final String name;
    setUpAll(() {
      final asks = <String, int>{};
      final reads = <String, int>{};
      for (final p in kPillPool) {
        final m = p.asksSomething ? asks : reads;
        m[p.topic] = (m[p.topic] ?? 0) + 1;
      }
      final both = asks.keys.where((t) => (reads[t] ?? 0) > 0).toList()
        ..sort((a, b) {
          int least(String t) => asks[t]! < reads[t]! ? asks[t]! : reads[t]!;
          return least(b).compareTo(least(a));
        });
      expect(both, isNotEmpty, reason: 'no subject holds both kinds of card');
      name = both.first;
      key = kTopics.entries.firstWhere((e) => e.value.name == name).key;
    });

    // A day is a fixed share of questions and reads, so on one subject the
    // lean can move nothing; against another it moves which subject's
    // questions take the asking slots. Over many days, count that subject's
    // questions in the deck.
    int questionsOf(int level) {
      final others = kTopics.keys.where((k) => k != key).toList();
      var n = 0;
      for (var d = 1; d <= 120; d++) {
        final deck = pillsForDate(
          DateTime(2026, 1, 1).add(Duration(days: d)),
          topics: {key, ...others},
          weights: {key: 1, for (final o in others) o: 1},
          levels: {key: level},
          count: 10,
        );
        n += deck.where((p) => p.topic == name && p.asksSomething).length;
      }
      return n;
    }

    test('solid is asked, curious is told', () {
      expect(questionsOf(2), greaterThan(questionsOf(0)));
    });

    test('saying nothing changes nothing', () {
      List<String> ids(Map<String, int> levels) => pillsForDate(
        DateTime(2026, 3, 3),
        topics: {'history', 'science'},
        weights: const {'history': 1, 'science': 1},
        levels: levels,
      ).map((p) => p.id).toList();
      expect(ids(const {'history': 1}), ids(const {}));
    });
  });
}
