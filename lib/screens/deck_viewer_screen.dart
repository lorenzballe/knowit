import 'package:flutter/material.dart';

import '../models/pill.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/pill_card_stack.dart';
import '../widgets/share_sheet.dart';

/// A full-screen re-read of a set of cards.
///
/// This is not the trainer. The deck on Today asks you to commit before it
/// turns anything over, and that commitment is what the whole record rests
/// on. Here every card starts face down again and turns on a tap, because
/// coming back to five cards you have already worked through is reading, not
/// answering — and re-reading is the thing a person actually does with a card
/// they liked.
///
/// Every card opens, including ones that were skipped rather than answered.
/// Withholding those made the re-read useless — most of a deck somebody
/// clicked through is unanswered — and it never closed the hole it was for:
/// the deck already lets a card be passed without committing, and a finished
/// day cannot be gone back and answered anyway. Commitment is enforced where
/// it means something, on the card itself, the first time it is dealt.
class DeckViewerScreen extends StatefulWidget {
  final AppState app;
  final List<Pill> deck;
  final String title;
  final int initialIndex;

  const DeckViewerScreen({
    super.key,
    required this.app,
    required this.deck,
    required this.title,
    this.initialIndex = 0,
  });

  @override
  State<DeckViewerScreen> createState() => _DeckViewerScreenState();
}

class _DeckViewerScreenState extends State<DeckViewerScreen> {
  late int _index = widget.initialIndex;

  /// Which face is showing now lives inside the deck, so the line under it
  /// no longer tries to say — it names the gesture the card does not already
  /// carry on its own face.
  String get _hint => widget.deck.length > 1
      ? 'Swipe for the next one'
      : 'That was the only one';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.p.surface,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 6, 18, 0),
              child: Row(
                children: [
                  Semantics(
                    button: true,
                    label: 'Close',
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: context.p.line),
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: context.p.ink,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      widget.title,
                      textAlign: TextAlign.center,
                      style: AppText.display(
                        size: 16,
                        weight: FontWeight.w600,
                        spacing: -0.3,
                        color: context.p.ink,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 38,
                    child: Text(
                      '${_index + 1}/${widget.deck.length}',
                      textAlign: TextAlign.right,
                      style: AppText.label(
                        size: 11.5,
                        color: context.p.inkFaint,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // The same deck Today uses, not a second way of drawing a
            // card. A re-read that looks unlike the day it is re-reading is
            // two designs for one thing.
            Expanded(
              child: PillCardStack(
                deck: widget.deck,
                index: _index,
                onAdvance: () =>
                    setState(() => _index = (_index + 1) % widget.deck.length),
                reviewIds: const {},
                answering: false,
                answerFor: widget.app.answerFor,
                onAnswer: (id, response, confidence, reason) =>
                    widget.app.recordAnswer(
                      id,
                      response,
                      confidence: confidence,
                      reason: reason,
                    ),
                isSaved: widget.app.isSaved,
                onSave: (pill) {
                  widget.app.toggleSaved(pill.id);
                  setState(() {});
                },
                onShare: (pill) => showShareSheet(context, pill),
              ),
            ),

            const SizedBox(height: 12),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              child: Text(
                _hint,
                key: ValueKey(_hint),
                style: AppText.body(
                  size: 12.5,
                  weight: FontWeight.w500,
                  color: context.p.inkFaint,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Opens a set of cards full screen, face down.
///
/// A route rather than a tab, so the card gets the whole window with no tab
/// bar under it.
Future<void> openDeckViewer(
  BuildContext context,
  AppState app,
  List<Pill> deck,
  String title, {
  int initialIndex = 0,
}) {
  return Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => DeckViewerScreen(
        app: app,
        deck: deck,
        title: title,
        initialIndex: initialIndex,
      ),
    ),
  );
}
