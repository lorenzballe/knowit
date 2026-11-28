// Explore's endless flow, ended for the day on the free plan, behind the
// server's number `explore.freeCards` (lib/explore/blocks/core/feed_cap.dart):
// nought as built, and then no end; with a number, once the cards read
// beyond the day's five reach it, the flow lays no more bands and a calm
// card names Astute+ where the next one would have been. Soft: what is on
// the page stays, and Astute+ has no end.
//
//   flutter test test/explore/feed_cap_test.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/explore/blocks/core/feed_cap.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/remote/remote.dart';
import 'package:astuto/state/app_state.dart';
import 'package:astuto/sync/served.dart';
import 'package:astuto/widgets/explore/card_tiles.dart';

import 'core_harness.dart';

final AppLocalizations _en = lookupAppLocalizations(const Locale('en'));

const Map<String, Object?> _feed = {
  'id': 'feed',
  'block': 'feed',
  'title': 'Keep exploring',
  'subtitle': 'The same for everyone.',
};

int _docs = 0;

/// The server's number for the end, or nothing said of it.
void _cap(int? cards) => Remote.adopt(
  RemoteConfig.parse(
    jsonEncode({
      'schema': 1,
      'hash': 'feed-cap-${_docs++}',
      'app': {
        'tunables': {'explore.freeCards': ?cards},
      },
      'strings': <String, Object?>{},
      'explore': null,
      'looks': null,
    }),
  ),
);

/// Reads [n] cards on Explore, none of them today's five.
Future<void> _read(AppState app, int n) async {
  final Set<String> five = {for (final Pill p in app.todaysDeck) p.id};
  final Iterable<Pill> others = PillBank.cards.where(
    (p) => !five.contains(p.id) && !app.seenIds.contains(p.id),
  );
  for (final Pill p in others.take(n)) {
    await app.markReadElsewhere(p.id);
  }
}

Future<void> _scrollFar(WidgetTester tester) async {
  final ScrollPosition list = tester
      .state<ScrollableState>(find.byType(Scrollable).first)
      .position;
  for (int i = 0; i < 12; i++) {
    list.jumpTo(list.pixels + 600);
    await tester.pump();
  }
}

void main() {
  setUpAll(loadFonts);
  setUp(() {
    Served.useForTest(Served());
    Remote.reset();
  });
  tearDown(Remote.reset);

  test('nought as built, a number the server can set', () async {
    expect(AppState.kExploreFreeCardsKnob.fallback, 0);
    final AppState app = await readyApp({'knowit.plus': false});
    await _read(app, 40);
    expect(app.readBeyondFiveToday, 40);
    expect(app.exploreCapped, isFalse);
    _cap(30);
    expect(app.exploreCapped, isTrue);
    _cap(41);
    expect(app.exploreCapped, isFalse);
    // Today's five are not counted: they are the day's.
    await app.markReadElsewhere(app.todaysDeck.first.id);
    expect(app.readBeyondFiveToday, 40);
    // Never on Astute+, whose Explore has no end.
    _cap(30);
    await app.applyEntitlement(true);
    expect(app.exploreCapped, isFalse);
  });

  testWidgets('no number, no end: the flow goes on', (tester) async {
    final AppState app = await readyApp({'knowit.plus': false});
    await _read(app, 30);
    await pumpSections(tester, CoreHost(app), sectionsOf([_feed]));
    await _scrollFar(tester);
    expect(find.byType(FeedCapCard), findsNothing);
    expect(find.byType(BoxTile), findsWidgets);
  });

  testWidgets('the day\'s number reached: the flow ends on the card, and '
      'goes no further', (tester) async {
    _cap(20);
    final AppState app = await readyApp({'knowit.plus': false});
    await _read(app, 20);
    await pumpSections(tester, CoreHost(app), sectionsOf([_feed]));
    expect(find.text('Keep exploring'), findsOneWidget);
    expect(find.byType(FeedCapCard), findsOneWidget);
    expect(find.text(_en.exploreCapTitle), findsOneWidget);
    expect(find.text(_en.exploreCapLine(20)), findsOneWidget);
    expect(find.text(_en.exploreCapPlus), findsOneWidget);
    await _scrollFar(tester);
    expect(find.byType(BoxTile), findsNothing);
  });

  testWidgets('reached while reading: what is on the page stays, and the '
      'card follows it', (tester) async {
    _cap(20);
    final AppState app = await readyApp({'knowit.plus': false});
    await _read(app, 19);
    final CoreHost host = CoreHost(app);
    await pumpSections(tester, host, sectionsOf([_feed]));
    final int before = find.byType(BoxTile).evaluate().length;
    expect(before, greaterThan(0));
    expect(find.byType(FeedCapCard), findsNothing);

    await _read(app, 1);
    await pumpSections(tester, host, sectionsOf([_feed]));
    // The bands already laid are still there, the card after them, and
    // nothing after the card.
    expect(find.byType(BoxTile).evaluate().length, before);
    await tester.scrollUntilVisible(
      find.byType(FeedCapCard),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.byType(FeedCapCard), findsOneWidget);
    final double card = tester.getRect(find.byType(FeedCapCard)).top;
    for (final Element tile in find.byType(BoxTile).evaluate()) {
      final RenderBox box = tile.renderObject! as RenderBox;
      expect(box.localToGlobal(Offset.zero).dy, lessThan(card));
    }
  });

  testWidgets('on Astute+ there is no end', (tester) async {
    _cap(5);
    final AppState app = await readyApp({'knowit.plus': true});
    await _read(app, 10);
    await pumpSections(tester, CoreHost(app), sectionsOf([_feed]));
    await _scrollFar(tester);
    expect(find.byType(FeedCapCard), findsNothing);
    expect(find.byType(BoxTile), findsWidgets);
  });

  testWidgets('the card holds in German on the small phone', (tester) async {
    _cap(20);
    final AppState app = await readyApp({'knowit.plus': false});
    await _read(app, 20);
    await pumpSections(
      tester,
      CoreHost(app, language: 'de'),
      sectionsOf([_feed]),
      size: const Size(320, 568),
      locale: const Locale('de'),
      text: 1.3,
    );
    expect(tester.takeException(), isNull);
    expect(find.byType(FeedCapCard), findsOneWidget);
  });
}
