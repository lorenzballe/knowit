import 'package:flutter/material.dart';

import '../l10n/l10n.dart';

import 'package:flutter/services.dart';

import '../measure/card_read.dart';
import '../measure/session.dart';
import '../models/pill.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../data/topics.dart';
import '../widgets/magic_card.dart';
import '../data/pills_repository.dart';
import '../widgets/pill_card_stack.dart';
import '../widgets/premium.dart';
import '../widgets/share_sheet.dart';
import '../widgets/ui.dart';
import '../widgets/web/web_card_page.dart';
import 'today_done_view.dart';

/// The card is the screen: dark chrome, and the deck filling everything
/// between the progress bars and the tab bar.
///
/// Two screens live here, and they are deliberately not the same one with a
/// different middle. While the five are unread this is the trainer — "Today"
/// at the top, the bars, the deck, and nothing else to do. Once they are
/// read it becomes the shelf from artboard 66a, which is a place to look
/// back rather than a place to work.
class TodayScreen extends StatefulWidget {
  final AppState app;

  /// Set when this is opened as its own screen off the path, so the way back
  /// sits in the header rather than stacked above it.
  final VoidCallback? onBack;

  /// True while a card is under the finger. The tab bar steps aside for the
  /// gesture: a card being thrown towards the bottom of the screen should
  /// not be thrown at a row of buttons.
  final ValueChanged<bool>? onCardMotion;

  /// True while there is a deck on the table — the five, or the card after
  /// them — and false once the shelf is up. The shell locks the tabs while
  /// it is true, so a throw is never taken for a swipe to the next tab.
  /// The day being finished is not the same thing: the sixth card is on
  /// the table after the fifth is thrown, and it is thrown too.
  final ValueChanged<bool>? onDeckOnTable;

  /// Told as one of the day's cards is let go, sent on. From the first one
  /// the day is under way: the shell keeps its tab bar out of the way of
  /// the cards that are left, and gives the deck the room it held.
  final VoidCallback? onCardSent;

  /// What stands at the far end of the header while the shell keeps its tab
  /// bar aside: the tabs, small, where they can be called back from. Null
  /// while the bar is in its place.
  final Widget? tabsAside;

  /// Calls the tab bar back, from anywhere on the header; null while the
  /// bar is in its place.
  final VoidCallback? onCallTabs;

  const TodayScreen({
    super.key,
    required this.app,
    this.onBack,
    this.onCardMotion,
    this.onDeckOnTable,
    this.onCardSent,
    this.tabsAside,
    this.onCallTabs,
  });

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  /// Whether the day was done at the last build — null before the first,
  /// so opening the app onto a finished day is not mistaken for finishing it.
  bool? _wasDone;

  /// Whether the card after the fifth is still on the table. It is dealt
  /// only when the day is finished *here*, in this session — opening the
  /// app onto a day already done goes straight to the shelf — and only on
  /// the free plan, where there is something to offer: all five cards,
  /// the reader's own. It leaves the way every card leaves: thrown.
  bool _magic = false;

  /// Which of the finished day's cards is at the front of the shelf. Held
  /// here rather than in the shelf because the header's dot and the glow
  /// behind the whole tab take that card's colour.
  int _shelfAt = 0;
  List<Pill>? _shelfDeck;

  /// Finishing the day is the one moment worth marking. Fired after the frame
  /// so the feedback is a side effect of the state, not of painting.
  void _markCompletion(bool completed) {
    final bool? before = _wasDone;
    _wasDone = completed;
    if (before == null || before == completed) return;
    if (!completed) {
      // A new day: the table is a deck again, and nothing is on offer yet.
      _magic = false;
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      HapticFeedback.heavyImpact();
    });
    if (!widget.app.isPlus) _magic = true;
  }

  /// What the shell was last told about the table.
  bool? _toldOnTable;

  /// Tells the shell whether a deck is on the table, once per change and
  /// after the frame, so it is a side effect of the state and not of
  /// painting.
  void _tellShell(bool onTable) {
    if (onTable == _toldOnTable) return;
    _toldOnTable = onTable;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onDeckOnTable?.call(onTable);
    });
  }

  /// How the card just thrown was read, until the day moves past it.
  CardStint? _thrown;

  /// True once the deck has shown how a card is sent on, until one is.
  bool _hinting = false;

  /// The first of the day's own cards, on a Sunday that has one more of
  /// them than other days; null on any other day.
  static String? _sundaysOwn(AppState app) {
    if (!app.sundayExtraToday) return null;
    for (final Pill p in app.todaysDeck) {
      if (app.ownIdsToday.contains(p.id)) return p.id;
    }
    return null;
  }

  /// The card after the fifth, thrown.
  void _throwMagic() {
    if (!mounted || !_magic) return;
    setState(() => _magic = false);
  }

  /// The offer: the paywall. Coming back without the trial, the card is
  /// still on the table, to be thrown like any other; with it, tomorrow's
  /// five are all the reader's own, and the card says so.
  Future<void> _offer(BuildContext context) =>
      requirePlus(context, widget.app, () {}, source: 'sixth card');

  /// Less like this — said once, quietly, with the way back.
  void _dislike(BuildContext context, Pill pill) {
    final app = widget.app;
    app.dislike(pill.id);
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(context.l10n.lessLikeThis),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: context.l10n.undo,
          onPressed: () => app.undislike(pill.id),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = widget.app;
    final bool done = app.todayCompleted;
    _markCompletion(done);
    // Bought from the card itself: the offer has nothing left to offer and
    // leaves the table, so the shelf comes up. It used to stay "on the
    // table" with no card on it — the deck drops the card after the fifth
    // on Astute+ — and Today was a blank page for the reader who had just
    // paid.
    if (_magic && app.isPlus) _magic = false;

    // The sixth card keeps the deck on the table after the fifth is gone:
    // the shelf comes up when it, too, has been thrown.
    final bool onTable = !done || _magic;
    _tellShell(onTable);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 420),
      switchInCurve: Curves.easeOutCubic,
      child: onTable
          ? _reading(context, key: const ValueKey('deck'))
          : _shelf(context, key: const ValueKey('shelf')),
    );
  }

  /// The day, being read. Unchanged from the screen this app has always
  /// opened on: the word Today, the streak beside it, the bars, the deck.
  Widget _reading(BuildContext context, {required Key key}) {
    final app = widget.app;
    return Stack(
      key: key,
      clipBehavior: Clip.none,
      children: [
        // The table takes a breath of the colour of the card in front, the
        // way the shelf's ground answers its front card once the day is
        // read: black with the card's colour in it, never a second colour.
        // It runs past this screen's own room, over the status bar and
        // under the tab bar, so the table has no seam where the shell's
        // room for them begins; the page clips it at the glass.
        Positioned(
          left: 0,
          right: 0,
          top: -_Tint.reach,
          bottom: -_Tint.reach,
          child: _Tint(colour: _frontColour(app)),
        ),
        _table(context),
      ],
    );
  }

  /// The colour of the card in front: a free card's own ground where its
  /// page has one, its subject's otherwise, and behind the card after the
  /// fifth the spectrum's violet, as on the shelf.
  static Color _frontColour(AppState app) {
    final List<Pill> deck = app.todaysDeck;
    final int at = app.todayIndex;
    if (at >= deck.length) return kSpectrum[9];
    final Pill pill = deck[at];
    return pill.hasPage ? groundOf(pill) : pill.color;
  }

  /// The word Today, the bars and the deck.
  Widget _table(BuildContext context) {
    final app = widget.app;
    return Padding(
      // The sides come from the deck's own constant, so Today and the
      // re-read cannot drift apart again.
      padding: const EdgeInsets.fromLTRB(kDeckMargin, 10, kDeckMargin, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // The header and the gap under it are one thing to touch while
          // the shell keeps its tab bar aside: a tap anywhere on them calls
          // the bar back. The tabs standing small at the far end say so and
          // answer a screen reader themselves; the room is the same as it
          // was, so nothing under it moves.
          GestureDetector(
            key: const ValueKey('today-head'),
            behavior: HitTestBehavior.opaque,
            excludeFromSemantics: true,
            onTap: widget.onCallTabs,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _ReadingHeader(
                streak: app.liveStreak,
                frozen: app.streakWasFrozen,
                onBack: widget.onBack,
                // Said beside the day's name — the one place on the screen
                // with room to spare on a first morning, which has no streak
                // to show there — so the deck below never moves to make
                // room for it.
                hint: _hinting && app.pillsRead == 0
                    ? context.l10n.swipeForTheNextOne
                    : null,
                far: widget.tabsAside,
              ),
            ),
          ),
          _ProgressBars(total: app.todaysDeck.length, index: app.todayIndex),
          const SizedBox(height: 16),
          // The deck takes every pixel that is left.
          Expanded(
            child: PillCardStack(
              deck: app.todaysDeck,
              index: app.todayIndex,
              // After the last pill, on the free plan, the card that offers
              // the whole day: all five the reader's own, the ones dealt at
              // random too. It is thrown like the rest, and it says where
              // the reader's week has got to.
              trailing: app.isPlus
                  ? null
                  : MagicCard(
                      key: const ValueKey('magic-card'),
                      eyebrow: context.l10n.plusNameCaps,
                      note: weekNoteOf(context, app),
                      headline: context.l10n.plusCardHeadline,
                      line: context.l10n.magicLine,
                      action: plusActionOf(context),
                      onAction: () => _offer(context),
                    ),
              // How each card was read: a card thrown on is said with the
              // day moving on past it ('card advanced'); one left standing
              // for another tab or the background is said as it is left.
              onRead: (stint) {
                if (stint.thrown) {
                  _thrown = stint;
                  // Said as the card is let go, not when it has flown: the
                  // deck takes the bar's room while the next card rises
                  // into it, never under a card being read.
                  widget.onCardSent?.call();
                } else {
                  app.cardClosed(stint, where: 'today');
                }
              },
              // The first card of a start standing on screen: how long the
              // reader waited for it.
              onStand: (_) => FirstCard.shown(app.firstCardFacts),
              onAdvance: () {
                final CardStint? thrown = _thrown;
                _thrown = null;
                if (app.todayIndex >= app.todaysDeck.length) {
                  _throwMagic();
                  return null;
                }
                return app.advance(read: thrown?.facts ?? const {});
              },
              isSaved: app.isSaved,
              onSave: (pill) => app.toggleSaved(pill.id),
              isLiked: app.isLiked,
              onLike: (pill) => app.toggleLiked(pill.id),
              onDislike: (pill) => _dislike(context, pill),
              onShare: (pill) => showShareSheet(context, pill),
              onMotion: widget.onCardMotion,
              // The card about where the reader lives says so on its front.
              home: app.place,
              // Nothing else on the screen says how card two is reached,
              // so the first card shows it, once, to a reader who has never
              // sent a card on.
              swipeHint: app.pillsRead == 0,
              onSwipeHint: () {
                if (mounted) setState(() => _hinting = true);
              },
              reviewIds: app.reviewIdsToday,
              // Which cards are the reader's own, on the day that has
              // others: Astute+ has no others to tell them from.
              ownIds: app.isPlus ? const {} : app.ownIdsToday,
              // On the reader's Sunday, the one more of their own is said
              // on the card itself — the first of their own — under its
              // head, where a card about a place says why it is there. It
              // used to be a line over the deck, about a card not yet in
              // sight, read before the day had started.
              notes: {
                if (_sundaysOwn(app) case final String id)
                  id: context.l10n.sundayOneMore,
              },
              answerFor: app.answerFor,
              onAnswer: (id, response, confidence, reason) => app.recordAnswer(
                id,
                response,
                confidence: confidence,
                reason: reason,
              ),
              onReact: app.react,
            ),
          ),
        ],
      ),
    );
  }

  /// The day, done — artboard 66a, down to its margins.
  Widget _shelf(BuildContext context, {required Key key}) {
    final app = widget.app;
    final deck = app.todaysDeck;
    if (deck.isEmpty) return SizedBox.shrink(key: key);

    // A new deck — the next day, or the second set dealt — starts the shelf
    // from its first card.
    if (!identical(_shelfDeck, deck)) {
      _shelfDeck = deck;
      _shelfAt = 0;
    }
    // On the free plan the shelf ends on the card that offers the rest of
    // the day; that card has no subject, so the tab takes the spectrum's
    // violet behind it rather than the last card's colour.
    final int count = deck.length + (app.isPlus ? 0 : 1);
    final int at = _shelfAt.clamp(0, count - 1);
    final Color colour = at < deck.length ? deck[at].color : kSpectrum[9];

    return Stack(
      key: key,
      children: [
        Positioned.fill(child: _Glow(colour: colour)),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: TodayDoneView(
                app: app,
                at: at,
                onPick: (k) => setState(() => _shelfAt = k),
                // Which day this was, and what it made, on the shelf's own
                // first row.
                heading: (
                  line: context.l10n.dayRead(
                    app.dayNumber,
                    context.l10n.countWord('${app.todaysDeck.length}'),
                  ),
                  aside: _shelfAside(context, app),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// The header while the day is being read.
/// Today before its day has come: the same screen in the same places, the
/// word Today and the bars, with the deck in grey where the cards will
/// stand. The app opens on it at once, as a feed opens on the outline of its
/// posts, and the day lands in the room it kept.
class TodaySkeleton extends StatelessWidget {
  const TodaySkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    // The padding, the header and the gaps of [_TodayScreenState._reading].
    return const Padding(
      padding: EdgeInsets.fromLTRB(kDeckMargin, 10, kDeckMargin, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ReadingHeader(streak: 0),
          SizedBox(height: 16),
          // None lit yet: nothing of the day has been read, and the first
          // lights as its card lands.
          _ProgressBars(total: kPillsPerDay, index: -1),
          SizedBox(height: 16),
          Expanded(child: DeckSkeleton()),
        ],
      ),
    );
  }
}

class _ReadingHeader extends StatelessWidget {
  final int streak;
  final bool frozen;
  final VoidCallback? onBack;

  /// How the card is sent on, once, at the far end of the row.
  final String? hint;

  /// What stands at the far end of the row when the hint does not: the
  /// tabs, small, while the shell keeps its bar out of the day's way. No
  /// taller than the row already is, so the deck under it never moves.
  final Widget? far;
  const _ReadingHeader({
    required this.streak,
    this.frozen = false,
    this.onBack,
    this.hint,
    this.far,
  });

  @override
  Widget build(BuildContext context) {
    final Widget? far = hint == null ? this.far : null;
    final Widget row = _row(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      // The tabs stand over the row's far end rather than in it: the row is
      // measured without them, so it is exactly as tall and as wide as it
      // was, and they are flush to the end whatever the day's name and the
      // streak beside it take.
      child: far == null
          ? row
          : Stack(
              clipBehavior: Clip.none,
              children: [
                row,
                PositionedDirectional(
                  top: 0,
                  bottom: 0,
                  end: 0,
                  child: Center(child: far),
                ),
              ],
            ),
    );
  }

  Widget _row(BuildContext context) {
    return Row(
      children: [
        if (onBack != null) ...[
          BackCircle(onPressed: onBack!),
          const SizedBox(width: 12),
        ],
        // A long date and a streak badge do not both fit on a narrow
        // handset. The date gives way by a point or two rather than being
        // clipped, or overflowing, which is what it did.
        Flexible(
          flex: 2,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              context.l10n.tabToday,
              maxLines: 1,
              style: AppText.display(
                size: 20,
                weight: FontWeight.w600,
                spacing: -0.4,
                color: context.p.ink,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        // Nothing until there is something. A badge reading "0 days" on the
        // morning somebody installs the app is a worse first impression
        // than no badge at all.
        if (streak > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
            decoration: BoxDecoration(
              color: frozen
                  ? context.p.link.withValues(alpha: 0.22)
                  : context.p.line,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: frozen ? context.p.link : context.p.inverse,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  context.l10n.streakDays(streak),
                  style: AppText.body(
                    size: 12,
                    weight: FontWeight.w600,
                    color: context.p.ink,
                  ),
                ),
              ],
            ),
          ),
        if (hint != null) ...[
          const SizedBox(width: 12),
          // Three parts of the row's room to the day's name's two: the
          // name keeps its size in every language, and the hint, which
          // gives way, rarely has to.
          Expanded(flex: 3, child: _SwipeHint(text: hint!)),
        ],
      ],
    );
  }
}

/// How a card is sent on, said once: a hand's mark and a few words, quiet,
/// flush to the far end of the header. It comes in as the card leans, and
/// goes as the first card does. One line, given way by a point or two
/// rather than wrapped, so the header never grows under it.
class _SwipeHint extends StatelessWidget {
  const _SwipeHint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final bool still = MediaQuery.disableAnimationsOf(context);
    final Color ink = context.p.inkFaint;
    return TweenAnimationBuilder<double>(
      key: const ValueKey('swipe-hint'),
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: still ? 0 : 420),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(10 * (1 - t), 0),
          child: child,
        ),
      ),
      child: Align(
        alignment: AlignmentDirectional.centerEnd,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ExcludeSemantics(
                child: Icon(Icons.swipe_left_rounded, size: 16, color: ink),
              ),
              const SizedBox(width: 6),
              Text(
                text,
                maxLines: 1,
                style: AppText.body(
                  size: 12.5,
                  weight: FontWeight.w500,
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

/// The table while the five are read, washed with the front card's colour.
///
/// It was black and still, so that the card was the only colour on the
/// screen. It still is the only colour: this is that colour, an eighth of
/// it, thrown on the ground the card stands on, brightest beside the card
/// and falling away towards the top and the foot of the screen, so the
/// phone reads as lit by the card rather than framed in black. The colour
/// crosses over when the next card comes to the front, as the shelf's glow
/// does, and holds still otherwise.
class _Tint extends StatelessWidget {
  const _Tint({required this.colour});

  final Color colour;

  /// How far past its screen the wash runs, above and below.
  static const double reach = 400;

  @override
  Widget build(BuildContext context) {
    final bool still = MediaQuery.disableAnimationsOf(context);
    return IgnorePointer(
      child: TweenAnimationBuilder<Color?>(
        key: const ValueKey('table-tint'),
        tween: ColorTween(end: colour),
        duration: Duration(milliseconds: still ? 0 : 550),
        curve: Curves.easeOut,
        builder: (context, lit, _) {
          final Color c = lit ?? colour;
          return DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                radius: 0.9,
                colors: [
                  c.withValues(alpha: 0.13),
                  c.withValues(alpha: 0.11),
                  c.withValues(alpha: 0.07),
                ],
                stops: const [0, 0.62, 1],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// The header once the day is done: a dot in the front card's colour, which
/// day this was, and at the far end what was kept. One line, because the
/// screen under it is the subject and a header should say where you are
/// rather than take a third of the room saying it.
/// Two pools of the front card's colour thrown on the ground, one high
/// behind the card and a fainter one low behind the controls — the
/// artboard's two blurred circles, at its positions but at a third of its
/// strength. At the canvas's 30% and 16% the page reads as a coloured
/// filter laid over the app; at nothing at all the card lights a room that
/// does not answer. This is the room answering quietly. The colour crosses
/// over when the front card changes rather than snapping.
class _Glow extends StatelessWidget {
  const _Glow({required this.colour});

  final Color colour;

  /// Where the artboard puts them, less the 56 points of status bar its
  /// frame draws above the page.
  static const double _statusBar = 56;

  @override
  Widget build(BuildContext context) {
    final bool still = MediaQuery.disableAnimationsOf(context);
    final duration = Duration(milliseconds: still ? 0 : 550);
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, box) {
          final double w = box.maxWidth;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: w / 2 - 320,
                top: 150 - _statusBar,
                child: _Pool(
                  colour: colour,
                  strength: 0.12,
                  size: 640,
                  duration: duration,
                ),
              ),
              Positioned(
                left: w / 2 - 260,
                top: 420 - _statusBar,
                child: _Pool(
                  colour: colour,
                  strength: 0.06,
                  size: 520,
                  height: 420,
                  duration: duration,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Pool extends StatelessWidget {
  const _Pool({
    required this.colour,
    required this.strength,
    required this.size,
    required this.duration,
    this.height,
  });

  final Color colour;
  final double strength;
  final double size;
  final double? height;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: duration,
      curve: Curves.easeOut,
      width: size,
      height: height ?? size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        // The canvas draws a hard-edged circle and blurs it by 130. A blur
        // that wide is a Gaussian, so the same shape is cheaper as a
        // gradient: most of the colour in the middle third, and gone well
        // before the edge.
        gradient: RadialGradient(
          colors: [
            colour.withValues(alpha: strength),
            colour.withValues(alpha: strength * 0.72),
            colour.withValues(alpha: strength * 0.30),
            colour.withValues(alpha: strength * 0.08),
            colour.withValues(alpha: 0),
          ],
          stops: const [0, 0.28, 0.55, 0.78, 1],
        ),
      ),
    );
  }
}

/// The small line under the finished day's. The freeze is said here and
/// nowhere else, so it comes first on the day it was spent. Otherwise the
/// gesture that likes a card, until the reader has liked one: from then on
/// they know it, a liked card says so itself with the heart in its corner,
/// and there is no line.
String? _shelfAside(BuildContext context, AppState app) {
  if (app.streakWasFrozen) return context.l10n.freezeKeptStreak;
  if (app.likedIds.isEmpty) return context.l10n.holdACardYouLike;
  return null;
}

class _ProgressBars extends StatelessWidget {
  final int total;
  final int index;
  const _ProgressBars({required this.total, required this.index});

  @override
  Widget build(BuildContext context) {
    return Padding(
      // The bars are the only thing that says where in the day you are, now
      // that the card has stopped repeating it. The key names what they
      // draw, so it can be read without a caption existing for its own sake.
      key: ValueKey('progress-${index + 1}-of-$total'),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Row(
        children: List.generate(total, (i) {
          final filled = i <= index;
          return Expanded(
            child: AnimatedContainer(
              duration: Duration(milliseconds: 260 + i * 40),
              curve: Curves.easeOut,
              margin: EdgeInsets.only(right: i == total - 1 ? 0 : 5),
              height: 3,
              decoration: BoxDecoration(
                color: filled ? context.p.ink : context.p.line,
                borderRadius: BorderRadius.circular(9),
              ),
            ),
          );
        }),
      ),
    );
  }
}
