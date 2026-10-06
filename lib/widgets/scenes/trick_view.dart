import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart' show OrdinalSortKey;
import 'package:flutter/services.dart';

import '../../l10n/l10n.dart';
import '../../models/scene.dart';
import '../../theme.dart';

/// Plays a [TrickScene]: find the trick in a chart, then watch it undone.
///
/// The chart sits on a clipping, a panel a shade darker than the card, with
/// where it ran, its headline, what it measures, and the chart itself. When
/// the card arrives each part the reader can tap is outlined once in turn,
/// so the chart is seen to be a set of pieces to question rather than a
/// picture. A tap draws a selection box round that part, the way an editor
/// marks a word. A wrong part shakes, stays faintly crossed, and the line
/// under the clipping says why it is innocent; "Show me" waits beside it.
/// The right part is boxed for good with a tick, the reader is told, and
/// the chart turns honest in place: the axis falls to zero, the window
/// opens, the totals drain and refill as rates, the pie unrolls into bars.
/// The headline changes to the one it should have had, and the trick's name
/// and a line to keep take the place under the clipping.
///
/// Every state is also said in words (the lines under the clipping, the
/// tick and cross beside a box), never by motion alone; with animations off
/// the honest chart is there on the next frame.
class TrickSceneView extends StatefulWidget {
  final TrickScene scene;
  final Color ink;
  final Color ground;
  const TrickSceneView({
    super.key,
    required this.scene,
    required this.ink,
    required this.ground,
  });

  @override
  State<TrickSceneView> createState() => _TrickSceneViewState();
}

class _TrickSceneViewState extends State<TrickSceneView>
    with TickerProviderStateMixin {
  /// Parts tapped that were not the trick, in the order tried.
  final List<TrickSceneRegion> _tried = [];

  /// The part tapped last, the one whose box pops and whose line shows.
  TrickSceneRegion? _last;

  /// Fixed when the trick is found or shown.
  bool _solved = false;
  bool _found = false;

  /// Each part outlined once in turn on arrival. Its first stretch is the
  /// wait; no Timer, which would outlive a disposed widget and hang a test.
  late final AnimationController _nudge = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );
  bool _started = false;

  /// A box popping in, or shaking off a wrong tap.
  late final AnimationController _pop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  /// The way to the honest chart: a pause on the box, the change, then the
  /// lesson. One clock, so a test can run it to the end.
  late final AnimationController _reveal = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2800),
  );

  final _TrickTextCache _texts = _TrickTextCache();

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
  void didUpdateWidget(TrickSceneView old) {
    super.didUpdateWidget(old);
    if (old.scene.raw != widget.scene.raw) {
      _tried.clear();
      _last = null;
      _solved = false;
      _found = false;
      _pop.value = 1;
      _reveal.value = 0;
    }
    if (old.ink != widget.ink) _texts.clear();
  }

  @override
  void dispose() {
    _nudge.dispose();
    _pop.dispose();
    _reveal.dispose();
    super.dispose();
  }

  bool get _still => MediaQuery.disableAnimationsOf(context);

  void _tap(TrickSceneRegion r) {
    if (_solved) return;
    _nudge.stop();
    _nudge.value = 1;
    final s = widget.scene;
    if (s.isTrick(r)) {
      HapticFeedback.lightImpact();
      setState(() {
        _last = r;
        _solved = true;
        _found = true;
      });
      _play();
    } else {
      HapticFeedback.selectionClick();
      setState(() {
        _last = r;
        if (!_tried.contains(r)) _tried.add(r);
      });
      if (_still) {
        _pop.value = 1;
      } else {
        _pop.forward(from: 0);
      }
    }
  }

  void _showMe() {
    if (_solved) return;
    HapticFeedback.lightImpact();
    _nudge.stop();
    setState(() {
      _solved = true;
      _found = false;
      _last = null;
    });
    _play();
  }

  void _play() {
    if (_still) {
      _pop.value = 1;
      _reveal.value = 1;
    } else {
      _pop.forward(from: 0);
      _reveal.forward(from: 0);
    }
  }

  /// 0 → 1 across the part of the reveal where the chart changes.
  double get _morph => ((_reveal.value - .16) / .6).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final tight = box.maxHeight < 340;
        final footerH = tight ? 78.0 : 92.0;
        final gap = tight ? 8.0 : 12.0;
        final panelH = math.max(0.0, box.maxHeight - footerH - gap);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: panelH,
              width: box.maxWidth,
              child: _panel(Size(box.maxWidth, panelH), tight),
            ),
            SizedBox(height: gap),
            SizedBox(
              height: footerH,
              width: box.maxWidth,
              child: AnimatedBuilder(
                animation: _reveal,
                builder: (context, _) => _footer(tight),
              ),
            ),
          ],
        );
      },
    );
  }

  // ---- the clipping ----

  Widget _panel(Size size, bool tight) {
    final s = widget.scene;
    final ink = widget.ink;
    final scaler = MediaQuery.textScalerOf(context);
    final layout = _TrickLayout.of(
      scene: s,
      size: size,
      tight: tight,
      scaler: scaler,
      texts: _texts,
      ink: ink,
    );

    return Stack(
      children: [
        // The clipping, its parts drawn and boxed. A tap on a part is read
        // here; a drag is claimed and dropped so it never swipes the deck
        // while the reader is still looking. Once solved, the card is free.
        Positioned.fill(
          child: ExcludeSemantics(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: _solved
                  ? null
                  : (d) {
                      final r = layout.hit(d.localPosition);
                      if (r != null) _tap(r);
                    },
              onHorizontalDragStart: _solved ? null : (_) {},
              onVerticalDragStart: _solved ? null : (_) {},
              child: RepaintBoundary(
                child: AnimatedBuilder(
                  animation: Listenable.merge([_nudge, _pop, _reveal]),
                  builder: (context, _) {
                    final m = _morph;
                    final frame = _TrickFrame(
                      morph: m,
                      nudge: _nudge.value,
                      pop: _pop.value,
                      tried: List.unmodifiable(_tried),
                      last: _last,
                      solved: _solved,
                      found: _found,
                      settle: ((_reveal.value - .8) / .2).clamp(0.0, 1.0),
                    );
                    return Stack(
                      children: [
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _TrickChartPainter(
                              scene: s,
                              layout: layout,
                              frame: frame,
                              ink: ink,
                              ground: widget.ground,
                              texts: _texts,
                            ),
                          ),
                        ),
                        ..._words(layout, m),
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _TrickBoxPainter(
                              scene: s,
                              layout: layout,
                              frame: frame,
                              ink: ink,
                              ground: widget.ground,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
        ..._regionNodes(layout),
      ],
    );
  }

  /// The outlet, the headline and the label, set as text so they stay
  /// crisp as they change: the headline to the honest one late in the
  /// change, a totals label to the rate as the bars refill.
  List<Widget> _words(_TrickLayout l, double m) {
    final s = widget.scene;
    final ink = widget.ink;
    final h = Curves.easeInOut.transform(((m - .55) / .4).clamp(0.0, 1.0));
    final relabel = s.refills
        ? Curves.easeInOut.transform(((m - .4) / .2).clamp(0.0, 1.0))
        : 0.0;
    Widget headline(String text, double opacity, double dy) => Positioned(
      left: l.headline.left,
      top: l.headline.top + dy,
      width: l.headline.width,
      child: Opacity(
        opacity: opacity,
        child: Text(
          text,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: l.headlineStyle(ink),
        ),
      ),
    );
    Widget label(String text, double opacity) => Positioned(
      left: l.label.left,
      top: l.label.top,
      width: l.label.width,
      child: Opacity(
        opacity: opacity,
        child: Text(
          text.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: l.labelStyle(ink),
        ),
      ),
    );
    return [
      if (l.outlet != null)
        Positioned(
          left: l.outlet!.left,
          top: l.outlet!.top,
          width: l.outlet!.width,
          child: Text(
            s.outlet.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.label(
              size: 10,
              weight: FontWeight.w700,
              spacing: 1.6,
              color: ink.withValues(alpha: 0.55),
            ),
          ),
        ),
      if (h < 1) headline(s.headline, 1 - h, -6 * h),
      if (h > 0) headline(s.honest, h, 6 * (1 - h)),
      if (relabel < 1) label(s.label, 1 - relabel),
      if (relabel > 0) label(s.honestLabel, relabel),
    ];
  }

  /// One screen-reader button per part, over the drawing: it speaks the
  /// part's own content and taps it the way a finger does.
  List<Widget> _regionNodes(_TrickLayout l) {
    final s = widget.scene;
    final out = <Widget>[];
    var order = 0;
    for (final r in s.regions) {
      final rect = l.regions[r];
      if (rect == null) continue;
      final crossed = _tried.contains(r);
      final boxed = _solved && s.isTrick(r);
      out.add(
        Positioned.fromRect(
          rect: rect,
          child: Semantics(
            container: true,
            button: !_solved,
            sortKey: OrdinalSortKey((order++).toDouble()),
            label: _speak(r),
            value: boxed
                ? s.name
                : crossed
                ? s.missFor(r)
                : null,
            onTap: _solved ? null : () => _tap(r),
            child: const SizedBox.expand(),
          ),
        ),
      );
    }
    return out;
  }

  /// What a part says to a screen reader: its content, never its shape.
  String _speak(TrickSceneRegion r) {
    final s = widget.scene;
    final f = _TrickFormat(s);
    final after = _solved;
    switch (r) {
      case TrickSceneRegion.headline:
        return after ? s.honest : s.headline;
      case TrickSceneRegion.label:
        if (s.form == TrickSceneForm.pie) {
          return [
            for (var i = 0; i < s.count; i++)
              '${s.columns[i]} ${f.value(s.values[i], honest: false)}',
          ].join(', ');
        }
        return after ? s.honestLabel : s.label;
      case TrickSceneRegion.yaxis:
        final range = after ? s.fair : s.shown;
        return '${f.tick(range.lo, range)} – ${f.tick(range.hi, range)}';
      case TrickSceneRegion.yaxis2:
        final range = after ? s.fair : s.shown2;
        return '${f.tick(range.lo, range)} – ${f.tick(range.hi, range)}';
      case TrickSceneRegion.xaxis:
        final a = after ? 0 : s.first;
        final b = after ? s.count - 1 : s.last;
        return '${s.columns[a]} – ${s.columns[b]}';
      case TrickSceneRegion.marks:
        if (s.form == TrickSceneForm.pie) {
          return [
            for (var i = 0; i < s.count; i++)
              '${s.columns[i]} ${f.value(s.values[i], honest: false)}',
          ].join(', ');
        }
        final vs = after ? s.honestValues : s.values;
        final a = after ? 0 : s.first;
        final b = after ? s.count - 1 : s.last;
        final idx = s.form == TrickSceneForm.bars
            ? [for (var i = a; i <= b; i++) i]
            : [a, b];
        return [
          for (final i in idx) '${s.columns[i]} ${f.value(vs[i], honest: after)}',
          if (s.trick == TrickSceneKind.dual)
            for (final i in idx)
              '${s.series[1]}, ${s.columns[i]} ${f.value(s.values2[i], honest: after)}',
        ].join(', ');
    }
  }

  // ---- the line under the clipping ----

  Widget _footer(bool tight) {
    final s = widget.scene;
    final ink = widget.ink;
    final l10n = context.l10n;
    final lesson = _solved && (!_found || _reveal.value >= .8);

    final Widget child;
    final String key;
    if (lesson) {
      key = 'lesson';
      child = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.display(
              size: tight ? 19 : 23,
              weight: FontWeight.w800,
              height: 1.1,
              spacing: -0.4,
              color: ink,
            ),
          ),
          SizedBox(height: tight ? 3 : 5),
          Text(
            s.lesson,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: AppText.body(
              size: tight ? 13 : 14.5,
              weight: FontWeight.w600,
              height: 1.3,
              color: ink.withValues(alpha: 0.9),
            ),
          ),
        ],
      );
    } else if (_solved) {
      key = 'found';
      child = Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: _TrickBadge(ink: ink, ground: widget.ground, right: true),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              s.found,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: AppText.display(
                size: tight ? 17 : 20,
                weight: FontWeight.w700,
                height: 1.18,
                spacing: -0.3,
                color: ink,
              ),
            ),
          ),
        ],
      );
    } else if (_last != null) {
      key = 'miss-${_last!.name}';
      child = Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: _TrickBadge(ink: ink, ground: widget.ground, right: false),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              s.missFor(_last!),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: AppText.body(
                size: tight ? 13.5 : 14.5,
                weight: FontWeight.w600,
                height: 1.3,
                color: ink.withValues(alpha: 0.92),
              ),
            ),
          ),
          const SizedBox(width: 10),
          _ShowMe(
            label: l10n.sceneShowMe,
            ink: ink,
            ground: widget.ground,
            onTap: _showMe,
          ),
        ],
      );
    } else {
      key = 'ask';
      child = Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox.square(
            dimension: 22,
            child: CustomPaint(
              painter: _TapMarkPainter(ink.withValues(alpha: 0.7)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              s.ask.isEmpty ? l10n.sceneTapToPick : s.ask,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppText.display(
                size: tight ? 18 : 21,
                weight: FontWeight.w700,
                height: 1.15,
                spacing: -0.3,
                color: ink,
              ),
            ),
          ),
        ],
      );
    }

    return Semantics(
      liveRegion: true,
      child: AnimatedSwitcher(
        duration: _still ? Duration.zero : const Duration(milliseconds: 280),
        transitionBuilder: (child, a) => FadeTransition(
          opacity: a,
          child: SlideTransition(
            position: Tween(
              begin: const Offset(0, .18),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
            child: child,
          ),
        ),
        layoutBuilder: (current, previous) => Stack(
          alignment: Alignment.topLeft,
          children: [...previous, ?current],
        ),
        child: Align(
          key: ValueKey(key),
          alignment: Alignment.topLeft,
          child: child,
        ),
      ),
    );
  }
}

// ---- numbers ----

/// How the chart writes its numbers.
class _TrickFormat {
  final TrickScene scene;
  const _TrickFormat(this.scene);

  static String plain(double v, int decimals) {
    final fixed = v.abs().toStringAsFixed(decimals);
    final parts = fixed.split('.');
    final whole = parts[0].replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => ',',
    );
    return '${v < 0 ? '−' : ''}$whole${parts.length > 1 ? '.${parts[1]}' : ''}';
  }

  static String withUnit(String n, String unit) {
    if (unit.isEmpty) return n;
    if (const {'€', r'$', '£', '¥'}.contains(unit)) {
      return n.startsWith('−') ? '−$unit${n.substring(1)}' : '$unit$n';
    }
    if (unit == '%' || unit.startsWith('°')) return '$n$unit';
    return '$n $unit';
  }

  /// A value as printed on a bar or a point.
  String value(double v, {required bool honest}) {
    final s = scene;
    final unit = honest ? s.honestUnit : s.unit;
    return withUnit(
      plain(v, honest ? s.honestDecimals : s.decimals),
      // A pie's numbers are shares, whatever the writer left out.
      unit.isEmpty && s.form == TrickSceneForm.pie ? '%' : unit,
    );
  }

  /// A mark on the value axis: as many decimals as the step needs, large
  /// numbers shortened, the unit only when it is short enough to sit there.
  String tick(double v, TrickSceneRange range, [int parts = 4]) {
    final step = TrickScene.tidyStep(range.hi - range.lo, parts);
    final big = math.max(range.hi.abs(), range.lo.abs());
    String n;
    if (big >= 1e5) {
      final (div, suffix) = big >= 1e9
          ? (1e9, 'B')
          : big >= 1e6
          ? (1e6, 'M')
          : (1e3, 'k');
      final d = _decimalsOf(step / div);
      n = v == 0 ? '0' : '${plain(v / div, d)}$suffix';
    } else {
      n = plain(v, _decimalsOf(step));
    }
    final unit = scene.unit;
    final short =
        unit == '%' || unit.startsWith('°') || const {'€', r'$', '£', '¥'}.contains(unit);
    return short ? withUnit(n, unit) : n;
  }

  static int _decimalsOf(double step) {
    for (var d = 0; d < 4; d++) {
      final f = step * math.pow(10, d);
      if ((f - f.roundToDouble()).abs() < 1e-6) return d;
    }
    return 3;
  }
}

// ---- layout ----

/// Where everything on the clipping goes, worked out once per size and
/// read by the painters, the hit test and the screen-reader nodes alike.
class _TrickLayout {
  final TrickScene scene;
  final Size size;
  final bool tight;
  final double headlineSize;
  final Rect? outlet;
  final Rect headline;
  final Rect label;

  /// The drawing area under the label: plot and gutters together.
  final Rect chart;

  /// Where values map to, inside the gutters.
  final Rect plot;
  final TextScaler scaler;

  /// A pie's disc, and the rows of its answers.
  final Rect pie;
  final Rect rows;

  /// The tappable parts, in panel coordinates, and the boxes drawn round
  /// them.
  final Map<TrickSceneRegion, Rect> regions;
  final Map<TrickSceneRegion, Rect> boxes;

  /// How many steps the value axis is cut into: fewer on a short chart, so
  /// its labels never crowd.
  final int parts;

  _TrickLayout._({
    required this.scene,
    required this.size,
    required this.tight,
    required this.headlineSize,
    required this.outlet,
    required this.headline,
    required this.label,
    required this.chart,
    required this.plot,
    required this.scaler,
    required this.pie,
    required this.rows,
    required this.regions,
    required this.boxes,
    required this.parts,
  });

  static const pad = EdgeInsets.fromLTRB(14, 12, 14, 10);

  TextStyle headlineStyle(Color ink) => AppText.display(
    size: headlineSize,
    weight: FontWeight.w800,
    height: 1.08,
    spacing: -0.3 - headlineSize * 0.012,
    color: ink,
  );

  TextStyle labelStyle(Color ink) => AppText.label(
    size: 10.5,
    weight: FontWeight.w700,
    spacing: 1.3,
    color: ink.withValues(alpha: 0.62),
  );

  static TextStyle tickStyle(Color ink) =>
      AppText.label(size: 10.5, weight: FontWeight.w700, spacing: 0.2, color: ink);

  factory _TrickLayout.of({
    required TrickScene scene,
    required Size size,
    required bool tight,
    required TextScaler scaler,
    required _TrickTextCache texts,
    required Color ink,
  }) {
    final s = scene;
    final inner = pad.deflateRect(Offset.zero & size);
    var y = inner.top;

    Rect? outlet;
    if (s.outlet.isNotEmpty && !tight) {
      outlet = Rect.fromLTWH(inner.left, y, inner.width, scaler.scale(13));
      y = outlet.bottom + 5;
    }

    final hs = tight ? 18.0 : (inner.width * 0.072).clamp(20.0, 26.0);
    double measure(String text) {
      final tp = TextPainter(
        text: TextSpan(
          text: text,
          style: AppText.display(
            size: hs,
            weight: FontWeight.w800,
            height: 1.08,
            spacing: -0.3 - hs * 0.012,
          ),
        ),
        maxLines: 2,
        textDirection: TextDirection.ltr,
        textScaler: scaler,
      )..layout(maxWidth: inner.width);
      final h = tp.height;
      tp.dispose();
      return h;
    }

    final headline = Rect.fromLTWH(
      inner.left,
      y,
      inner.width,
      math.max(measure(s.headline), measure(s.honest)),
    );
    y = headline.bottom + (tight ? 8 : 12);
    final label = Rect.fromLTWH(inner.left, y, inner.width, scaler.scale(13));
    y = label.bottom + (tight ? 6 : 9);
    final chart = Rect.fromLTRB(inner.left, y, inner.right, inner.bottom);

    final f = _TrickFormat(s);
    final style = tickStyle(ink);
    double widest(Iterable<String> labels) {
      var w = 0.0;
      for (final t in labels) {
        w = math.max(w, texts.get(t, style, scaler).width);
      }
      return w;
    }

    final regions = <TrickSceneRegion, Rect>{};
    Rect inflateTo(Rect r, {double minW = 44, double minH = 44}) {
      final dx = math.max(0.0, (minW - r.width) / 2);
      final dy = math.max(0.0, (minH - r.height) / 2);
      return Rect.fromLTRB(r.left - dx, r.top - dy, r.right + dx, r.bottom + dy);
    }

    // What is drawn round a part when it is tapped: hugging what the part
    // shows, where the area a finger may hit is more generous.
    final boxes = <TrickSceneRegion, Rect>{};
    boxes[TrickSceneRegion.headline] = Rect.fromLTRB(
      inner.left - 6,
      headline.top - 3,
      inner.right + 6,
      headline.bottom + 2,
    );
    regions[TrickSceneRegion.headline] = Rect.fromLTRB(
      inner.left - 6,
      (outlet?.top ?? headline.top) - 4,
      inner.right + 6,
      headline.bottom + 3,
    );

    var plot = chart;
    var pie = Rect.zero;
    var rows = Rect.zero;

    if (s.form == TrickSceneForm.pie) {
      final d = math.min(chart.height, chart.width * 0.42);
      pie = Rect.fromLTWH(
        chart.left,
        chart.top + (chart.height - d) / 2,
        d,
        d,
      );
      rows = Rect.fromLTRB(pie.right + 16, chart.top, chart.right, chart.bottom);
      regions[TrickSceneRegion.label] = Rect.fromLTRB(
        rows.left - 6,
        label.top - 6,
        rows.right + 6,
        chart.bottom + 4,
      );
      regions[TrickSceneRegion.marks] = pie.inflate(6);
      boxes[TrickSceneRegion.label] = regions[TrickSceneRegion.label]!;
      boxes[TrickSceneRegion.marks] = pie.inflate(4);
      // The label line over a pie belongs with the answers it heads.
    } else {
      final ticks = [
        ...TrickScene.ticks(s.shown).map((v) => f.tick(v, s.shown)),
        ...TrickScene.ticks(s.fair).map((v) => f.tick(v, s.fair)),
      ];
      final left = widest(ticks) + 12;
      var right = 0.0;
      if (s.trick == TrickSceneKind.dual) {
        right =
            widest([
              ...TrickScene.ticks(s.shown2).map((v) => f.tick(v, s.shown2)),
              ...TrickScene.ticks(s.fair).map((v) => f.tick(v, s.fair)),
            ]) +
            8;
      }
      final bars = s.form == TrickSceneForm.bars;
      final xGutter = scaler.scale(bars ? 30 : 18);
      final topPad = scaler.scale(bars ? 24 : 18);
      plot = Rect.fromLTRB(
        chart.left + left,
        chart.top + topPad,
        chart.right - right - (right == 0 ? 4 : 0),
        chart.bottom - xGutter,
      );

      boxes[TrickSceneRegion.label] = Rect.fromLTRB(
        inner.left - 6,
        label.top - 4,
        inner.right + 6,
        label.bottom + 4,
      );
      regions[TrickSceneRegion.label] = inflateTo(
        boxes[TrickSceneRegion.label]!,
        minH: 24,
      );
      boxes[TrickSceneRegion.yaxis] = Rect.fromLTRB(
        chart.left - 6,
        plot.top - 12,
        plot.left - 1,
        plot.bottom - 1,
      );
      boxes[TrickSceneRegion.xaxis] = Rect.fromLTRB(
        plot.left - 4,
        plot.bottom - 12,
        plot.right + 4,
        chart.bottom + 4,
      );
      boxes[TrickSceneRegion.marks] = Rect.fromLTRB(
        plot.left + 2,
        chart.top + 2,
        plot.right - 2,
        plot.bottom - 2,
      );
      if (right > 0) {
        boxes[TrickSceneRegion.yaxis2] = Rect.fromLTRB(
          plot.right + 3,
          plot.top - 12,
          chart.right + 6,
          plot.bottom - 1,
        );
      }
      regions[TrickSceneRegion.yaxis] = inflateTo(
        Rect.fromLTRB(chart.left - 6, plot.top - 8, plot.left + 8, plot.bottom + 8),
      );
      regions[TrickSceneRegion.xaxis] = inflateTo(
        Rect.fromLTRB(plot.left - 2, plot.bottom - 6, plot.right + 2, chart.bottom + 6),
        minH: 40,
      );
      regions[TrickSceneRegion.marks] = Rect.fromLTRB(
        plot.left + 10,
        chart.top + 2,
        plot.right - (right > 0 ? 10 : 0),
        plot.bottom - 8,
      );
      if (right > 0) {
        regions[TrickSceneRegion.yaxis2] = inflateTo(
          Rect.fromLTRB(plot.right - 8, plot.top - 8, chart.right + 6, plot.bottom + 8),
        );
      }
    }

    return _TrickLayout._(
      scene: s,
      size: size,
      tight: tight,
      headlineSize: hs,
      outlet: outlet,
      headline: headline,
      label: label,
      chart: chart,
      plot: plot,
      scaler: scaler,
      pie: pie,
      rows: rows,
      regions: regions,
      boxes: boxes,
      parts: chart.height < 150 ? 2 : 4,
    );
  }

  /// The part under a point: the narrow parts first, so an axis wins where
  /// it overlaps the plot.
  TrickSceneRegion? hit(Offset p) {
    for (final r in const [
      TrickSceneRegion.yaxis,
      TrickSceneRegion.yaxis2,
      TrickSceneRegion.xaxis,
      TrickSceneRegion.label,
      TrickSceneRegion.headline,
      TrickSceneRegion.marks,
    ]) {
      if (regions[r]?.contains(p) ?? false) return r;
    }
    return null;
  }
}

/// Laid-out labels kept between frames, so a moving axis does not lay out
/// the same few words sixty times a second.
class _TrickTextCache {
  final Map<String, TextPainter> _m = {};

  TextPainter get(
    String text,
    TextStyle style,
    TextScaler scaler, {
    double? maxWidth,
    int maxLines = 1,
    TextAlign align = TextAlign.left,
  }) {
    final key =
        '${style.fontFamily}|${style.fontSize}|${style.fontWeight?.value}|'
        '${style.color?.toARGB32()}|${scaler.scale(10)}|${maxWidth?.round()}|'
        '$maxLines|${align.index}|$text';
    return _m.putIfAbsent(
      key,
      () => TextPainter(
        text: TextSpan(text: text, style: style),
        maxLines: maxLines,
        ellipsis: '…',
        textAlign: align,
        textDirection: TextDirection.ltr,
        textScaler: scaler,
      )..layout(
        minWidth: align == TextAlign.center ? maxWidth ?? 0 : 0,
        maxWidth: maxWidth ?? double.infinity,
      ),
    );
  }

  void clear() {
    for (final t in _m.values) {
      t.dispose();
    }
    _m.clear();
  }
}

// ---- one frame ----

/// Everything that moves, as one value.
@immutable
class _TrickFrame {
  /// 0 the chart as published, 1 the honest chart.
  final double morph;

  /// Arrival: each part outlined once in turn.
  final double nudge;

  /// The last box popping in or shaking.
  final double pop;
  final List<TrickSceneRegion> tried;
  final TrickSceneRegion? last;
  final bool solved;
  final bool found;

  /// 0 → 1 as the lesson arrives: the trick's box settles.
  final double settle;

  const _TrickFrame({
    required this.morph,
    required this.nudge,
    required this.pop,
    required this.tried,
    required this.last,
    required this.solved,
    required this.found,
    required this.settle,
  });

  @override
  bool operator ==(Object other) =>
      other is _TrickFrame &&
      other.morph == morph &&
      other.nudge == nudge &&
      other.pop == pop &&
      other.tried.length == tried.length &&
      other.last == last &&
      other.solved == solved &&
      other.found == found &&
      other.settle == settle;

  @override
  int get hashCode =>
      Object.hash(morph, nudge, pop, tried.length, last, solved, found, settle);
}

// ---- the chart ----

class _TrickChartPainter extends CustomPainter {
  final TrickScene scene;
  final _TrickLayout layout;
  final _TrickFrame frame;
  final Color ink;
  final Color ground;
  final _TrickTextCache texts;

  _TrickChartPainter({
    required this.scene,
    required this.layout,
    required this.frame,
    required this.ink,
    required this.ground,
    required this.texts,
  });

  final Paint _fill = Paint();
  final Paint _stroke = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  @override
  void paint(Canvas canvas, Size size) {
    // The clipping itself: a shade of ink on the card's colour.
    _fill.color = ink.withValues(alpha: 0.07);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(18)),
      _fill,
    );
    if (scene.form == TrickSceneForm.pie) {
      _pie(canvas);
    } else {
      _xy(canvas);
    }
  }

  double _ease(double t) => Curves.easeInOutCubic.transform(t.clamp(0.0, 1.0));

  /// Text at a point, its anchor given as a fraction of its own size.
  void _text(
    Canvas canvas,
    String t,
    TextStyle style,
    Offset at, {
    double ax = 0,
    double ay = 0,
    double alpha = 1,
    double? maxWidth,
    int maxLines = 1,
    TextAlign align = TextAlign.left,
  }) {
    if (alpha <= 0.01) return;
    // Alpha in twentieths, so the cache holds a few fades, not every frame.
    final a = (alpha.clamp(0.0, 1.0) * 20).round() / 20;
    final c = style.color ?? ink;
    final tp = texts.get(
      t,
      style.copyWith(color: c.withValues(alpha: c.a * a)),
      layout.scaler,
      maxWidth: maxWidth,
      maxLines: maxLines,
      align: align,
    );
    final w = maxWidth != null && align == TextAlign.center ? maxWidth : tp.width;
    tp.paint(canvas, at - Offset(w * ax, tp.height * ay));
  }

  void _xy(Canvas canvas) {
    final s = scene;
    final plot = layout.plot;
    final f = _TrickFormat(s);
    final m = frame.morph;
    final bars = s.form == TrickSceneForm.bars;
    final tickStyle = _TrickLayout.tickStyle(ink.withValues(alpha: 0.7));

    // How far along the change is. Most tricks move what is there; totals
    // drain the old bars to nothing, then fill them again as rates.
    final e = s.refills ? 0.0 : _ease(m);
    final drain = s.refills ? _ease(m / .45) : 0.0;
    final fill = s.refills ? _ease((m - .55) / .45) : 0.0;
    final second = s.refills && m >= .5;

    TrickSceneRange lerpRange(TrickSceneRange a, TrickSceneRange b, double t) =>
        (lo: lerpDouble(a.lo, b.lo, t)!, hi: lerpDouble(a.hi, b.hi, t)!);
    final range = s.refills
        ? (second ? s.fair : s.shown)
        : lerpRange(s.shown, s.fair, e);
    final range2 = lerpRange(s.shown2, s.fair, e);
    // Upright is 1; a flipped chart starts at -1 and turns over.
    final up = s.trick == TrickSceneKind.flipped ? lerpDouble(-1, 1, e)! : 1.0;

    double yOf(double v, TrickSceneRange r) {
      final t = (v - r.lo) / (r.hi - r.lo);
      final mid = plot.center.dy;
      return mid + (0.5 - t) * plot.height * up;
    }

    // The columns in view.
    final x0 = lerpDouble(s.first.toDouble(), 0, e)!;
    final x1 = lerpDouble(s.last.toDouble(), s.count - 1.0, e)!;
    final slots = bars ? x1 - x0 + 1 : math.max(x1 - x0, 1e-6);
    final slotW = plot.width / slots;
    double xOf(double i) => bars
        ? plot.left + (i - x0 + .5) * slotW
        : plot.left + (i - x0) / (x1 - x0) * plot.width;

    // Grid and ticks: the old set fading as the new one comes, each at its
    // own value on the axis as it is now. A value in both sets stays put.
    final oldTicks = TrickScene.ticks(s.shown, layout.parts);
    final newTicks = TrickScene.ticks(s.fair, layout.parts);
    final oldAlpha = s.refills ? (second ? 0.0 : 1 - drain) : 1 - e;
    final newAlpha = s.refills ? (second ? fill : 0.0) : e;
    canvas.save();
    canvas.clipRect(
      Rect.fromLTRB(0, plot.top - 8, layout.size.width, plot.bottom + 8),
    );
    void tickRow(double v, double alpha, TrickSceneRange labelRange) {
      final y = yOf(v, range);
      if (y < plot.top - 6 || y > plot.bottom + 6) return;
      _stroke
        ..color = ink.withValues(alpha: 0.13 * alpha)
        ..strokeWidth = 1;
      canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), _stroke);
      // A flipping axis folds flat halfway; its labels fade as it does.
      _text(
        canvas,
        f.tick(v, labelRange, layout.parts),
        tickStyle,
        Offset(plot.left - 12, y),
        ax: 1,
        ay: .5,
        alpha: alpha * up.abs(),
      );
    }

    final same = s.trick == TrickSceneKind.flipped || s.trick == TrickSceneKind.pie;
    for (final v in oldTicks) {
      final both = newTicks.any((n) => (n - v).abs() < 1e-9);
      tickRow(v, same && both ? 1 : oldAlpha, s.shown);
    }
    if (!same) {
      for (final v in newTicks) {
        tickRow(v, newAlpha, s.fair);
      }
    }

    // The right axis of a dual chart, its marks turning into the shared
    // axis's.
    if (s.trick == TrickSceneKind.dual) {
      for (final (set, alpha, r) in [
        (TrickScene.ticks(s.shown2, layout.parts), 1 - e, s.shown2),
        (newTicks, e, s.fair),
      ]) {
        for (final v in set) {
          final y = yOf(v, range2);
          if (y < plot.top - 6 || y > plot.bottom + 6) continue;
          _text(
            canvas,
            f.tick(v, r, layout.parts),
            tickStyle,
            Offset(plot.right + 8, y),
            ay: .5,
            alpha: alpha,
          );
        }
      }
    }
    canvas.restore();

    // The axes: a firm line at the bottom and a light one up the side.
    _stroke
      ..color = ink.withValues(alpha: 0.55)
      ..strokeWidth = 1.5;
    final baseY = up >= 0 ? plot.bottom : plot.top;
    canvas.drawLine(
      Offset(plot.left, baseY),
      Offset(plot.right, baseY),
      _stroke,
    );
    _stroke
      ..color = ink.withValues(alpha: 0.3)
      ..strokeWidth = 1;
    canvas.drawLine(plot.topLeft, plot.bottomLeft, _stroke);
    if (s.trick == TrickSceneKind.dual) {
      canvas.drawLine(plot.topRight, plot.bottomRight, _stroke);
    }

    // The marks, kept inside the plot (a little wider, for the end dots).
    canvas.save();
    canvas.clipRect(
      Rect.fromLTRB(plot.left - 1, layout.chart.top, plot.right + 1, plot.bottom + 1)
          .inflate(bars ? 0 : 6),
    );
    final values = second ? s.honestValues : s.values;
    final grow = s.refills ? (second ? fill : 1 - drain) : 1.0;
    if (bars) {
      _bars(canvas, f, values, range, grow, second, xOf, yOf, slotW, e);
    } else {
      _lines(canvas, f, values, range, range2, grow, second, xOf, yOf, e);
    }
    canvas.restore();

    // The columns' names along the bottom.
    canvas.save();
    canvas.clipRect(
      Rect.fromLTRB(
        plot.left - 4,
        plot.bottom,
        plot.right + 4,
        layout.chart.bottom + 2,
      ),
    );
    final xStyle = AppText.label(
      size: 10.5,
      weight: FontWeight.w700,
      spacing: 0.3,
      height: 1.15,
      color: ink.withValues(alpha: 0.72),
    );
    if (bars) {
      for (var i = 0; i < s.count; i++) {
        final x = xOf(i.toDouble());
        if (x < plot.left - slotW || x > plot.right + slotW) continue;
        _text(
          canvas,
          s.columns[i],
          xStyle,
          Offset(x - (slotW - 4) / 2, plot.bottom + 6),
          maxWidth: slotW - 4,
          maxLines: 2,
          align: TextAlign.center,
        );
      }
    } else {
      final widest = s.columns
          .map((c) => texts.get(c, xStyle, layout.scaler).width)
          .reduce(math.max);
      for (final (from, to, alpha) in [
        (s.first, s.last, 1 - e),
        (0, s.count - 1, e),
      ]) {
        final shownAll = from == 0 && to == s.count - 1;
        if (shownAll && s.first == 0 && s.last == s.count - 1 && alpha < 1) {
          continue;
        }
        for (final i in _xLabels(from, to, plot.width, widest + 14)) {
          final x = xOf(i.toDouble());
          _text(
            canvas,
            s.columns[i],
            xStyle,
            Offset(x, plot.bottom + 6),
            ax: i == from && x - widest / 2 < plot.left
                ? 0
                : i == to && x + widest / 2 > plot.right
                ? 1
                : .5,
            alpha: s.first == 0 && s.last == s.count - 1 ? 1 : alpha,
          );
        }
      }
    }
    canvas.restore();
  }

  /// The columns to name along a line: both ends, and round steps between
  /// them that leave room for a label each.
  List<int> _xLabels(int from, int to, double width, double each) {
    final n = to - from + 1;
    final need = n * each / width;
    var step = 1;
    for (final k in const [1, 2, 5, 10, 20, 25, 50, 100]) {
      step = k;
      if (k >= need) break;
    }
    final out = <int>[from];
    for (var i = from + 1; i < to; i++) {
      if (i % step != 0) continue;
      if (i - from < step * .7 || to - i < step * .7) continue;
      out.add(i);
    }
    out.add(to);
    return out;
  }

  void _bars(
    Canvas canvas,
    _TrickFormat f,
    List<double> values,
    TrickSceneRange range,
    double grow,
    bool honest,
    double Function(double) xOf,
    double Function(double, TrickSceneRange) yOf,
    double slotW,
    double e,
  ) {
    final s = scene;
    final plot = layout.plot;
    final barW = math.min(slotW * 0.56, 76.0);
    final base = math.max(range.lo, math.min(0.0, range.hi));
    final valueStyle = AppText.display(
      size: layout.tight ? 15 : 17,
      weight: FontWeight.w800,
      height: 1,
      spacing: -0.3,
      color: ink,
    );
    for (var i = 0; i < s.count; i++) {
      final x = xOf(i.toDouble());
      if (x < plot.left - slotW || x > plot.right + slotW) continue;
      final v = base + (values[i] - base) * grow;
      final yTop = yOf(v, range);
      final yBase = yOf(base, range).clamp(plot.top, plot.bottom);
      final rect = Rect.fromLTRB(
        x - barW / 2,
        math.min(yTop, yBase),
        x + barW / 2,
        math.max(yTop, yBase),
      );
      _fill.color = ink;
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          rect,
          topLeft: const Radius.circular(5),
          topRight: const Radius.circular(5),
        ),
        _fill,
      );
      _text(
        canvas,
        f.value(values[i], honest: honest),
        valueStyle,
        Offset(x, rect.top - 6),
        ax: .5,
        ay: 1,
        alpha: s.refills ? grow : 1,
      );
    }
  }

  void _lines(
    Canvas canvas,
    _TrickFormat f,
    List<double> values,
    TrickSceneRange range,
    TrickSceneRange range2,
    double grow,
    bool honest,
    double Function(double) xOf,
    double Function(double, TrickSceneRange) yOf,
    double e,
  ) {
    final s = scene;
    final plot = layout.plot;
    final dual = s.trick == TrickSceneKind.dual;
    final base = math.max(range.lo, math.min(0.0, range.hi));

    Path line(List<double> vs, TrickSceneRange r) {
      final p = Path();
      for (var i = 0; i < vs.length; i++) {
        final v = base + (vs[i] - base) * grow;
        final o = Offset(xOf(i.toDouble()), yOf(v, r));
        if (i == 0) {
          p.moveTo(o.dx, o.dy);
        } else {
          p.lineTo(o.dx, o.dy);
        }
      }
      return p;
    }

    final main = line(values, range);
    // The line itself stops at the plot's edges; its end dots may not.
    canvas.save();
    canvas.clipRect(
      Rect.fromLTRB(plot.left, layout.chart.top, plot.right, plot.bottom + 1),
    );
    if (!dual) {
      // The area under the line, to the axis's own floor: on a flipped
      // chart the floor is at the top and the area hangs down from it.
      final floor = yOf(range.lo, range);
      final area = Path.from(main)
        ..lineTo(xOf(s.count - 1.0), floor)
        ..lineTo(xOf(0), floor)
        ..close();
      _fill.color = ink.withValues(alpha: 0.12);
      canvas.drawPath(area, _fill);
    }
    _stroke
      ..color = ink
      ..strokeWidth = 3.4;
    canvas.drawPath(main, _stroke);

    Path? other;
    if (dual) {
      other = line(s.values2, range2);
      // The second series dashed, so the two differ in more than colour.
      _stroke
        ..color = ink.withValues(alpha: 0.75)
        ..strokeWidth = 3.4;
      for (final metric in other.computeMetrics()) {
        var d = 0.0;
        while (d < metric.length) {
          canvas.drawPath(metric.extractPath(d, d + 9), _stroke);
          d += 15;
        }
      }
    }
    canvas.restore();

    // Values at the ends of what is in view, and the series' names.
    final valueStyle = AppText.display(
      size: layout.tight ? 13.5 : 15,
      weight: FontWeight.w800,
      height: 1,
      spacing: -0.2,
      color: ink,
    );
    final nameStyle = AppText.label(
      size: 10,
      weight: FontWeight.w800,
      spacing: 1,
      color: ink.withValues(alpha: 0.8),
    );
    void ends(int a, int b, double alpha) {
      for (final (series, vs, r) in [
        (0, values, range),
        if (dual) (1, s.values2, range2),
      ]) {
        for (final i in {a, b}) {
          final p = Offset(xOf(i.toDouble()), yOf(vs[i], r));
          _fill.color = ink;
          canvas.drawCircle(p, 4.5 * alpha, _fill);
          _fill.color = ground;
          canvas.drawCircle(p, 2 * alpha, _fill);
          final text = f.value(vs[i], honest: honest);
          final w = texts.get(text, valueStyle, layout.scaler).width;
          final left = i == a ? p.dx : p.dx - w;
          // How far the series' own line reaches up and down under the
          // label's width, so the label clears it on either side.
          var top = p.dy, bottom = p.dy;
          for (var k = 0; k + 1 < vs.length; k++) {
            final xa = xOf(k.toDouble()), xb = xOf(k + 1.0);
            final ya = yOf(vs[k], r), yb = yOf(vs[k + 1], r);
            for (final x in [left - 4, left + w + 4, xa, xb]) {
              if (x < math.min(xa, xb) || x > math.max(xa, xb)) continue;
              if (x < left - 4 || x > left + w + 4) continue;
              final y = xb == xa ? ya : ya + (yb - ya) * (x - xa) / (xb - xa);
              top = math.min(top, y);
              bottom = math.max(bottom, y);
            }
          }
          final fs = valueStyle.fontSize! * 1.1;
          final block = fs + (dual && i == a ? 18 : 0);
          final roomAbove = top - 9 - block >= layout.chart.top;
          final roomBelow = bottom + 9 + block <= plot.bottom;
          // Above the point by default, the side nearer the point otherwise;
          // on a dual chart, the side away from the other series.
          var above = (p.dy - top) <= (bottom - p.dy);
          if (dual) {
            final q = yOf(
              (series == 0 ? s.values2 : values)[i],
              series == 0 ? range2 : range,
            );
            above = p.dy <= q;
          }
          if (above && !roomAbove && roomBelow) above = false;
          if (!above && !roomBelow && roomAbove) above = true;
          var ly = above ? top - 9 : bottom + 9;
          ly = above
              ? math.max(ly, layout.chart.top + block)
              : math.min(ly, plot.bottom - block);
          _text(
            canvas,
            text,
            valueStyle,
            Offset(p.dx, ly),
            ax: i == a ? 0 : 1,
            ay: above ? 1 : 0,
            alpha: alpha,
          );
          if (dual && i == a) {
            _text(
              canvas,
              s.series[series].toUpperCase(),
              nameStyle,
              Offset(p.dx, ly + (above ? -18 : 18)),
              ay: above ? 1 : 0,
              alpha: alpha,
            );
          }
        }
      }
    }

    if (s.first == 0 && s.last == s.count - 1) {
      // A flipping chart folds flat halfway; its labels fade as it does.
      ends(
        0,
        s.count - 1,
        s.trick == TrickSceneKind.flipped ? (2 * e - 1).abs() : 1,
      );
    } else {
      ends(s.first, s.last, 1 - e);
      ends(0, s.count - 1, e);
    }
  }

  void _pie(Canvas canvas) {
    final s = scene;
    final f = _TrickFormat(s);
    final m = frame.morph;
    final drain = _ease(m / .5);
    final fill = _ease((m - .45) / .55);
    final slide = _ease(m);
    final pie = layout.pie;
    final total = s.values.fold(0.0, (a, b) => a + b);

    // Slice shades: ink thinning out, split by lines of the ground.
    double shade(int i) => 1.0 - i * (0.78 / math.max(1, s.count - 1));

    if (drain < 1) {
      final c = pie.center;
      final r = pie.width / 2 * (1 - drain * .35);
      var a = -math.pi / 2;
      for (var i = 0; i < s.count; i++) {
        final sweep = s.values[i] / total * math.pi * 2 * (1 - drain);
        _fill.color = ink.withValues(alpha: shade(i) * (1 - drain));
        canvas.drawArc(Rect.fromCircle(center: c, radius: r), a, sweep, true, _fill);
        _stroke
          ..color = ground.withValues(alpha: 1 - drain)
          ..strokeWidth = 2;
        canvas.drawLine(c, c + Offset(math.cos(a), math.sin(a)) * r, _stroke);
        a += sweep;
      }
    }

    // The answers: beside the pie at first, then across the whole width,
    // each with a track for 100% and its true share filling it.
    final rows = Rect.fromLTRB(
      lerpDouble(layout.rows.left, layout.chart.left, slide)!,
      layout.rows.top,
      layout.rows.right,
      layout.rows.bottom,
    );
    final n = s.count;
    final rowH = math.min(rows.height / n, 62.0);
    final top = rows.top + (rows.height - rowH * n) / 2;
    final labelStyle = AppText.body(
      size: layout.tight ? 12.5 : 14,
      weight: FontWeight.w700,
      height: 1.1,
      color: ink,
    );
    final valueStyle = AppText.display(
      size: layout.tight ? 15 : 18,
      weight: FontWeight.w800,
      height: 1,
      spacing: -0.3,
      color: ink,
    );
    for (var i = 0; i < n; i++) {
      final y = top + rowH * i;
      final mid = y + rowH / 2;
      // The text rises a little as the bar below it appears.
      final lift = (rowH * .18).clamp(0.0, 10.0) * slide;
      const sw = 12.0;
      final sx = rows.left;
      _fill.color = ink.withValues(alpha: shade(i));
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(sx + sw / 2, mid - lift),
            width: sw,
            height: sw,
          ),
          const Radius.circular(3),
        ),
        _fill,
      );
      final valueText = f.value(s.values[i], honest: false);
      final vw = texts.get(valueText, valueStyle, layout.scaler).width;
      _text(
        canvas,
        s.columns[i],
        labelStyle,
        Offset(sx + sw + 8, mid - lift),
        ay: .5,
        maxWidth: rows.width - sw - 8 - vw - 8,
      );
      _text(
        canvas,
        valueText,
        valueStyle,
        Offset(rows.right, mid - lift),
        ax: 1,
        ay: .5,
      );
      if (fill > 0) {
        final ty = mid + rowH * .26;
        final track = Rect.fromLTWH(sx, ty - 3, rows.width, 6);
        _fill.color = ink.withValues(alpha: 0.14 * fill);
        canvas.drawRRect(
          RRect.fromRectAndRadius(track, const Radius.circular(3)),
          _fill,
        );
        _fill.color = ink;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(sx, ty - 3, rows.width * s.values[i] / 100 * fill, 6),
            const Radius.circular(3),
          ),
          _fill,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_TrickChartPainter old) =>
      old.frame != frame ||
      old.layout != layout ||
      old.ink != ink ||
      old.ground != ground ||
      old.scene != scene;
}

// ---- the boxes ----

/// Selection boxes round the parts tapped: crossed and faint for the wrong
/// ones, solid with handles and a tick for the trick.
class _TrickBoxPainter extends CustomPainter {
  final TrickScene scene;
  final _TrickLayout layout;
  final _TrickFrame frame;
  final Color ink;
  final Color ground;

  _TrickBoxPainter({
    required this.scene,
    required this.layout,
    required this.frame,
    required this.ink,
    required this.ground,
  });

  final Paint _fill = Paint();
  final Paint _stroke = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  /// The box drawn for a part: its tap area, held inside the clipping.
  Rect _box(TrickSceneRegion r) {
    final a = layout.boxes[r]!;
    final inside = (Offset.zero & layout.size).deflate(7);
    return Rect.fromLTRB(
      math.max(a.left, inside.left),
      math.max(a.top, inside.top),
      math.min(a.right, inside.right),
      math.min(a.bottom, inside.bottom),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Arrival: each part outlined in turn, dashed and light.
    if (!frame.solved && frame.tried.isEmpty && frame.nudge > 0 && frame.nudge < 1) {
      final parts = scene.regions;
      for (var k = 0; k < parts.length; k++) {
        final start = .25 + k * (.55 / parts.length);
        final t = ((frame.nudge - start) / .28).clamp(0.0, 1.0);
        final a = math.sin(t * math.pi);
        if (a <= 0) continue;
        _dashed(canvas, _box(parts[k]), ink.withValues(alpha: 0.42 * a));
      }
    }

    final pop = Curves.easeOutBack.transform(frame.pop.clamp(0.0, 1.0));
    for (final r in frame.tried) {
      final current = r == frame.last && !frame.solved;
      var box = _box(r);
      double alpha = 0.32;
      if (current) {
        // A wrong part shakes off the tap, then rests faint.
        final p = frame.pop;
        final shake = math.sin(p * math.pi * 5) * (1 - p) * 6;
        box = box.shift(Offset(shake, 0));
        alpha = lerpDouble(0.9, 0.5, p)!;
      }
      _dashed(canvas, box, ink.withValues(alpha: alpha));
      _badge(canvas, box.topRight, false, alpha);
    }

    if (frame.solved) {
      final grow = frame.found ? pop : 1.0;
      for (final r in scene.spot) {
        final full = _box(r);
        final box = Rect.fromCenter(
          center: full.center,
          width: full.width * lerpDouble(1.12, 1, grow)!,
          height: full.height * lerpDouble(1.12, 1, grow)!,
        );
        final a0 = (frame.found ? frame.pop * 3 : frame.settle * 2 + frame.morph).clamp(
          0.0,
          1.0,
        );
        // A pie's box goes with the pie it marked.
        final gone = scene.form == TrickSceneForm.pie && r == TrickSceneRegion.marks
            ? 1 - frame.morph
            : 1.0;
        final a = a0 * gone;
        if (a <= 0) continue;
        final rr = RRect.fromRectAndRadius(box, const Radius.circular(9));
        _fill.color = ink.withValues(alpha: 0.07 * a);
        canvas.drawRRect(rr, _fill);
        _stroke
          ..color = ink.withValues(alpha: a)
          ..strokeWidth = 2;
        canvas.drawRRect(rr, _stroke);
        for (final c in [box.topLeft, box.bottomRight]) {
          _fill.color = ground;
          canvas.drawCircle(c, 5.5, _fill);
          _stroke.strokeWidth = 2;
          canvas.drawCircle(c, 5.5, _stroke);
        }
        if (frame.found) _badge(canvas, box.topRight, true, a);
      }
    }
  }

  void _dashed(Canvas canvas, Rect r, Color color) {
    _stroke
      ..color = color
      ..strokeWidth = 1.6;
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(r, const Radius.circular(9)));
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, d + 5), _stroke);
        d += 9;
      }
    }
  }

  /// A tick or a cross in a disc, on the box's corner.
  void _badge(Canvas canvas, Offset c, bool right, double alpha) {
    final at = c + const Offset(-3, 3);
    _fill.color = ink.withValues(alpha: alpha);
    canvas.drawCircle(at, 9, _fill);
    _stroke
      ..color = ground.withValues(alpha: alpha)
      ..strokeWidth = 2;
    if (right) {
      canvas.drawPath(
        Path()
          ..moveTo(at.dx - 4, at.dy)
          ..lineTo(at.dx - 1.2, at.dy + 3)
          ..lineTo(at.dx + 4.2, at.dy - 3.4),
        _stroke,
      );
    } else {
      canvas.drawLine(at + const Offset(-3, -3), at + const Offset(3, 3), _stroke);
      canvas.drawLine(at + const Offset(3, -3), at + const Offset(-3, 3), _stroke);
    }
  }

  @override
  bool shouldRepaint(_TrickBoxPainter old) =>
      old.frame != frame || old.layout != layout || old.ink != ink;
}

// ---- small pieces ----

/// The tick or cross that leads a line under the clipping, the same mark
/// as on the boxes.
class _TrickBadge extends StatelessWidget {
  final Color ink;
  final Color ground;
  final bool right;
  const _TrickBadge({required this.ink, required this.ground, required this.right});

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: 18,
    child: CustomPaint(painter: _BadgePainter(ink, ground, right)),
  );
}

class _BadgePainter extends CustomPainter {
  final Color ink;
  final Color ground;
  final bool right;
  _BadgePainter(this.ink, this.ground, this.right);

  late final Paint _fill = Paint()..color = ink;
  late final Paint _stroke = Paint()
    ..color = ground
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    canvas.drawCircle(c, size.width / 2, _fill);
    if (right) {
      canvas.drawPath(
        Path()
          ..moveTo(c.dx - 4, c.dy)
          ..lineTo(c.dx - 1.2, c.dy + 3)
          ..lineTo(c.dx + 4.2, c.dy - 3.4),
        _stroke,
      );
    } else {
      canvas.drawLine(c + const Offset(-3, -3), c + const Offset(3, 3), _stroke);
      canvas.drawLine(c + const Offset(3, -3), c + const Offset(-3, 3), _stroke);
    }
  }

  @override
  bool shouldRepaint(_BadgePainter old) =>
      old.ink != ink || old.ground != ground || old.right != right;
}

/// A fingertip with a ring: "tap a part".
class _TapMarkPainter extends CustomPainter {
  final Color color;
  _TapMarkPainter(this.color);

  late final Paint _stroke = Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;
  late final Paint _fill = Paint()..color = color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    canvas.drawCircle(c, size.width / 2 - 1, _stroke);
    canvas.drawCircle(c, size.width / 5, _fill);
  }

  @override
  bool shouldRepaint(_TapMarkPainter old) => old.color != color;
}

class _ShowMe extends StatelessWidget {
  final String label;
  final Color ink;
  final Color ground;
  final VoidCallback onTap;
  const _ShowMe({
    required this.label,
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
        color: Colors.transparent,
        shape: StadiumBorder(side: BorderSide(color: ink, width: 2)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          splashColor: ink.withValues(alpha: 0.12),
          highlightColor: ink.withValues(alpha: 0.06),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                widthFactor: 1,
                heightFactor: 1,
                child: Text(
                  label,
                  style: AppText.body(
                    size: 14,
                    weight: FontWeight.w800,
                    color: ink,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
