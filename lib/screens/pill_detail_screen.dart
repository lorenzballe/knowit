import 'package:flutter/material.dart';

import '../books/player_room.dart';
import '../l10n/l10n.dart';

import '../models/pill.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/card_note.dart';
import '../widgets/reveal_body.dart';
import '../widgets/share_sheet.dart';
import '../widgets/card_edge.dart';
import '../widgets/top_edge.dart' show SoftTop;
import '../widgets/ui.dart';
import '../data/topics.dart';
import '../widgets/web/card_thumb.dart';
import '../widgets/web/web_card_page.dart' show groundOf;
import 'deck_viewer_screen.dart';
import '../analytics.dart';

/// A single pill opened out of the archive or the saved list: the whole thing
/// at once, no flip needed.
///
/// At its head, the card. A card with a drawing shows its drawing, as its
/// picture, and plays again at full size on a tap: the drawing is the card,
/// and a page of its words alone, under its question in a plain box, was a
/// card with its drawing gone. A card in words opens the same way, to be
/// turned over again.
///
/// Opened among others — a shelf, a day of the archive, a search, a week's
/// misses — the cards beside it are a swipe away, in the order they were
/// shown there: going back out and in again for each was the way through a
/// shelf, one card at a time.
class PillDetailScreen extends StatefulWidget {
  final Pill pill;
  final AppState app;

  /// The cards [pill] was opened among, in the order shown there, itself
  /// included. Empty, or without it, the page is the one card.
  final List<Pill> among;

  const PillDetailScreen({
    super.key,
    required this.pill,
    required this.app,
    this.among = const [],
  });

  @override
  State<PillDetailScreen> createState() => _PillDetailScreenState();
}

class _PillDetailScreenState extends State<PillDetailScreen> {
  /// The cards turned through, and which is open.
  late final List<Pill> _cards = widget.among.any((p) => p.id == widget.pill.id)
      ? List.of(widget.among)
      : [widget.pill];
  late int _at = _cards.indexWhere((p) => p.id == widget.pill.id);
  late final PageController _pages = PageController(initialPage: _at);

  @override
  void initState() {
    super.initState();
    // A card fills the screen: a book read aloud keeps its small player out
    // of its way.
    BookPlayerRoom.cardsOpened();
    _opened(widget.pill, swiped: false);
  }

  @override
  void dispose() {
    BookPlayerRoom.cardsClosed();
    _pages.dispose();
    super.dispose();
  }

  /// Which cards get opened again, from the shelves and the archive: the
  /// card's tags, whether the reader had kept or liked it, and whether it
  /// was reached by a swipe from the one before rather than opened.
  void _opened(Pill pill, {required bool swiped}) =>
      Analytics.capture('pill opened', {
        ...widget.app.cardFacts(pill.id),
        'saved': widget.app.savedIds.contains(pill.id),
        'liked': widget.app.isLiked(pill.id),
        'answered': widget.app.answers.containsKey(pill.id),
        'swiped': swiped,
      });

  /// The card's colour, faint, over the page: its own dark tint at night,
  /// and on paper a wash of it over paper — the words on it are the
  /// page's, and dark on the dark tint they could not be read.
  Color _ground(BuildContext context, Pill pill) => context.p.isDark
      ? pill.tint
      : Color.alphaBlend(pill.color.withValues(alpha: 0.10), context.p.surface);

  @override
  Widget build(BuildContext context) {
    return ScreenView(
      name: 'pill detail',
      child: Scaffold(
        backgroundColor: _ground(context, _cards[_at]),
        body: _cards.length == 1
            ? _page(context, _cards.single, 0)
            : PageView.builder(
                key: const ValueKey('detail-pages'),
                controller: _pages,
                // The cards either side built ahead, their pictures with
                // them, so a swipe brings a card already drawn.
                allowImplicitScrolling: true,
                itemCount: _cards.length,
                onPageChanged: (i) {
                  setState(() => _at = i);
                  _opened(_cards[i], swiped: true);
                },
                // Each page on its own colour, so a swipe carries one card's
                // colour off and brings the next one's on.
                itemBuilder: (context, i) => ColoredBox(
                  color: _ground(context, _cards[i]),
                  child: _page(context, _cards[i], i),
                ),
              ),
      ),
    );
  }

  Widget _page(BuildContext context, Pill pill, int i) {
    final saved = widget.app.isSaved(pill.id);
    final liked = widget.app.isLiked(pill.id);
    final answered = widget.app.answerFor(pill.id);
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // The way back stays put above what scrolls: on iOS 26 it is
          // Apple's own glass button, a native view, and one inside a
          // scrolling list is drawn away from its place.
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 0),
            child: Row(
              children: [
                BackCircle(onPressed: () => Navigator.of(context).pop()),
                Expanded(
                  child: _cards.length == 1
                      ? const SizedBox.shrink()
                      : Semantics(
                          label: context.l10n.cardOf(i + 1, _cards.length),
                          excludeSemantics: true,
                          child: Text(
                            context.l10n.rungOfTotal(i + 1, _cards.length),
                            key: const ValueKey('detail-position'),
                            textAlign: TextAlign.center,
                            style:
                                AppText.body(
                                  size: 13,
                                  weight: FontWeight.w600,
                                  color: context.p.inkMuted,
                                ).copyWith(
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                          ),
                        ),
                ),
                _RoundAction(
                  label: liked
                      ? context.l10n.removeFromLiked
                      : context.l10n.likeThisPill,
                  icon: liked
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: liked ? pill.color : context.p.ink,
                  onTap: () async {
                    await widget.app.toggleLiked(pill.id);
                    if (mounted) setState(() {});
                  },
                ),
                const SizedBox(width: 8),
                _RoundAction(
                  label: saved
                      ? context.l10n.removeFromSaved
                      : context.l10n.saveThisPill,
                  icon: saved
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_border_rounded,
                  color: saved ? pill.color : context.p.ink,
                  onTap: () async {
                    await widget.app.toggleSaved(pill.id);
                    if (mounted) setState(() {});
                  },
                ),
                const SizedBox(width: 8),
                _RoundAction(
                  label: context.l10n.shareThisPill,
                  icon: Icons.ios_share_rounded,
                  color: context.p.ink,
                  onTap: () => showShareSheet(context, pill),
                ),
              ],
            ),
          ),
          Expanded(
            child: SoftTop(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 28),
                children: [
                  _CardHead(pill: pill, onOpen: () => _openCard(context, pill)),
                  const SizedBox(height: 22),
                  if (answered != null) ...[
                    _AnsweredLine(pill: pill, given: answered),
                    const SizedBox(height: 16),
                  ],
                  // The same reveal the card shows. This used to print
                  // pill.answer alone, which on a worked problem is the last
                  // line of the solution and on a debate is one side of it.
                  RevealBody.onPage(pill, context.p),
                  const SizedBox(height: 24),
                  CardNoteSection(app: widget.app, pill: pill),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// The card itself, at full size: a drawing live, to be played again, or
  /// a card in words face down, to be turned over again. The viewer says,
  /// in its 'card closed', that it was opened from here.
  void _openCard(BuildContext context, Pill pill) => Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => DeckViewerScreen(
        app: widget.app,
        deck: [pill],
        title: context.l10n.subjectOf(pill.topic),
        source: 'detail',
      ),
    ),
  );
}

/// The head of the page: the card.
///
/// A card with a drawing shows the picture of its front, whole — its
/// question, its drawing, its foot — with the way to play it under it: the
/// picture is the card as it was met, the play is the card itself. A card in
/// words shows its question on its colour, as it always has here, and opens
/// the same way, to be turned over again.
class _CardHead extends StatelessWidget {
  const _CardHead({required this.pill, required this.onOpen});

  final Pill pill;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    if (!pill.hasPage || !CardThumb.has(pill, CardSide.front)) {
      return Semantics(
        button: true,
        hint: l.openTheCard,
        child: GestureDetector(
          key: const ValueKey('detail-open-card'),
          behavior: HitTestBehavior.opaque,
          onTap: onOpen,
          child: _Words(
            pill: pill,
            foot: _Open(pill: pill, label: l.openTheCard),
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          button: true,
          hint: l.playTheCard,
          child: GestureDetector(
            key: const ValueKey('detail-open-card'),
            behavior: HitTestBehavior.opaque,
            onTap: onOpen,
            child: DecoratedBox(
              decoration: cardFace(
                context,
                groundOf(pill),
                radius: 30,
                lift: 1,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: AspectRatio(
                  // The picture's own shape: the card whole.
                  aspectRatio: 458 / 758,
                  child: CardThumb(
                    pill: pill,
                    side: CardSide.front,
                    large: true,
                    // Where the picture will not come, the card's words,
                    // its question at the head of its colour — a size
                    // down where the reader's text is set so large that
                    // they would run past the card's foot.
                    fallback: LayoutBuilder(
                      builder: (context, box) => ColoredBox(
                        color: pill.color,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.topCenter,
                          child: SizedBox(
                            width: box.maxWidth,
                            child: _Words(pill: pill, face: false),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        _Play(pill: pill, label: l.playTheCard, onTap: onOpen),
      ],
    );
  }
}

/// A card's words on its colour: its subject and its question, and what
/// goes at its foot.
class _Words extends StatelessWidget {
  const _Words({required this.pill, this.foot, this.face = true});

  final Pill pill;
  final Widget? foot;

  /// On a card face of its own; off, the words alone, on whatever card is
  /// already under them.
  final bool face;

  @override
  Widget build(BuildContext context) {
    final Color onCard = pill.ink;
    return Container(
      padding: EdgeInsets.fromLTRB(26, 26, 26, foot == null ? 26 : 20),
      decoration: face
          ? cardFace(context, pill.color, radius: 30, lift: 1)
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.subjectOf(pill.topic).toUpperCase(),
            style: AppText.label(
              size: 10.5,
              spacing: 1.4,
              color: onCard.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            pill.question,
            style: AppText.display(
              size: 26,
              weight: FontWeight.w600,
              height: 1.16,
              spacing: -0.9,
              color: onCard,
            ),
          ),
          if (foot != null) ...[const SizedBox(height: 18), foot!],
        ],
      ),
    );
  }
}

/// The small way into a card in words, at its foot, in a wash of its ink.
class _Open extends StatelessWidget {
  const _Open({required this.pill, required this.label});

  final Pill pill;
  final String label;

  @override
  Widget build(BuildContext context) {
    final Color ink = pill.ink;
    return Container(
      height: 36,
      padding: const EdgeInsets.fromLTRB(11, 0, 14, 0),
      decoration: BoxDecoration(
        color: ink.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.open_in_full_rounded, size: 16, color: ink),
          const SizedBox(width: 7),
          // Smaller rather than cut or spilling: at a large text size the
          // words are wider than the card.
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                label,
                maxLines: 1,
                style: AppText.body(
                  size: 13.5,
                  weight: FontWeight.w700,
                  color: ink,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The way to play a card with a drawing, under its picture: the width of
/// the card, in the ground its picture is drawn on (a drawing may have a
/// ground of its own, not its subject's).
class _Play extends StatelessWidget {
  const _Play({required this.pill, required this.label, required this.onTap});

  final Pill pill;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color ground = groundOf(pill);
    final Color ink = pill.web?.ground == null ? pill.ink : inkOn(ground);
    return Semantics(
      button: true,
      excludeSemantics: true,
      label: label,
      child: GestureDetector(
        key: const ValueKey('detail-play'),
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: ground,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.play_arrow_rounded, size: 24, color: ink),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppText.body(
                  size: 16,
                  weight: FontWeight.w700,
                  color: ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoundAction extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String label;

  const _RoundAction({
    required this.icon,
    required this.color,
    required this.onTap,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      // A ring of 38 in a target of 44.
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
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
              child: Icon(icon, size: 17, color: color),
            ),
          ),
        ),
      ),
    );
  }
}

/// What the reader said when they met this card, and how it went.
class _AnsweredLine extends StatelessWidget {
  final Pill pill;
  final Answer given;
  const _AnsweredLine({required this.pill, required this.given});

  @override
  Widget build(BuildContext context) {
    if (!pill.isGraded) {
      // And how far, when the side was leant to on a shelf.
      final int? level = leanLevel(given);
      final String took = context.l10n.youTookTheSide(
        pill.challenge.describe(given.response),
      );
      return Text(
        level == null ? took : '$took · ${context.l10n.leanHow('$level')}',
        style: AppText.body(
          size: 13,
          weight: FontWeight.w500,
          color: context.p.inkMuted,
        ),
      );
    }

    final right = pill.challenge.accepts(given.response);
    final sure = given.confidence == null
        ? ''
        : context.l10n.elided(context.l10n.atPercentSure(given.confidence!));
    return Row(
      children: [
        Icon(
          right ? Icons.check_circle_rounded : Icons.cancel_rounded,
          size: 16,
          color: right ? context.p.ink : context.p.alert,
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            right
                ? context.l10n.youGotThisOne(sure)
                : context.l10n.youSaidAnswer(
                    // A pick is the card's words, quoted in the app's
                    // sentence; a number is said as it is.
                    pill.challenge is PickOne
                        ? context.l10n.quoted(
                            pill.challenge.describe(given.response),
                          )
                        : pill.challenge.describe(given.response),
                    sure,
                  ),
            style: AppText.body(
              size: 13,
              weight: FontWeight.w500,
              color: context.p.inkMuted,
            ),
          ),
        ),
      ],
    );
  }
}
