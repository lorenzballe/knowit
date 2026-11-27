import 'package:flutter/material.dart';

import '../data/skill_levels.dart';
import '../l10n/l10n.dart';
import '../models/pill.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/pill_card_stack.dart';
import '../widgets/learn_looks.dart' show markedSkills, scoredSkills;
import '../widgets/share_sheet.dart';
import '../widgets/skill_score.dart' show todayMoveOf;

/// The one card the first run plays before its offer of the free trial,
/// when the server's switch `trial.firstRun` is on (lib/screens/
/// trial_offer.dart): a real card, the opening's best for this reader
/// ([AppState.firstRunCard]), on the deck Today deals from — answered
/// before it turns, turned, and thrown to go on, as every card is. A new
/// reader sees what Astute is before anything is offered to them.
///
/// It is read outside the day, as a card opened in Explore is
/// ([AppState.readFirstRunCard]): the five are dealt after the offer, and
/// never deal it again.
class FirstCardScreen extends StatefulWidget {
  const FirstCardScreen({
    super.key,
    required this.app,
    required this.card,
    required this.onDone,
  });

  final AppState app;

  /// The card to play.
  final Pill card;

  /// Called once the card has been thrown on and counted as read.
  final VoidCallback onDone;

  @override
  State<FirstCardScreen> createState() => _FirstCardScreenState();
}

class _FirstCardScreenState extends State<FirstCardScreen> {
  /// 0 while the card is on the table, 1 once it has been thrown: the
  /// table stays empty while the next step comes in.
  int _index = 0;

  /// True once the deck has shown how a card is sent on.
  bool _hinting = false;

  Future<void> _advance() async {
    if (_index > 0) return;
    setState(() => _index = 1);
    await widget.app.readFirstRunCard(widget.card.id);
    if (mounted) widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    final AppState app = widget.app;
    final Palette p = context.p;
    return Scaffold(
      backgroundColor: p.surface,
      body: SafeArea(
        child: Padding(
          // Today's own margins, so the card stands where the day's will.
          padding: const EdgeInsets.fromLTRB(kDeckMargin, 10, kDeckMargin, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Row(
                  children: [
                    Flexible(
                      flex: 3,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: AlignmentDirectional.centerStart,
                        child: Text(
                          context.l10n.firstCardTitle,
                          key: const ValueKey('first-card-title'),
                          maxLines: 1,
                          style: AppText.display(
                            size: 20,
                            weight: FontWeight.w600,
                            spacing: -0.4,
                            color: p.ink,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // How the card is sent on, said once, quietly, at the
                    // far end of the row, as Today says it on a first card.
                    Expanded(
                      flex: 2,
                      child: AnimatedOpacity(
                        opacity: _hinting ? 1 : 0,
                        duration: Duration(
                          milliseconds: MediaQuery.disableAnimationsOf(context)
                              ? 0
                              : 420,
                        ),
                        child: Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              context.l10n.firstCardSwipeOn,
                              key: const ValueKey('first-card-hint'),
                              maxLines: 1,
                              style: AppText.body(
                                size: 12.5,
                                weight: FontWeight.w500,
                                color: p.inkFaint,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: PillCardStack(
                  key: const ValueKey('first-card-deck'),
                  deck: [widget.card],
                  index: _index,
                  onAdvance: _advance,
                  // Every read is said as it ends, as a card read in the
                  // viewer is, where it was read.
                  onRead: (stint) => app.cardClosed(stint, where: 'first run'),
                  readBefore: (id) => app.seenIds.contains(id),
                  home: app.place,
                  reviewIds: const {},
                  answerFor: app.answerFor,
                  onAnswer: (id, response, confidence, reason) =>
                      app.recordAnswer(
                        id,
                        response,
                        confidence: confidence,
                        reason: reason,
                      ),
                  onReact: app.react,
                  isSaved: app.isSaved,
                  onSave: (pill) {
                    app.toggleSaved(pill.id);
                    setState(() {});
                  },
                  isLiked: app.isLiked,
                  onLike: (pill) {
                    app.toggleLiked(pill.id);
                    setState(() {});
                  },
                  onShare: (pill) => showShareSheet(context, pill),
                  skillOf: (pill) => skillMarkOf(pill, markedSkills(app)),
                  moveOf: (pill) => todayMoveOf(
                    app,
                    pill,
                    skillMarkOf(pill, scoredSkills(app)),
                  ),
                  // Nothing on the screen says how the card is sent on, so
                  // the card shows it, as Today's first card does.
                  swipeHint: true,
                  onSwipeHint: () {
                    if (mounted) setState(() => _hinting = true);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
