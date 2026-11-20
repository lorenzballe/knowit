import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/screens/drawing_screen.dart';
import 'package:astuto/widgets/diagram_view.dart';
import 'package:astuto/widgets/pill_card.dart';
import 'package:astuto/widgets/pill_card_stack.dart';

/// A card's drawing with the whole screen to itself.
///
/// The card stays a card. Once it is turned and its answer is out, a touch
/// on the diagram the answer is drawn with opens it over everything, on the
/// card's own colour, under the question it answers, drawn again from its
/// first stroke; the way back leaves the card as it was, still on its back.
/// Anywhere a diagram is not on a card in the deck, a touch plays it again
/// as it always did.
class _Deck extends StatefulWidget {
  const _Deck({super.key, required this.deck});

  final List<Pill> deck;

  @override
  State<_Deck> createState() => _DeckState();
}

class _DeckState extends State<_Deck> {
  int index = 0;

  @override
  Widget build(BuildContext context) => MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: PillCardStack(
        deck: widget.deck,
        index: index,
        onAdvance: () => setState(() => index++),
        reviewIds: const {},
        answerFor: (_) => null,
        onAnswer: (_, _, _, _) {},
        isSaved: (_) => false,
        onSave: (_) {},
        onShare: (_) {},
      ),
    ),
  );
}

void main() {
  setUp(PillBank.reset);

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 14; i++) {
      await tester.pump(const Duration(milliseconds: 80));
    }
  }

  void phone(WidgetTester tester) {
    tester.view.physicalSize = const Size(402, 874) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
  }

  Finder back() => find.byWidgetPredicate((w) => w is PillCard && w.flipped);
  final Finder onCard = find.byKey(const ValueKey('diagram'));
  final Finder large = find.byKey(const ValueKey('drawing-diagram'));

  /// Cards that only tell and carry a diagram: turned by a tap, with the
  /// picture on their back.
  List<Pill> drawn() => PillBank.live
      .where((p) => p.diagram != null && p.web == null && p.scene == null)
      .where((p) => p.challenge is NoChallenge)
      .toList();

  test('a card has a drawing to open when the app draws one, or the bank '
      'has its picture', () {
    final Pill plain = PillBank.live.firstWhere(
      (p) => p.diagram == null && p.web == null,
    );
    expect(DrawingScreen.has(plain), isFalse);
    expect(DrawingScreen.has(drawn().first), isTrue);
    final Pill pictured = PillBank.live.firstWhere(
      (p) => p.web?.thumbs?.back != null,
    );
    expect(DrawingScreen.has(pictured), isTrue);
  });

  testWidgets('a touch on the diagram of a card turned over opens it at '
      'full screen, and the way back leaves the card on its back', (
    tester,
  ) async {
    phone(tester);
    // The first whose back has the room to show its picture with its words
    // on this phone: a back short of room tucks the picture behind a line,
    // and that is another test's.
    Pill? card;
    for (final Pill p in drawn()) {
      await tester.pumpWidget(_Deck(key: ValueKey(p.id), deck: [p]));
      await settle(tester);
      await tester.tap(find.byType(PillCardStack));
      await settle(tester);
      if (onCard.evaluate().isNotEmpty) {
        card = p;
        break;
      }
    }
    expect(card, isNotNull, reason: 'a card that shows its diagram inline');
    expect(back(), findsOneWidget);
    expect(find.byType(DrawingScreen), findsNothing);

    final double onCardWide = tester.getSize(onCard).width;
    await tester.tap(onCard);
    await settle(tester);

    expect(find.byType(DrawingScreen), findsOneWidget);
    expect(large, findsOneWidget);
    // On the card's own colour, under the question it answers.
    final Scaffold screen = tester.widget<Scaffold>(
      find.descendant(
        of: find.byType(DrawingScreen),
        matching: find.byType(Scaffold),
      ),
    );
    expect(screen.backgroundColor, card!.color);
    expect(
      find.descendant(
        of: find.byType(DrawingScreen),
        matching: find.text(card.question),
      ),
      findsOneWidget,
    );
    // As wide as the screen takes it, which is wider than the card did.
    expect(tester.getSize(large).width, greaterThan(onCardWide));
    // There, a touch plays it again and opens nothing more.
    await tester.tap(large);
    await settle(tester);
    expect(find.byType(DrawingScreen), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('drawing-close')));
    await settle(tester);
    expect(find.byType(DrawingScreen), findsNothing);
    expect(back(), findsOneWidget);
    // Let the diagram's drawing and the card's own timers run out.
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('a diagram that is not on a card in the deck plays again at '
      'a touch, and opens nothing', (tester) async {
    final Pill card = drawn().first;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 320,
              child: DiagramView(diagram: card.diagram!, ink: card.ink),
            ),
          ),
        ),
      ),
    );
    await settle(tester);
    await tester.tap(find.byType(DiagramView));
    await settle(tester);
    expect(find.byType(DrawingScreen), findsNothing);
    await tester.pump(const Duration(seconds: 5));
  });
}
