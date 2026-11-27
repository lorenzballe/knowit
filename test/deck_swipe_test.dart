// To the right is back, and a deck has no going back: a card swiped or
// flung to the right comes home, never skips on unread. To the left it goes.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/theme.dart';
import 'package:astuto/widgets/pill_card_stack.dart';

void main() {
  testWidgets('right comes home, left goes on', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final List<Pill> deck = PillBank.cards
        .where(
          (p) => !p.hasPage && p.challenge is NoChallenge && p.scene == null,
        )
        .take(2)
        .toList();
    int index = 0, advanced = 0;
    Widget host() => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: buildAstutoTheme(Brightness.dark),
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.fromLTRB(
            kDeckMargin,
            100,
            kDeckMargin,
            110,
          ),
          child: StatefulBuilder(
            builder: (context, setState) => PillCardStack(
              isSaved: (_) => false,
              onSave: (_) {},
              onShare: (_) {},
              deck: deck,
              index: index,
              onAdvance: () {
                advanced++;
                setState(() => index++);
              },
              answerFor: (_) => null,
              reviewIds: const {},
              onAnswer: (_, _, _, _) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();
    expect(find.text(deck[0].question), findsOneWidget);

    final Rect card = tester.getRect(find.byType(PillCardStack));
    // Carried far to the right, and flung there: home both times.
    await tester.dragFrom(card.center, const Offset(240, 10));
    await tester.pumpAndSettle();
    await tester.flingFrom(card.center, const Offset(200, -20), 1600);
    await tester.pumpAndSettle();
    expect(advanced, 0);
    expect(find.text(deck[0].question), findsOneWidget);

    // To the left: on to the next.
    await tester.flingFrom(card.center, const Offset(-240, 0), 1600);
    await tester.pumpAndSettle();
    expect(advanced, 1);
    expect(find.text(deck[1].question), findsOneWidget);
  });
}
