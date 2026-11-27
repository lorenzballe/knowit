/// The way back of a page that scrolls whole, as Instagram keeps its own:
/// part of the page, not pinned over it.
///
/// - Going down, the way back and the small header it stands in go up and
///   away with the page, point for point, so the page is all content.
/// - Coming back up, even a little, they come straight back over the page,
///   softly, wherever the reader is, with the page's colour laid behind
///   them and fading out under them, as iOS 26 fades a page under its bar:
///   nothing runs through the ring or under the words beside it.
/// - At the top they stand where they always stood, with nothing behind.
///
/// For whoever asked for less motion nothing slides: the way back fades out
/// where it stands, and back in. With a screen reader on it stays where it
/// is, always there to be found.
///
/// It reads the page's own scrolling, not a row inside it that scrolls
/// sideways, and takes no touch of its own: the swipe back from the edge of
/// the screen is the route's, and goes on working whatever the way back is
/// doing. What has to stay, a button at the foot, stays outside it.
///
/// On iOS 26 the way back is Apple's own glass, a native view, which is
/// drawn away from its place inside a scrolling list. Here it is never in
/// one: it stands over the page and is only moved up out of sight and back.
library;

import 'dart:math' as math;

import 'package:flutter/rendering.dart' show RenderProxyBox;
import 'package:flutter/widgets.dart';

import '../theme.dart';

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
  /// of the screen itself.
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

  /// How far past its own foot the header still has something to show: the
  /// page's colour fading out under it, and a glass ring's shadow.
  static const double shade = 24;

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

  /// How tall the header was laid out, kept as it is laid out: the page
  /// tells of its scrolling while it is being laid out itself, when the
  /// header's own size may not be asked for.
  final _HeaderHeight _headerHeight = _HeaderHeight();

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

  /// How far up the header goes to be out of sight: its own height and
  /// whatever it shows under it.
  double get _gone {
    final double? height = _headerHeight.value;
    return height == null ? 0 : height + QuickReturn.shade;
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

  @override
  Widget build(BuildContext context) {
    _still = MediaQuery.disableAnimationsOf(context);
    _stays = MediaQuery.accessibleNavigationOf(context);
    // The page's own colour, light or dark as the page is.
    final Color ground = context.p.surface;
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
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          child: AnimatedBuilder(
            animation: Listenable.merge([_up, _scrolled]),
            child: _KeepHeight(keep: _headerHeight, child: widget.header),
            builder: (context, header) {
              final double gone = _gone;
              final double up = _stays ? 0 : _up.value;
              // Where it stands: in its place, or as far up as it is.
              final double at = _still ? 0 : up;
              // The page's colour behind it, as much as the page has run
              // under it: none while it stands in its own place, whole once
              // it is back over the page.
              final Widget shown = Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 0,
                    bottom: -(QuickReturn.shade - 4),
                    child: IgnorePointer(
                      child: Opacity(
                        key: const ValueKey('quick-return-ground'),
                        opacity: ((_scrolled.value - at) / 24).clamp(0.0, 1.0),
                        child: _Ground(color: ground),
                      ),
                    ),
                  ),
                  header!,
                ],
              );
              final bool away = gone > 0 && up >= gone / 2;
              if (_still) {
                return IgnorePointer(
                  ignoring: away,
                  child: AnimatedOpacity(
                    key: const ValueKey('quick-return-fade'),
                    opacity: away ? 0 : 1,
                    duration: QuickReturn.fade,
                    curve: Curves.easeOut,
                    child: shown,
                  ),
                );
              }
              // Gone into the last of its shade: faded with it, and not
              // drawn at all once out of sight.
              final double seen = gone <= 0
                  ? 1
                  : ((gone - up) / QuickReturn.shade).clamp(0.0, 1.0);
              return IgnorePointer(
                ignoring: seen < 1,
                child: Transform.translate(
                  offset: Offset(0, -at),
                  child: Opacity(opacity: seen, child: shown),
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

/// Where the header's height is kept.
class _HeaderHeight {
  double? value;
}

/// Keeps its child's height in [keep] each time the child is laid out.
class _KeepHeight extends SingleChildRenderObjectWidget {
  const _KeepHeight({required this.keep, super.child});

  final _HeaderHeight keep;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderKeepHeight(keep);

  @override
  void updateRenderObject(BuildContext context, _RenderKeepHeight render) =>
      render.keep = keep;
}

class _RenderKeepHeight extends RenderProxyBox {
  _RenderKeepHeight(this.keep);

  _HeaderHeight keep;

  @override
  void performLayout() {
    super.performLayout();
    keep.value = size.height;
  }
}

/// The page's colour behind the header: whole behind the way back, so
/// nothing runs through its ring, then gone a little under it.
class _Ground extends StatelessWidget {
  const _Ground({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final double h = math.max(box.maxHeight, 1);
      return DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              color,
              color,
              color.withValues(alpha: 0.7),
              color.withValues(alpha: 0),
            ],
            stops: [
              0,
              ((h - 28) / h).clamp(0.0, 1.0),
              ((h - 14) / h).clamp(0.0, 1.0),
              1,
            ],
          ),
        ),
      );
    },
  );
}
