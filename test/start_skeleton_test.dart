import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astuto/main.dart';
import 'package:astuto/screens/today_screen.dart';
import 'package:astuto/sync/served.dart';
import 'package:astuto/widgets/pill_card_stack.dart';
import 'package:astuto/widgets/web/web_card_face.dart';

void main() {
  tearDown(() => Served.useForTest(Served()));

  testWidgets('a reader opens on Today in grey at once, with no wheel, and '
      'the day lands where its outline stood', (tester) async {
    SharedPreferences.setMockInitialValues({'knowit.onboarded': true});
    // A server slow to answer: the day waits for it, then the phone deals.
    Served.useForTest(
      Served(
        storeOverride: MemoryServedStore()..slow = const Duration(seconds: 2),
        uidOverride: 'me',
        startWait: const Duration(milliseconds: 600),
      ),
    );
    await tester.pumpWidget(const AstutoApp());
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(TodaySkeleton), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    final Rect outline = tester.getRect(
      find.byKey(const ValueKey('deck-skeleton-card')),
    );

    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(TodaySkeleton), findsNothing);
    expect(find.byType(PillCardStack), findsOneWidget);
    final Rect card = tester.getRect(
      find.descendant(
        of: find.byType(PillCardStack),
        matching: find.byType(PageHold),
      ),
    );
    expect(card.left, closeTo(outline.left, 0.5));
    expect(card.top, closeTo(outline.top, 0.5));
    expect(card.width, closeTo(outline.width, 0.5));
    expect(card.height, closeTo(outline.height, 0.5));
  });

  testWidgets('a first open shows nothing of a Today it does not have', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const AstutoApp());
    await tester.pump(const Duration(milliseconds: 20));
    expect(find.byType(TodaySkeleton), findsNothing);
  });
}
