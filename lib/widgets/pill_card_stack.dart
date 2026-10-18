import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../measure/card_read.dart';
import '../measure/screens.dart';
import '../models/pill.dart';
import '../models/place.dart';
import '../sync/trace.dart';
import '../theme.dart';
import 'card_edge.dart';
import 'flip_card.dart';
import 'pill_card.dart';

/// How much room the deck leaves at each side of the screen.
///
/// Named because two screens draw this deck and they have to agree: a card
/// re-read in the viewer that comes out wider than the one dealt on Today is
/// the same card at two sizes, which reads as two designs.
const double kDeckMargin = 18;

/// Drag sideways to advance, tap to flip — a stack of up to three cards
/// peeking below the top one.
class PillCardStack extends StatefulWidget {
  final List<Pill> deck;
  final int index;

  /// One card after the deck, if there is one: it peeks from under the last
  /// pill like any next card, comes to the top when that one is thrown, and
  /// is thrown the same way. It has no back, asks nothing, and is never
  /// liked, saved or shared — it is drawn as given. Throwing it calls
  /// [onAdvance] like every other card; the caller knows it was the last.
  final Widget? trailing;

  /// Moves the deck on, and is waited on.
  ///
  /// Waited on because the card that left has to stay gone until the next one
  /// is actually here — see [_onPanEnd]. `FutureOr` rather than `Future` so a
  /// parent that moves its own index in a line, like the deck viewer, is not
  /// made to say `async` about it.
  final FutureOr<void> Function() onAdvance;

  /// What the reader has already committed to, and where to record a new
  /// commitment. Raw strings: the challenge knows how to read its own.
  final Answer? Function(String id) answerFor;
  final void Function(
    String id,
    String response,
    int? confidence,
    String? reason,
  )
  onAnswer;

  /// Which of these cards are back for another go.
  final Set<String> reviewIds;

  /// Which of these cards were chosen for the reader, where the day marks
  /// them — on the free plan, where the others came at random.
  final Set<String> ownIds;

  /// True while a card is under the finger, so the chrome can step out of
  /// the way of the gesture.
  final ValueChanged<bool>? onMotion;

  /// Whether these cards are being answered now, or read back.
  ///
  /// Answering: a card that asks will not turn over until the reader has
  /// committed, which is the whole point of the day. Reading back: the cards
  /// open freely and show the answer that was given, because most of a
  /// finished day was never answered and asking again days later is not a
  /// second first impression — it is a quiz nobody asked for.
  final bool answering;

  /// Keeping and sharing, which the top card carries itself.
  final bool Function(String id) isSaved;
  final ValueChanged<Pill> onSave;
  final ValueChanged<Pill> onShare;

  /// Held down: liked. Left null, a hold does nothing here.
  final bool Function(String id)? isLiked;
  final ValueChanged<Pill>? onLike;

  /// Thrown down, hard and straight: less like this. Left null, a throw
  /// down is a throw like any other.
  final ValueChanged<Pill>? onDislike;

  /// How each card on top was read, told when its stint ends (see
  /// [CardRead]): thrown, or left standing when its screen went out of
  /// sight. A throw is told just before [onAdvance] is called.
  final ValueChanged<CardStint>? onRead;

  /// Told each time a card stands on top with the reader looking at it.
  final ValueChanged<Pill>? onStand;

  /// Whether the reader had read this card before it was put in front of
  /// them here, for a deck of cards read back.
  final bool Function(String id)? readBefore;

  /// Where the reader lives, so a card about a place can say on its front
  /// why it is here; null when they have not said.
  final Place? home;

  /// Whether to show, once, how a card is sent on, for a reader who has
  /// never sent one: a few seconds after the back of the card in front has
  /// come round — or at once, when the reader turns it back to its front
  /// looking for the way on — the card leans aside, as a hand starting to
  /// throw it would, and settles back. [onSwipeHint] is told as it does,
  /// so the screen can say it in words too; with motion reduced, the words
  /// are all there is.
  final bool swipeHint;
  final VoidCallback? onSwipeHint;

  /// How many cards the stack holds: the deck, and the one after it.
  int get count => deck.length + (trailing != null ? 1 : 0);

  const PillCardStack({
    this.trailing,
    super.key,
    required this.deck,
    required this.index,
    required this.onAdvance,
    required this.answerFor,
    required this.onAnswer,
    required this.reviewIds,
    this.ownIds = const {},
    required this.isSaved,
    required this.onSave,
    required this.onShare,
    this.isLiked,
    this.onLike,
    this.onDislike,
    this.answering = true,
    this.onMotion,
    this.onRead,
    this.onStand,
    this.readBefore,
    this.home,
    this.swipeHint = false,
    this.onSwipeHint,
  });

  @override
  State<PillCardStack> createState() => _PillCardStackState();
}

class _PillCardStackState extends State<PillCardStack>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Offset _drag = Offset.zero;
  bool _dragging = false;
  double _dragTotalMove = 0;
  bool _flipped = false;

  /// True once the reader has committed to the card on screen, so a review
  /// can be turned back and forth after it has been answered again.
  bool _answeredHere = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _upAt = DateTime.now();
  }

  /// When the card in front came up, so a turn can say how long the front
  /// held the reader before they wanted the back.
  DateTime? _upAt;

  /// How the card on top is being read, while it stands there in sight.
  CardRead? _read;

  /// True from a card being let go to the deck having moved on.
  bool _throwing = false;

  /// The cards that have stood on top here, so one come back to is said to
  /// be read again.
  final Set<String> _stood = {};

  /// The screen this deck is drawn on, which says when it goes out of
  /// sight. Null for a deck pumped on its own, which is always in sight.
  ScreenPresence? _presence;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ScreenPresence? presence = ScreenPresence.maybeOf(context);
    if (!identical(presence, _presence)) {
      _presence?.removeListener(_stand);
      _presence = presence;
      presence?.addListener(_stand);
    }
    _stand();
  }

  @override
  void didUpdateWidget(covariant PillCardStack old) {
    super.didUpdateWidget(old);
    if (old.index != widget.index) {
      _drag = Offset.zero;
      _flipped = false;
      _answeredHere = false;
      _upAt = DateTime.now();
      _hintTimer?.cancel();
    }
    _stand();
  }

  @override
  void dispose() {
    _hintTimer?.cancel();
    _presence?.removeListener(_stand);
    final CardRead? read = _read;
    if (read != null) _close(read, 'gone');
    _controller.dispose();
    super.dispose();
  }

  Pill? get _top =>
      widget.index < widget.deck.length ? widget.deck[widget.index] : null;

  /// Starts and ends the stints as the card on top and its screen change: a
  /// card stands while it is on top and in sight, and stops standing when
  /// the screen goes — for another tab, a pushed screen, the background.
  void _stand() {
    final Pill? top = _top;
    final bool inSight = _presence?.showing ?? true;
    final CardRead? read = _read;
    if (read != null && (!inSight || read.pill.id != top?.id)) {
      _close(read, inSight ? 'gone' : _leftFor(_presence?.left));
    }
    if (_read != null || top == null || !inSight || !mounted || _throwing) {
      return;
    }
    _read = CardRead(
      top,
      reread:
          _stood.contains(top.id) || (widget.readBefore?.call(top.id) ?? false),
      back: _flipped,
    );
    _stood.add(top.id);
    widget.onStand?.call(top);
  }

  /// A card's way out, from why its screen went out of sight.
  static String _leftFor(String? left) => switch (left) {
    'push' => 'push',
    'background' => 'background',
    'switch' => 'tab',
    _ => 'closed',
  };

  void _close(CardRead read, String exit) {
    if (identical(_read, read)) _read = null;
    if (read.ended) return;
    widget.onRead?.call(read.end(exit));
  }

  void _onPanStart(DragStartDetails d) {
    if (widget.index >= widget.count) return;
    // The reader has found the gesture, or is looking for it with a finger:
    // nothing is shown while a card is held.
    _hintTimer?.cancel();
    _controller.stop();
    _dragging = true;
    _dragTotalMove = 0;
  }

  void _onPanUpdate(DragUpdateDetails d) {
    if (!_dragging) return;
    setState(() {
      // Both axes, one to one with the finger. Sideways only meant a card
      // pulled upward stayed put under the thumb, which reads as the card
      // being stuck rather than held.
      _drag += d.delta;
      _dragTotalMove += d.delta.distance;
    });
    widget.onMotion?.call(true);
  }

  Future<void> _onPanEnd(DragEndDetails d) async {
    if (!_dragging) return;
    _dragging = false;
    widget.onMotion?.call(false);

    final Offset thrown = d.velocity.pixelsPerSecond;
    // Either carried far enough or thrown hard enough. Distance alone made a
    // quick flick do nothing, which is the gesture most people actually make.
    final bool gone = _drag.distance > 78 || thrown.distance > 620;
    if (gone) {
      // Out along the way it was sent — a card pushed up leaves upward. The
      // throw decides the heading when there is one, otherwise the drag does.
      final Offset heading = thrown.distance > 220 ? thrown : _drag;
      // Straight down, and thrown rather than carried: the one heading a
      // card is never sent in by accident, so it can mean something —
      // less like this. A drag that drifts downward on its way sideways
      // is not it.
      // The card after the deck is not a pill: it cannot be disliked.
      final Pill? leaving = widget.index < widget.deck.length
          ? widget.deck[widget.index]
          : null;
      final bool down =
          leaving != null &&
          widget.onDislike != null &&
          thrown.dy > 520 &&
          thrown.dy > thrown.dx.abs() * 1.8;
      if (down) {
        HapticFeedback.mediumImpact();
      } else {
        HapticFeedback.lightImpact();
      }
      // The card's read ends as it is let go, not when it has flown: the
      // flight is the deck's, not the reader's. Flung, carried off past the
      // line, or thrown down, which says less like this. No card stands
      // again until the throw is over.
      _throwing = true;
      final CardRead? read = _read;
      if (read != null && leaving != null) {
        _close(
          read,
          down
              ? 'thrown down'
              : thrown.distance > 620
              ? 'thrown'
              : 'swiped',
        );
      }
      final double length = heading.distance;
      await _animateTo(
        length == 0 ? const Offset(480, 0) : heading * (1100 / length),
      );
      if (!mounted) return;
      if (down) widget.onDislike!(leaving);

      // The card is gone, and it stays gone until the next one is here.
      //
      // This used to put the drag back first and move the deck on after,
      // which is what the throw stuttered on. The index arrives on the far
      // side of three writes to disk — `AppState.advance` records the new
      // position, the cards read and the ids seen before it tells anyone —
      // so for every frame in between, the deck drew the card that had just
      // left back in the middle of the screen at full size, and the card
      // behind it dropped from where it had risen to back down to where it
      // started. Two cards moving backwards, which is the whole of it.
      //
      // Waiting means the new index and the cleared drag land in the same
      // frame: didUpdateWidget clears it the moment a new card is on top, so
      // nothing is ever drawn in between.
      await widget.onAdvance();
      if (!mounted) return;

      // Unless nothing arrived. A deck of one wraps to the same index, and a
      // state that declines to advance would otherwise leave the reader
      // looking at the empty square where their card used to be. By here the
      // clear above has already happened when there was one to do, so this
      // is a no-op in every case but that.
      if (_drag != Offset.zero || _flipped) {
        setState(() {
          _drag = Offset.zero;
          _flipped = false;
        });
      }
      // The card now on top stands, face up, once the deck is built with it
      // — the new index lands with the next frame, not with the await — and
      // even where the deck wrapped round to the one that was just thrown.
      _throwing = false;
      WidgetsBinding.instance
        ..addPostFrameCallback((_) {
          if (mounted) _stand();
        })
        ..ensureVisualUpdate();
    } else if (_dragTotalMove < 7) {
      // Barely moved: put it back where it was and turn it over, with
      // nothing to settle first — the card never went anywhere.
      setState(() => _drag = Offset.zero);
      _turnOver();
    } else {
      await _animateTo(Offset.zero);
      if (_flipped) _hintIn(_hintAfterBack);
    }
  }

  /// How long the back is read before the card shows how it is sent on,
  /// and how soon after a turn back to the front, which is a reader looking
  /// for the way on.
  static const Duration _hintAfterBack = Duration(seconds: 4);
  static const Duration _hintAfterFront = Duration(milliseconds: 600);

  Timer? _hintTimer;

  /// True once the hint has been shown here: it is shown once.
  bool _hinted = false;

  void _hintIn(Duration after) {
    _hintTimer?.cancel();
    if (!widget.swipeHint || _hinted) return;
    _hintTimer = Timer(after, _hint);
  }

  void _hint() {
    if (!mounted || !widget.swipeHint || _hinted) return;
    if (_dragging || _throwing || widget.index >= widget.deck.length) return;
    // Away for another tab or behind another screen: shown when it is
    // back, after the same wait, rather than to nobody.
    if (!(_presence?.showing ?? true)) {
      _hintIn(_hintAfterBack);
      return;
    }
    _hinted = true;
    widget.onSwipeHint?.call();
    if (!MediaQuery.disableAnimationsOf(context)) _lean();
  }

  /// The card leans aside and settles, twice, the second time less: the
  /// start of a throw, shown rather than explained. The card behind rises
  /// a little with it, as it does under a finger.
  Future<void> _lean() async {
    _controller.stop();
    final Animation<double> lean = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 0.0,
          end: -34.0,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: -34.0,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.easeInOutCubic)),
        weight: 32,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 0.0,
          end: -14.0,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 18,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: -14.0,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.easeInOutCubic)),
        weight: 20,
      ),
    ]).animate(_controller);
    void follow() {
      if (mounted && !_dragging) setState(() => _drag = Offset(lean.value, 0));
    }

    _controller
      ..duration = const Duration(milliseconds: 1400)
      ..reset();
    lean.addListener(follow);
    try {
      await _controller.forward().orCancel;
    } on TickerCanceled {
      // Taken by a finger part way: the card is the reader's from there.
    } finally {
      lean.removeListener(follow);
      _controller.duration = const Duration(milliseconds: 300);
    }
  }

  /// Turn the card over.
  ///
  /// This used to be reached only through a pan that happened not to move,
  /// which worked for exactly as long as the deck's drag was the only thing
  /// listening: a second recogniser on the card — a press held to keep it —
  /// puts two of them in the arena, and a still finger then wins nothing at
  /// all. It is a tap, so it is on the tap.
  void _turnOver() {
    if (!mounted) return;
    // The card after the deck has no back.
    if (widget.index >= widget.deck.length) return;
    // A card that asks turns over when the reader commits, not on a stray
    // tap — otherwise the answer can be reached without ever guessing. A
    // card that has come back has an answer already, so it must be asked
    // again rather than opened for free.
    final top = widget.deck[widget.index];
    final mustAnswer =
        widget.answerFor(top.id) == null || widget.reviewIds.contains(top.id);
    if (widget.answering && top.asksSomething && mustAnswer && !_answeredHere) {
      return;
    }
    HapticFeedback.selectionClick();
    setState(() => _flipped = !_flipped);
    _read?.turned(toBack: _flipped);
    _hintIn(_flipped ? _hintAfterBack : _hintAfterFront);
    // The turn itself, for the reader's own trace: a card turned over is a
    // card read, and the dealer hears it. PostHog hears it once, with the
    // rest of how the card was read, when the card leaves (CardRead).
    if (_flipped) {
      final DateTime? upAt = _upAt;
      Trace.instance.note('card flipped', {
        'pill_id': top.id,
        'ms_to_flip': upAt == null
            ? null
            : DateTime.now().difference(upAt).inMilliseconds,
      });
    }
  }

  Future<void> _animateTo(Offset target) async {
    final start = _drag;
    _controller.reset();
    final anim = Tween<Offset>(
      begin: start,
      end: target,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    void listener() {
      if (mounted) setState(() => _drag = anim.value);
    }

    anim.addListener(listener);
    await _controller.forward();
    anim.removeListener(listener);
  }

  /// How far the top card has travelled towards being gone, 0 to 1.
  ///
  /// Everything behind it is placed against this rather than against its
  /// integer position in the stack. That is the whole fix: a card sitting at
  /// depth 1 used to hold a fixed opacity, scale and offset until the index
  /// moved, and then snap to the top card's values in a single frame — which
  /// is what read as the card underneath lighting up all at once. Sliding
  /// depth by the drag means that by the time the index actually moves, the
  /// card below is already exactly where the new top card belongs, and the
  /// change of index is invisible.
  double get _progress => (_drag.distance / 220).clamp(0.0, 1.0);

  /// The tallest a card goes against its own width.
  ///
  /// The deck takes the room it is given, up to this. At 1.55 it sat in
  /// the middle of the screen with a band of black above and below, which
  /// reads as a card measured for a smaller phone; past this it stops
  /// being a card and becomes a column.
  static const double _cardAspect = 1.82;

  /// The least black kept above and below the deck.
  static const double _air = 10;

  /// How much of the card behind shows under the one being read, on every
  /// phone. It used to be sixteen points down less what the smaller card
  /// lost: eight on a small phone, five on a large one, where the sliver
  /// thinned to a line and its rounded ends to nothing.
  static const double _peek = 10;

  /// How much smaller each card further back is drawn.
  static const double _shrink = 0.035;

  /// How far a card further back is drawn toward the page's own colour.
  static double _dimBehind(Palette p) => p.isDark ? 0.4 : 0.45;

  @override
  Widget build(BuildContext context) {
    final remaining = widget.count - widget.index;
    // Three: the card being read, the one behind it, and the one after
    // that waiting at nothing — it fades in only as the top card leaves,
    // so what is on screen is never more than the next question.
    final visible = math.min(3, remaining);
    if (visible <= 0) return const SizedBox.shrink();

    // As big as the room allows, short of a slab: the card takes the
    // height it is given, minus a little black at each end so the deck
    // reads as sitting in a space rather than jammed into one, and stops
    // at a card's tallest proportion.
    //
    // A card's own scrolling — a back too long for a very large text size —
    // is the card's, measured by the card, and goes no further: the screen
    // the deck is on does not scroll when a card does.
    return NotificationListener<ScrollMetricsNotification>(
      onNotification: (_) => true,
      child: NotificationListener<ScrollNotification>(
        onNotification: (_) => true,
        child: Center(
          child: LayoutBuilder(
            builder: (context, box) {
              final double height = math.min(
                math.max(0, box.maxHeight - _air * 2),
                box.maxWidth * _cardAspect,
              );
              return SizedBox(
                width: box.maxWidth,
                height: height,
                child: Stack(children: _layers(context, visible, height)),
              );
            },
          ),
        ),
      ),
    );
  }

  /// The cards on the table, the one furthest back first.
  List<Widget> _layers(BuildContext context, int visible, double height) {
    final progress = _progress;
    final Palette palette = context.p;

    final layers = <Widget>[];
    for (var d = visible - 1; d >= 0; d--) {
      final int k = widget.index + d;
      final isTop = d == 0;
      final Pill? pill = k < widget.deck.length ? widget.deck[k] : null;
      final given = pill == null ? null : widget.answerFor(pill.id);

      // Every depth is built the same shape, whether or not it is the one
      // being read. A card used to be a bare PillCard underneath and a
      // FlipCard on top, which meant the frame the deck landed on threw away
      // the card the reader was about to look at and built it again from
      // nothing — a whole card laid out in the one frame that has to be
      // smooth. Same widgets at every depth, and the card that rises keeps
      // the element it already had: that frame now pays for a transform.
      //
      // The back face is the exception, because it is the one thing a card
      // underneath truly does not have. FlipCard does not build it below a
      // half turn, and nothing but the top card is ever turned.
      final bool controls = isTop;
      Widget card = pill == null
          ? widget.trailing!
          : FlipCard(
              showBack: isTop && _flipped,
              front: PillCard(
                pill: pill,
                flipped: false,
                isReview: widget.reviewIds.contains(pill.id),
                isOwn: widget.ownIds.contains(pill.id),
                home: widget.home,
                given: controls ? given : null,
                saved: controls && widget.isSaved(pill.id),
                onSave: controls ? () => widget.onSave(pill) : null,
                liked: controls && (widget.isLiked?.call(pill.id) ?? false),
                onLike: !controls || widget.onLike == null
                    ? null
                    : () => widget.onLike!(pill),
                onShare: controls ? () => widget.onShare(pill) : null,
                onAnswer: !controls || !widget.answering
                    ? null
                    : (response, confidence, reason) {
                        // The answer's own feel, on the frame it is given:
                        // firmer for right, light for wrong — acknowledged,
                        // never punished.
                        if (pill.isGraded &&
                            !pill.challenge.accepts(response)) {
                          HapticFeedback.lightImpact();
                        } else {
                          HapticFeedback.mediumImpact();
                        }
                        widget.onAnswer(pill.id, response, confidence, reason);
                        setState(() {
                          _answeredHere = true;
                          _flipped = true;
                        });
                        _read?.turned(toBack: true);
                        _hintIn(_hintAfterBack);
                      },
              ),
              back: !isTop
                  ? const SizedBox.shrink()
                  : PillCard(
                      pill: pill,
                      flipped: true,
                      isReview: widget.reviewIds.contains(pill.id),
                      isOwn: widget.ownIds.contains(pill.id),
                      home: widget.home,
                      given: given,
                      saved: widget.isSaved(pill.id),
                      onSave: () => widget.onSave(pill),
                      liked: widget.isLiked?.call(pill.id) ?? false,
                      onLike: widget.onLike == null
                          ? null
                          : () => widget.onLike!(pill),
                      onShare: () => widget.onShare(pill),
                    ),
            );

      // Continuous depth: 1 becomes 0 as the top card leaves.
      final depth = isTop ? 0.0 : d - progress;
      final translateY = depth * (_peek + height * _shrink / 2);
      final scale = 1 - depth * _shrink;
      // The card being dragged stays solid. Fading it turned it into a
      // window onto the card underneath, and two legible questions printed
      // over each other read as a fault rather than as one card leaving. It
      // travels far enough to clear the screen on its own.
      //
      // Behind it, only the next one, solid and quieter: drawn toward the
      // page's colour, and brought back to its own as the top card goes.
      // It used to be faded, and a faded card is a window — the shadow of
      // the card in front and the page showed through, and the edge of the
      // deck read as a grey or olive band. A stack that showed every card
      // it holds would show four questions at once, which is three more
      // than the reader asked for and a spoiler of the rest of the day, so
      // the third is drawn at nothing and arrives only as the top card goes.
      final double dim = isTop
          ? 0.0
          : math.min(depth, 1.0) * _dimBehind(palette);
      final double opacity = depth <= 1 ? 1.0 : (2 - depth).clamp(0.0, 1.0);

      card = Opacity(
        opacity: opacity,
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..translateByDouble(
              isTop ? _drag.dx : 0.0,
              isTop ? translateY + _drag.dy : translateY,
              0.0,
              1.0,
            )
            ..scaleByDouble(scale, scale, 1.0, 1.0)
            // Tilt follows the sideways travel only: a card lifted straight
            // up should rise, not spin.
            ..rotateZ(isTop ? _drag.dx * 0.035 * math.pi / 180 : 0.0),
          child: CardDim(
            amount: dim,
            ground: palette.surface,
            radius: 34,
            child: card,
          ),
        ),
      );

      // Same reason as above: one shape at every depth. The card underneath
      // is not listening because it is inside an IgnorePointer, not because
      // it was given a different widget to be. Every depth has its read
      // handed down too — none, for a card nobody is reading yet.
      layers.add(
        Positioned.fill(
          key: ValueKey(pill?.id ?? 'trailing'),
          child: IgnorePointer(
            ignoring: !isTop,
            child: Listener(
              onPointerDown: isTop ? (_) => _read?.touched() : null,
              child: GestureDetector(
                onTap: _turnOver,
                onPanStart: _onPanStart,
                onPanUpdate: _onPanUpdate,
                onPanEnd: _onPanEnd,
                // Only the card on top moves on its own: a living scene on
                // the card waiting behind it holds still until it rises.
                child: TickerMode(
                  enabled: isTop,
                  child: CardReadScope(
                    read: isTop ? () => _read : null,
                    child: card,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return layers;
  }
}
