import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/topics.dart';
import '../theme.dart';
import 'ui.dart';

/// The one card in the app that is not a card: it appears after the fifth,
/// stays a few seconds, and offers five more.
///
/// It looks like nothing else on purpose — a rim of every colour the deck
/// has, turning, with light spilling off it — because it is the one moment
/// the app asks for something rather than gives it, and a moment like that
/// should look like a reward, not a form. The rim is painted, not an asset,
/// so it takes the palette's own colours and the card's own size.
class MagicCard extends StatefulWidget {
  const MagicCard({
    super.key,
    required this.eyebrow,
    required this.headline,
    required this.line,
    required this.action,
    required this.onAction,
    this.skip,
    this.onSkip,
  });

  final String eyebrow;
  final String headline;
  final String line;
  final String action;
  final VoidCallback onAction;

  /// The quiet way past the card. Absent on the shelf, where a swipe is.
  final String? skip;
  final VoidCallback? onSkip;

  @override
  State<MagicCard> createState() => _MagicCardState();
}

class _MagicCardState extends State<MagicCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _turn = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2800),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // A phone that asked for less motion gets the rim standing still; it
    // is still every colour, it just does not spin.
    final bool still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (still) {
      _turn.stop();
    } else if (!_turn.isAnimating) {
      _turn.repeat();
    }
  }

  @override
  void dispose() {
    _turn.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color ink = context.p.ink;
    return AnimatedBuilder(
      animation: _turn,
      builder: (context, child) => CustomPaint(
        painter: _Rim(turn: _turn.value),
        child: child,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: context.p.surface,
          borderRadius: BorderRadius.circular(_Rim.radius),
        ),
        padding: const EdgeInsets.fromLTRB(26, 26, 26, 22),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome_rounded, size: 15, color: ink),
                const SizedBox(width: 8),
                Eyebrow(widget.eyebrow),
              ],
            ),
            const Spacer(),
            Text(
              widget.headline,
              style: AppText.display(
                size: 40,
                weight: FontWeight.w600,
                height: 1.02,
                spacing: -1.2,
                color: ink,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              widget.line,
              style: AppText.body(
                size: 15,
                height: 1.4,
                color: ink.withValues(alpha: 0.62),
              ),
            ),
            const Spacer(),
            PrimaryButton(label: widget.action, onPressed: widget.onAction),
            if (widget.skip != null && widget.onSkip != null) ...[
              const SizedBox(height: 4),
              Center(
                child: QuietButton(
                  label: widget.skip!,
                  onPressed: widget.onSkip!,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The rim: the whole spectrum swept round the card once, turning, and the
/// same sweep again, wide and blurred, as the light it throws.
class _Rim extends CustomPainter {
  const _Rim({required this.turn});

  final double turn;

  static const double radius = 30;
  static const double width = 3;
  static const double glow = 26;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    final RRect edge = RRect.fromRectAndRadius(
      rect.deflate(width / 2),
      const Radius.circular(radius),
    );
    final Shader sweep = SweepGradient(
      colors: [...kSpectrum, kSpectrum.first],
      transform: GradientRotation(turn * 2 * math.pi),
    ).createShader(rect);

    // The spill: a wide stroke of the same colours, blurred out, and let
    // through at half strength so it reads as light on the table rather than
    // as a second border.
    canvas.drawRRect(
      edge,
      Paint()
        ..shader = sweep
        ..style = PaintingStyle.stroke
        ..strokeWidth = glow
        ..color = const Color(0x8CFFFFFF)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, glow * 0.7),
    );
    canvas.drawRRect(
      edge,
      Paint()
        ..shader = sweep
        ..style = PaintingStyle.stroke
        ..strokeWidth = width,
    );
  }

  @override
  bool shouldRepaint(_Rim old) => old.turn != turn;
}
