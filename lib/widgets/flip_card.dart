import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Turns [front] over to reveal [back] with a real perspective flip, the way a
/// physical card would turn. The faces swap at the halfway point, so neither is
/// ever seen mirrored.
class FlipCard extends StatefulWidget {
  final bool showBack;
  final Widget front;
  final Widget back;
  final Duration duration;

  const FlipCard({
    super.key,
    required this.showBack,
    required this.front,
    required this.back,
    // Four hundred and sixty was a card turning over at its leisure. The
    // gesture is a tap: the answer should arrive with it, not after it.
    this.duration = const Duration(milliseconds: 300),
  });

  @override
  State<FlipCard> createState() => _FlipCardState();
}

class _FlipCardState extends State<FlipCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
    value: widget.showBack ? 1 : 0,
  );

  late final Animation<double> _turn = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeInOutCubic,
  );

  @override
  void didUpdateWidget(covariant FlipCard old) {
    super.didUpdateWidget(old);
    if (old.showBack != widget.showBack) {
      if (widget.showBack) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Someone who has asked for less motion gets the answer, not the trick.
    if (MediaQuery.disableAnimationsOf(context)) {
      return widget.showBack ? widget.back : widget.front;
    }
    return AnimatedBuilder(
      animation: _turn,
      builder: (context, _) {
        final t = _turn.value;
        final showingBack = t >= 0.5;
        // The back face is drawn already turned a half-turn, so that once the
        // card passes the halfway point it reads the right way round.
        final face = showingBack
            ? Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()..rotateY(math.pi),
                child: widget.back,
              )
            : widget.front;

        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0012) // perspective
            ..rotateY(t * math.pi),
          child: face,
        );
      },
    );
  }
}
