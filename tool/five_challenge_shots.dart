// Photographs "Challenge a friend" on today's five where it sits in the app
// (lib/explore/blocks/bets/five_challenge.dart), for the owner, with the
// server's switch on (share.challenge): at the end of the five on Explore,
// in place of the score as squares; and under the finished day's share, as
// it ships (A). In Italian, at night, on a 390 by 844 phone, and the end of
// the five again in German at twice the text size on the smallest phone,
// where long words would show it if they were cut.
//
//   SHOTS=/some/folder flutter test tool/five_challenge_shots.dart --update-goldens
//
// A camera, not a check: it lives outside test/ so CI never runs it. The
// cards' pictures are read from web/cards, as the site serves them.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/data/pills_repository.dart' show dateKey;
import 'package:astuto/debug_flags.dart';
import 'package:astuto/explore/blocks/bets/answers.dart' show plainResponse;
import 'package:astuto/explore/blocks/bets/bets_day.dart';
import 'package:astuto/explore/blocks/bets/daily_deal.dart';
import 'package:astuto/explore/blocks/bets/deal.dart' show answerOf;
import 'package:astuto/explore/blocks/bets/three.dart';
import 'package:astuto/explore/explore_block.dart';
import 'package:astuto/main.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/remote/remote.dart';
import 'package:astuto/state/app_state.dart';
import 'package:astuto/state/debug_looks.dart';
import 'package:astuto/sync/daily_crowd.dart';
import 'package:astuto/widgets/web/card_thumb.dart';

import '../test/explore/bets_host.dart';

/// The server's switch, on.
void _challengesOn() => Remote.adopt(
  RemoteConfig.parse(
    jsonEncode({
      'schema': 1,
      'hash': 'five-challenge-shots',
      'app': {
        'flags': {'share.challenge': true},
      },
      'strings': <String, Object?>{},
      'explore': null,
      'looks': null,
    }),
  ),
);

/// A card's picture, from the site's own folder rather than the network.
ImageProvider _local(Uri url) {
  final String path = url.path.startsWith('/cards/')
      ? url.path.substring('/cards/'.length)
      : url.path;
  final File file = File('web/cards/$path');
  return MemoryImage(file.existsSync() ? file.readAsBytesSync() : Uint8List(0));
}

Future<void> _settle(WidgetTester tester, [int frames = 14]) async {
  for (int f = 0; f < frames; f++) {
    await tester.pump(const Duration(milliseconds: 90));
  }
}

/// Waits for the pictures on screen to come, as a phone would.
Future<void> _pictures(WidgetTester tester) async {
  for (int round = 0; round < 3; round++) {
    await tester.runAsync(() async {
      for (final Element e in find.byType(Image).evaluate().toList()) {
        final Image image = e.widget as Image;
        try {
          await precacheImage(image.image, e, onError: (_, _) {});
        } catch (_) {}
      }
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await _settle(tester, 6);
  }
}

/// Holds the phone: its size in points, its status and home bars.
void _phone(WidgetTester tester, Size size, {double top = 47, double bottom = 34}) {
  const double ratio = 3;
  tester.view.physicalSize = size * ratio;
  tester.view.devicePixelRatio = ratio;
  final FakeViewPadding padding = FakeViewPadding(
    top: top * ratio,
    bottom: bottom * ratio,
  );
  tester.view.padding = padding;
  tester.view.viewPadding = padding;
  addTearDown(tester.view.reset);
}

/// Today's five played as a reader might, four of them right: each locked
/// in as the game locks it (three.dart), and the game at its result.
void _playedFive(DateTime now) {
  final List<Pill> five = DailyDeal.five(now);
  for (final (int i, Pill p) in five.indexed) {
    final bool aim = i != 2;
    final String said = switch (p.challenge) {
      PickOne(:final correct, :final options) =>
        '${aim ? correct : (correct + 1) % options.length}',
      _ => plainResponse(
        ((answerOf(p)?.value ?? 50) + (aim ? 0 : 30))
            .roundToDouble()
            .clamp(0, 100)
            .toDouble(),
      ),
    };
    BetsDay.instance.place(
      Bet(
        kind: kDailyBet,
        section: 'three',
        pill: p.id,
        said: said,
        right: p.challenge.accepts(said),
        facts: {
          'pts': dailyPoints(p, said),
          'step': i + 1,
          'of': five.length,
          'game': 'five',
        },
      ),
    );
  }
  BetsDay.instance.keepDraft('daily:five:at', five.length);
}

/// A reader on the fourth day running, today's five read, on the free plan,
/// nothing asked of them over the shelf, the day sent as it ships (A).
Map<String, Object> _finished() {
  final DateTime now = DateTime.now();
  String back(int days) =>
      dateKey(DateTime(now.year, now.month, now.day - days));
  Pill of(String topic, [int skip = 0]) => PillBank.cards
      .where((p) => p.topic == topic && p.web?.thumbs != null)
      .elementAt(skip);
  final List<String> deck = [
    for (final Pill p in [
      of('Human body'),
      of('Space', 3),
      of('Psychology', 2),
      of('Economics', 1),
      of('History', 4),
    ])
      p.id,
  ];
  return {
    'knowit.onboarded': true,
    'knowit.plus': false,
    'knowit.pushAsked': true,
    'knowit.widgetAsked': true,
    'knowit.accountOffered': true,
    'knowit.reviewAsked': true,
    'knowit.goalAsked': true,
    'knowit.placeAsks': 9,
    'knowit.todayDate': back(0),
    'knowit.todayDeckIds': deck,
    'knowit.todayIndex': deck.length,
    'knowit.streak': 4,
    'knowit.bestStreak': 4,
    'knowit.lastCompletionDate': back(0),
    'knowit.completedDates': [for (int d = 3; d >= 0; d--) back(d)],
    'knowit.seenIds': [...PillBank.cards.take(40).map((p) => p.id), ...deck],
    'knowit.debug.shareDay': ShareDayPick.a.name,
  };
}

void main() {
  setUpAll(() async {
    await loadBetsFonts();
    CardThumb.image = _local;
  });
  setUp(() {
    DailyCrowd.useForTest(null);
    _challengesOn();
  });
  tearDown(() {
    DailyCrowd.useForTest(null, on: false);
    Remote.reset();
  });

  final String out = Platform.environment['SHOTS'] ?? 'tool/shots/challenge';

  for (final (String lang, Size size, double text) in const [
    ('it', Size(390, 844), 1.0),
    ('de', Size(320, 640), 2.0),
  ]) {
    testWidgets('the end of the five on Explore, $lang', (tester) async {
      _phone(tester, size);
      final DateTime now = DateTime.now();
      SharedPreferences.setMockInitialValues({'knowit.onboarded': true});
      // ignore: invalid_use_of_visible_for_testing_member
      BetsDay.resetForTest(clock: () => now);
      // ignore: invalid_use_of_visible_for_testing_member
      ThreeDays.resetForTest();
      final AppState app = AppState(clock: () => now);
      await tester.runAsync(app.init);
      await tester.runAsync(BetsDay.instance.load);
      await tester.runAsync(ThreeDays.instance.load);
      _playedFive(now);
      final BetsTestHost host = BetsTestHost(app, language: lang);
      await tester.pumpWidget(
        betsApp(
          Scaffold(
            body: SafeArea(
              child: BetsPage(
                host: host,
                sections: [
                  ExploreSection.fromJson(const {'id': 'three', 'block': 'three'}),
                ],
              ),
            ),
          ),
          locale: Locale(lang),
          phone: size,
          text: text,
        ),
      );
      await _settle(tester);
      // Down to the end of the result, where it is sent from: its two
      // buttons at the foot of the screen, the questions over them.
      Scrollable.ensureVisible(
        tester.element(find.byKey(const ValueKey('three-why'))),
        alignment: 0.9,
      );
      await _settle(tester);
      expect(find.byKey(const ValueKey('three-challenge')), findsOneWidget);
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('$out/five-end-$lang.png'),
      );
    });
  }

  testWidgets('the finished day\'s share, it', (tester) async {
    _phone(tester, const Size(390, 844));
    const Locale locale = Locale('it');
    tester.platformDispatcher.localeTestValue = locale;
    tester.platformDispatcher.localesTestValue = [locale];
    addTearDown(tester.platformDispatcher.clearLocaleTestValue);
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    final bool tools = debugToolsOn;
    debugToolsOn = true;
    addTearDown(() {
      debugToolsOn = tools;
      // ignore: invalid_use_of_visible_for_testing_member
      DebugLooks.reset();
    });
    // ignore: invalid_use_of_visible_for_testing_member
    BetsDay.resetForTest();
    SharedPreferences.setMockInitialValues(_finished());
    await tester.pumpWidget(const AstutoApp());
    await _settle(tester);
    await _pictures(tester);
    await tester.tap(find.byKey(const ValueKey('shelf-share-day')));
    await _settle(tester);
    await _pictures(tester);
    await _settle(tester, 6);
    expect(find.byKey(const ValueKey('share-day-challenge')), findsOneWidget);
    expect(tester.takeException(), isNull);
    await expectLater(
      find.byType(AstutoApp),
      matchesGoldenFile('$out/day-share-it.png'),
    );
  });
}
