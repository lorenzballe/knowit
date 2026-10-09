import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astuto/data/explore_mix.dart';
import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/main.dart';
import 'package:astuto/state/explore_play.dart';

/// Explore under the shelves that were always there, played: an answer
/// given on a shelf, the round against the clock, a stake from the day's
/// points. Each is a thing a reader does, so each is driven the way a
/// reader would drive it, on the screen as it ships.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Finder _down() => find
    .byWidgetPredicate(
      (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
    )
    .first;

Finder _keyed(bool Function(String) test) => find.byWidgetPredicate(
  (w) => w.key is ValueKey<String> && test((w.key! as ValueKey<String>).value),
);

/// Scrolls the shelves until [target] is built, then brings it up.
Future<void> _reach(WidgetTester tester, Finder target) async {
  for (var i = 0; i < 80 && target.evaluate().isEmpty; i++) {
    await tester.drag(_down(), const Offset(0, -500));
    await tester.pump();
  }
  expect(target, findsWidgets);
  await tester.ensureVisible(target.first);
  await _settle(tester);
  final double top = tester.getTopLeft(target.first).dy;
  await tester.drag(_down(), Offset(0, -(top - 260)));
  await _settle(tester);
}

Future<void> _openExplore(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({'knowit.onboarded': true});
  await tester.pumpWidget(const AstutoApp());
  await _settle(tester);
  await tester.tap(find.byKey(const ValueKey('tab-Explore')));
  await _settle(tester);
}

void main() {
  setUp(() {
    final view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.physicalSize = const Size(402, 874) * 3;
    view.devicePixelRatio = 3;
    ExplorePlay.resetForTest();
  });

  tearDown(() {
    final view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.resetPhysicalSize();
    view.resetDevicePixelRatio();
  });

  testWidgets('every shelf of the mix is on the page, in its order', (
    tester,
  ) async {
    await _openExplore(tester);
    // Read in the order the page lays them out: each is found further down
    // than the one before. What came back is not here: a reader who has
    // answered nothing has nothing coming back.
    final order = [
      // Cards to read.
      'mix-month',
      'theme-myths-0',
      'signature-numbers',
      'theme-practical-0',
      'signature-debates',
      'theme-sharpest-0',
      'theme-origins-0',
      'theme-seen-0',
      'theme-stories-0',
      // Cards to play.
      'theme-trueOrFalse-0',
      'mix-move-sampling',
      'mix-move-compared',
      'mix-work',
      'mix-unmask',
      'mix-how-sure',
      'mix-what-if',
      // Ways in by time, and one card from anywhere to end.
      'mix-series',
      'mix-sixty',
      'mix-mood',
      'front-page',
      'mix-through-time',
      'mix-did-you-know',
      'mix-surprise',
    ];
    // Every theme on the way down has a form of its own: none of the rows
    // of small cards that were all alike is left at the foot.
    const formed = {
      'theme-myths-0',
      'theme-trueOrFalse-0',
      'theme-practical-0',
      'theme-stories-0',
      'theme-sharpest-0',
      'theme-seen-0',
      'theme-origins-0',
    };
    final Set<String> themes = {};
    for (final key in order) {
      await _reach(tester, find.byKey(ValueKey(key)));
      for (final e in _keyed((k) => k.startsWith('theme-')).evaluate()) {
        themes.add((e.widget.key! as ValueKey<String>).value);
      }
    }
    expect(themes.difference(formed), isEmpty);
  });

  testWidgets('a true or false answered on the shelf is the card answered', (
    tester,
  ) async {
    await _openExplore(tester);
    final Finder sayTrue = _keyed(
      (k) => k.startsWith('tf-') && k.endsWith('-true'),
    );
    await _reach(tester, sayTrue);
    final String key =
        (tester.widget(sayTrue.first).key! as ValueKey<String>).value;
    final String id = key.substring(3, key.length - '-true'.length);

    await tester.tap(sayTrue.first);
    await _settle(tester);

    // The card says how it went, there and then, and counts as read.
    expect(find.byKey(ValueKey('tf-verdict-$id')), findsOneWidget);
    expect(find.byKey(ValueKey('explore-read-$id')), findsWidgets);
    final card = PillBank.byId(id)!;
    final bool right = trueOrFalseAnswer(card);
    expect(
      find.text(
        right ? 'Right. Open it for why.' : "It's False. Open it for why.",
      ),
      findsOneWidget,
    );

    // An answer stands: a second tap does not change it. The tap lands on
    // the card, which opens for the why, so the verdict is looked for under
    // the card that opened.
    await tester.tap(find.byKey(ValueKey('tf-$id-false')), warnIfMissed: false);
    await _settle(tester);
    expect(
      find.byKey(ValueKey('tf-verdict-$id'), skipOffstage: false),
      findsOneWidget,
    );
    expect(
      find.text(
        right ? 'Right. Open it for why.' : "It's False. Open it for why.",
        skipOffstage: false,
      ),
      findsOneWidget,
    );
  });

  testWidgets('sixty seconds: eight claims, then the score and the misses', (
    tester,
  ) async {
    await _openExplore(tester);
    await _reach(tester, find.byKey(const ValueKey('sixty-start')));
    await tester.tap(find.byKey(const ValueKey('sixty-start')));
    await _settle(tester);
    expect(find.byKey(const ValueKey('sixty-round')), findsOneWidget);
    for (var i = 0; i < 8; i++) {
      await tester.tap(find.byKey(const ValueKey('sixty-true')));
      await tester.pump(const Duration(milliseconds: 200));
    }
    await _settle(tester);
    expect(find.byKey(const ValueKey('sixty-end')), findsOneWidget);
    expect(find.textContaining('of 8'), findsWidgets);
    // Kept for the day: the round is shown as it ended.
    expect(ExplorePlay.instance['sixty'], isA<Map>());
  });

  testWidgets('sixty seconds: the clock ends the round on its own', (
    tester,
  ) async {
    await _openExplore(tester);
    await _reach(tester, find.byKey(const ValueKey('sixty-start')));
    await tester.tap(find.byKey(const ValueKey('sixty-start')));
    await _settle(tester);
    await tester.tap(find.byKey(const ValueKey('sixty-false')));
    await tester.pump(const Duration(seconds: 61));
    await _settle(tester);
    expect(find.byKey(const ValueKey('sixty-end')), findsOneWidget);
    expect(find.text('before the time ran out'), findsOneWidget);
  });

  testWidgets('work it out: a stake is paid from the day\'s hundred points', (
    tester,
  ) async {
    await _openExplore(tester);
    await _reach(tester, find.byKey(const ValueKey('work-wallet')));
    expect(find.text('100'), findsWidgets);

    // The chips are a row that scrolls, and which one is lit first turns
    // with the day: bring "Place your bet" in, unless it is already on.
    final Finder chip = find.byKey(const ValueKey('work-stake-off'));
    if (find.byKey(const ValueKey('work-stake-on')).evaluate().isEmpty) {
      final Finder chips = find
          .ancestor(
            of: _keyed(
              (k) =>
                  k.startsWith('work-') &&
                  (k.endsWith('-on') || k.endsWith('-off')),
            ),
            matching: find.byWidgetPredicate(
              (w) => w is Scrollable && w.axisDirection == AxisDirection.right,
            ),
          )
          .first;
      for (var i = 0; i < 12 && chip.evaluate().isEmpty; i++) {
        await tester.drag(chips, const Offset(-90, 0));
        await _settle(tester);
      }
      // Built is not on screen: the last chip can sit past the edge.
      await tester.ensureVisible(chip);
      await _settle(tester);
      await tester.tap(chip);
      await _settle(tester);
    }
    expect(find.byKey(const ValueKey('work-stake-on')), findsOneWidget);

    final Finder option = _keyed((k) => RegExp(r'^stake-.*-o0$').hasMatch(k));
    await tester.tap(option.first);
    await _settle(tester);
    final Finder bet = _keyed((k) => k.startsWith('stake-bet-'));
    await tester.tap(bet.first);
    await _settle(tester);

    // Ten points staked: won, a hundred and ten; lost, ninety.
    expect(ExplorePlay.instance.points, anyOf(110, 90));
    expect(_keyed((k) => k.startsWith('stake-said-')), findsOneWidget);
  });

  testWidgets('did you know: a fact turned over and judged is read', (
    tester,
  ) async {
    await _openExplore(tester);
    await _reach(tester, find.byKey(const ValueKey('dyk-new')));
    await tester.tap(find.byKey(const ValueKey('dyk-new')));
    await tester.pump(const Duration(milliseconds: 400));
    await _settle(tester);
    final Object? said = ExplorePlay.instance['dyk'];
    expect(said, isA<Map>());
    expect((said! as Map).values, contains('n'));
  });
}
