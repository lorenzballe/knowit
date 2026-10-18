import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/data/pills_repository.dart';
import 'package:astuto/main.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/screens/today_done_view.dart';
import 'package:astuto/widgets/magic_card.dart';
import 'package:astuto/widgets/pill_card_stack.dart';

/// Astute+ bought from the card after the fifth: Today shows the finished
/// day. It used to keep the deck "on the table" with no card on it, and
/// the reader who had just paid looked at a blank page until tomorrow.
void main() {
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  testWidgets('bought from the evening card, Today shows the shelf', (
    tester,
  ) async {
    final DateTime now = DateTime.now();
    final String yesterday = dateKey(now.subtract(const Duration(days: 1)));
    final List<String> five = PillBank.live
        .where((p) => p.challenge is NoChallenge && p.scene == null)
        .take(5)
        .map((p) => p.id)
        .toList();
    SharedPreferences.setMockInitialValues({
      'knowit.onboarded': true,
      'knowit.pushAsked': true,
      'knowit.todayDate': dateKey(now),
      'knowit.todayDeckIds': five,
      'knowit.todayIndex': 4,
      'knowit.streak': 1,
      'knowit.bestStreak': 1,
      'knowit.lastCompletionDate': yesterday,
      'knowit.completedDates': [yesterday],
      'knowit.seenIds': five.take(4).toList(),
    });
    await tester.pumpWidget(const AstutoApp());
    await settle(tester);

    // The fifth thrown: the card that offers the rest is on the table.
    final Rect deck = tester.getRect(find.byType(PillCardStack));
    await tester.flingFrom(
      Offset(deck.center.dx, deck.top + 90),
      const Offset(-320, 0),
      900,
    );
    await settle(tester);
    expect(find.byType(MagicCard), findsOneWidget);

    // The store says yes, as the paywall's purchase would.
    final app = tester.widget<AstutoRoot>(find.byType(AstutoRoot)).app;
    await app.applyEntitlement(true);
    await settle(tester);

    expect(find.byType(PillCardStack), findsNothing);
    expect(find.byType(TodayDoneView), findsOneWidget);
  });
}
