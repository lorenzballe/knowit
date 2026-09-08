import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Hold a card to keep it.
///
/// The heart in the corner is a small target on a big object, and nothing
/// about it says that the card is the thing being kept. Holding the card
/// says it: press anywhere on it, the card dips under the finger, a ring
/// draws itself round a heart in the middle as the hold fills, and at the
/// top of it the phone thumps and the card is kept. Let go early and it
/// unwinds, having done nothing — which is what makes it safe to try.
class HoldToKeep extends StatefulWidget {
  const HoldToKeep({
    super.key,
    required this.saved,
    required this.ink,
    required this.ground,
    required this.onToggle,
    required this.child,
  });

  /// Whether the card is already kept: a hold on a kept card lets it go.
  final bool saved;

  /// The card's own ink, so the mark is drawn in the card's colours rather
  /// than in the app's.
  final Color ink;

  /// The card's own ground, laid under the mark: a heart read through the
  /// question printed behind it is a smudge, not a heart.
  final Color ground;

  final VoidCallback onToggle;
  final Widget child;

  @override
  State<HoldToKeep> createState() => _HoldToKeepState();
}

class _HoldToKeepState extends State<HoldToKeep> with TickerProviderStateMixin {
  /// How long the finger has to stay down. Longer than the framework's
  /// 500ms, because a card is also tapped to turn it over and a keep is
  /// the more expensive of the two: a tap that runs a little long should
  /// not start keeping things.
  static const Duration _press = Duration(milliseconds: 700);

  /// Nothing is drawn for the first stretch of the press. Under this the
  /// finger is still plausibly tapping, and a mark that flashes up on
  /// every tap of the card is a mark in the way.
  static const double _quiet = 0.36;

  /// How far into the hold the finger is, 0 to 1, its length that of the
  /// press — so the ring closes on the frame the press is recognised
  /// rather than before or after it.
  late final AnimationController _hold = AnimationController(
    vsync: this,
    duration: _press,
    reverseDuration: const Duration(milliseconds: 160),
  );

  /// The beat after: the heart lands, swells and goes.
  late final AnimationController _done = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 620),
  );

  /// What the finished mark says — a heart, or a heart let go.
  bool _letting = false;

  @override
  void dispose() {
    _hold.dispose();
    _done.dispose();
    super.dispose();
  }

  void _fire() {
    setState(() => _letting = widget.saved);
    HapticFeedback.mediumImpact();
    widget.onToggle();
    _hold.value = 0;
    _done.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return RawGestureDetector(
      // The card underneath keeps its tap and its throw: a quick tap never
      // reaches this, and a card dragged away takes the pointer with it.
      gestures: {
        LongPressGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
              () => LongPressGestureRecognizer(duration: _press),
              (r) => r
                ..onLongPressDown = ((_) => _hold.forward())
                ..onLongPressCancel = (() => _hold.reverse())
                ..onLongPressStart = ((_) => _fire())
                ..onLongPressEnd = ((_) => _hold.reverse()),
            ),
      },
      child: AnimatedBuilder(
        animation: Listenable.merge([_hold, _done]),
        builder: (context, child) {
          // The quiet stretch first, then the whole mark in what is left.
          final double hold = Curves.easeOut.transform(
            ((_hold.value - _quiet) / (1 - _quiet)).clamp(0.0, 1.0),
          );
          final double done = _done.value;
          return Transform.scale(
            scale: 1 - 0.02 * hold,
            child: Stack(
              alignment: Alignment.center,
              children: [
                child!,
                if (hold > 0 || done > 0)
                  IgnorePointer(
                    child: CustomPaint(
                      size: const Size(112, 112),
                      painter: _Mark(
                        hold: hold,
                        done: done,
                        letting: _letting,
                        ink: widget.ink,
                        ground: widget.ground,
                      ),
                      child: SizedBox(
                        width: 112,
                        height: 112,
                        child: Center(
                          child: Opacity(
                            opacity: done > 0
                                ? (1 -
                                          Curves.easeIn.transform(
                                            (done - 0.45).clamp(0.0, 1.0) /
                                                0.55,
                                          ))
                                      .clamp(0.0, 1.0)
                                : hold,
                            child: Transform.scale(
                              scale: done > 0
                                  ? 1 +
                                        0.35 *
                                            Curves.easeOutBack.transform(
                                              (done / 0.45).clamp(0.0, 1.0),
                                            )
                                  : 0.7 + 0.3 * hold,
                              child: Icon(
                                done > 0 && _letting
                                    ? Icons.heart_broken_rounded
                                    : done > 0
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                size: 38,
                                color: widget.ink.withValues(alpha: 0.85),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
        child: widget.child,
      ),
    );
  }
}

/// The ring: a thin track that fills clockwise while the finger is down,
/// then a single wave off the edge once the press lands.
class _Mark extends CustomPainter {
  const _Mark({
    required this.hold,
    required this.done,
    required this.letting,
    required this.ink,
    required this.ground,
  });

  final double hold;
  final double done;
  final bool letting;
  final Color ink;
  final Color ground;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset centre = size.center(Offset.zero);
    const double r = 38;
    // The coin is what the heart is read against, so it arrives ahead of
    // the ring and leaves only once the mark has landed: a heart read
    // through the question printed under it is a smudge, not a heart.
    final double coin = done > 0
        ? 1 - ((done - 0.55) / 0.45).clamp(0.0, 1.0)
        : (hold * 1.8).clamp(0.0, 1.0);

    if (done > 0) {
      final double t = Curves.easeOut.transform(done);
      final double fade = (1 - t).clamp(0.0, 1.0);
      canvas.drawCircle(
        centre,
        r,
        Paint()..color = ground.withValues(alpha: coin),
      );
      canvas.drawCircle(
        centre,
        r + 26 * t,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..color = ink.withValues(alpha: 0.35 * fade),
      );
      return;
    }
    if (hold <= 0) return;

    canvas.drawCircle(
      centre,
      r,
      Paint()..color = ground.withValues(alpha: coin),
    );
    canvas.drawCircle(
      centre,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = ink.withValues(alpha: 0.16 * hold),
    );
    canvas.drawArc(
      Rect.fromCircle(center: centre, radius: r),
      -3.14159 / 2,
      6.28318 * hold,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..color = ink.withValues(alpha: 0.6),
    );
  }

  @override
  bool shouldRepaint(_Mark old) =>
      old.hold != hold || old.done != done || old.letting != letting;
}
