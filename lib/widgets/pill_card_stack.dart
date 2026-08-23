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
  final void Function(String id, String response, int? confidence) onAnswer;

  const PillCardStack({
    super.key,
    required this.deck,
    required this.index,
    required this.onAdvance,
    required this.answerFor,
    required this.onAnswer,
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
      // A puzzle turns over when the reader commits, not on a stray tap —
      // otherwise the answer can be reached without ever guessing.
      final top = widget.deck[widget.index];
      if (top.asksSomething && widget.answerFor(top.id) == null) return;
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

  @override
  Widget build(BuildContext context) {
    final remaining = widget.deck.length - widget.index;
    final visible = math.min(3, remaining);
    if (visible <= 0) return const SizedBox.shrink();

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
                given: given,
                onAnswer: (response, confidence) {
                  HapticFeedback.mediumImpact();
                  widget.onAnswer(pill.id, response, confidence);
                  setState(() => _flipped = true);
                },
              ),
              back: PillCard(
                pill: pill,
                indexLabel: num,
                flipped: true,
                given: given,
              ),
            )
          : PillCard(pill: pill, indexLabel: num, flipped: false);

      final translateY = isTop ? 0.0 : d * 16.0;
      final scale = isTop ? 1.0 : 1 - d * 0.035;
      final opacity = isTop
          ? math.max(0.0, 1 - _dx.abs() / 420)
          : (d == 1 ? 0.55 : 0.28);

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
