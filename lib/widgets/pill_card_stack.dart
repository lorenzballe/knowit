import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/pill.dart';
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
  final VoidCallback onAdvance;

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

  const PillCardStack({
    super.key,
    required this.deck,
    required this.index,
    required this.onAdvance,
    required this.answerFor,
    required this.onAnswer,
    required this.reviewIds,
    required this.isSaved,
    required this.onSave,
    required this.onShare,
    this.isLiked,
    this.onLike,
    this.onDislike,
    this.answering = true,
    this.onMotion,
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
  }

  @override
  void didUpdateWidget(covariant PillCardStack old) {
    super.didUpdateWidget(old);
    if (old.index != widget.index) {
      _drag = Offset.zero;
      _flipped = false;
      _answeredHere = false;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails d) {
    if (widget.index >= widget.deck.length) return;
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
      final bool down =
          widget.onDislike != null &&
          thrown.dy > 520 &&
          thrown.dy > thrown.dx.abs() * 1.8;
      if (down) {
        HapticFeedback.mediumImpact();
      } else {
        HapticFeedback.lightImpact();
      }
      final Pill leaving = widget.deck[widget.index];
      final double length = heading.distance;
      await _animateTo(
        length == 0 ? const Offset(480, 0) : heading * (1100 / length),
      );
      if (!mounted) return;
      setState(() {
        _drag = Offset.zero;
        _flipped = false;
      });
      if (down) widget.onDislike!(leaving);
      widget.onAdvance();
    } else if (_dragTotalMove < 7) {
      // Barely moved: put it back where it was and turn it over, with
      // nothing to settle first — the card never went anywhere.
      setState(() => _drag = Offset.zero);
      _turnOver();
    } else {
      await _animateTo(Offset.zero);
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

  @override
  Widget build(BuildContext context) {
    final remaining = widget.deck.length - widget.index;
    // Three: the card being read, the one behind it, and the one after
    // that waiting at nothing — it fades in only as the top card leaves,
    // so what is on screen is never more than the next question.
    final visible = math.min(3, remaining);
    if (visible <= 0) return const SizedBox.shrink();
    final progress = _progress;

    final layers = <Widget>[];
    for (var d = visible - 1; d >= 0; d--) {
      final pill = widget.deck[widget.index + d];
      final isTop = d == 0;

      final given = widget.answerFor(pill.id);

      Widget card = isTop
          ? FlipCard(
              showBack: _flipped,
              front: PillCard(
                pill: pill,
                flipped: false,
                isReview: widget.reviewIds.contains(pill.id),
                given: given,
                saved: widget.isSaved(pill.id),
                onSave: () => widget.onSave(pill),
                liked: widget.isLiked?.call(pill.id) ?? false,
                onLike: widget.onLike == null
                    ? null
                    : () => widget.onLike!(pill),
                onShare: () => widget.onShare(pill),
                onAnswer: !widget.answering
                    ? null
                    : (response, confidence, reason) {
                        HapticFeedback.mediumImpact();
                        widget.onAnswer(pill.id, response, confidence, reason);
                        setState(() {
                          _answeredHere = true;
                          _flipped = true;
                        });
                      },
              ),
              back: PillCard(
                pill: pill,
                flipped: true,
                isReview: widget.reviewIds.contains(pill.id),
                given: given,
                saved: widget.isSaved(pill.id),
                onSave: () => widget.onSave(pill),
                liked: widget.isLiked?.call(pill.id) ?? false,
                onLike: widget.onLike == null
                    ? null
                    : () => widget.onLike!(pill),
                onShare: () => widget.onShare(pill),
              ),
            )
          : PillCard(
              pill: pill,
              flipped: false,
              isReview: widget.reviewIds.contains(pill.id),
            );

      // Continuous depth: 1 becomes 0 as the top card leaves.
      final depth = isTop ? 0.0 : d - progress;
      final translateY = depth * 16.0;
      final scale = 1 - depth * 0.035;
      // The card being dragged stays solid. Fading it turned it into a
      // window onto the card underneath, and two legible questions printed
      // over each other read as a fault rather than as one card leaving. It
      // travels far enough to clear the screen on its own.
      //
      // Behind it, only the next one. A stack that fades every card it
      // holds shows four questions at once, which is three more than the
      // reader asked for and a spoiler of the rest of the day. The third
      // is drawn at nothing and arrives only as the top card goes.
      final opacity = isTop
          ? 1.0
          : depth <= 1
          ? math.pow(0.5, depth).toDouble()
          : (0.5 * (2 - depth)).clamp(0.0, 0.5);

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
          child: card,
        ),
      );

      layers.add(
        Positioned.fill(
          key: ValueKey(pill.id),
          child: isTop
              ? GestureDetector(
                  onTap: _turnOver,
                  onPanStart: _onPanStart,
                  onPanUpdate: _onPanUpdate,
                  onPanEnd: _onPanEnd,
                  child: card,
                )
              : IgnorePointer(child: card),
        ),
      );
    }

    // As big as the room allows, short of a slab: the card takes the
    // height it is given, minus a little black at each end so the deck
    // reads as sitting in a space rather than jammed into one, and stops
    // at a card's tallest proportion.
    return Center(
      child: LayoutBuilder(
        builder: (context, box) => SizedBox(
          width: box.maxWidth,
          height: math.min(
            math.max(0, box.maxHeight - _air * 2),
            box.maxWidth * _cardAspect,
          ),
          child: Stack(children: layers),
        ),
      ),
    );
  }
}
