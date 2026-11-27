import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/widgets.dart';

import '../theme.dart';

/// The top edge of a page that runs on under the status bar, and under what
/// stands over its top: what passes under it is blurred, strongest at the
/// top of the screen and thinning to nothing at the foot, with the page's
/// colour over it, nearly whole at the edge of the screen and gone at the
/// foot. The page goes soft and dissolves into its own colour rather than
/// being cut by a line, as iOS 26 draws a list under its bar: it is never a
/// band of colour, and what is under it always shows through.
///
/// At rest it is the status bar's room ([rest]) and no more: Explore's
/// shelves, and every long page at its top. Where a way back has come back
/// over the page ([QuickReturn]) the edge reaches further down, past the
/// foot of what stands there, as deep as its box, and the way back stands
/// on it; [strength] says how much of that deeper edge shows, growing out
/// of the edge at rest. One look for the whole app.
///
/// The blur is laid in thin slices, each blurring the page itself rather
/// than the slice above it, by a little less than the one before: close
/// enough that no seam shows, and one picture of the page serves them all.
class TopEdge extends StatelessWidget {
  const TopEdge({
    super.key,
    required this.ground,
    this.rest,
    this.strength = 0,
  });

  /// The page's colour.
  final Color ground;

  /// How deep the edge is at rest, from the top of its box: the status
  /// bar's room. Null for the whole box, always.
  final double? rest;

  /// How much of the deeper edge, the whole box, shows: 0 the edge at rest,
  /// 1 all of it.
  final double strength;

  /// The edge at rest, from the top of the screen down: how soft each of
  /// its eight slices is.
  static const List<double> sigmas = [9, 7.5, 6, 4.6, 3.4, 2.4, 1.5, 0.8];

  /// The most of the page's colour, at the very top.
  static const double most = 0.9;

  /// How tall a slice of the deeper edge is, at most.
  static const double slice = 8;

  /// No slice softer than this is laid: it would not be seen.
  static const double _faint = 0.3;

  /// The page's colour over the page down the edge at rest, as a share of
  /// [most], at each share of the way down: whole at the top, a little more
  /// than half at 45%, a fifth at 75%, none at the foot.
  static const List<(double, double)> cover = [
    (0, 1),
    (0.45, 0.55 / most),
    (0.75, 0.18 / most),
    (1, 0),
  ];

  /// How soft the page is down the edge at rest, at each share of the way
  /// down: through the middle of each of its slices.
  static const List<(double, double)> soft = [
    (0, 9.75),
    (1 / 16, 9),
    (3 / 16, 7.5),
    (5 / 16, 6),
    (7 / 16, 4.6),
    (9 / 16, 3.4),
    (11 / 16, 2.4),
    (13 / 16, 1.5),
    (15 / 16, 0.8),
    (1, 0.45),
  ];

  /// The page's colour over the page down the deeper edge, a way back
  /// standing on it, as a share of [most]: still most of it at the status
  /// bar's foot, about a third of the way down; more than half at the middle
  /// of the way back, so that it and the words beside it are read on the
  /// page and not over it; a third at its foot, three quarters of the way
  /// down; and from there thinning to nothing, past it.
  static const List<(double, double)> coverDeeper = [
    (0, 1),
    (0.37, 0.8),
    (0.575, 0.61),
    (0.78, 0.33),
    (1, 0),
  ];

  /// How soft the page is down the deeper edge: as soft as under the status
  /// bar at its top, still soft behind the way back, and a breath at the
  /// foot.
  static const List<(double, double)> softDeeper = [
    (0, 9.75),
    (0.37, 6.4),
    (0.575, 4.6),
    (0.78, 2.4),
    (0.9, 1.2),
    (1, 0.45),
  ];

  /// The line through [points], (share of the way down, value), at [t] of
  /// the way down: nothing past the foot.
  static double along(List<(double, double)> points, double t) {
    if (t.isNaN || t > 1) return 0;
    if (t <= 0) return points.first.$2;
    for (int i = 1; i < points.length; i++) {
      final (double x1, double y1) = points[i];
      if (t <= x1) {
        final (double x0, double y0) = points[i - 1];
        return y0 + (y1 - y0) * (t - x0) / (x1 - x0);
      }
    }
    return points.last.$2;
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final double whole = box.maxHeight;
      final double atRest = math.min(rest ?? whole, whole);
      final double grown = atRest >= whole ? 0 : strength.clamp(0.0, 1.0);
      // Nothing to draw: no backdrop is read for it.
      if (grown == 0 && atRest <= 0) return const SizedBox.shrink();
      if (grown == 0) {
        return Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: double.infinity,
            height: atRest,
            child: _AtRest(ground: ground),
          ),
        );
      }
      return _Deeper(
        ground: ground,
        rest: atRest,
        whole: whole,
        strength: grown,
      );
    },
  );
}

/// The edge at rest, the status bar's room: eight slices, and the page's
/// colour over them.
class _AtRest extends StatelessWidget {
  const _AtRest({required this.ground});

  final Color ground;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      BackdropGroup(
        child: Column(
          children: [
            for (final double sigma in TopEdge.sigmas)
              Expanded(
                child: ClipRect(
                  child: BackdropFilter.grouped(
                    filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
          ],
        ),
      ),
      // The page's own colour over the blur, nearly whole at the edge of
      // the screen and gone at the foot: what passes under the time
      // dissolves into the page rather than being cut by a line.
      DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              ground.withValues(alpha: TopEdge.most),
              ground.withValues(alpha: 0.55),
              ground.withValues(alpha: 0.18),
              ground.withValues(alpha: 0),
            ],
            stops: const [0, 0.45, 0.75, 1],
          ),
        ),
      ),
    ],
  );
}

/// The edge grown deeper than its rest, as deep as [whole], by [strength]:
/// at each depth the blur and the colour of the edge at rest, moved by
/// [strength] towards those of an edge as deep as [whole]. The status bar's
/// room keeps its eight slices; below it the slices are [TopEdge.slice]
/// tall at most, and none is laid too faint to be seen.
class _Deeper extends StatelessWidget {
  const _Deeper({
    required this.ground,
    required this.rest,
    required this.whole,
    required this.strength,
  });

  final Color ground;
  final double rest;
  final double whole;
  final double strength;

  /// [atRest] at [y] in the edge at rest, moved by [strength] towards
  /// [deeper] at [y] in the deeper edge.
  double _mix(
    List<(double, double)> atRest,
    List<(double, double)> deeper,
    double y,
  ) {
    final double was = rest > 0 ? TopEdge.along(atRest, y / rest) : 0;
    return was + (TopEdge.along(deeper, y / whole) - was) * strength;
  }

  @override
  Widget build(BuildContext context) {
    final List<(double, double)> slices = [
      for (int i = 0; i < TopEdge.sigmas.length; i++)
        (rest * i / TopEdge.sigmas.length, rest / TopEdge.sigmas.length),
    ];
    final int below = ((whole - rest) / TopEdge.slice).ceil();
    for (int i = 0; i < below; i++) {
      final double tall = (whole - rest) / below;
      slices.add((rest + tall * i, tall));
    }
    // Where the colour turns, in either edge.
    final List<double> turns = {
      for (final (double t, _) in TopEdge.cover) t * rest,
      for (final (double t, _) in TopEdge.coverDeeper) t * whole,
    }.where((y) => y >= 0 && y <= whole).toList()..sort();
    return Stack(
      fit: StackFit.expand,
      children: [
        BackdropGroup(
          child: Stack(
            children: [
              for (final (double top, double tall) in slices)
                if (_mix(TopEdge.soft, TopEdge.softDeeper, top + tall / 2)
                    case final double sigma
                    when sigma >= TopEdge._faint && tall > 0)
                  Positioned(
                    left: 0,
                    right: 0,
                    top: top,
                    height: tall,
                    child: ClipRect(
                      child: BackdropFilter.grouped(
                        filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ),
            ],
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                for (final double y in turns)
                  ground.withValues(
                    alpha:
                        TopEdge.most *
                        _mix(TopEdge.cover, TopEdge.coverDeeper, y),
                  ),
              ],
              stops: [for (final double y in turns) y / whole],
            ),
          ),
        ),
      ],
    );
  }
}

/// A list that scrolls under a bar which stays where it is and does not let
/// it run on under itself: what scrolls up goes soft and dissolves into the
/// page's colour as it comes to the bar, in the look of the edge under the
/// status bar ([TopEdge]), rather than being cut at a line under the bar.
/// It grows in as the list leaves its top; at the top there is nothing to
/// dissolve, and nothing is drawn.
class SoftTop extends StatefulWidget {
  const SoftTop({super.key, required this.child, this.depth = 28});

  /// The list, filling the room.
  final Widget child;

  /// How far down from the top of the list the dissolve reaches.
  final double depth;

  @override
  State<SoftTop> createState() => _SoftTopState();
}

class _SoftTopState extends State<SoftTop> {
  /// How far the list has gone from its top.
  final ValueNotifier<double> _scrolled = ValueNotifier(0);

  @override
  void dispose() {
    _scrolled.dispose();
    super.dispose();
  }

  bool _onMetrics(ScrollMetrics m, int depth) {
    if (depth == 0 && m.axis == Axis.vertical) {
      _scrolled.value = m.pixels - m.minScrollExtent;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.passthrough,
    children: [
      NotificationListener<ScrollMetricsNotification>(
        onNotification: (n) => _onMetrics(n.metrics, n.depth),
        child: NotificationListener<ScrollNotification>(
          onNotification: (n) => _onMetrics(n.metrics, n.depth),
          child: widget.child,
        ),
      ),
      Positioned(
        left: 0,
        right: 0,
        top: 0,
        height: widget.depth,
        child: IgnorePointer(
          child: ValueListenableBuilder<double>(
            valueListenable: _scrolled,
            builder: (context, scrolled, _) => TopEdge(
              key: const ValueKey('soft-top'),
              ground: context.p.surface,
              rest: 0,
              strength: (scrolled / widget.depth).clamp(0.0, 1.0),
            ),
          ),
        ),
      ),
    ],
  );
}

/// A page that runs on under the status bar, as Explore does: [child] fills
/// the screen from its top, with the status bar's room at its own top (the
/// status bar's padding is its to lay out, and is taken from what is under
/// it), and over that room the edge at rest ([TopEdge]), so what scrolls up
/// under the time goes soft and dissolves rather than being cut at a line.
/// At the top the room is the page's own colour, and nothing changes.
class UnderStatusBar extends StatelessWidget {
  const UnderStatusBar({super.key, required this.child});

  /// The page, its top as far down as the status bar's room.
  final Widget child;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    bottom: false,
    child: Stack(
      fit: StackFit.expand,
      children: [
        MediaQuery.removePadding(
          context: context,
          removeTop: true,
          child: child,
        ),
        Positioned(
          key: const ValueKey('under-status-bar-edge'),
          left: 0,
          right: 0,
          top: 0,
          height: MediaQuery.paddingOf(context).top,
          child: IgnorePointer(child: TopEdge(ground: context.p.surface)),
        ),
      ],
    ),
  );
}
