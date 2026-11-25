// Sixty seconds on a screen of its own, opened from its tile among Explore's
// challenges: the tile flying open into the screen and back, the three
// moments, a round played there kept and counted exactly as the shelf's
// round is — the day's round, the events, the record — the claims answered
// by a tap or a swipe, one at a time, the clock ending the round on its
// own, the score sent on without the answers, the next challenge a tap
// away, motion reduced, and every moment whole at a large text size.
//
//   flutter test test/explore/sixty_game_test.dart
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart' show SemanticsNode;
import 'package:flutter_test/flutter_test.dart';

import 'package:astuto/analytics.dart';
import 'package:astuto/data/explore_mix.dart';
import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/explore/blocks/bets/bets_day.dart';
import 'package:astuto/explore/blocks/core/quick_games_block.dart';
import 'package:astuto/explore/blocks/core/shelves.dart';
import 'package:astuto/explore/explore_block.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/state/explore_play.dart';
import 'package:astuto/theme.dart';
import 'package:astuto/utils/share_link.dart' show sendText;
import 'package:astuto/utils/share_text.dart';
import 'package:astuto/widgets/explore/challenge_marks.dart';
import 'package:astuto/widgets/explore/challenge_screen.dart';
import 'package:astuto/widgets/explore/challenges.dart';
import 'package:astuto/widgets/explore/sixty_game.dart';

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

void main() {
  setUpAll(loadFonts);
  late _Said said;
  setUp(() {
    // ignore: invalid_use_of_visible_for_testing_member
    ExplorePlay.resetForTest();
    BetsDay.resetForTest();
    said = _Said();
    Analytics.useForTest(said);
  });
  tearDown(() => Analytics.useForTest(null));

  /// Explore's challenges for [host], the screens a tile opens pushed as
  /// the Explore screen pushes them.
  Future<void> pumpChallenges(
    WidgetTester tester,
    CoreHost host, {
    bool calm = false,
  }) async {
    host.pushScreen = (route) =>
        tester.state<NavigatorState>(find.byType(Navigator).first).push(route);
    await pumpSections(tester, host, [_challenges], calm: calm);
  }

  /// Taps the Sixty seconds tile and waits for the screen to be all the way
  /// up, its words in.
  Future<void> open(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey('challenge-sixty')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 300));
  }

  /// The claim in front of the reader.
  Pill front(WidgetTester tester) {
    final Finder claim = find.byWidgetPredicate(
      (w) =>
          w.key is ValueKey<String> &&
          (w.key! as ValueKey<String>).value.startsWith('sixty-claim-'),
    );
    final String id = (tester.widget(claim).key! as ValueKey<String>).value
        .substring('sixty-claim-'.length);
    return PillBank.byId(id)!;
  }

  /// Says the claim in front right or wrong, by its button.
  Future<void> say(WidgetTester tester, {required bool right}) async {
    final bool truth = trueOrFalseAnswer(front(tester));
    await tester.tap(
      find.byKey(ValueKey(truth == right ? 'sixty-true' : 'sixty-false')),
    );
    await tester.pump(const Duration(milliseconds: 350));
  }

  Future<void> play(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey('sixty-play')));
    for (int i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  testWidgets('the tile opens into a screen of its own, on the app\'s own '
      'page: the skill, the name, what it measures, Begin; the cross puts '
      'it back', (tester) async {
    final CoreHost host = CoreHost(await readyApp());
    await pumpChallenges(tester, host);
    final SemanticsNode tile = tester.getSemantics(
      find.byKey(const ValueKey('challenge-sixty')),
    );
    expect(
      tile.label,
      'Intuition, Sixty seconds, Eight claims against the clock.',
    );

    await tester.tap(find.byKey(const ValueKey('challenge-sixty')));
    await tester.pump();
    expect(host.screens.single.id, 'quick-games-sixty');
    expect(host.screens.single.block, 'sixty');
    expect(host.pages, isEmpty);
    // Halfway: the tile's ground on its way, the screen's words not yet in.
    await tester.pump(const Duration(milliseconds: 120));
    expect(find.byType(ChallengeScreen), findsOneWidget);
    final Iterable<Hero> heroes = tester.widgetList<Hero>(find.byType(Hero));
    expect(
      heroes.where((h) => h.tag == challengeHeroOf(host.screens.single)),
      isNotEmpty,
    );
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Sixty seconds'), findsWidgets);
    expect(find.text('INTUITION'), findsOneWidget);
    expect(
      find.text(
        'Eight claims, true or false, in one minute. It measures how well '
        'you judge at speed, the way most of what we read is judged.',
      ),
      findsOneWidget,
    );
    // No best yet: no figures to show.
    expect(find.byKey(const ValueKey('sixty-record')), findsNothing);
    expect(find.bySemanticsLabel('Begin'), findsOneWidget);
    // The page is the app's own, tinted with the challenge's colour.
    final ChallengeGround ground = tester.widget(
      find.byKey(const ValueKey('sixty-ground')),
    );
    expect(ground.colour, kQuickGames.first.tone.page(Palette.dark));
    expect(find.byType(ChallengeRule), findsWidgets);

    await tester.tap(find.byKey(const ValueKey('sixty-close')));
    await tester.pumpAndSettle();
    expect(find.byType(ChallengeScreen), findsNothing);
    expect(find.byKey(const ValueKey('challenge-sixty')), findsOneWidget);
  });

  testWidgets('a round on the screen is the day\'s round: kept for the day, '
      'said, and its record kept for good; opened again, the screen opens on '
      'how it went', (tester) async {
    final CoreHost host = CoreHost(await readyApp());
    final List<Pill> claims = ExploreShelves.of(host).mix.sixty;
    await pumpChallenges(tester, host);
    await open(tester);
    await play(tester);
    expect(find.byKey(const ValueKey('sixty-seg-0-now')), findsOneWidget);
    expect(find.bySemanticsLabel('60 seconds left'), findsOneWidget);
    for (int i = 0; i < 8; i++) {
      await say(tester, right: true);
    }
    for (int i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byKey(const ValueKey('sixty-end')), findsOneWidget);
    expect(find.text('All eight right.'), findsOneWidget);
    expect(find.text('Personal best'), findsOneWidget);
    expect(find.bySemanticsLabel('8 of 8'), findsOneWidget);
    expect(host.app.sixtyBest, 8);

    final Object? kept = ExplorePlay.instance['sixty'];
    expect(kept, isA<Map>());
    expect((kept! as Map)['ids'], [for (final p in claims) p.id]);
    expect((kept as Map)['a'], [for (final p in claims) trueOrFalseAnswer(p)]);
    expect(said.of('explore sixty started'), hasLength(1));
    expect(said.of('explore sixty finished').single['right'], 8);
    expect(said.of('explore sixty finished').single['answered'], 8);
    // Every claim was put in front of the reader, under the game's section.
    expect(
      host.shown.where((s) => s.$1 == 'quick-games-sixty').map((s) => s.$2),
      containsAll([for (final p in claims) p.id]),
    );

    // A claim of the round opens its card, among the eight.
    await tester.drag(
      find.byKey(const ValueKey('sixty-end')),
      const Offset(0, -500),
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byKey(ValueKey('sixty-miss-${claims[2].id}')));
    expect(host.opened.last, ('quick-games-sixty', claims[2].id));

    await tester.tap(find.byKey(const ValueKey('sixty-close')));
    await tester.pumpAndSettle();
    await open(tester);
    expect(find.byKey(const ValueKey('sixty-end')), findsOneWidget);
    expect(find.byKey(const ValueKey('sixty-play')), findsNothing);
    // Not a new best now: the best it set.
    expect(find.text('Personal best'), findsNothing);
    expect(find.text('Best'), findsOneWidget);
    expect(find.text('8/8'), findsOneWidget);
  });

  testWidgets('the clock ends the round on its own; a claim not answered is '
      'neither right nor wrong', (tester) async {
    final CoreHost host = CoreHost(await readyApp());
    await host.app.noteSixtyRound(3);
    await pumpChallenges(tester, host);
    await open(tester);
    expect(find.text('Best'), findsOneWidget);
    expect(find.text('3/8'), findsOneWidget);
    await play(tester);
    await say(tester, right: false);
    await tester.pump(const Duration(seconds: 5));
    expect(
      find.bySemanticsLabel(RegExp(r'^5\d seconds left$')),
      findsOneWidget,
    );
    await tester.pump(const Duration(seconds: 60));
    for (int i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byKey(const ValueKey('sixty-end')), findsOneWidget);
    expect(
      find.text('The time ran out with 7 claims unanswered.'),
      findsOneWidget,
    );
    expect(find.text('3/8'), findsOneWidget);
    expect(find.text('Personal best'), findsNothing);
    expect(host.app.sixtyBest, 3);
    expect(said.of('explore sixty finished').single['answered'], 1);
    expect(find.bySemanticsLabel(RegExp(r'No answer\.$')), findsNWidgets(7));
  });

  testWidgets('a swipe says true or false as the buttons do, and two taps at '
      'once say one claim, not two', (tester) async {
    final CoreHost host = CoreHost(await readyApp());
    await pumpChallenges(tester, host);
    await open(tester);
    await play(tester);
    final bool first = trueOrFalseAnswer(front(tester));
    await tester.drag(
      find.byKey(const ValueKey('sixty-card')),
      const Offset(300, 0),
    );
    await tester.pump(const Duration(milliseconds: 400));
    // To the right is true.
    expect(
      find.byKey(ValueKey('sixty-seg-0-${first ? 'right' : 'wrong'}')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('sixty-false')));
    await tester.tap(find.byKey(const ValueKey('sixty-false')));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const ValueKey('sixty-seg-2-now')), findsOneWidget);
  });

  testWidgets('the score is sent on as squares, never the answers; the next '
      'challenge opens its own page', (tester) async {
    final List<String> sent = [];
    sendText = (text) async {
      sent.add(text);
      return true;
    };
    addTearDown(() => sendText = shareText);
    final CoreHost host = CoreHost(await readyApp());
    final List<Pill> claims = ExploreShelves.of(host).mix.sixty;
    await pumpChallenges(tester, host);
    await open(tester);
    await play(tester);
    for (int i = 0; i < 8; i++) {
      await say(tester, right: i.isEven);
    }
    for (int i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.tap(find.byKey(const ValueKey('sixty-share')));
    await tester.pump();
    final String text = sent.single;
    expect(text, startsWith('Astute · Sixty seconds · '));
    expect(text, contains('4 of 8 right'));
    expect(text, contains('🟩🟥🟩🟥🟩🟥🟩🟥'));
    expect(text, contains('ref=share_sixty'));
    for (final Pill p in claims) {
      expect(text, isNot(contains(claimOf(p))));
    }
    expect(said.of('explore sixty shared').single['right'], 4);

    // The next challenge, after the claims again: this screen back into
    // its tile, and the next one out of its own, on its screen.
    await tester.ensureVisible(find.byKey(const ValueKey('sixty-next')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('sixty-next')));
    for (int i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 400));
    }
    expect(host.screens.last.id, 'quick-games-spot-false');
    expect(host.screens.last.block, 'spot-false');
    expect(find.byKey(const ValueKey('spot-play')), findsOneWidget);
    expect(find.byKey(const ValueKey('sixty-play')), findsNothing);
    expect(host.pages, isEmpty);
  });

  testWidgets('with motion reduced the screen is there at once, and the '
      'round starts at once', (tester) async {
    // Asked of the phone, as a reader asks it: every screen without motion.
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final CoreHost host = CoreHost(await readyApp());
    await pumpChallenges(tester, host, calm: true);
    await tester.tap(find.byKey(const ValueKey('challenge-sixty')));
    await tester.pump();
    await tester.pump();
    expect(find.byKey(const ValueKey('sixty-play')).hitTestable(), findsOne);
    await tester.tap(find.byKey(const ValueKey('sixty-play')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    // Still a minute: reduced motion does not hurry the clock.
    expect(find.bySemanticsLabel('58 seconds left'), findsOneWidget);
    // An answer is told at once, with nothing flying.
    await say(tester, right: true);
    expect(find.byKey(const ValueKey('sixty-seg-0-right')), findsOneWidget);
    expect(find.byKey(const ValueKey('sixty-seg-1-now')), findsOneWidget);
  });

  testWidgets('the shelf\'s round, too, lasts a minute with motion reduced', (
    tester,
  ) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final CoreHost host = CoreHost(await readyApp());
    await pumpSections(tester, host, [
      ExploreSection.fromJson({'id': 'sixty', 'block': 'sixty'}),
    ]);
    await tester.tap(find.byKey(const ValueKey('sixty-start')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 5));
    expect(find.byKey(const ValueKey('sixty-round')), findsOneWidget);
    expect(find.text('55 s'), findsOneWidget);
  });

  for (final (String language, double text) in [('en', 2.0), ('de', 1.4)]) {
    testWidgets('$language at ${text}x, 360 by 740: every moment whole', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 740) * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final CoreHost host = CoreHost(await readyApp(), language: language);
      await host.app.noteSixtyRound(5);
      final List<Pill> claims = ExploreShelves.of(host).mix.sixty;
      final AppLocalizations l = lookupAppLocalizations(Locale(language));
      await tester.pumpWidget(
        MaterialApp(
          locale: Locale(language),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: buildAstutoTheme(Brightness.dark),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(text)),
            child: child!,
          ),
          home: ChallengeScreen(
            game: SixtyChallenge(
              pills: claims,
              best: () => host.app.sixtyBest,
              onFinished: host.app.noteSixtyRound,
              onOpen: (_, _) {},
            ),
            look: ChallengeLook(
              title: l.sixtyTitle,
              skill: l.sixtySkill,
              line: l.sixtyAsks,
              tone: kQuickGames.first.tone,
              mark: ChallengeMark.sixty,
            ),
            heroTag: 'sixty',
            next: ChallengeLook(
              title: l.spotTitle,
              skill: l.spotSkill,
              line: l.spotAsks,
              tone: kQuickGames[1].tone,
              mark: ChallengeMark.spot,
            ),
            onNext: () {},
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.takeException(), isNull);
      expect(find.byKey(const ValueKey('sixty-play')), findsOneWidget);
      await play(tester);
      expect(tester.takeException(), isNull);
      for (int i = 0; i < 8; i++) {
        await say(tester, right: i < 6);
      }
      for (int i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }
      expect(tester.takeException(), isNull);
      expect(find.byKey(const ValueKey('sixty-end')), findsOneWidget);
      expect(find.byKey(const ValueKey('sixty-best')), findsOneWidget);
    });
  }
}
