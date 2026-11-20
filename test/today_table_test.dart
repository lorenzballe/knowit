import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/data/pills_repository.dart';
import 'package:astuto/main.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/state/app_state.dart';
import 'package:astuto/widgets/pill_card_stack.dart';

/// The table the five are read on.
///
/// It takes a breath of the front card's colour, and the next card's as it
/// comes to the front.
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
}
