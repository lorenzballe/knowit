import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/l10n.dart';
import '../../models/scene.dart';
import '../../theme.dart';

/// Plays a [NewsScene]: a clipping from the paper, explained in three taps.
///
/// The headline sits at the top on a cut-out of newsprint: the outlet and
/// the date on its masthead over a double rule, the headline set large, the
/// bottom edge torn. Under it the card lists what it is about to give, like
/// the contents of a page: "01 What happened", "02 Why", "03 What it means
/// for you". The first line is a button; the others wait, dimmed.
///
/// Each tap (or a swipe to the left) opens the next step. The contents fold
/// into three bars under the clipping, one per step, filled as they are
/// read; the step slides in from the right with its label, its number when
/// it has one, and its text. A small button at the foot names the step that
/// is coming ("Why →"), so the reader meets the question before the answer.
///
/// When the card has a past case, the last step drops an older clipping in
/// under today's: printed in reverse, ink with the card's colour for type,
/// the year large beside that time's headline, and one line under it on what
/// the two have in common.
///
/// Once all three steps are open, the scene lets go: a tap turns the card
/// over and a swipe moves the deck. The bars stay buttons, to read a step
/// again. With animations off every step is simply there on the next frame.
class NewsSceneView extends StatefulWidget {
  final NewsScene scene;
  final Color ink;
  final Color ground;
  const NewsSceneView({
    super.key,
    required this.scene,
    required this.ink,
    required this.ground,
  });

  @override
  State<NewsSceneView> createState() => _NewsSceneViewState();
}

class _NewsSceneViewState extends State<NewsSceneView>
    with TickerProviderStateMixin {
  /// Steps opened so far: 0 is the contents alone, 3 all of them.
  int _open = 0;

  /// The step on show, and the one before the last turn (-1 the contents).
  int _view = -1;
  int _from = -1;

  /// One turn of the page. Starts finished, so the scene is at rest.
  late final AnimationController _turn = AnimationController(
    vsync: this,
    value: 1,
    duration: const Duration(milliseconds: 560),
  );

  /// On arrival the first line's arrow nudges once, after a wait that is
  /// the first part of the controller: no Timer.
  late final AnimationController _nudge = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  );
  bool _started = false;

  /// A sideways drag in progress, followed with resistance.
  double _drag = 0;

  _NewsLayout? _layout;
  Object? _layoutKey;

  int get _steps => widget.scene.steps;
  bool get _done => _open == _steps;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started && !MediaQuery.disableAnimationsOf(context)) {
      _started = true;
      _nudge.forward();
    }
  }

  /// A different card in the same place starts over.
  @override
  void didUpdateWidget(NewsSceneView old) {
    super.didUpdateWidget(old);
    if (old.scene.raw != widget.scene.raw) {
      _turn.value = 1;
      _open = 0;
      _view = _from = -1;
      _drag = 0;
      _layout = null;
    }
  }

  @override
  void dispose() {
    _turn.dispose();
    _nudge.dispose();
    super.dispose();
  }

  // ---- commands ----

  /// The next step: one already read, or the next one opened.
  void _next() {
    if (_view < _open - 1) {
      _show(_view + 1);
    } else if (_open < _steps) {
      _open++;
      _show(_open - 1, opened: true);
    }
  }

  void _back() {
    if (_view > 0) _show(_view - 1);
  }

  void _show(int step, {bool opened = false}) {
    if (step == _view || step < 0 || step >= _open) return;
    _nudge.stop();
    if (opened && _open == _steps) {
      HapticFeedback.lightImpact();
    } else {
      HapticFeedback.selectionClick();
    }
    setState(() {
      _from = _view;
      _view = step;
      _drag = 0;
    });
    if (MediaQuery.disableAnimationsOf(context)) {
      _turn.value = 1;
    } else {
      _turn.forward(from: 0);
    }
  }

  void _dragBy(double dx) {
    if (_turn.isAnimating) _turn.value = 1;
    _nudge.stop();
    setState(() => _drag = (_drag + dx).clamp(-240.0, 240.0));
  }

  void _letGo(double velocity) {
    final d = _drag;
    setState(() => _drag = 0);
    if (d < -44 || velocity < -420) {
      _next();
    } else if (d > 44 || velocity > 420) {
      _back();
    }
  }

  static double _seg(double t, double a, double b, [Curve c = Curves.linear]) =>
      c.transform(((t - a) / (b - a)).clamp(0.0, 1.0));

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final scaler = MediaQuery.textScalerOf(context);
        final key = (box.maxWidth, box.maxHeight, scaler, widget.scene.raw);
        if (_layout == null || _layoutKey != key) {
          _layoutKey = key;
          _layout = _NewsLayout.measure(
            widget.scene,
            Size(box.maxWidth, box.maxHeight),
            scaler,
          );
        }
        return AnimatedBuilder(
          animation: Listenable.merge([_turn, _nudge]),
          builder: (context, _) => _frame(context, _layout!),
        );
      },
    );
  }

  Widget _frame(BuildContext context, _NewsLayout l) {
    final ink = widget.ink;
    final ground = widget.ground;
    final s = widget.scene;
    final t = _turn.value;
    final fromIntro = _from == -1 && _view >= 0;
    final forward = _view > _from;

    // The contents fold away on the first turn; the bars and the step come
    // in after them.
    final introOut = _view == -1 ? 0.0 : (fromIntro ? _seg(t, 0, .4) : 1.0);
    final stripIn = _view == -1
        ? 0.0
        : (fromIntro ? _seg(t, .25, .7, Curves.easeOutCubic) : 1.0);
    final outgoing = fromIntro ? 1.0 : _seg(t, 0, .34, Curves.easeInCubic);
    final incoming = _seg(t, .36, 1, Curves.easeOutCubic);
    final dir = forward ? 1.0 : -1.0;
    // The page follows a sideways drag with resistance, never far.
    final drag = 28 * _drag / (90 + _drag.abs());

    final nudge =
        math.sin(_seg(_nudge.value, .45, 1) * math.pi * 2) *
        (1 - _seg(_nudge.value, .45, 1)) *
        5;

    // The clipping folds to its smaller self as the first step opens.
    final fold = _view == -1
        ? 0.0
        : (fromIntro ? _seg(t, 0, .55, Curves.easeInOutCubic) : 1.0);

    final children = <Widget>[
      // Today's clipping.
      Positioned(
        left: 0,
        top: 0,
        width: l.size.width,
        height: l.clipBig + _NewsLayout.tear + _NewsLayout.shadow,
        child: _Clipping(
          scene: s,
          layout: l,
          fold: fold,
          ink: ink,
          ground: ground,
          date:
              '${MaterialLocalizations.of(context).formatShortMonthDay(s.date)}, '
              '${s.date.year}',
        ),
      ),
    ];

    // The contents: what the card is about to give.
    if (introOut < 1) {
      for (var i = 0; i < _steps; i++) {
        final a = _seg(introOut, i * .12, .64 + i * .12, Curves.easeInCubic);
        children.add(
          Positioned(
            left: 0,
            width: l.size.width,
            top: l.rowTop(i) + a * 10,
            height: l.rowH,
            child: Opacity(
              opacity: (1 - a).clamp(0.0, 1.0),
              child: _ContentsRow(
                number: i + 1,
                label: s.labelOf(i),
                first: i == 0,
                nudge: i == 0 ? nudge : 0,
                font: l.rowFont,
                ink: ink,
                ground: ground,
                onTap: i == 0 && _view == -1 ? _next : null,
              ),
            ),
          ),
        );
      }
    }

    if (_view >= 0) {
      // The bars: one per step, filled once read, the one on show solid.
      children.add(
        Positioned(
          left: 0,
          width: l.size.width,
          top: l.stripTop,
          height: _NewsLayout.stripH,
          child: Opacity(
            opacity: stripIn,
            child: _Strip(
              steps: _steps,
              open: _open,
              view: _view,
              from: _from,
              t: incoming,
              labelOf: (i) =>
                  '${s.labelOf(i)}, ${context.l10n.sceneNOfM(i + 1, _steps)}',
              ink: ink,
              onShow: _show,
            ),
          ),
        ),
      );

      // The step leaving, then the step arriving.
      if (!fromIntro && outgoing < 1 && _from >= 0) {
        children.add(
          _panelAt(
            l,
            _from,
            dx: -dir * 26 * outgoing,
            opacity: 1 - outgoing,
            arrive: 1,
          ),
        );
      }
      children.add(
        _panelAt(
          l,
          _view,
          dx: dir * 26 * (1 - incoming) + drag,
          opacity: incoming,
          arrive: incoming,
          live: true,
        ),
      );
    }

    // Until every step is open the scene is the reader's: a tap opens the
    // next, a sideways drag turns the page and is held so the deck does not
    // slide away. Then the card is free again.
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _done ? null : _next,
      onHorizontalDragUpdate: _done ? null : (d) => _dragBy(d.delta.dx),
      onHorizontalDragEnd: _done
          ? null
          : (d) => _letGo(d.velocity.pixelsPerSecond.dx),
      onHorizontalDragCancel: _done ? null : () => _letGo(0),
      child: SizedBox(
        width: l.size.width,
        height: l.size.height,
        child: Stack(clipBehavior: Clip.none, children: children),
      ),
    );
  }

  Widget _panelAt(
    _NewsLayout l,
    int step, {
    required double dx,
    required double opacity,
    required double arrive,
    bool live = false,
  }) {
    final s = widget.scene;
    final m = context.l10n.sceneNOfM(step + 1, _steps);
    // The step's label, and the button that names the step to come.
    final head = _StepHead(
      label: s.labelOf(step),
      count: m,
      next: step < _steps - 1 ? s.labelOf(step + 1) : null,
      onNext: _next,
      layout: l,
      ink: widget.ink,
      ground: widget.ground,
    );
    final Widget body = step < s.panels.length
        ? _PanelBody(
            panel: s.panels[step],
            head: head,
            layout: l,
            arrive: arrive,
            ink: widget.ink,
          )
        : _ThenBody(
            then: s.then!,
            head: head,
            layout: l,
            arrive: arrive,
            ink: widget.ink,
            ground: widget.ground,
          );
    return Positioned(
      left: 0,
      width: l.size.width,
      top: l.panelTop,
      height: l.panelRoom,
      child: Transform.translate(
        offset: Offset(dx, 0),
        child: Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: Semantics(container: true, liveRegion: live, child: body),
        ),
      ),
    );
  }
}

/// Where everything sits and how large, measured once per size.
///
/// Two fits. Before the first tap: the clipping at its largest over the
/// contents. After it: the clipping folded smaller over the bars and the
/// tallest of the steps. Type starts from sizes set by the phone and steps
/// down until each fits; the headline gives way before the steps do.
class _NewsLayout {
  final Size size;
  final double headBig;
  final double headSmall;
  final double panelFont;
  final double rowFont;
  final double chipFont;

  /// The clipping's height, open and folded, not counting its torn edge and
  /// shadow.
  final double clipBig;
  final double clipSmall;
  final double rowH;

  /// Whether the steps are set tight: a smaller number, less air.
  final bool tight;

  static const double pad = 15;
  static const double tear = 7;
  static const double shadow = 4;
  static const double stripH = 22;
  static const double chipH = 30;
  static const double rules = 6;

  const _NewsLayout._({
    required this.size,
    required this.headBig,
    required this.headSmall,
    required this.panelFont,
    required this.rowFont,
    required this.chipFont,
    required this.clipBig,
    required this.clipSmall,
    required this.rowH,
    required this.tight,
  });

  double get clipW => size.width - shadow;
  double get rowGap => rowH * 0.2;
  double rowTop(int i) => clipBig + tear + shadow + 14 + i * (rowH + rowGap);
  double get stripTop => clipSmall + tear + shadow + 6;
  double get panelTop => stripTop + stripH + (tight ? 4 : 8);
  double get panelRoom => size.height - panelTop;
  double get headGap => tight ? 8 : 12;

  double get figFont => panelFont * (tight ? 1.75 : 2.1);
  double get yearFont => panelFont * (tight ? 1.5 : 1.75);
  double get thenPad => tight ? 10 : 13;

  /// The masthead's line height at this text scale.
  static double mast(TextScaler scaler) => scaler.scale(1) * 13;

  /// The headline's top inside the clipping.
  static double headTop(TextScaler scaler) =>
      12 + mast(scaler) + 8 + rules + 10;

  static TextStyle headStyle(double size, Color c) => AppText.display(
    size: size,
    weight: FontWeight.w800,
    height: 1.08,
    spacing: -0.3 - size * 0.014,
    color: c,
  );

  static TextStyle textStyle(double size, Color c) => AppText.display(
    size: size,
    weight: FontWeight.w600,
    height: 1.22,
    spacing: -0.1 - size * 0.006,
    color: c,
  );

  static TextStyle figStyle(double size, Color c) => AppText.display(
    size: size,
    weight: FontWeight.w800,
    height: 1,
    spacing: -0.6,
    color: c,
  ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]);

  static TextStyle labelStyle(Color c) =>
      AppText.label(size: 10.5, weight: FontWeight.w800, height: 1.2, color: c);

  static TextStyle thenHeadStyle(double size, Color c) => AppText.display(
    size: size,
    weight: FontWeight.w700,
    height: 1.12,
    spacing: -0.2,
    color: c,
  );

  static TextStyle chipStyle(double size, Color c) =>
      AppText.body(size: size, weight: FontWeight.w700, height: 1, color: c);

  /// The old clipping's height: the year beside that time's headline.
  double thenClipH(NewsThen then, TextScaler scaler) {
    final year = _paint(
      '${then.year}',
      figStyle(yearFont, Colors.black),
      double.infinity,
      scaler,
    );
    final head = _paint(
      then.headline,
      thenHeadStyle(panelFont * 0.92, Colors.black),
      math.max(1, clipW - 2 * thenPad - year.width - 12),
      scaler,
    );
    final h = math.max(year.height, head.height) + 2 * thenPad;
    year.dispose();
    head.dispose();
    return h;
  }

  /// The head row of a step: its label, and the button to the next.
  double headH(TextScaler scaler) => math.max(chipH, mast(scaler));

  static TextPainter _paint(
    String text,
    TextStyle style,
    double width,
    TextScaler scaler,
  ) => TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
    textScaler: scaler,
  )..layout(maxWidth: width);

  static double _clipH(
    String headline,
    double font,
    double width,
    TextScaler scaler,
  ) {
    final hp = _paint(
      headline,
      headStyle(font, Colors.black),
      width - shadow - 2 * pad,
      scaler,
    );
    final h = headTop(scaler) + hp.height + 13;
    hp.dispose();
    return h;
  }

  static _NewsLayout measure(NewsScene s, Size size, TextScaler scaler) {
    final h = size.height;
    final w = size.width;
    final tight = h < 340;

    // Before the first tap: the clipping as large as the contents allow.
    final rowFont0 = (h * 0.04).clamp(15.0, 19.0);
    final rowH = math.max(
      tight ? 40.0 : 46.0,
      rowFont0 * 1.15 * scaler.scale(1) + 20,
    );
    final rows = s.steps * rowH + (s.steps - 1) * rowH * 0.2;
    var headBig = (h * 0.075).clamp(20.0, 34.0);
    var clipBig = _clipH(s.headline, headBig, w, scaler);
    while (headBig > 15 && clipBig + tear + shadow + 14 + rows > h) {
      headBig -= 1;
      clipBig = _clipH(s.headline, headBig, w, scaler);
    }

    // After it: the steps first, then the clipping in what is left.
    var panel = (h * 0.054).clamp(15.0, 25.0);
    var headSmall = math.min(
      headBig,
      math.max(panel * 1.15, (h * 0.055).clamp(17.0, 28.0)),
    );
    late _NewsLayout out;
    while (true) {
      out = _NewsLayout._(
        size: size,
        headBig: headBig,
        headSmall: headSmall,
        panelFont: panel,
        rowFont: rowFont0,
        chipFont: (panel * 0.82).clamp(12.5, 15.0),
        clipBig: clipBig,
        clipSmall: _clipH(s.headline, headSmall, w, scaler),
        rowH: rowH,
        tight: tight,
      );
      final room = out.panelRoom - out.headH(scaler) - out.headGap;
      var tallest = 0.0;
      for (final p in s.panels) {
        var ph = 0.0;
        if (p.hasFigure) {
          final f = _paint(
            p.figure,
            figStyle(out.figFont, Colors.black),
            double.infinity,
            scaler,
          );
          ph += f.height + (tight ? 4 : 8);
          f.dispose();
        }
        final tp = _paint(p.text, textStyle(panel, Colors.black), w, scaler);
        ph += tp.height;
        tp.dispose();
        tallest = math.max(tallest, ph);
      }
      if (s.then != null) {
        final line = _paint(
          s.then!.line,
          textStyle(panel * 0.94, Colors.black),
          w,
          scaler,
        );
        tallest = math.max(
          tallest,
          out.thenClipH(s.then!, scaler) +
              tear +
              (tight ? 6 : 12) +
              line.height,
        );
        line.dispose();
      }
      if (tallest <= room) break;
      // The headline gives way first, down to a little over the steps' type.
      if (headSmall > math.max(14.0, panel * 1.08)) {
        headSmall -= 1;
      } else if (panel > 13) {
        panel -= 0.5;
        headSmall = math.min(headSmall, math.max(14.0, panel * 1.08) + 1);
      } else {
        break;
      }
    }
    return out;
  }
}

/// Today's clipping: the masthead, the double rule, the headline. As the
/// first step opens it folds: the paper shortens and the headline is reset
/// smaller, the large one fading as the small one comes in.
class _Clipping extends StatelessWidget {
  final NewsScene scene;
  final _NewsLayout layout;

  /// 0 the clipping at its largest, 1 folded.
  final double fold;
  final Color ink;
  final Color ground;
  final String date;
  const _Clipping({
    required this.scene,
    required this.layout,
    required this.fold,
    required this.ink,
    required this.ground,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    final l = layout;
    final scaler = MediaQuery.textScalerOf(context);
    final label = _NewsLayout.labelStyle(ink.withValues(alpha: 0.78));
    final height = l.clipBig + (l.clipSmall - l.clipBig) * fold;
    final top = _NewsLayout.headTop(scaler);
    Widget headline(double font, double opacity) => Positioned(
      left: _NewsLayout.pad,
      right: _NewsLayout.shadow + _NewsLayout.pad,
      top: top,
      child: Opacity(
        opacity: opacity.clamp(0.0, 1.0),
        child: Text(scene.headline, style: _NewsLayout.headStyle(font, ink)),
      ),
    );
    final same = l.clipBig == l.clipSmall && l.headBig == l.headSmall;
    return Semantics(
      container: true,
      header: true,
      label: '${scene.outlet}, $date. ${scene.headline}',
      child: ExcludeSemantics(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _PaperPainter(
                  width: l.clipW,
                  height: height,
                  seed: scene.headline.hashCode,
                  fill: Color.alphaBlend(ink.withValues(alpha: 0.045), ground),
                  edge: ink,
                  shadow: ink,
                  rules: 12 + _NewsLayout.mast(scaler) + 8,
                ),
              ),
            ),
            Positioned(
              left: _NewsLayout.pad,
              right: _NewsLayout.shadow + _NewsLayout.pad,
              top: 12,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      scene.outlet.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: label,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(date.toUpperCase(), style: label),
                ],
              ),
            ),
            // The headline is kept to the paper while it folds.
            Positioned(
              left: 0,
              top: 0,
              width: l.clipW,
              height: height,
              child: ClipRect(
                child: Stack(
                  children: [
                    if (same)
                      headline(l.headBig, 1)
                    else ...[
                      if (fold < .5) headline(l.headBig, 1 - fold * 2.2),
                      if (fold > .4) headline(l.headSmall, (fold - .45) * 2),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A sheet of paper with a torn bottom edge, an offset shadow, and the
/// double rule under the masthead. Inverse paper (the past case) has no
/// shadow and no rules.
class _PaperPainter extends CustomPainter {
  final double width;
  final double height;
  final int seed;
  final Color fill;
  final Color edge;
  final Color? shadow;

  /// Where the double rule sits, or null for none.
  final double? rules;

  _PaperPainter({
    required this.width,
    required this.height,
    required this.seed,
    required this.fill,
    required this.edge,
    this.shadow,
    this.rules,
  });

  final Paint _fill = Paint();
  final Paint _line = Paint()
    ..style = PaintingStyle.stroke
    ..strokeJoin = StrokeJoin.round;

  /// The sheet: square top corners softened, the bottom torn in uneven
  /// teeth whose pattern comes from [seed], so a card always tears the same.
  Path _sheet() {
    final rnd = math.Random(seed);
    const r = 3.0;
    final p = Path()
      ..moveTo(0, r)
      ..quadraticBezierTo(0, 0, r, 0)
      ..lineTo(width - r, 0)
      ..quadraticBezierTo(width, 0, width, r)
      ..lineTo(width, height);
    var x = width;
    var up = true;
    while (x > 0) {
      x = math.max(0, x - (5 + rnd.nextDouble() * 7));
      final y = height + (up ? 0.6 : 3.4 + rnd.nextDouble() * 3.6);
      p.lineTo(x, y);
      up = !up;
    }
    return p..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final sheet = _sheet();
    if (shadow != null) {
      _fill.color = shadow!;
      canvas.drawPath(
        sheet.shift(const Offset(_NewsLayout.shadow, _NewsLayout.shadow)),
        _fill,
      );
    }
    _fill.color = fill;
    canvas.drawPath(sheet, _fill);
    _line
      ..color = edge
      ..strokeWidth = 1.6;
    canvas.drawPath(sheet, _line);
    if (rules != null) {
      const x0 = _NewsLayout.pad, gap = 2.2;
      final x1 = width - _NewsLayout.pad;
      _fill.color = edge;
      canvas.drawRect(Rect.fromLTRB(x0, rules!, x1, rules! + 2.6), _fill);
      canvas.drawRect(
        Rect.fromLTRB(x0, rules! + 2.6 + gap, x1, rules! + 3.6 + gap),
        _fill,
      );
    }
  }

  @override
  bool shouldRepaint(_PaperPainter old) =>
      old.width != width ||
      old.height != height ||
      old.seed != seed ||
      old.fill != fill ||
      old.edge != edge ||
      old.shadow != shadow ||
      old.rules != rules;
}

/// A line of the contents: its number, its label, and on the first an
/// arrow; the first is solid, the rest wait.
class _ContentsRow extends StatelessWidget {
  final int number;
  final String label;
  final bool first;
  final double nudge;
  final double font;
  final Color ink;
  final Color ground;
  final VoidCallback? onTap;
  const _ContentsRow({
    required this.number,
    required this.label,
    required this.first,
    required this.nudge,
    required this.font,
    required this.ink,
    required this.ground,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final face = first ? ground : ink.withValues(alpha: 0.62);
    final row = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Text(
              number.toString().padLeft(2, '0'),
              style: _NewsLayout.labelStyle(
                first ? ground.withValues(alpha: 0.8) : face,
              ),
            ),
          ),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.display(
                size: font,
                weight: FontWeight.w700,
                height: 1.15,
                spacing: -0.2,
                color: face,
              ),
            ),
          ),
          if (first)
            Transform.translate(
              offset: Offset(nudge, 0),
              child: SizedBox(
                width: 18,
                height: 14,
                child: CustomPaint(painter: _ArrowPainter(ground)),
              ),
            ),
        ],
      ),
    );
    if (!first) {
      return ExcludeSemantics(
        child: DecoratedBox(
          decoration: ShapeDecoration(
            shape: StadiumBorder(
              side: BorderSide(color: ink.withValues(alpha: 0.28), width: 1.4),
            ),
          ),
          child: row,
        ),
      );
    }
    return Semantics(
      button: true,
      label: label,
      onTap: onTap,
      child: ExcludeSemantics(
        child: Material(
          color: ink,
          shape: const StadiumBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            splashColor: ground.withValues(alpha: 0.2),
            highlightColor: ground.withValues(alpha: 0.1),
            child: row,
          ),
        ),
      ),
    );
  }
}

/// Three bars under the clipping: read ones half-filled, the one on show
/// solid, the rest faint. Each read bar is a button back to its step.
class _Strip extends StatelessWidget {
  final int steps;
  final int open;
  final int view;
  final int from;

  /// 0 → 1: the bar on show filling.
  final double t;
  final String Function(int) labelOf;
  final Color ink;
  final void Function(int) onShow;
  const _Strip({
    required this.steps,
    required this.open,
    required this.view,
    required this.from,
    required this.t,
    required this.labelOf,
    required this.ink,
    required this.onShow,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < steps; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(
            child: Semantics(
              button: i < open,
              selected: i == view,
              label: labelOf(i),
              onTap: i < open && i != view ? () => onShow(i) : null,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: i < open ? () => onShow(i) : null,
                child: Center(
                  child: CustomPaint(
                    size: const Size(double.infinity, 5),
                    painter: _BarPainter(
                      fill: i == view
                          ? 1
                          : i < open
                          ? (i == from ? 1 - t * 0.6 : 0.4)
                          : 0,
                      grow: i == view && i == open - 1 && i != from ? t : 1,
                      ink: ink,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _BarPainter extends CustomPainter {
  /// How solid the bar is: 1 the step on show, 0.4 read, 0 not yet.
  final double fill;

  /// 0 → 1: the solid part sweeping in from the left.
  final double grow;
  final Color ink;
  _BarPainter({required this.fill, required this.grow, required this.ink});

  final Paint _p = Paint();

  @override
  void paint(Canvas canvas, Size size) {
    final r = Radius.circular(size.height / 2);
    _p.color = ink.withValues(alpha: 0.16);
    canvas.drawRRect(RRect.fromRectAndRadius(Offset.zero & size, r), _p);
    if (fill <= 0 || grow <= 0) return;
    _p.color = ink.withValues(alpha: fill.clamp(0.0, 1.0));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width * grow, size.height),
        r,
      ),
      _p,
    );
  }

  @override
  bool shouldRepaint(_BarPainter old) =>
      old.fill != fill || old.grow != grow || old.ink != ink;
}

/// The head of a step: its label, and the button that names the step to
/// come ("Why →"), so the reader meets the question before the answer.
class _StepHead extends StatelessWidget {
  final String label;

  /// "2 OF 3", for a screen reader: the bars say it to the eye.
  final String count;
  final String? next;
  final VoidCallback onNext;
  final _NewsLayout layout;
  final Color ink;
  final Color ground;
  const _StepHead({
    required this.label,
    required this.count,
    required this.next,
    required this.onNext,
    required this.layout,
    required this.ink,
    required this.ground,
  });

  @override
  Widget build(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    return SizedBox(
      height: layout.headH(scaler),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              label: '$label, $count',
              child: ExcludeSemantics(
                child: Text(
                  label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _NewsLayout.labelStyle(ink),
                ),
              ),
            ),
          ),
          if (next != null) ...[
            const SizedBox(width: 10),
            _NextButton(
              label: next!,
              font: layout.chipFont,
              ink: ink,
              ground: ground,
              onTap: onNext,
            ),
          ],
        ],
      ),
    );
  }
}

/// A step: its number set large when it has one, then its text.
class _PanelBody extends StatelessWidget {
  final NewsPanel panel;
  final Widget head;
  final _NewsLayout layout;

  /// 0 → 1: the step arriving; the number lands a beat after the label.
  final double arrive;
  final Color ink;
  const _PanelBody({
    required this.panel,
    required this.head,
    required this.layout,
    required this.arrive,
    required this.ink,
  });

  @override
  Widget build(BuildContext context) {
    final f = Curves.easeOutBack.transform(
      ((arrive - 0.25) / 0.75).clamp(0.0, 1.0),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        head,
        SizedBox(height: layout.headGap),
        if (panel.hasFigure) ...[
          Transform.scale(
            scale: 0.9 + 0.1 * f,
            alignment: Alignment.bottomLeft,
            child: Text(
              panel.figure,
              style: _NewsLayout.figStyle(layout.figFont, ink),
            ),
          ),
          SizedBox(height: layout.tight ? 4 : 8),
        ],
        Text(panel.text, style: _NewsLayout.textStyle(layout.panelFont, ink)),
      ],
    );
  }
}

/// The past case: an older clipping printed in reverse, the year beside
/// that time's headline, and the line on what the two share.
class _ThenBody extends StatelessWidget {
  final NewsThen then;
  final Widget head;
  final _NewsLayout layout;
  final double arrive;
  final Color ink;
  final Color ground;
  const _ThenBody({
    required this.then,
    required this.head,
    required this.layout,
    required this.arrive,
    required this.ink,
    required this.ground,
  });

  @override
  Widget build(BuildContext context) {
    final l = layout;
    final h = l.thenClipH(then, MediaQuery.textScalerOf(context));
    // The old clipping drops in from above; the line follows it.
    final drop = Curves.easeOutCubic.transform(
      ((arrive - 0.1) / 0.6).clamp(0.0, 1.0),
    );
    final line = ((arrive - 0.5) / 0.5).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        head,
        SizedBox(height: l.headGap),
        Transform.translate(
          offset: Offset(0, -12 * (1 - drop)),
          child: SizedBox(
            width: l.clipW,
            height: h + _NewsLayout.tear,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _PaperPainter(
                      width: l.clipW,
                      height: h,
                      seed: then.headline.hashCode,
                      fill: ink,
                      edge: ink,
                    ),
                  ),
                ),
                Positioned(
                  left: l.thenPad,
                  right: l.thenPad,
                  top: l.thenPad,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${then.year}',
                        style: _NewsLayout.figStyle(l.yearFont, ground),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 1),
                          child: Text(
                            then.headline,
                            style: _NewsLayout.thenHeadStyle(
                              l.panelFont * 0.92,
                              ground,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: l.tight ? 6 : 12),
        Opacity(
          opacity: line,
          child: Text(
            then.line,
            style: _NewsLayout.textStyle(l.panelFont * 0.94, ink),
          ),
        ),
      ],
    );
  }
}

/// The button that names the step to come.
class _NextButton extends StatelessWidget {
  final String label;
  final double font;
  final Color ink;
  final Color ground;
  final VoidCallback onTap;
  const _NextButton({
    required this.label,
    required this.font,
    required this.ink,
    required this.ground,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    button: true,
    label: label,
    onTap: onTap,
    child: ExcludeSemantics(
      child: Material(
        color: ink,
        shape: const StadiumBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          splashColor: ground.withValues(alpha: 0.2),
          highlightColor: ground.withValues(alpha: 0.1),
          child: SizedBox(
            height: _NewsLayout.chipH,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 12, 0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label, style: _NewsLayout.chipStyle(font, ground)),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 14,
                    height: 10,
                    child: CustomPaint(painter: _ArrowPainter(ground)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _ArrowPainter extends CustomPainter {
  final Color color;
  _ArrowPainter(this.color);

  late final Paint _stroke = Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.2
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    canvas.drawLine(Offset(1.5, h / 2), Offset(w - 1.5, h / 2), _stroke);
    canvas.drawPath(
      Path()
        ..moveTo(w - h / 2 - 1, 1.5)
        ..lineTo(w - 1.5, h / 2)
        ..lineTo(w - h / 2 - 1, h - 1.5),
      _stroke,
    );
  }

  @override
  bool shouldRepaint(_ArrowPainter old) => old.color != color;
}
