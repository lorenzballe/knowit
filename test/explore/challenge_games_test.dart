// Every challenge besides Sixty seconds on a screen of its own, opened from
// its tile among Explore's challenges: what it is, a round played the way
// its mechanic asks, and how it went — and each counted exactly as on its
// shelf: the pick of Spot the false one kept for the day and recorded as
// the card's answer, the claims of True or false answered as the cards'
// own, every bet laid as its tile lays it, under the game's own section,
// with the same drafts, the same how sure, the same notes. The three
// games of time keep their round for the day, deal the same round to
// everyone, and play again with the day's next. Motion reduced, and a
// large text size on a small phone, every screen still whole.
//
//   flutter test test/explore/challenge_games_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:astuto/analytics.dart';
import 'package:astuto/data/dated_lines.dart';
import 'package:astuto/data/explore_mix.dart';
import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/explore/blocks/bets/answers.dart';
import 'package:astuto/explore/blocks/bets/bets_day.dart';
import 'package:astuto/explore/blocks/bets/closer.dart';
import 'package:astuto/explore/blocks/bets/deal.dart';
import 'package:astuto/explore/blocks/core/shelves.dart';
import 'package:astuto/explore/explore_block.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/state/explore_play.dart';
import 'package:astuto/utils/share_link.dart' show sendText;
import 'package:astuto/widgets/explore/challenge_screen.dart';
import 'package:astuto/widgets/explore/spot_the_false.dart';

import 'core_harness.dart';

ExploreSection get _challenges =>
    ExploreSection.fromJson({'id': 'quick-games', 'block': 'quick-games'});

/// What the analytics were told.
class _Said implements AnalyticsSink {
  final List<(String, Map<String, Object>)> events = [];

  Iterable<Map<String, Object>> of(String event) => [
    for (final e in events)
      if (e.$1 == event) e.$2,
  ];

  @override
  Future<void> capture(String event, Map<String, Object> properties) async =>
      events.add((event, properties));

  @override
  Future<void> screen(String name) async {}

  @override
  Future<void> identify(String id, Map<String, Object> properties) async {}

  @override
  Future<void> reset() async {}

  @override
  Future<void> register(String key, Object value) async {}

  @override
  Future<void> setCollecting(bool on) async {}

  @override
  Future<void> setPerson(
    Map<String, Object> set,
    Map<String, Object> setOnce,
  ) async {}

  @override
  Future<void> error(
    Object error,
    StackTrace? stack,
    Map<String, Object> properties,
  ) async {}
}

/// The page of the challenges each game's tile is on.
const Map<String, int> _page = {
  'spot-false': 0,
  'true-false': 0,
  'bets-bigger': 0,
  'bets-closer': 1,
  'bets-magnitude': 1,
  'bets-range': 1,
  'bets-stake': 1,
  'bets-number': 2,
  'in-order': 2,
  'what-year': 2,
  'before-after': 2,
};

void main() {
  setUpAll(loadFonts);
  late _Said said;
  setUp(() async {
    // ignore: invalid_use_of_visible_for_testing_member
    ExplorePlay.resetForTest();
    BetsDay.resetForTest();
    said = _Said();
    Analytics.useForTest(said);
  });
  tearDown(() => Analytics.useForTest(null));

  Finder prefixed(String prefix) => find.byWidgetPredicate(
    (w) =>
        w.key is ValueKey<String> &&
        (w.key! as ValueKey<String>).value.startsWith(prefix),
  );

  /// The id in the first key that starts with [prefix].
  String idAfter(WidgetTester tester, String prefix) =>
      (tester.widget(prefixed(prefix).first).key! as ValueKey<String>).value
          .substring(prefix.length);

  Future<void> frames(WidgetTester tester, [int n = 8]) async {
    for (int i = 0; i < n; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  /// Explore's challenges for [host], the screens a tile opens pushed as
  /// the Explore screen pushes them, the day's bets read.
  Future<void> pumpChallenges(
    WidgetTester tester,
    CoreHost host, {
    bool calm = false,
    Size size = const Size(375, 667),
    double text = 1,
  }) async {
    host.pushScreen = (route) =>
        tester.state<NavigatorState>(find.byType(Navigator).first).push(route);
    await BetsDay.instance.load();
    await pumpSections(
      tester,
      host,
      [_challenges],
      calm: calm,
      size: size,
      text: text,
    );
    await tester.pump();
  }

  /// Opens [game] out of its tile, turning to its page first, and waits
  /// for its screen to be all the way up.
  Future<void> open(WidgetTester tester, String game) async {
    final int page = _page[game]!;
    if (page > 0) {
      await tester.tap(find.byKey(ValueKey('challenge-dot-$page')));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.byKey(ValueKey('challenge-$game')));
    await frames(tester, 10);
  }

  Future<void> play(WidgetTester tester, String id) async {
    await tester.tap(find.byKey(ValueKey('$id-play')));
    await frames(tester, 6);
  }

  /// The way on, once a round is told, until the score.
  Future<void> next(WidgetTester tester, String id) async {
    await tester.tap(find.byKey(ValueKey('$id-next-card')));
    await frames(tester, 6);
  }

  String scoreLabel(WidgetTester tester, String id) => tester
      .getSemantics(find.byKey(ValueKey('$id-score')))
      .label;

  group('the games of the cards', () {
    testWidgets('Spot the false one: four claims on the whole screen, one '
        'pick, kept for the day and recorded as its card\'s answer; the '
        'other three read; opened again, how it went', (tester) async {
      final CoreHost host = CoreHost(await readyApp());
      final SpotTheFalse spot = ExploreShelves.of(host).mix.spot!;
      await pumpChallenges(tester, host);
      await open(tester, 'spot-false');
      expect(host.screens.single.id, 'quick-games-spot-false');
      expect(
        find.text(
          'Four claims: three are true and one is false. Find the false '
          'one. It measures how well you tell a sound claim from one that '
          'only sounds right.',
        ),
        findsOneWidget,
      );
      expect(find.text('One pick a day'), findsOneWidget);
      await play(tester, 'spot');
      expect(find.text('Tap the claim you think is false.'), findsOneWidget);
      // Nothing picked: nothing to confirm.
      await tester.tap(find.byKey(const ValueKey('spot-confirm')));
      await tester.pump();
      expect(host.answered, isEmpty);

      final Pill lie = spot.falseOne;
      await tester.tap(find.byKey(ValueKey('spot-claim-${lie.id}')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('spot-confirm')));
      await frames(tester, 3);
      expect(ExplorePlay.instance[spotKey(spot)], lie.id);
      expect(host.answered, [(lie.id, '${trueOrFalseIndex(lie, false)}')]);
      for (final Pill p in spot.cards.where((p) => p.id != lie.id)) {
        expect(host.app.seenIds, contains(p.id));
      }
      expect(said.of('explore spot').single, {
        'pill_id': lie.id,
        'right': true,
      });
      await frames(tester, 25);
      expect(scoreLabel(tester, 'spot'), '1 of 1');
      expect(find.text('You spotted the false one.'), findsOneWidget);
      expect(find.byKey(const ValueKey('spot-tomorrow')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('spot-close')));
      await tester.pumpAndSettle();
      await open(tester, 'spot-false');
      expect(find.byKey(const ValueKey('spot-score')), findsOneWidget);
      expect(find.byKey(const ValueKey('spot-play')), findsNothing);
    });

    testWidgets('True or false: the shelf\'s claims one at a time, each '
        'recorded as its card\'s answer and told at once; the round goes '
        'on where it was left', (tester) async {
      final CoreHost host = CoreHost(await readyApp());
      final List<Pill> claims = ExploreShelves.of(host).mix.trueFalse!.pills;
      await pumpChallenges(tester, host);
      await open(tester, 'true-false');
      // The day's claims listed under the rules, a row each.
      expect(find.byKey(const ValueKey('tf-today')), findsOneWidget);
      await play(tester, 'tf');
      final Pill first = claims.first;
      await tester.tap(
        find.byKey(
          ValueKey(trueOrFalseAnswer(first) ? 'tf-true' : 'tf-false'),
        ),
      );
      await frames(tester, 4);
      expect(host.answered.single, (
        first.id,
        '${trueOrFalseIndex(first, trueOrFalseAnswer(first))}',
      ));
      expect(find.byKey(ValueKey('tf-told-${first.id}')), findsOneWidget);
      expect(find.byKey(const ValueKey('tf-seg-0-right')), findsOneWidget);
      // The rest, all wrong.
      for (int i = 1; i < claims.length; i++) {
        await tester.tap(find.byKey(const ValueKey('tf-next')));
        await frames(tester, 4);
        final Pill p = claims[i];
        await tester.tap(
          find.byKey(ValueKey(trueOrFalseAnswer(p) ? 'tf-false' : 'tf-true')),
        );
        await frames(tester, 4);
      }
      expect(host.answered, hasLength(claims.length));
      await tester.tap(find.byKey(const ValueKey('tf-next')));
      await frames(tester, 8);
      expect(scoreLabel(tester, 'tf'), '1 of ${claims.length}');
    });

    testWidgets('Which is bigger?: a pair at a time, the bet laid on the '
        'pair as the tile lays it, both cards counted read', (tester) async {
      final CoreHost host = CoreHost(await readyApp());
      await pumpChallenges(tester, host);
      await open(tester, 'bets-bigger');
      expect(find.byKey(const ValueKey('bigger-today')), findsOneWidget);
      await play(tester, 'bigger');
      final String a = idAfter(tester, 'bigger-half-');
      await tester.tap(prefixed('bigger-half-').first);
      await frames(tester, 4);
      final Bet bet = BetsDay.instance.betOn('bigger', a)!;
      expect(bet.section, 'quick-games-bets-bigger');
      expect(bet.said, '0');
      expect(
        host.notes.where((n) => n.$2 == 'bet revealed'),
        hasLength(2),
      );
      expect(host.notes.first.$1, 'quick-games-bets-bigger');
      expect(find.byKey(const ValueKey('bigger-next-card')), findsOneWidget);
    });
  });

  group('the games of bets', () {
    testWidgets('Closer, closer: more or less, step by step, the game kept '
        'as the tile keeps it and laid at its last step', (tester) async {
      final CoreHost host = CoreHost(await readyApp());
      await pumpChallenges(tester, host);
      await open(tester, 'bets-closer');
      await play(tester, 'closer');
      final String id = idAfter(tester, 'closer-more-');
      final BetAnswer answer = answerOf(PillBank.byId(id)!)!;
      await tester.tap(find.byKey(ValueKey('closer-more-$id')));
      await frames(tester, 3);
      // A step taken is the tile's draft.
      expect(BetsDay.instance.draft(BetsDay.draftKey('closer', id)), 'M');
      expect(closerTaps(answer), 'M');
      await tester.tap(find.byKey(ValueKey('closer-less-$id')));
      await frames(tester, 3);
      await tester.tap(find.byKey(ValueKey('closer-more-$id')));
      await frames(tester, 3);
      final Bet bet = BetsDay.instance.betOn('closer', id)!;
      final CloserGame game = CloserGame.of('MLM', answer.value, 3);
      expect(bet.said, 'MLM');
      expect(bet.section, 'quick-games-bets-closer');
      expect(bet.facts, {'right': game.right, 'steps': game.taken});
      expect(bet.right, game.right == game.taken);
      expect(
        host.notes.map((n) => n.$2),
        containsAll(['bet laid', 'bet revealed']),
      );
      expect(find.byKey(const ValueKey('closer-next-card')), findsOneWidget);
    });

    testWidgets('Orders of magnitude: a size from the staircase, how sure, '
        'and the card\'s answer given', (tester) async {
      final CoreHost host = CoreHost(await readyApp());
      await pumpChallenges(tester, host);
      await open(tester, 'bets-magnitude');
      await play(tester, 'magnitude');
      final Finder stairs = find.byWidgetPredicate(
        (w) =>
            w.key is ValueKey<String> &&
            RegExp(
              r'^magnitude-(?!round-|seg-|card-).+-\d$',
            ).hasMatch((w.key! as ValueKey<String>).value),
      );
      final String key =
          (tester.widget(stairs.at(1)).key! as ValueKey<String>).value;
      final String id = key.substring(
        'magnitude-'.length,
        key.lastIndexOf('-'),
      );
      await tester.tap(stairs.at(1));
      await frames(tester, 3);
      expect(BetsDay.instance.draft(BetsDay.draftKey('magnitude', id)), {
        'p': 1,
      });
      await tester.tap(find.byKey(const ValueKey('magnitude-sure-70')));
      await frames(tester, 3);
      final Bet bet = BetsDay.instance.betOn('magnitude', id)!;
      expect(bet.confidence, 70);
      expect(bet.facts['at'], 1);
      expect(host.answered.single.$1, id);
      expect(host.answered.single.$2, bet.said);
    });

    testWidgets('Bet a range: a width and a guess, the bet laid as the tile '
        'lays it', (tester) async {
      final CoreHost host = CoreHost(await readyApp());
      await pumpChallenges(tester, host);
      await open(tester, 'bets-range');
      await play(tester, 'range');
      final String id = idAfter(tester, 'range-bet-');
      await tester.tap(find.byKey(ValueKey('range-$id-w0')));
      await frames(tester, 2);
      await tester.tap(find.byKey(ValueKey('range-bet-$id')));
      await frames(tester, 3);
      final Bet bet = BetsDay.instance.betOn('range', id)!;
      expect(bet.facts['w'], 0);
      expect(bet.facts['half'], kRangeWidths.first.half);
      expect(bet.facts['lo'], 50 - kRangeWidths.first.half);
      expect(bet.said, '50');
      expect(host.answered.single, (id, '50'));
    });

    testWidgets('Place your bet: an amount, a stake, how sure; the points '
        'doubled or lost', (tester) async {
      final CoreHost host = CoreHost(await readyApp());
      await pumpChallenges(tester, host);
      await open(tester, 'bets-stake');
      expect(find.text('100 points left today'), findsOneWidget);
      await play(tester, 'stake');
      final String id = idAfter(tester, 'stake-bet-');
      await tester.tap(find.byKey(ValueKey('stake-$id-o1')));
      await frames(tester, 2);
      await tester.tap(find.byKey(ValueKey('stake-$id-k1')));
      await frames(tester, 2);
      await tester.tap(find.byKey(ValueKey('stake-bet-$id')));
      await frames(tester, 2);
      await tester.tap(find.byKey(const ValueKey('stake-sure-80')));
      await frames(tester, 3);
      final Bet bet = BetsDay.instance.betOn('stake', id)!;
      expect(bet.said, '1');
      expect(bet.facts['stake'], 20);
      expect(bet.confidence, 80);
      expect(bet.points, bet.right ? 20 : -20);
      expect(BetsDay.instance.points, 100 + bet.points);
    });

    testWidgets('Your number: steppers, a lock, how sure', (tester) async {
      final CoreHost host = CoreHost(await readyApp());
      await pumpChallenges(tester, host);
      await open(tester, 'bets-number');
      await play(tester, 'number');
      final String id = idAfter(tester, 'number-lock-');
      final BetAnswer answer = answerOf(PillBank.byId(id)!)!;
      final StepScale scale = StepScale.around(answer)!;
      await tester.tap(find.byKey(ValueKey('number-$id-${scale.big}')));
      await frames(tester, 2);
      await tester.tap(find.byKey(ValueKey('number-lock-$id')));
      await frames(tester, 2);
      await tester.tap(find.byKey(const ValueKey('number-sure-60')));
      await frames(tester, 3);
      final Bet bet = BetsDay.instance.betOn('number', id)!;
      expect(
        bet.said,
        plainResponse(scale.move(scale.start, scale.big)),
      );
      expect(bet.confidence, 60);
      expect(bet.section, 'quick-games-bets-number');
    });

    testWidgets('a round of bets played to its end: the score from the bets '
        'laid, the cards again, and on its shelf the same bets told',
        (tester) async {
      final CoreHost host = CoreHost(await readyApp());
      await pumpChallenges(tester, host);
      await open(tester, 'bets-closer');
      await play(tester, 'closer');
      for (int card = 0; card < 3; card++) {
        final String id = idAfter(tester, 'closer-more-');
        for (int step = 0; step < 3; step++) {
          if (prefixed('closer-more-$id').evaluate().isEmpty) break;
          await tester.tap(find.byKey(ValueKey('closer-more-$id')));
          await frames(tester, 2);
        }
        await next(tester, 'closer');
      }
      expect(find.byKey(const ValueKey('closer-score')), findsOneWidget);
      // Every step counted, and the round as squares, a step each.
      expect(
        find.byKey(const ValueKey('closer-tomorrow')),
        findsOneWidget,
      );
      final List<Bet> bets = [
        for (final Bet b in BetsDay.instance.slip)
          if (b.kind == 'closer') b,
      ];
      expect(bets, hasLength(3));
      final int right = bets.fold(
        0,
        (a, b) => a + ((b.facts['right'] as num?)?.toInt() ?? 0),
      );
      final int steps = bets.fold(
        0,
        (a, b) => a + ((b.facts['steps'] as num?)?.toInt() ?? 0),
      );
      expect(scoreLabel(tester, 'closer'), '$right of $steps');
      // Opened again: how it went.
      await tester.tap(find.byKey(const ValueKey('closer-close')));
      await tester.pumpAndSettle();
      await open(tester, 'bets-closer');
      expect(find.byKey(const ValueKey('closer-score')), findsOneWidget);
    });
  });

  group('the games of time', () {
    testWidgets('In order: four moments tapped in the order they happened, '
        'kept for the day; the same round for everybody; played again, '
        'the day\'s next round', (tester) async {
      final CoreHost host = CoreHost(await readyApp());
      final TimeDeal deal = ExploreShelves.of(host).time;
      final List<DatedLine> round = deal.round(TimeGame.order, 0);
      expect(round, hasLength(4));
      // The same round for anybody else today.
      final CoreHost other = CoreHost(await readyApp());
      expect(
        [for (final d in ExploreShelves.of(other).time.round(TimeGame.order, 0))
          d.pill.id],
        [for (final d in round) d.pill.id],
      );
      await pumpChallenges(tester, host);
      await open(tester, 'in-order');
      expect(host.screens.single.block, 'in-order');
      await play(tester, 'in-order');
      expect(said.of('explore in-order started').single, {'round': 0});
      expect(find.text('Tap the moment that came first.'), findsOneWidget);
      final List<DatedLine> truth = [...round]
        ..sort((a, b) => a.year.compareTo(b.year));
      // The year is not on the screen until the order is checked.
      for (final DatedLine d in round) {
        expect(find.textContaining('${d.year}'), findsNothing);
      }
      for (final DatedLine d in truth) {
        await tester.tap(find.byKey(ValueKey('in-order-card-${d.pill.id}')));
        await tester.pump();
      }
      expect(find.text('All placed.'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('in-order-check')));
      await frames(tester, 3);
      expect(ExplorePlay.instance['in-order'], {
        'r': 0,
        'ids': [for (final d in round) d.pill.id],
        'a': [
          [for (final d in truth) d.pill.id],
        ],
      });
      expect(said.of('explore in-order finished').single, {
        'right': 4,
        'round': 0,
      });
      await frames(tester, 25);
      expect(scoreLabel(tester, 'in-order'), '4 of 4');
      expect(find.text('Every one in its place.'), findsOneWidget);
      // Played again: the day's second round, other moments.
      await tester.tap(find.byKey(const ValueKey('in-order-again')));
      await frames(tester, 6);
      final List<DatedLine> second = deal.round(TimeGame.order, 1);
      expect(
        second.map((d) => d.pill.id).toSet().intersection(
          round.map((d) => d.pill.id).toSet(),
        ),
        isEmpty,
      );
      expect(
        find.byKey(ValueKey('in-order-card-${second.first.pill.id}')),
        findsOneWidget,
      );
      expect(said.of('explore in-order started').last, {'round': 1});
    });

    testWidgets('What year?: the year dialled for each moment, points by '
        'how near, the share without the moments', (tester) async {
      final List<String> sent = [];
      final shareText = sendText;
      sendText = (text) async {
        sent.add(text);
        return true;
      };
      addTearDown(() => sendText = shareText);
      final CoreHost host = CoreHost(await readyApp());
      final List<DatedLine> round = ExploreShelves.of(
        host,
      ).time.round(TimeGame.year, 0);
      await pumpChallenges(tester, host);
      await open(tester, 'what-year');
      await play(tester, 'what-year');
      int points = 0;
      for (int i = 0; i < round.length; i++) {
        // One step on from where the dial starts, and locked.
        await tester.tap(find.byKey(const ValueKey('what-year-step-10')));
        await tester.pump();
        expect(find.text('1960'), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('what-year-lock')));
        await frames(tester, 3);
        points += yearPoints(1960, round[i].year, now: DateTime.now().year);
        expect(find.text('${round[i].year}'), findsWidgets);
        await tester.tap(find.byKey(const ValueKey('what-year-next')));
        await frames(tester, 8);
      }
      expect(ExplorePlay.instance['what-year'], {
        'r': 0,
        'ids': [for (final d in round) d.pill.id],
        'a': [1960, 1960, 1960],
      });
      expect(scoreLabel(tester, 'what-year'), '$points of 30 points');
      await tester.tap(find.byKey(const ValueKey('what-year-share')));
      await tester.pump();
      expect(sent.single, startsWith('Astute · What year? · '));
      expect(sent.single, contains('$points of 30 points'));
      expect(sent.single, contains('ref=share_challenges'));
      for (final DatedLine d in round) {
        // The moment itself, never its words: a moment that opens on a
        // word as short as "A" is not told by that word alone.
        expect(sent.single, isNot(contains(d.text)));
        expect(sent.single, isNot(contains(d.gapped(''))));
      }
      expect(said.of('explore what-year shared').single['points'], points);
    });

    testWidgets('Before or after?: each moment against the one above it, '
        'its year told once said', (tester) async {
      final CoreHost host = CoreHost(await readyApp());
      final List<DatedLine> chain = ExploreShelves.of(
        host,
      ).time.round(TimeGame.chain, 0);
      expect(chain, hasLength(6));
      await pumpChallenges(tester, host);
      await open(tester, 'before-after');
      await play(tester, 'before-after');
      for (int i = 1; i < chain.length; i++) {
        expect(find.text('Before or after ${chain[i - 1].year}?'),
            findsOneWidget);
        final bool after = chain[i].year > chain[i - 1].year;
        await tester.tap(
          find.byKey(
            ValueKey(after ? 'before-after-after' : 'before-after-before'),
          ),
        );
        await frames(tester, 14);
      }
      await frames(tester, 6);
      expect(scoreLabel(tester, 'before-after'), '5 of 5');
      expect(find.text('Not one out of place.'), findsOneWidget);
      expect(said.of('explore before-after finished').single['right'], 5);
    });
  });

  group('every screen, for every reader', () {
    testWidgets('with motion reduced a round ends at once, nothing flying',
        (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      final CoreHost host = CoreHost(await readyApp());
      final List<DatedLine> round = ExploreShelves.of(
        host,
      ).time.round(TimeGame.order, 0);
      await pumpChallenges(tester, host, calm: true);
      await tester.tap(find.byKey(const ValueKey('challenge-dot-2')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('challenge-in-order')));
      await tester.pump();
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('in-order-play')));
      await tester.pump();
      await tester.pump();
      for (final DatedLine d in round) {
        await tester.tap(find.byKey(ValueKey('in-order-card-${d.pill.id}')));
        await tester.pump();
      }
      await tester.tap(find.byKey(const ValueKey('in-order-check')));
      await tester.pump();
      await tester.pump();
      expect(find.byKey(const ValueKey('in-order-score')), findsOneWidget);
    });

    for (final (String game, String id) in const [
      ('spot-false', 'spot'),
      ('true-false', 'tf'),
      ('bets-bigger', 'bigger'),
      ('bets-closer', 'closer'),
      ('bets-magnitude', 'magnitude'),
      ('bets-range', 'range'),
      ('bets-stake', 'stake'),
      ('bets-number', 'number'),
      ('in-order', 'in-order'),
      ('what-year', 'what-year'),
      ('before-after', 'before-after'),
    ]) {
      testWidgets('$game at 2x on 360 by 740: what it is and the round, '
          'whole', (tester) async {
        final CoreHost host = CoreHost(await readyApp());
        await pumpChallenges(
          tester,
          host,
          size: const Size(360, 740),
          text: 2,
        );
        await open(tester, game);
        expect(tester.takeException(), isNull, reason: '$game, what it is');
        expect(find.byType(ChallengeScreen), findsOneWidget);
        await tester.ensureVisible(find.byKey(ValueKey('$id-play')));
        await tester.pump();
        await tester.tap(find.byKey(ValueKey('$id-play')));
        await frames(tester, 6);
        expect(tester.takeException(), isNull, reason: '$game, the round');
      });
    }
  });
}
