// How the bets read a card's answer as a number, and what a bet keeps as
// the card's answer: the same as the remote checker reads it (both are held
// to bets_cases.json), and always what the card itself counts right.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/explore/blocks/bets/answers.dart';
import 'package:astuto/explore/blocks/bets/block.dart';
import 'package:astuto/explore/blocks/bets_blocks.dart';
import 'package:astuto/models/pill.dart';

/// The blocks that bet on [pill], by name: the slip lists any card with a
/// number for an answer.
List<String> blocksFor(Pill pill) {
  final BetAnswer? a = BetAnswer.of(pill);
  if (a == null) return const [];
  return [
    for (final b in blocks)
      if (b is BetBlock ? b.fits(a) : b.name == 'bets-slip') b.name,
  ]..sort();
}

void main() {
  final Map<String, Object?> cases = jsonDecode(
    File('test/explore/bets_cases.json').readAsStringSync(),
  ) as Map<String, Object?>;

  group('the same as the remote checker', () {
    test('amounts', () {
      for (final Object? c in cases['amounts']! as List) {
        final List row = c! as List;
        final Amount? got = Amount.parse(row[0] as String);
        if (row[1] == null) {
          expect(got, isNull, reason: row[0] as String);
        } else {
          expect(got, isNotNull, reason: row[0] as String);
          expect(got!.value, closeTo((row[1] as num).toDouble(), 1e-9));
          expect(got.percent, row[2], reason: row[0] as String);
        }
      }
    });

    test('odds', () {
      for (final Object? c in cases['odds']! as List) {
        final List row = c! as List;
        expect(
          oddsOf(row[0] as String),
          row[1] == null ? isNull : (row[1] as num).toDouble(),
          reason: row[0] as String,
        );
      }
    });

    test('which blocks bet on which cards', () {
      final Map cards = cases['cards']! as Map;
      for (final MapEntry e in cards.entries) {
        final Pill? pill = PillBank.byId(e.key as String);
        expect(pill, isNotNull, reason: e.key as String);
        expect(blocksFor(pill!), e.value, reason: e.key as String);
      }
    });

    test('the plain form an answer is kept in', () {
      for (final Object? c in cases['plain']! as List) {
        final List row = c! as List;
        expect(plainResponse((row[0] as num).toDouble()), row[1]);
      }
    });

    test('the numbers cards are placed by', () {
      for (final Object? c in cases['units']! as List) {
        final List row = c! as List;
        expect(betUnit(row[0] as String), (row[1] as num).toDouble());
      }
    });
  });

  group('a bet is the card answer', () {
    final List<BetAnswer> all = [
      for (final Pill p in PillBank.cards)
        if (BetAnswer.of(p) case final BetAnswer a) a,
    ];

    test('the bank has cards for every block', () {
      for (final b in blocks.whereType<BetBlock>()) {
        expect(all.where(b.fits), isNotEmpty, reason: b.name);
      }
    });

    test('the answer itself is right, by the card', () {
      for (final BetAnswer a in all) {
        if (a.isPick) {
          expect(a.accepts('${a.correct}'), isTrue, reason: a.pill.id);
          expect(a.value, a.amounts[a.correct]);
        } else {
          expect(a.accepts(plainResponse(a.value)), isTrue, reason: a.pill.id);
        }
      }
    });

    test('a share is from 0 to 100', () {
      for (final BetAnswer a in all.where((a) => a.share)) {
        expect(a.value, inInclusiveRange(0, 100), reason: a.pill.id);
      }
    });

    test('steppers reach the answer and never start on it', () {
      int checked = 0;
      for (final BetAnswer a in all) {
        final StepScale? s = StepScale.around(a);
        if (s == null || a.kind != BetAnswerKind.typed) continue;
        checked++;
        expect(
          a.accepts(plainResponse(s.start)),
          isFalse,
          reason: '${a.pill.id} starts on its answer',
        );
        // Walk from the start to the answer on the small step.
        double v = s.start;
        final double by = a.value > v ? s.small : -s.small;
        for (int i = 0; i < 400 && !a.accepts(plainResponse(v)); i++) {
          v = s.move(v, by);
        }
        expect(a.accepts(plainResponse(v)), isTrue, reason: a.pill.id);
        expect(s.big, anyOf(s.small * 10, s.small * 5));
      }
      expect(checked, greaterThan(100));
    });

    test('a card the steppers cannot reach is left out', () {
      // A typed number whose answer neither a tenth nor a twentieth of its
      // size reaches within its tolerance.
      final BetAnswer? a = BetAnswer.of(PillBank.byId('cinema-sequels-3')!);
      expect(a, isNotNull);
      expect(a!.kind, BetAnswerKind.typed);
      expect(StepScale.around(a), isNull);
      expect(blocksFor(a.pill), ['bets-friend', 'bets-slip']);
    });

    test('one notch is right, by the card, and the others are not', () {
      int checked = 0;
      for (final BetAnswer a in all) {
        final Notches? n = Notches.of(a);
        if (n == null) continue;
        checked++;
        for (int i = 1; i < n.values.length; i++) {
          expect(n.values[i], greaterThan(n.values[i - 1]));
        }
        expect(a.accepts(n.responseAt(n.right)), isTrue, reason: a.pill.id);
        if (a.isPick) continue;
        expect(n.values, hasLength(6));
        expect(n.right, inInclusiveRange(1, 4));
        for (int i = 0; i < n.values.length; i++) {
          if (i == n.right) continue;
          expect(a.accepts(n.responseAt(i)), isFalse, reason: a.pill.id);
          expect(n.offBy(i), (i - n.right).abs());
        }
      }
      expect(checked, greaterThan(10));
    });
  });

  group('numbers in the reader language', () {
    test('the per cent sign where the language puts it', () {
      expect(BetNumbers('en').percent(21.5), '21.5%');
      expect(BetNumbers('tr').percent(21.5), startsWith('%'));
      expect(BetNumbers('fr').percent(21.5), contains('21,5'));
      expect(BetNumbers('en').range(40, 60), '40–60%');
      expect(BetNumbers('tr').range(40, 60), startsWith('%40'));
    });

    test('powers of ten for a label with no room', () {
      expect(BetNumbers.power(1000), '1000');
      expect(BetNumbers.power(1e6), '10⁶');
      expect(BetNumbers.power(0.01), '10⁻²');
    });
  });
}
