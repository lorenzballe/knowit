import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' show PointMode, lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/l10n.dart';
import '../../models/scene.dart';
import '../../theme.dart';

/// Plays a [StoryScene]: what happens next?
///
/// Top to bottom: a row of dashes, one per stop, that fills as the story
/// goes on; a drawing on a halftone disc; the fact in small capitals; the
/// line, big; a hint at the foot. A tap anywhere in the scene (or a swipe
/// to the left) goes on; a swipe to the right goes back.
///
/// The scenes do not slide past like slides. The drawing is one object
/// that turns into the next: every glyph is line art, and its strokes
/// travel to become the strokes of the next one, while the disc behind it
/// drifts a little round it. The old line lifts away and the new one rises
/// into place line by line, as if from behind a mask.
///
/// At the stop the drawing becomes a question mark, the question takes the
/// line's place and the outcomes rise as buttons. A tap commits: the button
/// fills, the question mark turns into the outcome's drawing, the outcome
/// rises, then what the reader picked (struck through if it did not
/// happen), then the line that names why.
///
/// Until the outcome has landed, taps and horizontal drags in the scene
/// stay in the scene; afterwards a tap turns the card and a swipe moves the
/// deck, as on any card.
class StorySceneView extends StatefulWidget {
  final StoryScene scene;
  final Color ink;
  final Color ground;
  const StorySceneView({
    super.key,
    required this.scene,
    required this.ink,
    required this.ground,
  });

  @override
  State<StorySceneView> createState() => _StorySceneViewState();
}

class _StorySceneViewState extends State<StorySceneView>
    with SingleTickerProviderStateMixin {
  static const _change = Duration(milliseconds: 780);
  static const _entrance = Duration(milliseconds: 1100);
  static const _landing = Duration(milliseconds: 1700);

  /// One controller for every change: from [_from] to [_at], 0 to 1.
  late final AnimationController _run = AnimationController(
    vsync: this,
    duration: _entrance,
  );

  /// The stop on show: a scene, the question ([StoryScene.askAt]) or the
  /// outcome ([StoryScene.outcomeAt]).
  int _at = 0;

  /// The stop being left, while [_run] runs; null on the first arrival,
  /// when the drawing draws itself in.
  int? _from;

  /// The outcome the reader committed to.
  int? _pick;

  /// The button under a finger, for the press state.
  int? _pressed;

  /// How far a horizontal drag has travelled.
  double _drag = 0;

  bool _started = false;

  /// Layouts, worked out once per size: fitting type means measuring it.
  final Map<int, _Plan> _plans = {};
  Size _planned = Size.zero;
  TextScaler _scaler = TextScaler.noScaling;

  StoryScene get _s => widget.scene;

  bool get _calm => MediaQuery.disableAnimationsOf(context);

  bool get _landed => _at == _s.outcomeAt && _run.isCompleted;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (_calm) {
      _run.value = 1;
    } else {
      _run.forward(from: 0);
    }
  }

  @override
  void didUpdateWidget(StorySceneView old) {
    super.didUpdateWidget(old);
    if (!identical(old.scene, widget.scene)) {
      _at = 0;
      _from = null;
      _pick = null;
      _pressed = null;
      _plans.clear();
      _run.value = 1;
    }
  }

  @override
  void dispose() {
    _run.dispose();
    super.dispose();
  }

  /// Moves to [to]. A change still running is cut to its end first, so a
  /// quick reader is never made to wait.
  void _go(int to) {
    if (to == _at) return;
    setState(() {
      _from = _at;
      _at = to;
    });
    if (_calm) {
      _run.value = 1;
      return;
    }
    _run.duration = to == _s.outcomeAt ? _landing : _change;
    _run.forward(from: 0);
  }

  void _next() {
    if (_at >= _s.askAt) return;
    HapticFeedback.selectionClick();
    _go(_at + 1);
  }

  void _back() {
    if (_at == 0 || _at > _s.askAt) return;
    HapticFeedback.selectionClick();
    _go(_at - 1);
  }

  void _choose(int i) {
    if (_pick != null || _at != _s.askAt) return;
    HapticFeedback.lightImpact();
    setState(() {
      _pick = i;
      _pressed = null;
    });
    _go(_s.outcomeAt);
  }

  /// A tap in the scene but off the buttons: on a scene it goes on; while
  /// the outcome is landing it lands it at once.
  void _tap() {
    if (_at < _s.askAt) {
      _next();
    } else if (_at == _s.outcomeAt && !_run.isCompleted) {
      _run.value = 1;
    }
  }

  void _dragEnd(DragEndDetails d) {
    final v = d.primaryVelocity ?? 0;
    final dx = _drag;
    _drag = 0;
    if (dx < -36 || v < -350) {
      _next();
    } else if (dx > 36 || v > 350) {
      _back();
    }
  }

  // ---------------------------------------------------------------- layout

  _Plan _plan(int stop, Size size) {
    if (size != _planned) {
      _plans.clear();
      _planned = size;
    }
    return _plans.putIfAbsent(
      stop,
      () => _Plan.lay(
        _s,
        stop,
        size,
        widget.ink,
        _scaler,
        context.l10n.sceneNOfM(_s.stops, _s.stops).toUpperCase(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    if (scaler != _scaler) {
      _scaler = scaler;
      _plans.clear();
    }
    return LayoutBuilder(
      builder: (context, box) {
        final size = Size(box.maxWidth, box.maxHeight);
        return AnimatedBuilder(
          animation: _run,
          builder: (context, _) => _build(context, size),
        );
      },
    );
  }

  Widget _build(BuildContext context, Size size) {
    final s = _s;
    final ink = widget.ink;
    final ground = widget.ground;
    final t = _run.value;
    final from = _from;
    final landing = _at == s.outcomeAt;
    final to = _plan(_at, size);
    final was = from == null ? null : _plan(from, size);

    // The share of each part of the change, on its own clock.
    double part(double a, double b, [Curve c = Curves.easeOutCubic]) =>
        c.transform(((t - a) / (b - a)).clamp(0.0, 1.0));
    final toOutcome = landing && from != null;
    final morph = part(
      toOutcome ? 0.14 : 0,
      toOutcome ? 0.62 : 0.7,
      Curves.easeInOutCubic,
    );
    final leave = part(
      toOutcome ? 0.1 : 0,
      toOutcome ? 0.38 : 0.3,
      Curves.easeInCubic,
    );
    final arrive = toOutcome ? 0.32 : 0.16;

    final l10n = context.l10n;
    final children = <Widget>[
      // The drawing, the disc and the dashes: one painter, one geometry.
      Positioned.fill(
        child: ExcludeSemantics(
          child: RepaintBoundary(
            child: CustomPaint(
              painter: _StoryPainter(
                ink: ink,
                stops: s.stops,
                filled: lerpDouble(
                  (from ?? -1) + 1.0,
                  _at + 1.0,
                  part(0, 0.6),
                )!,
                stripRight: size.width - to.counterWidth - 12,
                fromGlyph: from == null ? null : _glyphOf(from),
                toGlyph: _glyphOf(_at),
                fromRect: was?.glyph,
                toRect: to.glyph,
                fromAngle: was == null ? null : _angleOf(from!, was, size),
                toAngle: _angleOf(_at, to, size),
                morph: from == null ? 1 : morph,
                drawOn: from == null
                    ? part(0.0, 0.8, Curves.easeInOutCubic)
                    : 1,
              ),
            ),
          ),
        ),
      ),
      // n of m, at the end of the dashes.
      Positioned(
        right: 0,
        top: 0,
        child: ExcludeSemantics(
          child: Text(
            l10n.sceneNOfM(_at + 1, s.stops).toUpperCase(),
            textScaler: _scaler,
            style: _Plan.counterStyle(ink),
          ),
        ),
      ),
    ];

    // The stop being left: it lifts and fades as one piece.
    if (was != null && leave < 1) {
      children.add(
        Positioned.fill(
          child: IgnorePointer(
            child: ExcludeSemantics(
              child: Opacity(
                opacity: 1 - leave,
                child: Transform.translate(
                  offset: Offset(0, -14 * leave),
                  child: Stack(
                    children: _texts(was, from!, ink, ground, 1, size),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    // The stop arriving, part by part.
    final incoming = _texts(to, _at, ink, ground, t, size, arriveAt: arrive);
    children.add(
      Positioned.fill(
        child: Semantics(
          container: true,
          liveRegion: true,
          button: _at < s.askAt,
          label: _spoken(context),
          hint: _at < s.askAt ? l10n.sceneSwipeHint : null,
          onTap: _at < s.askAt ? _next : null,
          child: Stack(children: incoming),
        ),
      ),
    );

    // The hint at the foot, on scenes and at the question.
    if (to.footer != null) {
      final hint = _at < s.askAt ? l10n.sceneSwipeHint : l10n.sceneTapToPick;
      final sameAsBefore =
          was?.footer != null && (from! < s.askAt) == (_at < s.askAt);
      final o = sameAsBefore || from == null ? 1.0 : part(0.3, 0.7);
      children.add(
        Positioned(
          left: 0,
          right: 0,
          top: to.footer,
          child: ExcludeSemantics(
            child: Opacity(
              opacity: o,
              child: Row(
                children: [
                  Text(hint, textScaler: _scaler, style: _Plan.hintStyle(ink)),
                  if (_at < s.askAt) ...[
                    const SizedBox(width: 8),
                    CustomPaint(
                      size: const Size(18, 10),
                      painter: _ArrowPainter(ink.withValues(alpha: 0.55)),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      excludeFromSemantics: true,
      onTap: _landed ? null : _tap,
      onHorizontalDragStart: _landed ? null : (_) => _drag = 0,
      onHorizontalDragUpdate: _landed ? null : (d) => _drag += d.delta.dx,
      onHorizontalDragEnd: _landed ? null : _dragEnd,
      child: SizedBox.fromSize(
        size: size,
        child: Stack(clipBehavior: Clip.none, children: children),
      ),
    );
  }

  StoryGlyph _glyphOf(int stop) {
    final s = _s;
    if (stop < s.askAt) return s.scenes[stop].glyph;
    if (stop == s.askAt) return StoryGlyph.question;
    return s.outcome.glyph;
  }

  /// Where the disc sits round the drawing: a little further round at
  /// every stop, so the page seems to turn under it, and always on the side
  /// where the scene has room.
  static double _angleOf(int stop, _Plan p, Size size) {
    final a = const [-0.4, 0.4, 1.0, 0.05, 0.7][stop % 5];
    // A drawing on the right of the scene has its disc on its left.
    return p.glyph.center.dx > size.width / 2 ? math.pi - a : a;
  }

  String _spoken(BuildContext context) {
    final s = _s;
    final l10n = context.l10n;
    String beat(StoryBeat b) =>
        [if (b.fact.isNotEmpty) b.fact, b.line].join('. ');
    if (_at < s.askAt) {
      return '${l10n.sceneNOfM(_at + 1, s.stops)}. ${beat(s.scenes[_at])}';
    }
    if (_at == s.askAt) return s.ask;
    final pick = _pick == null
        ? ''
        : '${l10n.sceneYou}: ${s.options[_pick!]}. ';
    return '${beat(s.outcome)}. $pick${s.why}';
  }

  /// The words of [stop], laid out by [p]. [t] is the change's clock;
  /// [arriveAt] is where on it this stop's words begin to rise (a stop
  /// leaving is drawn whole, at t = 1, and faded as a piece).
  List<Widget> _texts(
    _Plan p,
    int stop,
    Color ink,
    Color ground,
    double t,
    Size size, {
    double arriveAt = -1,
  }) {
    final s = _s;
    final out = <Widget>[];
    // Before [arriveAt] everything waits; then the parts follow one
    // another at a fixed spacing, so the eye reads them in order.
    double at(double offset, [double length = 0.42]) {
      if (arriveAt < 0) return 1;
      // The offsets are written on a clock of 0.96 after [arriveAt]; it is
      // squeezed into what is left of the change, so the last part lands
      // as the controller ends.
      final k = (1 - arriveAt) / 0.96;
      final a = arriveAt + offset * k;
      return Curves.easeOutCubic.transform(
        ((t - a) / (length * k)).clamp(0.0, 1.0),
      );
    }

    if (p.fact != null) {
      final e = at(0);
      out.add(
        Positioned(
          left: 0,
          right: 0,
          top: p.fact!.top,
          child: Opacity(
            opacity: e,
            child: Transform.translate(
              offset: Offset(-10 * (1 - e), 0),
              child: ExcludeSemantics(
                child: Text(
                  p.fact!.text,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.clip,
                  textScaler: _scaler,
                  style: _Plan.factStyle(ink),
                ),
              ),
            ),
          ),
        ),
      );
    }

    final lines = p.line;
    for (var i = 0; i < lines.lines.length; i++) {
      final e = at(0.05 + 0.08 * i, 0.46);
      out.add(
        Positioned(
          left: 0,
          width: size.width + 40,
          top: lines.top + i * lines.lineHeight,
          height: lines.lineHeight,
          child: ClipRect(
            child: ExcludeSemantics(
              child: Transform.translate(
                offset: Offset(0, lines.lineHeight * 0.85 * (1 - e)),
                child: Opacity(
                  opacity: (e * 1.6).clamp(0.0, 1.0),
                  child: Text(
                    lines.lines[i],
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.visible,
                    textScaler: _scaler,
                    style: lines.style,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    // The outcomes, as buttons.
    for (var i = 0; i < p.options.length; i++) {
      final e = at(0.2 + 0.09 * i, 0.4);
      final r = p.options[i];
      out.add(
        Positioned.fromRect(
          rect: r,
          child: Opacity(
            opacity: e,
            child: Transform.translate(
              offset: Offset(0, 16 * (1 - e)),
              child: _option(i, ink, ground, live: arriveAt >= 0),
            ),
          ),
        ),
      );
    }

    // What the reader picked, then why.
    if (p.verdict != null && _pick != null) {
      final e = at(0.32, 0.4);
      final right = _pick == s.answer;
      out.add(
        Positioned(
          left: 0,
          right: 0,
          top: p.verdict,
          height: _Plan.verdictH,
          child: Opacity(
            opacity: e,
            child: Transform.translate(
              offset: Offset(-10 * (1 - e), 0),
              child: ExcludeSemantics(child: _verdict(ink, ground, right)),
            ),
          ),
        ),
      );
    }
    if (p.why != null) {
      final w = p.why!;
      final e = at(0.44, 0.4);
      out.add(
        Positioned(
          left: 0,
          top: w.top,
          width: 3,
          height: w.lines.length * w.lineHeight,
          child: Transform.scale(
            alignment: Alignment.topCenter,
            scaleY: e,
            child: ColoredBox(color: ink),
          ),
        ),
      );
      for (var i = 0; i < w.lines.length; i++) {
        final f = at(0.48 + 0.04 * i, 0.36);
        out.add(
          Positioned(
            left: _Plan.whyIndent,
            width: size.width,
            top: w.top + i * w.lineHeight,
            height: w.lineHeight,
            child: Opacity(
              opacity: f,
              child: Transform.translate(
                offset: Offset(0, 6 * (1 - f)),
                child: ExcludeSemantics(
                  child: Text(
                    w.lines[i],
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.visible,
                    textScaler: _scaler,
                    style: w.style,
                  ),
                ),
              ),
            ),
          ),
        );
      }
    }
    return out;
  }

  Widget _option(int i, Color ink, Color ground, {required bool live}) {
    final s = _s;
    final mine = _pick == i;
    final open = _pick == null && _at == s.askAt && live;
    final pressed = _pressed == i;
    final calm = _calm;
    final fg = mine ? ground : ink;
    return Semantics(
      container: true,
      button: true,
      enabled: open,
      selected: mine,
      label: s.options[i],
      hint: open ? context.l10n.sceneTapToPick : null,
      onTap: open ? () => _choose(i) : null,
      child: ExcludeSemantics(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: open ? (_) => setState(() => _pressed = i) : null,
          onTapCancel: open ? () => setState(() => _pressed = null) : null,
          onTap: open ? () => _choose(i) : null,
          child: AnimatedContainer(
            duration: calm ? Duration.zero : const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            decoration: BoxDecoration(
              color: mine ? ink : ink.withValues(alpha: pressed ? 0.14 : 0.0),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: mine ? ink : ink.withValues(alpha: 0.5),
                width: 1.6,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    s.options[i],
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.fade,
                    textScaler: _scaler,
                    style: AppText.body(
                      size: 16,
                      weight: FontWeight.w800,
                      color: fg,
                    ),
                  ),
                ),
                // The pick is said by shape too: an empty ring, then a
                // ring with a dot.
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: mine ? ground : ink.withValues(alpha: 0.5),
                      width: 1.6,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: mine
                      ? Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: ground,
                            shape: BoxShape.circle,
                          ),
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// YOU, what you picked, and a tick or a cross: struck through as well
  /// when it did not happen, so it reads without the mark.
  Widget _verdict(Color ink, Color ground, bool right) {
    final you = context.l10n.sceneYou;
    return Row(
      children: [
        Container(
          height: 18,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: ink,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(
            you,
            textScaler: _scaler,
            style: AppText.label(
              size: 9.5,
              weight: FontWeight.w800,
              spacing: 1.6,
              color: ground,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            _s.options[_pick!],
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.fade,
            textScaler: _scaler,
            style:
                AppText.body(
                  size: 14,
                  weight: FontWeight.w700,
                  color: ink.withValues(alpha: right ? 1 : 0.62),
                ).copyWith(
                  decoration: right ? null : TextDecoration.lineThrough,
                  decorationColor: ink.withValues(alpha: 0.7),
                  decorationThickness: 2,
                ),
          ),
        ),
        const SizedBox(width: 8),
        CustomPaint(
          size: const Size(14, 14),
          painter: _MarkPainter(ink, right: right),
        ),
      ],
    );
  }
}

// ------------------------------------------------------------------ layout

/// Lines of text already broken to the width, so each can move on its own.
class _Lines {
  final List<String> lines;
  final TextStyle style;
  final double lineHeight;
  final double top;
  const _Lines(this.lines, this.style, this.lineHeight, this.top);

  double get height => lines.length * lineHeight;

  _Lines at(double top) => _Lines(lines, style, lineHeight, top);

  /// Breaks [text] at [width] in [style], using the same breaks Flutter
  /// would, so each line set on its own looks exactly as the paragraph.
  static _Lines measure(
    String text,
    TextStyle style,
    double width,
    TextScaler scaler,
  ) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textScaler: scaler,
    )..layout(maxWidth: math.max(1, width));
    final metrics = tp.computeLineMetrics();
    final lines = <String>[];
    var off = 0;
    while (off < text.length && lines.length < 12) {
      final b = tp.getLineBoundary(TextPosition(offset: off));
      if (b.end <= off) break;
      lines.add(text.substring(b.start, b.end).trimRight());
      off = b.end;
      while (off < text.length && text[off] == ' ') {
        off++;
      }
    }
    final lh = metrics.isEmpty ? style.fontSize! : metrics.first.height;
    tp.dispose();
    return _Lines(lines, style, lh, 0);
  }

  /// The largest display size from [max] down to [min] at which [text]
  /// fits [width] in [maxLines] lines and [maxHeight]; at worst, [min].
  static _Lines fit(
    String text,
    TextStyle Function(double size) style,
    double width,
    double maxHeight,
    TextScaler scaler, {
    required double min,
    required double max,
    int maxLines = 3,
  }) {
    _Lines? best;
    for (var size = max; size >= min; size -= 1) {
      final l = measure(text, style(size), width, scaler);
      best = l;
      if (l.lines.length <= maxLines && l.height <= maxHeight) return l;
    }
    return best ?? measure(text, style(min), width, scaler);
  }
}

/// Where everything of one stop goes, for one size of scene. The painter
/// reads [glyph]; the words are placed from the rest.
class _Plan {
  final Rect glyph;
  final ({double top, String text})? fact;
  final _Lines line;
  final List<Rect> options;
  final double? verdict;
  final _Lines? why;

  /// Where the hint at the foot sits, or null when there is none.
  final double? footer;
  final double counterWidth;

  const _Plan({
    required this.glyph,
    required this.fact,
    required this.line,
    required this.options,
    required this.verdict,
    required this.why,
    required this.footer,
    required this.counterWidth,
  });

  static const stripH = 14.0;
  static const verdictH = 20.0;
  static const whyIndent = 14.0;
  static const factH = 14.0;

  static TextStyle factStyle(Color ink) => AppText.label(
    size: 10.5,
    weight: FontWeight.w800,
    spacing: 2.2,
    height: 1.2,
    color: ink.withValues(alpha: 0.72),
  );

  static TextStyle counterStyle(Color ink) => AppText.label(
    size: 10.5,
    weight: FontWeight.w800,
    spacing: 1.6,
    height: 1.2,
    color: ink.withValues(alpha: 0.6),
  );

  static TextStyle hintStyle(Color ink) => AppText.body(
    size: 13,
    weight: FontWeight.w600,
    height: 1.3,
    color: ink.withValues(alpha: 0.55),
  );

  static TextStyle lineStyle(double size, Color ink) => AppText.display(
    size: size,
    weight: FontWeight.w700,
    height: 1.1,
    spacing: -0.2 - size * 0.018,
    color: ink,
  );

  // Spacing is set, never inherited: the text is measured here and must
  // break the same way where the theme sets its own.
  static TextStyle whyStyle(double size, Color ink) => AppText.body(
    size: size,
    weight: FontWeight.w600,
    height: 1.35,
    spacing: 0,
    color: ink.withValues(alpha: 0.92),
  );

  factory _Plan.lay(
    StoryScene s,
    int stop,
    Size size,
    Color ink,
    TextScaler scaler,
    String counterText,
  ) {
    final w = size.width;
    final h = size.height;
    final short = h < 330;
    final stageTop = stripH + (short ? 12 : 22);

    final counter = TextPainter(
      text: TextSpan(text: counterText, style: counterStyle(ink)),
      textDirection: TextDirection.ltr,
      textScaler: scaler,
    )..layout();
    final counterWidth = counter.width;
    counter.dispose();

    final hint = TextPainter(
      text: TextSpan(text: 'Ag', style: hintStyle(ink)),
      textDirection: TextDirection.ltr,
      textScaler: scaler,
    )..layout();
    final hintH = hint.height;
    hint.dispose();

    final factLine = scaler.scale(factH);
    final display = (h * 0.075).clamp(24.0, 34.0);

    // The drawing takes what the words leave, square, up to half the width;
    // too small to read and it is left out.
    // It leans towards the words below it, so the two read as one block.
    Rect glyphIn(double top, double bottom) {
      final room = bottom - top;
      final side = math.min(room, math.min(w * 0.58, 250.0));
      if (side < 64) return Rect.zero;
      return Rect.fromLTWH(4, top + (room - side) * 0.85, side, side);
    }

    if (stop < s.askAt || stop == s.outcomeAt) {
      final outcome = stop == s.outcomeAt;
      final b = outcome ? s.outcome : s.scenes[stop];
      final footer = outcome ? null : h - hintH;
      var bottom = outcome ? h : footer! - (short ? 10 : 16);

      _Lines? why;
      double? verdict;
      if (outcome) {
        why = _Lines.fit(
          s.why,
          (z) => whyStyle(z, ink),
          w - whyIndent,
          h * 0.3,
          scaler,
          min: 13,
          max: short ? 14 : 15,
          maxLines: 4,
        );
        why = why.at(bottom - why.height);
        verdict = why.top - (short ? 12 : 16) - verdictH;
        bottom = verdict - (short ? 10 : 14);
      }

      final factRoom = b.fact.isEmpty ? 0.0 : factLine + 8;
      var line = _Lines.fit(
        b.line,
        (z) => lineStyle(z, ink),
        w,
        (bottom - stageTop - factRoom) * (outcome ? 0.8 : 0.62),
        scaler,
        min: 18,
        max: outcome ? display - 2 : display,
      );
      line = line.at(bottom - line.height);
      final factTop = line.top - factRoom;
      return _Plan(
        glyph: glyphIn(stageTop, factTop - (short ? 10 : 18)),
        fact: b.fact.isEmpty
            ? null
            : (top: factTop, text: b.fact.toUpperCase()),
        line: line,
        options: const [],
        verdict: verdict,
        why: why,
        footer: footer,
        counterWidth: counterWidth,
      );
    }

    // The question, and the outcomes under it.
    final footer = h - hintH;
    final bottom = footer - (short ? 10 : 14);
    final optH = short ? 44.0 : 50.0;
    final gap = short ? 7.0 : 9.0;
    final n = s.options.length;
    final optionsTop = bottom - n * optH - (n - 1) * gap;
    _Lines askAt(double width) => _Lines.fit(
      s.ask,
      (z) => lineStyle(z, ink),
      width,
      (optionsTop - stageTop) * 0.7,
      scaler,
      min: 18,
      max: display - 2,
      maxLines: 2,
    ).at(0);
    var ask = askAt(w);
    ask = ask.at(optionsTop - (short ? 12 : 18) - ask.height);
    var glyph = glyphIn(stageTop, ask.top - (short ? 10 : 18));
    if (glyph == Rect.zero) {
      // No room above: the question mark stands beside the question, as
      // tall as it, and the question takes the rest of the width.
      final gapAbove = short ? 12 : 18;
      final room = optionsTop - gapAbove - stageTop;
      final side = math.min(math.min(w * 0.3, 104.0), room);
      ask = askAt(w - side - 12);
      final block = math.max(ask.height, side);
      final top = optionsTop - gapAbove - block;
      // The question sits on the buttons; the mark stands over its end.
      ask = ask.at(top + block - ask.height);
      glyph = side < 40 || top < stageTop
          ? Rect.zero
          : Rect.fromLTWH(w - side, top + (block - side) / 2, side, side);
    }
    return _Plan(
      glyph: glyph,
      fact: null,
      line: ask,
      options: [
        for (var i = 0; i < n; i++)
          Rect.fromLTWH(0, optionsTop + i * (optH + gap), w, optH),
      ],
      verdict: null,
      why: null,
      footer: footer,
      counterWidth: counterWidth,
    );
  }
}

// ------------------------------------------------------------------ glyphs

/// Every glyph as strokes resampled to the same number of points, longest
/// stroke first: the order a pen draws them in, and takes them back.
class _Strokes {
  static const points = 48;
  static final Map<StoryGlyph, List<Float32List>> _cache = {};

  static List<Float32List> of(StoryGlyph g) =>
      _cache.putIfAbsent(g, () => _resample(_draw(g)));

  static List<Float32List> _resample(List<List<Offset>> strokes) {
    final out = <(double, Float32List)>[];
    for (final s in strokes) {
      final lens = <double>[0];
      for (var i = 1; i < s.length; i++) {
        lens.add(lens.last + (s[i] - s[i - 1]).distance);
      }
      final total = lens.last;
      final pts = Float32List(points * 2);
      var j = 1;
      for (var k = 0; k < points; k++) {
        final d = total * k / (points - 1);
        while (j < s.length - 1 && lens[j] < d) {
          j++;
        }
        final seg = lens[j] - lens[j - 1];
        final f = seg == 0 ? 0.0 : ((d - lens[j - 1]) / seg).clamp(0.0, 1.0);
        final p = Offset.lerp(s[j - 1], s[j], f)!;
        pts[k * 2] = p.dx;
        pts[k * 2 + 1] = p.dy;
      }
      out.add((total, pts));
    }
    out.sort((a, b) => b.$1.compareTo(a.$1));
    return [for (final o in out) o.$2];
  }

  // The drawings, in a 100 × 100 box. Line art only: every stroke is a
  // polyline, so each can be resampled and morphed.

  static List<Offset> _poly(List<double> xy) => [
    for (var i = 0; i < xy.length; i += 2) Offset(xy[i], xy[i + 1]),
  ];

  static List<Offset> _arc(
    double cx,
    double cy,
    double rx,
    double ry,
    double a0,
    double a1,
  ) {
    final n = math.max(8, ((a1 - a0).abs() / (math.pi / 18)).ceil());
    return [
      for (var i = 0; i <= n; i++)
        Offset(
          cx + rx * math.cos(a0 + (a1 - a0) * i / n),
          cy + ry * math.sin(a0 + (a1 - a0) * i / n),
        ),
    ];
  }

  static List<Offset> _ring(double cx, double cy, double r) =>
      _arc(cx, cy, r, r, -math.pi / 2, math.pi * 1.5);

  static List<Offset> _rrect(double l, double t, double r, double b, double k) {
    const q = math.pi / 2;
    return [
      ..._arc(l + k, t + k, k, k, 2 * q, 3 * q),
      ..._arc(r - k, t + k, k, k, 3 * q, 4 * q),
      ..._arc(r - k, b - k, k, k, 0, q),
      ..._arc(l + k, b - k, k, k, q, 2 * q),
      Offset(l, t + k),
    ];
  }

  static List<Offset> _quad(Offset a, Offset c, Offset b) => [
    for (var i = 0; i <= 16; i++)
      () {
        final t = i / 16;
        final u = 1 - t;
        return a * (u * u) + c * (2 * u * t) + b * (t * t);
      }(),
  ];

  static List<List<Offset>> _draw(StoryGlyph g) {
    const p = math.pi;
    switch (g) {
      case StoryGlyph.pin:
        return [
          [
            const Offset(50, 90),
            ..._arc(50, 40, 27, 27, p * 0.80, p * 2.20),
            const Offset(50, 90),
          ],
          _ring(50, 40, 10),
        ];
      case StoryGlyph.lights:
        return [
          _rrect(33, 8, 67, 78, 12),
          _ring(50, 25, 8),
          _ring(50, 43, 8),
          _ring(50, 61, 8),
          _poly([50, 78, 50, 94]),
        ];
      case StoryGlyph.car:
        return [
          _poly([
            8,
            66,
            8,
            54,
            22,
            50,
            34,
            33,
            66,
            33,
            80,
            50,
            92,
            54,
            92,
            66,
            82,
            66,
          ]),
          _ring(70, 68, 9),
          _ring(30, 68, 9),
          _poly([36, 50, 76, 50]),
          _poly([40, 66, 60, 66]),
        ];
      case StoryGlyph.walker:
        return [
          _poly([46, 30, 42, 60, 30, 90]),
          _poly([42, 60, 58, 74, 58, 92]),
          _poly([45, 38, 30, 52]),
          _poly([45, 38, 64, 48]),
          _ring(50, 16, 9),
        ];
      case StoryGlyph.crowd:
        return [
          _arc(50, 80, 22, 22, p, p * 2),
          _arc(22, 86, 17, 17, p, p * 2),
          _arc(78, 86, 17, 17, p, p * 2),
          _ring(50, 40, 12),
          _ring(22, 52, 9),
          _ring(78, 52, 9),
        ];
      case StoryGlyph.family:
        return [
          _poly([32, 30, 32, 62, 22, 92]),
          _poly([32, 62, 42, 92]),
          _poly([32, 40, 54, 60, 66, 58]),
          _poly([68, 58, 68, 76, 62, 92]),
          _poly([68, 76, 74, 92]),
          _ring(32, 17, 10),
          _ring(68, 46, 8),
        ];
      case StoryGlyph.house:
        return [
          _poly([22, 42, 22, 88, 78, 88, 78, 42]),
          _poly([10, 50, 50, 14, 90, 50]),
          _poly([42, 88, 42, 64, 58, 64, 58, 88]),
        ];
      case StoryGlyph.clock:
        return [
          _ring(50, 52, 38),
          _poly([50, 52, 50, 28]),
          _poly([50, 52, 66, 62]),
          _poly([50, 6, 50, 12]),
        ];
      case StoryGlyph.calendar:
        return [
          _rrect(12, 20, 88, 88, 9),
          _poly([12, 40, 88, 40]),
          _poly([32, 10, 32, 28]),
          _poly([68, 10, 68, 28]),
          _poly([30, 58, 44, 58]),
          _poly([56, 58, 70, 58]),
          _poly([30, 72, 44, 72]),
        ];
      case StoryGlyph.coin:
        return [
          _ring(50, 50, 38),
          _ring(50, 50, 28),
          _arc(50, 50, 12, 14, p * 0.25, p * 1.75),
          _poly([50, 30, 50, 70]),
        ];
      case StoryGlyph.ticket:
        return [
          [
            const Offset(10, 28),
            const Offset(90, 28),
            ..._arc(90, 50, 8, 8, -p / 2, -p * 1.5),
            const Offset(90, 72),
            const Offset(10, 72),
            ..._arc(10, 50, 8, 8, p / 2, -p / 2),
          ],
          _poly([62, 30, 62, 70]),
          _poly([24, 42, 50, 42]),
          _poly([24, 56, 42, 56]),
        ];
      case StoryGlyph.rat:
        return [
          [
            ..._arc(46, 62, 28, 18, p * 0.15, p * 1.0),
            ..._arc(46, 62, 28, 18, p * 1.0, p * 1.62),
            const Offset(90, 62),
            const Offset(72, 70),
          ],
          _quad(
            const Offset(18, 64),
            const Offset(-4, 50),
            const Offset(14, 28),
          ),
          _ring(64, 42, 7),
          _poly([34, 78, 32, 88]),
          _poly([58, 78, 60, 88]),
        ];
      case StoryGlyph.drain:
        return [
          _ring(50, 50, 38),
          _poly([22, 36, 78, 36]),
          _poly([14, 50, 86, 50]),
          _poly([22, 64, 78, 64]),
        ];
      case StoryGlyph.eye:
        return [
          _quad(const Offset(8, 50), const Offset(50, 6), const Offset(92, 50)),
          _quad(
            const Offset(8, 50),
            const Offset(50, 94),
            const Offset(92, 50),
          ),
          _ring(50, 50, 14),
          _ring(50, 50, 4),
        ];
      case StoryGlyph.rise:
        return [
          _poly([12, 10, 12, 88, 90, 88]),
          _poly([22, 74, 42, 56, 56, 62, 84, 28]),
          _poly([70, 28, 84, 28, 84, 42]),
        ];
      case StoryGlyph.fall:
        return [
          _poly([12, 10, 12, 88, 90, 88]),
          _poly([22, 26, 42, 44, 56, 38, 84, 72]),
          _poly([84, 58, 84, 72, 70, 72]),
        ];
      case StoryGlyph.ban:
        return [
          _ring(50, 50, 38),
          _poly([23, 77, 77, 23]),
        ];
      case StoryGlyph.check:
        return [
          _poly([16, 52, 40, 76, 86, 26]),
        ];
      case StoryGlyph.cross:
        return [
          _poly([20, 20, 80, 80]),
          _poly([80, 20, 20, 80]),
        ];
      case StoryGlyph.book:
        return [
          _poly([50, 26, 50, 86]),
          [
            ..._quad(
              const Offset(50, 26),
              const Offset(30, 16),
              const Offset(8, 22),
            ),
            const Offset(8, 80),
            ..._quad(
              const Offset(8, 80),
              const Offset(30, 74),
              const Offset(50, 86),
            ),
          ],
          [
            ..._quad(
              const Offset(50, 26),
              const Offset(70, 16),
              const Offset(92, 22),
            ),
            const Offset(92, 80),
            ..._quad(
              const Offset(92, 80),
              const Offset(70, 74),
              const Offset(50, 86),
            ),
          ],
        ];
      case StoryGlyph.phone:
        return [
          _rrect(28, 8, 72, 92, 10),
          _poly([44, 18, 56, 18]),
          _poly([46, 80, 54, 80]),
        ];
      case StoryGlyph.question:
        return [
          [
            ..._arc(50, 32, 19, 19, p * 1.05, p * 2.35),
            ..._quad(
              const Offset(58, 46),
              const Offset(50, 52),
              const Offset(50, 62),
            ),
          ],
          _ring(50, 81, 3),
        ];
    }
  }
}

// ----------------------------------------------------------------- painters

/// The dashes, the disc and the drawing, from one set of numbers. It is
/// rebuilt every frame of a change by the view's AnimatedBuilder; between
/// changes [shouldRepaint] keeps it still.
class _StoryPainter extends CustomPainter {
  final Color ink;
  final int stops;

  /// How many dashes are full, fractional while one fills.
  final double filled;
  final double stripRight;
  final StoryGlyph? fromGlyph;
  final StoryGlyph toGlyph;
  final Rect? fromRect;
  final Rect toRect;
  final double? fromAngle;
  final double toAngle;

  /// 0 shows the old drawing, 1 the new.
  final double morph;

  /// How much of the new drawing is drawn in, on the first arrival.
  final double drawOn;

  _StoryPainter({
    required this.ink,
    required this.stops,
    required this.filled,
    required this.stripRight,
    required this.fromGlyph,
    required this.toGlyph,
    required this.fromRect,
    required this.toRect,
    required this.fromAngle,
    required this.toAngle,
    required this.morph,
    required this.drawOn,
  });

  final Paint _dash = Paint()..strokeCap = StrokeCap.round;
  final Paint _stroke = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
  final Paint _dots = Paint()..strokeCap = StrokeCap.round;
  final Path _path = Path();

  static final Map<int, List<(double, Float32List)>> _halftones = {};

  @override
  void paint(Canvas canvas, Size size) {
    _strip(canvas);
    final from = fromRect;
    final had = from != null && from != Rect.zero && fromGlyph != null;
    final has = toRect != Rect.zero;
    if (!had && !has) return;

    // The box the drawing is in, travelling between the two stops' boxes.
    // A stop with no room for a drawing lends the other's box, so the
    // drawing fades where it is rather than flying off.
    final a = had ? from : toRect;
    final b = has ? toRect : from!;
    final m = morph;
    final box = Rect.lerp(a, b, m)!;
    final fade = had && has ? 1.0 : (has ? m : 1 - m);
    final angle = lerpDouble(fromAngle ?? toAngle, toAngle, m)!;
    // The disc stays under the dashes and inside the scene.
    canvas.save();
    canvas.clipRect(
      Rect.fromLTRB(-8, _Plan.stripH + 6, size.width, size.height),
    );
    _disc(canvas, box, angle, fade * drawOn.clamp(0.0, 1.0));
    canvas.restore();
    _glyph(canvas, a, b, m, had, has);
  }

  void _strip(Canvas canvas) {
    const y = 6.0;
    const gap = 6.0;
    final seg = (stripRight - gap * (stops - 1)) / stops;
    if (seg <= 2) return;
    _dash.strokeWidth = 3;
    for (var i = 0; i < stops; i++) {
      final x0 = i * (seg + gap);
      _dash.color = ink.withValues(alpha: 0.2);
      canvas.drawLine(Offset(x0, y), Offset(x0 + seg, y), _dash);
      final f = (filled - i).clamp(0.0, 1.0);
      if (f > 0) {
        _dash.color = ink;
        canvas.drawLine(Offset(x0, y), Offset(x0 + seg * f, y), _dash);
      }
    }
  }

  /// A halftone disc: dots on a grid, large on one side and fading to
  /// specks on the other, like a printed screen.
  void _disc(Canvas canvas, Rect box, double angle, double alpha) {
    if (alpha <= 0) return;
    final side = box.width;
    final r = side * 0.5;
    var c =
        box.center + Offset(math.cos(angle), math.sin(angle)) * (side * 0.3);
    // It may lean out to the side, but not down into the words below.
    c = Offset(c.dx, math.min(c.dy, box.bottom + side * 0.06 - r));
    final key = r.round();
    final sets = _halftones.putIfAbsent(key, () => _lay(key.toDouble()));
    canvas.save();
    canvas.translate(c.dx, c.dy);
    for (final (radius, pts) in sets) {
      _dots
        ..strokeWidth = radius * 2
        ..color = ink.withValues(alpha: 0.2 * alpha);
      canvas.drawRawPoints(PointMode.points, pts, _dots);
    }
    canvas.restore();
  }

  static List<(double, Float32List)> _lay(double r) {
    final step = math.max(5.0, r / 9);
    const bands = 5;
    final buckets = List.generate(bands, (_) => <double>[]);
    final n = (r / step).ceil();
    for (var i = -n; i <= n; i++) {
      for (var j = -n; j <= n; j++) {
        final x = i * step + (j.isOdd ? step / 2 : 0);
        final y = j * step * 0.87;
        if (x * x + y * y > r * r) continue;
        // Heavier towards the lower right.
        final s = ((x + y) / (r * 1.42) + 1) / 2;
        final b = (s * bands).floor().clamp(0, bands - 1);
        buckets[b]
          ..add(x)
          ..add(y);
      }
    }
    return [
      for (var b = 0; b < bands; b++)
        if (buckets[b].isNotEmpty)
          (
            step * (0.1 + 0.36 * (b + 1) / bands),
            Float32List.fromList(buckets[b]),
          ),
    ];
  }

  /// The change between two drawings, as a pen would make it: the old
  /// strokes are taken back along their own path, longest first, while the
  /// new ones are drawn in, longest first, and the box they share glides
  /// from the old place and size to the new. Every frame is two clean
  /// partial drawings, never a tangle of points in flight.
  void _glyph(Canvas canvas, Rect a, Rect b, double m, bool had, bool has) {
    final box = Rect.lerp(a, b, m)!;
    _stroke.strokeWidth = (box.width * 0.05).clamp(2.5, 9.0);
    if (fromGlyph != null && had && m < 1) {
      _pen(canvas, _Strokes.of(fromGlyph!), box, from: m / 0.6, to: 1);
    }
    if (has) {
      final drawIn = fromGlyph == null ? drawOn : (m - 0.3) / 0.7;
      _pen(canvas, _Strokes.of(toGlyph), box, from: 0, to: drawIn);
    }
  }

  /// Draws each stroke of [strokes] in [box] between [from] and [to] of
  /// the way along it, staggered so the longest stroke leads.
  void _pen(
    Canvas canvas,
    List<Float32List> strokes,
    Rect box, {
    required double from,
    required double to,
  }) {
    const n = _Strokes.points;
    final s = box.width / 100;
    final count = strokes.length;
    _stroke.color = ink;
    for (var k = 0; k < count; k++) {
      final lead = count == 1 ? 0.0 : k / (count - 1) * 0.35;
      double along(double v) => ((v - lead) / 0.65).clamp(0.0, 1.0);
      final f0 = from <= 0 ? 0.0 : along(from);
      final f1 = to >= 1 ? 1.0 : along(to);
      if (f1 - f0 <= 0.001) continue;
      final st = strokes[k];
      final i0 = f0 * (n - 1);
      final i1 = f1 * (n - 1);
      Offset at(double i) {
        final j = i.floor().clamp(0, n - 2);
        final t = i - j;
        return Offset(
          box.left + lerpDouble(st[j * 2], st[j * 2 + 2], t)! * s,
          box.top + lerpDouble(st[j * 2 + 1], st[j * 2 + 3], t)! * s,
        );
      }

      _path.reset();
      final p0 = at(i0);
      _path.moveTo(p0.dx, p0.dy);
      for (var i = i0.floor() + 1; i < i1; i++) {
        final p = at(i.toDouble());
        _path.lineTo(p.dx, p.dy);
      }
      final p1 = at(i1);
      _path.lineTo(p1.dx + 0.01, p1.dy);
      canvas.drawPath(_path, _stroke);
    }
  }

  @override
  bool shouldRepaint(_StoryPainter old) =>
      old.ink != ink ||
      old.stops != stops ||
      old.filled != filled ||
      old.stripRight != stripRight ||
      old.fromGlyph != fromGlyph ||
      old.toGlyph != toGlyph ||
      old.fromRect != fromRect ||
      old.toRect != toRect ||
      old.fromAngle != fromAngle ||
      old.toAngle != toAngle ||
      old.morph != morph ||
      old.drawOn != drawOn;
}

/// A small arrow after the hint: on it goes.
class _ArrowPainter extends CustomPainter {
  final Color color;
  _ArrowPainter(this.color);

  late final Paint _p = Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.8
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height / 2;
    canvas.drawLine(Offset(0, y), Offset(size.width, y), _p);
    canvas.drawPath(
      Path()
        ..moveTo(size.width - 5, y - 4)
        ..lineTo(size.width, y)
        ..lineTo(size.width - 5, y + 4),
      _p,
    );
  }

  @override
  bool shouldRepaint(_ArrowPainter old) => old.color != color;
}

/// A tick when the pick came true, a cross when it did not.
class _MarkPainter extends CustomPainter {
  final Color ink;
  final bool right;
  _MarkPainter(this.ink, {required this.right});

  late final Paint _p = Paint()
    ..color = ink
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.2
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    if (right) {
      canvas.drawPath(
        Path()
          ..moveTo(w * 0.1, h * 0.55)
          ..lineTo(w * 0.4, h * 0.85)
          ..lineTo(w * 0.92, h * 0.18),
        _p,
      );
    } else {
      canvas.drawLine(
        Offset(w * 0.15, h * 0.15),
        Offset(w * 0.85, h * 0.85),
        _p,
      );
      canvas.drawLine(
        Offset(w * 0.85, h * 0.15),
        Offset(w * 0.15, h * 0.85),
        _p,
      );
    }
  }

  @override
  bool shouldRepaint(_MarkPainter old) => old.ink != ink || old.right != right;
}
