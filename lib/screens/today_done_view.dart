import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/l10n.dart';

import 'package:flutter/services.dart';

import '../data/pills_repository.dart' show dateKey;
import '../models/pill.dart';
import '../data/daily.dart';
import '../data/skill_levels.dart';
import '../data/skills.dart';
import '../state/app_state.dart';
import '../sync/subscription.dart';
import '../theme.dart';
import '../widgets/card_edge.dart';
import '../widgets/fit_text.dart';
import '../widgets/flip_card.dart';
import '../widgets/hold_to_keep.dart';
import '../widgets/liked_mark.dart';
import '../widgets/skill_mark.dart';
import 'deck_viewer_screen.dart';
import 'journey_screen.dart';
import '../analytics.dart';
import '../widgets/motion.dart';
import '../widgets/magic_card.dart';
import '../widgets/premium.dart';
import '../data/topics.dart';
import '../widgets/share_day.dart';
import '../widgets/share_sheet.dart';
import '../widgets/subject_icon.dart';
import '../widgets/web/card_thumb.dart';
import '../widgets/web/web_card_page.dart' show groundOf;

/// The Today tab once the five are done, from artboard 66a.
///
/// At rest the tab is a shelf. The day's five come back as a real carousel —
/// swipe through them, tap one to turn it over — so "review" is the screen
/// itself and not a button. Under the card at the front a glow in its
/// colour, rather than a coloured ground. Then the one thing no earlier
/// version had: the subject that opens tomorrow, already named tonight,
/// which is the strongest return hook a daily product has. The primary
/// action goes to the Explore tab's best of today, and the extra pills sit
/// quietly under it.
///
/// Which card is at the front belongs to the screen above, because the
/// header's dot and the glow behind everything take that card's colour.
/// What the card after the fifth says about the plan tonight, on the
/// free plan, with a key for what it says: the evening a week is kept,
/// that tomorrow has one more of their own, said once, where it reads as a
/// reward rather than a rule. It is said on the card that makes the offer,
/// beside what Astute+ keeps, and only once the day is done, because until
/// then tonight has not happened.
/// What the offer's button says: the free days the store will give this
/// reader, as many as it gives, or plainly Astute+ once they have had them
/// — the store gives the trial once, and a button that promises it again
/// is one Apple would charge through.
String plusActionOf(BuildContext context) {
  final int? days = Subscription.instance.trialDays;
  return days == null ? context.l10n.getPlus : context.l10n.magicUnlock(days);
}

(String, String)? weekNoteOf(BuildContext context, AppState app) {
  if (app.isPlus || !app.todayCompleted) return null;
  if (app.tomorrowIsRewarded) {
    // A Sunday after a week kept has the week's extra card and Sunday's.
    final DateTime tomorrow = DateTime(
      app.today.year,
      app.today.month,
      app.today.day + 1,
    );
    return (
      'week-reward',
      isSunday(tomorrow)
          ? context.l10n.weekKeptSundayFourOwn
          : context.l10n.weekKeptThreeOwn,
    );
  }
  return null;
}

class TodayDoneView extends StatefulWidget {
  final AppState app;

  /// The card at the front, and where a new pick goes.
  final int at;
  final ValueChanged<int> onPick;

  /// The day's own line, and the aside under it, at the head of the shelf
  /// in place of its eyebrow: where the day got to, beside the shelf's two
  /// buttons, on one row. The Today tab passes them. They used to be a row
  /// of their own over the eyebrow's, and the eyebrow ("TODAY'S FIVE") said
  /// again what the line had just said ("five read"), with an odd band of
  /// air between the two. On its own the shelf heads itself with the
  /// eyebrow.
  final ({String line, String? aside})? heading;

  const TodayDoneView({
    super.key,
    required this.app,
    required this.at,
    required this.onPick,
    this.heading,
  });

  @override
  State<TodayDoneView> createState() => _TodayDoneViewState();
}

class _TodayDoneViewState extends State<TodayDoneView>
    with SingleTickerProviderStateMixin {
  /// The artboard's card, and the distance between one card and the next.
  static const double _artWidth = 324;
  static const double _artHeight = 452;

  /// How far a card's shadow may spill past the room it sits in before the
  /// fade takes it. The canvas pads the shelf by this and pulls the padding
  /// straight back off with a negative margin.
  static const double _bleed = 90;

  /// The least room left above and below the card, whatever the screen.
  static const double _air = 14;

  /// What the card leaves at each side. The canvas gives it 39, which on a
  /// screen taller than the canvas leaves the card floating in the middle
  /// with the dots stranded under it; 24 lets the card grow into the room
  /// instead, and takes the dots down with it to the line about tomorrow.
  static const double _side = 24;

  /// Settles the cards after a drag. The curve overshoots a touch, so a
  /// card lands rather than stops.
  late final AnimationController _settle = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  )..addListener(_tick);
  Animation<double>? _settling;

  /// How far the shelf has been pulled from rest, in points.
  double _dx = 0;

  /// Whether the card at the front has been turned to its answer. The
  /// finished day shows each card by its question, as it came in the deck,
  /// and a tap turns it over (the owner: the day's cards are not shown
  /// turned already). A drawn card's question is its picture taken at the
  /// shelf's own proportion, its drawing filling the room it has.
  bool _flipped = false;

  /// The pick this widget asked for, so the parent handing it back is not
  /// mistaken for the deck being reset under it.
  int? _pendingAt;

  /// Set by the layout, read by the gestures.
  double _cardWidth = _artWidth;
  double _cardHeight = _artHeight;

  /// Whether the shelf ends on the card that offers the rest of the day.
  /// It does on the free plan, where three of the five came at random,
  /// and never on Astute+, so nobody is sold what they already have.
  bool get _offer => !widget.app.isPlus;

  /// How many cards the shelf holds: the deck, and the offer after it.
  int _count(List<Pill> deck) => deck.length + (_offer ? 1 : 0);

  /// The offer: the paywall.
  Future<void> _sell() =>
      requirePlus(context, widget.app, () {}, source: 'sixth card');

  /// Tomorrow's opening card, dealt once per state of the record rather
  /// than on every frame of a drag. The deal depends on the date, what has
  /// been read and answered, today's deck and the mix, so those are the key.
  Pill? _lead;
  String? _leadKey;

  Pill? _tomorrowsLead(AppState app) {
    final key = [
      dateKey(app.today),
      app.todaysDeck.length,
      app.seenIds.length,
      app.answers.length,
      app.pickedTopics.join(','),
      identityHashCode(app.topicWeights),
    ].join('|');
    if (key != _leadKey) {
      _leadKey = key;
      _lead = app.tomorrowsDeck.firstOrNull;
    }
    return _lead;
  }

  double get _step => _cardWidth - 2;

  @override
  void didUpdateWidget(covariant TodayDoneView old) {
    super.didUpdateWidget(old);
    if (old.at == widget.at) return;
    if (widget.at == _pendingAt) {
      _pendingAt = null;
      return;
    }
    // Moved from outside: a new day, or a reset. Nothing to carry over.
    _settle.stop();
    _settling = null;
    _dx = 0;
    _flipped = false;
  }

  @override
  void dispose() {
    _settle.dispose();
    super.dispose();
  }

  void _tick() {
    final anim = _settling;
    if (anim == null) return;
    setState(() => _dx = anim.value);
  }

  void _onDragStart(DragStartDetails d) {
    _settle.stop();
    _settling = null;
  }

  void _onDragUpdate(DragUpdateDetails d) {
    setState(() => _dx += d.delta.dx);
  }

  void _onDragEnd(DragEndDetails d) {
    final deck = widget.app.todaysDeck;
    final int at = widget.at;
    final double thrown = d.velocity.pixelsPerSecond.dx;
    // Either carried far enough or thrown hard enough: distance alone makes
    // a quick flick do nothing, and the flick is the gesture people make.
    int target = at;
    if ((_dx < -60 || thrown < -500) && at < _count(deck) - 1) {
      target = at + 1;
    } else if ((_dx > 60 || thrown > 500) && at > 0) {
      target = at - 1;
    }
    _goTo(target);
  }

  /// Brings [target] to the front from wherever the shelf is now. The cards
  /// keep their place on screen across the change of index, so what the
  /// finger left is exactly what the settle starts from.
  void _goTo(int target) {
    final int at = widget.at;
    if (target != at) {
      HapticFeedback.selectionClick();
      _dx += (target - at) * _step;
      _flipped = false;
      _pendingAt = target;
      widget.onPick(target);
    }
    _home();
  }

  void _home() {
    if (MediaQuery.disableAnimationsOf(context)) {
      setState(() => _dx = 0);
      return;
    }
    final anim = Tween<double>(begin: _dx, end: 0).animate(
      CurvedAnimation(parent: _settle, curve: const Cubic(0.3, 1.14, 0.3, 1)),
    );
    _settling = anim;
    _settle
      ..reset()
      ..forward();
  }

  void _flip() {
    HapticFeedback.selectionClick();
    setState(() => _flipped = !_flipped);
  }

  /// A tap on the card at the front turns it over; on a card beside it,
  /// brings that one to the front.
  void _onTapUp(TapUpDetails d, Size stage) {
    final deck = widget.app.todaysDeck;
    final int at = widget.at;
    final Offset centre = stage.center(Offset.zero);
    for (final off in const [0, -1, 1]) {
      final int k = at + off;
      if (k < 0 || k >= _count(deck)) continue;
      final double x = off * _step + _dx;
      final double scale = 1 - math.min(x.abs() / _step, 1) * 0.07;
      final Rect box = Rect.fromCenter(
        center: centre.translate(x, 0),
        width: _cardWidth * scale,
        height: _cardHeight * scale,
      );
      if (!box.contains(d.localPosition)) continue;
      if (off == 0) {
        // The offer has no back; its button is its own.
        if (k < deck.length) _flip();
      } else {
        _goTo(k);
      }
      return;
    }
  }

  /// How wide [text] sets in [style] on one line, at the reader's text size.
  static double _width(BuildContext context, String text, TextStyle style) {
    final TextPainter painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    final double width = painter.width;
    painter.dispose();
    return width;
  }

  /// The day's cards again at full size, the way they first came, from the
  /// one at the front of the shelf: the page a widget's tap opens. The
  /// shelf shows them in small; this is the cards themselves.
  void _seeAgain(BuildContext context, List<Pill> deck, int at) {
    HapticFeedback.selectionClick();
    Analytics.capture('today seen again', {'from': 'today', 'at': at});
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DeckViewerScreen(
          app: widget.app,
          deck: deck,
          title: context.l10n.tabToday,
          initialIndex: at < deck.length ? at : 0,
          source: 'today again',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = widget.app;
    final deck = app.todaysDeck;
    if (deck.isEmpty) return const SizedBox.shrink();
    final int count = _count(deck);
    final int at = widget.at.clamp(0, count - 1);
    final Color ink = context.p.ink;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          // Eight above rather than sixteen: the row is as tall as its two
          // buttons now, and the shelf under it keeps nearly all its room.
          // Headed by the day's line, the row is the screen's first, and
          // sits where that line did.
          padding: EdgeInsets.fromLTRB(
            24,
            widget.heading == null ? 8 : 0,
            18,
            0,
          ),
          child: LayoutBuilder(
            builder: (context, box) {
              final ({String line, String? aside})? heading = widget.heading;
              final String eyebrow = context.l10n.shelfEyebrow(
                context.l10n.countWord('${deck.length}').toUpperCase(),
              );
              final TextStyle eyebrowStyle = AppText.label(
                size: 10.5,
                weight: FontWeight.w700,
                spacing: 1.6,
                color: ink.withValues(alpha: 0.4),
              );
              // The heading is never cut for the buttons: where the two do
              // not fit on the line ("DIE FÜNF VON HEUTE" and "Nochmal
              // ansehen"), "See again" gives up its word and keeps its mark.
              // The day's line gives a point or two first (it is set to
              // shrink to fit), and only past that does "See again" give up
              // its word: "Giorno 13 · cinque lette" and "Rivedi" share an
              // SE's line with the line a size down.
              final double lead = heading == null
                  ? _width(context, eyebrow, eyebrowStyle)
                  : _DayHeading.dotRoom +
                        _width(
                          context,
                          heading.line,
                          _DayHeading.lineStyle(ink, size: _DayHeading.least),
                        );
              final bool compact =
                  lead + 12 + _DayTools.widthOf(context, app, compact: false) >
                  box.maxWidth;
              return Row(
                children: [
                  Expanded(
                    child: heading == null
                        ? Text(
                            eyebrow,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: eyebrowStyle,
                          )
                        : _DayHeading(
                            line: heading.line,
                            aside: heading.aside,
                            // The card at the front's colour; the offer's,
                            // the spectrum's violet, as the glow takes.
                            dot: at < deck.length
                                ? deck[at].color
                                : kSpectrum[9],
                          ),
                  ),
                  const SizedBox(width: 12),
                  // Where the counter was: the dots under the shelf already say
                  // which card is at the front, so the row's end is the day's
                  // two ways on instead — the five again at full size, and the
                  // day sent. Neither takes a line of its own: on a small phone
                  // the shelf is what this screen is for.
                  _DayTools(
                    app: app,
                    compact: compact,
                    onSeeAgain: () => _seeAgain(context, deck, at),
                  ),
                ],
              );
            },
          ),
        ),
        Expanded(child: _shelf(context, deck, at)),
        _Dots(deck: deck, count: count, at: at, onPick: _goTo),
        // Close under the dots: they count the deck, but they read as
        // belonging to whatever line they sit nearest, and that line is
        // the one about tomorrow.
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 6, 24, 0),
          child: _Tomorrow(lead: _tomorrowsLead(app)),
        ),
        // The way on is the journey: where the day just went, on the
        // ladder. Beside it, the day sent as five squares.
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          child: _Actions(app: app),
        ),
        // What the canvas leaves between the last line and the tab bar.
        const SizedBox(height: 16),
      ],
    );
  }

  /// The carousel: the card at the front full size and solid, its
  /// neighbours a step to either side, smaller and half faded, and the
  /// edges of the shelf dissolving into the ground.
  Widget _shelf(BuildContext context, List<Pill> deck, int at) {
    return LayoutBuilder(
      builder: (context, box) {
        // The card grows into its room rather than holding the canvas's
        // 324 by 452 and leaving the rest as black — the room is what sits
        // between the line above it and the dots below, and a card that
        // leaves a third of it empty puts those two lines a long way
        // apart. Everything printed on the card scales with its width, so
        // a wider card is the same card, bigger; the extra height beyond
        // the canvas's proportion is air inside the card, and is capped
        // before the card turns into a column.
        // (Taking the drawn cards' pictures' taller proportion instead made
        // every card narrower and its words smaller on a phone short of
        // room, and the owner liked the shelf less: the shape stays.)
        final double room = math.max(0, box.maxHeight - _air * 2);
        final double width = math.min(
          box.maxWidth - _side * 2,
          room * _artWidth / _artHeight,
        );
        _cardWidth = width;
        _cardHeight = math.min(room, width * _artHeight / _artWidth * 1.25);
        _learnTags(deck);
        final Size stage = Size(box.maxWidth, box.maxHeight);

        // Painted furthest-from-the-front first, so the front card is on
        // top, and only what could actually be on screen.
        final order = List<int>.generate(_count(deck), (k) => k)
          ..sort((a, b) => (b - at).abs().compareTo((a - at).abs()));
        final layers = <Widget>[];
        for (final k in order) {
          final double x = (k - at) * _step + _dx;
          if (x.abs() > stage.width / 2 + _cardWidth / 2) continue;
          final double dist = math.min(x.abs() / _step, 1);
          final bool front = k == at;
          // Keyed by its place on the shelf, and wrapped the same way at
          // the front as to the side: a card that changes place in the
          // paint order, or comes to the front, is the same card carried
          // over, not a new one built in its place. Built anew, the card
          // after the fifth started its rim's turn over mid-swipe.
          layers.add(
            Transform.translate(
              key: ValueKey('shelf-layer-$k'),
              offset: Offset(x, 0),
              child: Transform.scale(
                scale: 1 - dist * 0.07,
                // Quieter to the side, as the deck's next card is: drawn
                // toward the page rather than faded into a window onto it.
                child: CardDim(
                  amount: dist * 0.5,
                  ground: context.p.surface,
                  // The day's cards at the shelf's scale, and the card
                  // after them at the deck's.
                  radius: k < deck.length ? 34 * _cardWidth / _artWidth : 34,
                  child: ExcludeSemantics(
                    excluding: !front,
                    child: IgnorePointer(
                      ignoring: !front,
                      child: k < deck.length
                          ? _card(k, deck[k], glow: 1 - dist, front: front)
                          : _sixth(context),
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: (d) => _onTapUp(d, stage),
          onHorizontalDragStart: _onDragStart,
          onHorizontalDragUpdate: _onDragUpdate,
          onHorizontalDragEnd: _onDragEnd,
          child: SizedBox.fromSize(
            size: stage,
            child: OverflowBox(
              maxWidth: stage.width,
              maxHeight: stage.height + _bleed * 2,
              child: _Fade(
                child: SizedBox(
                  width: stage.width,
                  height: stage.height + _bleed * 2,
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: layers,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _card(int k, Pill pill, {required double glow, required bool front}) {
    final app = widget.app;
    final bool saved = app.isSaved(pill.id);
    // The mark the card carried in the deck, kept on the shelf: the reader's
    // own on the free plan, where the others came at random, and a card
    // back for another go on either plan. One card, marked one way.
    final String? chip = app.reviewIdsToday.contains(pill.id)
        ? context.l10n.againChip
        : !app.isPlus && app.ownIdsToday.contains(pill.id)
        ? context.l10n.forYouChip
        : null;
    String picture(bool back) => '${pill.id}-${back ? 'back' : 'front'}';
    Widget face(bool back) => _CardFace(
      key: ValueKey('shelf-face-${pill.id}-${back ? 'back' : 'front'}'),
      pill: pill,
      come: _come.contains(picture(back)),
      onCome: () => _came(picture(back)),
      number: k + 1,
      chip: chip,
      width: _cardWidth,
      height: _cardHeight,
      back: back,
      glow: glow,
      saved: saved,
      liked: app.isLiked(pill.id),
      skill: skillMarkOf(pill, app.skills),
      onSave: () {
        HapticFeedback.mediumImpact();
        app.toggleSaved(pill.id);
      },
      onShare: () => showShareSheet(context, pill),
    );
    if (!front) return face(false);
    // Held down, the card is liked; the bookmark on its back saves it.
    return HoldToKeep(
      saved: app.isLiked(pill.id),
      ink: pill.ink,
      ground: pill.color,
      onToggle: () => app.toggleLiked(pill.id),
      child: FlipCard(showBack: _flipped, front: face(false), back: face(true)),
    );
  }

  /// The shelf's pictures that have come, by card and side: until one has,
  /// its card is its outline in grey, edge and light under it included.
  final Set<String> _come = {};

  void _came(String picture) {
    if (mounted && _come.add(picture)) setState(() {});
  }

  /// Reads the tag of each drawn card on the shelf with a heart or a skill's
  /// mark from its page, so they stand before the tag; drawn again once it
  /// is known.
  void _learnTags(List<Pill> deck) {
    for (final Pill pill in deck) {
      if (pill.web == null || CardTags.knows(pill.id)) continue;
      if (!widget.app.isLiked(pill.id) &&
          skillMarkOf(pill, widget.app.skills) == null) {
        continue;
      }
      CardTags.learn(pill).then((_) {
        if (mounted) setState(() {});
      });
    }
  }

  /// The card after the five: the same one that appears when the fifth is
  /// thrown, kept here as the last card on the shelf, with no way past it
  /// but a swipe — which is the way past every other card.
  Widget _sixth(BuildContext context) {
    final app = widget.app;
    final l = context.l10n;
    return SizedBox(
      key: const ValueKey('shelf-magic'),
      width: _cardWidth,
      height: _cardHeight,
      child: MagicCard(
        eyebrow: l.plusNameCaps,
        note: weekNoteOf(context, app),
        headline: l.plusCardHeadline,
        line: l.magicLine,
        action: plusActionOf(context),
        onAction: _sell,
      ),
    );
  }
}

/// A count as a word, for the labels that say "today's five".
String spellCount(int n) {
  const words = [
    'NONE',
    'ONE',
    'TWO',
    'THREE',
    'FOUR',
    'FIVE',
    'SIX',
    'SEVEN',
    'EIGHT',
    'NINE',
    'TEN',
  ];
  return n < words.length ? words[n] : '$n';
}

/// The shelf dissolves at its sides, and a little at the foot, so the
/// cards read as passing behind the frame rather than being cut off by it.
class _Fade extends StatelessWidget {
  const _Fade({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (rect) => const LinearGradient(
        colors: [
          Color(0x00000000),
          Colors.black,
          Colors.black,
          Color(0x00000000),
        ],
        stops: [0, 0.08, 0.92, 1],
      ).createShader(rect),
      child: ShaderMask(
        blendMode: BlendMode.dstIn,
        shaderCallback: (rect) => const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black, Colors.black, Color(0x8C000000)],
          stops: [0, 0.88, 1],
        ).createShader(rect),
        child: child,
      ),
    );
  }
}

/// One face of a card on the shelf.
///
/// The front carries the question and the line to bring it up with; the
/// back the question small and the whole reveal under it. Both keep the
/// subject's mark at the top and the two things you do to a card at the
/// foot, so turning it over changes what you read and not where things are.
class _CardFace extends StatelessWidget {
  const _CardFace({
    super.key,
    required this.pill,
    required this.number,
    this.chip,
    required this.width,
    required this.height,
    required this.back,
    required this.glow,
    required this.saved,
    this.liked = false,
    this.skill,
    required this.onSave,
    required this.onShare,
    this.come = true,
    this.onCome,
  });

  final Pill pill;
  final int number;

  /// Whether the card's picture has come. Until it has, the card is plain
  /// grey with its save and share (CardThumb.waiting), and its edge and the
  /// light under it are grey too: nothing of its colour shows before the
  /// card does.
  final bool come;

  /// Told once the card's picture has come.
  final VoidCallback? onCome;

  /// Whether the reader liked the card: a heart in its head, on the right.
  final bool liked;

  /// The skill in focus the card trains, if any: its mark before the heart,
  /// as in the deck, only seen here.
  final Skill? skill;

  /// The deck's mark beside the subject, "For you" or "Again", when the
  /// card carried one.
  final String? chip;
  final double width;
  final double height;
  final bool back;

  /// How much of the card's own colour is thrown on the ground under it,
  /// 0 to 1. Full at the front, gone a step away.
  final double glow;
  final bool saved;
  final VoidCallback onSave;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final double s = width / _TodayDoneViewState._artWidth;
    final Color ink = pill.ink;
    // The card's own second and third colours: the ink let down for the
    // small print, and let down further for a panel. A pale card's dark
    // ink needs a touch less of both than white does on a saturated one.
    final bool darkInk = ink.computeLuminance() < 0.5;
    final Color sub = ink.withValues(alpha: darkInk ? 0.6 : 0.66);
    final Color soft = ink.withValues(alpha: darkInk ? 0.10 : 0.14);

    final Palette p = context.p;
    final CardSide side = back ? CardSide.back : CardSide.front;
    final Widget words = Padding(
      padding: EdgeInsets.all(28 * s),
      child: _words(context, s, ink: ink, sub: sub, soft: soft),
    );
    // A free card with its picture is shown by it, whole: the card as the
    // reader met it, drawing and all, on the same shape, edge and glow as
    // any card here. Where the picture will not come, its words, as on a
    // card that has none.
    if (CardThumb.has(pill, side)) {
      final Color ground = groundOf(pill);
      // Of the card's two pictures, the one nearer its shape: on most phones
      // the one taken at the shelf's own proportion, which fills the card
      // from side to side as every card does; on a card the room has made
      // taller, the one taken at the deck's.
      final bool atShelf =
          width / height > (WebThumbs.shelfAspect + WebThumbs.aspect) / 2;
      final Color mark = pill.web?.ground == null ? ink : inkOn(ground);
      return Container(
        key: const ValueKey('shelf-picture'),
        width: width,
        height: height,
        decoration: come
            ? _decoration(p, s, ground)
            : _decoration(p, s, CardThumb.waitingColour(p), glowing: false),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(34 * s),
          child: CardThumb(
            pill: pill,
            side: side,
            onCome: onCome,
            // Taken 366 points across either way (tool/cards/thumbs.cjs): at
            // the shelf's proportion, 366 by 511, so the page lays itself out
            // with nearly the room it has on the deck and its drawing is
            // drawn again at that size, not squashed (the owner's phone, a
            // card of Space, once); its content then lines up with the card's
            // sides, where the deck's picture, narrower than the card, stood
            // in its middle with a band of ground either side (the owner's
            // phone, a card of Psychology). Whole, from the top.
            shelf: atShelf,
            large: !atShelf,
            fit: BoxFit.contain,
            // While it comes, the card in grey with its save and share, in
            // the grey's ink, as a photo still coming sits under its post's
            // own buttons.
            waiting: _PictureControls(
              aspect: atShelf ? WebThumbs.shelfAspect : WebThumbs.aspect,
              saved: saved,
              ink: p.ink.withValues(alpha: p.isDark ? 0.55 : 0.5),
              onSave: onSave,
              onShare: onShare,
            ),
            // Where the picture will not come, the card in words, with the
            // same save and share as everywhere else.
            fallback: ColoredBox(
              color: pill.color,
              child: Stack(
                children: [
                  Positioned.fill(child: words),
                  Positioned.fill(
                    child: _PictureControls(
                      aspect: width / height,
                      saved: saved,
                      ink: ink,
                      onSave: onSave,
                      onShare: onShare,
                    ),
                  ),
                ],
              ),
            ),
            foreground: _PictureControls(
              aspect: atShelf ? WebThumbs.shelfAspect : WebThumbs.aspect,
              saved: saved,
              liked: liked,
              skill: CardTags.read(pill.id) ? skill : null,
              subject: pill.topic,
              tag: CardTags.of(pill.id),
              ink: mark,
              onSave: onSave,
              onShare: onShare,
            ),
          ),
        ),
      );
    }
    // The save and share where the deck has them, at the deck's size: the
    // same on a card in words as on a drawn one (the owner: every card, the
    // same buttons in the same place).
    return Container(
      width: width,
      height: height,
      decoration: _decoration(p, s, pill.color),
      child: Stack(
        children: [
          Positioned.fill(child: words),
          Positioned.fill(
            child: _PictureControls(
              aspect: width / height,
              saved: saved,
              ink: ink,
              onSave: onSave,
              onShare: onShare,
            ),
          ),
        ],
      ),
    );
  }

  /// The card's shape, edge, glow and lift in [colour].
  BoxDecoration _decoration(
    Palette p,
    double s,
    Color colour, {
    bool glowing = true,
  }) {
    return BoxDecoration(
      color: colour,
      // The deck's corner, at the shelf's scale: one card, one shape.
      borderRadius: BorderRadius.circular(34 * s),
      border: cardHairline(colour, p.surface),
      boxShadow: [
        // A pool under the card rather than a wash over the screen: the
        // canvas throws the card's colour across the whole page, which on
        // a real phone reads as a filter over the app instead of as a lit
        // object. Kept low and close, the same colour reads as light
        // coming off the card — but pulled all the way in it stopped
        // reaching the ground at all, so it spreads further than it did
        // on the first pass and less far than the canvas asks.
        if (glow > 0 && glowing)
          BoxShadow(
            color: pill.color.withValues(
              alpha: (p.isDark ? 0.52 : 0.36) * glow,
            ),
            offset: Offset(0, 30 * s),
            blurRadius: 64 * s,
            spreadRadius: -26 * s,
          ),
        // On paper, the deck's own lift under the pool. Half of black,
        // blurred, was a grey slab there; on the night paper it was
        // black on black, and is not drawn.
        ...cardLift(p),
      ],
    );
  }

  /// The card in words: its head, the question or the reveal, and the two
  /// things you do to a card at its foot.
  Widget _words(
    BuildContext context,
    double s, {
    required Color ink,
    required Color sub,
    required Color soft,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CardMark(pill: pill, size: 16 * s, ink: ink),
            SizedBox(width: 8 * s),
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      context.l10n.subjectOf(pill.topic).toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.label(
                        size: 9.5 * s,
                        weight: FontWeight.w700,
                        spacing: 1.4,
                        color: sub,
                      ),
                    ),
                  ),
                  if (chip case final String chip) ...[
                    SizedBox(width: 8 * s),
                    // The deck's own chip, at the shelf's scale.
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 7 * s,
                        vertical: 2.5 * s,
                      ),
                      decoration: BoxDecoration(
                        color: pill.wash,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        chip,
                        maxLines: 1,
                        style: AppText.label(
                          size: 8.5 * s,
                          spacing: 1,
                          color: ink.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (skill case final Skill skill) ...[
              SkillMark(
                skill: skill,
                ink: ink,
                scale: s,
                reach: SkillMark.size,
              ),
              SizedBox(width: SkillMark.gap * s),
            ],
            if (liked) ...[
              LikedMark(ink: ink, scale: s),
              SizedBox(width: 8 * s),
            ],
            Text(
              number.toString().padLeft(2, '0'),
              style: AppText.label(
                size: 9.5 * s,
                weight: FontWeight.w700,
                color: sub,
              ),
            ),
          ],
        ),
        SizedBox(height: 22 * s),
        Expanded(
          child: back
              ? _Back(pill: pill, scale: s, sub: sub)
              : _Front(pill: pill, scale: s, sub: sub),
        ),
        SizedBox(height: 22 * s),
        // The save and share are laid over the card where the deck puts
        // them ([_PictureControls]); this row keeps their room.
        SizedBox(
          height: 42 * s,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  context.l10n.tapToFlip,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.label(
                    size: 10 * s,
                    weight: FontWeight.w600,
                    spacing: 1.1,
                    color: sub,
                  ),
                ),
              ),
              SizedBox(width: width * (109 / 366) - 28 * s + 8 * s),
            ],
          ),
        ),
      ],
    );
  }
}

/// The save and share of a card shown by its picture, where the deck puts
/// them on the same card: in the corner the page keeps empty for them, at
/// the deck's measures scaled to the picture, so they sit on its ground and
/// never on its words.
class _PictureControls extends StatelessWidget {
  const _PictureControls({
    required this.aspect,
    required this.saved,
    this.liked = false,
    this.skill,
    this.subject,
    this.tag,
    required this.ink,
    required this.onSave,
    required this.onShare,
  });

  /// The proportion of the picture under them, width over height.
  final double aspect;

  final bool saved;

  /// Whether the card is liked, and the tag its picture prints on the right
  /// of its head: the heart stands just before it, where the page puts it.
  final bool liked;
  final String? tag;

  /// The skill in focus the card trains, if any, its mark before the heart,
  /// once the page has been read for its [tag]; and the card's subject,
  /// which the picture names in English (tool/cards/thumbs.cjs), so the mark
  /// is left out where the name would run into it.
  final Skill? skill;
  final String? subject;
  final Color ink;
  final VoidCallback onSave;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        // Where the picture lies in the card, drawn whole from the top.
        final bool wide = box.maxWidth / box.maxHeight > aspect;
        final double picture = wide ? box.maxHeight * aspect : box.maxWidth;
        final double side = (box.maxWidth - picture) / 2;
        // The pair sits at the card's foot, as on a card in words, under the
        // picture's ground where the card is taller than the picture.
        const double foot = 0;
        // The page was taken 366 points across, the deck's own width, at
        // either proportion; its pair of 44 sits 17 in from the side and 15
        // up from the foot, 4 apart (pill_card.dart).
        final double k = picture / 366;
        final double middle = SkillMark.middleOnPage(tag, liked: liked);
        return Stack(
          children: [
            if (skill case final Skill skill
                when SkillMark.fits(
                  width: 366,
                  middle: middle,
                  subject: lookupAppLocalizations(const Locale('en'))
                      .subjectOf(subject ?? ''),
                ))
              Positioned(
                top: (CardTags.headMiddle - SkillMark.size / 2) * k,
                right: side + (middle - SkillMark.size / 2) * k,
                child: SkillMark(
                  skill: skill,
                  ink: ink,
                  scale: k,
                  reach: SkillMark.size,
                ),
              ),
            if (liked)
              Positioned(
                top: (CardTags.headMiddle - LikedMark.size / 2) * k,
                right: side + CardTags.heartRight(tag) * k,
                child: LikedMark(ink: ink, scale: k),
              ),
            Positioned(
              right: side + 17 * k,
              bottom: foot + 15 * k,
              child: Row(
                children: [
                  _HeartButton(
                    saved: saved,
                    ink: ink,
                    size: 44 * k,
                    onTap: onSave,
                  ),
                  SizedBox(width: 4 * k),
                  _CardButton(
                    label: context.l10n.shareThisCard,
                    icon: Icons.ios_share_rounded,
                    ink: ink,
                    size: 44 * k,
                    onTap: onShare,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// The question, set as large as the card will take it, and the line to
/// bring it up with under a rule.
class _Front extends StatelessWidget {
  const _Front({required this.pill, required this.scale, required this.sub});

  final Pill pill;
  final double scale;
  final Color sub;

  TextStyle _question(double size) => AppText.display(
    size: size,
    weight: FontWeight.w600,
    height: 1.1,
    spacing: -size * 0.035,
    color: pill.ink,
  );

  @override
  Widget build(BuildContext context) {
    final double s = scale;
    final TextStyle line = AppText.body(
      size: 15.5 * s,
      weight: FontWeight.w500,
      height: 1.42,
      color: sub,
    );
    return LayoutBuilder(
      builder: (context, box) {
        // The artboard sets the question at 31 and the line follows it
        // directly. A question that would not fit at 31 comes down until it
        // does, and one that would not fit at all is cut with an ellipsis
        // rather than spilling — the whole of it is on the back.
        //
        // Measured once per card and box. A drag rebuilds the shelf every
        // frame, and laying text out seven times over for three cards on
        // each of them is work nobody asked for.
        // Measured in the style the Text will actually set: whatever the
        // style leaves unsaid, the screen's default fills in, letter
        // spacing included, and the painter has to see the same.
        final TextStyle base = DefaultTextStyle.of(context).style;
        // At the phone's own text size, as the Text below will set it: a
        // reader with larger text was measured at the standard size, told
        // the question fit, and shown it cut off with an ellipsis.
        final TextScaler scaler = MediaQuery.textScalerOf(context);
        final String key =
            '${pill.id}|${box.maxWidth}|${box.maxHeight}|$s|${scaler.scale(10)}';
        final (double size, double room) = _fits.putIfAbsent(key, () {
          if (_fits.length > 64) _fits.clear();
          final double lineHeight = _measure(
            pill.barMove,
            base.merge(line),
            box.maxWidth,
            maxLines: 3,
            scaler: scaler,
          );
          final double room = box.maxHeight - lineHeight - 1 - 36 * s;
          return (
            _fit(
              pill.question,
              (size) => base.merge(_question(size)),
              box.maxWidth,
              room,
              // Far enough down that the whole question nearly always fits:
              // the reader sees it entire, never cut.
              min: 14 * s,
              max: 31 * s,
              scaler: scaler,
            ),
            room,
          );
        });
        final int lines = math.max(
          1,
          (room / scaler.scale(size * 1.1)).floor(),
        );
        // Measured to fit, and still allowed a few pixels over, clipped: a
        // font's real line box can run a hair past its nominal height, and
        // the hair of a descender is not worth a striped bar.
        return ClipRect(
          child: OverflowBox(
            alignment: Alignment.topLeft,
            minHeight: 0,
            maxHeight: box.maxHeight + 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  pill.question,
                  maxLines: lines,
                  overflow: TextOverflow.ellipsis,
                  style: _question(size),
                ),
                SizedBox(height: 18 * s),
                Container(height: 1, color: pill.ink.withValues(alpha: 0.2)),
                SizedBox(height: 18 * s),
                Text(
                  pill.barMove,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: line,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static final Map<String, (double, double)> _fits = {};

  static double _measure(
    String text,
    TextStyle style,
    double width, {
    int? maxLines,
    TextScaler scaler = TextScaler.noScaling,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      maxLines: maxLines,
      textScaler: scaler,
    )..layout(maxWidth: width);
    return painter.height;
  }

  /// The largest size in the band at which [text] fits the box.
  static double _fit(
    String text,
    TextStyle Function(double) styleFor,
    double width,
    double height, {
    required double min,
    required double max,
    TextScaler scaler = TextScaler.noScaling,
  }) {
    if (!width.isFinite || !height.isFinite || width <= 0 || height <= 0) {
      return min;
    }
    bool fits(double size) =>
        _measure(text, styleFor(size), width, scaler: scaler) <= height;
    if (fits(max)) return max;
    var lo = min;
    var hi = max;
    while (hi - lo > 0.25) {
      final mid = (lo + hi) / 2;
      if (fits(mid)) {
        lo = mid;
      } else {
        hi = mid;
      }
    }
    return lo;
  }
}

/// The back of a card, as the canvas draws it: the question again small
/// and quiet, the answer, a hairline, and the line to bring it up with.
///
/// Not the deck's full reveal — no hint, no worked steps, no counterpoint.
/// Those belong to the card being answered for the first time; this is a
/// shelf, and what a person wants off a shelf at the end of the day is the
/// one thing the card said.
///
/// The canvas was drawn around a four-line answer. Real ones run longer, so
/// the whole block is set down a size or two until it fits — the same move
/// the front makes with the question, and it keeps the canvas's
/// proportions rather than clipping its last line in half.
class _Back extends StatelessWidget {
  const _Back({required this.pill, required this.scale, required this.sub});

  final Pill pill;
  final double scale;
  final Color sub;

  /// How far the block may be set down before it is left to scroll.
  static const double _floor = 0.76;

  TextStyle _questionStyle(double s) => AppText.display(
    size: 15 * s,
    weight: FontWeight.w600,
    height: 1.3,
    spacing: -0.3,
    color: sub,
  );

  TextStyle _answerStyle(double s) =>
      AppText.body(size: 16.5 * s, height: 1.44, color: pill.ink);

  TextStyle _lineStyle(double s) => AppText.body(
    size: 14.5 * s,
    weight: FontWeight.w500,
    height: 1.4,
    color: sub,
  );

  /// Measured in the style the Text widget will actually set — a Text
  /// takes whatever the screen's default style says for anything the
  /// style leaves unsaid, letter spacing included, and a quarter of a
  /// point of tracking the painter never saw was a whole extra line.
  double _height(
    String text,
    TextStyle style,
    double width,
    TextStyle base,
    TextScaler scaler,
  ) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: base.merge(style)),
      textDirection: TextDirection.ltr,
      textScaler: scaler,
    )..layout(maxWidth: width);
    return painter.height;
  }

  /// The block's height at scale [s]: the three texts, the three gaps of
  /// sixteen between and around the rule, and the rule.
  double _blockHeight(
    double s,
    double width,
    TextStyle base,
    TextScaler scaler,
  ) =>
      _height(pill.question, _questionStyle(s), width, base, scaler) +
      48 * s +
      _height(pill.answer, _answerStyle(s), width, base, scaler) +
      1 +
      _height(pill.barMove, _lineStyle(s), width, base, scaler);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final TextStyle base = DefaultTextStyle.of(context).style;
        final TextScaler scaler = MediaQuery.textScalerOf(context);
        final double full = scale;
        double s = full;
        if (_blockHeight(s, box.maxWidth, base, scaler) > box.maxHeight) {
          var lo = full * _floor;
          var hi = full;
          while (hi - lo > full * 0.01) {
            final mid = (lo + hi) / 2;
            if (_blockHeight(mid, box.maxWidth, base, scaler) <=
                box.maxHeight) {
              lo = mid;
            } else {
              hi = mid;
            }
          }
          s = lo;
        }

        final Widget body = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(pill.question, style: _questionStyle(s)),
            SizedBox(height: 16 * s),
            Text(pill.answer, style: _answerStyle(s)),
            SizedBox(height: 16 * s),
            Container(height: 1, color: pill.ink.withValues(alpha: 0.2)),
            SizedBox(height: 16 * s),
            Text(pill.barMove, style: _lineStyle(s)),
          ],
        );

        // Past the floor it scrolls, and the foot of it dissolves rather
        // than being cut: text sliced through the middle of a line reads as
        // a fault, text fading out reads as more below.
        final bool fits =
            _blockHeight(s, box.maxWidth, base, scaler) <= box.maxHeight;
        final Widget rising = RiseIn(
          duration: const Duration(milliseconds: 300),
          distance: 8,
          child: body,
        );
        if (fits) {
          return SizedBox(
            width: box.maxWidth,
            height: box.maxHeight,
            child: rising,
          );
        }
        return ShaderMask(
          blendMode: BlendMode.dstIn,
          shaderCallback: (rect) => const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black, Colors.black, Color(0x00000000)],
            stops: [0, 0.9, 1],
          ).createShader(rect),
          child: SingleChildScrollView(child: rising),
        );
      },
    );
  }
}

/// A square control drawn on the card, in the card's own ink on a panel of
/// the card's own colour let down.
class _CardButton extends StatelessWidget {
  const _CardButton({
    required this.label,
    required this.icon,
    required this.ink,
    required this.size,
    required this.onTap,
    this.child,
  });

  final String label;
  final IconData icon;
  final Color ink;
  final double size;
  final VoidCallback onTap;

  /// Something to draw instead of [icon].
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        // The deck's own control (pill_card.dart): the mark alone, 20 in a
        // square of 44, in the card's ink let down, at the card's scale.
        child: SizedBox.square(
          dimension: size,
          child: Center(
            child:
                child ??
                Icon(
                  icon,
                  size: size * 20 / 44,
                  color: ink.withValues(alpha: 0.62),
                ),
          ),
        ),
      ),
    );
  }
}

/// The bookmark, which swells for a moment when it fills. Keeping a card
/// is the one thing a reader does here that is worth marking.
class _HeartButton extends StatefulWidget {
  const _HeartButton({
    required this.saved,
    required this.ink,
    required this.size,
    required this.onTap,
  });

  final bool saved;
  final Color ink;
  final double size;
  final VoidCallback onTap;

  @override
  State<_HeartButton> createState() => _HeartButtonState();
}

class _HeartButtonState extends State<_HeartButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
  );

  @override
  void didUpdateWidget(covariant _HeartButton old) {
    super.didUpdateWidget(old);
    if (!old.saved && widget.saved) {
      _pop
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _pop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool still = MediaQuery.disableAnimationsOf(context);
    return _CardButton(
      label: widget.saved
          ? context.l10n.removeFromSaved
          : context.l10n.saveThisPill,
      icon: widget.saved
          ? Icons.bookmark_rounded
          : Icons.bookmark_border_rounded,
      ink: widget.ink,
      size: widget.size,
      onTap: widget.onTap,
      child: still
          ? null
          : AnimatedBuilder(
              animation: _pop,
              builder: (context, child) {
                // Up to 1.35 by two fifths of the way, and back.
                final double t = Curves.easeOut.transform(_pop.value);
                final double scale = 1 + 0.35 * math.sin(math.pi * t);
                return Transform.scale(scale: scale, child: child);
              },
              child: Icon(
                widget.saved
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_border_rounded,
                size: widget.size * 20 / 44,
                color: widget.ink.withValues(alpha: 0.62),
              ),
            ),
    );
  }
}

/// One dot a card, the front one drawn long and in its colour.
class _Dots extends StatelessWidget {
  const _Dots({
    required this.deck,
    required this.count,
    required this.at,
    required this.onPick,
  });

  final List<Pill> deck;

  /// The dots to draw: one per card, and one more for the offer after
  /// them, which takes every colour rather than one.
  final int count;
  final int at;
  final ValueChanged<int> onPick;

  /// 14 above the dots and 8 below them, on the canvas.
  static const double height = 28;

  @override
  Widget build(BuildContext context) {
    final bool still = MediaQuery.disableAnimationsOf(context);
    final Color faint = context.p.ink.withValues(alpha: 0.18);
    return SizedBox(
      height: height,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (int k = 0; k < count; k++)
            Semantics(
              button: true,
              selected: k == at,
              label: k < deck.length
                  ? context.l10n.cardOf(k + 1, deck.length)
                  : context.l10n.plusNameCaps,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onPick(k),
                // A six-point dot is not a target. Each one takes a slice
                // of the whole row instead — which is the height the
                // canvas gives the row anyway, so nothing grows.
                child: SizedBox(
                  width: (k == at ? 22 : 6) + 7,
                  height: height,
                  child: Center(
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: still ? 0 : 350),
                      curve: Curves.easeOut,
                      width: k == at ? 22 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: k < deck.length
                            ? (k == at ? deck[k].color : faint)
                            : null,
                        // The offer's dot is every colour when it is the
                        // one, and grey as a gradient of greys when it is
                        // not, so the change is each grey turning into its
                        // colour, as quick as the other dots. Grey as a
                        // plain colour, the dot faded the rainbow in from
                        // nothing and arrived half a second late.
                        gradient: k < deck.length
                            ? null
                            : LinearGradient(
                                colors: k == at
                                    ? kSpectrum
                                    : List<Color>.filled(
                                        kSpectrum.length,
                                        faint,
                                      ),
                              ),
                        borderRadius: BorderRadius.circular(9),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// What opens tomorrow, and when.
///
/// Tomorrow's deck is dealt from the date and the reading history, both of
/// which are settled by tonight, so the subject named here is the one that
/// will actually be on top in the morning.
class _Tomorrow extends StatelessWidget {
  const _Tomorrow({required this.lead});

  /// The card on top of tomorrow's deck, or null if there is somehow none.
  final Pill? lead;

  @override
  Widget build(BuildContext context) {
    final Pill? lead = this.lead;
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final left = tomorrow.difference(now);
    final int hours = left.inHours;
    final int minutes = left.inMinutes % 60;
    final String when = hours >= 1 ? '${hours}h ${minutes}m' : '${minutes}m';

    // A subject's colour is its mark's colour, unless the ground is so close
    // to it that the mark vanishes — Thinking's white on paper. Measured as a
    // contrast ratio, not a difference in luminance: Cinema's violet sits
    // near black in luminance yet reads plainly on it.
    Color tint = lead?.color ?? context.p.ink;
    final a = tint.computeLuminance(), b = context.p.surface.computeLuminance();
    if ((math.max(a, b) + 0.05) / (math.min(a, b) + 0.05) < 1.6) {
      tint = context.p.ink;
    }

    return Row(
      children: [
        if (lead != null) ...[
          CardMark(pill: lead, size: 20, ink: tint),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Text(
            lead == null
                ? context.l10n.tomorrowsFiveOpenIn(when)
                : context.l10n.topicOpensTomorrow(
                    context.l10n.subjectOf(lead.topic),
                    when,
                  ),
            style: AppText.body(
              size: 13.5,
              weight: FontWeight.w500,
              height: 1.35,
              color: context.p.ink.withValues(alpha: 0.6),
            ),
          ),
        ),
      ],
    );
  }
}

/// The canvas's button: flat, 52 by 18, the label and an arrow behind it.
///
/// Not the app's chunky button, which is right where a press is a
/// commitment — an answer, a purchase — and too heavy for a door out of a
/// screen that is finished. It still gives under the finger.
class _JourneyButton extends StatefulWidget {
  const _JourneyButton({required this.onPressed, this.locked = false});

  final VoidCallback onPressed;

  /// True on the free plan, where the journey is Astute+ and the button
  /// says so before it is pressed: a lock where the arrow would be.
  final bool locked;

  @override
  State<_JourneyButton> createState() => _JourneyButtonState();
}

class _JourneyButtonState extends State<_JourneyButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final Color ink = context.p.onInverse;
    return Semantics(
      button: true,
      label: context.l10n.yourJourney,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _down = true),
        onTapUp: (_) => setState(() => _down = false),
        onTapCancel: () => setState(() => _down = false),
        onTap: () {
          HapticFeedback.lightImpact();
          widget.onPressed();
        },
        child: AnimatedScale(
          scale: _down ? 0.98 : 1,
          duration: const Duration(milliseconds: 90),
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              color: context.p.inverse,
              borderRadius: BorderRadius.circular(18),
            ),
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    context.l10n.yourJourney,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.body(
                      size: 14.5,
                      weight: FontWeight.w700,
                      color: ink,
                    ),
                  ),
                ),
                const SizedBox(width: 9),
                widget.locked
                    ? Icon(
                        Icons.lock_rounded,
                        size: 13,
                        color: ink.withValues(alpha: 0.55),
                      )
                    : Text(
                        '\u2192',
                        style: AppText.body(
                          size: 14,
                          color: ink.withValues(alpha: 0.45),
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The way on: the journey, which is Astute+, the whole width. The day sent
/// as five squares used to stand beside it as a second button, which made
/// the row two things to choose between; it is a mark at the end of the
/// shelf's heading now ([_DayTools]), where it costs the shelf nothing. The
/// offer stays the sixth card on the shelf; nothing in this row sells.
class _Actions extends StatelessWidget {
  const _Actions({required this.app});

  final AppState app;

  @override
  Widget build(BuildContext context) {
    final Widget journey = _JourneyButton(
      locked: !app.isPlus,
      onPressed: () => requirePlus(
        context,
        app,
        () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (routeContext) => JourneyScreen(
              app: app,
              onBack: () => Navigator.of(routeContext).pop(),
            ),
          ),
        ),
        source: 'journey',
      ),
    );
    return journey;
  }
}

/// The end of the shelf's heading: the day's five again at full size, and
/// the day sent as five squares once it is closed.
///
/// "See again" opens the cards themselves, the way they first came, which is
/// what a tap on the widget does; the shelf above only has them in small.
/// The day is sent with no gate, on either plan, as it always was: a day in
/// somebody's chat is how the app travels.
/// The day's line at the head of the shelf — a dot in the front card's
/// colour, which day this was — and under it, small, the freeze spent or,
/// until the reader has liked a card, how to. A liked card says so on
/// itself, with the heart in its corner, rather than as a count here.
class _DayHeading extends StatelessWidget {
  const _DayHeading({
    required this.line,
    required this.aside,
    required this.dot,
  });

  final String line;
  final String? aside;
  final Color dot;

  /// The dot and the air after it.
  static const double dotRoom = 18;

  /// The size the line is set at, and the least it shrinks to before the
  /// buttons beside it give up their words.
  static const double size = 17;
  static const double least = 15;

  static TextStyle lineStyle(Color ink, {double size = size}) => AppText.body(
    size: size,
    weight: FontWeight.w600,
    spacing: -0.2,
    height: 1.2,
    color: ink,
  );

  @override
  Widget build(BuildContext context) {
    final bool still = MediaQuery.disableAnimationsOf(context);
    final Color ink = context.p.ink;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          // On the line's middle: a line of 17 at 1.2 is 20.4 high.
          padding: const EdgeInsets.only(top: 6.2),
          child: AnimatedContainer(
            duration: Duration(milliseconds: still ? 0 : 500),
            curve: Curves.easeOut,
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
          ),
        ),
        const SizedBox(width: dotRoom - 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Semantics(
                header: true,
                child: FitText(
                  line,
                  maxLines: 1,
                  minSize: 13,
                  style: lineStyle(ink),
                ),
              ),
              // The line under goes the moment the reader's first card is
              // liked; the shelf under it closes up in a beat, not a jump.
              AnimatedSize(
                duration: Duration(milliseconds: still ? 0 : 260),
                curve: Curves.easeOut,
                alignment: Alignment.topLeft,
                child: aside == null
                    ? const SizedBox(width: double.infinity)
                    : Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: FitText(
                          aside!,
                          key: const ValueKey('shelf-aside'),
                          maxLines: 2,
                          minSize: 11,
                          style: AppText.body(
                            size: 12,
                            weight: FontWeight.w500,
                            height: 1.25,
                            color: ink.withValues(alpha: 0.42),
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DayTools extends StatelessWidget {
  const _DayTools({
    required this.app,
    required this.onSeeAgain,
    this.compact = false,
  });

  final AppState app;
  final VoidCallback onSeeAgain;

  /// The mark alone, without its word, where the line is short.
  final bool compact;

  static TextStyle _labelStyle(Color ink) =>
      AppText.body(size: 12.5, weight: FontWeight.w700, color: ink);

  /// How wide the two take on the line.
  static double widthOf(
    BuildContext context,
    AppState app, {
    required bool compact,
  }) {
    double width = compact ? 28 : 9 + 17 + 3 + 12;
    if (!compact) {
      width += _TodayDoneViewState._width(
        context,
        context.l10n.todaySeeAgain,
        _labelStyle(context.p.ink),
      );
    }
    if (app.dayClosed) width += 40;
    return width;
  }

  @override
  Widget build(BuildContext context) {
    final Color ink = context.p.ink;
    final l = context.l10n;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          button: true,
          label: l.todaySeeAgain,
          hint: l.todaySeeAgainHint,
          excludeSemantics: true,
          child: GestureDetector(
            key: const ValueKey('shelf-see-again'),
            behavior: HitTestBehavior.opaque,
            onTap: onSeeAgain,
            // 36 high to the finger, 28 to the eye.
            child: SizedBox(
              height: 36,
              child: Center(
                child: Container(
                  height: 28,
                  width: compact ? 28 : null,
                  padding: compact
                      ? EdgeInsets.zero
                      : const EdgeInsets.fromLTRB(9, 0, 12, 0),
                  decoration: BoxDecoration(
                    color: ink.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: compact
                      ? Icon(Icons.play_arrow_rounded, size: 17, color: ink)
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.play_arrow_rounded,
                              size: 17,
                              color: ink,
                            ),
                            const SizedBox(width: 3),
                            Text(l.todaySeeAgain, style: _labelStyle(ink)),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ),
        // Once the day is closed, the same test the journey's foot makes:
        // the squares are the closed day's.
        if (app.dayClosed)
          Semantics(
            button: true,
            label: l.shareMyDay,
            excludeSemantics: true,
            child: GestureDetector(
              key: const ValueKey('shelf-share-day'),
              behavior: HitTestBehavior.opaque,
              onTap: () => ShareDay.send(context, app, from: 'done view'),
              child: SizedBox(
                width: 40,
                height: 36,
                child: Center(
                  child: Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: ink.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.ios_share_rounded, size: 15, color: ink),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
