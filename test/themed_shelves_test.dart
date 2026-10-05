import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/data/themed_shelves.dart';
import 'package:astuto/models/pill.dart';

void main() {
  final pool = PillBank.cards;

  test('seven themes a day, each a full shelf', () {
    for (int day = 20000; day < 20030; day++) {
      final shelves = themedShelves(pool, day: day);
      expect(shelves, hasLength(kThemesPerDay), reason: '$day');
      for (final s in shelves) {
        expect(s.pills.length, kThemeCards, reason: s.key);
        expect(s.pills.map((p) => p.id).toSet(), hasLength(kThemeCards));
      }
    }
  });

  test('a different set of themes every day, none two days running', () {
    for (int day = 20000; day < 20060; day++) {
      final today = themedShelves(pool, day: day).map((s) => s.key).toSet();
      final next = themedShelves(pool, day: day + 1).map((s) => s.key).toSet();
      expect(today.intersection(next), isEmpty, reason: '$day');
    }
  });

  test('every theme comes up within a few days', () {
    final seen = <ShelfTheme>{};
    for (int day = 20000; day < 20000 + 3; day++) {
      seen.addAll(themedShelves(pool, day: day).map((s) => s.theme));
    }
    expect(seen, containsAll(ShelfTheme.values));
  });

  test('the same for everybody on a day, dealt afresh the next time round', () {
    final a = themedShelves(pool, day: 20100);
    final b = themedShelves(List.of(pool.reversed), day: 20100);
    expect(
      [for (final s in a) s.pills.map((p) => p.id).toList()],
      [for (final s in b) s.pills.map((p) => p.id).toList()],
    );
    final first = themedShelves(pool, day: 20100).first;
    // The next day round the cycle the theme is up again.
    final again = [
      for (int d = 20101; d < 20110; d++) ...themedShelves(pool, day: d),
    ].firstWhere((s) => s.theme == first.theme);
    expect(again.pills.map((p) => p.id), isNot(first.pills.map((p) => p.id)));
  });

  test('a theme with too few cards is skipped, not shown thin', () {
    final few = pool.where((p) => p.diagram == null).toList();
    for (int day = 20000; day < 20012; day++) {
      expect(
        themedShelves(few, day: day).map((s) => s.theme),
        isNot(contains(ShelfTheme.seen)),
      );
    }
  });

  test(
    'the three signature shelves are there every day, each true to kind',
    () {
      for (var day = 20000; day < 20020; day++) {
        final shelves = signatureShelves(pool, day: day);
        expect(shelves.map((s) => s.theme), kSignatureThemes, reason: '$day');
        for (final s in shelves) {
          expect(s.pills.length, kThemeCards, reason: s.key);
          for (final p in s.pills) {
            switch (s.theme) {
              case ShelfTheme.numbers:
                expect(shelfFigure(p), isNotNull, reason: p.id);
              case ShelfTheme.debates:
                expect(p.challenge, isA<TakeASide>(), reason: p.id);
              case ShelfTheme.practical:
                expect(p.challenge, isNot(isA<TakeASide>()), reason: p.id);
              default:
                fail('not a signature theme: ${s.theme}');
            }
          }
        }
      }
    },
  );

  test('the figure a numbers card shows is the amount, not the year', () {
    String? fig(String q) => shelfFigure(
      Pill(
        id: 'figure',
        topic: 'Science',
        color: const Color(0xFF00E5A0),
        ink: const Color(0xFF10100C),
        tint: const Color(0xFF00E5A0),
        question: q,
        answer: '',
        barMove: '',
        source: '',
      ),
    );
    expect(fig('In 1909 a chemist crushed 12,000 sea snails.'), '12,000');
    expect(fig('A court awarded \$6.75 million in 2013.'), '\$6.75M');
    expect(fig('It exposed 1,250,000 feet of film.'), '1.25M');
    expect(fig('About 30% wider than in a mirror.'), '30%');
    expect(fig('Who painted it in 1503?'), isNull);
  });
}
