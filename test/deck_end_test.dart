import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/screens/deck_viewer_screen.dart';
import 'package:astuto/state/app_state.dart';
import 'package:astuto/theme.dart';
import 'package:astuto/widgets/pill_card_stack.dart';

/// A deck read again comes to an end: it used to go round, the last card
/// thrown bringing back the first with nothing to say the deck was done.
void main() {
  Future<AppState> freshApp() async {
    SharedPreferences.setMockInitialValues({'knowit.onboarded': true});
    final app = AppState();
    await app.init();
    return app;
  }

  /// Cards that turn over on a tap and ask nothing, so a throw is a throw.
  List<Pill> plain(int n) => PillBank.cards
      .where((p) => p.challenge is NoChallenge && p.scene == null)
      .take(n)
      .toList();

  /// A screen that opens the viewer, so closing it can be seen.
  Widget host(AppState app, List<Pill> deck) => MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    theme: buildAstutoTheme(Brightness.dark),
    home: Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: TextButton(
            key: const ValueKey('open'),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    DeckViewerScreen(app: app, deck: deck, title: 'Explore'),
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );

  Future<void> throwTop(WidgetTester tester) async {
    final Rect r = tester.getRect(find.byType(PillCardStack));
    await tester.flingFrom(
      Offset(r.center.dx, r.top + 90),
      const Offset(-320, 0),
      900,
    );
    await tester.pumpAndSettle();
  }

  testWidgets('the last card thrown brings the end, not the first card', (
    tester,
  ) async {
    final app = await freshApp();
    await tester.pumpWidget(host(app, plain(3)));
    await tester.tap(find.byKey(const ValueKey('open')));
    await tester.pumpAndSettle();

    expect(find.text('1/3'), findsOneWidget);
    expect(find.text('Swipe for the next one'), findsOneWidget);
    await throwTop(tester);
    await throwTop(tester);
    expect(find.text('3/3'), findsOneWidget);
    expect(find.text('The last one'), findsOneWidget);

    await throwTop(tester);
    // The end, on top: how many there were, and no count going round.
    expect(find.text("That's all three."), findsOneWidget);
    expect(find.text('1/3'), findsNothing);
    expect(find.text('3/3'), findsNothing);

    // Round again from the first, by choice.
    await tester.tap(find.byKey(const ValueKey('deck-end-again')));
    await tester.pumpAndSettle();
    expect(find.text('1/3'), findsOneWidget);
  });

  testWidgets('the end thrown, or closed, puts the deck down', (tester) async {
    final app = await freshApp();
    await tester.pumpWidget(host(app, plain(2)));
    await tester.tap(find.byKey(const ValueKey('open')));
    await tester.pumpAndSettle();
    await throwTop(tester);
    await throwTop(tester);
    expect(find.byType(DeckEnd), findsOneWidget);
    await throwTop(tester);
    expect(find.byType(DeckViewerScreen), findsNothing);

    await tester.tap(find.byKey(const ValueKey('open')));
    await tester.pumpAndSettle();
    await throwTop(tester);
    await throwTop(tester);
    await tester.tap(find.byKey(const ValueKey('deck-end-close')));
    await tester.pumpAndSettle();
    expect(find.byType(DeckViewerScreen), findsNothing);
  });

  testWidgets('one card, thrown, is put down', (tester) async {
    final app = await freshApp();
    await tester.pumpWidget(host(app, plain(1)));
    await tester.tap(find.byKey(const ValueKey('open')));
    await tester.pumpAndSettle();
    expect(find.text('That was the only one'), findsOneWidget);
    expect(find.byType(DeckEnd), findsNothing);
    await throwTop(tester);
    expect(find.byType(DeckViewerScreen), findsNothing);
  });
}
