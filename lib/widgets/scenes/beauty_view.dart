import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' show PointMode;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../../models/scene.dart';
import '../../theme.dart';

/// Plays a [BeautyScene]: a living drawing, the rule under it, one way in.
///
/// The drawing takes every point the card can spare. Under it, for a piece
/// with a dial, the dial's value in big figures and a scale with the true
/// value marked; then the rule; then a line that first says what the hand
/// can do and, once it has, what the touch showed.
///
/// The drawing runs on one ticker, which stops on its own when nothing is
/// looking: the ticker obeys [TickerMode], and a drawing that has not been
/// painted for a few frames (a card waiting unseen in the deck, faded to
/// nothing) puts it to sleep until it is painted again. With motion off the
/// drawing is a still frame, chosen to be a good one, and the hand still
/// changes it.
class BeautySceneView extends StatefulWidget {
  final BeautyScene scene;
  final Color ink;
  final Color ground;
  const BeautySceneView({
    super.key,
    required this.scene,
    required this.ink,
    required this.ground,
  });

  @override
  State<BeautySceneView> createState() => _BeautySceneViewState();
}

class _BeautySceneViewState extends State<BeautySceneView>
    with SingleTickerProviderStateMixin {
  late _World _world = _World.of(widget.scene);
  late final Ticker _ticker = createTicker(_tick);
  final _Clock _clock = _Clock();

  late double _value = widget.scene.dial?.value ?? 0;
  bool _played = false;

  /// Frames ticked, and the frame the drawing was last painted on: when
  /// the two drift apart the drawing is not being shown, and the ticker
  /// sleeps until it is.
  int _ticks = 0;
  int _paintedAt = 0;
  bool _asleep = false;
  Duration _last = Duration.zero;

  /// The width of the drawing at the last layout, for the dial's drag.
  double _width = 1;

  bool get _calm => MediaQuery.disableAnimationsOf(context);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _world.calm = _calm;
    _world.value = _value;
    if (_calm) {
      _ticker.stop();
      _clock.tick();
    } else if (!_ticker.isActive && !_asleep) {
      _last = Duration.zero;
      _ticker.start();
    }
  }

  @override
  void didUpdateWidget(BeautySceneView old) {
    super.didUpdateWidget(old);
    if (!identical(old.scene, widget.scene)) {
      _world = _World.of(widget.scene)..calm = _calm;
      _value = widget.scene.dial?.value ?? 0;
      _world.value = _value;
      _played = false;
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _clock.dispose();
    super.dispose();
  }

  void _tick(Duration elapsed) {
    final dt = _last == Duration.zero
        ? 1 / 60
        : ((elapsed - _last).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _last = elapsed;
    _world.step(dt);
    _ticks++;
    if (_ticks - _paintedAt > 3) {
      // Unseen: stop asking for frames, but leave the drawing marked for
      // paint, so the first time it is painted again it wakes.
      _asleep = true;
      _ticker.stop();
    }
    _clock.tick();
  }

  void _painted() {
    _paintedAt = _ticks;
    if (!_asleep) return;
    _asleep = false;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _calm || _ticker.isActive) return;
      _last = Duration.zero;
      _ticker.start();
    });
  }

  void _play() {
    if (!_played) setState(() => _played = true);
  }

  // ---- the hand ----------------------------------------------------------

  void _down(Offset p) {
    _play();
    if (widget.scene.dial != null) return;
    HapticFeedback.lightImpact();
    _world.touch(p, first: true);
    _clock.tick();
  }

  void _move(DragUpdateDetails d) {
    if (widget.scene.dial != null) {
      _turnTo(_value + d.delta.dx / _width * _span * 0.6);
    } else {
      _world.touch(d.localPosition, first: false);
      _clock.tick();
    }
  }

  void _up() {
    final dial = widget.scene.dial;
    if (dial != null) {
      // A gentle click into the true value when the hand lets go near it.
      if ((_value - dial.value).abs() < _span * 0.015 && _value != dial.value) {
        _turnTo(dial.value);
      }
      return;
    }
    _world.release();
    _clock.tick();
  }

  double get _span {
    final d = widget.scene.dial!;
    return d.to - d.from;
  }

  void _turnTo(double v) {
    final dial = widget.scene.dial!;
    final next = dial.clamp(v);
    if (next == _value) return;
    // The truth is a detent: the phone clicks as the dial passes it.
    if ((_value < dial.value) != (next < dial.value) ||
        next == dial.value) {
      HapticFeedback.selectionClick();
    }
    _play();
    setState(() => _value = next);
    _world.value = next;
    _clock.tick();
  }

  /// The screen reader's way in to a touched piece: the flock gets a
  /// falcon through its middle, the waves' sources move apart or together.
  void _act(double by) {
    _play();
    _world.nudge(by);
    _clock.tick();
  }

  // ---- the page ----------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final s = widget.scene;
    final ink = widget.ink;
    final look = _Look.of(ink, widget.ground, s.accent);
    final dial = s.dial;

    return LayoutBuilder(
      builder: (context, box) {
        final compact = box.maxHeight < 300;
        _width = math.max(1, box.maxWidth);
        final line = _played && s.reveal.isNotEmpty ? s.reveal : s.hint;

        final drawing = RepaintBoundary(
          child: CustomPaint(
            size: Size.infinite,
            isComplex: true,
            willChange: !_calm,
            painter: _Painter(
              world: _world,
              look: look,
              value: _value,
              onPainted: _painted,
              clock: _clock,
            ),
          ),
        );

        // Every touch on the drawing is the drawing's, from the moment the
        // finger lands: not a swipe of the deck, a flip or a keep.
        final hand = RawGestureDetector(
          behavior: HitTestBehavior.opaque,
          gestures: {
            _EagerPan: GestureRecognizerFactoryWithHandlers<_EagerPan>(
              _EagerPan.new,
              (r) => r
                ..dragStartBehavior = DragStartBehavior.down
                ..onDown = ((d) => _down(d.localPosition))
                ..onUpdate = _move
                ..onEnd = ((_) => _up())
                ..onCancel = _up,
            ),
          },
          child: drawing,
        );

        final Widget art;
        if (dial != null) {
          final step = _span / 20;
          art = Semantics(
            slider: true,
            label: dial.label,
            value: dial.format(_value),
            increasedValue: dial.format(dial.clamp(_value + step)),
            decreasedValue: dial.format(dial.clamp(_value - step)),
            onIncrease: () => _turnTo(_value + step),
            onDecrease: () => _turnTo(_value - step),
            child: ExcludeSemantics(child: hand),
          );
        } else if (s.piece == BeautyPiece.flock) {
          art = Semantics(
            button: true,
            label: s.hint,
            onTap: () => _act(1),
            child: ExcludeSemantics(child: hand),
          );
        } else {
          art = Semantics(
            slider: true,
            label: s.hint,
            value: '${(_world.spread * 100).round()}%',
            increasedValue: '${(_world.spread * 100).round() + 4}%',
            decreasedValue: '${math.max(0, (_world.spread * 100).round() - 4)}%',
            onIncrease: () => _act(1),
            onDecrease: () => _act(-1),
            child: ExcludeSemantics(child: hand),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: art),
            SizedBox(height: compact ? 6 : 12),
            if (dial != null) ...[
              ExcludeSemantics(
                child: _Readout(
                  dial: dial,
                  value: _value,
                  ink: ink,
                  size: compact ? 24 : 32,
                ),
              ),
              SizedBox(height: compact ? 2 : 4),
              ExcludeSemantics(
                child: RawGestureDetector(
                  behavior: HitTestBehavior.opaque,
                  gestures: {
                    _EagerPan: GestureRecognizerFactoryWithHandlers<_EagerPan>(
                      _EagerPan.new,
                      (r) => r
                        ..dragStartBehavior = DragStartBehavior.down
                        ..onDown = ((d) => _scaleTo(d.localPosition.dx))
                        ..onUpdate = ((d) => _scaleTo(d.localPosition.dx))
                        ..onEnd = ((_) => _up())
                        ..onCancel = _up,
                    ),
                  },
                  child: SizedBox(
                    height: compact ? 24 : 30,
                    width: double.infinity,
                    child: CustomPaint(
                      painter: _ScalePainter(
                        from: dial.from,
                        to: dial.to,
                        truth: dial.value,
                        now: _value,
                        look: look,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: compact ? 4 : 8),
            ],
            Text(
              s.caption,
              maxLines: compact ? 2 : 3,
              overflow: TextOverflow.ellipsis,
              style: AppText.body(
                size: compact ? 13.5 : 15,
                weight: FontWeight.w600,
                height: 1.3,
                color: ink.withValues(alpha: 0.95),
              ),
            ),
            SizedBox(height: compact ? 2 : 5),
            AnimatedSwitcher(
              duration: Duration(milliseconds: _calm ? 0 : 300),
              transitionBuilder: (child, a) => FadeTransition(
                opacity: a,
                child: SlideTransition(
                  position: Tween(
                    begin: const Offset(0, .3),
                    end: Offset.zero,
                  ).animate(a),
                  child: child,
                ),
              ),
              layoutBuilder: (current, previous) => Stack(
                alignment: Alignment.topLeft,
                children: [...previous, ?current],
              ),
              child: Semantics(
                key: ValueKey(line),
                liveRegion: _played,
                child: SizedBox(
                  width: double.infinity,
                  child: Text(
                    line,
                    maxLines: compact ? 1 : 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.body(
                      size: compact ? 12 : 13,
                      weight: FontWeight.w500,
                      height: 1.3,
                      color: ink.withValues(alpha: 0.66),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// A drag on the scale puts the dial where the finger is.
  void _scaleTo(double x) {
    final d = widget.scene.dial!;
    const r = _ScalePainter.knob;
    final t = ((x - r) / math.max(1, _width - r * 2)).clamp(0.0, 1.0);
    _turnTo(d.from + (d.to - d.from) * t);
  }
}

/// A pan that wins the moment a finger lands, before the deck's own pan,
/// tap or long press can: inside the drawing every touch is the drawing's.
class _EagerPan extends PanGestureRecognizer {
  _EagerPan({super.debugOwner});

  @override
  void addAllowedPointer(PointerDownEvent event) {
    super.addAllowedPointer(event);
    resolve(GestureDisposition.accepted);
  }

  @override
  String get debugDescription => 'beauty';
}

/// Ticks once a frame, so the painter repaints without the page rebuilding.
class _Clock extends ChangeNotifier {
  void tick() => notifyListeners();
}

/// The three colours a drawing may use: ink, ground, and the card's accent
/// when it shows on the ground (ink when it would not).
@immutable
class _Look {
  final Color ink;
  final Color ground;
  final Color accent;
  const _Look(this.ink, this.ground, this.accent);

  factory _Look.of(Color ink, Color ground, int? accent) {
    if (accent == null) return _Look(ink, ground, ink);
    final a = Color(accent);
    final la = a.computeLuminance();
    final lg = ground.computeLuminance();
    final ratio = (math.max(la, lg) + 0.05) / (math.min(la, lg) + 0.05);
    return _Look(ink, ground, ratio >= 1.8 ? a : ink);
  }

  @override
  bool operator ==(Object other) =>
      other is _Look &&
      other.ink == ink &&
      other.ground == ground &&
      other.accent == accent;

  @override
  int get hashCode => Object.hash(ink, ground, accent);
}

class _Painter extends CustomPainter {
  final _World world;
  final _Look look;
  final double value;
  final VoidCallback onPainted;
  _Painter({
    required this.world,
    required this.look,
    required this.value,
    required this.onPainted,
    required Listenable clock,
  }) : super(repaint: clock);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    world.resize(size);
    world.value = value;
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    world.paint(canvas, look);
    canvas.restore();
    onPainted();
  }

  @override
  bool shouldRepaint(_Painter old) =>
      !identical(old.world, world) || old.look != look || old.value != value;
}

// ---- the readout under a dialled piece ------------------------------------

/// "137.5°" big, and what it is beside it.
class _Readout extends StatelessWidget {
  final BeautyDial dial;
  final double value;
  final Color ink;
  final double size;
  const _Readout({
    required this.dial,
    required this.value,
    required this.ink,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          dial.format(value),
          maxLines: 1,
          style: AppText.display(
            size: size,
            weight: FontWeight.w800,
            height: 1,
            spacing: -0.035 * size,
            color: ink,
          ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            dial.label.toUpperCase(),
            maxLines: 1,
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
            style: AppText.label(size: 10.5, color: ink.withValues(alpha: 0.7)),
          ),
        ),
      ],
    );
  }
}

/// The dial's range as a row of fine ticks, the true value standing taller
/// with a dot over it, and a knob where the dial is now.
class _ScalePainter extends CustomPainter {
  static const knob = 10.0;

  final double from;
  final double to;
  final double truth;
  final double now;
  final _Look look;
  _ScalePainter({
    required this.from,
    required this.to,
    required this.truth,
    required this.now,
    required this.look,
  }) : _tick = Paint()
         ..color = look.ink.withValues(alpha: 0.32)
         ..strokeWidth = 1.5
         ..strokeCap = StrokeCap.round,
       _true = Paint()
         ..color = look.accent
         ..strokeWidth = 2.5
         ..strokeCap = StrokeCap.round,
       _ink = Paint()..color = look.ink,
       _ground = Paint()..color = look.ground;

  final Paint _tick;
  final Paint _true;
  final Paint _ink;
  final Paint _ground;

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height / 2;
    final w = size.width - knob * 2;
    double x(double v) => knob + (v - from) / (to - from) * w;

    const n = 40;
    for (var i = 0; i <= n; i++) {
      final tx = knob + w * i / n;
      final h = i % 5 == 0 ? 5.0 : 3.0;
      canvas.drawLine(Offset(tx, y - h), Offset(tx, y + h), _tick);
    }
    final tx = x(truth);
    canvas.drawLine(Offset(tx, y - 9), Offset(tx, y + 9), _true);
    canvas.drawCircle(Offset(tx, y - 12.5), 2.2, _true..style = PaintingStyle.fill);
    _true.style = PaintingStyle.stroke;

    final c = Offset(x(now), y);
    canvas.drawCircle(c, knob - 1, _ink);
    canvas.drawCircle(c, 3.5, _ground);
  }

  @override
  bool shouldRepaint(_ScalePainter old) =>
      old.now != now ||
      old.from != from ||
      old.to != to ||
      old.truth != truth ||
      old.look != look;
}

// ---- the drawings ---------------------------------------------------------

/// Park and Miller's generator: the same numbers on a phone and on the web,
/// so a card's flock is the same flock for every reader.
class _Rng {
  int _x;
  _Rng(int seed) : _x = seed % 2147483647 == 0 ? 1 : seed % 2147483647 {
    for (var i = 0; i < 3; i++) {
      next();
    }
  }

  double next() {
    _x = _x * 16807 % 2147483647;
    return _x / 2147483647;
  }
}

/// One drawing and its little world: what it holds, how it moves, how it
/// is painted. A piece is a world because a flock has to remember where
/// every bird was; the closed-form pieces (seeds, orbits, waves, tree) only
/// keep the clock.
abstract class _World {
  _World(this.scene);

  factory _World.of(BeautyScene s) => switch (s.piece) {
    BeautyPiece.flock => _Flock(s),
    BeautyPiece.phyllotaxis => _Sunflower(s),
    BeautyPiece.orbits => _Orbits(s),
    BeautyPiece.waves => _Waves(s),
    BeautyPiece.fractal => _Tree(s),
  };

  final BeautyScene scene;
  Size size = Size.zero;

  /// Seconds the drawing has run.
  double t = 0;

  /// The dial, for the pieces that have one.
  double value = 0;

  /// With motion off: a still frame, moved only by the hand.
  bool calm = false;

  /// From 0 to 1 over the first moment, as the drawing comes in.
  double get enter => calm ? 1 : Curves.easeOut.transform((t / 0.9).clamp(0, 1));

  /// For the waves' screen-reader slider: how far apart the sources are.
  double get spread => 0;

  void resize(Size s) {
    if (s == size) return;
    final old = size;
    size = s;
    placed(old);
  }

  /// The size has changed (from nothing, the first time).
  void placed(Size old) {}

  void step(double dt) => t += dt;

  void paint(Canvas canvas, _Look look);

  void touch(Offset p, {required bool first}) {}
  void release() {}
  void nudge(double by) {}
}

/// Packs points into a reused buffer and draws them in one call.
class _Batch {
  Float32List _xy = Float32List(512);
  int _n = 0;

  void clear() => _n = 0;
  bool get isEmpty => _n == 0;

  void add(double x, double y) {
    if (_n + 2 > _xy.length) {
      final bigger = Float32List(_xy.length * 2)..setRange(0, _n, _xy);
      _xy = bigger;
    }
    _xy[_n++] = x;
    _xy[_n++] = y;
  }

  void line(double x1, double y1, double x2, double y2) {
    add(x1, y1);
    add(x2, y2);
  }

  void draw(Canvas canvas, PointMode mode, Paint paint) {
    if (_n == 0) return;
    canvas.drawRawPoints(mode, Float32List.sublistView(_xy, 0, _n), paint);
  }
}

// ---- flock --------------------------------------------------------------

/// Starlings, each steering by its seven nearest neighbours only: towards
/// them, along with them, and not into them. Ballerini et al. (2008) found
/// real starlings keep track of six or seven neighbours whatever the
/// distance, which is what lets a flock stretch and stay whole. A slow
/// wandering pull keeps it sweeping round the card, as a roost does; a
/// finger is a falcon, and the birds near it break away.
class _Flock extends _World {
  _Flock(super.scene)
    : n = scene.birds,
      x = Float64List(scene.birds),
      y = Float64List(scene.birds),
      vx = Float64List(scene.birds),
      vy = Float64List(scene.birds),
      nx = Float64List(scene.birds),
      ny = Float64List(scene.birds),
      z = Float64List(scene.birds),
      rng = _Rng(scene.seed);

  static const _k = 7;
  static const _h = 1 / 60;

  final int n;
  final Float64List x, y, vx, vy, nx, ny;

  /// How near each bird is: nearer birds are drawn bigger and darker.
  final Float64List z;
  final _Rng rng;

  final Float64List _nd = Float64List(_k);
  final Int32List _ni = Int32List(_k);
  double _acc = 0;
  bool _born = false;

  // The falcon: where it is, where it heads, and how present it is.
  double fx = 0, fy = 0, fvx = 0, fvy = 0, falcon = 0;
  Offset? finger;
  double strike = -1;


  final List<_Batch> _layers = [_Batch(), _Batch(), _Batch()];
  final Paint _bird = Paint()..strokeCap = StrokeCap.round;
  final Paint _fill = Paint();
  final Path _path = Path();

  double get _s => math.min(size.width, size.height);

  @override
  void placed(Size old) {
    if (!_born) {
      _born = true;
      // Born already a flock: a loose cloud, everyone heading roughly the
      // same way, so the card opens on a murmuration, not on confetti.
      final heading = rng.next() * math.pi * 2;
      final cx = size.width / 2, cy = size.height / 2;
      for (var i = 0; i < n; i++) {
        final a = rng.next() * math.pi * 2;
        final r = math.sqrt(rng.next());
        x[i] = cx + math.cos(a) * r * size.width * 0.3;
        y[i] = cy + math.sin(a) * r * size.height * 0.22;
        final h = heading + (rng.next() - 0.5) * 0.9;
        vx[i] = math.cos(h) * _s * 0.3;
        vy[i] = math.sin(h) * _s * 0.3;
        z[i] = rng.next();
      }
      fx = -_s;
      fy = cy;
      for (var i = 0; i < (calm ? 150 : 50); i++) {
        _sim();
      }
      return;
    }
    if (old.isEmpty) return;
    final sx = size.width / old.width, sy = size.height / old.height;
    for (var i = 0; i < n; i++) {
      x[i] *= sx;
      y[i] *= sy;
    }
  }

  @override
  void step(double dt) {
    super.step(dt);
    if (!_born) return;
    _acc += dt;
    var steps = 0;
    while (_acc >= _h && steps < 3) {
      _acc -= _h;
      steps++;
      _sim();
    }
    if (steps == 3) _acc = 0;
  }

  void _sim() {
    final w = size.width, hgt = size.height, s = _s;
    final vmax = s * 0.34, vmin = s * 0.18;
    final sep = s * 0.045;
    final reach = s * 0.3;
    final margin = s * 0.16;
    // The roost's slow pull: a point wandering a Lissajous figure.
    final px = w * (0.5 + 0.16 * math.cos(t * 0.23 + 1.3));
    final py = hgt * (0.5 + 0.14 * math.sin(t * 0.31));
    _falconStep();

    for (var i = 0; i < n; i++) {
      for (var q = 0; q < _k; q++) {
        _nd[q] = double.infinity;
        _ni[q] = -1;
      }
      final xi = x[i], yi = y[i];
      for (var j = 0; j < n; j++) {
        if (j == i) continue;
        final dx = x[j] - xi, dy = y[j] - yi;
        final d2 = dx * dx + dy * dy;
        if (d2 >= _nd[_k - 1]) continue;
        var q = _k - 1;
        while (q > 0 && _nd[q - 1] > d2) {
          _nd[q] = _nd[q - 1];
          _ni[q] = _ni[q - 1];
          q--;
        }
        _nd[q] = d2;
        _ni[q] = j;
      }
      var cx = 0.0, cy = 0.0, ax = 0.0, ay = 0.0, sx = 0.0, sy = 0.0;
      for (var q = 0; q < _k; q++) {
        final j = _ni[q];
        cx += x[j];
        cy += y[j];
        ax += vx[j];
        ay += vy[j];
        final d = math.sqrt(_nd[q]);
        if (d < sep && d > 1e-6) {
          final push = (1 - d / sep) / d;
          sx -= (x[j] - xi) * push;
          sy -= (y[j] - yi) * push;
        }
      }
      cx = cx / _k - xi;
      cy = cy / _k - yi;
      ax = ax / _k - vx[i];
      ay = ay / _k - vy[i];

      var fx2 = cx * 2.2 + ax * 2.6 + sx * vmax * 4 + (px - xi) * 0.8;
      var fy2 = cy * 2.2 + ay * 2.6 + sy * vmax * 4 + (py - yi) * 0.8;

      // The card's edges, felt as a soft wall.
      if (xi < margin) fx2 += (margin - xi) * 16;
      if (xi > w - margin) fx2 -= (xi - (w - margin)) * 16;
      if (yi < margin) fy2 += (margin - yi) * 16;
      if (yi > hgt - margin) fy2 -= (yi - (hgt - margin)) * 16;

      var panic = 0.0;
      if (falcon > 0) {
        final dx = xi - fx, dy = yi - fy;
        final d = math.sqrt(dx * dx + dy * dy);
        if (d < reach && d > 1e-6) {
          final f = (1 - d / reach) * falcon;
          fx2 += dx / d * f * vmax * 14;
          fy2 += dy / d * f * vmax * 14;
          panic = f;
        }
      }

      var nvx = vx[i] + fx2 * _h, nvy = vy[i] + fy2 * _h;
      final sp = math.sqrt(nvx * nvx + nvy * nvy);
      final top = vmax * (1 + panic * 0.8);
      if (sp > top) {
        nvx *= top / sp;
        nvy *= top / sp;
      } else if (sp < vmin && sp > 1e-6) {
        nvx *= vmin / sp;
        nvy *= vmin / sp;
      }
      nx[i] = nvx;
      ny[i] = nvy;
    }
    for (var i = 0; i < n; i++) {
      vx[i] = nx[i];
      vy[i] = ny[i];
      x[i] += vx[i] * _h;
      y[i] += vy[i] * _h;
    }
  }

  void _falconStep() {
    final s = _s;
    if (strike >= 0) {
      // The screen reader's falcon: one pass through the middle.
      strike += _h / 1.6;
      final p = Curves.easeInOut.transform(strike.clamp(0.0, 1.0));
      final ox = fx, oy = fy;
      fx = -s * 0.1 + (size.width + s * 0.2) * p;
      fy = size.height * (0.3 + 0.4 * p);
      fvx = (fx - ox) / _h;
      fvy = (fy - oy) / _h;
      falcon = math.sin(p * math.pi).clamp(0.0, 1.0);
      if (strike >= 1) strike = -1;
      return;
    }
    final f = finger;
    if (f != null) {
      final ox = fx, oy = fy;
      fx += (f.dx - fx) * 0.35;
      fy += (f.dy - fy) * 0.35;
      fvx = fvx * 0.7 + (fx - ox) / _h * 0.3;
      fvy = fvy * 0.7 + (fy - oy) / _h * 0.3;
      falcon = math.min(1, falcon + _h * 5);
    } else if (falcon > 0) {
      // Let go: the falcon carries on its way and is gone.
      final sp = math.sqrt(fvx * fvx + fvy * fvy);
      if (sp < s * 0.6) {
        final k = sp < 1e-6 ? 0.0 : s * 0.6 / sp;
        fvx = sp < 1e-6 ? s * 0.6 : fvx * k;
        fvy = sp < 1e-6 ? -s * 0.2 : fvy * k;
      }
      fx += fvx * _h;
      fy += fvy * _h;
      falcon = math.max(0, falcon - _h * 1.6);
    }
  }

  @override
  void touch(Offset p, {required bool first}) {
    if (first) {
      strike = -1;
      fx = p.dx;
      fy = p.dy;
      fvx = 0;
      fvy = 0;
    }
    finger = p;
    if (calm) {
      // No motion to watch: the flock jumps to how it has answered.
      falcon = 1;
      for (var i = 0; i < 14; i++) {
        _sim();
      }
    }
  }

  @override
  void release() {
    finger = null;
    if (calm) falcon = 0;
  }

  @override
  void nudge(double by) {
    if (calm) {
      fx = size.width / 2;
      fy = size.height / 2;
      falcon = 1;
      for (var i = 0; i < 30; i++) {
        _sim();
      }
      falcon = 0;
      return;
    }
    finger = null;
    strike = 0;
  }

  @override
  void paint(Canvas canvas, _Look look) {
    if (!_born) return;
    final s = _s;
    final e = enter;
    for (final l in _layers) {
      l.clear();
    }
    final from = look.accent == look.ink ? 0 : 1;
    for (var i = from; i < n; i++) {
      final sp = math.sqrt(vx[i] * vx[i] + vy[i] * vy[i]);
      if (sp < 1e-6) continue;
      final len = s * (0.011 + 0.008 * z[i]) * (0.6 + 0.4 * e);
      final ux = vx[i] / sp * len / 2, uy = vy[i] / sp * len / 2;
      final layer = z[i] < 0.34 ? 0 : (z[i] < 0.67 ? 1 : 2);
      _layers[layer].line(x[i] - ux, y[i] - uy, x[i] + ux, y[i] + uy);
    }
    for (var l = 0; l < 3; l++) {
      _bird
        ..color = look.ink.withValues(alpha: (0.42 + 0.27 * l) * e)
        ..strokeWidth = s * (0.0045 + 0.0022 * l);
      _layers[l].draw(canvas, PointMode.lines, _bird);
    }

    // The followed bird, in the accent: one life in the crowd to watch.
    // Without an accent it is simply one of the flock.
    final sp0 = math.sqrt(vx[0] * vx[0] + vy[0] * vy[0]);
    if (sp0 > 1e-6 && look.accent != look.ink) {
      final len = s * 0.024;
      final ux = vx[0] / sp0 * len / 2, uy = vy[0] / sp0 * len / 2;
      _bird
        ..color = look.accent.withValues(alpha: e)
        ..strokeWidth = s * 0.01;
      canvas.drawLine(
        Offset(x[0] - ux, y[0] - uy),
        Offset(x[0] + ux, y[0] + uy),
        _bird,
      );
    }

    if (falcon > 0.01) {
      // The falcon: a swept chevron, bigger than any bird, pointing where
      // it flies.
      final sp = math.sqrt(fvx * fvx + fvy * fvy);
      final a = sp < 1e-3 ? -math.pi / 2 : math.atan2(fvy, fvx);
      final r = s * 0.06;
      final c = math.cos(a), sn = math.sin(a);
      Offset at(double fwd, double side) => Offset(
        fx + c * fwd * r - sn * side * r,
        fy + sn * fwd * r + c * side * r,
      );
      final tip = at(0.7, 0);
      final l = at(-0.5, -0.95);
      final notch = at(-0.15, 0);
      final rr = at(-0.5, 0.95);
      _path
        ..reset()
        ..moveTo(tip.dx, tip.dy)
        ..lineTo(l.dx, l.dy)
        ..lineTo(notch.dx, notch.dy)
        ..lineTo(rr.dx, rr.dy)
        ..close();
      _fill.color = look.accent.withValues(alpha: falcon);
      canvas.drawPath(_path, _fill);
    }
  }
}

// ---- phyllotaxis ----------------------------------------------------------

/// Vogel's sunflower (1979): seed k at angle k·θ and radius c·√k. Seeds are
/// born at the centre and drift outward as newer ones arrive, the oldest
/// fading at the rim, so the head is always growing and always whole. Two
/// of its spiral arms are picked out, one each way, so the reader can see
/// the spirals the eye finds, and watch them become spokes off the angle.
class _Sunflower extends _World {
  _Sunflower(super.scene) {
    // Opens full: as if it had been growing for as long as it holds.
    t = scene.seeds / _rate + 3;
    _born = t;
  }

  static const _rate = 34.0;
  static const _sizes = 9;
  late final double _born;

  final List<_Batch> _dots = List.generate(_sizes, (_) => _Batch());
  final List<_Batch> _arms = List.generate(_sizes, (_) => _Batch());
  final Paint _dot = Paint()..strokeCap = StrokeCap.round;

  @override
  double get enter =>
      calm ? 1 : Curves.easeOut.transform(((t - _born) / 1.1).clamp(0, 1));

  @override
  void paint(Canvas canvas, _Look look) {
    final big = scene.seeds.toDouble();
    final cx = size.width / 2, cy = size.height / 2;
    final e = enter;
    final r0 = math.min(size.width, size.height) * 0.485 * (0.9 + 0.1 * e);
    final c = r0 / math.sqrt(big);
    final theta = value * math.pi / 180;
    final now = calm ? _born : t;
    final spin = now * 0.04;
    final kTop = (now * _rate).floor();
    final dmax = c * 1.32;
    for (var b = 0; b < _sizes; b++) {
      _dots[b].clear();
      _arms[b].clear();
    }
    for (var k = math.max(0, kTop - scene.seeds); k <= kTop; k++) {
      final age = now * _rate - k;
      if (age <= 0 || age > big) continue;
      final r = c * math.sqrt(age);
      final a = k * theta + spin;
      // New seeds swell into place; old ones shrink away at the rim.
      var d = dmax * (0.78 + 0.22 * math.sqrt(age / big));
      d *= math.min(1, age / 6);
      if (age > big * 0.9) d *= (big - age) / (big * 0.1);
      if (d < 0.6) continue;
      final b = ((d / dmax) * (_sizes - 1)).round().clamp(0, _sizes - 1);
      final arm = k % 21 % 3 == 0;
      (arm ? _arms : _dots)[b].add(cx + r * math.cos(a), cy + r * math.sin(a));
    }
    for (var b = 0; b < _sizes; b++) {
      final w = dmax * (b + 0.5) / _sizes * e;
      _dot
        ..strokeWidth = w
        ..color = look.ink.withValues(alpha: 0.5 * e);
      _dots[b].draw(canvas, PointMode.points, _dot);
      _dot.color = look.accent.withValues(alpha: e);
      _arms[b].draw(canvas, PointMode.points, _dot);
    }
  }
}

// ---- orbits ---------------------------------------------------------------

/// Two planets on circular orbits at their real periods, a line drawn
/// between them every few days and kept for a span of years, the oldest
/// fading. Seen from above the Sun, the lines of Venus and Earth weave a
/// rose of five petals, because thirteen Venus years are almost exactly
/// eight of ours.
class _Orbits extends _World {
  _Orbits(super.scene);

  static const _shades = 10;

  /// Days a second of watching covers.
  double get _pace => scene.outer / 1.7;
  double get _days => scene.span + (calm ? 0 : t * _pace);

  final List<_Batch> _bands = List.generate(_shades, (_) => _Batch());
  final Paint _line = Paint()..strokeCap = StrokeCap.round;
  final Paint _ring = Paint()..style = PaintingStyle.stroke;
  final Paint _fill = Paint();

  @override
  void paint(Canvas canvas, _Look look) {
    final cx = size.width / 2, cy = size.height / 2;
    final e = enter;
    final scale =
        math.min(size.width, size.height) * 0.47 / scene.outerRadius;
    final r1 = scene.innerRadius * scale, r2 = scene.outerRadius * scale;
    final p1 = value, p2 = scene.outer;
    final now = _days;
    final every = scene.every;
    final count = (scene.span / every).floor();
    final last = (now / every).floor();

    for (final b in _bands) {
      b.clear();
    }
    for (var q = 0; q < count; q++) {
      final d = (last - q) * every;
      if (d < 0) break;
      final a1 = d / p1 * math.pi * 2 - math.pi / 2;
      final a2 = d / p2 * math.pi * 2 - math.pi / 2;
      // Shade by age, newest darkest; and the lines still being drawn
      // arrive with the clock rather than all at once.
      final band = (q / count * _shades).floor().clamp(0, _shades - 1);
      _bands[band].line(
        cx + r1 * math.cos(a1),
        cy + r1 * math.sin(a1),
        cx + r2 * math.cos(a2),
        cy + r2 * math.sin(a2),
      );
    }

    _ring
      ..color = look.ink.withValues(alpha: 0.22 * e)
      ..strokeWidth = 1;
    canvas.drawCircle(Offset(cx, cy), r1, _ring);
    canvas.drawCircle(Offset(cx, cy), r2, _ring);

    for (var b = 0; b < _shades; b++) {
      final age = b / (_shades - 1);
      _line
        ..strokeWidth = 0.9
        ..color = look.ink.withValues(alpha: (0.55 - 0.47 * age) * e);
      _bands[b].draw(canvas, PointMode.lines, _line);
    }

    // The Sun, and the two planets with the line between them now.
    final a1 = now / p1 * math.pi * 2 - math.pi / 2;
    final a2 = now / p2 * math.pi * 2 - math.pi / 2;
    final v = Offset(cx + r1 * math.cos(a1), cy + r1 * math.sin(a1));
    final h = Offset(cx + r2 * math.cos(a2), cy + r2 * math.sin(a2));
    _line
      ..strokeWidth = 2
      ..color = look.accent.withValues(alpha: 0.9 * e);
    canvas.drawLine(v, h, _line);
    final s = math.min(size.width, size.height);
    _fill.color = look.accent.withValues(alpha: e);
    canvas.drawCircle(Offset(cx, cy), s * 0.022, _fill);
    for (final (p, r) in [(v, s * 0.019), (h, s * 0.021)]) {
      _fill.color = look.ground.withValues(alpha: e);
      canvas.drawCircle(p, r + 2.5, _fill);
      _fill.color = look.accent.withValues(alpha: e);
      canvas.drawCircle(p, r, _fill);
    }
  }
}

// ---- waves ----------------------------------------------------------------

/// Two sources of ripples, every crest drawn as a field of dots. Where the
/// crests of one meet the troughs of the other the water never moves, and
/// those lanes stay empty while the rest runs outward. A finger drags the
/// nearer source, and the lanes swing with it.
class _Waves extends _World {
  _Waves(super.scene);

  static const _sizes = 8;
  Offset a = Offset.zero, b = Offset.zero;
  int? _held;
  final List<_Batch> _dots = List.generate(_sizes, (_) => _Batch());
  final Paint _dot = Paint()..strokeCap = StrokeCap.round;
  final Paint _ring = Paint()..style = PaintingStyle.stroke;
  final Paint _fill = Paint();

  @override
  double get spread => (b - a).distance / math.max(1, size.width);

  @override
  void placed(Size old) {
    if (old.isEmpty) {
      final g = scene.gap * size.width / 2;
      a = Offset(size.width / 2 - g, size.height * 0.5);
      b = Offset(size.width / 2 + g, size.height * 0.5);
    } else {
      Offset sc(Offset p) =>
          Offset(p.dx * size.width / old.width, p.dy * size.height / old.height);
      a = sc(a);
      b = sc(b);
    }
  }

  Offset _inside(Offset p) => Offset(
    p.dx.clamp(8.0, math.max(8.0, size.width - 8)),
    p.dy.clamp(8.0, math.max(8.0, size.height - 8)),
  );

  @override
  void touch(Offset p, {required bool first}) {
    if (first || _held == null) {
      _held = (p - a).distance <= (p - b).distance ? 0 : 1;
      HapticFeedback.selectionClick();
    }
    if (_held == 0) {
      a = _inside(p);
    } else {
      b = _inside(p);
    }
  }

  @override
  void release() => _held = null;

  @override
  void nudge(double by) {
    final mid = (a + b) / 2;
    var half = (b - a) / 2;
    final len = half.distance;
    final next = (len + by * size.width * 0.04).clamp(
      size.width * 0.03,
      size.width * 0.45,
    );
    half = len < 1e-6 ? Offset(next, 0) : half * (next / len);
    a = _inside(mid - half);
    b = _inside(mid + half);
  }

  @override
  void paint(Canvas canvas, _Look look) {
    final e = enter;
    final lambda = scene.wavelength * size.width;
    final k = math.pi * 2 / lambda;
    final w = math.pi * 2 / 1.7;
    final time = calm ? 0.35 : t;
    final g = math.max(5.0, size.width / 58);
    final cols = (size.width / g).floor();
    final rows = (size.height / g).floor();
    final ox = (size.width - (cols - 1) * g) / 2;
    final oy = (size.height - (rows - 1) * g) / 2;
    final reach = lambda * 4;

    for (final d in _dots) {
      d.clear();
    }
    for (var r = 0; r < rows; r++) {
      final py = oy + r * g;
      for (var c = 0; c < cols; c++) {
        final px = ox + c * g;
        final d1 = math.sqrt((px - a.dx) * (px - a.dx) + (py - a.dy) * (py - a.dy));
        final d2 = math.sqrt((px - b.dx) * (px - b.dx) + (py - b.dy) * (py - b.dy));
        // The ripples weaken as they spread, gently, so the far field
        // still carries the pattern.
        final v =
            math.cos(k * d1 - w * time) / math.sqrt(1 + d1 / reach) +
            math.cos(k * d2 - w * time) / math.sqrt(1 + d2 / reach);
        // Every point a dot: a crest swells it, a trough shrinks it to a
        // speck, and where the two waves cancel it never changes.
        final q = (((v + 2) / 4).clamp(0.0, 1.0) * (_sizes - 1)).round();
        _dots[q].add(px, py);
      }
    }
    for (var q = 0; q < _sizes; q++) {
      final f = q / (_sizes - 1);
      _dot
        ..strokeWidth = g * (0.12 + 0.86 * f * f) * e
        ..color = look.ink.withValues(alpha: (0.35 + 0.65 * f) * e);
      _dots[q].draw(canvas, PointMode.points, _dot);
    }

    for (final p in [a, b]) {
      _fill.color = look.ground.withValues(alpha: e);
      canvas.drawCircle(p, g * 1.5, _fill);
      _fill.color = look.accent.withValues(alpha: e);
      canvas.drawCircle(p, g * 0.75, _fill);
      _ring
        ..color = look.accent.withValues(alpha: e)
        ..strokeWidth = 2;
      canvas.drawCircle(p, g * 1.5, _ring);
    }
  }
}

// ---- fractal tree -------------------------------------------------------

/// One rule, done again and again: a branch ends by splitting in two, each
/// turned by the dial's angle and a little shorter. It grows in when the
/// card arrives and sways as if in a light wind, more at the tips; the
/// whole tree is fitted to the card at every angle.
class _Tree extends _World {
  _Tree(super.scene) : _ends = Float64List(4 << (scene.depth + 1));

  static const _grow = 1.6;

  /// Every branch's end, filled breadth-first: x, y, heading, length.
  final Float64List _ends;
  final List<_Batch> _levels = List.generate(12, (_) => _Batch());
  final _Batch _tips = _Batch();
  final Paint _wood = Paint()..strokeCap = StrokeCap.round;
  final Paint _leaf = Paint()..strokeCap = StrokeCap.round;

  // The fit, eased so the tree does not jump as the angle changes.
  double _fs = 0, _fx = 0, _fy = 0;

  @override
  void paint(Canvas canvas, _Look look) {
    final depth = scene.depth;
    final grown = calm ? 1.0 : (t / _grow).clamp(0.0, 1.0);
    final g = Curves.easeOut.transform(grown) * (depth + 1);
    final spread = value * math.pi / 180;
    final wind = calm ? 0.0 : t;

    // Lay the tree out in its own units: trunk from (0,0) straight up,
    // length 1, then each level's branches from their parents' ends.
    var minX = -0.01, maxX = 0.01, minY = -1.0, maxY = 0.0;
    _ends[0] = 0;
    _ends[1] = -1;
    _ends[2] = -math.pi / 2;
    _ends[3] = 1;
    for (var l = 1; l <= depth; l++) {
      final first = (1 << l) - 1, parents = (1 << (l - 1)) - 1;
      final sway = math.sin(wind * 0.9 + l * 0.55) * 0.012 * l +
          math.sin(wind * 0.37) * 0.01;
      for (var i = 0; i < 1 << l; i++) {
        final p = (parents + (i >> 1)) * 4;
        final side = i.isEven ? -1 : 1;
        final h = _ends[p + 2] + side * spread + sway;
        final len = _ends[p + 3] * scene.ratio;
        final o = (first + i) * 4;
        final ex = _ends[p] + math.cos(h) * len;
        final ey = _ends[p + 1] + math.sin(h) * len;
        _ends[o] = ex;
        _ends[o + 1] = ey;
        _ends[o + 2] = h;
        _ends[o + 3] = len;
        if (ex < minX) minX = ex;
        if (ex > maxX) maxX = ex;
        if (ey < minY) minY = ey;
        if (ey > maxY) maxY = ey;
      }
    }

    // Fit: as big as the card allows, centred, its foot never above the
    // bottom edge.
    const pad = 0.05;
    final bw = maxX - minX, bh = maxY - minY;
    final fs = math.min(
      size.width * (1 - pad * 2) / math.max(bw, 1e-3),
      size.height * (1 - pad * 2) / math.max(bh, 1e-3),
    );
    final fx = size.width / 2 - (minX + bw / 2) * fs;
    final fy = size.height / 2 - (minY + bh / 2) * fs;
    if (_fs == 0 || calm) {
      _fs = fs;
      _fx = fx;
      _fy = fy;
    } else {
      _fs += (fs - _fs) * 0.2;
      _fx += (fx - _fx) * 0.2;
      _fy += (fy - _fy) * 0.2;
    }

    for (var l = 0; l <= depth; l++) {
      _levels[l].clear();
    }
    _tips.clear();
    for (var l = 0; l <= depth; l++) {
      final f = (g - l).clamp(0.0, 1.0);
      if (f <= 0) break;
      final first = (1 << l) - 1;
      for (var i = 0; i < 1 << l; i++) {
        final o = (first + i) * 4;
        final ex = _ends[o], ey = _ends[o + 1];
        final double sx, sy;
        if (l == 0) {
          sx = 0;
          sy = 0;
        } else {
          final p = ((1 << (l - 1)) - 1 + (i >> 1)) * 4;
          sx = _ends[p];
          sy = _ends[p + 1];
        }
        final tx = sx + (ex - sx) * f, ty = sy + (ey - sy) * f;
        _levels[l].line(
          _fx + sx * _fs,
          _fy + sy * _fs,
          _fx + tx * _fs,
          _fy + ty * _fs,
        );
        if (l == depth) _tips.add(_fx + tx * _fs, _fy + ty * _fs);
      }
    }
    final s = math.min(size.width, size.height);
    for (var l = 0; l <= depth; l++) {
      _wood
        ..strokeWidth = math.max(0.9, s * 0.03 * math.pow(0.68, l))
        ..color = look.ink.withValues(alpha: math.max(0.55, 1 - l * 0.05));
      _levels[l].draw(canvas, PointMode.lines, _wood);
    }
    _leaf
      ..strokeWidth = math.max(2.6, s * 0.012)
      ..color = look.accent.withValues(alpha: 0.9 * (g - depth).clamp(0.0, 1.0));
    _tips.draw(canvas, PointMode.points, _leaf);
  }
}
