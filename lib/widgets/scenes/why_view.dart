import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/l10n.dart';
import '../../models/scene.dart';
import '../../theme.dart';

/// Plays a [WhyScene]: a cross-section of the ground, dug one layer at a time.
///
/// The everyday thing sits on the surface, above a ground line drawn the way
/// a section drawing draws earth. Below it the causes wait as strata, each a
/// little darker than the one above, so the reader sees how deep the shaft
/// goes before digging. Every "And why?" (or a tap, or a pull upward on the
/// section) lowers a plumb line one layer: the rope reaches the next node,
/// the view sinks with it, and the cause rises into its stratum. Depth ticks
/// at the right edge slide past, so the descent is felt as distance.
///
/// When the scene has a guess, the last layer before the root opens into two
/// or three branches, one per candidate root, and the reader must pick. Then
/// the weight drops straight down and hits bedrock: a flood of solid ink
/// spreads from the point of impact, the view jolts, and the root appears in
/// the ground colour, set larger than everything above it. The reader's guess
/// is printed under it with a tick or a cross.
///
/// The figure is never the only signal: every state has words (the layer's
/// line, the guess with its mark), and with animations off each step is
/// simply there on the next frame.
class WhySceneView extends StatefulWidget {
  final WhyScene scene;
  final Color ink;
  final Color ground;
  const WhySceneView({
    super.key,
    required this.scene,
    required this.ink,
    required this.ground,
  });

  @override
  State<WhySceneView> createState() => _WhySceneViewState();
}

class _WhySceneViewState extends State<WhySceneView>
    with TickerProviderStateMixin {
  /// Causes uncovered so far: 0 is the surface alone, `levels.length` the
  /// root. [_from] is where the current step began.
  int _stage = 0;
  int _from = 0;

  /// The option the reader took, once the guess is answered.
  int? _picked;

  /// One step of the descent. Starts finished, so the scene is at rest.
  late final AnimationController _dig = AnimationController(
    vsync: this,
    value: 1,
    duration: const Duration(milliseconds: 820),
  );

  // On arrival the weight dips into the hole and comes back, so the shaft
  // is seen to go down. The first part of the controller is the wait; no
  // Timer, which would outlive a disposed widget and hang a test.
  late final AnimationController _nudge = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1700),
  );
  bool _started = false;

  // A pull upward on the section: the view follows the finger with
  // resistance; let go far enough and it digs, otherwise it springs back.
  double _pull = 0;
  double _springFrom = 0;
  double _carry = 0;
  late final AnimationController _spring = AnimationController(
    vsync: this,
    value: 1,
    duration: const Duration(milliseconds: 320),
  );

  _WhyLayout? _layout;
  Object? _layoutKey;

  int get _n => widget.scene.levels.length;
  bool get _done => _stage == _n;
  bool get _hasGuess => widget.scene.guess != null;

  /// Waiting on the reader's pick before the root.
  bool get _guessing => _hasGuess && _stage == _n - 1;

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
  void didUpdateWidget(WhySceneView old) {
    super.didUpdateWidget(old);
    if (old.scene.raw != widget.scene.raw) {
      _dig.value = 1;
      _stage = _from = 0;
      _picked = null;
      _pull = _carry = 0;
      _layout = null;
    }
  }

  @override
  void dispose() {
    _dig.dispose();
    _nudge.dispose();
    _spring.dispose();
    super.dispose();
  }

  // ---- commands ----

  /// One layer deeper. A step still playing is finished first, so a fast
  /// reader is never made to wait and never skips a layer.
  void _descend({double carry = 0}) {
    if (_done || _guessing) return;
    _go(_stage + 1, carry: carry);
  }

  void _pick(int option) {
    if (!_guessing || _picked != null) return;
    setState(() => _picked = option);
    _go(_n);
  }

  void _go(int stage, {double carry = 0}) {
    _nudge.stop();
    _spring.value = 1;
    final toRoot = stage == _n;
    if (toRoot) {
      HapticFeedback.lightImpact();
    } else {
      HapticFeedback.selectionClick();
    }
    setState(() {
      _from = _stage;
      _stage = stage;
      _carry = carry;
      _pull = 0;
    });
    _dig.duration = Duration(
      milliseconds: toRoot
          ? 1700
          : (_hasGuess && stage == _n - 1)
          ? 1150
          : 820,
    );
    if (MediaQuery.disableAnimationsOf(context)) {
      _dig.value = 1;
    } else {
      _dig.forward(from: 0);
    }
  }

  double get _pullShown {
    if (_pull > 0) return 72 * (1 - math.exp(-_pull / 120));
    if (_spring.value < 1) {
      return _springFrom * (1 - Curves.easeOutCubic.transform(_spring.value));
    }
    return 0;
  }

  void _pullBy(double dy) {
    if (_done || _guessing) return;
    if (_dig.isAnimating) _dig.value = 1;
    _nudge.stop();
    _spring.value = 1;
    setState(() => _pull = (_pull - dy).clamp(0.0, 400.0));
  }

  void _letGo(double velocity) {
    if (_pull == 0) return;
    final shown = _pullShown;
    if (_pull > 56 || velocity < -500) {
      _descend(carry: shown);
      return;
    }
    setState(() {
      _pull = 0;
      _springFrom = shown;
    });
    if (MediaQuery.disableAnimationsOf(context)) {
      _spring.value = 1;
    } else {
      _spring.forward(from: 0);
    }
  }

  // ---- timeline ----

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
          _layout = _WhyLayout.measure(
            widget.scene,
            Size(box.maxWidth, box.maxHeight),
            scaler,
            context.l10n.sceneYourGuess.toUpperCase(),
          );
        }
        return AnimatedBuilder(
          animation: Listenable.merge([_dig, _nudge, _spring]),
          builder: (context, _) => _frame(context, _layout!),
        );
      },
    );
  }

  /// How much of the footer stands at a stage: the button while there is
  /// digging to do, nothing while the reader picks or once the root is in.
  double _footerAt(int stage) {
    if (stage == _n) return 0;
    if (stage == _n - 1 && _hasGuess) return 0;
    return 1;
  }

  Widget _frame(BuildContext context, _WhyLayout l) {
    final ink = widget.ink;
    final ground = widget.ground;
    final s = widget.scene;
    final t = _dig.value;
    final toRoot = _stage == _n && _from == _n - 1;
    final intoGuess = _hasGuess && _stage == _n - 1 && _from == _n - 2;

    // Each step's clock. The root's is longer: a verdict, a fall, an impact.
    final double rope, cam, rise, fig, flood, jolt, foot;
    var verdict = 0.0, chipsOut = 0.0, branches = 0.0, chipsIn = 0.0;
    var line = 0.0;
    if (toRoot) {
      verdict = _seg(t, 0, .16, Curves.easeOutCubic);
      chipsOut = _seg(t, .3, .44);
      rope = _seg(t, .2, .48, Curves.easeInQuad);
      cam = _seg(t, .08, .5, Curves.easeInOutCubic);
      flood = _seg(t, .48, .74, Curves.easeOutCubic);
      final j = _seg(t, .48, .78);
      jolt = j <= 0 || j >= 1 ? 0 : math.sin(j * math.pi * 3) * (1 - j) * 7;
      rise = _seg(t, .6, .86, Curves.easeOutCubic);
      fig = _seg(t, .7, .92, Curves.easeOutCubic);
      line = _seg(t, .8, 1, Curves.easeOutCubic);
      foot = _seg(t, .25, .7, Curves.easeInOutCubic);
      branches = 1;
      chipsIn = 1;
    } else {
      rope = _seg(t, 0, .55, Curves.easeInOutCubic);
      cam = _seg(t, 0, .7, Curves.easeInOutCubic);
      rise = _seg(t, .32, .78, Curves.easeOutCubic);
      fig = _seg(t, .5, .95, Curves.easeOutCubic);
      flood = _done ? 1 : 0;
      jolt = 0;
      foot = _seg(t, 0, .6, Curves.easeInOutCubic);
      if (intoGuess) {
        branches = _seg(t, .45, .85, Curves.easeInOutCubic);
        chipsIn = _seg(t, .6, 1, Curves.easeOutCubic);
      } else if (_guessing) {
        branches = chipsIn = 1;
      }
      if (_done) line = 1;
    }

    final footer =
        _footerAt(_from) + (_footerAt(_stage) - _footerAt(_from)) * foot;
    final footH = l.footerH * footer;
    final viewH = l.size.height - footH - l.footerGap * footer;
    final offset =
        (l.offsetFor(_from, viewH, _hasGuess) +
            (l.offsetFor(_stage, viewH, _hasGuess) -
                    l.offsetFor(_from, viewH, _hasGuess)) *
                cam) +
        _carry * (1 - cam) +
        _pullShown +
        jolt;

    // The weight's place along the rope: whole nodes behind, the step's
    // share of the next one ahead.
    final along = _from + (_stage - _from) * rope;
    final np = _seg(_nudge.value, .4, 1);
    final dip = _stage == 0 ? math.sin(np * math.pi) * 9 : 0.0;

    final picture = _WhyPicture(
      layout: l,
      offset: offset,
      viewH: viewH,
      along: along,
      dip: dip,
      flood: flood,
      branches: _hasGuess ? branches * (1 - chipsOut) : 0,
      right: s.guess?.answer ?? -1,
      verdict: verdict,
      ink: ink,
      ground: ground,
    );

    final active = !_done && !_guessing;
    final deepest = _stage;
    final texts = <Widget>[];

    // The surface and every cause uncovered so far. The newest rises into
    // its stratum; the ones above step back so the eye stays on the new one.
    for (var k = 0; k < _n; k++) {
      final shown = k <= _from ? 1.0 : (k == _stage ? rise : 0.0);
      if (shown <= 0) continue;
      final step = k == 0 ? s.start : s.levels[k - 1];
      final behind = k < deepest
          ? (k == _from && _stage > _from ? rise : 1.0)
          : 0.0;
      final emphasis = 1 - 0.42 * behind;
      texts.add(
        Positioned(
          left: l.textLeft,
          width: l.textW,
          top: l.textTop(k) - offset + (1 - shown) * 12,
          child: Opacity(
            opacity: (shown * emphasis).clamp(0.0, 1.0),
            child: Semantics(
              liveRegion: k == deepest && k > 0,
              child: _StepText(
                step: step,
                style: l.textStyle(k, ink),
                figure: k == _stage && k > _from ? fig : 1,
                figFont: l.figFont,
                color: ink,
                ground: ground,
              ),
            ),
          ),
        ),
      );
    }

    // The candidate roots, at the end of their branches.
    final g = s.guess;
    if (g != null && (_guessing || (toRoot && chipsOut < 1))) {
      final appear = _guessing ? chipsIn : 1.0;
      texts.add(
        Positioned(
          left: l.textLeft,
          width: l.textW,
          top: l.guessLabelY - offset,
          child: Opacity(
            opacity: appear * (1 - chipsOut),
            child: Text(
              l.guessLabel,
              style: AppText.label(
                size: 10.5,
                weight: FontWeight.w800,
                color: ink.withValues(alpha: 0.7),
              ),
            ),
          ),
        ),
      );
      for (var i = 0; i < g.options.length; i++) {
        final r = l.chips[i];
        final a = _seg(appear, i * .18, .64 + i * .18);
        final isRight = i == g.answer;
        final isPicked = i == _picked;
        texts.add(
          Positioned(
            left: r.left,
            width: r.width,
            top: r.top - offset + (1 - a) * 10,
            height: r.height,
            child: Opacity(
              opacity: (a * (1 - chipsOut)).clamp(0.0, 1.0),
              child: _Chip(
                label: g.options[i],
                onTap: _guessing && _picked == null ? () => _pick(i) : null,
                solid: isRight ? verdict : 0,
                dim: !isRight && !isPicked ? verdict : 0,
                mark: verdict > 0 && (isRight || isPicked)
                    ? (isRight ? 1 : -1)
                    : 0,
                font: l.chipFont,
                ink: ink,
                ground: ground,
              ),
            ),
          ),
        );
      }
    }

    // The root, on bedrock, and the reader's guess under it.
    if (_done) {
      texts.add(
        Positioned(
          left: l.textLeft,
          width: l.textW,
          top: l.textTop(_n) - offset + (1 - rise) * 16,
          child: Opacity(
            opacity: rise,
            child: Semantics(
              liveRegion: true,
              child: _StepText(
                step: s.root,
                style: l.textStyle(_n, ground),
                figure: fig,
                figFont: l.figFont * 1.08,
                color: ground,
                ground: ink,
              ),
            ),
          ),
        ),
      );
      if (g != null && _picked != null) {
        texts.add(
          Positioned(
            left: l.textLeft,
            width: l.textW,
            top: l.verdictY - offset + (1 - line) * 8,
            child: Opacity(
              opacity: line,
              child: _Verdict(
                label: l.guessLabel,
                option: g.options[_picked!],
                right: _picked == g.answer,
                color: ground,
              ),
            ),
          ),
        );
      }
    }

    final view = SizedBox(
      height: viewH,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: GestureDetector(
          // While there is digging to do, the section is the scene's: a tap
          // digs, a pull upward digs, and a sideways drag is held so the
          // deck does not slide away under a slanted pull. Once the root is
          // in, the card is free again.
          behavior: HitTestBehavior.opaque,
          onTap: _done ? null : (active ? _descend : () {}),
          onVerticalDragUpdate: _done ? null : (d) => _pullBy(d.delta.dy),
          onVerticalDragEnd: _done
              ? null
              : (d) => _letGo(d.velocity.pixelsPerSecond.dy),
          onVerticalDragCancel: _done ? null : () => _letGo(0),
          onHorizontalDragUpdate: _done ? null : (d) => _pullBy(d.delta.dy),
          onHorizontalDragEnd: _done ? null : (_) => _letGo(0),
          child: ShaderMask(
            // What has scrolled above the top fades out instead of being
            // cut by the edge.
            blendMode: BlendMode.dstIn,
            shaderCallback: (r) => LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white.withValues(
                  alpha: 1 - (offset / 24).clamp(0.0, 1.0),
                ),
                Colors.white,
              ],
              stops: [0, (22 / r.height).clamp(0.0, 1.0)],
            ).createShader(r),
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                Positioned.fill(
                  child: ExcludeSemantics(
                    child: RepaintBoundary(
                      child: CustomPaint(painter: _WhyPainter(picture)),
                    ),
                  ),
                ),
                ...texts,
              ],
            ),
          ),
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        view,
        if (footer > 0) ...[
          SizedBox(height: l.footerGap * footer),
          SizedBox(
            height: footH,
            child: ClipRect(
              child: OverflowBox(
                alignment: Alignment.topCenter,
                minHeight: l.footerH,
                maxHeight: l.footerH,
                child: Opacity(
                  opacity: footer,
                  child: _AskButton(
                    label: s.ask,
                    nudge: dip,
                    ink: ink,
                    ground: ground,
                    onTap: active ? _descend : null,
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

/// Where everything sits, measured once per size: the strata, the nodes
/// on the rope, the candidate roots. All in content coordinates, with 0 at
/// the top of the surface; the view scrolls by an offset.
class _WhyLayout {
  final Size size;
  final int n;
  final double font;
  final double rootFont;
  final double figFont;
  final double chipFont;
  final double footerH;
  final double footerGap;
  final String guessLabel;

  /// Top of each band: 0 the surface, 1…n the causes, n the root.
  final List<double> bandTop;
  final List<double> bandH;

  /// Where the rope passes: 0 the pulley over the hole, k the node of
  /// layer k.
  final List<double> nodeY;
  final List<double> _textTop;
  final List<Rect> chips;
  final double guessLabelY;
  final double verdictY;

  static const railX = 15.0;
  static const textLeft = 38.0;
  static const rightPad = 20.0;
  static const peek = 34.0;

  _WhyLayout._({
    required this.size,
    required this.n,
    required this.font,
    required this.rootFont,
    required this.figFont,
    required this.chipFont,
    required this.footerH,
    required this.footerGap,
    required this.guessLabel,
    required this.bandTop,
    required this.bandH,
    required this.nodeY,
    required List<double> textTop,
    required this.chips,
    required this.guessLabelY,
    required this.verdictY,
  }) : _textTop = textTop;

  double get textW => size.width - textLeft - rightPad;
  double get groundY => bandTop[1];
  double get contentH => bandTop[n] + bandH[n];
  double textTop(int k) => _textTop[k];
  double bottom(int k) => bandTop[k] + bandH[k];

  TextStyle textStyle(int k, Color color) => k == n
      ? AppText.display(
          size: rootFont,
          weight: FontWeight.w800,
          height: 1.12,
          spacing: -0.3 - rootFont * 0.012,
          color: color,
        )
      : AppText.display(
          size: font,
          weight: k == 0 ? FontWeight.w700 : FontWeight.w600,
          height: 1.16,
          spacing: -0.2 - font * 0.01,
          color: color,
        );

  /// How far the view has sunk at a stage: the newest layer whole, with a
  /// strip of the next stratum showing under it; at the guess and at the
  /// root, the bottom of the section.
  double offsetFor(int stage, double viewH, bool guess) {
    final most = math.max(0.0, contentH - viewH);
    if (stage >= n || (guess && stage == n - 1)) return most;
    return (bottom(stage) + peek - viewH).clamp(0.0, most);
  }

  static _WhyLayout measure(
    WhyScene s,
    Size size,
    TextScaler scaler,
    String guessLabel,
  ) {
    final n = s.levels.length;
    final tight = size.height < 330;
    final footerH = tight ? 46.0 : 52.0;
    final footerGap = tight ? 10.0 : 14.0;
    final textW = size.width - textLeft - rightPad;
    final withFooter = size.height - footerH - footerGap;

    TextPainter paint(String text, TextStyle style, double width, [int? max]) =>
        TextPainter(
          text: TextSpan(text: text, style: style),
          textDirection: TextDirection.ltr,
          textScaler: scaler,
          maxLines: max,
        )..layout(maxWidth: math.max(1, width));

    // Fit: start from type sized to the phone and step down until every
    // layer fits the view with room to see the one above, and the root and
    // the guess fit the whole height.
    var font = (size.height * 0.044).clamp(18.0, 23.0);
    late _WhyLayout out;
    while (true) {
      final rootFont = font * 1.2;
      final figFont = font * 1.06;
      final chipFont = (font * 0.74).clamp(14.0, 16.0);

      double stepH(WhyStep st, TextStyle style, double ff) {
        final tp = paint(st.text, style, textW);
        var h = tp.height;
        tp.dispose();
        if (st.hasFigure) h += 10 + _figRowH(st, ff, textW, scaler);
        return h;
      }

      final probe = _WhyLayout._(
        size: size,
        n: n,
        font: font,
        rootFont: rootFont,
        figFont: figFont,
        chipFont: chipFont,
        footerH: footerH,
        footerGap: footerGap,
        guessLabel: guessLabel,
        bandTop: const [],
        bandH: const [],
        nodeY: const [],
        textTop: const [],
        chips: const [],
        guessLabelY: 0,
        verdictY: 0,
      );

      final bandTop = <double>[];
      final bandH = <double>[];
      final textTop = <double>[];
      final nodeY = <double>[];
      var y = 0.0;

      // The surface: the line, then air down to the ground line.
      final firstLine = font * 1.16 * scaler.scale(1);
      bandTop.add(y);
      textTop.add(y + 4);
      final h0 = 4 + stepH(s.start, probe.textStyle(0, Colors.black), figFont);
      bandH.add(h0 + 22);
      y += h0 + 22;
      nodeY.add(y - 13); // the pulley, on top of its tripod

      const padTop = 16.0, padBottom = 20.0;
      for (var k = 1; k < n; k++) {
        final st = s.levels[k - 1];
        bandTop.add(y);
        textTop.add(y + padTop);
        nodeY.add(y + padTop + firstLine / 2);
        final h = padTop + stepH(st, probe.textStyle(k, Colors.black), figFont);
        bandH.add(h + padBottom);
        y += h + padBottom;
      }

      // The root band holds the root (and the verdict under it), or,
      // before that, the candidate roots: whichever is taller.
      final rootTop = y;
      const rootPad = 26.0;
      final rootTextH = stepH(
        s.root,
        probe.textStyle(n, Colors.black),
        figFont * 1.08,
      );
      final verdictH = s.guess == null ? 0.0 : 14 + 18.0 * scaler.scale(1);
      final rootH = rootPad + rootTextH + verdictH + rootPad;

      final chips = <Rect>[];
      var guessH = 0.0;
      var labelY = 0.0;
      if (s.guess != null) {
        labelY = rootTop + 16;
        var cy = labelY + 13 * scaler.scale(1) + 10;
        for (final o in s.guess!.options) {
          final tp = paint(
            o,
            AppText.body(size: chipFont, weight: FontWeight.w700, height: 1.2),
            textW - 36,
            2,
          );
          final h = math.max(tight ? 42.0 : 46.0, tp.height + 18);
          tp.dispose();
          chips.add(Rect.fromLTWH(textLeft, cy, textW, h));
          cy += h + (tight ? 7 : 9);
        }
        guessH = cy - (tight ? 7 : 9) + 18 - rootTop;
      }
      bandTop.add(rootTop);
      textTop.add(rootTop + rootPad);
      nodeY.add(rootTop + rootPad + rootFont * 1.12 * scaler.scale(1) / 2);
      bandH.add(math.max(rootH, guessH));

      out = _WhyLayout._(
        size: size,
        n: n,
        font: font,
        rootFont: rootFont,
        figFont: figFont,
        chipFont: chipFont,
        footerH: footerH,
        footerGap: footerGap,
        guessLabel: guessLabel,
        bandTop: bandTop,
        bandH: bandH,
        nodeY: nodeY,
        textTop: textTop,
        chips: chips,
        guessLabelY: labelY,
        verdictY: rootTop + rootPad + rootTextH + 14,
      );

      var fits = rootH <= size.height * 0.86;
      for (var k = 0; k < n && fits; k++) {
        if (bandH[k] + peek > withFooter * 0.94) fits = false;
      }
      if (s.guess != null && guessH + bandH[n - 1] * 0.5 > size.height) {
        fits = false;
      }
      if (fits || font <= 14.5) break;
      font -= 0.5;
    }
    return out;
  }
}

/// The height of a figure in its box beside its unit.
double _figRowH(WhyStep st, double figFont, double width, TextScaler scaler) {
  final f = TextPainter(
    text: TextSpan(
      text: st.figure,
      style: AppText.display(size: figFont, weight: FontWeight.w800, height: 1),
    ),
    textDirection: TextDirection.ltr,
    textScaler: scaler,
  )..layout();
  final boxW = f.width + 20;
  final boxH = f.height + 12;
  f.dispose();
  if (st.unit.isEmpty) return boxH;
  final u = TextPainter(
    text: TextSpan(
      text: st.unit,
      style: AppText.body(size: 13, weight: FontWeight.w600, height: 1.25),
    ),
    textDirection: TextDirection.ltr,
    textScaler: scaler,
    maxLines: 2,
  )..layout(maxWidth: math.max(1, width - boxW - 10));
  final h = math.max(boxH, u.height);
  u.dispose();
  return h;
}

/// A layer's line, and its figure in a box with the unit beside it.
class _StepText extends StatelessWidget {
  final WhyStep step;
  final TextStyle style;

  /// 0 → 1: the figure's box arriving.
  final double figure;
  final double figFont;
  final Color color;
  final Color ground;
  const _StepText({
    required this.step,
    required this.style,
    required this.figure,
    required this.figFont,
    required this.color,
    required this.ground,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(step.text, style: style),
      if (step.hasFigure) ...[
        const SizedBox(height: 10),
        Opacity(
          opacity: figure,
          child: Transform.translate(
            offset: Offset(-8 * (1 - figure), 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: color, width: 1.8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8.2, 4.2, 8.2, 4.2),
                    child: Text(
                      step.figure,
                      style: AppText.display(
                        size: figFont,
                        weight: FontWeight.w800,
                        height: 1,
                        spacing: -0.4,
                        color: color,
                      ).copyWith(
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ),
                if (step.unit.isNotEmpty) ...[
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      step.unit,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.body(
                        size: 13,
                        weight: FontWeight.w600,
                        height: 1.25,
                        color: color.withValues(alpha: 0.78),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    ],
  );
}

/// One candidate root. After the pick the right one turns solid with a
/// tick, the reader's wrong one keeps a cross, the rest step back.
class _Chip extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final double solid;
  final double dim;

  /// 1 a tick, -1 a cross, 0 nothing.
  final int mark;
  final double font;
  final Color ink;
  final Color ground;
  const _Chip({
    required this.label,
    required this.onTap,
    required this.solid,
    required this.dim,
    required this.mark,
    required this.font,
    required this.ink,
    required this.ground,
  });

  @override
  Widget build(BuildContext context) {
    final fill = Color.lerp(
      Color.alphaBlend(ink.withValues(alpha: 0.06), ground),
      ink,
      solid,
    )!;
    final face = Color.lerp(ink, ground, solid)!;
    return Semantics(
      button: true,
      label: label,
      checked: mark == 0 ? null : mark > 0,
      onTap: onTap,
      child: ExcludeSemantics(
        child: Opacity(
          opacity: 1 - 0.55 * dim,
          child: Material(
            color: fill,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(
                color: ink.withValues(alpha: 0.5 + 0.5 * solid),
                width: 1.6,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              splashColor: ink.withValues(alpha: 0.12),
              highlightColor: ink.withValues(alpha: 0.06),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.body(
                          size: font,
                          weight: FontWeight.w700,
                          height: 1.2,
                          color: face,
                        ),
                      ),
                    ),
                    if (mark != 0) ...[
                      const SizedBox(width: 8),
                      SizedBox.square(
                        dimension: 15,
                        child: CustomPaint(
                          painter: _MarkPainter(mark > 0, face),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Under the root: what the reader guessed, with a tick or a cross.
class _Verdict extends StatelessWidget {
  final String label;
  final String option;
  final bool right;
  final Color color;
  const _Verdict({
    required this.label,
    required this.option,
    required this.right,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Semantics(
    checked: right,
    child: Row(
      children: [
        Text(
          label,
          style: AppText.label(
            size: 10.5,
            weight: FontWeight.w800,
            color: color.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            option,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.body(
              size: 13.5,
              weight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
        const SizedBox(width: 7),
        SizedBox.square(
          dimension: 13,
          child: CustomPaint(painter: _MarkPainter(right, color)),
        ),
      ],
    ),
  );
}

class _MarkPainter extends CustomPainter {
  final bool tick;
  final Color color;
  _MarkPainter(this.tick, this.color);

  late final Paint _stroke = Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.2
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    if (tick) {
      canvas.drawPath(
        Path()
          ..moveTo(w * 0.06, h * 0.55)
          ..lineTo(w * 0.38, h * 0.86)
          ..lineTo(w * 0.94, h * 0.16),
        _stroke,
      );
    } else {
      canvas.drawLine(Offset(w * .15, h * .15), Offset(w * .85, h * .85), _stroke);
      canvas.drawLine(Offset(w * .85, h * .15), Offset(w * .15, h * .85), _stroke);
    }
  }

  @override
  bool shouldRepaint(_MarkPainter old) =>
      old.tick != tick || old.color != color;
}

/// The button that digs: the card's own words and a small arrow pointing
/// down, which dips with the weight when the card arrives.
class _AskButton extends StatelessWidget {
  final String label;
  final double nudge;
  final Color ink;
  final Color ground;
  final VoidCallback? onTap;
  const _AskButton({
    required this.label,
    required this.nudge,
    required this.ink,
    required this.ground,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    enabled: onTap != null,
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
          child: SizedBox.expand(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: AppText.display(
                    size: 18,
                    weight: FontWeight.w700,
                    height: 1,
                    spacing: -0.2,
                    color: ground,
                  ),
                ),
                const SizedBox(width: 10),
                Transform.translate(
                  offset: Offset(0, nudge * 0.35),
                  child: SizedBox(
                    width: 12,
                    height: 16,
                    child: CustomPaint(painter: _ArrowPainter(ground)),
                  ),
                ),
              ],
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
    canvas.drawLine(Offset(w / 2, 1.5), Offset(w / 2, h - 1.5), _stroke);
    canvas.drawPath(
      Path()
        ..moveTo(1.5, h - w / 2 - 1)
        ..lineTo(w / 2, h - 1.5)
        ..lineTo(w - 1.5, h - w / 2 - 1),
      _stroke,
    );
  }

  @override
  bool shouldRepaint(_ArrowPainter old) => old.color != color;
}

/// Everything the section painter needs for one frame, as a value, so the
/// painter repaints exactly when one of these changes.
@immutable
class _WhyPicture {
  final _WhyLayout layout;
  final double offset;
  final double viewH;

  /// The weight's place along the rope: k sits on layer k's node.
  final double along;

  /// The arrival dip of the weight below the pulley.
  final double dip;

  /// 0 → 1: bedrock spreading from the point of impact.
  final double flood;

  /// 0 → 1: the branches to the candidate roots drawing out.
  final double branches;
  final int right;

  /// 0 → 1: the right branch standing out from the others.
  final double verdict;
  final Color ink;
  final Color ground;

  const _WhyPicture({
    required this.layout,
    required this.offset,
    required this.viewH,
    required this.along,
    required this.dip,
    required this.flood,
    required this.branches,
    required this.right,
    required this.verdict,
    required this.ink,
    required this.ground,
  });

  @override
  bool operator ==(Object other) =>
      other is _WhyPicture &&
      identical(other.layout, layout) &&
      other.offset == offset &&
      other.viewH == viewH &&
      other.along == along &&
      other.dip == dip &&
      other.flood == flood &&
      other.branches == branches &&
      other.right == right &&
      other.verdict == verdict &&
      other.ink == ink &&
      other.ground == ground;

  @override
  int get hashCode => Object.hash(
    layout,
    offset,
    viewH,
    along,
    dip,
    flood,
    branches,
    right,
    verdict,
    ink,
    ground,
  );
}

/// The section: strata darkening with depth, the ground line hatched like
/// earth in a drawing, depth ticks at the right edge, the tripod and its
/// plumb line, the branches of the guess, and bedrock.
class _WhyPainter extends CustomPainter {
  final _WhyPicture p;
  _WhyPainter(this.p);

  final Paint _fill = Paint();
  final Paint _line = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  _WhyLayout get l => p.layout;

  /// The soft top edge of stratum [k]: a hand-drawn wave, straight for the
  /// ground line.
  double _wave(double x, int k, double w) => k <= 1
      ? 0
      : 2.4 * math.sin(2 * math.pi * (x / w) * 1.15 + k * 1.9);

  Path _band(int k, double top, double bottom, double w) {
    final path = Path()..moveTo(0, top + _wave(0, k, w));
    for (var i = 1; i <= 24; i++) {
      final x = w * i / 24;
      path.lineTo(x, top + _wave(x, k, w));
    }
    if (k < l.n) {
      for (var i = 24; i >= 0; i--) {
        final x = w * i / 24;
        path.lineTo(x, bottom + _wave(x, k + 1, w));
      }
    } else {
      path
        ..lineTo(w, bottom)
        ..lineTo(0, bottom);
    }
    return path..close();
  }

  /// A point on the rope at [a] (k is layer k's node, 0 the pulley).
  /// Between nodes the rope sways a little, alternately; the fall to the
  /// root is a plumb line.
  Offset _ropeAt(double a) {
    final k = a.floor().clamp(0, l.n - 1);
    final f = (a - k).clamp(0.0, 1.0);
    final y0 = l.nodeY[k], y1 = l.nodeY[k + 1];
    const x = _WhyLayout.railX;
    final sway = k == l.n - 1 ? 0.0 : (k.isEven ? 6.0 : -6.0);
    final u = 1 - f;
    final dx = 3 * u * u * f * sway + 3 * u * f * f * -sway;
    final dy = u * u * u * y0 +
        3 * u * u * f * (y0 + (y1 - y0) * .33) +
        3 * u * f * f * (y0 + (y1 - y0) * .66) +
        f * f * f * y1;
    return Offset(x + dx, dy);
  }

  void _rope(Canvas canvas, Color c, Color hole) {
    final end = p.along;
    final path = Path();
    final o = _ropeAt(0);
    path.moveTo(o.dx, o.dy);
    final steps = (end * 22).ceil();
    for (var i = 1; i <= steps; i++) {
      final q = _ropeAt(end * i / steps);
      path.lineTo(q.dx, q.dy);
    }
    _line
      ..color = c
      ..strokeWidth = 2.2;
    canvas.drawPath(path, _line);

    // Passed nodes are rings; the weight hangs at the end.
    for (var k = 1; k <= end.floor() && k <= l.n; k++) {
      if (k == end && k > 0) break;
      final at = _ropeAt(k.toDouble());
      _fill.color = c;
      canvas.drawCircle(at, 5.5, _fill);
      _fill.color = hole;
      canvas.drawCircle(at, 2.4, _fill);
    }
    final bob = end == 0 ? o + Offset(0, 9 + p.dip) : _ropeAt(end);
    if (end == 0) {
      canvas.drawLine(o, bob, _line);
    }
    _fill.color = c;
    canvas.drawCircle(bob, 7, _fill);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final ink = p.ink, ground = p.ground;
    canvas.save();
    canvas.translate(0, -p.offset);
    final bottom = math.max(l.contentH, p.offset + size.height) + 30;

    // Strata, a little darker with every layer down.
    for (var k = 1; k <= l.n; k++) {
      final top = l.bandTop[k];
      final bot = k < l.n ? l.bottom(k) : bottom;
      final depth = (k - 1) / math.max(1, l.n - 1);
      _fill.color = ink.withValues(alpha: 0.035 + 0.16 * depth);
      canvas.drawPath(_band(k, top, bot, w), _fill);
      if (k > 1) {
        final edge = Path()..moveTo(0, top + _wave(0, k, w));
        for (var i = 1; i <= 24; i++) {
          final x = w * i / 24;
          edge.lineTo(x, top + _wave(x, k, w));
        }
        _line
          ..color = ink.withValues(alpha: 0.13)
          ..strokeWidth = 1;
        canvas.drawPath(edge, _line);
      }
    }

    // The ground line, broken where the hole goes down, hatched below.
    final gy = l.groundY;
    const hx = _WhyLayout.railX;
    _line
      ..color = ink
      ..strokeWidth = 2.4;
    canvas.drawLine(Offset(0, gy), Offset(hx - 6, gy), _line);
    canvas.drawLine(Offset(hx + 6, gy), Offset(w, gy), _line);
    _line
      ..color = ink.withValues(alpha: 0.3)
      ..strokeWidth = 1.2;
    for (var x = hx + 14.0; x < w + 6; x += 9) {
      canvas.drawLine(Offset(x, gy + 2), Offset(x - 6, gy + 8), _line);
    }
    _line
      ..color = ink
      ..strokeWidth = 1.6;
    canvas.drawLine(Offset(hx - 6, gy), Offset(hx - 6, gy + 8), _line);
    canvas.drawLine(Offset(hx + 6, gy), Offset(hx + 6, gy + 8), _line);

    // Depth ticks at the right edge, sliding past as the view sinks.
    _ticks(canvas, w, gy, bottom, ink);

    // The tripod over the hole, its pulley where the rope starts.
    final top = l.nodeY[0];
    _line
      ..color = ink
      ..strokeWidth = 2;
    canvas.drawLine(Offset(hx - 10, gy), Offset(hx, top), _line);
    canvas.drawLine(Offset(hx + 10, gy), Offset(hx, top), _line);
    _fill.color = ink;
    canvas.drawCircle(Offset(hx, top), 3.4, _fill);

    // Branches to the candidate roots.
    if (p.branches > 0 && l.chips.isNotEmpty) {
      final from = _ropeAt((l.n - 1).toDouble());
      for (var i = 0; i < l.chips.length; i++) {
        final c = l.chips[i];
        final to = Offset(c.left - 3, c.center.dy);
        final path = Path()
          ..moveTo(from.dx, from.dy)
          ..cubicTo(
            from.dx,
            from.dy + (to.dy - from.dy) * .62,
            from.dx + (to.dx - from.dx) * .2,
            to.dy,
            to.dx,
            to.dy,
          );
        final grow = ((p.branches * 1.25) - i * .12).clamp(0.0, 1.0);
        if (grow <= 0) continue;
        final m = path.computeMetrics().first;
        final emphasis = i == p.right ? p.verdict : -p.verdict;
        _line
          ..color = ink.withValues(
            alpha: (0.55 + 0.45 * emphasis).clamp(0.12, 1.0),
          )
          ..strokeWidth = 1.6 + emphasis.clamp(0.0, 1.0) * 1.2;
        canvas.drawPath(m.extractPath(0, m.length * grow), _line);
        if (grow >= 1) {
          _fill.color = _line.color;
          canvas.drawCircle(to, 3, _fill);
        }
      }
    }

    _rope(canvas, ink, ground);

    // Bedrock: solid ink spreading from where the weight landed, with the
    // rope, the ticks and the weight drawn again on it in the ground colour.
    if (p.flood > 0) {
      final hit = _ropeAt(l.n.toDouble());
      final rootTop = l.bandTop[l.n];
      final reach = math.sqrt(
        math.pow(w, 2) + math.pow(bottom - rootTop, 2),
      );
      canvas.save();
      canvas.clipPath(_band(l.n, rootTop, bottom, w));
      canvas.clipPath(
        Path()..addOval(Rect.fromCircle(center: hit, radius: reach * p.flood)),
      );
      _fill.color = ink;
      canvas.drawRect(Rect.fromLTRB(0, rootTop - 4, w, bottom), _fill);
      _ticks(canvas, w, rootTop, bottom, ground);
      _rope(canvas, ground, ink);
      canvas.restore();
    }
    canvas.restore();
  }

  void _ticks(Canvas canvas, double w, double from, double to, Color c) {
    _line
      ..color = c.withValues(alpha: 0.28)
      ..strokeWidth = 1.2;
    var i = 0;
    for (var y = l.groundY + 16; y < to; y += 16, i++) {
      if (y < from) continue;
      final long = i % 4 == 3;
      canvas.drawLine(Offset(w - (long ? 13 : 7), y), Offset(w - 3, y), _line);
    }
  }

  @override
  bool shouldRepaint(_WhyPainter old) => old.p != p;
}
