// Photographs the day's challenges where the phone shows them, on the
// medium phone (390 × 844): Explore for every subject opening on Today's
// five, a pick locked in, a share on its track, and the result with today's
// players' numbers, at night and by day; then a subject's page opening on
// its own Today's three.
//
//   FIVE_SHOTS=/some/dir flutter test tool/today_five_shots.dart \
//     --update-goldens
//
// A camera, not a check, so it lives outside test/ like the other shots.
// The pictures land where FIVE_SHOTS says, or in the gallery, which is not
// kept. Today's players are made up, two hundred or so of them, kept in
// memory and judged as the server judges them.
//
// ignore_for_file: invalid_use_of_visible_for_testing_member
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:astuto/analytics.dart';
import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/data/pills_repository.dart' show dateKey;
import 'package:astuto/explore/blocks/bets/bets_day.dart';
import 'package:astuto/explore/blocks/bets/daily_deal.dart';
import 'package:astuto/explore/blocks/bets/deal.dart' show answerOf;
import 'package:astuto/explore/blocks/bets/three.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/screens/explore_screen.dart';
import 'package:astuto/state/app_state.dart';
import 'package:astuto/state/explore_play.dart';
import 'package:astuto/sync/daily_crowd.dart';
import 'package:astuto/sync/served.dart';
import 'package:astuto/sync/trace.dart';
import 'package:astuto/theme.dart';
import 'package:astuto/widgets/web/card_thumb.dart';

import '../test/explore/core_harness.dart';
import '../test/web/thumbs_harness.dart' show onePixel;

final DateTime _now = DateTime(2026, 11, 26, 9, 30);
DateTime _clock() => _now;

final String _out =
    Platform.environment['FIVE_SHOTS'] ?? 'shots/gallery/today-five';

/// How the server judges an answer (functions/src/daily.ts).
({bool right, int points, int? pick, double? guess}) _judge(
  String id,
  String said,
) {
  final Pill p = PillBank.byId(id)!;
  final bool pick = p.challenge is PickOne;
  return (
    right: p.challenge.accepts(said),
    points: dailyPoints(p, said),
    pick: pick ? int.parse(said) : null,
    guess: pick ? null : double.parse(said),
  );
}

/// Today's players before the reader: by score, about three hundred the
/// middle, and on each card a share right, or guesses a little high.
DailyCounts _crowd(List<Pill> cards, int max) {
  final int top = max ~/ 10;
  final List<int> scores = [
    for (int b = 0; b <= top; b++)
      (11 * math.exp(-math.pow((b - top * 0.58) / (top * 0.17), 2) / 2))
          .round(),
  ];
  final int players = scores.fold(0, (a, b) => a + b);
  final Map<String, DailyItemCounts> items = {};
  for (final (int i, Pill p) in cards.indexed) {
    final double share = [0.71, 0.38, 0.56, 0.83, 0.47][i % 5];
    final int right = (players * share).round();
    switch (p.challenge) {
      case PickOne(:final correct, :final options):
        final List<int> picks = List.filled(options.length, 0);
        picks[correct] = right;
        int left = players - right;
        for (int o = 0; o < options.length; o++) {
          if (o == correct) continue;
          final int some = o == options.length - 1 || left == 0
              ? left
              : (left * 0.6).round();
          picks[o] += some;
          left -= some;
        }
        items[p.id] = DailyItemCounts(n: players, right: right, picks: picks);
      default:
        final double truth = answerOf(p)?.value ?? 50;
        final double mean = (truth + 9).clamp(0, 100).toDouble();
        final List<int> guesses = List.filled(11, 0);
        guesses[(mean / 10).floor().clamp(0, 10)] = players;
        items[p.id] = DailyItemCounts(
          n: players,
          right: (players * 0.12).round(),
          guesses: guesses,
          sum: mean * players,
        );
    }
  }
  return DailyCounts(players: players, scores: scores, items: items);
}

void main() {
  setUpAll(loadFonts);

  Future<void> settle(WidgetTester tester) async {
    for (int f = 0; f < 14; f++) {
      await tester.pump(const Duration(milliseconds: 90));
    }
  }

  Future<void> shoot(WidgetTester tester, String name) => expectLater(
    find.byType(Scaffold).first,
    matchesGoldenFile('$_out/$name.png'),
  );

  /// Taps [key] once it is in the middle of the screen: at the top, the
  /// subjects' row stays over the page and would take the tap.
  Future<void> tapKey(WidgetTester tester, String key) async {
    final Finder f = find.byKey(ValueKey(key));
    await Scrollable.ensureVisible(tester.element(f), alignment: 0.5);
    await settle(tester);
    await tester.tap(f);
    await settle(tester);
  }

  /// Scrolls Explore so [key] starts just under the subjects' row.
  Future<void> bringUp(WidgetTester tester, String key) async {
    final BuildContext at = tester.element(find.byKey(ValueKey(key)));
    final ScrollPosition p = Scrollable.of(at).position;
    await Scrollable.ensureVisible(at);
    p.jumpTo((p.pixels - 72).clamp(p.minScrollExtent, p.maxScrollExtent));
    await settle(tester);
  }

  /// The card in front of the reader: the one whose answer is to be locked in.
  String onScreen(WidgetTester tester) {
    final Finder lock = find.byWidgetPredicate(
      (w) =>
          w.key is ValueKey<String> &&
          (w.key! as ValueKey<String>).value.startsWith('three-lock-'),
    );
    return (tester.widget(lock).key! as ValueKey<String>).value.substring(
      'three-lock-'.length,
    );
  }

  /// Answers the card in front of the reader: a pick right unless [wrong],
  /// a share [off] points from its answer.
  Future<String> answer(
    WidgetTester tester, {
    bool wrong = false,
    double off = 4,
  }) async {
    final String id = onScreen(tester);
    final Pill p = PillBank.byId(id)!;
    switch (p.challenge) {
      case PickOne(:final correct, :final options):
        final int pick = wrong ? (correct + 1) % options.length : correct;
        await tapKey(tester, 'three-option-$id-$pick');
      default:
        BetsDay.instance.keepDraft(BetsDay.draftKey(kDailyBet, id), {
          'g': ((answerOf(p)?.value ?? 50) + off).clamp(0, 100).roundToDouble(),
        });
        await settle(tester);
    }
    return id;
  }

  Future<AppState> start(WidgetTester tester, Brightness brightness) async {
    Analytics.useForTest(null);
    Trace.useForTest(Trace());
    Served.useForTest(Served());
    ExplorePlay.resetForTest(clock: _clock);
    BetsDay.resetForTest(clock: _clock);
    ThreeDays.resetForTest();
    // No network in a camera: pictures stay as their drawn stand-ins.
    CardThumb.image = (url) => onePixel;
    final MemoryDailyStore store = MemoryDailyStore(judge: _judge);
    final List<Pill> five = DailyDeal.five(_now);
    store.put(
      DailyGame.five(dateKey(_now)).keyFor([for (final p in five) p.id]),
      _crowd(five, 500),
    );
    final List<Pill> three = DailyDeal.three(_now, 'economics');
    store.put(
      DailyGame.three(
        dateKey(_now),
        'economics',
      ).keyFor([for (final p in three) p.id]),
      _crowd(three, 300),
    );
    DailyCrowd.useForTest(store);
    final AppState app = (await tester.runAsync(
      () => readyApp(const {}, _clock),
    ))!;
    await tester.runAsync(BetsDay.instance.load);
    await tester.runAsync(ThreeDays.instance.load);
    tester.view.physicalSize = const Size(390, 844) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildAstutoTheme(brightness),
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: SafeArea(child: ExploreScreen(app: app)),
        ),
      ),
    );
    await settle(tester);
    return app;
  }

  for (final Brightness b in Brightness.values) {
    final String tone = b == Brightness.dark ? 'night' : 'day';

    testWidgets('Today\'s five, played through: $tone', (tester) async {
      await start(tester, b);
      await shoot(tester, 'five-$tone-1-top');
      // The first card locked in: what it came to, and the why.
      final String first = await answer(tester);
      await tapKey(tester, 'three-lock-$first');
      await bringUp(tester, 'three-card-$first');
      await shoot(tester, 'five-$tone-2-locked');
      await tapKey(tester, 'three-next');
      bool shareShot = false;
      for (int i = 1; i < 5; i++) {
        final String id = await answer(tester, wrong: i == 2);
        if (!shareShot && PillBank.byId(id)!.challenge is! PickOne) {
          await bringUp(tester, 'three-card-$id');
          await shoot(tester, 'five-$tone-3-share');
          shareShot = true;
        }
        await tapKey(tester, 'three-lock-$id');
        await tapKey(tester, 'three-next');
      }
      await bringUp(tester, 'three-result');
      await shoot(tester, 'five-$tone-4-result');
      // Question by question, opened.
      await tester.tap(find.byKey(const ValueKey('three-each')));
      await settle(tester);
      await bringUp(tester, 'three-row-${DailyDeal.five(_now)[2].id}');
      await shoot(tester, 'five-$tone-5-rows');
    });
  }

  testWidgets('a subject\'s page opens on its own Today\'s three', (
    tester,
  ) async {
    await start(tester, Brightness.dark);
    await tapKey(tester, 'subject-Economics-off');
    final ScrollPosition page = Scrollable.of(
      tester.element(find.byKey(const ValueKey('three-step-0'))),
    ).position;
    page.jumpTo(page.minScrollExtent);
    await settle(tester);
    await shoot(tester, 'three-night-1-top');
    for (int i = 0; i < 3; i++) {
      final String id = await answer(tester, wrong: i == 1);
      // A share on its track, the guess set and not yet locked in.
      if (PillBank.byId(id)!.challenge is! PickOne) {
        await bringUp(tester, 'three-card-$id');
        await shoot(tester, 'three-night-2-share');
      }
      await tapKey(tester, 'three-lock-$id');
      await tapKey(tester, 'three-next');
    }
    await bringUp(tester, 'three-result');
    await shoot(tester, 'three-night-3-result');
  });
}
