// The feed at the end of Explore: the whole bank in the day's order, the
// same for every reader, laid band after band for as long as the reader
// scrolls, never the same card twice and never one read already, a tap
// opening a card among the cards laid so far; anywhere but last, its first
// round of bands; and not one question cut, at a large text size too.
//
//   flutter test test/explore/feed_test.dart
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
    final int round = kFeedBands.fold(0, (n, band) => n + band.length);
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

  test('the build\'s own Explore ends on the feed', () {
    expect(kOwnExploreJson.last['block'], 'feed');
  });
}
