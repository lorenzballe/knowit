// The core family of Explore's blocks: every one the checker knows and the
// app draws, every card block at every size on the narrowest phone and at a
// large text size with not one question cut, the rule the checker refuses a
// small box by held to the real fonts, and what each block does when it is
// touched.
//
//   flutter test test/explore/core_blocks_test.dart
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/explore/blocks/core/card_blocks.dart';
import 'package:astuto/explore/blocks/core/other_blocks.dart';
import 'package:astuto/explore/blocks/core_blocks.dart' as core;
import 'package:astuto/explore/catalogue.dart';
import 'package:astuto/explore/explore_block.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/state/app_state.dart';
import 'package:astuto/sync/served.dart';
import 'package:astuto/theme.dart';
import 'package:astuto/widgets/explore/card_tiles.dart';
import 'package:astuto/widgets/scaled_text.dart';

import 'core_harness.dart';

/// Every card block, with the sizes it has (null: it has none).
const Map<String, List<String?>> _cardBlocks = {
  'carousel': ['xs', 's', 'm', 'l', 'xl'],
  'hero': ['m', 'l', 'xl'],
  'banner': ['s', 'm', 'l'],
  'pair': ['s', 'm', 'l'],
  'list': ['s', 'm', 'l'],
  'stack': ['s', 'm', 'l'],
  'ticker': ['xs', 's', 'm'],
  'single': [null],
};

/// Whether every question set on screen is set whole: no ScaledText had to
/// scroll its question because even its smallest size did not fit.
void _nothingCut(WidgetTester tester) {
  for (final Element text in find.byType(ScaledText).evaluate()) {
    final Finder scroll = find.descendant(
      of: find.byElementPredicate((e) => e == text),
      matching: find.byType(Scrollable),
    );
    final ScrollPosition position = tester
        .state<ScrollableState>(scroll.first)
        .position;
    expect(
      position.maxScrollExtent,
      lessThanOrEqualTo(0.5),
      reason: (text.widget as ScaledText).text,
    );
  }
}

/// The share of the bank's questions a tile of [box] sets whole.
double _share(WidgetTester tester, Size box, {TileLook? look}) {
  final BuildContext context = tester.element(find.byType(Scaffold));
  final List<Pill> cards = PillBank.cards;
  int fit = 0;
  for (final Pill pill in cards) {
    if (questionFits(context, pill, box, look ?? TileLook.forBox(box))) fit++;
  }
  return fit / cards.length;
}

Future<void> _pumpEmpty(WidgetTester tester) async {
  tester.view.physicalSize = const Size(375, 667) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: buildAstutoTheme(Brightness.dark),
      home: const Scaffold(body: SizedBox()),
    ),
  );
}

void main() {
  setUpAll(loadFonts);
  setUp(() => Served.useForTest(Served()));

  test('every core block is the app\'s by its name, and the checker\'s', () {
    final Set<String> names = {for (final b in core.blocks) b.name};
    expect(names, hasLength(core.blocks.length));
    for (final ExploreBlock block in core.blocks) {
      expect(kExploreBlocks[block.name], same(block));
    }
    final String checker = File('tool/remote/parts/explore_blocks/core.py')
        .readAsStringSync();
    final String listed = checker.substring(checker.indexOf('BLOCKS:'));
    final Set<String> checked = {
      for (final m in RegExp(
        r'^\s+"([a-z-]+)":',
        multiLine: true,
      ).allMatches(listed))
        m.group(1)!,
    };
    expect(checked, names);
  });

  group('every card block at every size', () {
    for (final MapEntry<String, List<String?>> block in _cardBlocks.entries) {
      for (final String? size in block.value) {
        for (final double text in [1.0, 2.0]) {
          testWidgets('${block.key} ${size ?? ''} at ${text}x, 375 wide: '
              'drawn, nothing cut, a tap opens it', (tester) async {
            final CoreHost host = CoreHost(await readyApp());
            await pumpSections(tester, host, [
              ExploreSection.fromJson({
                'id': 'it',
                'block': block.key,
                'size': ?size,
                'title': 'A section',
                'source': {
                  'query': {
                    'subjects': ['space', 'history', 'psychology'],
                  },
                },
              }),
            ], text: text);
            expect(tester.takeException(), isNull);
            final Finder tiles = find.byWidgetPredicate(
              (w) =>
                  w.key is ValueKey<String> &&
                  (w.key! as ValueKey<String>).value.startsWith('explore-'),
            );
            expect(tiles, findsWidgets);
            _nothingCut(tester);
            await tester.tap(tiles.first, warnIfMissed: false);
            await tester.pump();
            expect(host.opened, isNotEmpty);
            expect(host.opened.first.$1, 'it');
          });
        }
      }
    }

    for (final (int columns, String shape) in [
      (2, 'portrait'),
      (2, 'square'),
      (2, 'landscape'),
      (3, 'portrait'),
      (3, 'square'),
      (4, 'portrait'),
    ]) {
      testWidgets('grid of $columns, $shape, at 1.5x, 375 wide: whole rows, '
          'nothing cut', (tester) async {
        final CoreHost host = CoreHost(await readyApp());
        await pumpSections(tester, host, [
          ExploreSection.fromJson({
            'id': 'grid',
            'block': 'grid',
            'columns': columns,
            'shape': shape,
            'limit': columns * 2,
            'source': {
              'query': <String, Object?>{'seed': 'fixed'},
            },
          }),
        ], text: 1.5);
        expect(tester.takeException(), isNull);
        final int tiles = find.byType(BoxTile).evaluate().length;
        expect(tiles, greaterThan(0));
        if (tiles > columns) expect(tiles % columns, 0);
        _nothingCut(tester);
      });
    }

    testWidgets('bento: every default mosaic, and one of every span, '
        'nothing cut', (tester) async {
      final CoreHost host = CoreHost(await readyApp());
      await pumpSections(tester, host, [
        for (final int columns in [2, 3, 4])
          ExploreSection.fromJson({
            'id': 'bento-$columns',
            'block': 'bento',
            'columns': columns,
            'source': {
              'query': {
                'subjects': ['science', 'history'],
              },
            },
          }),
        ExploreSection.fromJson({
          'id': 'spans',
          'block': 'bento',
          'columns': 4,
          'ratio': 1.4,
          'items': ['4x1', '3x2', '1x2', '2x3', '2x2', '1x3'],
          'source': {
            'query': <String, Object?>{'seed': 'week'},
          },
        }),
      ], size: const Size(375, 4000));
      expect(tester.takeException(), isNull);
      expect(find.byType(BoxTile), findsWidgets);
      _nothingCut(tester);
    });
  });

  testWidgets('a mosaic packs each item where it first fits', (tester) async {
    expect(
      packBento([
        (columns: 2, rows: 2),
        (columns: 1, rows: 1),
        (columns: 1, rows: 1),
        (columns: 3, rows: 1),
      ], 3),
      [
        (column: 0, row: 0),
        (column: 2, row: 0),
        (column: 2, row: 1),
        (column: 0, row: 2),
      ],
    );
    expect(bentoSpan('2x3', 3), (columns: 2, rows: 3));
    expect(bentoSpan('4x1', 3), isNull);
    expect(bentoSpan('2x4', 4), isNull);
    expect(bentoSpan(2, 4), isNull);
  });

  testWidgets('the checker\'s rule for a small box holds to the real fonts: '
      'what it lets through sets a fifth of the bank or more, what it '
      'refuses sets less than a quarter', (tester) async {
    await _pumpEmpty(tester);
    const double across = 375 - 40;
    for (final (int columns, String shape, bool allowed) in [
      (2, 'square', true),
      (2, 'portrait', true),
      (2, 'landscape', true),
      (3, 'square', true),
      (3, 'portrait', true),
      (4, 'portrait', true),
      (3, 'landscape', false),
      (4, 'square', false),
      (4, 'landscape', false),
    ]) {
      final double share = _share(
        tester,
        GridBlock.tileFor(across, columns, shape),
      );
      expect(
        share,
        allowed ? greaterThanOrEqualTo(0.2) : lessThan(0.25),
        reason: '$columns $shape: $share',
      );
    }
    final double unit = (across - 8 * 3) / 4;
    expect(_share(tester, Size(unit, unit)), lessThan(0.25));
    expect(_share(tester, Size(unit, unit * 2 + 8)), greaterThan(0.5));
  });

  testWidgets('the steps of a row hold the bank: all of it from s up, and '
      'nearly all of it at xs', (tester) async {
    await _pumpEmpty(tester);
    for (final TileSize size in TileSize.values) {
      final double share = _share(
        tester,
        Size(size.width, size.height),
        look: TileLook.of(size),
      );
      expect(
        share,
        size == TileSize.xs ? greaterThan(0.95) : greaterThan(0.995),
        reason: '${size.name}: $share',
      );
    }
  });

  testWidgets('a card block with no cards is not there at all', (tester) async {
    final CoreHost host = CoreHost(await readyApp());
    await _pumpEmpty(tester);
    final BuildContext context = tester.element(find.byType(Scaffold));
    for (final String block in [..._cardBlocks.keys, 'grid', 'bento']) {
      final ExploreSection section = ExploreSection.fromJson({
        'id': 'empty-$block',
        'block': block,
        'source': {'mine': 'saved'},
      });
      expect(
        kExploreBlocks[block]!.build(context, host, section),
        isNull,
        reason: block,
      );
    }
  });

  testWidgets('the deck: a swipe brings the next card up, a tap opens the '
      'one on top, at once for a reader who asked for less motion', (
    tester,
  ) async {
    for (final bool calm in [false, true]) {
      final CoreHost host = CoreHost(await readyApp());
      final List<Pill> cards = PillBank.cards
          .where((p) => p.question.length < 90)
          .take(3)
          .toList();
      host.cards['deck'] = cards;
      await pumpSections(tester, host, [
        ExploreSection.fromJson({'id': 'deck', 'block': 'stack'}),
      ], calm: calm);
      final Finder top = find.byKey(ValueKey('explore-${cards[0].id}'));
      await tester.drag(top, const Offset(-220, 0));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ValueKey('explore-${cards[1].id}')));
      await tester.pump();
      expect(host.opened.last, ('deck', cards[1].id));
      expect(host.shown, contains(('deck', cards[1].id)));
      await tester.pumpWidget(const SizedBox());
    }
  });

  testWidgets('the procession moves on by itself, and holds still for a '
      'reader who asked for less motion', (tester) async {
    for (final bool calm in [false, true]) {
      final CoreHost host = CoreHost(await readyApp());
      await pumpSections(tester, host, [
        ExploreSection.fromJson({
          'id': 'ticker',
          'block': 'ticker',
          'source': {
            'query': <String, Object?>{'seed': 'fixed'},
          },
        }),
      ], calm: calm);
      final ScrollPosition row = tester
          .state<ScrollableState>(
            find
                .descendant(
                  of: find.byType(Procession),
                  matching: find.byType(Scrollable),
                )
                .first,
          )
          .position;
      for (int i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      if (calm) {
        expect(row.pixels, 0);
      } else {
        expect(row.pixels, closeTo(Procession.speed * 2, 4));
      }
      await tester.pumpWidget(const SizedBox());
    }
  });

  group('the blocks that are not cards', () {
    testWidgets('a countdown: the days, today, and after it what the '
        'section says, or nothing', (tester) async {
      final DateTime now = DateTime(2026, 10, 19, 10);
      expect(CountdownBlock.daysTo('2026-10-22', now), 3);
      expect(CountdownBlock.daysTo('2026-10-19', now), 0);
      expect(CountdownBlock.daysTo('2026-10-18', now), -1);
      expect(CountdownBlock.daysTo('2026-02-30', now), isNull);
      expect(CountdownBlock.daysTo('soon', now), isNull);

      final CoreHost host = CoreHost(await readyApp(const {}, () => now));
      ExploreSection countdown(String to, {bool after = false}) =>
          ExploreSection.fromJson({
            'id': 'count-$to',
            'block': 'countdown',
            'to': to,
            'label': {'en': 'to the eclipse', 'it': 'all\'eclissi'},
            'today': 'The eclipse is today',
            if (after) 'after': 'The eclipse has been',
          });
      await pumpSections(tester, host, [
        countdown('2026-10-22'),
        countdown('2026-10-19'),
        countdown('2026-10-01'),
        countdown('2026-10-02', after: true),
      ]);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('DAYS'), findsOneWidget);
      expect(find.text('to the eclipse'), findsOneWidget);
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('The eclipse is today'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('countdown-count-2026-10-01')),
        findsNothing,
      );
      expect(find.text('The eclipse has been'), findsOneWidget);
    });

    testWidgets('the offer: on the free plan only unless it says all, and '
        'a tap opens the plans by its door', (tester) async {
      final CoreHost free = CoreHost(await readyApp());
      await pumpSections(tester, free, [
        ExploreSection.fromJson({
          'id': 'offer',
          'block': 'promo',
          'from': 'explore promo',
        }),
      ]);
      await tester.tap(find.text('Get Astute+'));
      expect(free.plans, ['explore promo']);

      final CoreHost plus = CoreHost(await readyApp({'knowit.plus': true}));
      await pumpSections(tester, plus, [
        ExploreSection.fromJson({'id': 'offer', 'block': 'promo'}),
        ExploreSection.fromJson({
          'id': 'everyone',
          'block': 'promo',
          'plan': 'all',
          'headline': {'en': 'Thank you for reading'},
        }),
      ]);
      expect(find.byKey(const ValueKey('promo-offer')), findsNothing);
      expect(find.text('Thank you for reading'), findsOneWidget);
    });

    testWidgets('subjects narrow Explore as the chips do, the one in view '
        'lit', (tester) async {
      final CoreHost host = CoreHost(await readyApp(), subject: 'Space');
      await pumpSections(tester, host, [
        ExploreSection.fromJson({
          'id': 'subjects',
          'block': 'subjects',
          'subjects': ['space', 'history', 'thinking'],
        }),
      ]);
      expect(
        find.byKey(const ValueKey('section-subject-space-on')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('section-subject-thinking-off')),
        findsNothing,
      );
      await tester.tap(
        find.byKey(const ValueKey('section-subject-history-off')),
      );
      expect(host.subjects, ['History']);
    });

    testWidgets('words in the reader\'s language, or English, and nothing '
        'without them', (tester) async {
      final ExploreSection quote = ExploreSection.fromJson({
        'id': 'quote',
        'block': 'text',
        'kind': 'quote',
        'text': {'en': 'Look twice.', 'it': 'Guarda due volte.'},
        'by': 'A reader',
      });
      final ExploreSection headline = ExploreSection.fromJson({
        'id': 'headline',
        'block': 'text',
        'kind': 'headline',
        'text': 'Every block, every size',
      });
      final ExploreSection none = ExploreSection.fromJson({
        'id': 'none',
        'block': 'text',
      });
      final AppState app = await readyApp();
      await pumpSections(tester, CoreHost(app, language: 'it'), [
        quote,
        headline,
        none,
      ], locale: const Locale('it'));
      expect(find.text('Guarda due volte.'), findsOneWidget);
      expect(find.text('A READER'), findsOneWidget);
      expect(find.text('Every block, every size'), findsOneWidget);
      await pumpSections(tester, CoreHost(app, language: 'de'), [
        quote,
      ], locale: const Locale('de'));
      expect(find.text('Look twice.'), findsOneWidget);
    });

    testWidgets('room, a rule, and a page through the web surface once it '
        'is in the build', (tester) async {
      final CoreHost host = CoreHost(await readyApp());
      final List<ExploreSection> sections = [
        ExploreSection.fromJson({
          'id': 'room',
          'block': 'spacer',
          'height': 64,
        }),
        ExploreSection.fromJson({
          'id': 'rule',
          'block': 'divider',
          'label': 'and',
        }),
        ExploreSection.fromJson({
          'id': 'page',
          'block': 'web',
          'html': {'en': '<p>Hi</p>'},
          'height': 180,
        }),
      ];
      await pumpSections(tester, host, sections);
      expect(find.text('AND'), findsOneWidget);
      expect(find.byKey(const ValueKey('web-page')), findsNothing);

      final List<(String, double)> drawn = [];
      WebBlock.webSection = (context, {required html, required height}) {
        drawn.add((html, height));
        return const ColoredBox(color: Colors.blue);
      };
      addTearDown(() => WebBlock.webSection = null);
      await pumpSections(tester, host, sections);
      expect(find.byKey(const ValueKey('web-page')), findsOneWidget);
      expect(
        tester.getSize(find.byKey(const ValueKey('web-page'))).height,
        180,
      );
      expect(drawn.last, ('<p>Hi</p>', 180.0));
    });
  });

  testWidgets('the build\'s own shelves draw for any host, a test\'s too', (
    tester,
  ) async {
    final CoreHost host = CoreHost(await readyApp());
    await pumpSections(
      tester,
      host,
      sectionsOf([
        {'id': 'today', 'block': 'today', 'gap': 0},
        {'id': 'top', 'block': 'top'},
        {'id': 'asking', 'block': 'asking'},
        {'id': 'month', 'block': 'month'},
        {'id': 'sixty', 'block': 'sixty'},
      ]),
      size: const Size(402, 3000),
    );
    expect(tester.takeException(), isNull);
    expect(find.text("Today's shelf"), findsOneWidget);
    expect(find.byKey(const ValueKey('top-empty')), findsOneWidget);
    expect(find.byKey(const ValueKey('shelf-asking')), findsOneWidget);
    expect(find.byKey(const ValueKey('mix-month')), findsOneWidget);
    expect(find.byKey(const ValueKey('mix-sixty')), findsOneWidget);
    expect(host.shown, isNotEmpty);
    expect(math.max(1, host.shown.length), greaterThan(0));
  });
}
