// The cards on the landing page's first screen (tool/site/README.md): the
// pool the page deals today's nine from, five on the phone's shelf and four
// around it. Every one must be a card the app deals, drawn, with the
// pictures the page shows and the page it plays, and named for its subject
// as the page's script expects: the subject is read from the card's id, and
// painted in the colour the page gives that subject.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:astuto/data/explore_mix.dart' show subjectKeyOf;
import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/state/app_state.dart';

void main() {
  final String page = File('site/index.html').readAsStringSync();
  final String script = page.substring(
    page.indexOf('const POOL = ['),
    page.indexOf('const now = new Date();', page.indexOf('const POOL = [')),
  );
  final List<(String, String)> pool = [
    for (final RegExpMatch m in RegExp(
      r'\["([a-z_]+-[a-z0-9-]+)", "([^"]+)"\]',
    ).allMatches(script))
      (m.group(1)!, m.group(2)!),
  ];
  final Map<String, String> colours = {
    for (final RegExpMatch m in RegExp(
      r"(\w+): \['[^']+', '(#[0-9A-F]{6})'\]",
    ).allMatches(script))
      m.group(1)!: m.group(2)!,
  };

  test('the pool is there, large enough for a different nine every day', () {
    expect(pool.length, greaterThanOrEqualTo(54));
    expect({for (final (String id, _) in pool) id}, hasLength(pool.length));
    // Nine a day, a different nine for at least six days running.
    expect(pool.length ~/ 9, greaterThanOrEqualTo(6));
    // Enough subjects for five different ones on the phone every day.
    expect(
      {for (final (String id, _) in pool) id.split('-').first}.length,
      greaterThanOrEqualTo(9),
    );
  });

  for (final (String id, String what) in pool) {
    test(id, () {
      final Pill? card = PillBank.byId(id);
      expect(card, isNotNull, reason: 'not in the bank');
      expect(
        PillBank.cards.any((p) => p.id == id),
        isTrue,
        reason: 'not dealt: retired, about a place, or a book',
      );
      expect(card!.mature, isFalse);
      expect(card.web, isNotNull, reason: 'not drawn');
      for (final String file in [
        'web/cards/pages/$id.html',
        'web/cards/thumbs/$id-front.webp',
        'web/cards/thumbs/$id-back.webp',
        'web/cards/thumbs/large/$id-front.webp',
      ]) {
        expect(File(file).existsSync(), isTrue, reason: file);
      }
      final String subject = id.split('-').first;
      expect(subjectKeyOf(card), subject);
      expect(colours[subject], AppState.hexOf(card.color), reason: subject);
      expect(what.trim(), isNotEmpty);
    });
  }
}
