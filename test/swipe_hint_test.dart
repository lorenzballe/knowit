import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/main.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/screens/today_screen.dart';
import 'package:astuto/theme.dart';
import 'package:astuto/widgets/flip_card.dart';
import 'package:astuto/widgets/pill_card_stack.dart';

// Nothing on Today said how card two is reached. The first card now shows
// it, once, to a reader who has never sent a card on: a few seconds after
// its back comes round — or at once when the reader turns it back to its
// front, looking for the way on — it leans aside and settles, and the
// header says it in words. With motion reduced, the words are all there is.

final List<Pill> _facts = PillBank.cards
    .where((p) => p.challenge is NoChallenge)
    .take(2)
    .toList();

Widget _deck({
  required bool hint,
  required VoidCallback onHint,
  bool still = false,
}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    theme: buildAstutoTheme(Brightness.dark),
    home: Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: still),
        child: Scaffold(
          backgroundColor: Palette.dark.surface,
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: kDeckMargin),
            child: PillCardStack(
              deck: _facts,
              index: 0,
              onAdvance: () {},
              answerFor: (_) => null,
              onAnswer: (_, _, _, _) {},
              reviewIds: const {},
              isSaved: (_) => false,
              onSave: (_) {},
              onShare: (_) {},
              swipeHint: hint,
              onSwipeHint: onHint,
            ),
          ),
        ),
      ),
    ),
  );
}

/// Where the card in front is drawn, transforms and all.
double _left(WidgetTester tester) =>
    tester.getTopLeft(find.byType(FlipCard).last).dx;

/// Turns the card in front over, by its top, where neither face has
/// anything of its own to tap.
Future<void> _turn(WidgetTester tester) async {
  final Rect card = tester.getRect(find.byType(FlipCard).last);
  await tester.tapAt(card.topCenter + const Offset(0, 40));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    final view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.physicalSize = const Size(390, 844) * 3;
    view.devicePixelRatio = 3;
  });

  tearDown(() {
    final view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.resetPhysicalSize();
    view.resetDevicePixelRatio();
  });

  testWidgets('a while after the back comes round, the card leans, once', (
    tester,
  ) async {
    var hints = 0;
    await tester.pumpWidget(_deck(hint: true, onHint: () => hints++));
    await tester.pumpAndSettle();
    final double rest = _left(tester);

    await _turn(tester);
    // Reading the back is not interrupted.
    await tester.pump(const Duration(seconds: 3));
    expect(hints, 0);

    await tester.pump(const Duration(milliseconds: 1100));
    expect(hints, 1);
    // On the way, the card goes aside, toward the way it would go...
    var least = rest;
    for (var i = 0; i < 16; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      least = least < _left(tester) ? least : _left(tester);
    }
    expect(least, lessThan(rest - 20));
    // ...and it settles back where it was.
    await tester.pumpAndSettle();
    expect(_left(tester), moreOrLessEquals(rest, epsilon: 0.5));

    // Once: turning it over and back again, and waiting, shows nothing more.
    await _turn(tester);
    await _turn(tester);
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();
    expect(hints, 1);
    expect(_left(tester), moreOrLessEquals(rest, epsilon: 0.5));
  });

  testWidgets('turned back to its front, the card shows the way at once', (
    tester,
  ) async {
    var hints = 0;
    await tester.pumpWidget(_deck(hint: true, onHint: () => hints++));
    await tester.pumpAndSettle();

    await _turn(tester);
    await _turn(tester);
    await tester.pump(const Duration(milliseconds: 700));
    expect(hints, 1);
    await tester.pumpAndSettle();
  });

  testWidgets('with motion reduced, the card holds still and only says it', (
    tester,
  ) async {
    var hints = 0;
    await tester.pumpWidget(
      _deck(hint: true, onHint: () => hints++, still: true),
    );
    await tester.pumpAndSettle();
    final double rest = _left(tester);

    await _turn(tester);
    await tester.pump(const Duration(milliseconds: 4100));
    expect(hints, 1);
    await tester.pump(const Duration(milliseconds: 300));
    expect(_left(tester), moreOrLessEquals(rest, epsilon: 0.5));
  });

  testWidgets('a card held before the wait is up is never leaned on', (
    tester,
  ) async {
    var hints = 0;
    await tester.pumpWidget(_deck(hint: true, onHint: () => hints++));
    await tester.pumpAndSettle();

    await _turn(tester);
    await tester.pump(const Duration(seconds: 2));
    final TestGesture finger = await tester.startGesture(
      tester.getCenter(find.byType(FlipCard).last),
    );
    await finger.moveBy(const Offset(-30, 0));
    await tester.pump(const Duration(seconds: 5));
    expect(hints, 0);
    await finger.moveBy(const Offset(30, 0));
    await finger.up();
    await tester.pumpAndSettle();
  });

  testWidgets('a reader who has sent a card on is never shown', (tester) async {
    var hints = 0;
    await tester.pumpWidget(_deck(hint: false, onHint: () => hints++));
    await tester.pumpAndSettle();

    await _turn(tester);
    await tester.pump(const Duration(seconds: 6));
    await _turn(tester);
    await tester.pump(const Duration(seconds: 2));
    expect(hints, 0);
  });

  testWidgets('on Today, the words sit beside the day\'s name until a card '
      'is sent on, and never come again', (tester) async {
    SharedPreferences.setMockInitialValues({
      'knowit.onboarded': true,
      'knowit.plus': false,
    });
    await tester.pumpWidget(const AstutoApp());
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    PillCardStack deck() => tester.widget(find.byType(PillCardStack));
    expect(deck().swipeHint, isTrue);
    expect(find.text('Swipe for the next one'), findsNothing);
    final Rect before = tester.getRect(find.byType(PillCardStack));

    // The deck says it has shown the way; the header says it in words.
    deck().onSwipeHint!();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Swipe for the next one'), findsOneWidget);
    // Beside the day's name, so nothing under it moves to make room.
    expect(tester.getRect(find.byType(PillCardStack)), before);
    expect(
      tester.getCenter(find.text('Swipe for the next one')).dy,
      moreOrLessEquals(
        tester
            .getCenter(
              find.descendant(
                of: find.byType(TodayScreen),
                matching: find.text('Today'),
              ),
            )
            .dy,
        epsilon: 2,
      ),
    );

    // Sent on: the words go, and the deck is not asked to show it again.
    final Rect deckRect = tester.getRect(find.byType(PillCardStack));
    await tester.flingFrom(
      Offset(deckRect.center.dx, deckRect.top + 90),
      const Offset(-320, 0),
      900,
    );
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('Swipe for the next one'), findsNothing);
    expect(deck().swipeHint, isFalse);
  });
}
