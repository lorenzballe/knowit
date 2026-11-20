import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/data/pills_repository.dart';
import 'package:astuto/main.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/screens/today_done_view.dart';
import 'package:astuto/state/app_state.dart';
import 'package:astuto/widgets/magic_card.dart';
import 'package:astuto/widgets/pill_card_stack.dart';

/// The table the five are read on.
///
/// It takes a breath of the front card's colour, and the next card's as it
/// comes to the front. And once the day is under way — from the first card
/// sent on — the tab bar keeps out of the way of the cards that are left and
/// the deck has the room it held: never at the start, where the app opens
/// with its three tabs in sight, and never past the shelf. Called back from
/// the header, the bar lies over the foot of the deck for a few seconds and
/// goes; the deck does not move for it.
void main() {
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 16; i++) {
      await tester.pump(const Duration(milliseconds: 90));
    }
  }

  /// Five cards that only tell, of five colours where the bank has them, so
  /// a throw is a throw and the table has a colour to change to.
  List<Pill> five() {
    final List<Pill> plain = PillBank.live
        .where((p) => p.challenge is NoChallenge && p.scene == null)
        .where((p) => p.web == null)
        .toList();
    final List<Pill> picked = [];
    for (final Pill p in plain) {
      if (picked.every((q) => q.color != p.color)) picked.add(p);
      if (picked.length == 5) break;
    }
    return picked;
  }

  /// The app opened on a phone with a home indicator, on a day whose five
  /// are [deck], [read] of them already sent on before this start.
  Future<AppState> open(
    WidgetTester tester,
    List<Pill> deck, {
    int read = 0,
    Size phone = const Size(402, 874),
    double foot = 34,
  }) async {
    tester.view.physicalSize = phone * 3;
    tester.view.devicePixelRatio = 3;
    tester.view.padding = FakeViewPadding(top: 59 * 3, bottom: foot * 3);
    tester.view.viewPadding = FakeViewPadding(top: 59 * 3, bottom: foot * 3);
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({
      'knowit.onboarded': true,
      'knowit.pushAsked': true,
      'knowit.todayDate': dateKey(DateTime.now()),
      'knowit.todayDeckIds': [for (final Pill p in deck) p.id],
      'knowit.todayIndex': read,
      'knowit.seenIds': [for (final Pill p in deck.take(read)) p.id],
    });
    await tester.pumpWidget(const AstutoApp());
    await settle(tester);
    return tester.widget<AstutoRoot>(find.byType(AstutoRoot)).app;
  }

  Future<void> sendOn(WidgetTester tester) async {
    final Rect deck = tester.getRect(find.byType(PillCardStack));
    await tester.flingFrom(
      Offset(deck.center.dx, deck.top + 90),
      const Offset(-320, 0),
      900,
    );
    await settle(tester);
  }

  /// The colour the table is washed with, as it is heading.
  Color? tint(WidgetTester tester) => tester
      .widget<TweenAnimationBuilder<Color?>>(
        find.byKey(const ValueKey('table-tint')),
      )
      .tween
      .end;

  /// Whether the tab bar is in sight, and can be pressed.
  bool barShown(WidgetTester tester) {
    final Finder bar = find.ancestor(
      of: find.byKey(const ValueKey('tab-Explore')),
      matching: find.byType(AnimatedOpacity),
    );
    return tester.widget<AnimatedOpacity>(bar.first).opacity == 1;
  }

  final Finder tabsAside = find.byKey(const ValueKey('tabs-aside'));
  final Finder head = find.byKey(const ValueKey('today-head'));

  double deckHeight(WidgetTester tester) =>
      tester.getSize(find.byType(PillCardStack)).height;

  setUp(PillBank.reset);

  testWidgets('the table takes the colour of the card in front', (
    tester,
  ) async {
    final List<Pill> deck = five();
    expect(deck, hasLength(5), reason: 'five plain cards of five colours');
    await open(tester, deck);

    expect(tint(tester), deck[0].color);

    await sendOn(tester);
    expect(tint(tester), deck[1].color);
    expect(deck[1].color, isNot(deck[0].color));
  });

  testWidgets('the bar is in its place until the first card is sent on', (
    tester,
  ) async {
    final List<Pill> deck = five();
    await open(tester, deck);

    // The app opens with its tabs in sight, and nothing in the header.
    expect(barShown(tester), isTrue);
    expect(tabsAside, findsNothing);
    final double before = deckHeight(tester);
    final double headWas = tester.getSize(head).height;
    final double headTop = tester.getTopLeft(head).dy;

    // A card held and put back is not a card sent on.
    final TestGesture held = await tester.startGesture(
      tester.getCenter(find.byType(PillCardStack)),
    );
    await held.moveBy(const Offset(-30, 0));
    await tester.pump(const Duration(milliseconds: 60));
    await held.up();
    await settle(tester);
    expect(barShown(tester), isTrue);
    expect(deckHeight(tester), before);

    await sendOn(tester);

    // The day is under way: the bar is aside, the tabs stand small in the
    // header, and the deck has the bar's room, down to what the bar itself
    // kept under it (22 on a phone with a home indicator of 34).
    expect(barShown(tester), isFalse);
    expect(tabsAside, findsOneWidget);
    expect(deckHeight(tester), before + 64 + 4);
    // The header is where it was and as tall: only the deck's foot moved.
    expect(tester.getSize(head).height, headWas);
    expect(tester.getTopLeft(head).dy, headTop);

    // And it stays aside between cards.
    await sendOn(tester);
    expect(barShown(tester), isFalse);
    expect(deckHeight(tester), before + 64 + 4);
  });

  testWidgets('a phone with no home indicator gives the deck the same room', (
    tester,
  ) async {
    final List<Pill> deck = five();
    await open(tester, deck, phone: const Size(375, 667), foot: 0);
    final double before = deckHeight(tester);
    await sendOn(tester);
    expect(barShown(tester), isFalse);
    expect(deckHeight(tester), before + 64 + 4);
  });

  testWidgets('called back from the header, the bar stays a moment and goes', (
    tester,
  ) async {
    final List<Pill> deck = five();
    await open(tester, deck);
    await sendOn(tester);
    final double tall = deckHeight(tester);
    expect(barShown(tester), isFalse);

    // A tap on the header calls it back, over the deck: the deck is not
    // made to move for it.
    await tester.tap(head);
    await settle(tester);
    expect(barShown(tester), isTrue);
    expect(deckHeight(tester), tall);

    // Left alone, it steps aside again.
    await tester.pump(const Duration(seconds: 6));
    await settle(tester);
    expect(barShown(tester), isFalse);

    // Called back and used: Explore, with the bar in its place there.
    await tester.tap(head);
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('tab-Explore')));
    await settle(tester);
    expect(barShown(tester), isTrue);

    // Back on Today the day is still under way, and the bar aside.
    await tester.tap(find.byKey(const ValueKey('tab-Today')));
    await settle(tester);
    expect(barShown(tester), isFalse);
    expect(tabsAside, findsOneWidget);
    expect(deckHeight(tester), tall);

    // A second tap on the header sends a called bar away.
    await tester.tap(head);
    await settle(tester);
    expect(barShown(tester), isTrue);
    await tester.tap(head);
    await settle(tester);
    expect(barShown(tester), isFalse);

    // And a card taken under the finger does too.
    await tester.tap(head);
    await settle(tester);
    expect(barShown(tester), isTrue);
    await sendOn(tester);
    expect(barShown(tester), isFalse);
  });

  testWidgets('a screen reader is told the tabs by name', (tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    final List<Pill> deck = five();
    await open(tester, deck);
    await sendOn(tester);
    expect(
      tester.getSemantics(tabsAside),
      matchesSemantics(
        label: 'Today, Explore, Profile',
        isButton: true,
        hasTapAction: true,
      ),
    );
    handle.dispose();
  });

  testWidgets('the day done, the bar is back in its place', (tester) async {
    final List<Pill> deck = five();
    await open(tester, deck, read: 3);

    // An app opened part way through the day opens with its bar.
    expect(barShown(tester), isTrue);
    expect(tabsAside, findsNothing);

    await sendOn(tester);
    expect(barShown(tester), isFalse);
    await sendOn(tester);
    // The card after the fifth is on the table, and the bar still aside.
    expect(find.byType(MagicCard), findsOneWidget);
    expect(barShown(tester), isFalse);

    await sendOn(tester);
    expect(find.byType(TodayDoneView), findsOneWidget);
    expect(barShown(tester), isTrue);
    expect(tabsAside, findsNothing);
  });
}
