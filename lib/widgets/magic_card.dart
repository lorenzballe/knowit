import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/topics.dart';
import '../theme.dart';
import 'fit_text.dart';
import 'ui.dart';

/// The one card in the app that is not a card: the last in the deck, after
/// the fifth, and it offers five more.
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
    this.note,
    this.skip,
    this.onSkip,
    this.headlineSize = 40,
    this.headlineLines = 2,
  });

  final String eyebrow;

  /// Where the reader's week has got to, under the eyebrow, with a key to
  /// find it by: that a week kept makes tomorrow one more of their own.
  /// Said here, beside the offer, rather than over the shelf, where it
  /// would take room from the cards.
  final (String, String)? note;
  final String headline;
  final String line;
  final String action;
  final VoidCallback onAction;

  /// The quiet way past the card. Absent on the shelf, where a swipe is.
  final String? skip;
  final VoidCallback? onSkip;

  /// The headline's size, and the lines it may take: a short offer set
  /// large on two, as built; a sentence about the reader's day a little
  /// smaller, on as many as it needs (lib/widgets/sixth_card.dart).
  final double headlineSize;
  final int headlineLines;

  @override
  State<MagicCard> createState() => _MagicCardState();
}

class _MagicCardState extends State<MagicCard>
    with SingleTickerProviderStateMixin {
  /// One turn of the rim.
  static const Duration _period = Duration(milliseconds: 2800);

  /// One clock for every rim. Where the rim is in its turn is read off it
  /// on every frame, rather than counted from when the card was built: the
  /// shelf builds the card again when it comes back in from the edge, and
  /// the deck's card gives way to the shelf's, and each started its turn
  /// over from the top. Read off one clock, a card built again is at the
  /// point in the turn it would have reached.
  static final Stopwatch _clock = Stopwatch()..start();

  static double get _turnNow =>
      (_clock.elapsedMicroseconds % _period.inMicroseconds) /
      _period.inMicroseconds;

  /// Only a heartbeat: it asks for a frame, and the frame asks the clock.
  late final AnimationController _beat = AnimationController(
    vsync: this,
    duration: _period,
  );

  bool _still = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // A phone that asked for less motion gets the rim standing still; it
    // is still every colour, it just does not spin.
    _still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (_still) {
      _beat.stop();
    } else if (!_beat.isAnimating) {
      _beat.repeat();
    }
  }

  @override
  void dispose() {
    _beat.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color ink = context.p.ink;
    return AnimatedBuilder(
      animation: _beat,
      builder: (context, child) => CustomPaint(
        painter: _Rim(turn: _still ? 0 : _turnNow),
        child: child,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: context.p.surface,
          borderRadius: BorderRadius.circular(_Rim.radius),
        ),
        padding: const EdgeInsets.fromLTRB(26, 26, 26, 22),
        child: LayoutBuilder(
          builder: (context, box) {
            final (bool note, bool line, double? shrunk) = _fit(context, box);
            return Column(
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
                if (note)
                  if (widget.note case final (String, String) said) ...[
                    const SizedBox(height: 12),
                    Text(
                      said.$2,
                      key: ValueKey(said.$1),
                      style: _noteStyle(ink),
                    ),
                  ],
                const Spacer(),
                // Two lines at most, in whatever size two lines take: the
                // Italian is two words longer, the German longer again.
                // Smaller still, on as many lines as it takes, only where
                // not even the headline and the button would fit as it is.
                if (shrunk == null)
                  FitText(
                    widget.headline,
                    maxLines: widget.headlineLines,
                    minSize: _minSize,
                    style: _headlineStyle(ink, widget.headlineSize),
                  )
                else
                  Text(
                    widget.headline,
                    style: _headlineStyle(
                      ink,
                      widget.headlineSize,
                    ).copyWith(fontSize: shrunk),
                  ),
                if (line) ...[
                  const SizedBox(height: 14),
                  Text(widget.line, style: _lineStyle(ink)),
                ],
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
            );
          },
        ),
      ),
    );
  }

  static TextStyle _noteStyle(Color ink) => AppText.body(
    size: 13.5,
    weight: FontWeight.w600,
    height: 1.35,
    color: ink.withValues(alpha: 0.85),
  );

  static TextStyle _headlineStyle(Color ink, [double size = 40]) =>
      AppText.display(
        size: size,
        weight: FontWeight.w600,
        height: size < 40 ? 1.08 : 1.02,
        spacing: -1.2 * size / 40,
        color: ink,
      );

  static TextStyle _lineStyle(Color ink) =>
      AppText.body(size: 15, height: 1.4, color: ink.withValues(alpha: 0.62));

  /// The smallest the headline is set at on its lines (FitText's floor).
  double get _minSize => 24 * widget.headlineSize / 40;

  /// The least the headline is ever set at, where even its floor would not
  /// leave the button room.
  static const double _leastSize = 12;

  /// Which of the two things the card can do without fit in [box]: the
  /// week's note, and the line under the headline; and the size the
  /// headline is set at where it must be smaller than its own fitting
  /// takes it (null: as FitText sets it).
  ///
  /// The eyebrow, the headline and the button always stay: they are the
  /// offer. On a short phone the card was a fixed column with nothing that
  /// gave way, and the button the card exists for was cut off by 23
  /// points. The line goes first, being the headline said again at
  /// length; then the note, which the shelf says elsewhere; and last, a
  /// long sentence about the reader's day at the largest text sizes, the
  /// headline goes a size down at a time until the button has its room.
  (bool, bool, double?) _fit(BuildContext context, BoxConstraints box) {
    if (!box.maxHeight.isFinite) return (true, true, null);
    final TextScaler scaler = MediaQuery.textScalerOf(context);
    final TextDirection direction = Directionality.of(context);
    final Color ink = context.p.ink;
    // On the inherited style, as a Text here sets it: the theme's tracking
    // is in it, and without it a line measured short of the one drawn.
    final TextStyle inherited = DefaultTextStyle.of(context).style;
    double measure(String text, TextStyle style, {int? lines}) {
      final TextPainter p = TextPainter(
        text: TextSpan(text: text, style: inherited.merge(style)),
        textDirection: direction,
        textScaler: scaler,
        maxLines: lines,
      )..layout(maxWidth: box.maxWidth);
      final double h = p.height;
      p.dispose();
      return h;
    }

    // The headline as FitText sets it: the largest size, a point at a
    // time, at which it keeps to its lines; at its floor, on as many as it
    // takes.
    final TextStyle headline = _headlineStyle(ink, widget.headlineSize);
    double size = headline.fontSize ?? widget.headlineSize;
    while (size > _minSize) {
      final TextPainter p = TextPainter(
        text: TextSpan(
          text: widget.headline,
          style: inherited.merge(headline.copyWith(fontSize: size)),
        ),
        textDirection: direction,
        textScaler: scaler,
        maxLines: widget.headlineLines,
      )..layout(maxWidth: box.maxWidth);
      final bool over = p.didExceedMaxLines;
      p.dispose();
      if (!over) break;
      size -= 1;
    }
    // The eyebrow's row: its mark, or its words as the face sets them,
    // whichever is taller — at the largest text sizes, the words.
    final double eyebrow = math.max(
      15,
      measure(
        widget.eyebrow.toUpperCase(),
        AppText.label(size: 11, spacing: 1.3),
        lines: 1,
      ),
    );
    final double chrome =
        eyebrow +
        // The button is 54, and the quiet way past it its own line.
        54 +
        (widget.skip != null ? 4 + 20 + scaler.scale(13) * 1.3 : 0);
    final double fixed =
        chrome +
        measure(
          widget.headline,
          headline.copyWith(fontSize: size),
          lines: size <= _minSize ? null : widget.headlineLines,
        );
    final double note = widget.note == null
        ? 0
        : 12 + measure(widget.note!.$2, _noteStyle(ink));
    final double line = 14 + measure(widget.line, _lineStyle(ink));
    final double room = box.maxHeight;
    if (fixed + note + line <= room) return (true, true, null);
    if (fixed + note <= room) return (true, false, null);
    if (fixed <= room) return (false, false, null);
    for (size -= 1; size > _leastSize; size -= 1) {
      final double head = measure(
        widget.headline,
        headline.copyWith(fontSize: size),
      );
      if (chrome + head <= room) return (false, false, size);
    }
    return (false, false, _leastSize);
  }
}

/// The rim: the whole spectrum swept round the card once, turning, and the
/// same sweep again, wide and blurred, as the light it throws.
class _Rim extends CustomPainter {
  const _Rim({required this.turn});

  final double turn;

  /// The deck's corner: the card after the fifth is the same shape as the
  /// five before it.
  static const double radius = 34;
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
