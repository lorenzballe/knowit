import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../data/topics.dart' show kSpectrum;
import '../theme.dart';

/// The looks a [GlowOutline] can take, all in the app's own colours
/// (kSpectrum) washed towards white, never at full strength: full strength
/// is the magic card's (widgets/magic_card.dart).
enum GlowOutlineStyle {
  /// A white hairline, and a sheen travelling slowly round it: white at its
  /// heart, the spectrum's cool end behind it and the warm end ahead, as
  /// white light breaks at the edge of a glass.
  sheen,

  /// A white hairline, and a soft light round it that slowly comes and goes,
  /// as a sleeping laptop's lamp did.
  breath,

  /// The whole spectrum, washed towards white, turning slowly round the edge:
  /// the magic card's rim, quietened.
  spectrum,
}

/// A thin, luminous outline round [child], for the one thing on a screen
/// that should stand out a little: the line of the day, and whatever else
/// earns it, so that each wears the same light rather than one of its own.
///
/// One controller drives it and one painter draws it, the colours laid
/// along the edge by a sweep gradient set so the light moves round at one
/// pace, corners and sides alike. Nothing else is drawn again as it moves:
/// [child] is kept as it was painted. The controller is muted by
/// [TickerMode] (a page or tab not on screen), and stops on its own when
/// the outline has not been painted for a few frames (scrolled away, a tab
/// beside the one shown) until it is painted again. With motion off it is
/// a still frame, chosen to be a good one.
///
/// [child] is drawn at its own size, its corners [radius] round; the
/// outline runs along its edge and its light spills a little past it.
class GlowOutline extends StatefulWidget {
  const GlowOutline({
    super.key,
    required this.child,
    this.style = GlowOutlineStyle.sheen,
    this.radius = 22,
  });

  final Widget child;
  final GlowOutlineStyle style;

  /// The corners of [child], which the outline follows.
  final double radius;

  @override
  State<GlowOutline> createState() => _GlowOutlineState();
}

class _GlowOutlineState extends State<GlowOutline>
    with SingleTickerProviderStateMixin {
  /// One lap of the sheen, one breath, one turn of the spectrum.
  static Duration _periodOf(GlowOutlineStyle style) => switch (style) {
    GlowOutlineStyle.sheen => const Duration(seconds: 10),
    GlowOutlineStyle.breath => const Duration(seconds: 6),
    GlowOutlineStyle.spectrum => const Duration(seconds: 20),
  };

  late final AnimationController _turn = AnimationController(
    vsync: this,
    duration: _periodOf(widget.style),
  )..addListener(_tick);

  /// Frames ticked, and the frame the outline was last painted on: when
  /// the two drift apart nobody is looking, and the controller sleeps until
  /// the outline is painted again.
  int _ticks = 0;
  int _paintedAt = 0;
  bool _asleep = false;

  /// Whether the reader asked for less motion: the outline stands still.
  bool _still = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _still = MediaQuery.disableAnimationsOf(context);
    _run();
  }

  @override
  void didUpdateWidget(GlowOutline old) {
    super.didUpdateWidget(old);
    if (old.style == widget.style) return;
    _turn.duration = _periodOf(widget.style);
    if (_turn.isAnimating) _turn.repeat();
  }

  void _run() {
    if (_still) {
      _turn.stop();
    } else if (!_turn.isAnimating && !_asleep) {
      _turn.repeat();
    }
  }

  void _tick() {
    if (!_turn.isAnimating) return;
    if (++_ticks - _paintedAt > 3) {
      // Unseen: stop asking for frames, but leave the outline marked for
      // paint, so the first time it is painted again it wakes.
      _asleep = true;
      _turn.stop();
    }
  }

  void _painted() {
    _paintedAt = _ticks;
    if (!_asleep) return;
    _asleep = false;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_still && !_turn.isAnimating) _turn.repeat();
    });
  }

  @override
  void dispose() {
    _turn.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        foregroundPainter: _OutlinePainter(
          style: widget.style,
          radius: widget.radius,
          dark: context.p.isDark,
          turn: _turn,
          hold: _still,
          onPainted: _painted,
        ),
        willChange: !_still,
        child: RepaintBoundary(child: widget.child),
      ),
    );
  }
}

/// Where along a rounded rectangle's edge a point is, and which way it
/// lies from the middle: the edge measured clockwise from the middle of
/// its top-left corner, so a light can be laid along it at an even pace.
class _Edge {
  _Edge(this.size, this.box) {
    final double r = box.tlRadiusX;
    _top = box.width - 2 * r;
    _side = box.height - 2 * r;
    _arc = math.pi * r / 2;
    length = 2 * (_top + _side) + 4 * _arc;
  }

  /// The size of what the outline goes round, and the edge itself.
  final Size size;
  final RRect box;
  late final double length;
  late final double _top, _side, _arc;

  Offset get centre => box.center;

  /// The point [s] along the edge, from the middle of the top-left corner.
  Offset at(double s) {
    final double r = box.tlRadiusX;
    double d = (s + _arc / 2) % length;
    Offset arc(Offset c, double from) {
      final double a = from + d / r;
      return c + Offset(math.cos(a), math.sin(a)) * r;
    }

    if (d < _top) return Offset(box.left + r + d, box.top);
    d -= _top;
    if (d < _arc) {
      return arc(Offset(box.right - r, box.top + r), -math.pi / 2);
    }
    d -= _arc;
    if (d < _side) return Offset(box.right, box.top + r + d);
    d -= _side;
    if (d < _arc) return arc(Offset(box.right - r, box.bottom - r), 0);
    d -= _arc;
    if (d < _top) return Offset(box.right - r - d, box.bottom);
    d -= _top;
    if (d < _arc) {
      return arc(Offset(box.left + r, box.bottom - r), math.pi / 2);
    }
    d -= _arc;
    if (d < _side) return Offset(box.left, box.bottom - r - d);
    d -= _side;
    return arc(Offset(box.left + r, box.top + r), math.pi);
  }

  final Map<double, Shader> _spectra = {};

  /// The spectrum washed [wash] of the way to white, laid once round the
  /// edge from the top-left corner. It never moves, so it is made once.
  Shader spectrum(Rect bounds, double wash) => _spectra[wash] ??= sweep(
    bounds,
    0,
    (u) => _spectral(u, wash),
    samples: kSpectrum.length * 2,
  );

  /// A sweep about the middle that lays [colourAt] evenly along the whole
  /// edge, [colourAt] being asked for each of [samples] points from [from]
  /// (a fraction of the way round) by how far round from there it is.
  Shader sweep(
    Rect bounds,
    double from,
    Color Function(double) colourAt, {
    int samples = 48,
  }) {
    final List<Color> colours = [];
    final List<double> stops = [];
    final Offset c = centre;
    double angle(double u) {
      final Offset p = at((from + u) * length) - c;
      return math.atan2(p.dy, p.dx);
    }

    final double first = angle(0);
    double last = first;
    for (int k = 0; k <= samples; k++) {
      final double u = k / samples;
      double a = k == samples ? first + 2 * math.pi : angle(u);
      // Clockwise on the screen is the way the angle grows; once round it
      // has come back past where it started.
      while (a < last) {
        a += 2 * math.pi;
      }
      last = a;
      colours.add(colourAt(u));
      stops.add(((a - first) / (2 * math.pi)).clamp(0.0, 1.0));
    }
    return SweepGradient(
      colors: colours,
      stops: stops,
      transform: GradientRotation(first),
    ).createShader(bounds);
  }
}

/// The colour [stops] give at [u], each stop a place along the way (0 to 1)
/// and the colour there, the colours between them mixed.
Color _along(List<(double, Color)> stops, double u) {
  if (u <= stops.first.$1) return stops.first.$2;
  for (int i = 1; i < stops.length; i++) {
    final (double at, Color colour) = stops[i];
    if (u <= at) {
      final (double was, Color before) = stops[i - 1];
      return Color.lerp(before, colour, (u - was) / (at - was))!;
    }
  }
  return stops.last.$2;
}

/// A colour of the spectrum, [wash] of the way to white.
Color _washed(int hue, double wash) =>
    Color.lerp(kSpectrum[hue], Colors.white, wash)!;

/// The spectrum [u] of the way round (0 to 1, yellow to yellow), each hue
/// mixed into the next, [wash] of the way to white.
Color _spectral(double u, double wash) {
  final int n = kSpectrum.length;
  final double at = (u % 1) * n;
  final int i = at.floor() % n;
  return Color.lerp(
    _washed(i, wash),
    _washed((i + 1) % n, wash),
    at - at.floor(),
  )!;
}

class _OutlinePainter extends CustomPainter {
  _OutlinePainter({
    required this.style,
    required this.radius,
    required this.dark,
    required this.turn,
    required this.hold,
    required this.onPainted,
  }) : super(repaint: turn);

  final GlowOutlineStyle style;
  final double radius;
  final bool dark;
  final Animation<double> turn;

  /// Whether the outline stands still, at the moment chosen for it.
  final bool hold;
  final VoidCallback onPainted;

  /// The hairline, in points.
  static const double _line = 1;

  _Edge? _edge;

  _Edge _edgeOf(Size size) {
    final _Edge? kept = _edge;
    if (kept != null && kept.size == size) return kept;
    return _edge = _Edge(
      size,
      RRect.fromRectAndRadius(
        (Offset.zero & size).deflate(_line / 2),
        Radius.circular(math.max(0, radius - _line / 2)),
      ),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    onPainted();
    if (size.isEmpty) return;
    final _Edge edge = _edgeOf(size);
    final Rect bounds = Offset.zero & size;
    switch (style) {
      case GlowOutlineStyle.sheen:
        _sheen(canvas, edge, bounds, hold ? 0 : turn.value);
      case GlowOutlineStyle.breath:
        // In and out, easing at both ends, as breath does; held still most
        // of the way to its brightest.
        _breath(
          canvas,
          edge,
          bounds,
          hold ? 0.7 : 0.5 - 0.5 * math.cos(2 * math.pi * turn.value),
        );
      case GlowOutlineStyle.spectrum:
        _spectrum(canvas, edge, bounds, hold ? 0 : turn.value);
    }
  }

  /// The hairline all round, in [colour].
  void _hairline(Canvas canvas, _Edge edge, Color colour) => canvas.drawRRect(
    edge.box,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _line
      ..color = colour,
  );

  /// [shader] along the edge, as a line [width] wide, at [alpha]; blurred
  /// by [blur] when given, as the light the line throws.
  void _stroke(
    Canvas canvas,
    _Edge edge,
    Shader shader,
    double width,
    double alpha, {
    double blur = 0,
  }) {
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..shader = shader
      ..color = Color.fromRGBO(255, 255, 255, alpha.clamp(0.0, 1.0));
    if (blur > 0) paint.maskFilter = MaskFilter.blur(BlurStyle.normal, blur);
    canvas.drawRRect(edge.box, paint);
  }

  /// How much of the edge the sheen covers.
  static const double _sheenSpan = 0.42;

  /// The sheen from its tail to its head: the cool end of the spectrum
  /// behind, white at its heart, the warm end ahead, each fading out.
  static List<(double, Color)> _sheenOf(double wash) => [
    (0.00, _washed(8, wash).withValues(alpha: 0)),
    (0.12, _washed(8, wash).withValues(alpha: 0.3)),
    (0.26, _washed(6, wash).withValues(alpha: 0.65)),
    (0.38, _washed(4, wash).withValues(alpha: 0.9)),
    (0.50, Colors.white),
    (0.62, _washed(0, wash).withValues(alpha: 0.9)),
    (0.74, _washed(16, wash).withValues(alpha: 0.65)),
    (0.88, _washed(13, wash).withValues(alpha: 0.3)),
    (1.00, _washed(13, wash).withValues(alpha: 0)),
  ];

  static final List<(double, Color)> _sheenNight = _sheenOf(0.45);
  static final List<(double, Color)> _sheenDay = _sheenOf(0.5);

  /// The hairline under the light: at night the spectrum washed almost to
  /// white, a white rainbow; on paper a pencil line, as white is no light
  /// there.
  void _underline(Canvas canvas, _Edge edge, Rect bounds, double alpha) {
    if (dark) {
      _stroke(canvas, edge, edge.spectrum(bounds, 0.82), _line, alpha);
    } else {
      _hairline(
        canvas,
        edge,
        const Color(0xFF131316).withValues(alpha: alpha * 0.36),
      );
    }
  }

  void _sheen(Canvas canvas, _Edge edge, Rect bounds, double t) {
    _underline(canvas, edge, bounds, 0.34);
    // The sheen's heart sits on the top-left corner at the start of its lap
    // (and there, still, for a reader who asked for less motion).
    final double from = t - _sheenSpan / 2;
    final List<(double, Color)> light = dark ? _sheenNight : _sheenDay;
    final Shader shader = edge.sweep(
      bounds,
      from,
      (u) => u >= _sheenSpan ? light.last.$2 : _along(light, u / _sheenSpan),
      samples: 72,
    );
    _stroke(canvas, edge, shader, 6, dark ? 0.75 : 0.3, blur: 7);
    _stroke(canvas, edge, shader, _line * 1.25, 1);
  }

  /// The breath at [b], from its faintest (0) to its brightest (1).
  void _breath(Canvas canvas, _Edge edge, Rect bounds, double b) {
    _stroke(
      canvas,
      edge,
      edge.spectrum(bounds, dark ? 0.55 : 0.35),
      5,
      dark ? 0.12 + 0.38 * b : 0.08 + 0.22 * b,
      blur: 8,
    );
    _underline(canvas, edge, bounds, 0.3 + 0.45 * b);
  }

  void _spectrum(Canvas canvas, _Edge edge, Rect bounds, double t) {
    final double wash = dark ? 0.52 : 0.5;
    final Shader shader = edge.sweep(
      bounds,
      t,
      (u) => _spectral(u, wash),
      samples: kSpectrum.length * 3,
    );
    _stroke(canvas, edge, shader, 4, dark ? 0.32 : 0.22, blur: 6);
    _stroke(canvas, edge, shader, _line * 1.25, dark ? 0.85 : 0.8);
  }

  @override
  bool shouldRepaint(_OutlinePainter old) =>
      old.style != style ||
      old.radius != radius ||
      old.dark != dark ||
      old.hold != hold ||
      old.turn != turn;
}
