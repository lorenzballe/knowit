// Explore's cover (lib/explore/blocks/core/cover_block.dart): the day's
// cards in a mosaic at the top of the page, two large and four small; the
// large one on the left and then on the right; a subject to a card; every
// card in words, the long questions in the large tiles, none cut; a tap
// opening the card among the cover's; and the cover coming up once, when it
// is seen, not while it waits beside the tab on screen.
//
//   flutter test test/explore/cover_test.dart
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/explore/blocks/core/cover_block.dart';
import 'package:astuto/explore/blocks/core/own_explore.dart';
import 'package:astuto/explore/explore_block.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/sync/served.dart';
import 'package:astuto/widgets/explore/explore_engine.dart';
import 'package:astuto/widgets/explore/card_tiles.dart';
import 'package:astuto/widgets/scaled_text.dart';
import 'package:astuto/widgets/web/card_thumb.dart';

import '../web/thumbs_harness.dart';
import 'core_harness.dart';

const Map<String, Object?> _cover = {
  'id': 'cover',
  'block': 'cover',
  'gap': 6,
  'source': {
    'query': {'unread': true, 'perSubject': 1, 'limit': 40},
  },
};

/// The cover's tiles on screen, by card id, each with where it is drawn.
Map<String, Rect> _tiles(WidgetTester tester) => {
  for (final Element e
      in find
          .byWidgetPredicate(
            (w) =>
                w.key is ValueKey<String> &&
                (w.key! as ValueKey<String>).value.startsWith('cover-'),
          )
          .evaluate())
    (e.widget.key! as ValueKey<String>).value.substring('cover-'.length): tester
        .getRect(find.byWidget(e.widget)),
};

void main() {
  setUpAll(loadFonts);
  setUp(() {
    Served.useForTest(Served());
    CoverMosaic.cameUp = false;
  });
  tearDown(() {
    PillBank.reset();
    CardThumb.image = (url) => onePixel;
  });

  testWidgets('today\'s three opens the build\'s own Explore, the cover '
      'under it', (tester) async {
    expect(kOwnExplore.skip(2).first.id, 'three');
    expect(kOwnExplore.skip(3).first.id, 'cover');
    expect(kOwnExplore.skip(3).first.json['gap'], 6);
  });

  testWidgets('two groups of three: the large card on the left, then on the '
      'right, two small ones beside each, a subject to a card, none cut', (
    tester,
  ) async {
    final CoreHost host = CoreHost(await readyApp());
    await pumpSections(
      tester,
      host,
      sectionsOf([_cover]),
      size: const Size(402, 874),
    );
    await tester.pumpAndSettle();
    final Map<String, Rect> tiles = _tiles(tester);
    expect(tiles, hasLength(6));
    final List<Pill> cards = [for (final id in tiles.keys) PillBank.byId(id)!];
    expect({for (final p in cards) p.topic}, hasLength(6));

    // By size: two large, four small.
    final List<MapEntry<String, Rect>> bySize = tiles.entries.toList()
      ..sort((a, b) => b.value.width.compareTo(a.value.width));
    final Rect first = bySize[0].value.top < bySize[1].value.top
        ? bySize[0].value
        : bySize[1].value;
    final Rect second = first == bySize[0].value
        ? bySize[1].value
        : bySize[0].value;
    expect(first.width, greaterThan(bySize[2].value.width * 1.4));
    // The first large card on the left, the second on the right.
    expect(first.left, lessThan(second.left));
    expect(second.right, closeTo(402 - 20, 0.5));
    expect(first.left, closeTo(20, 0.5));
    // As tall as a card on the day's shelf of its width.
    expect(first.width / first.height, closeTo(WebThumbs.shelfAspect, 0.01));

    // Not one question cut: none of them scrolls inside its tile.
    for (final Element e in find.byType(ScaledText).evaluate()) {
      final Finder scroll = find.descendant(
        of: find.byElementPredicate((x) => x == e),
        matching: find.byType(Scrollable),
      );
      expect(
        tester.state<ScrollableState>(scroll.first).position.maxScrollExtent,
        lessThanOrEqualTo(0.5),
        reason: (e.widget as ScaledText).text,
      );
    }

    // A tap opens the card, as the cover's.
    final String small = bySize[3].key;
    await tester.tap(find.byKey(ValueKey('cover-$small')));
    expect(host.opened.last, ('cover', small));
  });

  testWidgets('every card in words, one with a picture too; the longest '
      'question set large, the short ones small', (tester) async {
    // Every card of the bank with a picture of its front.
    PillBank.adopt(bankWithPictures({for (final p in pagedCards()) p.id}));
    CardThumb.image = (url) => onePixel;
    final CoreHost host = CoreHost(await readyApp());
    // Six short questions of six subjects, then the longest of a seventh,
    // last.
    final List<Pill> byLength = [...PillBank.cards]
      ..sort((a, b) => a.question.length - b.question.length);
    final List<Pill> shorts = [];
    for (final Pill p in byLength) {
      if (shorts.length == 6) break;
      if (p.question.length > 40 && !shorts.any((s) => s.topic == p.topic)) {
        shorts.add(p);
      }
    }
    final Pill long = byLength.reversed.firstWhere(
      (p) => p.question.length < 220 && !shorts.any((s) => s.topic == p.topic),
    );
    host.cards['cover'] = [...shorts, long];
    await pumpSections(
      tester,
      host,
      sectionsOf([_cover]),
      size: const Size(402, 874),
    );
    await tester.pumpAndSettle();
    final Map<String, Rect> tiles = _tiles(tester);
    expect(tiles, hasLength(6));
    expect(find.byType(CardThumb), findsNothing);
    expect(find.byType(BoxTile), findsNWidgets(6));
    final double widest = tiles.values.map((r) => r.width).reduce(math.max);
    expect(tiles[long.id]?.width, widest);
  });

  testWidgets('it comes up once, when it is seen: not while it waits on the '
      'next page', (tester) async {
    final CoreHost host = CoreHost(await readyApp());
    final PageController pages = PageController();
    addTearDown(pages.dispose);
    tester.view.physicalSize = const Size(402, 874) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final List<ExploreSection> sections = sectionsOf([_cover]);
    // As the app's tabs: the cover on the second page, built beside the
    // first; and the tabs standing still on the first (a card on the table),
    // which gives them another scroll once they move again.
    Widget tabs({required bool still}) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: PageView(
          controller: pages,
          physics: still ? const NeverScrollableScrollPhysics() : null,
          allowImplicitScrolling: true,
          children: [
            const SizedBox.expand(),
            Builder(
              builder: (context) => CustomScrollView(
                slivers: [
                  ExploreSliver(
                    host: host,
                    slots: exploreSlots(
                      context,
                      host,
                      sections,
                      host.app.remoteContext(host.language),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    await tester.pumpWidget(tabs(still: true));
    await tester.pump(const Duration(seconds: 2));
    // Built beside the page on screen, and still waiting.
    expect(CoverMosaic.cameUp, isFalse);
    final Finder tile = find.byWidgetPredicate(
      (w) =>
          w.key is ValueKey<String> &&
          (w.key! as ValueKey<String>).value.startsWith('cover-') &&
          !(w.key! as ValueKey<String>).value.startsWith('cover-picture-'),
      skipOffstage: false,
    );
    expect(tile, findsNWidgets(6));
    double shown() => tester
        .widgetList<Opacity>(
          find.ancestor(
            of: tile.first,
            matching: find.byType(Opacity, skipOffstage: false),
          ),
        )
        .fold(1.0, (a, o) => a * o.opacity);
    expect(shown(), 0);

    // Gone to, it comes up.
    await tester.pumpWidget(tabs(still: false));
    pages.jumpToPage(1);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    expect(CoverMosaic.cameUp, isTrue);
    await tester.pump(CoverMosaic.rise);
    expect(shown(), 1);
  });

  testWidgets('for a reader who asked for less motion it is simply there', (
    tester,
  ) async {
    final CoreHost host = CoreHost(await readyApp());
    await pumpSections(
      tester,
      host,
      sectionsOf([_cover]),
      size: const Size(402, 874),
      calm: true,
    );
    await tester.pump();
    expect(CoverMosaic.cameUp, isTrue);
    expect(_tiles(tester), hasLength(6));
    for (final String id in _tiles(tester).keys) {
      expect(
        find.ancestor(
          of: find.byKey(ValueKey('cover-$id')),
          matching: find.byType(Opacity),
        ),
        findsNothing,
      );
    }
  });
}
