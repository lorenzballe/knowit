// The front page (141f), in its seven parts: the masthead and its words;
// the lead and a standfirst that never gives the answer away; two columns,
// three figures, a correction and a puzzle, each of its own kind; the last
// line. Made only of defaults from one pool, the parts never print the
// same card twice, and deal them by the day, whatever order Explore keeps
// its cards in; given their cards, they print those.
//
//   flutter test test/explore/screens_front_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:astuto/data/themed_shelves.dart';
import 'package:astuto/explore/blocks/screens/front_page.dart';
import 'package:astuto/explore/explore_block.dart';
import 'package:astuto/l10n/app_localizations_en.dart';
import 'package:astuto/models/pill.dart';

import 'fake_host.dart';
import 'screens_harness.dart';

void main() {
  setUpAll(loadScreensFonts);

  final l = AppLocalizationsEn();

  /// A day's pool with every kind a part looks for.
  List<Pill> pool() => [
    ...bankWhere(isFigure, most: 4),
    ...bankWhere(isCorrection, most: 2),
    ...bankWhere((p) => p.challenge is TakeASide, most: 2),
    ...bankWhere(isPuzzle, most: 2),
    ...bankWhere(isLead, most: 2),
    ...bankWhere(
      (p) => p.hook == 'practical' && p.challenge is! TakeASide,
      most: 2,
    ),
  ];

  testWidgets('the masthead: the day, the name, the edition', (tester) async {
    final app = await screensReader();
    final host = FakeExploreHost(app);
    await pumpBlock(
      tester,
      const MastheadBlock(),
      screensSection('masthead'),
      host,
    );
    expect(find.text(l.screensFrontName), findsOneWidget);
    expect(find.text(l.screensFrontEdition.toUpperCase()), findsOneWidget);
    expect(find.text(l.screensFrontSame.toUpperCase()), findsOneWidget);
    await pumpBlock(
      tester,
      const MastheadBlock(),
      screensSection('masthead', {
        'title': 'The Sunday Astute',
        'kicker': {'en': 'A special edition'},
        'right': {'en': 'Six cards'},
      }),
      host,
    );
    expect(find.text('The Sunday Astute'), findsOneWidget);
    expect(find.text('A SPECIAL EDITION'), findsOneWidget);
    expect(find.text('SIX CARDS'), findsOneWidget);
  });

  testWidgets('the lead\'s standfirst never gives the answer away', (
    tester,
  ) async {
    final Pill lead = bankWhere(isLead).first;
    var app = await screensReader();
    var host = FakeExploreHost(app)..cards['x'] = [lead];
    await pumpBlock(
      tester,
      const FrontLeadBlock(),
      screensSection('front-lead'),
      host,
    );
    expect(find.text(lead.question), findsOneWidget);
    expect(find.text(lead.barMove), findsNothing);
    // Read, the line to keep is the standfirst.
    app = await screensReader({
      'knowit.seenIds': [lead.id],
    });
    host = FakeExploreHost(app)..cards['x'] = [lead];
    await pumpBlock(
      tester,
      const FrontLeadBlock(),
      screensSection('front-lead'),
      host,
    );
    expect(find.text(lead.barMove), findsOneWidget);
    // The section's own headline and standfirst come first.
    await pumpBlock(
      tester,
      const FrontLeadBlock(),
      screensSection('front-lead', {
        'headline': {'en': 'The universe is speeding up'},
        'deck': 'So why is the rate falling?',
      }),
      host,
    );
    expect(find.text('The universe is speeding up'), findsOneWidget);
    expect(find.text('So why is the rate falling?'), findsOneWidget);
    await tester.tap(find.byKey(ValueKey('explore-${lead.id}')));
    expect(host.opened, [('x', lead.id)]);
  });

  testWidgets('made of defaults from one pool, no part repeats a card', (
    tester,
  ) async {
    final app = await screensReader();
    final List<Pill> day = pool();
    final Map<String, List<String>> printed = {};
    for (final ExploreBlock block in const [
      FrontLeadBlock(),
      FrontColumnsBlock(),
      FrontNumbersBlock(),
      FrontCorrectionBlock(),
      FrontPuzzleBlock(),
    ]) {
      final host = FakeExploreHost(app)..cards['x'] = day;
      final bool drew = await pumpBlock(
        tester,
        block,
        screensSection(block.name),
        host,
      );
      expect(drew, isTrue, reason: block.name);
      printed[block.name] = [for (final s in host.shown) s.$2];
    }
    final List<String> all = [for (final ids in printed.values) ...ids];
    expect(all.toSet().length, all.length, reason: '$printed');
    // Each part prints its own kind.
    Pill card(String id) => day.firstWhere((p) => p.id == id);
    expect(isLead(card(printed['front-lead']!.single)), isTrue);
    expect(
      printed['front-columns']!.map(card).any((p) => p.challenge is TakeASide),
      isTrue,
    );
    expect(printed['front-numbers']!.map(card).every(isFigure), isTrue);
    expect(isCorrection(card(printed['front-correction']!.single)), isTrue);
    expect(isPuzzle(card(printed['front-puzzle']!.single)), isTrue);
  });

  test(
    'the deal is the day\'s, not the order Explore keeps its cards in',
    () async {
      final app = await screensReader();
      final List<Pill> pool = bankWhere((p) => true, most: 800);
      final DateTime monday = DateTime(2026, 10, 19);
      List<String> dealt(List<Pill> cards, DateTime on) {
        final host = FakeExploreHost(app)..cards['x'] = cards;
        final ExploreSection section = screensSection('front-lead');
        return [
          for (final FrontPart part in FrontPart.values)
            for (final Pill p in frontCards(
              host,
              section,
              part,
              count: 2,
              on: on,
            ))
              p.id,
          for (final Pill p in frontColumns(host, section, on: on)) p.id,
        ];
      }

      final List<String> today = dealt(pool, monday);
      expect(today, hasLength(12));
      expect(dealt(pool.reversed.toList(), monday), today);
      // Another day, another page.
      final Set<String> leads = {
        for (int d = 0; d < 7; d++)
          dealt(pool, monday.add(Duration(days: d))).first,
      };
      expect(leads.length, greaterThan(1));
    },
  );

  testWidgets('the figures are set large, and only cards with one count', (
    tester,
  ) async {
    final app = await screensReader();
    final List<Pill> figures = bankWhere(isFigure, most: 3);
    final host = FakeExploreHost(app)..cards['x'] = figures;
    await pumpBlock(
      tester,
      const FrontNumbersBlock(),
      screensSection('front-numbers'),
      host,
    );
    for (final Pill p in figures) {
      expect(find.text(shelfFigure(p)!), findsWidgets);
    }
    host.cards['x'] = bankWhere((p) => !isFigure(p), most: 10);
    expect(
      await pumpBlock(
        tester,
        const FrontNumbersBlock(),
        screensSection('front-numbers'),
        host,
      ),
      isFalse,
    );
  });

  testWidgets('given their cards, the parts print those, in order', (
    tester,
  ) async {
    final app = await screensReader();
    final List<Pill> two = bankWhere((p) => p.topic == 'Music', most: 2);
    final host = FakeExploreHost(app);
    await pumpBlock(
      tester,
      const FrontColumnsBlock(),
      screensSection('front-columns', {
        'source': {
          'ids': [for (final p in two) p.id],
        },
      }),
      host,
    );
    expect(host.shown.map((s) => s.$2), [for (final p in two) p.id]);
  });

  testWidgets('the puzzle\'s button opens it to be worked out', (tester) async {
    final app = await screensReader();
    final Pill puzzle = bankWhere(isPuzzle).first;
    final host = FakeExploreHost(app)..cards['x'] = [puzzle];
    await pumpBlock(
      tester,
      const FrontPuzzleBlock(),
      screensSection('front-puzzle', {'button': 'Solve it'}),
      host,
    );
    expect(find.text(l.screensFrontPuzzle.toUpperCase()), findsOneWidget);
    await tester.tap(find.text('Solve it'));
    expect(host.opened, [('x', puzzle.id)]);
  });

  testWidgets('the correction is a myth, under the line that says so', (
    tester,
  ) async {
    final app = await screensReader();
    final Pill myth = bankWhere(isCorrection).first;
    final host = FakeExploreHost(app)
      ..cards['x'] = [...bankWhere((p) => !isCorrection(p), most: 5), myth];
    await pumpBlock(
      tester,
      const FrontCorrectionBlock(),
      screensSection('front-correction'),
      host,
    );
    expect(find.text(myth.question), findsOneWidget);
    expect(find.text(l.themeMythsLine), findsOneWidget);
    host.cards['x'] = bankWhere((p) => !isCorrection(p), most: 5);
    expect(
      await pumpBlock(
        tester,
        const FrontCorrectionBlock(),
        screensSection('front-correction'),
        host,
      ),
      isFalse,
    );
  });

  testWidgets('the edition ends, in its own words or the section\'s', (
    tester,
  ) async {
    final app = await screensReader();
    final host = FakeExploreHost(app);
    await pumpBlock(
      tester,
      const EditionEndBlock(),
      screensSection('edition-end'),
      host,
    );
    expect(find.text(l.screensFrontEnd), findsOneWidget);
    expect(find.text(l.screensFrontTomorrow), findsOneWidget);
    await pumpBlock(
      tester,
      const EditionEndBlock(),
      screensSection('edition-end', {
        'title': 'That was Sunday',
        'subtitle': {'en': 'Monday is out at seven'},
      }),
      host,
    );
    expect(find.text('That was Sunday'), findsOneWidget);
    expect(find.text('Monday is out at seven'), findsOneWidget);
  });
}
