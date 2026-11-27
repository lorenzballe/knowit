import 'package:flutter/material.dart';

/// [child] a little smaller the instant a finger is on it, and back with a
/// small spring when it lifts: the press a card's options and levels of how
/// sure have (pill_card.dart), for a button whose taps are handled around
/// it. Only what is seen: it takes no tap, so a button that swallows taps
/// while it cannot be pressed goes on swallowing them. [live] false, it
/// never gives.
class PressScale extends StatefulWidget {
  const PressScale({super.key, required this.live, required this.child});

  final bool live;
  final Widget child;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _down = false;

  void _set(bool down) {
    if (_down != down && mounted) setState(() => _down = down);
  }

  @override
  Widget build(BuildContext context) {
    final bool still = MediaQuery.disableAnimationsOf(context);
    return Listener(
      // Wherever the finger lands on it, whatever is drawn there.
      behavior: HitTestBehavior.translucent,
      onPointerDown: widget.live ? (_) => _set(true) : null,
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: _down && widget.live ? 0.965 : 1,
        duration: still
            ? Duration.zero
            : Duration(milliseconds: _down ? 70 : 280),
        curve: _down ? Curves.easeOut : Curves.easeOutBack,
        child: widget.child,
      ),
    );
  }
}
