// The moments the games of time are dealt from (lib/data/dated_lines.dart):
// a year counts only where the card's own words make it a date, a false
// claim is never a moment, and the day's rounds are fair — the same for
// everybody, other moments for each game, no two years too close to put
// in order, a chain worth asking about — and afresh the next day.
//
//   flutter test test/explore/dated_lines_test.dart
import 'package:flutter_test/flutter_test.dart';

import 'package:astuto/data/card_json.dart';
import 'package:astuto/data/dated_lines.dart';
import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/models/pill.dart';

int _n = 0;

/// A card asking [question], of [topic].
Pill _read(String question, {String topic = 'history'}) => cardFromJson({
  'id': 'dated-${_n++}',
  'topic': topic,
  'kind': 'read',
  'difficulty': 'easy',
  'principle': 'none',
  'question': question,
  'answer': 'Because it did, and that is all there is to it.',
  'move': 'The move.',
  'source': 'A source',
});

/// A true-or-false card claiming [claim], which is [truth].
Pill _claim(String claim, {required bool truth}) => cardFromJson({
  'id': 'dated-${_n++}',
  'topic': 'history',
  'kind': 'pickOne',
  'difficulty': 'easy',
  'principle': 'none',
  'question': 'True or false: $claim?',
  'options': ['True', 'False'],
  'correct': truth ? 0 : 1,
  'answer': 'So it was.',
  'move': 'The move.',
  'trap': 'The trap.',
  'source': 'A source',
});

void main() {
  group('a year that is a date', () {
    test('in, of, a month, or a thing of its year', () {
      for (final (String q, int year) in [
        ('In 1990 McDonald\'s stopped frying in beef fat. What replaced it?',
            1990),
        ('Raiders of the Lost Ark was the biggest hit of 1981. Who turned it '
            'down?', 1981),
        ('In Strasbourg in February 1349, what drove the killings?', 1349),
        ('Greenspan warned of irrational exuberance in December 1996. '
            'Where was the index?', 1996),
        ('Chadwick\'s 1842 report said labourers died at 15. What does it '
            'mean?', 1842),
        ('A 2016 study put the number of galaxies at 2 trillion. What '
            'next?', 2016),
      ]) {
        final DatedLine? d = datedLineOf(_read(q));
        expect(d, isNotNull, reason: q);
        expect(d!.year, year);
        expect(d.text, q);
        expect(d.gapped('____'), isNot(contains('$year')));
      }
    });

    test('never a bound, a baseline, a span, a decade, a number or a '
        'title', () {
      for (final String q in [
        'Since 1980, have computers squeezed out the lowest-paid jobs?',
        'Before 1492, which trees did people tend in the Amazon?',
        'Does the world keep more hives today than it did in 1961?',
        'How much poorer would the US have been in 1890 with no railways?',
        'What happened to prices from 1913 to 1977?',
        'Why did the music of the 1960s sound so loud?',
        'Why did the 1871–72 season start so late?',
        'Why does 2001: A Space Odyssey still look modern?',
        'How long would 1500 metres of film run?',
        'In 1984 and 1985, what did the miners ask for?',
        'Why was 2049 chosen for the sequel?',
      ]) {
        expect(datedLineOf(_read(q)), isNull, reason: q);
      }
    });

    test('a true claim is a moment; a false one never is', () {
      final DatedLine? truth = datedLineOf(
        _claim('a 1936 survey found half of Britain underfed', truth: true),
      );
      expect(truth, isNotNull);
      expect(truth!.year, 1936);
      expect(truth.text, startsWith('A 1936 survey'));
      expect(
        datedLineOf(
          _claim(
            'most American families owned shares in the crash of 1929',
            truth: false,
          ),
        ),
        isNull,
      );
    });

    test('a year still to come is a plan, not a moment', () {
      final Pill plan = _read('What will the mission find in 2029?');
      expect(datedLineOf(plan), isNotNull);
      expect(datedLines([plan], latest: 2026), isEmpty);
    });
  });

  group('the day\'s rounds', () {
    final List<DatedLine> lines = datedLines(
      PillBank.cards,
      latest: DateTime.now().year,
    );

    test('the bank has moments for many days of rounds', () {
      expect(lines.length, greaterThan(200));
    });

    test('the same for everybody on a day, others the next day', () {
      final TimeDeal a = TimeDeal(lines, day: 400);
      final TimeDeal b = TimeDeal([...lines.reversed], day: 400);
      final TimeDeal c = TimeDeal(lines, day: 401);
      for (final TimeGame g in TimeGame.values) {
        final List<String> today = [
          for (final d in a.round(g, 0)) d.pill.id,
        ];
        expect(today, hasLength(g.size));
        expect([for (final d in b.round(g, 0)) d.pill.id], today);
        expect([for (final d in c.round(g, 0)) d.pill.id], isNot(today));
      }
    });

    test('fair rounds: years far enough apart to order, one subject each, '
        'a chain worth asking, no moment in two games', () {
      for (int day = 300; day < 330; day++) {
        final TimeDeal deal = TimeDeal(lines, day: day);
        final List<DatedLine> order = deal.round(TimeGame.order, 0);
        for (int i = 0; i < order.length; i++) {
          for (int j = i + 1; j < order.length; j++) {
            expect(
              (order[i].year - order[j].year).abs(),
              greaterThanOrEqualTo(5),
            );
          }
        }
        expect(order.map((d) => d.pill.topic).toSet(), hasLength(4));
        final List<DatedLine> year = deal.round(TimeGame.year, 0);
        expect(year.map((d) => d.year ~/ 10).toSet(), hasLength(3));
        final List<DatedLine> chain = deal.round(TimeGame.chain, 0);
        for (int i = 1; i < chain.length; i++) {
          final int gap = (chain[i].year - chain[i - 1].year).abs();
          expect(gap, inInclusiveRange(2, 80));
        }
        final List<String> all = [
          for (final g in TimeGame.values)
            for (final d in deal.round(g, 0)) d.pill.id,
        ];
        expect(all.toSet(), hasLength(all.length));
        // Played again: other moments than the day's first round.
        final Set<String> again = {
          for (final d in deal.round(TimeGame.order, 1)) d.pill.id,
        };
        expect(again.intersection(all.toSet()), isEmpty);
      }
    });

    test('too few moments make no round', () {
      expect(TimeDeal(lines.take(2).toList(), day: 1).round(TimeGame.order, 0),
          isEmpty);
    });
  });

  test('a year\'s points: ten for the year itself, fewer as it is further '
      'off, as fair for the Middle Ages as for last decade', () {
    expect(yearPoints(1969, 1969, now: 2026), 10);
    expect(yearPoints(2016, 2016, now: 2026), 10);
    // Ten years off a recent year scores nothing; ten off a medieval one,
    // most of the points.
    expect(yearPoints(2006, 2016, now: 2026), 0);
    expect(yearPoints(1339, 1349, now: 2026), 9);
    expect(yearPoints(2013, 2016, now: 2026), 7);
    expect(yearPoints(1000, 2016, now: 2026), 0);
    for (int off = 0; off < 60; off++) {
      expect(
        yearPoints(1900 + off, 1900, now: 2026),
        greaterThanOrEqualTo(yearPoints(1901 + off, 1900, now: 2026)),
      );
    }
  });
}
