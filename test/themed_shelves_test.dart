import 'package:flutter_test/flutter_test.dart';

import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/data/themed_shelves.dart';

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
}
