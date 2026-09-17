import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/widgets/pill_card.dart';
import 'package:astuto/widgets/pill_card_stack.dart';

/// A deck whose index arrives late, which is the condition the real app runs
/// under and the one the stutter needed.
///
/// `AppState.advance()` writes the new position, the cards read and the ids
/// seen to disk before it tells anyone, so on a phone the index lands several
/// frames after the card has gone. Under a test `SharedPreferences` answers
/// from a map in the same frame, which is exactly why driving the whole app
/// could never show this: the two changes coalesced and the bad frame was
/// never drawn. So the wait is made explicit here instead.
class _SlowDeck extends StatefulWidget {
  final List<Pill> deck;

  /// How long the parent sits on the new index — a stand-in for the writes.
  final Duration lag;

  const _SlowDeck({required this.deck, required this.lag});

  @override
  State<_SlowDeck> createState() => _SlowDeckState();
}

class _SlowDeckState extends State<_SlowDeck> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: PillCardStack(
          deck: widget.deck,
          index: index,
          onAdvance: () async {
            await Future<void>.delayed(widget.lag);
            if (mounted) setState(() => index += 1);
          },
          answering: false,
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
}

/// Where a card is actually painted. The transforms that move it live above
/// it, so its own box is the only honest witness to where a reader sees it.
Offset? _centreOf(WidgetTester tester, Pill pill) {
  final finder = find.byWidgetPredicate(
    (w) => w is PillCard && w.pill.id == pill.id,
  );
  if (finder.evaluate().isEmpty) return null;
  return tester.getCenter(finder.first);
}

/// Throws the top card off to the left, and stops at the moment the finger
/// leaves the glass.
Future<void> _throw(WidgetTester tester, Offset from) async {
  final gesture = await tester.startGesture(from);
  for (var i = 0; i < 6; i++) {
    await gesture.moveBy(const Offset(-26, 0));
    await tester.pump(const Duration(milliseconds: 16));
  }
  await gesture.up();
}

void main() {
  final List<Pill> deck = PillBank.cards.take(4).toList();

  testWidgets('a card thrown away does not come back while the next is on '
      'its way', (tester) async {
    await tester.pumpWidget(
      _SlowDeck(deck: deck, lag: const Duration(milliseconds: 200)),
    );
    await tester.pump();

    final Pill leaving = deck.first;
    final Offset atRest = _centreOf(tester, leaving)!;

    await _throw(tester, atRest);

    // Frame by frame from the throw until the card is gone from the tree.
    // It may travel as far as it likes; what it may not do is reappear in
    // the middle of the screen, which is what reads as the deck stuttering.
    var wentAway = false;
    double? cameBack;
    for (var frame = 0; frame < 120; frame++) {
      await tester.pump(const Duration(milliseconds: 16));
      final Offset? now = _centreOf(tester, leaving);
      if (now == null) break;
      final double travelled = (now.dx - atRest.dx).abs();
      if (travelled > 150) {
        wentAway = true;
      } else if (wentAway && travelled < 40) {
        cameBack = travelled;
        break;
      }
    }

    expect(wentAway, isTrue, reason: 'the throw should have carried it off');
    expect(
      cameBack,
      isNull,
      reason:
          'the card that left was drawn back ${cameBack?.round()}px from '
          'where it started, before the next one replaced it',
    );

    await tester.pumpAndSettle();
  });

  testWidgets('the card underneath rises once and does not drop back', (
    tester,
  ) async {
    await tester.pumpWidget(
      _SlowDeck(deck: deck, lag: const Duration(milliseconds: 200)),
    );
    await tester.pump();

    final Offset atRest = _centreOf(tester, deck[0])!;
    final Offset behind = _centreOf(tester, deck[1])!;
    // The card behind sits lower until it is the one being read.
    expect(behind.dy, greaterThan(atRest.dy));

    await _throw(tester, atRest);

    var highest = behind.dy;
    for (var frame = 0; frame < 120; frame++) {
      await tester.pump(const Duration(milliseconds: 16));
      final Offset? now = _centreOf(tester, deck[1]);
      if (now == null) continue;
      expect(
        now.dy,
        lessThanOrEqualTo(highest + 0.5),
        reason: 'the card underneath dropped back down on frame $frame',
      );
      if (now.dy < highest) highest = now.dy;
    }

    await tester.pumpAndSettle();
    expect(
      _centreOf(tester, deck[1])!.dy,
      closeTo(atRest.dy, 0.5),
      reason: 'it should have arrived exactly where the card it replaces sat',
    );
  });

  testWidgets('the card underneath is not rebuilt when it reaches the top', (
    tester,
  ) async {
    await tester.pumpWidget(
      _SlowDeck(deck: deck, lag: const Duration(milliseconds: 200)),
    );
    await tester.pump();

    Element elementOf(Pill pill) => tester.element(
      find.byWidgetPredicate((w) => w is PillCard && w.pill.id == pill.id),
    );

    final Element before = elementOf(deck[1]);

    await _throw(tester, _centreOf(tester, deck[0])!);
    // Frame by frame past the throw and past the lag the parent sits on, so
    // the deck has really landed. One long pump would jump the animation to
    // its end and leave the parent's wait still running.
    for (var i = 0; i < 60; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }

    // The card the reader is now looking at was already built and laid out
    // one layer down. Reusing its element means the frame the deck lands on
    // pays for a new transform and nothing else; building it again there
    // means laying out a whole card in the one frame that has to be smooth.
    expect(
      identical(elementOf(deck[1]), before),
      isTrue,
      reason:
          'the card underneath was torn down and built again on the frame it '
          'became the one being read',
    );
  });

  testWidgets('a deck that refuses to move on puts the card back', (
    tester,
  ) async {
    // The deck viewer wraps with `% length`, so a deck of one advances to
    // itself. The card must land back under the reader rather than stay
    // wherever the throw sent it.
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: PillCardStack(
            deck: deck,
            index: 0,
            onAdvance: () {},
            answering: false,
            reviewIds: const {},
            answerFor: (_) => null,
            onAnswer: (_, _, _, _) {},
            isSaved: (_) => false,
            onSave: (_) {},
            onShare: (_) {},
          ),
        ),
      ),
    );
    await tester.pump();

    final Offset atRest = _centreOf(tester, deck.first)!;
    await _throw(tester, atRest);
    await tester.pumpAndSettle();

    expect(_centreOf(tester, deck.first), atRest);
  });
}
