// The feed at the end of Explore: the whole bank in the day's order, the
// same for every reader, laid band after band for as long as the reader
// scrolls, never the same card twice and never one read already, a tap
// opening a card among the cards laid so far; anywhere but last, its first
// round of bands; not one question cut, at a large text size too; and every
// card as tall as its question, the columns of a band level, none left half
// empty under a question that ends halfway down it.
//
//   flutter test test/explore/feed_test.dart
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:astuto/explore/blocks/core/feed_block.dart';
import 'package:astuto/explore/blocks/core/own_explore.dart';
import 'package:astuto/explore/explore_block.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/sync/served.dart';
import 'package:astuto/widgets/explore/card_tiles.dart';
import 'package:astuto/widgets/scaled_text.dart';

import 'core_harness.dart';

/// A host for which [read] are read already.
class _ReaderHost extends CoreHost {
  _ReaderHost(super.app, {this.read = const {}});

  final Set<String> read;

  @override
  bool isRead(Pill pill) => read.contains(pill.id);
}

const Map<String, Object?> _feed = {
  'id': 'feed',
  'block': 'feed',
  'title': 'Keep exploring',
  'subtitle': 'The same for everyone.',
};

/// The cards the feed lays for [host] in its first [bands] bands, on a
/// 375-point phone, at the text size of the screen [tester] shows.
List<Pill> _laid(WidgetTester tester, ExploreHost host, int bands) {
  final BuildContext context = tester.element(find.byType(Scaffold));
  final FeedDeal deal = feedDeal(host, ExploreSection.fromJson(_feed));
  final FeedGrid grid = FeedGrid(375 - 40);
  for (int i = 0; i < bands; i++) {
    if (deal.band(context, i, grid, isRead: host.isRead) == null) break;
  }
  return deal.laid;
}

/// The ids of the cards on screen, the feed's and the others'.
Set<String> _onScreen(WidgetTester tester) => {
  for (final Element e
      in find
          .byWidgetPredicate(
            (w) =>
                w.key is ValueKey<String> &&
                (w.key! as ValueKey<String>).value.startsWith('explore-'),
          )
          .evaluate())
    (e.widget.key! as ValueKey<String>).value.substring('explore-'.length),
};

void main() {
  setUpAll(loadFonts);
  setUp(() => Served.useForTest(Served()));

  testWidgets('the whole bank in the day\'s order: never the same card twice, '
      'never one read already, the same for every reader', (tester) async {
    final CoreHost one = CoreHost(await readyApp());
    await pumpSections(tester, one, const []);
    final List<Pill> laid = _laid(tester, one, 120);
    expect(laid.length, greaterThan(200));
    expect({for (final p in laid) p.id}, hasLength(laid.length));

    // Another reader, the same day: the same cards, in the same order.
    final List<Pill> again = _laid(tester, CoreHost(await readyApp()), 120);
    expect([for (final p in again) p.id], [for (final p in laid) p.id]);

    // One who has read some of the first ones meets the same cards less the
    // ones they read (within a band, the smaller boxes choose first, so a
    // band's worth at the edge may differ).
    final List<String> first = [for (final p in laid.take(40)) p.id];
    final Set<String> read = {
      for (int i = 0; i < first.length; i += 3) first[i],
    };
    final _ReaderHost other = _ReaderHost(await readyApp(), read: read);
    final List<Pill> theirs = _laid(tester, other, 120);
    expect(theirs.where((p) => read.contains(p.id)), isEmpty);
    final Set<String> mine = {
      for (final p in laid.where((p) => !read.contains(p.id)).take(100)) p.id,
    };
    final Set<String> them = {for (final p in theirs.take(100)) p.id};
    expect(mine.difference(them).length, lessThanOrEqualTo(3));
  });

  testWidgets('standing last, it goes on as far as the reader scrolls, and '
      'a tap opens a card among the ones laid so far', (tester) async {
    final CoreHost host = CoreHost(await readyApp());
    await pumpSections(tester, host, sectionsOf([_feed]));
    expect(find.text('Keep exploring'), findsOneWidget);
    expect(find.text('The same for everyone.'), findsOneWidget);
    final Set<String> met = {..._onScreen(tester)};
    expect(met, isNotEmpty);
    final ScrollPosition list = tester
        .state<ScrollableState>(find.byType(Scrollable).first)
        .position;
    for (int i = 0; i < 40; i++) {
      list.jumpTo(list.pixels + 600);
      await tester.pump();
      met.addAll(_onScreen(tester));
    }
    // Forty screens down, the feed is still going.
    expect(list.pixels, greaterThan(40 * 600 - 1));
    expect(find.byType(BoxTile), findsWidgets);
    expect(met.length, greaterThan(100));

    await tester.tap(find.byType(BoxTile).hitTestable().first);
    expect(host.opened, hasLength(1));
    expect(host.opened.single.$1, 'feed');
  });

  testWidgets('anywhere but last, its first round of bands, and the page '
      'goes on under it', (tester) async {
    final CoreHost host = CoreHost(await readyApp());
    await pumpSections(
      tester,
      host,
      sectionsOf([
        _feed,
        {
          'id': 'after',
          'block': 'carousel',
          'title': 'After the feed',
          'source': {
            'query': {
              'subjects': ['space'],
            },
          },
        },
      ]),
    );
    await tester.scrollUntilVisible(
      find.text('After the feed'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('After the feed'), findsOneWidget);
    // A round of bands holds four cards a band at the most.
    final int round = kFeedRound * 4;
    final Set<String> feedCards = {
      for (final (section, id) in host.shown)
        if (section == 'feed') id,
    };
    expect(feedCards.length, lessThanOrEqualTo(round));
  });

  for (final double text in [1.0, 2.0]) {
    testWidgets('at ${text}x, 375 wide: not one question cut', (tester) async {
      final CoreHost host = CoreHost(await readyApp());
      await pumpSections(tester, host, sectionsOf([_feed]), text: text);
      final ScrollPosition list = tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position;
      for (int i = 0; i < 6; i++) {
        for (final Element e in find.byType(ScaledText).evaluate()) {
          final Finder scroll = find.descendant(
            of: find.byElementPredicate((x) => x == e),
            matching: find.byType(Scrollable),
          );
          expect(
            tester
                .state<ScrollableState>(scroll.first)
                .position
                .maxScrollExtent,
            lessThanOrEqualTo(0.5),
            reason: (e.widget as ScaledText).text,
          );
        }
        list.jumpTo(list.pixels + 500);
        await tester.pump();
      }
    });
  }

  for (final double text in [1.0, 1.35]) {
    testWidgets('at ${text}x, every card as tall as its question: the columns '
        'of a band level, the tall box and the large one holding the longest '
        'question, two and two out of step by a clear step, none left half '
        'empty', (tester) async {
      for (final String? subject in [null, 'Science', 'History', 'Space']) {
        final CoreHost host = CoreHost(await readyApp(), subject: subject);
        await pumpSections(tester, host, const [], text: text);
        final BuildContext context = tester.element(find.byType(Scaffold));
        final FeedDeal deal = feedDeal(host, ExploreSection.fromJson(_feed));
        final FeedGrid grid = FeedGrid(375 - 40);
        int bands = 0, clean = 0;
        for (int i = 0; i < 40; i++) {
          final FeedLaid? band = deal.band(
            context,
            i,
            grid,
            isRead: host.isRead,
          );
          if (band == null) break;
          bands++;
          if (band.clean) clean++;
          final String where = '${subject ?? 'all'}, band $i';
          for (final List<int> column in FeedGrid.columnsOf(band.shape)) {
            expect(
              band.boxes[column.last].bottom,
              closeTo(band.height, 0.01),
              reason: '$where: its columns level',
            );
          }
          for (int b = 0; b < band.cards.length; b++) {
            final Pill pill = band.cards[b];
            final Rect box = band.boxes[b];
            final double need = feedNeed(
              context,
              pill,
              box.width,
              band.looks[b],
            );
            final double least = feedLeast(
              context,
              pill,
              box.width,
              band.looks[b],
            );
            expect(
              box.height,
              greaterThanOrEqualTo(need - 0.01),
              reason: '$where: ${pill.question}',
            );
            if (band.clean) {
              expect(
                box.height - math.max(need, least),
                lessThanOrEqualTo(feedSpare(box.height) + 0.01),
                reason: '$where: ${pill.question}',
              );
            }
          }
          if (band.shape.boxes == 3) {
            final int longest = band.cards.first.question.length;
            expect(
              band.cards.skip(1).every((p) => p.question.length <= longest),
              isTrue,
              reason: '$where: the longest question in the large box',
            );
          }
          if (band.shape == FeedShape.staggered && band.clean) {
            expect(
              (band.boxes[0].height - band.boxes[2].height).abs(),
              greaterThanOrEqualTo(kFeedStep - 0.01),
              reason: '$where: out of step',
            );
          }
        }
        expect(bands, greaterThan(20));
        expect(clean, greaterThanOrEqualTo(bands * 0.9));
      }
    });
  }

  testWidgets('under a cover the feed leaves out the cards the cover laid, '
      'and does not open in its shape: no mosaic of the same cards twice', (
    tester,
  ) async {
    final CoreHost host = CoreHost(await readyApp());
    await pumpSections(
      tester,
      host,
      sectionsOf([
        {
          'id': 'cover',
          'block': 'cover',
          'source': {
            'query': {'unread': true, 'perSubject': 1, 'limit': 40},
          },
        },
        _feed,
      ]),
      size: const Size(375, 2000),
    );
    final Set<String> cover = {
      for (final Element e
          in find
              .byWidgetPredicate(
                (w) =>
                    w.key is ValueKey<String> &&
                    (w.key! as ValueKey<String>).value.startsWith('cover-'),
              )
              .evaluate())
        (e.widget.key! as ValueKey<String>).value.substring('cover-'.length),
    };
    expect(cover, hasLength(6));
    expect(coverAbove(host), cover);

    final FeedDeal deal = feedDeal(host, ExploreSection.fromJson(_feed));
    final BuildContext context = tester.element(find.byType(Scaffold));
    for (int i = 0; i < 60; i++) {
      deal.band(context, i, FeedGrid(375 - 40), isRead: host.isRead);
    }
    expect(deal.laid, isNotEmpty);
    expect(deal.laid.where((p) => cover.contains(p.id)), isEmpty);
    expect(kCoverShapes, isNot(contains(deal.bands.first.shape)));

    // Without a cover, the same feed lays them where the day puts them.
    final CoreHost alone = CoreHost(await readyApp());
    await pumpSections(tester, alone, sectionsOf([_feed]));
    expect(coverAbove(alone), isEmpty);
  });

  test(
    'a feed under a cover never draws its shape first, whatever the lot',
    () {
      for (int day = 1; day <= 60; day++) {
        final String seed = '2026-11-$day|feed|';
        expect(
          kCoverShapes,
          isNot(contains(FeedPattern(seed, notFirst: kCoverShapes).shapeAt(0))),
          reason: seed,
        );
      }
      // Without one, the lot opens on them on some days.
      expect(
        [
          for (int day = 1; day <= 60; day++)
            FeedPattern('2026-11-$day|feed|').shapeAt(0),
        ].any(kCoverShapes.contains),
        isTrue,
      );
    },
  );

  test('the shapes of its bands, by lot: every shape, never one twice in a '
      'row, the large cards on either side in turn, the same lot for the '
      'same day and page and another for another', () {
    final FeedPattern a = FeedPattern('2026-11-19|feed|');
    final List<FeedShape> shapes = [for (int i = 0; i < 300; i++) a.shapeAt(i)];
    expect(shapes.toSet(), FeedShape.values.toSet());
    int lastSide = 0;
    for (int i = 0; i < shapes.length; i++) {
      if (i > 0) expect(shapes[i], isNot(shapes[i - 1]));
      if (shapes[i].side != 0) {
        expect(shapes[i].side, isNot(lastSide));
        lastSide = shapes[i].side;
      }
      if (shapes[i] == FeedShape.across) {
        for (int back = 1; back <= 3 && i - back >= 0; back++) {
          expect(shapes[i - back], isNot(FeedShape.across));
        }
      }
    }
    // The cover's shapes come often, two side by side the most.
    int count(FeedShape s) => shapes.where((x) => x == s).length;
    expect(
      count(FeedShape.coverLeft) + count(FeedShape.coverRight),
      greaterThan(60),
    );
    expect(count(FeedShape.pair), greaterThan(count(FeedShape.across)));

    final FeedPattern same = FeedPattern('2026-11-19|feed|');
    expect([for (int i = 0; i < 40; i++) same.shapeAt(i)], shapes.take(40));
    final FeedPattern tomorrow = FeedPattern('2026-11-20|feed|');
    final FeedPattern sport = FeedPattern('2026-11-19|feed|Sport');
    expect([
      for (int i = 0; i < 40; i++) tomorrow.shapeAt(i),
    ], isNot(shapes.take(40)));
    expect([
      for (int i = 0; i < 40; i++) sport.shapeAt(i),
    ], isNot(shapes.take(40)));
  });

  test('the cover\'s shapes measure as the cover does: three fifths and two '
      'fifths of the page, the two small ones sharing the large one\'s '
      'height, on the side the shape says', () {
    final FeedGrid grid = FeedGrid(362);
    final List<Rect> left = grid.rectsOf(FeedShape.coverLeft);
    expect(left[0].left, 0);
    expect(left[0].width, closeTo((362 - kFeedSpacing) * 3 / 5, 0.01));
    expect(left[1].left, closeTo(left[0].width + kFeedSpacing, 0.01));
    expect(left[1].right, closeTo(362, 0.01));
    expect(left[2].bottom, closeTo(left[0].bottom, 0.01));
    final List<Rect> right = grid.rectsOf(FeedShape.coverRight);
    expect(right[0].right, closeTo(362, 0.01));
    expect(right[1].left, 0);
    for (final FeedShape shape in FeedShape.values) {
      final List<Rect> boxes = grid.rectsOf(shape);
      expect(boxes, hasLength(shape.boxes));
      for (int i = 0; i < boxes.length; i++) {
        expect(boxes[i].left, greaterThanOrEqualTo(0));
        expect(boxes[i].right, lessThanOrEqualTo(362.01));
        for (int j = i + 1; j < boxes.length; j++) {
          expect(
            boxes[i].intersect(boxes[j]).isEmpty ||
                boxes[i].intersect(boxes[j]).width <= 0 ||
                boxes[i].intersect(boxes[j]).height <= 0,
            isTrue,
            reason: '$shape: boxes $i and $j overlap',
          );
        }
      }
    }
  });

  test('the build\'s own Explore ends on the feed', () {
    expect(kOwnExploreJson.last['block'], 'feed');
  });
}
