import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/pill.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/flip_card.dart';
import '../widgets/pill_card.dart';
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
/// One rule survives from the trainer: a graded card you have never answered
/// stays shut. Being able to read the answer here and then go and claim 90%
/// confidence on Today would quietly empty the calibration figures of any
/// meaning.
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
  late final PageController _controller = PageController(
    initialPage: widget.initialIndex,
  );

  /// One flag per card, and the state is fresh every time this screen opens —
  /// which is what makes the deck read as if it were the first time.
  late final List<bool> _flipped = List.filled(widget.deck.length, false);

  late int _index = widget.initialIndex;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Pill get _pill => widget.deck[_index];

  /// A card with nothing to score — a fact, or a debate — was never withheld
  /// in the first place. A graded one has to have been answered.
  bool _canOpen(Pill pill) =>
      !pill.asksSomething ||
      !pill.isGraded ||
      widget.app.answerFor(pill.id) != null;

  void _toggle(int i) {
    if (!_canOpen(widget.deck[i])) {
      HapticFeedback.vibrate();
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Answer this one on Today first.'),
            duration: Duration(seconds: 2),
          ),
        );
      return;
    }
    HapticFeedback.selectionClick();
    setState(() => _flipped[i] = !_flipped[i]);
  }

  String get _hint {
    if (!_canOpen(_pill)) return 'Answer this one on Today first';
    final hasNext = _index < widget.deck.length - 1;
    if (!_flipped[_index]) {
      // A fact already carries "Tap to reveal" on its own face. Repeating it
      // underneath teaches one gesture twice and the other not at all, so
      // that line goes to the swipe instead.
      if (!_pill.asksSomething && hasNext) return 'Swipe for the next one';
      return 'Tap for the answer';
    }
    return hasNext ? 'Swipe for the next one' : 'That was the last one';
  }

  @override
  Widget build(BuildContext context) {
    final saved = widget.app.isSaved(_pill.id);

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

            // The card takes everything left over, which is the point of
            // opening it on its own screen rather than under a tab bar.
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: widget.deck.length,
                onPageChanged: (i) {
                  HapticFeedback.selectionClick();
                  setState(() => _index = i);
                },
                itemBuilder: (context, i) {
                  final pill = widget.deck[i];
                  final label =
                      '${(i + 1).toString().padLeft(2, '0')} / '
                      '${widget.deck.length.toString().padLeft(2, '0')}';
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _toggle(i),
                      child: FlipCard(
                        showBack: _flipped[i],
                        front: PillCard(
                          pill: pill,
                          indexLabel: label,
                          flipped: false,
                          given: widget.app.answerFor(pill.id),
                        ),
                        back: PillCard(
                          pill: pill,
                          indexLabel: label,
                          flipped: true,
                          given: widget.app.answerFor(pill.id),
                        ),
                      ),
                    ),
                  );
                },
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
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _ViewerAction(
                    label: saved ? 'Remove from saved' : 'Save this pill',
                    icon: saved
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    tint: saved ? context.p.alert : context.p.ink,
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      widget.app.toggleSaved(_pill.id);
                      setState(() {});
                    },
                  ),
                  const SizedBox(width: 18),
                  _ViewerAction(
                    label: 'Share this pill',
                    icon: Icons.ios_share_rounded,
                    tint: context.p.ink,
                    onTap: () => showShareSheet(context, _pill),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ViewerAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color tint;
  final VoidCallback onTap;

  const _ViewerAction({
    required this.label,
    required this.icon,
    required this.tint,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: context.p.surfaceRaised,
            border: Border.all(color: context.p.line),
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 21, color: tint),
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
