import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/l10n.dart';
import '../../models/scene.dart';
import '../../theme.dart';

/// Plays a [SortScene]: a short deck of slips, thrown one at a time onto
/// two piles.
///
/// It fills the height it is given: the deck on top taking whatever is
/// left, the two piles as trays at the foot. A slip is a little raised card
/// of the card's own colour, ink-edged like the card itself. Thrown, it is
/// stamped with the reader's call, turns over to its dark side to say where
/// it really belongs, and drops into the tray it was thrown at. When the
/// last one is in, the trays rise into two columns, the wrong calls walk
/// across to the pile they belong on, marked, and the score sits on top.
///
/// The swipe is caught by a horizontal drag over the whole scene, which
/// wins the arena against the deck's pan because it claims at a shorter
/// slop; a vertical drag is left to the deck. Once the piles have settled
/// the scene stops listening, so a swipe on it moves the deck on again.
class SortSceneView extends StatefulWidget {
  final SortScene scene;
  final Color ink;
  final Color ground;
  const SortSceneView({
    super.key,
    required this.scene,
    required this.ink,
    required this.ground,
  });

  @override
  State<SortSceneView> createState() => _SortSceneViewState();
}

class _SortSceneViewState extends State<SortSceneView>
    with TickerProviderStateMixin {
  SortScene get _s => widget.scene;

  /// Which slip is on top; the deck is done when it reaches the length.
  int _at = 0;

  /// The reader's call for each slip that has landed.
  late List<SortSide?> _calls = List.filled(_s.items.length, null);

  /// The call on the slip that is turning over now, before it lands.
  SortSide? _pending;

  /// Where the finger had carried the slip when it was let go, so the turn
  /// can start from there instead of jumping back to the middle.
  double _releaseDx = 0;

  /// The top slip's sideways travel under the finger, and its spring home.
  late final AnimationController _x = AnimationController.unbounded(
    vsync: this,
  );

  /// One thrown slip: the stamp and the turn, the time to read its back,
  /// the drop into the tray. One controller with its own timings per slip,
  /// rather than three, so a tap can skip to the drop by moving one value.
  late final AnimationController _step = AnimationController(vsync: this);
  double _turnEnd = 0, _dropStart = 0;

  /// The end: trays rise into columns and the wrong calls cross over.
  late final AnimationController _settle = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1900),
  );

  /// The tray a slip just landed in gives a small bump.
  late final AnimationController _land = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  );
  SortSide? _landSide;

  /// When the card arrives the top slip leans a little way toward a pile
  /// and comes back, so it is seen to be a thing to throw. The wait is the
  /// first third of the controller rather than a Timer, which would outlive
  /// a disposed widget and hang a widget test.
  late final AnimationController _nudge = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2100),
  );
  bool _started = false;
  bool _touched = false;

  /// Past the line where letting go throws, so the crossing clicks once.
  bool _armed = false;

  double _width = 300;

  bool get _calm => MediaQuery.disableAnimationsOf(context);
  bool get _done => _at >= _s.items.length;

  @override
  void initState() {
    super.initState();
    _step.addStatusListener((status) {
      // animateTo reports `completed` at any target, so the pause before
      // the drop would count as landing without the value check.
      if (status == AnimationStatus.completed && _step.value >= 1) _landed();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started && !_calm) {
      _started = true;
      _nudge.forward();
    }
  }

  @override
  void didUpdateWidget(SortSceneView old) {
    super.didUpdateWidget(old);
    if (!identical(old.scene, widget.scene)) _restart();
  }

  @override
  void dispose() {
    _x.dispose();
    _step.dispose();
    _settle.dispose();
    _land.dispose();
    _nudge.dispose();
    super.dispose();
  }

  double get _throwAt => _width * 0.28;

  void _dragStart(DragStartDetails d) {
    if (_pending != null) {
      _skip();
      return;
    }
    _touched = true;
    _nudge.stop();
    _x.stop();
  }

  void _dragUpdate(DragUpdateDetails d) {
    if (_pending != null || _done) return;
    _x.value += d.primaryDelta ?? d.delta.dx;
    final armed = _x.value.abs() > _throwAt;
    if (armed != _armed) {
      _armed = armed;
      if (armed) HapticFeedback.selectionClick();
    }
  }

  void _dragEnd(DragEndDetails d) {
    if (_pending != null || _done) return;
    final dx = _x.value;
    final v = d.primaryVelocity ?? 0;
    // Carried past the line, or flicked hard the way it was already going:
    // a quick flick is the gesture most people actually make.
    if (dx.abs() > _throwAt || (v.abs() > 700 && dx.abs() > 16 && v * dx > 0)) {
      _decide(dx > 0 ? SortSide.right : SortSide.left);
    } else {
      _armed = false;
      _x.animateTo(
        0,
        duration: Duration(milliseconds: _calm ? 0 : 340),
        curve: Curves.easeOutBack,
      );
    }
  }

  /// The reader's call on the top slip: stamp it, turn it, drop it.
  void _decide(SortSide side) {
    if (_pending != null || _done) return;
    HapticFeedback.lightImpact();
    _nudge.stop();
    _touched = true;
    _armed = false;
    final item = _s.items[_at];
    final turn = _calm ? 0 : 560;
    final drop = _calm ? 0 : 440;
    // Long enough to read the back at an easy pace, never a wait.
    final hold = (1300 + item.verdict.length * 26).clamp(1800, 3600);
    final total = turn + hold + drop;
    _turnEnd = turn / total;
    _dropStart = (turn + hold) / total;
    setState(() {
      _pending = side;
      _releaseDx = _x.value;
    });
    _x.stop();
    _step.duration = Duration(milliseconds: total);
    _step.value = 0;
    // With a screen reader on, the back stays up until the reader moves on:
    // a line read aloud should not be cut off by a clock.
    final waits = MediaQuery.accessibleNavigationOf(context);
    _step.animateTo(_dropStart).then((_) {
      if (mounted && !waits) _step.forward();
    });
  }

  /// A tap or a swipe while the back is up: on to the next slip.
  void _skip() {
    if (_pending == null || _step.value >= _dropStart) return;
    _step.forward(from: _dropStart);
  }

  void _landed() {
    final side = _pending;
    if (side == null) return;
    setState(() {
      _calls[_at] = side;
      _at++;
      _pending = null;
      _releaseDx = 0;
      _landSide = side;
    });
    _x.value = 0;
    _step.value = 0;
    if (!_calm) _land.forward(from: 0);
    if (_done) {
      HapticFeedback.lightImpact();
      if (_calm) {
        _settle.value = 1;
      } else {
        _settle.forward(from: 0);
      }
    }
  }

  void _restart() {
    HapticFeedback.selectionClick();
    _step.stop();
    _settle.stop();
    setState(() {
      _at = 0;
      _calls = List.filled(_s.items.length, null);
      _pending = null;
      _releaseDx = 0;
      _landSide = null;
    });
    _x.value = 0;
    _step.value = 0;
    _settle.value = 0;
  }

  /// A tap on a slip waiting to be thrown leans it again, to show how.
  void _tapSlip() {
    if (_pending != null) {
      _skip();
    } else if (!_calm) {
      _touched = false;
      _nudge.forward(from: 0.3);
    }
  }

  int get _right {
    var n = 0;
    for (var i = 0; i < _s.items.length; i++) {
      if (_calls[i] == _s.items[i].pile) n++;
    }
    return n;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        _width = box.maxWidth;
        final size = Size(box.maxWidth, box.maxHeight);
        return AnimatedBuilder(
          animation: Listenable.merge([_x, _step, _settle, _land, _nudge]),
          builder: (context, _) {
            final playing = !_done;
            final stack = Stack(
              clipBehavior: Clip.none,
              children: [
                if (_settle.value < 1) ..._play(context, size),
                if (_done) ..._piles(context, size),
              ],
            );
            return GestureDetector(
              behavior: HitTestBehavior.translucent,
              // Only while there is something to throw: once the piles
              // have settled a swipe here is a swipe on the card again.
              onHorizontalDragStart: playing ? _dragStart : null,
              onHorizontalDragUpdate: playing ? _dragUpdate : null,
              onHorizontalDragEnd: playing ? _dragEnd : null,
              child: SizedBox.fromSize(size: size, child: stack),
            );
          },
        );
      },
    );
  }

  // ───────────────────────── the deck and the trays ─────────────────────────

  /// How tall the trays are, and the deck's room above them.
  double _trayH(Size size) => (size.height * 0.16).clamp(50.0, 66.0);

  List<Widget> _play(BuildContext context, Size size) {
    final ink = widget.ink;
    final ground = widget.ground;
    final n = _s.items.length;
    final trayH = _trayH(size);
    const gap = 12.0, peek = 7.0, edge = 5.0, inset = 4.0;
    final deckH = size.height - trayH - gap;
    final slip = Rect.fromLTWH(
      inset,
      0,
      size.width - inset * 2,
      math.max(0, deckH - peek * 2 - edge),
    );
    final fade = 1 - Curves.easeIn.transform((_settle.value / 0.22).clamp(0, 1));

    // Where the step is: 0..1 within the stamp and turn, then the drop.
    final st = _step.value;
    final turnT = _turnEnd == 0
        ? (_pending == null ? 0.0 : 1.0)
        : (st / _turnEnd).clamp(0.0, 1.0);
    final dropT = _pending == null || st < _dropStart
        ? 0.0
        : _dropStart >= 1
        ? 1.0
        : ((st - _dropStart) / (1 - _dropStart)).clamp(0.0, 1.0);

    final trays = <SortSide, Rect>{
      SortSide.left: Rect.fromLTWH(0, size.height - trayH, (size.width - 10) / 2, trayH),
      SortSide.right: Rect.fromLTWH(
        (size.width + 10) / 2,
        size.height - trayH,
        (size.width - 10) / 2,
        trayH,
      ),
    };

    // The tray the slip is heading for lights up as it goes.
    double lit(SortSide side) {
      if (_pending != null) return _pending == side ? 1 : 0;
      final dx = _shownDx();
      final toward = side == SortSide.right ? dx : -dx;
      return (toward / _throwAt).clamp(0.0, 1.0) * 0.85 +
          (toward > _throwAt ? 0.15 : 0);
    }

    final out = <Widget>[];

    // The slips under the top one, back to front, rising as it leaves.
    for (var i = math.min(n - 1, _at + 2); i > _at; i--) {
      final depth = (i - _at) - dropT;
      out.add(_under(slip, depth, i, fade));
    }

    if (!_done) {
      out.add(
        _topSlip(context, slip, trays[_pending ?? SortSide.right]!, turnT, dropT, fade),
      );
    }

    for (final side in SortSide.values) {
      final count = _calls.where((c) => c == side).length;
      final bump = _landSide == side && _land.isAnimating
          ? math.sin(_land.value * math.pi) * 0.06
          : 0.0;
      out.add(
        Positioned.fromRect(
          rect: trays[side]!,
          child: Opacity(
            opacity: fade,
            child: Transform.scale(
              scale: 1 + bump,
              child: _Tray(
                name: _s.nameOf(side),
                side: side,
                count: count,
                lit: lit(side),
                ink: ink,
                ground: ground,
                onTap: _pending == null && !_done
                    ? () => _decide(side)
                    : _skip,
              ),
            ),
          ),
        ),
      );
    }
    return out;
  }

  /// The slip's sideways travel: the finger's, or the arrival nudge's.
  double _shownDx() {
    if (_touched || _pending != null) return _x.value;
    final p = ((_nudge.value * 3) - 1).clamp(0.0, 2.0) / 2;
    final v = Curves.easeInOut.transform(p < .5 ? p * 2 : 2 - p * 2);
    return _width * 0.13 * v;
  }

  /// A slip waiting its turn: blank, a little lower and smaller, tilted.
  Widget _under(Rect slip, double depth, int i, double fade) {
    final d = depth.clamp(0.0, 2.0);
    return Positioned.fromRect(
      rect: slip,
      child: IgnorePointer(
        child: Opacity(
          opacity: fade,
          child: Transform(
            alignment: Alignment.bottomCenter,
            transform: Matrix4.identity()
              ..translateByDouble(0.0, d * 7, 0.0, 1.0)
              ..scaleByDouble(1 - d * 0.035, 1 - d * 0.035, 1.0, 1.0)
              ..rotateZ((i.isOdd ? 1.6 : -1.3) * d * math.pi / 180),
            child: _Paper(
              ink: widget.ink,
              ground: widget.ground,
              shadow: false,
              // The next slip's face shows as it comes up to the top.
              child: Opacity(
                opacity: (1 - d).clamp(0.0, 1.0),
                child: _Front(
                  scene: _s,
                  index: i,
                  ink: widget.ink,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _topSlip(
    BuildContext context,
    Rect slip,
    Rect tray,
    double turnT,
    double dropT,
    double fade,
  ) {
    final ink = widget.ink;
    final ground = widget.ground;
    final item = _s.items[_at];
    final pending = _pending;

    // Stamp first, then the turn: the first third of the turn the slip
    // sits still under the stamp, the rest it rotates over.
    final rot = Curves.easeInOutCubic.transform(((turnT - 0.32) / 0.68).clamp(0, 1));
    final angle = rot * math.pi;
    final showBack = angle > math.pi / 2;

    double dx;
    if (pending == null) {
      dx = _shownDx();
    } else {
      final sign = pending == SortSide.right ? 1.0 : -1.0;
      dx = _releaseDx * (1 - Curves.easeOutCubic.transform(turnT)) +
          sign * _width * 0.05 * math.sin(turnT * math.pi);
    }
    final tilt = dx * 0.0011;

    // The drop: toward the tray, shrinking into it, gone as it lands.
    final dropE = Curves.easeInCubic.transform(dropT);
    final target = tray.center - slip.center;
    final shrink = 1 - dropE * (1 - (tray.width * 0.7) / slip.width);
    final dropSign = pending == SortSide.left ? -1.0 : 1.0;

    // The stamp of the side the slip is going, while it is on its way.
    final stampSide = pending ?? (dx >= 0 ? SortSide.right : SortSide.left);
    final stampOpacity = pending != null
        ? 1.0
        : (dx.abs() / _throwAt).clamp(0.0, 1.0);
    final slam = pending == null
        ? 1.0
        : 1.5 - 0.5 * Curves.easeOutBack.transform((turnT / 0.3).clamp(0, 1));

    final face = showBack
        ? Transform(
            alignment: Alignment.center,
            transform: Matrix4.rotationY(math.pi),
            child: _Paper(
              ink: ink,
              ground: ink,
              edge: Color.lerp(ink, ground, 0.45)!,
              child: _Back(scene: _s, index: _at, call: pending!, ink: ink, ground: ground),
            ),
          )
        : _Paper(
            ink: ink,
            ground: ground,
            child: Stack(
              children: [
                _Front(scene: _s, index: _at, ink: ink),
                if (stampOpacity > 0)
                  _Stamp(
                    text: _s.nameOf(stampSide),
                    side: stampSide,
                    opacity: stampOpacity,
                    scale: slam,
                    ink: ink,
                    ground: ground,
                  ),
              ],
            ),
          );

    final call = pending;
    final label = call == null
        ? '${context.l10n.sceneNOfM(_at + 1, _s.items.length)}. ${item.text}. ${item.note}'
        : '${_s.nameOf(item.pile)}. ${item.verdict}'
              '${call == item.pile ? '' : ' ${context.l10n.sceneYou}: ${_s.nameOf(call)}.'}';

    return Positioned.fromRect(
      rect: slip,
      child: Opacity(
        opacity: fade * (1 - Curves.easeIn.transform(((dropT - 0.55) / 0.45).clamp(0, 1))),
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..translateByDouble(
              dx + target.dx * dropE,
              -dx.abs() * 0.04 + target.dy * dropE,
              0.0,
              1.0,
            )
            ..rotateZ(tilt + dropSign * 0.12 * dropE)
            ..scaleByDouble(shrink, shrink, 1.0, 1.0)
            ..setEntry(3, 2, 0.0013)
            ..rotateY(angle),
          child: Semantics(
            container: true,
            liveRegion: call != null,
            label: label,
            hint: call == null ? context.l10n.sceneSwipeHint : null,
            onTap: call != null ? _skip : null,
            child: ExcludeSemantics(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _tapSlip,
                child: face,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ───────────────────────────── the settled piles ─────────────────────────────

  List<Widget> _piles(BuildContext context, Size size) {
    final ink = widget.ink;
    final ground = widget.ground;
    final items = _s.items;
    final n = items.length;
    final t = _settle.value;
    final colGap = 12.0;
    final colW = (size.width - colGap) / 2;
    double colX(SortSide s) => s == SortSide.left ? 0 : colW + colGap;

    final scoreSize = (size.height * 0.12).clamp(30.0, 46.0);
    final scoreH = scoreSize * 1.05;
    final headTop = scoreH + 14;
    const headH = 34.0;
    final y0 = headTop + headH + 10;
    final trayTop = size.height - _trayH(size);

    // Where each slip stands: in the pile it was thrown on, and in the one
    // it belongs to — those called right first, the wrong ones after.
    final chosenSlot = List.filled(n, 0), trueSlot = List.filled(n, 0);
    final chosenCount = {SortSide.left: 0, SortSide.right: 0};
    final trueCount = {SortSide.left: 0, SortSide.right: 0};
    for (var i = 0; i < n; i++) {
      chosenSlot[i] = chosenCount[_calls[i]!]!;
      chosenCount[_calls[i]!] = chosenSlot[i] + 1;
    }
    for (final wrong in [false, true]) {
      for (var i = 0; i < n; i++) {
        if ((_calls[i] != items[i].pile) != wrong) continue;
        trueSlot[i] = trueCount[items[i].pile]!;
        trueCount[items[i].pile] = trueSlot[i] + 1;
      }
    }
    // Sized for the piles as they end, up to a slip you could pick up.
    // On the way, the pile the reader threw most on may be fuller than
    // that; there they overlap like a real pile, each word still clear.
    final avail = size.height - y0;
    final mostTrue = trueCount.values.reduce(math.max);
    final mostCalled = chosenCount.values.reduce(math.max);
    final miniH = (avail / mostTrue - 8).clamp(34.0, 66.0);
    double pitchFor(int most) => most <= 1
        ? miniH + 8
        : math.min(miniH + 8, (avail - miniH) / (most - 1));
    final pitch = pitchFor(mostTrue);
    final calledPitch = pitchFor(mostCalled);
    final textSize = math
        .min(miniH * 0.42, calledPitch - 9)
        .clamp(12.0, 22.0);

    double ease(double a, double b, [Curve c = Curves.easeOutCubic]) =>
        c.transform(((t - a) / (b - a)).clamp(0.0, 1.0));

    final headIn = ease(0.12, 0.34);
    final out = <Widget>[];

    // The score, once the piles are true.
    final scoreIn = ease(0.78, 0.96, Curves.easeOutBack);
    out.add(
      Positioned(
        left: 0,
        right: 0,
        top: 0,
        height: scoreH,
        child: Opacity(
          opacity: scoreIn.clamp(0.0, 1.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Semantics(
                  liveRegion: true,
                  child: Transform.translate(
                    offset: Offset(0, (1 - scoreIn) * 10),
                    child: Text(
                      context.l10n.sceneNOfM(_right, n),
                      maxLines: 1,
                      style: AppText.display(
                        size: scoreSize,
                        weight: FontWeight.w800,
                        height: 1,
                        spacing: -scoreSize * 0.03,
                        color: ink,
                      ),
                    ),
                  ),
                ),
              ),
              Semantics(
                button: true,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: t >= 1 ? _restart : null,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(99),
                          border: Border.all(color: ink, width: 2),
                        ),
                        child: Text(
                          context.l10n.sceneTryAgain,
                          style: AppText.body(
                            size: 13,
                            weight: FontWeight.w700,
                            color: ink,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    // The pile heads: the name and, once settled, how many truly belong.
    for (final side in SortSide.values) {
      final countIn = ease(0.7, 0.85);
      out.add(
        Positioned(
          left: colX(side),
          width: colW,
          top: headTop,
          height: headH,
          child: Opacity(
            opacity: headIn,
            child: Container(
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: ink, width: 2.5)),
              ),
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: _FitText(
                      text: _s.nameOf(side),
                      max: 22,
                      min: 13,
                      style: (s) => AppText.display(
                        size: s,
                        weight: FontWeight.w800,
                        height: 1,
                        spacing: -s * 0.02,
                        color: ink,
                      ),
                    ),
                  ),
                  Opacity(
                    opacity: countIn,
                    child: Text(
                      '${trueCount[side]}',
                      style: AppText.display(
                        size: 22,
                        weight: FontWeight.w800,
                        height: 1,
                        color: ink,
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

    // The minis: up out of the trays into the pile they were thrown on,
    // then the wrong ones across to where they belong.
    for (var i = 0; i < n; i++) {
      final item = items[i];
      final call = _calls[i]!;
      final wrong = call != item.pile;
      final k = i / math.max(1, n - 1);
      final rise = ease(0.08 + k * 0.22, 0.36 + k * 0.22);
      final cross = wrong ? ease(0.6, 0.82, Curves.easeInOutCubic) : 0.0;
      final repack = ease(0.62, 0.84, Curves.easeInOutCubic);
      final mark = wrong ? ease(0.82, 0.92, Curves.easeOutBack) : 0.0;

      final from = Offset(colX(call), trayTop);
      final mid = Offset(colX(call), y0 + chosenSlot[i] * calledPitch);
      final end = Offset(colX(item.pile), y0 + trueSlot[i] * pitch);
      var at = Offset.lerp(from, mid, rise)!;
      if (wrong) {
        // Lifted a little as it crosses, so it reads as carried over.
        at = Offset.lerp(mid, end, cross)! + Offset(0, -math.sin(cross * math.pi) * 14);
        if (cross == 0) at = Offset.lerp(from, mid, rise)!;
      } else if (rise >= 1) {
        at = Offset.lerp(mid, end, repack)!;
      }
      out.add(
        Positioned(
          left: at.dx,
          top: at.dy,
          width: colW,
          height: miniH,
          child: Opacity(
            opacity: rise.clamp(0.0, 1.0),
            child: Transform.rotate(
              angle: (1 - rise) * (i.isOdd ? 0.12 : -0.12) +
                  math.sin(cross * math.pi) * (item.pile == SortSide.right ? 0.06 : -0.06),
              child: Semantics(
                label: '${item.text}: ${_s.nameOf(item.pile)}'
                    '${wrong ? '. ${context.l10n.sceneYou}: ${_s.nameOf(call)}' : ''}',
                child: ExcludeSemantics(
                  child: _Mini(
                    text: item.text,
                    textSize: textSize,
                    // Room for a second line: what the reader had said.
                    said: wrong && miniH >= 56
                        ? '${context.l10n.sceneYou}: ${_s.nameOf(call).toUpperCase()}'
                        : null,
                    wrong: wrong,
                    mark: mark,
                    ink: ink,
                    ground: ground,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }
    return out;
  }
}

// ───────────────────────────────── the pieces ─────────────────────────────────

/// A slip of paper: the card's colour, an ink rule round it, and the ink
/// edge under it that every Astute card stands on.
class _Paper extends StatelessWidget {
  final Color ink;
  final Color ground;
  final Color? edge;
  final bool shadow;
  final Widget child;
  const _Paper({
    required this.ink,
    required this.ground,
    required this.child,
    this.edge,
    this.shadow = true,
  });

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(18);
    return Container(
      decoration: BoxDecoration(
        borderRadius: r,
        color: edge ?? ink,
        boxShadow: shadow
            ? const [
                BoxShadow(
                  color: Color(0x2E000000),
                  blurRadius: 18,
                  offset: Offset(0, 10),
                ),
              ]
            : null,
      ),
      padding: const EdgeInsets.only(bottom: 5),
      child: Container(
        decoration: BoxDecoration(
          color: ground,
          borderRadius: r,
          border: Border.all(color: ink, width: 2),
        ),
        child: ClipRRect(borderRadius: r, child: child),
      ),
    );
  }
}

/// The face of a slip: where it comes from and how far along, the thing in
/// large type, what it is in a line under it.
class _Front extends StatelessWidget {
  final SortScene scene;
  final int index;
  final Color ink;
  const _Front({required this.scene, required this.index, required this.ink});

  @override
  Widget build(BuildContext context) {
    final item = scene.items[index];
    final small = AppText.label(size: 10.5, color: ink.withValues(alpha: 0.62));
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  scene.tag.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.fade,
                  softWrap: false,
                  style: small,
                ),
              ),
              Text(
                context.l10n.sceneNOfM(index + 1, scene.items.length).toUpperCase(),
                style: small.copyWith(fontWeight: FontWeight.w800, color: ink),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(height: 1.5, color: ink.withValues(alpha: 0.2)),
          const SizedBox(height: 8),
          Expanded(
            child: Align(
              alignment: Alignment.bottomLeft,
              child: _FitText(
                text: item.text,
                max: 54,
                min: 20,
                lines: 2,
                align: Alignment.bottomLeft,
                style: (s) => AppText.display(
                  size: s,
                  weight: FontWeight.w800,
                  height: 1.0,
                  spacing: -s * 0.025,
                  color: ink,
                ),
              ),
            ),
          ),
          if (item.note.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              item.note,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppText.body(
                size: 14.5,
                weight: FontWeight.w500,
                height: 1.3,
                color: ink.withValues(alpha: 0.82),
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Text('← ', style: small.copyWith(letterSpacing: 0)),
              Text(context.l10n.sceneSwipeHint.toUpperCase(), style: small),
              Text(' →', style: small.copyWith(letterSpacing: 0)),
            ],
          ),
        ],
      ),
    );
  }
}

/// The back of a slip, dark: where the thing really belongs, in large type,
/// and the one line that says why. A mark in the corner says whether the
/// reader's call was right, and a wrong call is also said in words.
class _Back extends StatelessWidget {
  final SortScene scene;
  final int index;
  final SortSide call;
  final Color ink;
  final Color ground;
  const _Back({
    required this.scene,
    required this.index,
    required this.call,
    required this.ink,
    required this.ground,
  });

  @override
  Widget build(BuildContext context) {
    final item = scene.items[index];
    final right = call == item.pile;
    final small = AppText.label(size: 10.5, color: ground.withValues(alpha: 0.7));
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.text.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.fade,
                  softWrap: false,
                  style: small.copyWith(fontWeight: FontWeight.w800, color: ground),
                ),
              ),
              _Mark(right: right, color: ground, size: 26),
            ],
          ),
          const SizedBox(height: 6),
          Container(height: 1.5, color: ground.withValues(alpha: 0.25)),
          Expanded(
            child: LayoutBuilder(
              // The wrong call is said in words only where there is room
              // for it above the pile's name; the mark says it anyway.
              builder: (context, box) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (!right && box.maxHeight >= 56)
                    Text(
                      '${context.l10n.sceneYou}: ${scene.nameOf(call).toUpperCase()}',
                      maxLines: 1,
                      style: small.copyWith(
                        decoration: TextDecoration.lineThrough,
                        decorationColor: ground,
                      ),
                    ),
                  Flexible(
                    child: _FitText(
                      text: '${scene.nameOf(item.pile)}.',
                      max: 52,
                      min: 18,
                      align: Alignment.bottomLeft,
                      style: (s) => AppText.display(
                        size: s,
                        weight: FontWeight.w800,
                        height: 1.05,
                        spacing: -s * 0.025,
                        color: ground,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            item.verdict,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: AppText.body(
              size: 15,
              weight: FontWeight.w600,
              height: 1.3,
              color: ground,
            ),
          ),
        ],
      ),
    );
  }
}

/// The reader's call, slammed on the slip: the pile's name in a ruled box,
/// at an angle, on the side away from where it is going.
class _Stamp extends StatelessWidget {
  final String text;
  final SortSide side;
  final double opacity;
  final double scale;
  final Color ink;
  final Color ground;
  const _Stamp({
    required this.text,
    required this.side,
    required this.opacity,
    required this.scale,
    required this.ink,
    required this.ground,
  });

  @override
  Widget build(BuildContext context) {
    final right = side == SortSide.right;
    return Positioned(
      top: 38,
      left: right ? 14 : null,
      right: right ? null : 14,
      child: Opacity(
        opacity: opacity,
        child: Transform.rotate(
          angle: (right ? -11 : 11) * math.pi / 180,
          child: Transform.scale(
            scale: scale,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: ground.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: ink, width: 3.5),
              ),
              child: Text(
                text.toUpperCase(),
                style: AppText.display(
                  size: 24,
                  weight: FontWeight.w900,
                  height: 1,
                  spacing: 1.2,
                  color: ink,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A pile while the deck is played: a tray to throw at, and a button.
class _Tray extends StatelessWidget {
  final String name;
  final SortSide side;
  final int count;
  final double lit;
  final Color ink;
  final Color ground;
  final VoidCallback onTap;
  const _Tray({
    required this.name,
    required this.side,
    required this.count,
    required this.lit,
    required this.ink,
    required this.ground,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // The fill comes up with the drag; the type flips at once at half way,
    // so it is never a mid-tone on a mid-tone.
    final fill = Color.lerp(ground, ink, lit)!;
    final fg = lit > 0.5 ? ground : ink;
    final left = side == SortSide.left;
    final arrow = Text(
      left ? '←' : '→',
      style: AppText.body(size: 20, weight: FontWeight.w700, height: 1, color: fg),
    );
    final label = Expanded(
      child: _FitText(
        text: name,
        max: 21,
        min: 13,
        align: left ? Alignment.centerLeft : Alignment.centerRight,
        style: (s) => AppText.display(
          size: s,
          weight: FontWeight.w800,
          height: 1,
          spacing: -s * 0.02,
          color: fg,
        ),
      ),
    );
    final tally = Text(
      '$count',
      style: AppText.display(
        size: 15,
        weight: FontWeight.w800,
        height: 1,
        color: fg.withValues(alpha: 0.6),
      ),
    );
    return Semantics(
      button: true,
      label: name,
      value: '$count',
      onTap: onTap,
      child: ExcludeSemantics(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: ink, width: 2),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: left
                  ? [arrow, const SizedBox(width: 8), label, const SizedBox(width: 8), tally]
                  : [tally, const SizedBox(width: 8), label, const SizedBox(width: 8), arrow],
            ),
          ),
        ),
      ),
    );
  }
}

/// One slip in a settled pile. A wrong call carries a solid ink tab with a
/// cross, so it is told by shape and not only by where it moved.
class _Mini extends StatelessWidget {
  final String text;
  final String? said;
  final double textSize;
  final bool wrong;
  final double mark;
  final Color ink;
  final Color ground;
  const _Mini({
    required this.text,
    required this.textSize,
    required this.wrong,
    this.said,
    required this.mark,
    required this.ink,
    required this.ground,
  });

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(10);
    return Container(
      decoration: BoxDecoration(
        color: ink,
        borderRadius: r,
        boxShadow: const [
          BoxShadow(color: Color(0x22000000), blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      padding: const EdgeInsets.only(bottom: 3),
      child: Container(
        decoration: BoxDecoration(
          color: ground,
          borderRadius: r,
          border: Border.all(color: ink, width: 1.5),
        ),
        child: ClipRRect(
          borderRadius: r,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(12, textSize * 0.32, 6, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: textSize * 1.2,
                        child: _FitText(
                          text: text,
                          max: textSize,
                          min: 10,
                          align: Alignment.topLeft,
                          style: (s) => AppText.display(
                            size: s,
                            weight: FontWeight.w700,
                            height: 1.15,
                            spacing: -0.2,
                            color: ink,
                          ),
                        ),
                      ),
                      if (said != null)
                        Opacity(
                          opacity: mark.clamp(0.0, 1.0),
                          child: Text(
                            said!,
                            maxLines: 1,
                            overflow: TextOverflow.fade,
                            softWrap: false,
                            style: AppText.label(
                              size: 9.5,
                              color: ink.withValues(alpha: 0.7),
                            ).copyWith(
                              decoration: TextDecoration.lineThrough,
                              decorationColor: ink.withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              if (wrong)
                Container(
                  width: (textSize + 12) * mark.clamp(0.0, 1.2),
                  color: ink,
                  alignment: Alignment.topCenter,
                  padding: EdgeInsets.only(top: textSize * 0.4),
                  child: mark > 0.4
                      ? Transform.scale(
                          scale: mark,
                          child: _Mark(
                            right: false,
                            color: ground,
                            size: textSize * 0.8,
                            ring: false,
                          ),
                        )
                      : null,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A tick or a cross, drawn rather than set, so it is the same on every
/// phone; optionally in a ring.
class _Mark extends StatelessWidget {
  final bool right;
  final Color color;
  final double size;
  final bool ring;
  const _Mark({
    required this.right,
    required this.color,
    required this.size,
    this.ring = true,
  });

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(
      painter: _MarkPainter(right: right, color: color, ring: ring),
    ),
  );
}

class _MarkPainter extends CustomPainter {
  final bool right;
  final Color color;
  final bool ring;
  _MarkPainter({required this.right, required this.color, required this.ring});

  final Paint _pen = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    _pen
      ..color = color
      ..strokeWidth = s * (ring ? 0.09 : 0.16);
    if (ring) canvas.drawCircle(size.center(Offset.zero), s / 2 - s * 0.05, _pen);
    final k = ring ? 0.3 : 0.12;
    _pen.strokeWidth = s * (ring ? 0.11 : 0.18);
    if (right) {
      canvas.drawPath(
        Path()
          ..moveTo(s * k, s * 0.52)
          ..lineTo(s * 0.44, s * (1 - k - 0.02))
          ..lineTo(s * (1 - k + 0.02), s * (k + 0.04)),
        _pen,
      );
    } else {
      final a = s * (k + 0.04), b = s * (1 - k - 0.04);
      canvas.drawLine(Offset(a, a), Offset(b, b), _pen);
      canvas.drawLine(Offset(b, a), Offset(a, b), _pen);
    }
  }

  @override
  bool shouldRepaint(_MarkPainter old) =>
      old.right != right || old.color != color || old.ring != ring;
}

/// Text set as large as its box allows, within a band, without breaking a
/// word: a short word on a slip is a poster, a long one still fits.
class _FitText extends StatelessWidget {
  final String text;
  final double max;
  final double min;
  final int lines;
  final Alignment align;
  final TextStyle Function(double size) style;
  const _FitText({
    required this.text,
    required this.max,
    required this.min,
    required this.style,
    this.lines = 1,
    this.align = Alignment.centerLeft,
  });

  bool _fits(double s, double w, double h) {
    final st = style(s);
    // No single word may be wider than the box, or it would break inside.
    for (final word in text.split(' ')) {
      if (_measure(word, st, double.infinity, 1).width > w) return false;
    }
    final p = TextPainter(
      text: TextSpan(text: text, style: st),
      textDirection: TextDirection.ltr,
      maxLines: lines,
    )..layout(maxWidth: w);
    return !p.didExceedMaxLines && p.height <= h;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final w = box.maxWidth, h = box.maxHeight;
        var size = min;
        if (w.isFinite && w > 0) {
          if (_fits(max, w, h)) {
            size = max;
          } else {
            var lo = min, hi = max;
            while (hi - lo > 0.5) {
              final mid = (lo + hi) / 2;
              if (_fits(mid, w, h)) {
                lo = mid;
              } else {
                hi = mid;
              }
            }
            size = lo;
          }
        }
        return Align(
          alignment: align,
          child: Text(
            text,
            maxLines: lines,
            overflow: TextOverflow.ellipsis,
            textAlign: align.x > 0 ? TextAlign.right : TextAlign.left,
            style: style(size),
          ),
        );
      },
    );
  }
}

Size _measure(String text, TextStyle style, double maxWidth, int lines) {
  final p = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
    maxLines: lines,
  )..layout(maxWidth: maxWidth);
  return p.size;
}
