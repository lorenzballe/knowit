import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/l10n.dart';
import '../../models/scene.dart';
import '../../theme.dart';

/// Plays a [PollScene]: answer for yourself, then see everyone.
///
/// Before: the options are big slabs, each with an empty ring, filling the
/// height the card gives. A tap turns the slab solid at once and commits:
/// there is no lock-in step and no going back, because a choice you can
/// take back after a peek at the crowd says nothing about you.
///
/// After: the slabs shrink into a list of bars, each filling from the left
/// to the share of the study's people who chose it while its percentage
/// counts up. The reader's own row stays solid and carries a "YOU" tag, so
/// where they sit is read in shape and word, not colour alone. Under the
/// bars, the line about people who chose like them, then the line on why
/// people split.
///
/// With two questions the first slab, once tapped, holds for a beat and
/// the question slides away to the next one. Only after the second answer
/// do both crowds appear, one group of bars per wording, and the line says
/// whether the reader held steady or switched.
///
/// It only claims taps: inside the scene a tap answers rather than turning
/// the card over until the results are in, and a horizontal swipe is left
/// to the deck.
class PollSceneView extends StatefulWidget {
  final PollScene scene;
  final Color ink;
  final Color ground;
  const PollSceneView({
    super.key,
    required this.scene,
    required this.ink,
    required this.ground,
  });

  @override
  State<PollSceneView> createState() => _PollSceneViewState();
}

class _PollSceneViewState extends State<PollSceneView>
    with TickerProviderStateMixin {
  PollScene get _s => widget.scene;

  /// The reader's pick for each question, once made.
  late List<int?> _picks = List.filled(_s.questions.length, null);

  /// The question on show (or, during the turn, the one arriving).
  int _q = 0;

  /// The slab under the finger, before the tap is decided.
  int? _pressed;

  /// From the first question to the second: a beat on the solid pick, then
  /// the slide. Its value stays at 1 afterwards; while it is below 1 the
  /// second question is not yet tappable.
  late final AnimationController _turn = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 950),
  );

  /// Slabs to bars, bars growing, the lines arriving: one clock, so a test
  /// can run it to the end and the parts stay in step.
  late final AnimationController _reveal = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2100),
  );

  bool get _revealed => _picks.every((p) => p != null);

  @override
  void didUpdateWidget(PollSceneView old) {
    super.didUpdateWidget(old);
    if (old.scene.raw != widget.scene.raw) {
      _picks = List.filled(_s.questions.length, null);
      _q = 0;
      _pressed = null;
      _turn.value = 0;
      _reveal.value = 0;
    }
  }

  @override
  void dispose() {
    _turn.dispose();
    _reveal.dispose();
    super.dispose();
  }

  bool get _canPick =>
      !_revealed && (_q == 0 || _turn.value >= 1) && _picks[_q] == null;

  void _pick(int i) {
    if (!_canPick) return;
    HapticFeedback.lightImpact();
    final still = MediaQuery.disableAnimationsOf(context);
    setState(() {
      _picks[_q] = i;
      _pressed = null;
      if (!_revealed) _q++;
    });
    if (_revealed) {
      still ? _reveal.value = 1 : _reveal.forward();
    } else {
      still ? _turn.value = 1 : _turn.forward(from: 0);
    }
  }

  // ---- type ----

  TextStyle get _promptStyle => AppText.display(
    size: 19,
    weight: FontWeight.w600,
    height: 1.18,
    spacing: -0.3,
    color: widget.ink,
  );

  TextStyle _lineStyle(double size) => AppText.body(
    size: size,
    weight: FontWeight.w700,
    height: 1.3,
    color: widget.ink,
  );

  TextStyle _whyStyle(double size) => AppText.body(
    size: size,
    weight: FontWeight.w500,
    height: 1.3,
    color: widget.ink.withValues(alpha: 0.78),
  );

  double _measure(String text, TextStyle style, double width, int maxLines) {
    if (text.isEmpty) return 0;
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: maxLines,
    )..layout(maxWidth: width);
    final h = tp.height;
    tp.dispose();
    return h;
  }

  // ---- layout ----

  static const _hintH = 18.0;

  /// Where a question's prompt and slabs sit while it is being answered.
  _ChoiceLayout _choice(int q, double w, double h) {
    final qq = _s.questions[q];
    var y = _hintH + 14;
    final promptTop = y;
    var promptH = 0.0;
    if (qq.prompt.isNotEmpty) {
      promptH = _measure(qq.prompt, _promptStyle, w, 3);
      y += promptH + 16;
    }
    final n = qq.options.length;
    final area = math.max(0.0, h - y);
    final gap = (area * 0.035).clamp(8.0, 14.0);
    final rowH = ((area - gap * (n - 1)) / n).clamp(40.0, 170.0);
    final block = rowH * n + gap * (n - 1);
    // A short block sits in the middle of the room it has, not at its top.
    final start = y + math.max(0.0, (area - block) / 2);
    return _ChoiceLayout(
      promptTop: promptTop,
      promptH: promptH,
      tops: [for (var i = 0; i < n; i++) start + i * (rowH + gap)],
      rowH: rowH,
      font: (rowH * 0.22).clamp(17.0, 25.0),
    );
  }

  /// Where everything sits once the crowd is shown. What gives way when
  /// the room is short, in order: the type of the lines, the heading,
  /// the line on why people split. The reader's own line never does.
  _ResultLayout _result(double w, double h) {
    final s = _s;
    final line = s.lineFor([for (final p in _picks) p ?? 0]);
    const gap = 6.0, tagH = 16.0, tagGap = 6.0, groupGap = 16.0;
    final rows = s.questions.fold(0, (a, q) => a + q.options.length);
    final rowGaps = s.questions.fold(
      0.0,
      (a, q) => a + gap * (q.options.length - 1),
    );
    final groups = s.twice ? 2 * (tagH + tagGap) + groupGap : 0.0;

    ({double lineSize, double whySize, bool header, bool why, double footer})?
    fit;
    for (final (lineSize, whySize, header, why) in [
      (15.0, 14.0, true, true),
      (14.0, 13.0, true, true),
      (14.0, 13.0, false, true),
      (14.0, 13.0, false, false),
    ]) {
      final lineH = _measure(line, _lineStyle(lineSize), w, 4);
      final whyH = why ? _measure(s.why, _whyStyle(whySize), w, 4) : 0.0;
      final footer = 16 + lineH + (why ? 6 + whyH : 0);
      final need = (header ? _hintH + 12 : 0) + groups + rowGaps + footer;
      fit = (
        lineSize: lineSize,
        whySize: whySize,
        header: header,
        why: why,
        footer: footer,
      );
      if (need + rows * 30 <= h) break;
    }
    final f = fit!;
    final fixed =
        (f.header ? _hintH + 12 : 0) + groups + rowGaps + f.footer;
    final rowH = ((h - fixed) / rows).clamp(26.0, s.twice ? 52.0 : 64.0);
    final total = fixed + rowH * rows;
    var y = math.max(0.0, (h - total) / 2);
    final headerTop = y;
    if (f.header) y += _hintH + 12;
    final tagTops = <double>[];
    final tops = <List<double>>[];
    for (var q = 0; q < s.questions.length; q++) {
      if (s.twice) {
        if (q > 0) y += groupGap;
        tagTops.add(y);
        y += tagH + tagGap;
      }
      final n = s.questions[q].options.length;
      tops.add([for (var i = 0; i < n; i++) y + i * (rowH + gap)]);
      y += n * rowH + (n - 1) * gap;
    }
    return _ResultLayout(
      header: f.header,
      headerTop: headerTop,
      tagTops: tagTops,
      tops: tops,
      rowH: rowH,
      font: (rowH * 0.36).clamp(14.0, 18.0),
      footerTop: y + 16,
      line: line,
      lineSize: f.lineSize,
      whySize: f.whySize,
      why: f.why,
    );
  }

  // ---- build ----

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final w = box.maxWidth, h = box.maxHeight;
      return GestureDetector(
        // Until the crowd is in, a tap between the slabs is a near miss at
        // one, not a request to turn the card over.
        behavior: HitTestBehavior.opaque,
        onTap: _revealed ? null : () {},
        child: AnimatedBuilder(
          animation: Listenable.merge([_turn, _reveal]),
          builder: (context, _) => SizedBox(
            width: w,
            height: h,
            child: Stack(
              clipBehavior: Clip.none,
              children: _revealed
                  ? _revealing(w, h)
                  : _choosing(w, h),
            ),
          ),
        ),
      );
    },
  );

  List<Widget> _choosing(double w, double h) {
    final l10n = context.l10n;
    final out = <Widget>[
      Positioned(
        top: 0,
        left: 0,
        right: 0,
        height: _hintH,
        child: _Hint(
          left: l10n.sceneTapToPick,
          right: _s.twice ? l10n.sceneNOfM(_q + 1, 2) : null,
          ink: widget.ink,
        ),
      ),
    ];
    final turning = _q == 1 && _turn.value < 1;
    if (turning) {
      // A beat on the solid pick, then the first question leaves to the
      // left as the second comes in from the right.
      final e = Curves.easeInOutCubic.transform(
        ((_turn.value - .38) / .62).clamp(0.0, 1.0),
      );
      out.addAll(_question(0, w, h, dx: -w * .22 * e, opacity: 1 - e));
      out.addAll(_question(1, w, h, dx: w * .22 * (1 - e), opacity: e));
    } else {
      out.addAll(_question(_q, w, h));
    }
    return out;
  }

  List<Widget> _question(
    int q,
    double w,
    double h, {
    double dx = 0,
    double opacity = 1,
  }) {
    if (opacity <= 0) return const [];
    final qq = _s.questions[q];
    final c = _choice(q, w, h);
    final live = q == _q && _canPick;
    return [
      if (qq.prompt.isNotEmpty)
        Positioned(
          top: c.promptTop,
          left: dx,
          width: w,
          height: c.promptH,
          child: Opacity(
            opacity: opacity,
            child: Text(qq.prompt, maxLines: 3, style: _promptStyle),
          ),
        ),
      for (var i = 0; i < qq.options.length; i++)
        Positioned(
          top: c.tops[i],
          left: dx,
          width: w,
          height: c.rowH,
          child: Opacity(
            opacity: opacity,
            child: _slab(q, i, live: live, height: c.rowH, font: c.font),
          ),
        ),
    ];
  }

  Widget _slab(
    int q,
    int i, {
    required bool live,
    required double height,
    required double font,
  }) {
    final o = _s.questions[q].options[i];
    final chosen = _picks[q] == i || (live && _pressed == i);
    final row = _PollRow(
      label: o.label,
      height: height,
      font: font,
      maxLines: 2,
      solid: chosen ? 1 : 0,
      ring: 1,
      ink: widget.ink,
      ground: widget.ground,
    );
    if (!live) return ExcludeSemantics(child: row);
    return Semantics(
      button: true,
      label: o.label,
      onTap: () => _pick(i),
      child: ExcludeSemantics(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => setState(() => _pressed = i),
          onTapCancel: () => setState(() => _pressed = null),
          onTap: () => _pick(i),
          child: row,
        ),
      ),
    );
  }

  /// 0 → 1 over a stretch of the reveal.
  double _span(double from, double to, [Curve curve = Curves.easeOutCubic]) =>
      curve.transform(((_reveal.value - from) / (to - from)).clamp(0.0, 1.0));

  List<Widget> _revealing(double w, double h) {
    final s = _s;
    final l10n = context.l10n;
    final ink = widget.ink;
    final last = s.questions.length - 1;
    final from = _choice(last, w, h);
    final to = _result(w, h);
    final m = _span(0, .32, Curves.easeInOutCubic);
    final rest = _span(.12, .4);
    final out = <Widget>[];

    // The hint and the prompt give way to the study and the wordings.
    if (m < 1) {
      out.add(
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: _hintH,
          child: Opacity(
            opacity: 1 - m,
            child: _Hint(
              left: l10n.sceneTapToPick,
              right: s.twice ? l10n.sceneNOfM(2, 2) : null,
              ink: ink,
            ),
          ),
        ),
      );
      final prompt = s.questions[last].prompt;
      if (prompt.isNotEmpty) {
        out.add(
          Positioned(
            top: from.promptTop,
            left: 0,
            width: w,
            height: from.promptH,
            child: Opacity(
              opacity: 1 - m,
              child: ExcludeSemantics(
                child: Text(prompt, maxLines: 3, style: _promptStyle),
              ),
            ),
          ),
        );
      }
    }
    if (to.header) {
      out.add(
        Positioned(
          top: to.headerTop,
          left: 0,
          right: 0,
          height: _hintH,
          child: Opacity(
            opacity: rest,
            child: _Hint(left: s.who, ink: ink),
          ),
        ),
      );
    }
    for (var q = 0; q < s.questions.length; q++) {
      if (s.twice) {
        out.add(
          Positioned(
            top: to.tagTops[q],
            left: 0,
            right: 0,
            height: 16,
            child: Opacity(
              opacity: rest,
              child: Text(
                s.questions[q].tag,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.body(
                  size: 13,
                  weight: FontWeight.w700,
                  height: 1.2,
                  color: ink.withValues(alpha: 0.85),
                ),
              ),
            ),
          ),
        );
      }
      final opts = s.questions[q].options;
      for (var i = 0; i < opts.length; i++) {
        // The slabs just answered travel into their bars; the other
        // wording's bars fade in where they belong.
        final moving = q == last;
        final top = moving
            ? from.tops[i] + (to.tops[q][i] - from.tops[i]) * m
            : to.tops[q][i];
        final height = moving
            ? from.rowH + (to.rowH - from.rowH) * m
            : to.rowH;
        final font = moving ? from.font + (to.font - from.font) * m : to.font;
        final k = q * 2 + i;
        final grow = _span(.3 + k * .07, .7 + k * .07);
        final you = _picks[q] == i;
        final share = opts[i].share;
        out.add(
          Positioned(
            top: top,
            left: 0,
            width: w,
            height: height,
            child: Opacity(
              opacity: moving ? 1 : rest,
              child: Semantics(
                label: opts[i].label,
                value: you
                    ? '${share.round()}%, ${l10n.sceneYou}'
                    : '${share.round()}%',
                child: ExcludeSemantics(
                  child: _PollRow(
                    label: opts[i].label,
                    height: height,
                    font: font,
                    maxLines: m < .5 ? 2 : 1,
                    solid: you ? 1 : 0,
                    ring: 1 - m,
                    bar: share / 100 * grow,
                    percent: '${(share * grow).round()}%',
                    percentOpacity: (grow * 4).clamp(0.0, 1.0),
                    you: you ? rest : 0,
                    youLabel: l10n.sceneYou,
                    ink: ink,
                    ground: widget.ground,
                  ),
                ),
              ),
            ),
          ),
        );
      }
    }

    final fade = _span(.72, 1);
    out.add(
      Positioned(
        top: to.footerTop,
        left: 0,
        right: 0,
        bottom: 0,
        child: Semantics(
          liveRegion: true,
          child: Opacity(
            opacity: fade,
            child: Transform.translate(
              offset: Offset(0, 8 * (1 - fade)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    to.line,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: _lineStyle(to.lineSize),
                  ),
                  if (to.why) ...[
                    const SizedBox(height: 6),
                    Text(
                      s.why,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: _whyStyle(to.whySize),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
    return out;
  }
}

class _ChoiceLayout {
  final double promptTop, promptH, rowH, font;
  final List<double> tops;
  const _ChoiceLayout({
    required this.promptTop,
    required this.promptH,
    required this.tops,
    required this.rowH,
    required this.font,
  });
}

class _ResultLayout {
  final bool header, why;
  final double headerTop, rowH, font, footerTop, lineSize, whySize;
  final List<double> tagTops;
  final List<List<double>> tops;
  final String line;
  const _ResultLayout({
    required this.header,
    required this.headerTop,
    required this.tagTops,
    required this.tops,
    required this.rowH,
    required this.font,
    required this.footerTop,
    required this.line,
    required this.lineSize,
    required this.whySize,
    required this.why,
  });
}

/// The small line over the scene: what to do, or whose answers these are.
class _Hint extends StatelessWidget {
  final String left;
  final String? right;
  final Color ink;
  const _Hint({required this.left, this.right, required this.ink});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          left.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppText.label(size: 10.5, color: ink.withValues(alpha: 0.6)),
        ),
      ),
      if (right != null)
        Text(
          right!.toUpperCase(),
          style: AppText.label(size: 10.5, weight: FontWeight.w800, color: ink),
        ),
    ],
  );
}

/// One option: a slab to tap, and after the reveal a bar with its share.
///
/// The reader's own row is solid ink with the ground's colour for its
/// words and bar, the way a picked slab looked the moment it was tapped,
/// and wears a "YOU" tag.
class _PollRow extends StatelessWidget {
  final String label;
  final double height;
  final double font;
  final int maxLines;

  /// 0 an open slab, 1 the reader's.
  final double solid;

  /// How much of the choice ring shows; it gives way to the percentage.
  final double ring;

  /// How far the bar reaches, 0 to 1 of the row.
  final double bar;
  final String? percent;
  final double percentOpacity;

  /// How much of the "YOU" tag shows.
  final double you;
  final String youLabel;
  final Color ink;
  final Color ground;

  const _PollRow({
    required this.label,
    required this.height,
    required this.font,
    required this.maxLines,
    required this.solid,
    required this.ring,
    required this.ink,
    required this.ground,
    this.bar = 0,
    this.percent,
    this.percentOpacity = 0,
    this.you = 0,
    this.youLabel = '',
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular((height * 0.28).clamp(10.0, 22.0));
    final slab = Color.lerp(ink.withValues(alpha: 0.08), ink, solid)!;
    final barColor = Color.lerp(
      ink.withValues(alpha: 0.16),
      ground.withValues(alpha: 0.32),
      solid,
    )!;
    final face = Color.lerp(ink, ground, solid)!;
    final pad = (height * 0.2).clamp(12.0, 20.0);
    final ringSize = (font * 1.05).clamp(18.0, 26.0);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      decoration: BoxDecoration(borderRadius: radius, color: slab),
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (bar > 0)
              Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: bar.clamp(0.0, 1.0),
                  heightFactor: 1,
                  child: ColoredBox(color: barColor),
                ),
              ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: pad),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            label,
                            maxLines: maxLines,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.display(
                              size: font,
                              weight: FontWeight.w700,
                              height: 1.1,
                              spacing: -0.2 - font * 0.01,
                              color: face,
                            ),
                          ),
                        ),
                        if (you > 0) ...[
                          const SizedBox(width: 8),
                          Opacity(
                            opacity: you,
                            child: _YouTag(
                              label: youLabel,
                              ink: ink,
                              ground: ground,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: percent == null ? ringSize : null,
                    child: Stack(
                      alignment: Alignment.centerRight,
                      children: [
                        if (ring > 0)
                          Opacity(
                            opacity: ring,
                            child: SizedBox.square(
                              dimension: ringSize,
                              child: CustomPaint(
                                painter: _RingPainter(
                                  filled: solid > .5,
                                  color: face,
                                  hole: Color.lerp(ground, ink, solid)!,
                                ),
                              ),
                            ),
                          ),
                        if (percent != null)
                          Opacity(
                            opacity: percentOpacity,
                            child: Text(
                              percent!,
                              maxLines: 1,
                              style:
                                  AppText.display(
                                    size: font * 1.12,
                                    weight: FontWeight.w800,
                                    height: 1,
                                    spacing: -0.4,
                                    color: face,
                                  ).copyWith(
                                    fontFeatures: const [
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "YOU", in the ground's colour on the reader's solid row.
class _YouTag extends StatelessWidget {
  final String label;
  final Color ink;
  final Color ground;
  const _YouTag({required this.label, required this.ink, required this.ground});

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: ShapeDecoration(color: ground, shape: const StadiumBorder()),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(7, 3, 7, 3),
      child: Text(
        label,
        style: AppText.label(
          size: 9.5,
          weight: FontWeight.w800,
          spacing: 1,
          height: 1.1,
          color: ink,
        ),
      ),
    ),
  );
}

/// The choice ring: empty on an open slab, a filled disc with a hole once
/// picked, so the pick shows in shape as well as in colour.
class _RingPainter extends CustomPainter {
  final bool filled;
  final Color color;
  final Color hole;
  _RingPainter({required this.filled, required this.color, required this.hole});

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    if (filled) {
      canvas.drawCircle(c, r, Paint()..color = color);
      canvas.drawCircle(c, r * .38, Paint()..color = hole);
    } else {
      canvas.drawCircle(
        c,
        r - 1.1,
        Paint()
          ..color = color.withValues(alpha: 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.filled != filled || old.color != color || old.hole != hole;
}
