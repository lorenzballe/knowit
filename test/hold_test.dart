import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/theme.dart';
import 'package:astuto/widgets/pill_card_stack.dart';

/// Holding a card to like it behaves the same on its back as on its front:
/// the mark comes up while the finger is down and goes when it lifts.
void main() {
  final fact = PillBank.cards.firstWhere((p) => p.challenge is NoChallenge);

  Widget host(Set<String> liked) => MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    theme: buildAstutoTheme(Brightness.dark),
    home: Scaffold(
      body: SizedBox(
        height: 640,
        child: StatefulBuilder(
          builder: (context, set) => PillCardStack(
            isSaved: (_) => false,
            onSave: (_) {},
            onShare: (_) {},
            isLiked: liked.contains,
            onLike: (p) => set(() {
              if (!liked.remove(p.id)) liked.add(p.id);
            }),
            deck: [fact],
            index: 0,
            onAdvance: () {},
            answerFor: (_) => null,
            reviewIds: const {},
            onAnswer: (_, _, _, _) {},
          ),
        ),
      ),
    ),
  );

  final heart = find.byWidgetPredicate(
    (w) =>
        w is Icon &&
        (w.icon == Icons.favorite_border_rounded ||
            w.icon == Icons.favorite_rounded),
  );

  Future<void> turnOver(WidgetTester tester) async {
    await tester.tap(find.text('Tap to reveal'));
    await tester.pumpAndSettle();
    expect(find.text('WHAT TO KEEP'), findsOneWidget);
  }

  testWidgets('on the back, a hold that turns into a scroll leaves no mark', (
    tester,
  ) async {
    await tester.pumpWidget(host({}));
    await tester.pumpAndSettle();
    await turnOver(tester);

    final at = tester.getCenter(find.text('WHAT TO KEEP'));
    final g = await tester.startGesture(at);
    for (var f = 0; f < 5; f++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(heart, findsOneWidget, reason: 'the hold has begun');
    await g.moveBy(const Offset(0, -40));
    await tester.pump(const Duration(milliseconds: 50));
    await g.moveBy(const Offset(0, -40));
    await tester.pumpAndSettle();
    await g.up();
    await tester.pumpAndSettle();
    expect(heart, findsNothing, reason: 'the mark must unwind');
  });

  testWidgets('on the back, a full hold likes it and the mark goes', (
    tester,
  ) async {
    final liked = <String>{};
    await tester.pumpWidget(host(liked));
    await tester.pumpAndSettle();
    await turnOver(tester);

    final g = await tester.startGesture(
      tester.getCenter(find.text('WHAT TO KEEP')),
    );
    for (var f = 0; f < 9; f++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await g.up();
    await tester.pumpAndSettle();
    expect(liked, contains(fact.id));
    expect(heart, findsNothing);
  });
}
