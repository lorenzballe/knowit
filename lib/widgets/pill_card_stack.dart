import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/pill.dart';
import 'flip_card.dart';
import 'pill_card.dart';

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

  const PillCardStack({
    super.key,
    required this.deck,
    required this.index,
    required this.onAdvance,
    required this.answerFor,
    required this.onAnswer,
    required this.reviewIds,
  });

  @override
  State<PillCardStack> createState() => _PillCardStackState();
}

class _PillCardStackState extends State<PillCardStack>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  double _dx = 0;
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
      _dx = 0;
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
      _dx += d.delta.dx;
      _dragTotalMove += d.delta.dx.abs();
    });
  }

  Future<void> _onPanEnd(DragEndDetails d) async {
    if (!_dragging) return;
    _dragging = false;
    final dx = _dx;
    if (dx.abs() > 78) {
      HapticFeedback.lightImpact();
      await _animateTo(dx < 0 ? -480 : 480);
      if (!mounted) return;
      setState(() {
        _dx = 0;
        _flipped = false;
      });
      widget.onAdvance();
    } else if (_dragTotalMove < 7) {
      await _animateTo(0);
      if (!mounted) return;
      // A card that asks turns over when the reader commits, not on a stray
      // tap — otherwise the answer can be reached without ever guessing. A
      // card that has come back has an answer already, so it must be asked
      // again rather than opened for free.
      final top = widget.deck[widget.index];
      final mustAnswer =
          widget.answerFor(top.id) == null || widget.reviewIds.contains(top.id);
      if (top.asksSomething && mustAnswer && !_answeredHere) return;
      HapticFeedback.selectionClick();
      setState(() => _flipped = !_flipped);
    } else {
      await _animateTo(0);
    }
  }

  Future<void> _animateTo(double target) async {
    final start = _dx;
    _controller.reset();
    final anim = Tween<double>(
      begin: start,
      end: target,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    void listener() {
      if (mounted) setState(() => _dx = anim.value);
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
  double get _progress => (_dx.abs() / 220).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    final remaining = widget.deck.length - widget.index;
    // One layer more than is really visible: the extra sits at the back at
    // low opacity so a card entering the stack fades in instead of appearing.
    final visible = math.min(4, remaining);
    if (visible <= 0) return const SizedBox.shrink();
    final progress = _progress;

    final layers = <Widget>[];
    for (var d = visible - 1; d >= 0; d--) {
      final pill = widget.deck[widget.index + d];
      final isTop = d == 0;
      final num =
          '${(widget.index + d + 1).toString().padLeft(2, '0')} / '
          '${widget.deck.length.toString().padLeft(2, '0')}';

      final given = widget.answerFor(pill.id);

      Widget card = isTop
          ? FlipCard(
              showBack: _flipped,
              front: PillCard(
                pill: pill,
                indexLabel: num,
                flipped: false,
                isReview: widget.reviewIds.contains(pill.id),
                given: given,
                onAnswer: (response, confidence, reason) {
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
                indexLabel: num,
                flipped: true,
                isReview: widget.reviewIds.contains(pill.id),
                given: given,
              ),
            )
          : PillCard(
              pill: pill,
              indexLabel: num,
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
      final opacity = isTop ? 1.0 : math.pow(0.5, depth).toDouble();

      card = Opacity(
        opacity: opacity,
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..translateByDouble(isTop ? _dx : 0.0, translateY, 0.0, 1.0)
            ..scaleByDouble(scale, scale, 1.0, 1.0)
            ..rotateZ(isTop ? _dx * 0.035 * math.pi / 180 : 0.0),
          child: card,
        ),
      );

      layers.add(
        Positioned.fill(
          key: ValueKey(pill.id),
          child: isTop
              ? GestureDetector(
                  onPanStart: _onPanStart,
                  onPanUpdate: _onPanUpdate,
                  onPanEnd: _onPanEnd,
                  child: card,
                )
              : IgnorePointer(child: card),
        ),
      );
    }

    return Stack(children: layers);
  }
}
