/// The way back of a page that scrolls whole, as Instagram keeps its own:
/// part of the page, not pinned over it.
///
/// - Going down, the way back and the small header it stands in go up and
///   away with the page, point for point, so the page is all content: under
///   the status bar the page goes soft and dissolves into its own colour
///   ([TopEdge]), and the way back fades as it goes under.
/// - Coming back up, even a little, they come straight back over the page,
///   softly, wherever the reader is, and the edge under the status bar
///   comes down with them, past their foot: the page under them goes soft
///   and dark the higher it is, as iOS 26 draws a page under its floating
///   controls. It is never a band of colour: the page always shows through,
///   blurred, and there is no line where it ends.
/// - At the top they stand where they always stood, with nothing behind.
///
/// For whoever asked for less motion nothing slides: the way back fades out
/// where it stands, and back in, and the deeper edge with it. With a screen
/// reader on it stays where it is, always there to be found.
///
/// It reads the page's own scrolling, not a row inside it that scrolls
/// sideways, and takes no touch of its own: the swipe back from the edge of
/// the screen is the route's, and goes on working whatever the way back is
/// doing. What has to stay, a button at the foot, stays outside it.
///
/// On iOS 26 the way back is Apple's own glass, a native view, which iOS
/// lays out in the safe area of wherever it is put on the screen: put there
/// under the status bar, it is drawn a status bar lower than its place, and
/// stays so (inside a scrolling list it is put there again and again). Here
/// it is never in a list: it stands over the page and is only moved up out
/// of sight and back, and out of sight it waits in its own place, unseen,
/// so that it is never put back on the screen under the status bar.
library;

import 'dart:math' as math;

import 'package:flutter/scheduler.dart' show SchedulerBinding, SchedulerPhase;
import 'package:flutter/widgets.dart';

import '../theme.dart';
import 'top_edge.dart';

class QuickReturn extends StatefulWidget {
  const QuickReturn({
    super.key,
    required this.header,
    required this.child,
    this.clip = true,
  });

  /// The way back, and whatever stands beside it, as it stands at the top
  /// of the page: laid across the top of the room, as tall as it is, with
  /// its own room around it.
  final Widget header;

  /// The page: what scrolls, filling the room, with room for [header] at
  /// its top.
  final Widget child;

  /// Whether what goes up past the top of the room is cut there: not for
  /// a page laid under the status bar, whose header goes up past the edge
  /// of the screen itself, and whose top edge, at rest, is the status bar's
  /// room.
  final bool clip;

  /// How far the reader goes back up before the header comes back: a
  /// little, not a twitch of the finger or the page settling at its foot.
  static const double returnAfter = 6;

  /// How long it takes to come back: at once, and softly.
  static const Duration comeBack = Duration(milliseconds: 280);

  /// How long, left part of the way up when the page stops, it takes to go
  /// the rest of the way.
  static const Duration goOn = Duration(milliseconds: 180);

  /// How long, for whoever asked for less motion, it takes to fade.
  static const Duration fade = Duration(milliseconds: 200);

  /// How far past its own foot the header still has something to show: a
  /// glass ring's shadow.
  static const double shade = 24;

  /// How far past the foot of the header the edge under it reaches once it
  /// is back over the page, thinning to nothing there.
  static const double reach = 28;

  /// How much of the header shows while it waits out of sight: nothing to
  /// see, but drawn, so that Apple's glass is never taken off the screen
  /// and put back where iOS would push it down.
  static const double unseen = 1 / 255;

  @override
  State<QuickReturn> createState() => _QuickReturnState();
}

class _QuickReturnState extends State<QuickReturn>
    with SingleTickerProviderStateMixin {
  /// How far the header is up out of its place, in points: 0 in its place,
  /// [_gone] out of sight.
  late final AnimationController _up = AnimationController.unbounded(
    vsync: this,
  );

  /// How far the page has scrolled.
  final ValueNotifier<double> _scrolled = ValueNotifier(0);

  final GlobalKey _header = GlobalKey();

  /// How far the page has gone back up since it last went down.
  double _rising = 0;

  /// Where the header is being taken, while it is.
  double _to = 0;

  /// Whoever asked for less motion, and whoever reads with a screen reader,
  /// as the page was last built.
  bool _still = false;
  bool _stays = false;

  @override
  void dispose() {
    _up.dispose();
    _scrolled.dispose();
    super.dispose();
  }

  /// The last [_gone] read outside a layout.
  double _goneSeen = 0;

  /// How far up the header goes to be out of sight: its own height and
  /// whatever it shows under it. A scroll can start while the page is being
  /// laid out (a page that opens on a place jumps there then), and no size
  /// may be read in the middle of a layout: then it is the last one read.
  double get _gone {
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      return _goneSeen;
    }
    final RenderObject? box = _header.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return _goneSeen;
    return _goneSeen = box.size.height + QuickReturn.shade;
  }

  bool get _returning => _up.isAnimating && _to == 0;

  void _set(double up) {
    if (_up.value != up || _up.isAnimating) _up.value = up;
  }

  void _take(double to, Duration time, Curve curve) {
    if (_still) return _set(to);
    _to = to;
    _up.animateTo(to, duration: time, curve: curve);
  }

  bool _onScroll(ScrollNotification n) {
    if (n.depth != 0 || n.metrics.axis != Axis.vertical) return false;
    final ScrollMetrics m = n.metrics;
    _scrolled.value = m.pixels;
    if (_stays) return false;
    // Never further up than its own place on the page would be: near the
    // top, it goes up with the page as part of it.
    final double cap = m.pixels.clamp(0.0, _gone);
    if (n is ScrollUpdateNotification) {
      final double delta = n.scrollDelta ?? 0;
      final double was = m.pixels - delta;
      if (delta > 0) {
        // The page settling back after it was pulled down past its top.
        if (was < m.minScrollExtent) return false;
        _rising = 0;
        _set(math.min(cap, _up.value + delta));
      } else if (delta < 0) {
        // Coming down with the page wherever it is part of it.
        if (!_returning && _up.value > cap) _set(cap);
        // The page settling back after it was pulled up past its foot: the
        // page coming to rest, not the reader going back up.
        if (was > m.maxScrollExtent) return false;
        _rising -= delta;
        if (_rising >= QuickReturn.returnAfter &&
            _up.value > 0 &&
            !_returning) {
          _take(0, QuickReturn.comeBack, Curves.easeOutCubic);
        }
      }
    } else if (n is ScrollEndNotification) {
      // Left part of the way up when the page stopped: on, out of sight,
      // or to its place on the page near the top; and never left above
      // that place.
      final double up = _up.value;
      if (!_up.isAnimating && up > 0.5 && (up - cap).abs() > 0.5) {
        _take(cap, QuickReturn.goOn, Curves.easeOut);
      }
    }
    return false;
  }

  /// The page grown or shrunk under the header without scrolling.
  bool _onMetrics(ScrollMetricsNotification n) {
    if (n.depth != 0 || n.metrics.axis != Axis.vertical) return false;
    _scrolled.value = n.metrics.pixels;
    final double cap = n.metrics.pixels.clamp(0.0, _gone);
    if (!_stays && !_up.isAnimating && _up.value > cap) _set(cap);
    return false;
  }

  /// How much of the header shows at [at] points up: whole below the
  /// status bar, fading as it goes up under it as the page under the status
  /// bar does ([TopEdge.cover]), and into the last of its shade once out of
  /// sight; never quite nothing while it moves, so Apple's glass is never
  /// taken off the screen on its way. Before it has been measured it stands
  /// in its place, whole.
  double _shownAt(double at, double top, double gone) {
    if (gone <= 0) return 1;
    double shown = ((gone - at) / QuickReturn.shade).clamp(0.0, 1.0);
    if (top > 0) {
      // Its middle, between the status bar's foot and its own.
      final double middle = (top + gone - QuickReturn.shade) / 2 - at;
      shown = math.min(
        shown,
        1 - TopEdge.most * TopEdge.along(TopEdge.cover, middle / top),
      );
    }
    return math.max(shown, QuickReturn.unseen);
  }

  /// The edge under the status bar, and under the header once it is back
  /// over the page: as deep as [deep], grown by [strength] out of the
  /// status bar's room, [top].
  Widget _edge(Color ground, double top, double deep, double strength) =>
      SizedBox(
        height: strength > 0 ? math.max(top, deep) : top,
        child: TopEdge(
          key: const ValueKey('quick-return-edge'),
          ground: ground,
          rest: top,
          strength: strength,
        ),
      );

  @override
  Widget build(BuildContext context) {
    _still = MediaQuery.disableAnimationsOf(context);
    _stays = MediaQuery.accessibleNavigationOf(context);
    // The header measured once each frame is laid out, for a scroll that
    // starts inside the next layout.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _goneSeen = _gone;
    });
    // The page's own colour, light or dark as the page is.
    final Color ground = context.p.surface;
    // The status bar's room, for a page laid under it.
    final double top = widget.clip ? 0 : MediaQuery.paddingOf(context).top;
    final Widget room = Stack(
      fit: StackFit.expand,
      children: [
        NotificationListener<ScrollMetricsNotification>(
          onNotification: _onMetrics,
          child: NotificationListener<ScrollNotification>(
            onNotification: _onScroll,
            child: widget.child,
          ),
        ),
        // Under the header, never over it: the page going soft and dark
        // under the status bar, and under the header once it is back over
        // the page, as deep as its foot and a little more.
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: Listenable.merge([_up, _scrolled]),
              builder: (context, _) {
                final double gone = _gone;
                final double up = _stays ? 0 : _up.value;
                // Where it stands: in its place, or as far up as it is.
                final double at = _still ? 0 : up;
                // As deep as its foot, wherever it is, and a little more.
                final double deep = gone <= 0
                    ? top
                    : gone - QuickReturn.shade - at + QuickReturn.reach;
                // As much as the page has run under it: none while it
                // stands in its own place, all once it is back over the
                // page.
                final double under = ((_scrolled.value - at) / 24).clamp(
                  0.0,
                  1.0,
                );
                if (!_still) return _edge(ground, top, deep, under);
                final bool away = gone > 0 && up >= gone / 2;
                return TweenAnimationBuilder<double>(
                  tween: Tween(end: away ? 0 : 1),
                  duration: QuickReturn.fade,
                  curve: Curves.easeOut,
                  builder: (context, shown, _) =>
                      _edge(ground, top, deep, math.min(under, shown)),
                );
              },
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          child: AnimatedBuilder(
            animation: _up,
            child: KeyedSubtree(key: _header, child: widget.header),
            builder: (context, header) {
              final double gone = _gone;
              final double up = _stays ? 0 : _up.value;
              final bool away = gone > 0 && up >= gone / 2;
              if (_still) {
                return IgnorePointer(
                  ignoring: away,
                  child: AnimatedOpacity(
                    key: const ValueKey('quick-return-fade'),
                    opacity: away ? 0 : 1,
                    duration: QuickReturn.fade,
                    curve: Curves.easeOut,
                    child: header,
                  ),
                );
              }
              // Out of sight it waits in its own place, unseen, to be
              // moved from there when it comes back.
              final bool waits = gone > 0 && up >= gone;
              final double at = waits ? 0 : up;
              final double shown = waits
                  ? QuickReturn.unseen
                  : _shownAt(at, top, gone);
              return IgnorePointer(
                ignoring: shown < 0.5,
                child: ExcludeSemantics(
                  excluding: waits,
                  child: Transform.translate(
                    offset: Offset(0, -at),
                    child: Opacity(
                      key: const ValueKey('quick-return-header'),
                      opacity: shown,
                      child: header,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
    return widget.clip ? ClipRect(child: room) : room;
  }
}
