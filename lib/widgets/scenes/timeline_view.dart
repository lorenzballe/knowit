import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/l10n.dart';
import '../../models/scene.dart';
import '../../theme.dart';

/// Plays a [TimelineScene]: one lane per event over a shared time axis.
///
/// Each lane is a name, its year, and a track. The reader drags a handle
/// along every track — the whole lane is the target, so a thumb need not
/// find the knob — and locks the guesses in when all are placed. Then, lane
/// by lane, the true position slides out of the reader's handle, which stays
/// behind as a ring, and the stretch between them fills in with its size
/// written on it. The lane the reader missed by most among those with a
/// note is lit, and its note is said underneath. Tapping another lane with
/// a note says that one instead.
///
/// The axis is the place-it ruler laid on its side across every lane: the
/// same baseline weight, the same round knob with the card's colour for an
/// eye, a tick click under the thumb at each mark. Its marks run up through
/// all the lanes as hairlines, so a guess is read against the others as
/// well as against the dates — which is where the surprise is.
class TimelineSceneView extends StatefulWidget {
  final TimelineScene scene;
  final Color ink;
  final Color ground;
  const TimelineSceneView({
    super.key,
    required this.scene,
    required this.ink,
    required this.ground,
  });

  @override
  State<TimelineSceneView> createState() => _TimelineSceneViewState();
}

/// Timing of the reveal, shared by the painter and the readouts so the
/// year changes as its marker lands: each lane's truth slides for [_slide]
/// and the next one starts [_stagger] later; the note follows the last.
const _slide = 700.0;
const _stagger = 170.0;
const _noteTail = 320.0;

double _revealMs(int lanes) => _slide + _stagger * (lanes - 1) + _noteTail;

/// 0..1 progress of lane [i]'s slide at reveal value [v].
double _phase(double v, int i, int lanes) =>
    ((v * _revealMs(lanes) - i * _stagger) / _slide).clamp(0.0, 1.0);

/// Where a lane's parts sit, worked out once per layout and read by the
/// painter, the readouts and the hit test alike — so the knob the finger
/// moves is the knob that is drawn.
@immutable
class _Geometry {
  final double width;
  final double laneH;
  final double textH;
  final double trackZone;
  final double r;
  final int lanes;

  /// Room at each end of the axis for a knob to sit on the first or last
  /// year without being cut in half.
  static const pad = 14.0;

  const _Geometry({
    required this.width,
    required this.laneH,
    required this.textH,
    required this.trackZone,
    required this.r,
    required this.lanes,
  });

  factory _Geometry.of(double width, double height, int lanes) {
    final laneH = height / lanes;
    final textH = (laneH * 0.42).clamp(18.0, 30.0);
    final trackZone = (laneH - textH).clamp(14.0, 46.0);
    return _Geometry(
      width: width,
      laneH: laneH,
      textH: textH,
      trackZone: trackZone,
      r: (trackZone / 2 - 3).clamp(7.0, 13.0),
      lanes: lanes,
    );
  }

  /// A tall lane keeps its name and track together in its middle, rather
  /// than a name at the top and a track far below.
  double top(int i) => i * laneH + math.max(0, (laneH - textH - trackZone) / 2);
  double trackY(int i) => top(i) + textH + trackZone / 2;
  double x(double t) => pad + t * (width - pad * 2);
  double tAt(double dx) => ((dx - pad) / (width - pad * 2)).clamp(0.0, 1.0);
  int laneAt(double dy) => (dy / laneH).floor().clamp(0, lanes - 1);

  @override
  bool operator ==(Object other) =>
      other is _Geometry &&
      other.width == width &&
      other.laneH == laneH &&
      other.lanes == lanes;
  @override
  int get hashCode => Object.hash(width, laneH, lanes);
}

class _TimelineSceneViewState extends State<TimelineSceneView>
    with TickerProviderStateMixin {
  /// The reader's year for each event, already rounded as it is shown, or
  /// null while that event has not been touched.
  late List<double?> _guess = List.filled(widget.scene.events.length, null);
  bool _locked = false;

  /// The lane whose note is said; chosen at the reveal, moved by a tap.
  int? _lit;
  int _dragLane = 0;

  late final AnimationController _reveal = AnimationController(
    vsync: this,
    duration: Duration(
      milliseconds: _revealMs(widget.scene.events.length).round(),
    ),
  );

  // A lean of the first knob when the card arrives, like the slider's, so
  // the lanes are seen to be controls. The first third is a wait, held in
  // the controller rather than a Timer, which would outlive a disposed
  // widget and hang a widget test.
  late final AnimationController _nudge = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2100),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started && !MediaQuery.disableAnimationsOf(context)) {
      _started = true;
      _nudge.forward();
    }
  }

  @override
  void dispose() {
    _reveal.dispose();
    _nudge.dispose();
    super.dispose();
  }

  TimelineScene get _s => widget.scene;
  int get _placed => _guess.where((g) => g != null).length;

  void _place(int lane, double t) {
    if (_locked) return;
    final s = _s;
    final v = s.snap(s.valueAt(t));
    final was = _guess[lane];
    if (was == v) return;
    // A click as the knob first lands and at every mark it passes: the
    // hand feels the axis the way it feels the place-it ruler's decades.
    final ticks = s.ticks.map(s.t);
    int passed(double? g) =>
        g == null ? -1 : ticks.where((k) => k <= s.t(g)).length;
    if (was == null || passed(was) != passed(v)) {
      HapticFeedback.selectionClick();
    }
    _nudge.stop();
    setState(() => _guess[lane] = v);
  }

  /// Where a screen reader's swipe takes a lane: a twentieth of the axis,
  /// from the middle if it has not been placed.
  double _stepped(int lane, int dir) {
    final g = _guess[lane];
    final t = g == null ? 0.5 : (_s.t(g) + dir * 0.05).clamp(0.0, 1.0);
    return _s.snap(_s.valueAt(t));
  }

  void _step(int lane, int dir) => _place(lane, _s.t(_stepped(lane, dir)));

  void _lock() {
    if (_locked || _placed < _s.events.length) return;
    HapticFeedback.lightImpact();
    final s = _s;
    // The note said first is for the event this reader missed by most, of
    // those the writer knew people miss.
    int? lit;
    var worst = -1.0;
    for (var i = 0; i < s.events.length; i++) {
      final e = s.events[i];
      if (e.note.isEmpty) continue;
      final miss = (s.t(_guess[i]!) - s.t(e.at)).abs();
      if (miss > worst) {
        worst = miss;
        lit = i;
      }
    }
    setState(() {
      _locked = true;
      _lit = lit;
    });
    if (MediaQuery.disableAnimationsOf(context)) {
      _reveal.value = 1;
    } else {
      _reveal.forward(from: 0);
    }
  }

  void _again() {
    HapticFeedback.selectionClick();
    _reveal.value = 0;
    setState(() {
      _locked = false;
      _lit = null;
      _guess = List.filled(_s.events.length, null);
    });
  }

  void _light(int lane) {
    if (!_locked || _s.events[lane].note.isEmpty || _lit == lane) return;
    HapticFeedback.selectionClick();
    setState(() => _lit = lane);
  }

  @override
  Widget build(BuildContext context) {
    final ink = widget.ink;
    final l10n = context.l10n;
    return LayoutBuilder(
      builder: (context, box) {
        final height = box.maxHeight.isFinite ? box.maxHeight : 380.0;
        // The foot holds the lock, then the note: three short lines.
        final footH = height < 320 ? 54.0 : 62.0;
        const axisH = 22.0;
        final lanesH = math.max(0.0, height - axisH - footH - 6);
        final g = _Geometry.of(box.maxWidth, lanesH, _s.events.length);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: lanesH, child: _lanes(g)),
            SizedBox(
              height: axisH,
              child: ExcludeSemantics(
                child: CustomPaint(
                  size: Size.infinite,
                  painter: _AxisPainter(scene: _s, geometry: g, ink: ink),
                ),
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(height: footH, child: _foot(l10n)),
          ],
        );
      },
    );
  }

  Widget _lanes(_Geometry g) {
    final s = _s;
    final ink = widget.ink;
    final labelSize = (g.textH * 0.6).clamp(13.0, 17.0);
    final yearSize = (g.textH * 0.8).clamp(15.0, 24.0);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      // Sideways is the scene's: it claims the drag before the deck's pan
      // does, so moving a knob never throws the card. Up and down are left
      // to the deck.
      onHorizontalDragStart: (d) {
        _dragLane = g.laneAt(d.localPosition.dy);
        _place(_dragLane, g.tAt(d.localPosition.dx));
      },
      onHorizontalDragUpdate: (d) =>
          _place(_dragLane, g.tAt(d.localPosition.dx)),
      // A tap inside the lanes is also the scene's, so it places a knob (or
      // picks a note) rather than turning the card over.
      onTapUp: (d) {
        final lane = g.laneAt(d.localPosition.dy);
        if (_locked) {
          _light(lane);
        } else {
          _place(lane, g.tAt(d.localPosition.dx));
        }
      },
      child: Stack(
        children: [
          Positioned.fill(
            child: ExcludeSemantics(
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: _LanesPainter(
                    picture: _Picture(
                      geometry: g,
                      ticks: [for (final k in s.ticks) s.t(k)],
                      guesses: [
                        for (final v in _guess) v == null ? null : s.t(v),
                      ],
                      truths: [for (final e in s.events) s.t(e.at)],
                      gaps: [
                        for (var i = 0; i < s.events.length; i++)
                          _guess[i] == null
                              ? ''
                              : s.gap(_guess[i]!, s.events[i].at),
                      ],
                      locked: _locked,
                      lit: _lit,
                    ),
                    reveal: _reveal,
                    nudge: _nudge,
                    ink: ink,
                    ground: widget.ground,
                  ),
                ),
              ),
            ),
          ),
          for (var i = 0; i < s.events.length; i++)
            Positioned(
              left: 0,
              right: 0,
              top: i * g.laneH,
              height: g.laneH,
              child: _lane(i, g, labelSize, yearSize),
            ),
        ],
      ),
    );
  }

  Widget _lane(int i, _Geometry g, double labelSize, double yearSize) {
    final s = _s;
    final e = s.events[i];
    final ink = widget.ink;
    final guess = _guess[i];
    final still = MediaQuery.disableAnimationsOf(context);
    return AnimatedBuilder(
      animation: _reveal,
      builder: (context, _) {
        final shown =
            _locked && _phase(_reveal.value, i, s.events.length) > .55;
        // The lit lane stands out only once every truth has landed, so the
        // reveal does not give away which miss the note is about.
        final settled =
            _reveal.value >= 1 - _noteTail / _revealMs(s.events.length);
        final dim = _locked && settled && _lit != null && _lit != i;
        final value = !_locked
            ? (guess == null ? '?' : s.say(guess))
            : '${s.say(e.at)}, ${context.l10n.sceneYou.toLowerCase()} '
                  '${s.say(guess!)}';
        return Semantics(
          slider: !_locked,
          button: _locked && e.note.isNotEmpty,
          label: e.label,
          value: value,
          increasedValue: _locked ? null : s.say(_stepped(i, 1)),
          decreasedValue: _locked ? null : s.say(_stepped(i, -1)),
          onIncrease: _locked ? null : () => _step(i, 1),
          onDecrease: _locked ? null : () => _step(i, -1),
          onTap: _locked && e.note.isNotEmpty ? () => _light(i) : null,
          child: ExcludeSemantics(
            child: Container(
              alignment: Alignment.topLeft,
              padding: EdgeInsets.only(top: g.top(i) - i * g.laneH),
              child: SizedBox(
                height: g.textH,
                child: AnimatedOpacity(
                  duration: Duration(milliseconds: still ? 0 : 220),
                  opacity: dim ? 0.55 : 1,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(width: _Geometry.pad - 4),
                      Expanded(
                        child: Text(
                          e.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.body(
                            size: labelSize,
                            weight: FontWeight.w700,
                            height: 1.1,
                            color: ink,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      AnimatedSwitcher(
                        duration: Duration(milliseconds: still ? 0 : 260),
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
                        child: _year(
                          key: ValueKey(shown),
                          text: shown
                              ? s.say(e.at)
                              : guess == null
                              ? '?'
                              : s.say(guess),
                          size: yearSize,
                          faint: !shown && (guess == null || _locked),
                        ),
                      ),
                      const SizedBox(width: _Geometry.pad - 4),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// The year at the end of a lane: Fraunces, heavy, with the deep-time
  /// unit after it smaller, the way the slider writes its readout.
  Widget _year({
    required Key key,
    required String text,
    required double size,
    required bool faint,
  }) {
    final ink = widget.ink.withValues(alpha: faint ? 0.5 : 1);
    return Row(
      key: key,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          text,
          style: AppText.display(
            size: size,
            weight: FontWeight.w800,
            height: 1,
            spacing: -0.4,
            color: ink,
          ),
        ),
        if (_s.unit.isNotEmpty && text != '?') ...[
          const SizedBox(width: 4),
          Text(
            _s.unit,
            style: AppText.body(
              size: size * 0.56,
              weight: FontWeight.w600,
              color: ink.withValues(alpha: ink.a * 0.65),
            ),
          ),
        ],
      ],
    );
  }

  Widget _foot(AppLocalizations l10n) {
    final ink = widget.ink;
    final still = MediaQuery.disableAnimationsOf(context);
    final ready = _placed == _s.events.length;
    final Widget child;
    if (!_locked) {
      child = Row(
        key: const ValueKey('placing'),
        children: [
          Expanded(
            child: Text(
              l10n.sceneNOfM(_placed, _s.events.length),
              style: AppText.body(
                size: 14,
                weight: FontWeight.w600,
                color: ink.withValues(alpha: 0.62),
              ),
            ),
          ),
          Semantics(
            button: true,
            enabled: ready,
            label: l10n.sceneLockIn,
            onTap: ready ? _lock : null,
            child: ExcludeSemantics(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _lock,
                // Waiting, it is an outline; once every event is placed it
                // fills with ink — a change of shape, not only of shade.
                child: TweenAnimationBuilder<double>(
                  tween: Tween(end: ready ? 1 : 0),
                  duration: Duration(milliseconds: still ? 0 : 200),
                  curve: Curves.easeOut,
                  builder: (context, on, _) => Container(
                    constraints: const BoxConstraints(minHeight: 44),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: ink.withValues(alpha: on),
                      border: Border.all(
                        color: ink.withValues(alpha: 0.3 + 0.7 * on),
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      l10n.sceneLockIn,
                      style: AppText.label(
                        size: 11.5,
                        weight: FontWeight.w800,
                        spacing: 1.1,
                        color: Color.lerp(
                          ink.withValues(alpha: 0.5),
                          widget.ground,
                          on,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    } else {
      final note = _lit == null ? '' : _s.events[_lit!].note;
      child = Row(
        key: const ValueKey('said'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: FadeTransition(
              opacity: CurvedAnimation(
                parent: _reveal,
                curve: Interval(
                  1 - _noteTail / _revealMs(_s.events.length),
                  1,
                  curve: Curves.easeOut,
                ),
              ),
              child: AnimatedSwitcher(
                duration: Duration(milliseconds: still ? 0 : 240),
                child: Semantics(
                  key: ValueKey(note),
                  liveRegion: true,
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Text(
                      note,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.body(
                        size: 14,
                        weight: FontWeight.w600,
                        height: 1.3,
                        color: ink.withValues(alpha: 0.92),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Semantics(
            button: true,
            label: l10n.sceneTryAgain,
            onTap: _again,
            child: ExcludeSemantics(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _again,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: ink.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(Icons.replay_rounded, size: 20, color: ink),
                ),
              ),
            ),
          ),
        ],
      );
    }
    return AnimatedSwitcher(
      duration: Duration(milliseconds: still ? 0 : 220),
      child: child,
    );
  }
}

/// What the lanes painter draws, apart from the motion it listens to:
/// positions already turned into 0..1 along the axis and the gaps already
/// written out, so the painter only draws.
@immutable
class _Picture {
  final _Geometry geometry;
  final List<double> ticks;
  final List<double?> guesses;
  final List<double> truths;
  final List<String> gaps;
  final bool locked;
  final int? lit;

  const _Picture({
    required this.geometry,
    required this.ticks,
    required this.guesses,
    required this.truths,
    required this.gaps,
    required this.locked,
    required this.lit,
  });

  @override
  bool operator ==(Object other) =>
      other is _Picture &&
      other.geometry == geometry &&
      other.locked == locked &&
      other.lit == lit &&
      _same(other.guesses, guesses) &&
      _same(other.truths, truths) &&
      _same(other.gaps, gaps) &&
      _same(other.ticks, ticks);
  @override
  int get hashCode => Object.hash(
    geometry,
    locked,
    lit,
    Object.hashAll(guesses),
    Object.hashAll(gaps),
  );

  static bool _same(List<Object?> a, List<Object?> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

class _LanesPainter extends CustomPainter {
  final _Picture picture;
  final Animation<double> reveal;
  final Animation<double> nudge;
  final Color ink;
  final Color ground;

  _LanesPainter({
    required this.picture,
    required this.reveal,
    required this.nudge,
    required this.ink,
    required this.ground,
  }) : super(repaint: Listenable.merge([reveal, nudge]));

  final Paint _hair = Paint()..strokeWidth = 1;
  final Paint _track = Paint()
    ..strokeWidth = 2
    ..strokeCap = StrokeCap.round;
  final Paint _fill = Paint();
  final Paint _ring = Paint()..style = PaintingStyle.stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final g = picture.geometry;
    final n = picture.truths.length;

    // The axis marks, carried up through every lane.
    _hair.color = ink.withValues(alpha: 0.1);
    for (final t in picture.ticks) {
      final x = g.x(t);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), _hair);
    }

    // The first knob leans a little way along and back when the card
    // arrives, while nobody has touched anything.
    final p = ((nudge.value * 3) - 1).clamp(0.0, 2.0) / 2;
    final lean = Curves.easeInOut.transform(p < .5 ? p * 2 : 2 - p * 2) * 0.1;

    for (var i = 0; i < n; i++) {
      final y = g.trackY(i);
      _track.color = ink.withValues(alpha: 0.28);
      canvas.drawLine(Offset(g.x(0), y), Offset(g.x(1), y), _track);

      final guess = picture.guesses[i];
      if (guess == null) {
        // Not yet placed: a hollow knob mid-axis, waiting for a thumb.
        final untouched = picture.guesses.every((v) => v == null);
        final c = Offset(g.x(0.5 + (i == 0 && untouched ? lean : 0)), y);
        _fill.color = ground;
        canvas.drawCircle(c, g.r, _fill);
        _ring
          ..color = ink.withValues(alpha: 0.5)
          ..strokeWidth = 2;
        canvas.drawCircle(c, g.r - 1, _ring);
        continue;
      }

      final gx = g.x(guess);
      if (!picture.locked) {
        _knob(canvas, Offset(gx, y), g.r);
        continue;
      }

      // The reveal: the truth slides out of the reader's knob, which stays
      // behind as a ring, and the gap between them fills in.
      final ph = _phase(reveal.value, i, n);
      final eased = Curves.easeOutCubic.transform(ph);
      final tx = g.x(guess + (picture.truths[i] - guess) * eased);
      final lit =
          picture.lit == i && reveal.value >= 1 - _noteTail / _revealMs(n);
      final h = g.r * 1.5;
      _fill.color = ink.withValues(alpha: lit ? 0.26 : 0.17);
      canvas.drawRRect(
        RRect.fromLTRBR(
          math.min(gx, tx),
          y - h / 2,
          math.max(gx, tx),
          y + h / 2,
          Radius.circular(h / 2),
        ),
        _fill,
      );
      _fill.color = ground;
      canvas.drawCircle(Offset(gx, y), g.r * 0.72, _fill);
      _ring
        ..color = ink.withValues(alpha: 0.75)
        ..strokeWidth = 2.5;
      canvas.drawCircle(Offset(gx, y), g.r * 0.72, _ring);
      _knob(canvas, Offset(tx, y), g.r);

      // The size of the miss, once the truth has landed: on the band when
      // it fits, otherwise beside the ring on its far side from the truth.
      final gap = picture.gaps[i];
      final show = ((ph - 0.8) / 0.2).clamp(0.0, 1.0);
      if (gap.isEmpty || show == 0) continue;
      final tp = TextPainter(
        text: TextSpan(
          text: gap,
          style: AppText.label(
            size: 10.5,
            weight: FontWeight.w800,
            spacing: 0.4,
            color: ink.withValues(alpha: show),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final inner = (tx - gx).abs() - g.r * 1.72 - 8;
      double left;
      if (inner >= tp.width) {
        left = (gx + tx) / 2 - tp.width / 2 + (tx > gx ? -1 : 1) * g.r * 0.14;
      } else {
        final away = tx >= gx ? -1.0 : 1.0;
        left = away < 0 ? gx - g.r - 6 - tp.width : gx + g.r + 6;
        if (left < 0 || left + tp.width > size.width) {
          // No room behind the ring: past the truth instead.
          left = away < 0 ? tx + g.r + 6 : tx - g.r - 6 - tp.width;
        }
      }
      tp.paint(
        canvas,
        Offset(left.clamp(0.0, size.width - tp.width), y - tp.height / 2),
      );
    }
  }

  /// The place-it knob: solid ink, a soft shadow, the card's colour as eye.
  void _knob(Canvas canvas, Offset c, double r) {
    _fill.color = const Color(0x33000000);
    canvas.drawCircle(c + const Offset(0, 2), r, _fill);
    _fill.color = ink;
    canvas.drawCircle(c, r, _fill);
    _fill.color = ground;
    canvas.drawCircle(c, r * 0.36, _fill);
  }

  @override
  bool shouldRepaint(_LanesPainter old) =>
      old.picture != picture || old.ink != ink || old.ground != ground;
}

/// The marks under the lanes: a short tick and its year, at the same x as
/// the hairlines above, edge labels kept inside the card and any label
/// that would touch its neighbour left out.
class _AxisPainter extends CustomPainter {
  final TimelineScene scene;
  final _Geometry geometry;
  final Color ink;
  _AxisPainter({
    required this.scene,
    required this.geometry,
    required this.ink,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final g = geometry;
    final tick = Paint()
      ..color = ink.withValues(alpha: 0.5)
      ..strokeWidth = 1.5;
    canvas.drawLine(
      Offset(g.x(0), 0),
      Offset(g.x(1), 0),
      Paint()
        ..color = ink.withValues(alpha: 0.18)
        ..strokeWidth = 1,
    );
    var lastRight = -double.infinity;
    for (final v in scene.ticks) {
      final x = g.x(scene.t(v));
      canvas.drawLine(Offset(x, 0), Offset(x, 5), tick);
      final tp = TextPainter(
        text: TextSpan(
          text: scene.tickLabel(v),
          style: AppText.label(
            size: 10.5,
            spacing: 0.4,
            color: ink.withValues(alpha: 0.62),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final left = (x - tp.width / 2).clamp(0.0, size.width - tp.width);
      if (left < lastRight + 8) continue;
      tp.paint(canvas, Offset(left, 8));
      lastRight = left + tp.width;
    }
  }

  @override
  bool shouldRepaint(_AxisPainter old) =>
      old.scene != scene || old.geometry != geometry || old.ink != ink;
}
