/// Go deeper's parts in the app's own language, under the card's coloured
/// head: the ground every screen stands on (black, or paper), each part a
/// raised rounded card like the profile's, its name a small tinted label as
/// a card's subject is, the asking a pill like the app's own, and nothing
/// that moves faster than it needs to.
///
/// The subject's colour is only an echo: in the names, on the cards' edges
/// and in the chips over the two views.
library;

import 'dart:math' as math;
import 'dart:typed_data' show Float32List;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart'
    show PipelineOwner, RenderProxyBox, ShaderMaskLayer;
import 'package:flutter/services.dart' show HapticFeedback;

import '../../l10n/l10n.dart';
import '../../theme.dart';
import 'header.dart' show DeeperGlow;
import 'look.dart';
import 'pieces.dart' show deeperStill;

/// The few colours the parts use, from the app's palette and the subject.
class AppInk {
  AppInk._(this.p, this.accent, this.edge, this.sideA, this.sideB);

  factory AppInk.of(BuildContext context, DeeperLook look) {
    final Palette p = context.p;
    final bool dark = p.isDark;
    final double c = look.pearl ? 0.02 : 0.09;
    Color tint(double l, double chroma, double hue) =>
        Oklch(l, chroma, hue % 360).toColour();
    final Color accent = look.pearl
        ? p.inkMuted
        : dark
        ? tint(0.80, c, look.hue)
        : tint(0.48, c * 1.15, look.hue);
    return AppInk._(
      p,
      accent,
      Color.alphaBlend(accent.withValues(alpha: dark ? 0.16 : 0.2), p.line),
      dark
          ? tint(0.80, c, look.sideA.hue)
          : tint(0.47, c * 1.2, look.sideA.hue),
      dark
          ? tint(0.80, c, look.sideB.hue)
          : tint(0.47, c * 1.2, look.sideB.hue),
    );
  }

  final Palette p;

  /// The subject's colour, quietly: the names and the few marks.
  final Color accent;

  /// A card's edge, the app's hairline with a breath of the subject in it.
  final Color edge;

  /// The two views' own marks.
  final Color sideA;
  final Color sideB;

  /// What sits inside a card: a box to write in, a bubble, a view.
  Color get inset => p.isDark ? const Color(0xFF1A1A1E) : p.surface;
}

/// The colour the sheet is bathed in under the head: the subject's own,
/// deep at night and pale on paper, flowing down behind the cards and
/// fading into the app's ground over most of the screen.
Color appBath(DeeperLook world, Palette p) {
  if (world.pearl) {
    return p.isDark ? const Color(0xFF1C1C21) : const Color(0xFFECEAE4);
  }
  final Oklch o = Oklch.of(world.world);
  // A yellow deepens through amber, never olive.
  final double deepHue = (o.h > 80 && o.h < 125 ? o.h - 32 : o.h - 8) % 360;
  return p.isDark
      ? Oklch(0.31, math.min(o.c * 0.55, 0.11), deepHue).toColour()
      : Oklch(0.925, math.min(o.c * 0.3, 0.05), o.h).toColour();
}

/// Tells [height] how tall its child is, as it is laid out, so a painting
/// behind it knows where it ends.
class ReportHeight extends SingleChildRenderObjectWidget {
  const ReportHeight({super.key, required this.height, super.child});

  final ValueNotifier<double> height;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _ReportHeight(height);

  @override
  void updateRenderObject(BuildContext context, _ReportHeight render) =>
      render.height = height;
}

class _ReportHeight extends RenderProxyBox {
  _ReportHeight(this.height);

  ValueNotifier<double> height;

  @override
  void performLayout() {
    super.performLayout();
    height.value = size.height;
  }
}

/// What scrolls in the sheet goes soft and dissolves as it passes under the
/// sheet's top edge, as every page of the app does under its bar, instead of
/// being cut by the edge. Only the words and the parts dissolve: the
/// painting behind them stays whole, so they fade into the card's colour.
///
/// [scroll] is how far the sheet has scrolled. The child lies at the top of
/// what scrolls, so the edge is [scroll] down from the child's top. At rest
/// nothing dissolves; the edge comes in over the first [depth] of scrolling,
/// so the head is whole until the reader moves it.
class TopDissolve extends SingleChildRenderObjectWidget {
  const TopDissolve({
    super.key,
    required this.scroll,
    this.depth = 44,
    super.child,
  });

  final ValueListenable<double> scroll;
  final double depth;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _TopDissolve(scroll, depth);

  @override
  void updateRenderObject(BuildContext context, _TopDissolve render) => render
    ..scroll = scroll
    ..depth = depth;
}

class _TopDissolve extends RenderProxyBox {
  _TopDissolve(this._scroll, this._depth);

  ValueListenable<double> _scroll;
  set scroll(ValueListenable<double> value) {
    if (identical(value, _scroll)) return;
    if (attached) {
      _scroll.removeListener(markNeedsPaint);
      value.addListener(markNeedsPaint);
    }
    _scroll = value;
    markNeedsPaint();
  }

  double _depth;
  set depth(double value) {
    if (value == _depth) return;
    _depth = value;
    markNeedsPaint();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _scroll.addListener(markNeedsPaint);
  }

  @override
  void detach() {
    _scroll.removeListener(markNeedsPaint);
    super.detach();
  }

  @override
  bool get alwaysNeedsCompositing => child != null;

  @override
  void paint(PaintingContext context, Offset offset) {
    final RenderBox? child = this.child;
    if (child == null) return;
    final double at = math.max(0, _scroll.value);
    final double strength = _depth <= 0 ? 0 : (at / _depth).clamp(0.0, 1.0);
    if (strength == 0) {
      // At rest: drawn as it is, with no layer of its own to pay for.
      layer = null;
      context.paintChild(child, offset);
      return;
    }
    final ShaderMaskLayer mask = layer as ShaderMaskLayer? ?? ShaderMaskLayer();
    mask
      ..shader = ui.Gradient.linear(Offset(0, at), Offset(0, at + _depth), [
        Color.fromRGBO(0, 0, 0, 1 - strength),
        const Color(0xFF000000),
      ])
      ..maskRect = offset & size
      ..blendMode = BlendMode.dstIn;
    layer = mask;
    context.pushLayer(mask, super.paint, offset);
  }
}

/// Head and body as one painting, behind everything in the sheet: the
/// card's colour with its drifting lights where the head is, falling on
/// one eased curve into the bath's shade behind the first parts, then
/// through the bath's mesh of light into the ground, under one grain. One
/// painting has no edge between layers anywhere, at any scroll.
class AppWhole extends CustomPainter {
  AppWhole({
    required this.look,
    required this.bath,
    required this.ground,
    required this.drift,
    required this.scroll,
    required this.head,
    required this.foot,
    required this.depth,
  }) : super(repaint: Listenable.merge([drift, scroll, head]));

  final DeeperLook look;
  final Color bath;
  final Color ground;
  final Animation<double> drift;
  final ValueListenable<double>? scroll;
  final ValueListenable<double> head;
  final double foot;

  /// How far the bath runs below the head before it is the ground.
  final double depth;

  static const List<double> _ten = [
    0,
    0.1,
    0.2,
    0.3,
    0.4,
    0.5,
    0.6,
    0.7,
    0.8,
    0.9,
    1,
  ];

  static double _smooth(double t) => t * t * (3 - 2 * t);

  @override
  void paint(Canvas canvas, Size size) {
    final double h = head.value;
    if (h <= 0) return;
    final double w = size.width;
    // The colour lets go from just under the question and is the bath's
    // shade a long way below the head's end, behind the first part.
    final double m0 = h - 46;
    final double m1 = h + 300;
    final double f1 = m1 + depth;

    // The head: its colour, its depth and its lights, painted on down past
    // its end so nothing stops there.
    DeeperGlow(
      look: look,
      drift: drift,
      scroll: scroll,
      foot: foot,
      head: h,
      whole: true,
    ).paint(canvas, Size(w, m1 + 4));

    // One gradient from the head's colour through the bath into the
    // ground: the bath coming in over the head on an eased curve, then its
    // fall, worked out in OKLCH, the colour let go before the light and
    // its hue turning a little towards its deeper shade.
    final double r = (m1 - m0) / (f1 - m0);
    final Oklch a = Oklch.of(bath);
    final Oklch b = Oklch.of(ground);
    final List<Color> colours = [];
    final List<double> stops = [];
    for (final double t in _ten) {
      colours.add(bath.withValues(alpha: _smooth(t)));
      stops.add(r * t);
    }
    const int n = 16;
    for (int i = 1; i <= n; i++) {
      final double t = i / n;
      final double e = _smooth(t);
      colours.add(
        Oklch(
          a.l + (b.l - a.l) * e,
          a.c * (1 - math.min(1, e * 1.15)),
          (a.h - (look.dark ? 14 : 6) * e) % 360,
        ).toColour(),
      );
      stops.add(r + (1 - r) * t);
    }
    canvas.drawRect(
      Rect.fromLTRB(0, m0, w, f1),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, m0),
          Offset(0, f1),
          colours,
          stops,
        ),
    );

    // The bath's mesh: three pools of nearby hues, far enough below the
    // head that they rise into it only as the faintest light.
    final double v = drift.value;
    final List<Color> pools = _Bath._poolColoursFor(look);
    const List<(double, double, double, double)> at = [
      (0.15, 0.06, 0.95, 0.4),
      (0.9, 0.3, 0.85, 2.1),
      (0.2, 0.56, 0.8, 3.7),
    ];
    for (int i = 0; i < at.length; i++) {
      final (double x, double y, double rr, double phase) = at[i];
      final double turn = 2 * math.pi * v + phase;
      final Offset c = Offset(
        w * (x + 0.1 * (math.sin(turn) - math.sin(phase))),
        m1 - 40 + depth * (y + 0.04 * (math.cos(turn) - math.cos(phase))),
      );
      final double radius = w * rr;
      final double strength = (look.dark
          ? const [0.45, 0.36, 0.26]
          : const [0.55, 0.42, 0.3])[i];
      canvas.drawCircle(
        c,
        radius,
        Paint()
          ..shader = ui.Gradient.radial(c, radius, [
            for (final double t in _ten)
              pools[i].withValues(
                alpha: strength * math.exp(-4 * t * t) * (1 - t * t * t),
              ),
          ], _ten),
      );
    }

    // One grain over all of it, the same everywhere, so no change of
    // texture marks where the head was.
    final Size grained = Size(w, f1);
    canvas.drawRawPoints(
      ui.PointMode.points,
      _Bath._grain(grained, 0),
      Paint()
        ..color = Colors.white.withValues(alpha: look.dark ? 0.045 : 0.05)
        ..strokeWidth = 0.6,
    );
    canvas.drawRawPoints(
      ui.PointMode.points,
      _Bath._grain(grained, 1),
      Paint()
        ..color = Colors.black.withValues(alpha: look.dark ? 0.06 : 0.03)
        ..strokeWidth = 0.6,
    );
  }

  @override
  bool shouldRepaint(AppWhole old) =>
      old.look != look ||
      old.bath != bath ||
      old.ground != ground ||
      old.depth != depth ||
      old.foot != foot;
}

/// The bath itself: the colour at the top, falling slowly into the ground
/// by [depth] below through the colour's own deeper shade, the head's
/// light still glowing faintly at its top, and a fine grain over it so the
/// long fall shows no steps.
class AppBath extends StatelessWidget {
  const AppBath({
    super.key,
    required this.look,
    required this.bath,
    required this.ground,
    required this.depth,
    this.drift,
    this.lead = 0,
  });

  /// How far above its own top the bath begins, clear there and coming in
  /// over the head's foot: the head and the bath are then one painted
  /// light, with no edge between two layers.
  final double lead;

  /// The head's slow drift, which the bath's lights follow.
  final Animation<double>? drift;

  final DeeperLook look;
  final Color bath;
  final Color ground;
  final double depth;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: SizedBox(
      height: depth + lead,
      width: double.infinity,
      child: CustomPaint(painter: _Bath(look, bath, ground, drift, lead)),
    ),
  );
}

class _Bath extends CustomPainter {
  _Bath(this.look, this.bath, this.ground, this.drift, this.lead)
    : super(repaint: drift);

  final double lead;

  final Animation<double>? drift;

  /// The bath's lights: where each rests (across, and down the bath), its
  /// size against the width, and where in its slow circle it starts.
  static const List<(double, double, double, double)> _pools = [
    (0.12, 0.06, 0.95, 0.4),
    (0.92, 0.26, 0.85, 2.1),
    (0.18, 0.5, 0.8, 3.7),
  ];

  static final Map<(int, bool), List<Color>> _pooled = {};

  /// Three hues near the subject's, as the head's own lights are, set
  /// deep at night and pale on paper so the cards' words keep reading.
  List<Color> _poolColours() => _poolColoursFor(look);

  static List<Color> _poolColoursFor(DeeperLook look) =>
      _pooled[(look.world.toARGB32(), look.dark)] ??= [
        for (final Color g in [look.glow[0], look.glow[2], look.glow[3]])
          () {
            final Oklch o = Oklch.of(g);
            return look.dark
                ? Oklch(0.42, math.min(o.c * 0.75, 0.13), o.h).toColour()
                : Oklch(0.9, math.min(o.c * 0.5, 0.08), o.h).toColour();
          }(),
      ];

  final DeeperLook look;
  final Color bath;
  final Color ground;

  static final Map<(int, int, bool), (List<Color>, List<double>)> _falls = {};

  /// The fall, worked out in OKLCH so it stays clean all the way: the
  /// lightness eased, the colour let go a little sooner than the light,
  /// and the hue turned a few degrees towards its deeper shade on the way
  /// down.
  (List<Color>, List<double>) _fall() =>
      _falls[(bath.toARGB32(), ground.toARGB32(), look.dark)] ??= () {
        final Oklch a = Oklch.of(bath);
        final Oklch b = Oklch.of(ground);
        final List<Color> colours = [];
        final List<double> stops = [];
        const int n = 14;
        for (int i = 0; i <= n; i++) {
          final double t = i / n;
          final double e = t * t * (3 - 2 * t);
          final double ec = math.min(1, e * 1.15);
          colours.add(
            Oklch(
              a.l + (b.l - a.l) * e,
              a.c * (1 - ec),
              (a.h - (look.dark ? 14 : 6) * e) % 360,
            ).toColour(),
          );
          stops.add(t);
        }
        return (colours, stops);
      }();

  static final Map<(int, int, int), Float32List> _grains = {};

  static Float32List _grain(Size size, int seed) =>
      _grains[(size.width.round(), size.height.round(), seed)] ??= () {
        final math.Random r = math.Random(41 + seed);
        final int n = (size.width * size.height / 14).round();
        final Float32List at = Float32List(n * 2);
        for (int i = 0; i < n; i++) {
          at[i * 2] = r.nextDouble() * size.width;
          at[i * 2 + 1] = r.nextDouble() * size.height;
        }
        return at;
      }();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(Offset.zero & size);
    // The fall, from a little above where the lead-in ends, so the two
    // overlap and no row between them is left half painted.
    canvas.save();
    canvas.translate(0, lead - 2);
    _paintFall(canvas, Size(size.width, size.height - lead + 2));
    canvas.restore();
    if (lead <= 0) return;
    // The lead-in: the bath coming in over the head's foot on an eased
    // curve, opaque by the time the fall begins.
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, lead),
      Paint()
        ..shader = ui.Gradient.linear(Offset.zero, Offset(0, lead), [
          for (final double t in _ease)
            bath.withValues(alpha: t * t * (3 - 2 * t)),
        ], _ease),
    );
  }

  static const List<double> _ease = [
    0,
    0.1,
    0.2,
    0.3,
    0.4,
    0.5,
    0.6,
    0.7,
    0.8,
    0.9,
    1,
  ];

  void _paintFall(Canvas canvas, Size size) {
    final Rect box = Offset.zero & size;
    // The pools reach past the bath's top; they stay in it, under the head.
    canvas.clipRect(box);
    final (List<Color> colours, List<double> stops) = _fall();
    canvas.drawRect(
      box,
      Paint()
        ..shader = ui.Gradient.linear(
          box.topCenter,
          box.bottomCenter,
          colours,
          stops,
        ),
    );
    // A mesh of light: three pools of nearby hues, softly overlapping,
    // drifting slowly in small circles with the head's own lights.
    final double v = drift?.value ?? 0;
    final List<Color> pools = _poolColours();
    for (int i = 0; i < _pools.length; i++) {
      final (double x, double y, double r, double phase) = _pools[i];
      final double a = 2 * math.pi * v + phase;
      final Offset c = Offset(
        size.width * (x + 0.1 * (math.sin(a) - math.sin(phase))),
        size.height * (y + 0.04 * (math.cos(a) - math.cos(phase))),
      );
      final double radius = size.width * r;
      final double strength =
          (look.dark ? const [0.5, 0.38, 0.26] : const [0.6, 0.45, 0.3])[i] *
          (1 - y * 0.6);
      canvas.drawCircle(
        c,
        radius,
        Paint()
          ..shader = ui.Gradient.radial(
            c,
            radius,
            [
              pools[i].withValues(alpha: strength),
              pools[i].withValues(alpha: strength * 0.45),
              pools[i].withValues(alpha: 0),
            ],
            const [0, 0.5, 1],
          ),
      );
    }

    // The head's light, carried on a little way down: a soft pool at the
    // top, wider than the screen, so the head and the bath are one light.
    final Offset centre = Offset(size.width * 0.3, 0);
    final double radius = size.width * 1.1;
    final Color glow = look.glow[1];
    canvas.drawCircle(
      centre,
      radius,
      Paint()
        ..shader = ui.Gradient.radial(
          centre,
          radius,
          [
            glow.withValues(alpha: look.dark ? 0.14 : 0.22),
            glow.withValues(alpha: look.dark ? 0.05 : 0.08),
            glow.withValues(alpha: 0),
          ],
          const [0, 0.45, 1],
        ),
    );
    // At its very top the bath is the plain shade the head falls into, so
    // the head runs on into it with no seam; the pools come in below.
    const double seam = 260;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, seam),
      Paint()
        ..shader = ui.Gradient.linear(Offset.zero, const Offset(0, seam), [
          for (final double t in _ease)
            bath.withValues(alpha: 1 - t * t * (3 - 2 * t)),
        ], _ease),
    );
    // A grain finer than the eye can pick out, lighter and darker, so the
    // long fall never shows a step.
    canvas.drawRawPoints(
      ui.PointMode.points,
      _grain(size, 0),
      Paint()
        ..color = Colors.white.withValues(alpha: look.dark ? 0.04 : 0.05)
        ..strokeWidth = 0.6,
    );
    canvas.drawRawPoints(
      ui.PointMode.points,
      _grain(size, 1),
      Paint()
        ..color = Colors.black.withValues(alpha: look.dark ? 0.06 : 0.025)
        ..strokeWidth = 0.6,
    );
  }

  @override
  bool shouldRepaint(_Bath old) =>
      old.look != look ||
      old.bath != bath ||
      old.ground != ground ||
      old.drift != drift;
}

/// The words of a part, as the app sets its running text.
TextStyle appBody(BuildContext context) => AppText.body(
  size: 16,
  height: 1.6,
  color: context.p.ink.withValues(alpha: context.p.isDark ? 0.9 : 0.88),
);

/// The idea said simply: in the app's display face, as its cards speak.
TextStyle appSimply(BuildContext context) => AppText.display(
  size: 20,
  weight: FontWeight.w500,
  height: 1.4,
  spacing: -0.2,
  color: context.p.ink,
);

/// A small name in capitals, as a card names its subject.
TextStyle appLabel(Color colour, {double size = 11.5}) => AppText.label(
  size: size,
  weight: FontWeight.w700,
  spacing: 1.4,
  height: 1.3,
  color: colour,
);

/// A part: a raised rounded card, its name a small tinted label, the line
/// on what it gives under it, then what it says.
class AppSection extends StatelessWidget {
  const AppSection({
    super.key,
    required this.look,
    required this.title,
    required this.child,
    this.lead,
    this.badge,
  });

  final DeeperLook look;
  final String title;
  final String? lead;
  final Widget? badge;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final Palette p = context.p;
    final bool dark = p.isDark;
    const BorderRadius round = BorderRadius.all(Radius.circular(22));
    // A card over the light: the colour beneath shows through a fill dense
    // enough for the words to read as on any of the app's cards; a hairline
    // of light along its top edge, and two soft shadows, one near and one
    // far, lifting it off.
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: round,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.22 : 0.04),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.24 : 0.05),
            blurRadius: 34,
            spreadRadius: -10,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: round,
        // No blur of what lies behind: the painting under a part is soft
        // already, so the fill alone looks the same, and a blur under every
        // part, redone each frame the sheet moved, made the sheet stutter.
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: round,
            color: dark
                ? const Color(0xFF121215).withValues(alpha: 0.84)
                : Colors.white.withValues(alpha: 0.86),
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: round,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withValues(alpha: dark ? 0.035 : 0.25),
                  Colors.white.withValues(alpha: 0),
                ],
                stops: const [0, 0.4],
              ),
              border: Border.all(
                color: dark ? const Color(0x12FFFFFF) : const Color(0x0D000000),
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 0,
                  left: 24,
                  right: 24,
                  child: Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0),
                          Colors.white.withValues(alpha: dark ? 0.16 : 0.9),
                          Colors.white.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ),
                _body(p),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _body(Palette p) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              // The one mark of the subject's colour on a part.
              ExcludeSemantics(
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: look.pearl ? p.ink : look.world,
                  ),
                ),
              ),
              const SizedBox(width: 9),
              Flexible(
                child: Semantics(
                  header: true,
                  child: Text(
                    title.toUpperCase(),
                    style: AppText.label(
                      size: 11,
                      weight: FontWeight.w600,
                      spacing: 1.3,
                      height: 1.3,
                      color: p.inkMuted,
                    ),
                  ),
                ),
              ),
              if (badge case final Widget b) ...[const SizedBox(width: 10), b],
            ],
          ),
          if (lead case final String said) ...[
            const SizedBox(height: 8),
            Text(
              said,
              style: AppText.body(size: 14, height: 1.45, color: p.inkMuted),
            ),
          ],
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

/// The two views: each on an inset of its own inside the card, under a
/// small chip in its own colour, the one under the other.
class AppVersus extends StatelessWidget {
  const AppVersus({
    super.key,
    required this.look,
    required this.a,
    required this.b,
  });

  final DeeperLook look;
  final (String, String) a;
  final (String, String)? b;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final AppInk ink = AppInk.of(context, look);
    final (String, String)? other = b;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _AppView(
          ink: ink,
          chip: other == null ? l.deeperSideB : l.deeperSideA,
          colour: other == null ? ink.sideB : ink.sideA,
          view: a,
        ),
        if (other != null) ...[
          const SizedBox(height: 8),
          _AppView(
            ink: ink,
            chip: l.deeperSideB,
            colour: ink.sideB,
            view: other,
          ),
        ],
      ],
    );
  }
}

class _AppView extends StatelessWidget {
  const _AppView({
    required this.ink,
    required this.chip,
    required this.colour,
    required this.view,
  });

  final AppInk ink;
  final String chip;
  final Color colour;
  final (String, String) view;

  @override
  Widget build(BuildContext context) {
    final Palette p = context.p;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ink.inset,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 15, 16, 17),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (chip != view.$1) ...[
              ExcludeSemantics(
                child: Text(
                  chip.toUpperCase(),
                  style: AppText.label(
                    size: 10.5,
                    spacing: 1.3,
                    color: p.inkFaint,
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            Semantics(
              header: true,
              child: Text(
                view.$1,
                style: AppText.body(
                  size: 16,
                  weight: FontWeight.w600,
                  height: 1.32,
                  color: p.ink,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              view.$2,
              style: AppText.body(
                size: 15,
                height: 1.55,
                color: p.ink.withValues(alpha: p.isDark ? 0.82 : 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A small tinted pill, as the profile marks Astute+.
class AppChip extends StatelessWidget {
  const AppChip({
    super.key,
    required this.label,
    required this.colour,
    this.icon,
  });

  final String label;
  final Color colour;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: colour.withValues(alpha: context.p.isDark ? 0.16 : 0.12),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon case final IconData i) ...[
          Icon(i, size: 12, color: colour),
          const SizedBox(width: 5),
        ],
        Flexible(
          child: Text(
            label,
            style: AppText.body(
              size: 12.5,
              weight: FontWeight.w600,
              height: 1.2,
              color: colour,
            ),
          ),
        ),
      ],
    ),
  );
}

/// Astute+, beside a part's name on the free plan: the profile's chip.
class AppPlusBadge extends StatelessWidget {
  const AppPlusBadge({super.key});

  @override
  Widget build(BuildContext context) => AppChip(
    label: 'ASTUTE+',
    colour: context.p.link,
    icon: Icons.lock_rounded,
  );
}

/// The button that asks Claude: the app's own pill, its ink reversed, as
/// the tab bar marks where the reader is. While the answer comes it steps
/// back to a quiet pill and a small ring turns slowly beside its words.
class AppAskButton extends StatefulWidget {
  const AppAskButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.locked = false,
    this.busy = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool locked;
  final bool busy;

  @override
  State<AppAskButton> createState() => _AppAskButtonState();
}

class _AppAskButtonState extends State<AppAskButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final Palette p = context.p;
    final bool busy = widget.busy;
    final bool on = widget.onPressed != null && !busy;
    final bool still = deeperStill(context);
    final Duration calm = still
        ? Duration.zero
        : const Duration(milliseconds: 280);
    final bool dark = p.isDark;
    // Asking, the pill is the app's reversed ink, a touch of depth from
    // its top to its foot, a hairline of light round it and a soft shadow;
    // waiting or off, it is frosted glass like the cards, its ink stepped
    // back.
    final Color fill = on
        ? p.inverse
        : dark
        ? Colors.white.withValues(alpha: 0.07)
        : Colors.black.withValues(alpha: 0.045);
    final Color ink = on
        ? p.onInverse
        : busy
        ? p.inkMuted
        : p.inkFaint;
    final Widget mark = busy
        ? SizedBox(
            key: const ValueKey('busy'),
            width: 15,
            height: 15,
            child: still
                ? Icon(Icons.more_horiz_rounded, size: 15, color: ink)
                : CircularProgressIndicator(
                    strokeWidth: 1.6,
                    color: ink,
                    backgroundColor: ink.withValues(alpha: 0.18),
                  ),
          )
        : Icon(
            widget.locked ? Icons.lock_rounded : Icons.auto_awesome_rounded,
            key: const ValueKey('idle'),
            size: 16,
            color: ink,
          );
    return Semantics(
      button: true,
      enabled: on,
      liveRegion: busy,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: on ? (_) => setState(() => _down = true) : null,
        onTapUp: on ? (_) => setState(() => _down = false) : null,
        onTapCancel: on ? () => setState(() => _down = false) : null,
        onTap: on
            ? () {
                HapticFeedback.lightImpact();
                widget.onPressed!();
              }
            : null,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 120),
          scale: _down && on ? 0.97 : 1,
          child: AnimatedContainer(
            duration: calm,
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.fromLTRB(18, 13, 22, 13),
            decoration: BoxDecoration(
              color: fill,
              gradient: on
                  ? LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color.lerp(p.inverse, Colors.white, dark ? 0.35 : 0.1)!,
                        Color.lerp(p.inverse, p.onInverse, dark ? 0.1 : 0.0)!,
                      ],
                    )
                  : null,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: on
                    ? (dark ? const Color(0x66FFFFFF) : const Color(0x33FFFFFF))
                    : (dark
                          ? const Color(0x1AFFFFFF)
                          : const Color(0x0F000000)),
                width: 0.8,
              ),
              boxShadow: on
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: dark ? 0.35 : 0.16,
                        ),
                        blurRadius: 14,
                        spreadRadius: -4,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSwitcher(duration: calm, child: mark),
                const SizedBox(width: 10),
                Flexible(
                  child: AnimatedSwitcher(
                    duration: calm,
                    child: Text(
                      busy ? context.l10n.deeperBusy : widget.label,
                      key: ValueKey(busy),
                      style: AppText.body(
                        size: 15,
                        weight: FontWeight.w600,
                        height: 1.25,
                        color: ink,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The reader's own words, at the right on an inset, as a sent message is
/// in the app's quiet colours.
class AppReaderBubble extends StatelessWidget {
  const AppReaderBubble({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final Palette p = context.p;
    return Align(
      alignment: AlignmentDirectional.centerEnd,
      child: FractionallySizedBox(
        widthFactor: 0.86,
        alignment: AlignmentDirectional.centerEnd,
        child: Align(
          alignment: AlignmentDirectional.centerEnd,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: p.isDark ? const Color(0xFF1E1E22) : p.surface,
              borderRadius: const BorderRadiusDirectional.only(
                topStart: Radius.circular(18),
                topEnd: Radius.circular(18),
                bottomStart: Radius.circular(18),
                bottomEnd: Radius.circular(6),
              ).resolve(Directionality.of(context)),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(15, 11, 15, 12),
              child: Text(
                text,
                style: AppText.body(
                  size: 15,
                  weight: FontWeight.w500,
                  height: 1.45,
                  color: p.ink,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The foot of the sheet: the source under the app's eyebrow, and the way
/// to the original as a quiet pill.
class AppSource extends StatelessWidget {
  const AppSource({
    super.key,
    required this.look,
    required this.source,
    required this.kind,
    required this.open,
    this.watchBy,
    this.watch,
  });

  final DeeperLook look;
  final String source;
  final String? kind;
  final VoidCallback? open;

  /// Who made the video the card's story is told in at more length, and
  /// where; with [watch], which opens it. Both null where there is none.
  final String? watchBy;
  final VoidCallback? watch;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final Palette p = context.p;
    final String eyebrow = [
      l.deeperSource,
      if (kind case final String k) k,
    ].join('  ·  ').toUpperCase();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            eyebrow,
            style: AppText.label(size: 11, spacing: 1.3, color: p.inkFaint),
          ),
          const SizedBox(height: 10),
          Text(
            source,
            style: AppText.display(
              size: 17,
              weight: FontWeight.w500,
              height: 1.38,
              spacing: -0.15,
              color: p.ink,
            ),
          ),
          if (open case final VoidCallback go) ...[
            const SizedBox(height: 16),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Semantics(
                button: true,
                link: true,
                child: GestureDetector(
                  key: const ValueKey('deeper-open-source'),
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    go();
                  },
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(18, 11, 16, 11),
                    decoration: BoxDecoration(
                      color: p.surfaceRaised,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: p.line),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            l.deeperOpenSource,
                            style: AppText.body(
                              size: 14.5,
                              weight: FontWeight.w600,
                              color: p.ink,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.arrow_outward_rounded,
                          size: 17,
                          color: p.inkMuted,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
          if (watch case final VoidCallback see) ...[
            SizedBox(height: open == null ? 14 : 10),
            DeeperWatch(
              by: watchBy,
              onTap: see,
              ink: p.ink,
              muted: p.inkMuted,
            ),
          ],
        ],
      ),
    );
  }
}

/// Watch more, under a card's source: the video its story is told in at
/// more length, named with who made it. Quieter than the source's own way
/// out, since the source is what the card stands on and the video is extra.
class DeeperWatch extends StatelessWidget {
  const DeeperWatch({
    super.key,
    required this.by,
    required this.onTap,
    required this.ink,
    required this.muted,
  });

  final String? by;
  final VoidCallback onTap;
  final Color ink;
  final Color muted;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Semantics(
        button: true,
        link: true,
        child: GestureDetector(
          key: const ValueKey('deeper-watch'),
          behavior: HitTestBehavior.opaque,
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.play_circle_outline_rounded, size: 19, color: muted),
                const SizedBox(width: 8),
                Flexible(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: l.deeperWatchMore,
                          style: AppText.body(
                            size: 14.5,
                            weight: FontWeight.w600,
                            color: ink,
                          ),
                        ),
                        if (by case final String who)
                          TextSpan(
                            text: '  ·  $who',
                            style: AppText.body(size: 13.5, color: muted),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Icon(Icons.arrow_outward_rounded, size: 15, color: muted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
