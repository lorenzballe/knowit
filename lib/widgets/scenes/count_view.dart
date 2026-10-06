import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' show PointMode;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/l10n.dart';
import '../../models/scene.dart';
import '../../theme.dart';
import '../place_it.dart' show roughNumber;

/// Plays a [CountScene]: bet the number.
///
/// Top to bottom: the giant number with its spaced label, the field the
/// dots fill, the key to the dots, the bets as a row of chips with a lane
/// above them for the truth's marker, and the line that lands at the end.
///
/// Before the bet the number is a question mark and the field is a faint
/// sheet of dot paper. A tap on a chip (or a slide along the row, lifted on
/// one) places the bet. Then, in one movement, the number counts up, the
/// dots fill the field from the bottom like a glass, and a TRUTH marker
/// travels along the chips past the smaller bets to where the answer sits.
/// The gap between it and the reader's chip is how far off they were; the
/// note of their chip says so in words.
///
/// Until the count has landed, taps anywhere in the scene stay in the
/// scene: a stray tap must not turn the card over and spoil the bet.
class CountSceneView extends StatefulWidget {
  final CountScene scene;
  final Color ink;
  final Color ground;
  const CountSceneView({
    super.key,
    required this.scene,
    required this.ink,
    required this.ground,
  });

  @override
  State<CountSceneView> createState() => _CountSceneViewState();
}

class _CountSceneViewState extends State<CountSceneView>
    with SingleTickerProviderStateMixin {
  /// The reveal, in one controller: the count runs over the first 78%,
  /// the note settles in over the last part.
  late final AnimationController _run = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2900),
  )..addListener(_onTick);

  static const _countEnd = 0.78;
  static const _noteStart = 0.8;

  /// The reader's bet, once placed.
  int? _bet;

  /// The chip under a finger sliding along the row, before it lifts.
  int? _hover;

  /// The last option the truth's marker passed, for a click as it passes.
  int _passed = 0;

  @override
  void didUpdateWidget(CountSceneView old) {
    super.didUpdateWidget(old);
    if (!identical(old.scene, widget.scene)) {
      _run.value = 0;
      _bet = null;
      _hover = null;
      _passed = 0;
    }
  }

  @override
  void dispose() {
    _run.dispose();
    super.dispose();
  }

  /// How far the count has got, 0 to 1: fast at first, settling on the
  /// number, so the last digits are seen to land.
  double get _count =>
      Curves.easeOutCubic.transform((_run.value / _countEnd).clamp(0.0, 1.0));

  double get _value => widget.scene.answer * _count;

  bool get _landed => _run.value >= _countEnd;

  void _onTick() {
    final stop = widget.scene.stopOf(_value);
    final passed = (stop + 1e-6).floor();
    if (passed > _passed) {
      _passed = passed;
      HapticFeedback.selectionClick();
    }
    if (_run.isCompleted) HapticFeedback.lightImpact();
  }

  void _place(int i) {
    if (_bet != null) return;
    HapticFeedback.selectionClick();
    setState(() {
      _bet = i;
      _hover = null;
    });
    if (MediaQuery.disableAnimationsOf(context)) {
      _passed = widget.scene.stopOf(widget.scene.answer).floor();
      _run.value = 1;
    } else {
      _run.forward(from: 0);
    }
  }

  int _chipAt(double dx, double width) =>
      (dx / width * widget.scene.options.length).floor().clamp(
        0,
        widget.scene.options.length - 1,
      );

  void _slide(Offset p, double width) {
    if (_bet != null) return;
    final i = _chipAt(p.dx, width);
    if (i != _hover) {
      HapticFeedback.selectionClick();
      setState(() => _hover = i);
    }
  }

  /// Exact, with thousands marked; past a quadrillion, in words.
  String _fmt(double v) {
    final s = widget.scene;
    if (v >= 1e15) return '${s.prefix}${roughNumber(v)}';
    final fixed = v.toStringAsFixed(s.decimals);
    final parts = fixed.split('.');
    final whole = parts[0].replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => ',',
    );
    return '${s.prefix}$whole${parts.length > 1 ? '.${parts[1]}' : ''}';
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) => AnimatedBuilder(
        animation: _run,
        builder: (context, _) => _build(context, box),
      ),
    );
  }

  Widget _build(BuildContext context, BoxConstraints box) {
    final s = widget.scene;
    final ink = widget.ink;
    final ground = widget.ground;
    final h = box.maxHeight;
    final w = box.maxWidth;
    final short = h < 300;
    final bet = _bet;
    final counting = bet != null;

    // The giant number is sized once, to its final width, so it never
    // jumps as digits arrive.
    final finalText = _fmt(s.answer);
    final giantMax = short ? 44.0 : (h * 0.17).clamp(52.0, 84.0).toDouble();
    final giant = _fit(finalText, w, giantMax);
    final giantStyle = AppText.display(
      size: giant,
      weight: FontWeight.w800,
      height: 1,
      spacing: -giant * 0.03,
      color: ink,
    ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]);

    final chipH = short ? 46.0 : 54.0;
    final noteH = short ? 38.0 : 42.0;
    final noteT = ((_run.value - _noteStart) / (1 - _noteStart)).clamp(
      0.0,
      1.0,
    );
    final note = bet == null ? '' : s.options[bet].note;

    final column = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // The number, and what it counts.
        Semantics(
          liveRegion: _landed,
          label: _landed ? '${_fmt(s.answer)} ${s.unit}' : s.unit,
          child: ExcludeSemantics(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  counting ? _fmt(_value) : '?',
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.visible,
                  style: counting
                      ? giantStyle
                      : giantStyle.copyWith(color: ink.withValues(alpha: 0.3)),
                ),
                SizedBox(height: short ? 5 : 8),
                Text(
                  s.unit.toUpperCase(),
                  maxLines: short ? 1 : 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.label(
                    size: 10.5,
                    weight: FontWeight.w800,
                    spacing: 2.6,
                    height: 1.35,
                    color: ink.withValues(alpha: 0.72),
                  ),
                ),
                if (s.compare.isNotEmpty && h >= 400) ...[
                  const SizedBox(height: 6),
                  Opacity(
                    opacity: noteT,
                    child: Text(
                      s.compare,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.body(
                        size: 14,
                        weight: FontWeight.w600,
                        color: ink.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        SizedBox(height: short ? 6 : 12),
        // The field the dots fill.
        Expanded(
          child: Semantics(
            image: true,
            label: s.eachLabel,
            child: ExcludeSemantics(
              child: RepaintBoundary(
                child: _Field(
                  scene: s,
                  shown: counting ? s.dots * _count : 0,
                  paper: counting ? 1 - _count : 1,
                  ink: ink,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        // The key to the dots.
        ExcludeSemantics(
          child: Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(color: ink, shape: BoxShape.circle),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  s.eachLabel.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.label(
                    size: 10.5,
                    weight: FontWeight.w700,
                    color: ink.withValues(alpha: 0.65),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: short ? 8 : 14),
        // The lane for the truth's marker, then the bets.
        _Bets(
          scene: s,
          ink: ink,
          ground: ground,
          chipHeight: chipH,
          bet: bet,
          hover: _hover,
          landed: _landed,
          calm: MediaQuery.disableAnimationsOf(context),
          truth: counting ? s.stopOf(_value) : null,
          guessLabel: context.l10n.sceneYourGuess.toUpperCase(),
          truthLabel: context.l10n.sceneTruth,
          hint: context.l10n.sceneTapToPick,
          onTap: (dx, width) => _place(_chipAt(dx, width)),
          onSlide: _slide,
          onLift: () {
            final i = _hover;
            if (i != null) _place(i);
          },
          onPick: _place,
        ),
        const SizedBox(height: 10),
        // The line that lands: how far off the bet was.
        SizedBox(
          height: noteH,
          child: Align(
            alignment: Alignment.topLeft,
            child: bet == null
                ? Text(
                    context.l10n.sceneTapToPick,
                    maxLines: 1,
                    style: AppText.body(
                      size: 14,
                      weight: FontWeight.w600,
                      color: ink.withValues(alpha: 0.55),
                    ),
                  )
                : Semantics(
                    liveRegion: noteT > 0,
                    child: Opacity(
                      opacity: noteT,
                      child: Transform.translate(
                        offset: Offset(
                          0,
                          8 * (1 - Curves.easeOut.transform(noteT)),
                        ),
                        child: Text(
                          note,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.body(
                            size: 14,
                            weight: FontWeight.w600,
                            height: 1.35,
                            color: ink.withValues(alpha: 0.92),
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
        ),
      ],
    );

    // Until the count lands, a tap in the scene belongs to the scene.
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      excludeFromSemantics: true,
      onTap: _landed ? null : () {},
      child: column,
    );
  }

  /// The largest size up to [max] at which [text] fits [width] on one line.
  static double _fit(String text, double width, double max) {
    double measure(double size) {
      final tp = TextPainter(
        text: TextSpan(
          text: text,
          style: AppText.display(
            size: size,
            weight: FontWeight.w800,
            spacing: -size * 0.03,
          ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout();
      final w = tp.width;
      tp.dispose();
      return w;
    }

    // Fraunces widens as its optical size drops, so the width is not
    // linear in the size: guess, then measure again where the guess lands.
    var size = max;
    for (var k = 0; k < 3; k++) {
      final w = measure(size);
      if (w <= width - 2) break;
      size = size * (width - 2) / w * 0.99;
    }
    return size.clamp(18.0, max);
  }
}

/// The bets as one row of chips, and the lane above them where the truth's
/// marker travels. One recogniser for the row: a tap places a bet, a slide
/// lights the chip under the finger and lifting places it. The row also
/// keeps horizontal drags from swiping the deck away mid-bet.
class _Bets extends StatelessWidget {
  final CountScene scene;
  final Color ink;
  final Color ground;
  final double chipHeight;
  final int? bet;
  final int? hover;
  final bool landed;

  /// Animations are off: chips change at once.
  final bool calm;

  /// Where the truth's marker is, in option steps (see [CountScene.stopOf]).
  final double? truth;
  final String guessLabel;
  final String truthLabel;
  final String hint;
  final void Function(double dx, double width) onTap;
  final void Function(Offset p, double width) onSlide;
  final VoidCallback onLift;
  final ValueChanged<int> onPick;

  const _Bets({
    required this.scene,
    required this.ink,
    required this.ground,
    required this.chipHeight,
    required this.bet,
    required this.hover,
    required this.landed,
    required this.calm,
    required this.truth,
    required this.guessLabel,
    required this.truthLabel,
    required this.hint,
    required this.onTap,
    required this.onSlide,
    required this.onLift,
    required this.onPick,
  });

  static const _lane = 26.0;
  static const _gap = 8.0;

  @override
  Widget build(BuildContext context) {
    final n = scene.options.length;
    return LayoutBuilder(
      builder: (context, box) {
        final w = box.maxWidth;
        final step = w / n;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          excludeFromSemantics: true,
          onTapUp: bet == null ? (d) => onTap(d.localPosition.dx, w) : null,
          onPanStart: (d) => onSlide(d.localPosition, w),
          onPanUpdate: (d) => onSlide(d.localPosition, w),
          onPanEnd: (_) => onLift(),
          child: SizedBox(
            height: _lane + chipHeight,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // The lane: an eyebrow before the bet, the marker after.
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  height: _lane,
                  child: truth == null
                      ? Align(
                          alignment: Alignment.topLeft,
                          child: Text(
                            guessLabel,
                            style: AppText.label(
                              size: 10.5,
                              weight: FontWeight.w800,
                              color: ink.withValues(alpha: 0.65),
                            ),
                          ),
                        )
                      : ExcludeSemantics(
                          child: CustomPaint(
                            painter: _LanePainter(
                              from: (bet! + 0.5) * step,
                              to: (truth! + 0.5) * step,
                              ink: ink,
                            ),
                          ),
                        ),
                ),
                if (truth != null) _marker(context, (truth! + 0.5) * step, w),
                for (var i = 0; i < n; i++)
                  Positioned(
                    left: i * step + (i == 0 ? 0 : _gap / 2),
                    width: step - (i == 0 || i == n - 1 ? _gap / 2 : _gap),
                    top: _lane,
                    height: chipHeight,
                    child: _chip(i),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// The TRUTH pill riding the lane, its point on the exact place.
  Widget _marker(BuildContext context, double x, double width) {
    final style = AppText.label(
      size: 9.5,
      weight: FontWeight.w800,
      spacing: 1.6,
      color: ground,
    );
    final tp = TextPainter(
      text: TextSpan(text: truthLabel, style: style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    final pillW = tp.width + 16;
    tp.dispose();
    final left = (x - pillW / 2)
        .clamp(0.0, math.max(0.0, width - pillW))
        .toDouble();
    return Positioned(
      left: left,
      top: 0,
      width: pillW,
      height: 18,
      child: ExcludeSemantics(
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: ink,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(truthLabel, maxLines: 1, style: style),
        ),
      ),
    );
  }

  Widget _chip(int i) {
    final o = scene.options[i];
    final mine = bet == i;
    final lit = hover == i;
    final right = landed && i == scene.nearest;
    final faded = bet != null && !mine && !right;
    final fg = mine ? ground : ink.withValues(alpha: faded ? 0.5 : 1);
    return Semantics(
      button: true,
      enabled: bet == null,
      selected: mine,
      label: o.label,
      hint: bet == null ? hint : null,
      onTap: bet == null ? () => onPick(i) : null,
      child: ExcludeSemantics(
        child: AnimatedContainer(
          duration: calm ? Duration.zero : const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: mine ? ink : ink.withValues(alpha: lit ? 0.16 : 0.0),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: mine
                  ? ink
                  : ink.withValues(alpha: right ? 1 : (faded ? 0.28 : 0.55)),
              width: right && !mine ? 2.5 : 1.6,
            ),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: AnimatedDefaultTextStyle(
              duration: calm
                  ? Duration.zero
                  : const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              style: AppText.body(
                size: 14,
                weight: FontWeight.w800,
                height: 1.15,
                color: fg,
              ),
              child: Text(
                o.label.replaceFirst(' ', '\n'),
                textAlign: TextAlign.center,
                maxLines: 2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A hairline from the reader's chip to the truth: the size of the miss.
class _LanePainter extends CustomPainter {
  final double from;
  final double to;
  final Color ink;
  _LanePainter({required this.from, required this.to, required this.ink});

  late final Paint _line = Paint()
    ..color = ink.withValues(alpha: 0.45)
    ..strokeWidth = 1.5
    ..strokeCap = StrokeCap.round;
  late final Paint _caret = Paint()..color = ink;

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height - 3;
    canvas.drawLine(Offset(from, y - 4), Offset(from, y + 3), _line);
    canvas.drawLine(Offset(from, y), Offset(to, y), _line);
    // The marker's point, from the pill down to the chips.
    final caret = Path()
      ..moveTo(to - 5, 17)
      ..lineTo(to + 5, 17)
      ..lineTo(to, size.height + 1)
      ..close();
    canvas.drawPath(caret, _caret);
  }

  @override
  bool shouldRepaint(_LanePainter old) =>
      old.from != from || old.to != to || old.ink != ink;
}

/// The field: dot paper before the bet, then the dots filling it.
class _Field extends StatefulWidget {
  final CountScene scene;

  /// How many dots are out, fractional: the last one is still arriving.
  final double shown;

  /// How much of the faint dot paper still shows, 1 to 0.
  final double paper;
  final Color ink;
  const _Field({
    required this.scene,
    required this.shown,
    required this.paper,
    required this.ink,
  });

  @override
  State<_Field> createState() => _FieldState();
}

class _FieldState extends State<_Field> {
  _Dots? _dots;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final size = box.biggest;
        final s = widget.scene;
        var d = _dots;
        if (d == null ||
            d.size != size ||
            d.count != s.dots ||
            d.arrange != s.arrange) {
          d = _dots = _Dots.lay(size, s.dots, s.arrange);
        }
        return CustomPaint(
          size: size,
          painter: _FieldPainter(
            dots: d,
            shown: widget.shown,
            paper: widget.paper,
            ink: widget.ink,
          ),
        );
      },
    );
  }
}

/// Where every dot goes, worked out once per size. Dots are stored in the
/// order they arrive, split into three shades by arrival (dot i is shade
/// i % 3), so a cloud has depth and any first k dots draw in three calls.
class _Dots {
  final Size size;
  final int count;
  final CountArrange arrange;
  final double radius;

  /// x, y pairs per shade, in arrival order.
  final List<Float32List> shades;

  /// The same, for every dot, in arrival order.
  final Float32List all;

  /// The faint dot paper.
  final Float32List paper;

  _Dots(
    this.size,
    this.count,
    this.arrange,
    this.radius,
    this.shades,
    this.all,
    this.paper,
  );

  static const alphas = [1.0, 0.72, 0.48];

  /// A cloud has depth; a grid is for counting, so every dot is whole ink.
  double alpha(int shade) => arrange == CountArrange.grid ? 1.0 : alphas[shade];

  factory _Dots.lay(Size size, int n, CountArrange arrange) {
    final w = math.max(1.0, size.width);
    final h = math.max(1.0, size.height);
    final rnd = math.Random(n * 31 + 7);
    final pts = <Offset>[];
    double r;
    if (n > 0) {
      var cols = math.max(1, (math.sqrt(n * w / h)).ceil());
      var rows = (n / cols).ceil();
      if (arrange == CountArrange.grid) {
        // Rows of ten, in reading order: a grid is for counting, and
        // people count by tens.
        cols = math.min(n, 10);
        rows = (n / cols).ceil();
        final cell = math.min(w / cols, h / rows);
        r = (cell * 0.32).clamp(1.0, 15.0);
        for (var i = 0; i < n; i++) {
          pts.add(
            Offset(((i % cols) + 0.5) * cell, ((i ~/ cols) + 0.5) * cell),
          );
        }
      } else {
        final cw = w / cols;
        final ch = h / rows;
        r = (math.min(cw, ch) * 0.3).clamp(1.0, 10.0);
        // Every cell of the full rows, and a random few of the top one.
        final cells = <(int, int, double)>[];
        for (var row = 0; row < rows; row++) {
          for (var c = 0; c < cols; c++) {
            cells.add((c, row, rnd.nextDouble()));
          }
        }
        final top = cells.where((e) => e.$2 == rows - 1).toList()..shuffle(rnd);
        final drop = cols * rows - n;
        final dropped = top.take(drop).toSet();
        final keep = cells.where((e) => !dropped.contains(e)).toList();
        // Arrival rises from the floor, ragged, like a filling glass.
        keep.sort((a, b) => (a.$2 + a.$3 * 2.5).compareTo(b.$2 + b.$3 * 2.5));
        // Jitter up to half a cell: neighbours may touch, which is what
        // keeps a cloud from reading as a grid.
        final jx = cw / 2;
        final jy = ch / 2;
        for (final (c, row, _) in keep) {
          pts.add(
            Offset(
              (c + 0.5) * cw + (rnd.nextDouble() * 2 - 1) * jx * 0.9,
              h - (row + 0.5) * ch + (rnd.nextDouble() * 2 - 1) * jy * 0.9,
            ),
          );
        }
      }
    } else {
      r = 4;
    }

    final all = Float32List(pts.length * 2);
    final shades = List.generate(
      3,
      (b) => Float32List(((pts.length - b + 2) ~/ 3) * 2),
    );
    for (var i = 0; i < pts.length; i++) {
      all[i * 2] = pts[i].dx;
      all[i * 2 + 1] = pts[i].dy;
      final sh = shades[i % 3];
      final j = i ~/ 3;
      sh[j * 2] = pts[i].dx;
      sh[j * 2 + 1] = pts[i].dy;
    }

    const gap = 16.0;
    final pc = math.max(1, (w / gap).floor());
    final pr = math.max(1, (h / gap).floor());
    final ox = (w - (pc - 1) * gap) / 2;
    final oy = (h - (pr - 1) * gap) / 2;
    final paper = Float32List(pc * pr * 2);
    for (var y = 0; y < pr; y++) {
      for (var x = 0; x < pc; x++) {
        final k = (y * pc + x) * 2;
        paper[k] = ox + x * gap;
        paper[k + 1] = oy + y * gap;
      }
    }
    return _Dots(size, n, arrange, r, shades, all, paper);
  }
}

class _FieldPainter extends CustomPainter {
  final _Dots dots;
  final double shown;
  final double paper;
  final Color ink;
  _FieldPainter({
    required this.dots,
    required this.shown,
    required this.paper,
    required this.ink,
  });

  final Paint _pts = Paint()..strokeCap = StrokeCap.round;
  final Paint _one = Paint();

  @override
  void paint(Canvas canvas, Size size) {
    if (paper > 0.01 && dots.paper.isNotEmpty) {
      _pts
        ..color = ink.withValues(alpha: 0.17 * paper)
        ..strokeWidth = 2.4;
      canvas.drawRawPoints(PointMode.points, dots.paper, _pts);
    }
    final n = dots.count;
    if (n == 0 || shown <= 0) return;

    // The newest dots grow in over the last few percent; those before them
    // are whole and drawn three shades at a time.
    // [shown] runs to n; the arrivals run a window further, so that when
    // the count lands the last dot has landed too.
    final window = math.max(1.0, n * 0.05);
    final out = shown * (n + window) / n;
    final whole = (out - window).floor().clamp(0, n);
    final r = dots.radius;
    _pts.strokeWidth = r * 2;
    for (var b = 0; b < 3; b++) {
      final k = ((whole - b + 2) ~/ 3).clamp(0, dots.shades[b].length ~/ 2);
      if (k == 0) continue;
      _pts.color = ink.withValues(alpha: dots.alpha(b));
      canvas.drawRawPoints(
        PointMode.points,
        Float32List.sublistView(dots.shades[b], 0, k * 2),
        _pts,
      );
    }
    final last = out.ceil().clamp(0, n);
    for (var i = whole; i < last; i++) {
      final t = ((out - i) / window).clamp(0.0, 1.0);
      if (t <= 0) continue;
      final e = Curves.easeOutBack.transform(t);
      _one.color = ink.withValues(alpha: dots.alpha(i % 3) * t);
      canvas.drawCircle(
        Offset(dots.all[i * 2], dots.all[i * 2 + 1] + 6 * (1 - t)),
        r * e,
        _one,
      );
    }
  }

  @override
  bool shouldRepaint(_FieldPainter old) =>
      old.shown != shown ||
      old.paper != paper ||
      old.ink != ink ||
      !identical(old.dots, dots);
}
