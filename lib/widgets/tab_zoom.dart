/// Today, opening out of the tile on the profile that was tapped for it.
///
/// The tabs are pages side by side and Today is two away from the profile,
/// so a slide would haul Explore across the glass on its way; the shell cut
/// instead, and the reader landed on Today with nothing to say how. This is
/// the move a card on the App Store makes into its story: the tile grows
/// into the screen with Today inside it, Today's own head where the tile's
/// was, while the profile settles back behind it and dims — and the tab
/// bar's light travels to Today at the same time (the shell's).
///
/// The profile is a picture for the length of the move
/// ([RenderRepaintBoundary.toImageSync]): Today is already the page, from
/// the first frame, so nothing is built twice and nothing is reparented. A
/// phone that asked for less motion gets a dissolve instead, and anything
/// that cannot be pictured is simply cut, as before.
library;

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../theme.dart';

class TabZoom extends StatefulWidget {
  const TabZoom({super.key, required this.child});

  /// The pages.
  final Widget child;

  /// How long Today takes to open out of the tile.
  static const Duration open = Duration(milliseconds: 500);

  /// How long the dissolve takes, for less motion.
  static const Duration dissolve = Duration(milliseconds: 200);

  @override
  State<TabZoom> createState() => TabZoomState();
}

class TabZoomState extends State<TabZoom> with SingleTickerProviderStateMixin {
  /// The pages as they are painted, to be pictured.
  final GlobalKey _pages = GlobalKey();

  // Its own length whatever the phone says of animations: under less motion
  // it is a dissolve, which moves nothing, and one that took a twentieth of
  // its time would be the cut again.
  late final AnimationController _t = AnimationController(
    vsync: this,
    animationBehavior: AnimationBehavior.preserve,
  );

  /// The screen as it was when the tile was tapped; null at rest.
  ui.Image? _was;

  /// The tile, in this box's coordinates, and its corners.
  Rect _tile = Rect.zero;
  double _radius = 0;

  /// Pixels to a point in [_was].
  double _ratio = 1;

  /// A dissolve rather than the zoom.
  bool _still = false;

  /// Which move is running, so a move cut short does not end the next one.
  int _run = 0;

  /// Whether a move is under way.
  bool get moving => _was != null;

  @override
  void dispose() {
    _t.dispose();
    _was?.dispose();
    super.dispose();
  }

  /// Pictures the screen, has [swap] change the page under it — in this
  /// frame — and opens the new page out of [tile], a rectangle on the
  /// screen with corners of [radius]. With nothing to picture it only
  /// swaps, and says so.
  bool play({
    required Rect tile,
    required VoidCallback swap,
    double radius = 20,
  }) {
    final RenderObject? box = context.findRenderObject();
    final RenderObject? pages = _pages.currentContext?.findRenderObject();
    ui.Image? picture;
    if (box is RenderBox && box.hasSize && pages is RenderRepaintBoundary) {
      try {
        _ratio = MediaQuery.devicePixelRatioOf(context);
        picture = pages.toImageSync(pixelRatio: _ratio);
      } catch (_) {
        // Not painted yet, or a surface that cannot be read back: the cut.
        picture = null;
      }
    }
    if (picture == null || box is! RenderBox) {
      swap();
      return false;
    }
    _was?.dispose();
    final Offset at = box.globalToLocal(tile.topLeft);
    setState(() {
      _was = picture;
      _tile = at & tile.size;
      _radius = radius;
      _still = MediaQuery.disableAnimationsOf(context);
    });
    swap();
    final int run = ++_run;
    _t.duration = _still ? TabZoom.dissolve : TabZoom.open;
    _t.forward(from: 0).whenCompleteOrCancel(() {
      if (run != _run || !mounted) return;
      setState(() {
        _was?.dispose();
        _was = null;
      });
    });
    return true;
  }

  /// Ends a move under way at once: the reader went on before it landed.
  void finish() {
    if (_was == null) return;
    _run++;
    _t.stop();
    setState(() {
      _was?.dispose();
      _was = null;
    });
  }

  /// How far the tile has grown: it lifts off gently, then opens and
  /// settles slowly into place — Material's emphasized easing, the curve of
  /// a container that becomes a screen.
  static const Curve _grow = Curves.easeInOutCubicEmphasized;

  @override
  Widget build(BuildContext context) {
    final Widget pages = RepaintBoundary(key: _pages, child: widget.child);
    return LayoutBuilder(
      builder: (context, box) => AnimatedBuilder(
        animation: _t,
        child: pages,
        builder: (context, pages) => _frame(context, box.biggest, pages!),
      ),
    );
  }

  /// The same tree at rest and moving — a picture under, the pages in a
  /// frame — so the pages are never taken out and put back.
  Widget _frame(BuildContext context, Size size, Widget pages) {
    final Palette p = context.p;
    final ui.Image? was = _was;
    final double t = was == null ? 1 : _t.value;
    final Rect full = Offset.zero & size;

    // At rest, and in a dissolve: the pages where they always are.
    Rect frame = full;
    double radius = 0;
    Matrix4 place = Matrix4.identity();
    double shown = 1;
    Color ground = Colors.transparent;
    _Picture? under;
    _Picture? ghost;

    if (was != null && _still) {
      shown = Curves.easeOut.transform(t);
      under = _Picture(image: was, ratio: _ratio, opacity: 1 - shown);
    } else if (was != null) {
      final double g = _grow.transform(t);
      frame = Rect.lerp(_tile, full, g)!;
      radius = ui.lerpDouble(_radius, 0, g)!;
      // Today at the frame's width, its head — under the status bar — set
      // where the tile's own head was, and the whole page by the end.
      final double s = frame.width / size.width;
      final double head = MediaQuery.paddingOf(context).top;
      final double dy = frame.top + (14 - s * head) * (1 - g);
      place = Matrix4.identity()
        ..translateByDouble(frame.left, dy, 0, 1)
        ..scaleByDouble(s, s, 1, 1);
      // The tile's own words leave before Today's arrive, so the two are
      // never read on top of each other: between them, for a moment, the
      // frame is only its ground.
      shown = const Interval(0.2, 0.6, curve: Curves.easeOut).transform(t);
      ground = Color.lerp(
        p.surfaceRaised,
        p.surface,
        const Interval(0.1, 0.5).transform(t),
      )!;
      under = _Picture(
        image: was,
        ratio: _ratio,
        // The profile settles back towards the tile and dims behind it.
        scale: 1 - 0.06 * g,
        anchor: _tile.center,
        // Less on paper, where a dark veil reads as dirt rather than depth.
        scrim: (p.isDark ? 0.55 : 0.18) * g,
        ground: p.surface,
      );
      // The tile itself, from the picture, for the first few frames, at the
      // frame's width.
      final double w = frame.width / _tile.width;
      ghost = _Picture(
        image: was,
        ratio: _ratio,
        from: _tile,
        to: Rect.fromLTWH(
          frame.left,
          frame.top,
          _tile.width * w,
          _tile.height * w,
        ),
        opacity: 1 - const Interval(0, 0.2, curve: Curves.easeIn).transform(t),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        IgnorePointer(child: CustomPaint(painter: under)),
        ClipPath(
          clipper: _Rounded(frame, radius),
          clipBehavior: was != null && !_still ? Clip.antiAlias : Clip.none,
          child: Stack(
            fit: StackFit.expand,
            children: [
              IgnorePointer(child: ColoredBox(color: ground)),
              Transform(
                transform: place,
                child: Opacity(opacity: shown, child: pages),
              ),
              IgnorePointer(child: CustomPaint(painter: ghost)),
            ],
          ),
        ),
      ],
    );
  }
}

/// The frame Today grows in.
class _Rounded extends CustomClipper<Path> {
  const _Rounded(this.rect, this.radius);

  final Rect rect;
  final double radius;

  @override
  Path getClip(Size size) =>
      Path()..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)));

  @override
  bool shouldReclip(_Rounded old) => old.rect != rect || old.radius != radius;
}

/// The picture of the screen as it was: whole, behind, or a part of it —
/// the tile — drawn from [from] into [to].
class _Picture extends CustomPainter {
  const _Picture({
    required this.image,
    required this.ratio,
    this.opacity = 1,
    this.scale = 1,
    this.anchor = Offset.zero,
    this.scrim = 0,
    this.ground,
    this.from,
    this.to,
  });

  final ui.Image image;
  final double ratio;
  final double opacity;
  final double scale;
  final Offset anchor;
  final double scrim;
  final Color? ground;
  final Rect? from;
  final Rect? to;

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity <= 0) return;
    final Paint paint = Paint()
      ..filterQuality = FilterQuality.medium
      ..color = Color.fromRGBO(0, 0, 0, opacity);
    final Rect? part = from;
    if (part != null && to != null) {
      canvas.drawImageRect(
        image,
        Rect.fromLTRB(
          part.left * ratio,
          part.top * ratio,
          part.right * ratio,
          part.bottom * ratio,
        ),
        to!,
        paint,
      );
      return;
    }
    final Rect all = Offset.zero & size;
    if (ground != null) canvas.drawRect(all, Paint()..color = ground!);
    canvas.save();
    canvas.translate(anchor.dx, anchor.dy);
    canvas.scale(scale);
    canvas.translate(-anchor.dx, -anchor.dy);
    canvas.drawImageRect(
      image,
      Offset.zero & Size(image.width.toDouble(), image.height.toDouble()),
      all,
      paint,
    );
    canvas.restore();
    if (scrim > 0) {
      canvas.drawRect(all, Paint()..color = Color.fromRGBO(0, 0, 0, scrim));
    }
  }

  @override
  bool shouldRepaint(_Picture old) =>
      old.image != image ||
      old.opacity != opacity ||
      old.scale != scale ||
      old.anchor != anchor ||
      old.scrim != scrim ||
      old.ground != ground ||
      old.from != from ||
      old.to != to;
}
