import 'package:flutter/material.dart';

import '../books/player_room.dart';
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
import '../widgets/learn_looks.dart' show markedSkills, scoredSkills;
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

  /// False when the cards are answered again for the reader's own sake and
  /// nothing else: the week gone over from the journey (Review the week).
  /// Each card that asks is asked as [answering] asks it, its back says how
  /// this answer went, and the answer is forgotten when the viewer closes.
  /// The record never hears of it: a card's first answer stands, and so do
  /// its place on the review ladder, when it comes due, the score and how
  /// sure against how right. [AppState.recordAnswer] would not do: it drops
  /// a second answer to a card not yet due, and the back then shows the
  /// first; and it takes one to a card that is due, or was never answered,
  /// as that card's real answer, out of turn.
  final bool records;

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
    this.records = true,
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

  /// The cards marked as back again: of a deck to answer, those the reader
  /// had read or answered before the viewer opened. Cards that came due
  /// all were; a book's ideas, opened to be answered too, are new until
  /// they have been read, and its first idea is never "again" the first
  /// time. Taken once, so a card read here does not turn "again" while it
  /// is still on the table.
  ///
  /// None in a deck answered only for the reader ([records] false): every
  /// card in it was read before, and a mark on every card says nothing.
  late final Set<String> _again = widget.answering && widget.records
      ? {
          for (final Pill p in widget.deck)
            if (widget.app.seenIds.contains(p.id) ||
                widget.app.answerFor(p.id) != null)
              p.id,
        }
      : const {};

  /// What was answered here, by card, when the answers are not written
  /// down ([records] false): the back of each card says how it went, until
  /// the viewer closes or the deck starts again from the first.
  final Map<String, Answer> _here = {};

  /// The answer a card shows: the reader's own, from the record; or, in a
  /// deck answered only for the reader, the one given here, if any — never
  /// the first, which would turn the card over with its answer already in.
  Answer? _answerFor(String id) =>
      widget.records ? widget.app.answerFor(id) : _here[id];

  void _answer(String id, String response, int? confidence, String? reason) {
    if (!widget.records) {
      setState(
        () => _here[id] = Answer(
          response,
          confidence: confidence,
          reason: reason,
        ),
      );
      return;
    }
    widget.app.recordAnswer(
      id,
      response,
      confidence: confidence,
      reason: reason,
    );
  }

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
  void initState() {
    super.initState();
    // Cards fill the screen: a book read aloud keeps its small player out
    // of their way.
    BookPlayerRoom.cardsOpened();
  }

  @override
  void dispose() {
    BookPlayerRoom.cardsClosed();
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

  /// Whether the door under the card counts instead of the header: a card
  /// read on its own ("1/1" says nothing) whose path's door says where in
  /// the path it is. Wherever the header counts the cards being read, the
  /// door does not count its path as well: one count on the screen.
  bool get _doorCounts => _door != null && _total == 1;

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
                        _atEnd || _doorCounts ? '' : _count,
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
                            // Round again from the first: asked afresh.
                            onAgain: () => setState(() {
                              _index = 0;
                              _here.clear();
                            }),
                          )
                        : null,
                    reviewIds: _again,
                    answering: widget.answering,
                    answerFor: _answerFor,
                    onReact: widget.app.react,
                    onAnswer: _answer,
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
                    skillOf: (pill) =>
                        skillMarkOf(pill, markedSkills(widget.app)),
                    // The score the answer moved, beside its verdict: none,
                    // for an answer the record never hears of.
                    moveOf: widget.records
                        ? (pill) => todayMoveOf(
                            widget.app,
                            pill,
                            skillMarkOf(pill, scoredSkills(widget.app)),
                          )
                        : null,
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
                    place: _doorCounts,
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

/// The card after the last one: the deck as it was read, how many cards
/// there were, and the two ways on: put the deck down, or go round again
/// from the first. Thrown like any card, it puts the deck down.
///
/// A short deck shows a mark in each card's colour, in a row or two. A long
/// one, Explore's hundred and fifty, is told by its subjects instead: a
/// mark a card was a wall of colour in no order that pushed the words onto
/// the buttons, so it is one bar, the subjects the most read first, and
/// the first few of them named with their counts.
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

  /// Up to this many cards, a mark each: two rows at most on any phone.
  static const int marksUpTo = 20;

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
          if (deck.length <= marksUpTo)
            // The deck, read: one mark in each card's colour.
            ExcludeSemantics(
              key: const ValueKey('deck-end-marks'),
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
          Semantics(
            header: true,
            child: Padding(
              padding: EdgeInsets.only(top: deck.length <= marksUpTo ? 22 : 0),
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
          ),
          if (deck.length > marksUpTo) ...[
            const SizedBox(height: 22),
            DeckSubjects(deck: deck),
          ],
          const Spacer(),
          const SizedBox(height: 20),
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

/// A long deck by its subjects: one bar in their colours, each as wide as
/// its share of the deck, the most read first; under it the first [named]
/// of them with how many cards each, and how many more there were.
class DeckSubjects extends StatelessWidget {
  const DeckSubjects({super.key, required this.deck});

  final List<Pill> deck;

  /// The subjects named under the bar.
  static const int named = 4;

  /// The deck's subjects, the most cards first, then in the order first met.
  static List<({String topic, Color color, int count})> of(List<Pill> deck) {
    final Map<String, ({Color color, int count, int first})> by = {};
    for (final (int i, Pill pill) in deck.indexed) {
      final mark = by[pill.topic];
      by[pill.topic] = mark == null
          ? (color: pill.color, count: 1, first: i)
          : (color: mark.color, count: mark.count + 1, first: mark.first);
    }
    final List<MapEntry<String, ({Color color, int count, int first})>> rows =
        by.entries.toList()..sort((a, b) {
          final int byCount = b.value.count.compareTo(a.value.count);
          return byCount != 0
              ? byCount
              : a.value.first.compareTo(b.value.first);
        });
    return [
      for (final e in rows)
        (topic: e.key, color: e.value.color, count: e.value.count),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final Palette p = context.p;
    final l = context.l10n;
    final rows = of(deck);
    final TextStyle line = AppText.body(
      size: 15,
      weight: FontWeight.w600,
      height: 1.25,
      color: p.ink,
    );
    return Semantics(
      key: const ValueKey('deck-end-subjects'),
      label: [
        for (final r in rows.take(named)) '${l.subjectOf(r.topic)} ${r.count}',
        if (rows.length > named) l.trainingMore(rows.length - named),
      ].join(', '),
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: SizedBox(
              height: 10,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // The named subjects in their colours; the rest, which
                  // the line under the names counts, as one quiet stretch.
                  for (final (int i, r) in rows.take(named).indexed) ...[
                    if (i > 0) const SizedBox(width: 2),
                    Expanded(
                      flex: r.count,
                      child: ColoredBox(color: r.color),
                    ),
                  ],
                  if (rows.length > named) ...[
                    const SizedBox(width: 2),
                    Expanded(
                      flex: rows.skip(named).fold(0, (int n, r) => n + r.count),
                      child: ColoredBox(color: p.lineStrong),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          for (final r in rows.take(named))
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: r.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l.subjectOf(r.topic),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: line,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${r.count}',
                    style: line.copyWith(
                      color: p.inkMuted,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
          if (rows.length > named)
            Text(
              l.trainingMore(rows.length - named),
              style: AppText.body(size: 13.5, height: 1.3, color: p.inkFaint),
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
