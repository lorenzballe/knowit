import 'package:flutter/material.dart';

/// Fades and lifts a widget into place, after a delay.
///
/// A list that appears all at once reads as a screenshot; the same list
/// arriving in sequence reads as a screen being built for you. The delay is
/// what carries that, so it is the first argument rather than an option.
class RiseIn extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;

  /// How far it travels, in logical pixels. Small: this is a settle, not an
  /// entrance.
  final double distance;

  const RiseIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 420),
    this.distance = 14,
  });

  /// The nth item in a staggered run.
  factory RiseIn.staggered(
    int index, {
    required Widget child,
    Duration step = const Duration(milliseconds: 60),
    Duration from = Duration.zero,
    Key? key,
  }) => RiseIn(key: key, delay: from + step * index, child: child);

  @override
  State<RiseIn> createState() => _RiseInState();
}

class _RiseInState extends State<RiseIn> with SingleTickerProviderStateMixin {
  // The delay is an interval inside one controller rather than a Timer.
  // A pending Timer outlives a disposed widget and hangs a widget test, and
  // anything that only works outside tests is a thing nobody can check.
  late final Duration _total = widget.delay + widget.duration;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _total,
  )..forward();

  late final Animation<double> _curve = CurvedAnimation(
    parent: _controller,
    curve: Interval(
      _total.inMicroseconds == 0
          ? 0
          : widget.delay.inMicroseconds / _total.inMicroseconds,
      1,
      curve: Curves.easeOutCubic,
    ),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Someone who asked for less motion gets the finished state.
    if (MediaQuery.disableAnimationsOf(context)) return widget.child;

    final curve = _curve;
    return AnimatedBuilder(
      animation: curve,
      builder: (context, child) => Opacity(
        opacity: curve.value,
        child: Transform.translate(
          offset: Offset(0, widget.distance * (1 - curve.value)),
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}

/// Counts up to a number rather than printing it.
///
/// A streak that lands already at seven is information. A streak that climbs
/// to seven is the reason to come back tomorrow.
class CountUp extends StatelessWidget {
  final int value;
  final TextStyle style;
  final Duration duration;
  final Duration delay;

  const CountUp({
    super.key,
    required this.value,
    required this.style,
    this.duration = const Duration(milliseconds: 900),
    this.delay = Duration.zero,
  });

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context) || value == 0) {
      return Text('$value', style: style);
    }
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => Text('${v.round()}', style: style),
    );
  }
}

/// A one-shot pulse, for the instant something lands: a right answer, a
/// finished day. Overshoots then settles, so it reads as weight rather than
/// as a size change.
class PopIn extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final double strength;

  const PopIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.strength = 0.35,
  });

  @override
  State<PopIn> createState() => _PopInState();
}

class _PopInState extends State<PopIn> with SingleTickerProviderStateMixin {
  static const _pop = Duration(milliseconds: 520);

  late final Duration _total = widget.delay + _pop;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _total,
  )..forward();

  late final Animation<double> _curve = CurvedAnimation(
    parent: _controller,
    curve: Interval(
      _total.inMicroseconds == 0
          ? 0
          : widget.delay.inMicroseconds / _total.inMicroseconds,
      1,
      curve: Curves.elasticOut,
    ),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return widget.child;

    return AnimatedBuilder(
      animation: _curve,
      builder: (context, child) => Transform.scale(
        scale: (1 - widget.strength) + widget.strength * _curve.value,
        child: child,
      ),
      child: widget.child,
    );
  }
}
