import 'package:flutter/material.dart';

import '../data/skill_levels.dart';
import '../l10n/l10n.dart';

import '../models/pill.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/fit_text.dart';
import '../widgets/ui.dart';
import '../widgets/pill_card_stack.dart';
import '../widgets/path_door.dart';
import '../widgets/share_sheet.dart';
import '../widgets/skill_mark.dart';
import '../widgets/skill_score.dart' show todayMoveOf;
import '../widgets/glass_round.dart';

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

  /// True when these cards are back to be answered again — the ones that
  /// came due — rather than read back. Then a card that asks holds its
  /// answer until the reader commits, the way it did the first time.
  final bool answering;

  /// True when these are cards nobody dealt the reader — Explore's — so a
  /// card turned past, or the one open when the viewer closes, counts as
  /// read (see [AppState.markReadElsewhere]).
  final bool countsAsRead;

  /// Where the cards were opened from, as their 'card closed' says it:
  /// `explore`, `came back`, `journey`, `widget`.
  final String source;

  /// How many cards the set these are from holds, when it is more than
  /// [deck]: a path's free cards are two of ten, and the count says so.
  final int? of;

  /// The card after the last one, in place of the one that says the deck
  /// is done: a path's free cards end on the rest of the path.
  final Widget? end;

  const DeckViewerScreen({
    super.key,
    required this.app,
    required this.deck,
    required this.title,
    this.initialIndex = 0,
    this.answering = false,
    this.countsAsRead = false,
    this.source = 'viewer',
    this.of,
    this.end,
  });

  @override
  State<DeckViewerScreen> createState() => _DeckViewerScreenState();
}

class _DeckViewerScreenState extends State<DeckViewerScreen> {
  late int _index = widget.initialIndex;

  /// Past the last card: the card that says the deck is done is on top.
  bool get _atEnd => _index >= widget.deck.length;

  void _read(int index) {
    if (!widget.countsAsRead || index >= widget.deck.length) return;
    widget.app.markReadElsewhere(widget.deck[index].id);
  }

  /// The deck moves on. It used to go round: the eighth card thrown
  /// brought back the first, with nothing to say the deck had been read,
  /// and a reader who missed the counter went round again thinking the
  /// cards were new. A deck of several ends on a card that says it is
  /// done; one card, thrown, is simply put down.
  void _advance() {
    _read(_index);
    if (_atEnd || (widget.deck.length == 1 && widget.end == null)) {
      // Past everything the deck holds, so the table stays empty while the
      // screen goes, rather than the thrown card coming back to wave.
      setState(() => _index = widget.deck.length + 1);
      Navigator.of(context).maybePop();
      return;
    }
    setState(() => _index += 1);
  }

  @override
  void dispose() {
    // The card open when the viewer closes was read too: most visits from
    // Explore are one card, opened, turned over and closed.
    _read(_index);
    super.dispose();
  }

  /// Which face is showing now lives inside the deck, so the line under it
  /// no longer tries to say — it names the gesture the card does not already
  /// carry on its own face.
  ///
  /// A card with a drawing, read again, starts as it started the first
  /// time — its question, to be played again — and its page cannot say
  /// what was answered then. So the line says it instead: right or wrong,
  /// the first time. A card in words says it on its own back.
  String get _hint {
    if (_atEnd) return '';
    final Pill pill = widget.deck[_index];
    final Answer? given = widget.answering
        ? null
        : widget.app.answerFor(pill.id);
    if (given != null && pill.hasPage && pill.isGraded) {
      return pill.challenge.accepts(given.response)
          ? context.l10n.rereadRight
          : context.l10n.rereadWrong;
    }
    return widget.deck.length == 1
        ? context.l10n.thatWasTheOnlyOne
        : _index == widget.deck.length - 1 && _total == widget.deck.length
        ? context.l10n.lastOne
        : context.l10n.swipeForTheNextOne;
  }

  int get _total => widget.of ?? widget.deck.length;

  /// The card whose path's door is under it: the one open, when the deck is
  /// Explore's and the card is in a path.
  Pill? get _door {
    if (_atEnd || _index >= widget.deck.length) return null;
    if (!widget.source.startsWith('explore')) return null;
    final Pill pill = widget.deck[_index];
    return pathOfCard(pill) == null ? null : pill;
  }

  /// Where the reader is in the deck, as the header says it.
  String get _count => '${_index + 1}/$_total';

  TextStyle _countStyle(BuildContext context) => AppText.body(
    size: 13.5,
    weight: FontWeight.w600,
    color: context.p.inkMuted,
  ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]);

  /// How wide each side of the header is: the way out's 44, or the count's
  /// own width where a deck of hundreds needs more.
  double _side(BuildContext context) {
    final TextPainter t = TextPainter(
      text: TextSpan(text: '$_total/$_total', style: _countStyle(context)),
      textDirection: TextDirection.ltr,
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    final double width = t.width;
    t.dispose();
    return width + 2 > 44 ? width + 2 : 44;
  }

  @override
  Widget build(BuildContext context) {
    return ScreenView(
      name: 'deck viewer',
      child: Scaffold(
        backgroundColor: context.p.surface,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(15, 3, 15, 0),
                child: Row(
                  children: [
                    // A ring of 38, in a target a finger finds: 44.
                    SizedBox(
                      width: _side(context),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: GlassRound(
                          symbol: GlassRound.close,
                          label: MaterialLocalizations.of(context)
                              .closeButtonTooltip,
                          onPressed: () => Navigator.of(context).pop(),
                          size: 44,
                          iconSize: 17,
                          fallback: Semantics(
                            button: true,
                            label: MaterialLocalizations.of(context)
                                .closeButtonTooltip,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => Navigator.of(context).pop(),
                              child: SizedBox(
                                width: 44,
                                height: 44,
                                child: Center(
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
                            ),
                          ),
                        ),
                      ),
                    ),
                    // The screen's name — Today, Explore, the subject —
                    // as a title, at the size Today's own is set, not a
                    // caption: at sixteen it read as small print over a
                    // card twenty times its size. A long subject in a long
                    // language gives way by a point or two, never cut.
                    Expanded(
                      child: Semantics(
                        header: true,
                        child: FitText(
                          widget.title,
                          key: const ValueKey('viewer-title'),
                          maxLines: 1,
                          minSize: 16,
                          textAlign: TextAlign.center,
                          style: AppText.display(
                            size: 25,
                            weight: FontWeight.w600,
                            spacing: -0.6,
                            height: 1.1,
                            color: context.p.ink,
                          ),
                        ),
                      ),
                    ),
                    // Where the reader is, on one line however many cards
                    // the deck holds ("163/165"): as wide as it needs, the
                    // way out on the left taking as much, so the title
                    // stays in the middle.
                    SizedBox(
                      width: _side(context),
                      child: Text(
                        _atEnd ? '' : _count,
                        textAlign: TextAlign.right,
                        maxLines: 1,
                        softWrap: false,
                        style: _countStyle(context),
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
                // The same margin Today gives it. Without this the viewer
                // handed the deck the whole window, so a re-read card came out
                // wider than the one dealt — and, being held to a proportion,
                // taller with it.
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: kDeckMargin),
                  child: PillCardStack(
                    deck: widget.deck,
                    index: _index,
                    // Every card read here is said once per stint, however
                    // it left: thrown on, or still open when the viewer
                    // closed.
                    onRead: (stint) =>
                        widget.app.cardClosed(stint, where: widget.source),
                    readBefore: (id) => widget.app.seenIds.contains(id),
                    home: widget.app.place,
                    onAdvance: _advance,
                    trailing: widget.end != null
                        ? widget.end!
                        : widget.deck.length > 1
                        ? DeckEnd(
                            key: const ValueKey('deck-end'),
                            deck: widget.deck,
                            onClose: () => Navigator.of(context).maybePop(),
                            onAgain: () => setState(() => _index = 0),
                          )
                        : null,
                    reviewIds: widget.answering
                        ? {for (final p in widget.deck) p.id}
                        : const {},
                    answering: widget.answering,
                    answerFor: widget.app.answerFor,
                    onReact: widget.app.react,
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
                    isLiked: widget.app.isLiked,
                    onLike: (pill) {
                      widget.app.toggleLiked(pill.id);
                      setState(() {});
                    },
                    onShare: (pill) => showShareSheet(context, pill),
                    skillOf: (pill) => skillMarkOf(pill, widget.app.skills),
                    // The score the answer moved, beside its verdict.
                    moveOf: (pill) => todayMoveOf(
                      widget.app,
                      pill,
                      skillMarkOf(pill, widget.app.skills),
                    ),
                    onSkill: (pill, skill) => showSkillMarkSheet(
                      context,
                      widget.app,
                      skill,
                      cardId: pill.id,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),
              // A card read from Explore that belongs to a path has, in place
              // of the line about the gesture, the door to the path (A5).
              if (_door case final Pill pill)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: PathDoor(
                    key: ValueKey('path-door-${pill.id}'),
                    app: widget.app,
                    pill: pill,
                  ),
                )
              else
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
      ),
    );
  }
}

/// The card after the last one: the deck's colours in a row, how many
/// there were, and the two ways on — put the deck down, or go round again
/// from the first. Thrown like any card, it puts the deck down.
class DeckEnd extends StatelessWidget {
  const DeckEnd({
    super.key,
    required this.deck,
    required this.onClose,
    required this.onAgain,
  });

  final List<Pill> deck;
  final VoidCallback onClose;
  final VoidCallback onAgain;

  @override
  Widget build(BuildContext context) {
    final Palette p = context.p;
    final String title = context.l10n.deckEndTitle(
      context.l10n.countWord('${deck.length}'),
    );
    return Container(
      decoration: BoxDecoration(
        color: p.surfaceRaised,
        borderRadius: BorderRadius.circular(34),
        border: Border.all(color: p.line),
      ),
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(),
          // The deck, read: one mark in each card's colour.
          ExcludeSemantics(
            child: Wrap(
              spacing: 5,
              runSpacing: 5,
              children: [
                for (final Pill pill in deck)
                  Container(
                    width: 22,
                    height: 30,
                    decoration: BoxDecoration(
                      color: pill.color,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: p.line, width: 0),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Semantics(
            header: true,
            child: Text(
              title,
              style: AppText.display(
                size: 30,
                weight: FontWeight.w600,
                height: 1.08,
                spacing: -0.9,
                color: p.ink,
              ),
            ),
          ),
          const Spacer(),
          PrimaryButton(
            key: const ValueKey('deck-end-close'),
            label: MaterialLocalizations.of(context).closeButtonLabel,
            onPressed: onClose,
          ),
          const SizedBox(height: 4),
          Semantics(
            button: true,
            child: QuietButton(
              key: const ValueKey('deck-end-again'),
              label: context.l10n.deckEndAgain,
              onPressed: onAgain,
            ),
          ),
        ],
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
  bool countsAsRead = false,
  String source = 'viewer',
}) {
  return Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => DeckViewerScreen(
        app: app,
        deck: deck,
        title: title,
        initialIndex: initialIndex,
        countsAsRead: countsAsRead,
        source: source,
      ),
    ),
  );
}
