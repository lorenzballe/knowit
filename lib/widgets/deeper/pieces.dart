/// The pieces Go deeper (deeper_sheet.dart) is built from: a part's own
/// ground with its picture and name, the button that asks, the light that
/// crosses it while the answer comes, the answer unfolding, the two views
/// facing each other, the reader's words and the answer as a conversation,
/// the frosted glass over what Astute+ shows, and the source at the foot.
library;

import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;

import '../../l10n/l10n.dart';
import '../../theme.dart';
import '../chunky.dart' show chunkyEdge;
import 'art.dart';
import 'app_style.dart';
import 'editorial.dart';
import 'look.dart';

/// Whether the reader asked for less motion.
bool deeperStill(BuildContext context) =>
    MediaQuery.disableAnimationsOf(context);

/// Brings a part in: up from a little below, out of nothing, as its turn
/// in the sheet's arrival comes.
class DeeperArrive extends StatelessWidget {
  const DeeperArrive({
    super.key,
    required this.animation,
    required this.child,
    this.distance = 34,
  });

  final Animation<double> animation;
  final double distance;
  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: animation,
    // A part is drawn once and moved as a picture while it arrives.
    child: RepaintBoundary(child: child),
    builder: (context, child) {
      final double v = animation.value;
      final bool calm = deeperStyle == DeeperStyle.app;
      return Opacity(
        opacity: v.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, (calm ? 14 : distance) * (1 - v)),
          child: Transform.scale(
            scale: calm ? 1 : 0.965 + 0.035 * v,
            alignment: Alignment.topCenter,
            child: child,
          ),
        ),
      );
    },
  );
}

/// A part's ground: washed with the part's colour from its top left corner,
/// its picture and its name at the head, then what it says.
class DeeperTile extends StatelessWidget {
  const DeeperTile({
    super.key,
    required this.tone,
    required this.art,
    required this.look,
    required this.draw,
    required this.title,
    required this.child,
    this.lead,
    this.badge,
  });

  final DeeperTone tone;
  final DeeperArt art;
  final DeeperLook look;

  /// How far the picture has drawn itself in.
  final Animation<double> draw;
  final String title;

  /// A line under the name on what the part gives, for the parts that
  /// give it only when asked.
  final String? lead;

  /// A mark beside the name: Astute+, on the free plan.
  final Widget? badge;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (deeperEditorial) {
      return EdSection(
        look: look,
        title: title,
        lead: lead,
        badge: badge,
        child: child,
      );
    }
    final Palette p = context.p;
    final bool roomy = MediaQuery.textScalerOf(context).scale(1) <= 1.35;
    // The detail that stands out is in the colour across the wheel, unless
    // the part wears that colour itself: then in the subject's own side.
    final double gap = (tone.hue - look.sideB.hue).abs() % 360;
    final bool across = math.min(gap, 360 - gap) < 40;
    final Widget mark = DeeperMedallion(
      art: art,
      vivid: tone.vivid,
      accent: across ? look.sideA.fill : look.sideB.fill,
      second: across ? look.sideB.fill : look.sideA.fill,
      progress: draw,
    );
    final Widget name = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (badge case final Widget b) ...[b, const SizedBox(height: 7)],
        Semantics(
          header: true,
          child: Text(
            title,
            style: AppText.display(
              size: 21.5,
              weight: FontWeight.w600,
              height: 1.14,
              spacing: -0.35,
              color: tone.title,
            ),
          ),
        ),
        if (lead case final String said) ...[
          const SizedBox(height: 5),
          Text(
            said,
            style: AppText.body(size: 14.5, height: 1.38, color: p.inkMuted),
          ),
        ],
      ],
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: const Alignment(0.7, 1),
          colors: [tone.wash, tone.tile],
          stops: const [0, 0.62],
        ),
        border: Border.all(color: tone.edge),
        boxShadow: look.dark
            ? null
            : [
                BoxShadow(
                  color: tone.shadow,
                  blurRadius: 30,
                  offset: const Offset(0, 14),
                  spreadRadius: -8,
                ),
                const BoxShadow(
                  color: Color(0x0A000000),
                  blurRadius: 3,
                  offset: Offset(0, 1),
                ),
              ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (roomy)
              Row(
                children: [
                  mark,
                  const SizedBox(width: 15),
                  Expanded(child: name),
                ],
              )
            else ...[
              Align(alignment: AlignmentDirectional.centerStart, child: mark),
              const SizedBox(height: 12),
              name,
            ],
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

/// The words of a part, large and easy to read.
TextStyle deeperBody(BuildContext context) => deeperEditorial
    ? edBody(context)
    : AppText.body(size: 17, height: 1.5, color: context.p.ink);

/// The idea said simply: set in the display face, as the card's own voice.
TextStyle deeperSimply(BuildContext context) => deeperEditorial
    ? edSimply(context)
    : AppText.display(
        size: 20,
        weight: FontWeight.w500,
        height: 1.38,
        spacing: -0.2,
        color: context.p.ink,
      );

/// The button that asks Claude: the part's colour on a darker edge, pressed
/// down into it. While the answer comes, a light crosses it.
class DeeperAskButton extends StatefulWidget {
  const DeeperAskButton({
    super.key,
    required this.label,
    required this.vivid,
    required this.onPressed,
    this.locked = false,
    this.busy = false,
    this.look,
  });

  final String label;
  final DeeperVivid vivid;

  /// The sheet's look, for the editorial ways of setting it.
  final DeeperLook? look;

  /// Null leaves it off: nothing written yet.
  final VoidCallback? onPressed;

  /// On the free plan: a lock where the spark is, and the paywall behind it.
  final bool locked;

  /// The answer is on its way: the light crosses it, and it says so.
  final bool busy;

  @override
  State<DeeperAskButton> createState() => _DeeperAskButtonState();
}

class _DeeperAskButtonState extends State<DeeperAskButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    if (deeperEditorial && widget.look != null) {
      return EdAskButton(
        look: widget.look!,
        label: widget.label,
        onPressed: widget.onPressed,
        locked: widget.locked,
        busy: widget.busy,
      );
    }
    final Palette p = context.p;
    final bool on = widget.onPressed != null && !widget.busy;
    final bool lit = on || widget.busy;
    final Color ink = lit ? widget.vivid.ink : p.inkFaint;
    final Color edge = lit
        ? chunkyEdge(widget.vivid.deep, 0.12)
        : chunkyEdge(p.line, 0.06);
    final bool pressed = _down && on;
    final Widget face = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(99),
        color: lit ? null : p.line,
        gradient: lit
            ? LinearGradient(colors: [widget.vivid.fill, widget.vivid.deep])
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 20, 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              widget.locked ? Icons.lock_rounded : Icons.auto_awesome_rounded,
              size: 18,
              color: ink,
            ),
            const SizedBox(width: 9),
            Flexible(
              child: AnimatedSwitcher(
                duration: deeperStill(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 220),
                child: Text(
                  widget.busy ? context.l10n.deeperBusy : widget.label,
                  key: ValueKey(widget.busy),
                  style: AppText.body(
                    size: 15.5,
                    weight: FontWeight.w700,
                    height: 1.25,
                    color: ink,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    return Semantics(
      button: true,
      enabled: on,
      liveRegion: widget.busy,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: on ? (_) => setState(() => _down = true) : null,
        onTapUp: on ? (_) => setState(() => _down = false) : null,
        onTapCancel: on ? () => setState(() => _down = false) : null,
        onTap: on
            ? () {
                HapticFeedback.lightImpact();
                widget.onPressed!();
              }
            : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 70),
          decoration: BoxDecoration(
            color: edge,
            borderRadius: BorderRadius.circular(99),
            boxShadow: lit && !p.isDark
                ? [
                    BoxShadow(
                      color: widget.vivid.deep.withValues(alpha: 0.28),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                      spreadRadius: -6,
                    ),
                  ]
                : null,
          ),
          padding: EdgeInsets.only(
            top: pressed ? 4 : 0,
            bottom: pressed ? 0 : 4,
          ),
          child: DeeperSheen(active: widget.busy, child: face),
        ),
      ),
    );
  }
}

/// A band of light that crosses [child] again and again while [active]:
/// something is on its way. Still, for a reader who asked for less motion.
class DeeperSheen extends StatefulWidget {
  const DeeperSheen({
    super.key,
    required this.active,
    required this.child,
    this.strength = 0.42,
  });

  final bool active;
  final Widget child;

  /// How bright the band is at its middle.
  final double strength;

  @override
  State<DeeperSheen> createState() => _DeeperSheenState();
}

class _DeeperSheenState extends State<DeeperSheen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _light = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1450),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _run();
  }

  @override
  void didUpdateWidget(DeeperSheen old) {
    super.didUpdateWidget(old);
    _run();
  }

  void _run() {
    final bool go = widget.active && !deeperStill(context);
    if (go && !_light.isAnimating) {
      _light.repeat();
    } else if (!go && _light.isAnimating) {
      _light.stop();
    }
  }

  @override
  void dispose() {
    _light.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active || deeperStill(context)) return widget.child;
    return AnimatedBuilder(
      animation: _light,
      child: widget.child,
      builder: (context, child) => ShaderMask(
        blendMode: BlendMode.srcATop,
        shaderCallback: (Rect r) => LinearGradient(
          begin: const Alignment(-1, -0.6),
          end: const Alignment(1, 0.6),
          colors: [
            Colors.white.withValues(alpha: 0),
            Colors.white.withValues(alpha: widget.strength),
            Colors.white.withValues(alpha: 0),
          ],
          stops: const [0.35, 0.5, 0.65],
          transform: _Slide(_light.value),
        ).createShader(r),
        child: child,
      ),
    );
  }
}

/// Moves a gradient across its box: from wholly before it to wholly past.
class _Slide extends GradientTransform {
  const _Slide(this.v);

  final double v;

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) =>
      Matrix4.translationValues(bounds.width * (v * 2.4 - 1.2), 0, 0);
}

/// Lines where the answer will be, the light crossing them.
class DeeperSkeleton extends StatelessWidget {
  const DeeperSkeleton({super.key, required this.tone});

  final DeeperTone tone;

  @override
  Widget build(BuildContext context) {
    final Color bar = context.p.isDark
        ? Colors.white.withValues(alpha: 0.08)
        : tone.wash;
    Widget line(double part) => FractionallySizedBox(
      alignment: AlignmentDirectional.centerStart,
      widthFactor: part,
      child: Container(
        height: 12,
        margin: const EdgeInsets.only(bottom: 11),
        decoration: BoxDecoration(
          color: bar,
          borderRadius: BorderRadius.circular(6),
        ),
      ),
    );
    return ExcludeSemantics(
      child: DeeperSheen(
        active: true,
        strength: context.p.isDark ? 0.24 : 0.7,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [line(1), line(0.93), line(0.62)],
        ),
      ),
    );
  }
}

/// An answer as it comes: let down over the words from the top, as a page
/// is uncovered, while the part grows to hold it.
class DeeperUnfold extends StatefulWidget {
  const DeeperUnfold({super.key, required this.child});

  final Widget child;

  @override
  State<DeeperUnfold> createState() => _DeeperUnfoldState();
}

class _DeeperUnfoldState extends State<DeeperUnfold>
    with SingleTickerProviderStateMixin {
  late final AnimationController _show = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 820),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (deeperStill(context)) {
      _show.value = 1;
    } else if (_show.isDismissed) {
      _show.forward();
    }
  }

  @override
  void dispose() {
    _show.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: AnimatedBuilder(
      animation: _show,
      child: widget.child,
      builder: (context, child) {
        final double v = Curves.easeOutCubic.transform(_show.value);
        // Uncovered: the words as they are, with no layer over them. What
        // is unfolded is only ever words, so nothing is lost as the layer
        // goes.
        if (v >= 1) return child!;
        const double feather = 0.35;
        final double edge = -feather + v * (1 + feather);
        return ShaderMask(
          blendMode: BlendMode.dstIn,
          shaderCallback: (Rect r) => LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: const [Colors.white, Colors.white, Color(0x00FFFFFF)],
            stops: [0, edge.clamp(0.0, 1.0), (edge + feather).clamp(0.0, 1.0)],
          ).createShader(r),
          child: Transform.translate(
            offset: Offset(0, 8 * (1 - v)),
            child: child,
          ),
        );
      },
    ),
  );
}

/// Three dots that rise in turn: the answer is being written.
class DeeperTyping extends StatefulWidget {
  const DeeperTyping({super.key, required this.colour});

  final Color colour;

  @override
  State<DeeperTyping> createState() => _DeeperTypingState();
}

class _DeeperTypingState extends State<DeeperTyping>
    with SingleTickerProviderStateMixin {
  late final AnimationController _beat = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (deeperStill(context)) {
      _beat.stop();
    } else if (!_beat.isAnimating) {
      _beat.repeat();
    }
  }

  @override
  void dispose() {
    _beat.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: context.l10n.deeperBusy,
    liveRegion: true,
    child: SizedBox(
      width: 44,
      height: 22,
      child: CustomPaint(painter: _Dots(_beat, widget.colour)),
    ),
  );
}

class _Dots extends CustomPainter {
  _Dots(this.beat, this.colour) : super(repaint: beat);

  final Animation<double> beat;
  final Color colour;

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < 3; i++) {
      final double v = ((beat.value - i * 0.14) / 0.5).clamp(0.0, 1.0);
      final double up = math.sin(v * math.pi);
      canvas.drawCircle(
        Offset(8 + i * 14.0, size.height / 2 + 3 - 6 * up),
        4,
        Paint()..color = colour.withValues(alpha: 0.45 + 0.55 * up),
      );
    }
  }

  @override
  bool shouldRepaint(_Dots old) => old.colour != colour || old.beat != beat;
}

/// The reader's own words, on the right in the part's colour, as a sent
/// message is.
class DeeperReaderBubble extends StatelessWidget {
  const DeeperReaderBubble({
    super.key,
    required this.text,
    required this.vivid,
  });

  final String text;
  final DeeperVivid vivid;

  @override
  Widget build(BuildContext context) => deeperStyle == DeeperStyle.app
      ? AppReaderBubble(text: text)
      : deeperEditorial
      ? _edReader(context)
      : Align(
          alignment: AlignmentDirectional.centerEnd,
          child: FractionallySizedBox(
            widthFactor: 0.86,
            alignment: AlignmentDirectional.centerEnd,
            child: Align(
              alignment: AlignmentDirectional.centerEnd,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: vivid.gradient,
                  borderRadius: const BorderRadiusDirectional.only(
                    topStart: Radius.circular(22),
                    topEnd: Radius.circular(22),
                    bottomStart: Radius.circular(22),
                    bottomEnd: Radius.circular(6),
                  ).resolve(Directionality.of(context)),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 13),
                  child: Text(
                    text,
                    style: AppText.body(
                      size: 16,
                      weight: FontWeight.w600,
                      height: 1.42,
                      color: vivid.ink,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

  /// The reader's words, set editorially: quoted, under a fine rule at
  /// their side, as a page sets what somebody said.
  Widget _edReader(BuildContext context) {
    final Palette p = context.p;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(width: 1.5, color: p.inkFaint),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                text,
                style: AppText.body(
                  size: 15.5,
                  weight: FontWeight.w500,
                  height: 1.5,
                  color: p.ink.withValues(alpha: 0.72),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The answer, on the left, under the spark that marks it Claude's.
class DeeperAnswerBubble extends StatelessWidget {
  const DeeperAnswerBubble({
    super.key,
    required this.tone,
    required this.child,
  });

  final DeeperTone tone;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (deeperEditorial) {
      // Set editorially: the answer as the page's own words, under the
      // reader's, with nothing round it.
      return AnimatedSize(
        duration: deeperStill(context)
            ? Duration.zero
            : const Duration(milliseconds: 460),
        curve: Curves.easeOutCubic,
        alignment: AlignmentDirectional.topStart,
        child: Padding(
          padding: const EdgeInsetsDirectional.only(top: 4, end: 24),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: child,
          ),
        ),
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        ExcludeSemantics(
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: tone.vivid.gradient,
            ),
            child: Icon(
              Icons.auto_awesome_rounded,
              size: 17,
              color: tone.vivid.ink,
            ),
          ),
        ),
        const SizedBox(width: 9),
        Flexible(
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: AnimatedSize(
              duration: deeperStill(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 460),
              curve: Curves.easeOutCubic,
              alignment: AlignmentDirectional.topStart,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: tone.field,
                  border: Border.all(color: tone.edge),
                  borderRadius: const BorderRadiusDirectional.only(
                    topStart: Radius.circular(22),
                    topEnd: Radius.circular(22),
                    bottomStart: Radius.circular(6),
                    bottomEnd: Radius.circular(22),
                  ).resolve(Directionality.of(context)),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 13, 16, 14),
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// A view as the card writes it, "Label: one or two sentences", split into
/// its label and its words; a view with no label of its own gets [fallback].
(String, String) splitView(String view, String fallback) {
  final RegExpMatch? m = RegExp(
    r'^([^:：]{2,72})[:：]\s+(.+)$',
    dotAll: true,
  ).firstMatch(view.trim());
  if (m == null) return (fallback, view.trim());
  return (m.group(1)!.trim(), m.group(2)!.trim());
}

/// The two views facing each other: one half in each of two contrasting
/// colours, the medallion between them. Side by side where there is room
/// for a line of words in each, one over the other on a phone.
class DeeperVersus extends StatelessWidget {
  const DeeperVersus({
    super.key,
    required this.look,
    required this.a,
    required this.b,
    required this.progress,
  });

  final DeeperLook look;
  final (String, String) a;
  final (String, String)? b;

  /// The face-off's own arrival: the halves slide in from either side and
  /// the medallion lands between them.
  final Animation<double> progress;

  @override
  Widget build(BuildContext context) {
    if (deeperEditorial) return EdVersus(look: look, a: a, b: b);
    final (String, String)? other = b;
    if (other == null) {
      return _Half(
        vivid: look.sideB,
        label: a.$1,
        text: a.$2,
        radius: BorderRadius.circular(22),
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      );
    }
    final double scale = MediaQuery.textScalerOf(context).scale(1);
    return LayoutBuilder(
      builder: (context, box) {
        final bool across = box.maxWidth / scale >= 560;
        const double gap = 8;
        const Radius outer = Radius.circular(22);
        const Radius seam = Radius.circular(10);
        final Widget first = _In(
          progress: progress,
          from: across ? const Offset(-30, 0) : const Offset(-26, 0),
          start: 0,
          child: _Half(
            vivid: look.sideA,
            label: a.$1,
            text: a.$2,
            radius: across
                ? const BorderRadius.horizontal(left: outer, right: seam)
                : const BorderRadius.vertical(top: outer, bottom: seam),
            padding: across
                ? const EdgeInsets.fromLTRB(18, 18, 34, 20)
                : const EdgeInsets.fromLTRB(18, 18, 18, 32),
          ),
        );
        final Widget second = _In(
          progress: progress,
          from: across ? const Offset(30, 0) : const Offset(26, 0),
          start: 0.12,
          child: _Half(
            vivid: look.sideB,
            label: other.$1,
            text: other.$2,
            radius: across
                ? const BorderRadius.horizontal(left: seam, right: outer)
                : const BorderRadius.vertical(top: seam, bottom: outer),
            padding: across
                ? const EdgeInsets.fromLTRB(34, 18, 18, 20)
                : const EdgeInsets.fromLTRB(18, 32, 18, 20),
          ),
        );
        final Widget medal = _Medal(
          progress: progress,
          ring: look.tone(DeeperPart.sides).tile,
        );
        // The medallion is painted by the second half, after the first,
        // so it lies over the seam and over both.
        if (across) {
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: first),
                const SizedBox(width: gap),
                Expanded(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned.fill(child: second),
                      PositionedDirectional(
                        start: -gap / 2 - _Medal.size / 2,
                        top: 0,
                        bottom: 0,
                        child: Center(child: medal),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            first,
            const SizedBox(height: gap),
            Stack(
              clipBehavior: Clip.none,
              children: [
                second,
                Positioned(
                  top: -gap / 2 - _Medal.size / 2,
                  left: 0,
                  right: 0,
                  child: Center(child: medal),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

/// Slides a half in from its own side.
class _In extends StatelessWidget {
  const _In({
    required this.progress,
    required this.from,
    required this.start,
    required this.child,
  });

  final Animation<double> progress;
  final Offset from;
  final double start;
  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: progress,
    child: child,
    builder: (context, child) {
      final double v = Curves.easeOutCubic.transform(
        ((progress.value - start) / 0.55).clamp(0.0, 1.0),
      );
      return Opacity(
        opacity: v,
        child: Transform.translate(offset: from * (1 - v), child: child),
      );
    },
  );
}

class _Half extends StatelessWidget {
  const _Half({
    required this.vivid,
    required this.label,
    required this.text,
    required this.radius,
    required this.padding,
  });

  final DeeperVivid vivid;
  final String label;
  final String text;
  final BorderRadius radius;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(gradient: vivid.gradient, borderRadius: radius),
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          children: [
            // A quotation mark, large and faint, behind the words: this is
            // somebody's case, put in their words.
            PositionedDirectional(
              end: 14,
              top: 8,
              child: ExcludeSemantics(
                child: Text(
                  '“',
                  textScaler: TextScaler.noScaling,
                  style: AppText.display(
                    size: 76,
                    weight: FontWeight.w800,
                    height: 0.82,
                    color: vivid.ink.withValues(alpha: 0.13),
                  ),
                ),
              ),
            ),
            Padding(
              padding: padding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Semantics(
                    header: true,
                    child: Padding(
                      // Clear of the quotation mark in the corner.
                      padding: const EdgeInsetsDirectional.only(end: 46),
                      child: Text(
                        label,
                        style: AppText.display(
                          size: 19,
                          weight: FontWeight.w700,
                          height: 1.16,
                          spacing: -0.3,
                          color: vivid.ink,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    text,
                    style: AppText.body(
                      size: 16,
                      height: 1.47,
                      weight: FontWeight.w500,
                      color: vivid.ink,
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

/// The VS between the two views: a dark disc set into the seam, tipped a
/// little, landing with a small bounce.
class _Medal extends StatelessWidget {
  const _Medal({required this.progress, required this.ring});

  final Animation<double> progress;

  /// The ground round the disc, so it reads as cut into the seam.
  final Color ring;

  static const double size = 54;

  @override
  Widget build(BuildContext context) {
    final Widget disc = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: kDeeperLine,
        shape: BoxShape.circle,
        border: Border.all(color: ring, width: 4),
      ),
      // A fine rim inside the ring, as on a struck coin.
      child: Container(
        margin: const EdgeInsets.all(3),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.18),
            width: 1.2,
          ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              context.l10n.deeperVersus,
              maxLines: 1,
              textScaler: TextScaler.noScaling,
              style: AppText.display(
                size: 17,
                weight: FontWeight.w800,
                height: 1,
                spacing: -0.4,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
    return ExcludeSemantics(
      child: AnimatedBuilder(
        animation: progress,
        child: disc,
        builder: (context, child) {
          final double v = ((progress.value - 0.3) / 0.5).clamp(0.0, 1.0);
          final double grow = Curves.elasticOut.transform(v);
          return Opacity(
            opacity: v == 0 ? 0 : 1,
            child: Transform.rotate(
              angle: -0.14 - 0.5 * (1 - Curves.easeOutCubic.transform(v)),
              child: Transform.scale(scale: grow, child: child),
            ),
          );
        },
      ),
    );
  }
}

/// What Astute+ shows, frosted over on the free plan with the way through
/// on top of it. A tap anywhere on it opens the paywall.
class DeeperGlass extends StatelessWidget {
  const DeeperGlass({
    super.key,
    required this.locked,
    required this.onUnlock,
    required this.child,
  });

  final bool locked;
  final VoidCallback onUnlock;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!locked) return child;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.lightImpact();
        onUnlock();
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          ExcludeSemantics(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
                child: child,
              ),
            ),
          ),
          const DeeperPlusChip(),
        ],
      ),
    );
  }
}

/// The three colours Astute+ is drawn in on the paywall, bright at night
/// and deepened on paper (paywall_screen.dart).
List<Color> plusHues(bool dark) => dark
    ? const [Color(0xFFFFE14D), Color(0xFF2DE0D2), Color(0xFF8B6CFF)]
    : const [Color(0xFFD9A300), Color(0xFF00A99C), Color(0xFF6E3AFF)];

/// "With Astute+", on a dark pill ringed in Astute+'s three colours.
class DeeperPlusChip extends StatelessWidget {
  const DeeperPlusChip({super.key});

  @override
  Widget build(BuildContext context) {
    final Palette p = context.p;
    return Semantics(
      button: true,
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(99),
          gradient: LinearGradient(colors: plusHues(true)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
          decoration: BoxDecoration(
            color: p.isDark ? const Color(0xFF0B0B0D) : p.inverse,
            borderRadius: BorderRadius.circular(99),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_rounded, size: 15, color: Colors.white),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  context.l10n.deeperPlusOnly,
                  style: AppText.body(
                    size: 13.5,
                    weight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A small mark beside a part's name on the free plan: this one is
/// Astute+'s.
class DeeperPlusBadge extends StatelessWidget {
  const DeeperPlusBadge({super.key});

  @override
  Widget build(BuildContext context) => deeperEditorial
      ? const EdPlusBadge()
      : Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(99),
            gradient: LinearGradient(colors: plusHues(true)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_rounded, size: 10, color: kInkDark),
              const SizedBox(width: 4),
              Text(
                'ASTUTE+',
                style: AppText.label(
                  size: 9.5,
                  weight: FontWeight.w800,
                  spacing: 1,
                  color: kInkDark,
                ),
              ),
            ],
          ),
        );
}

/// The foot of the sheet: where the card's facts come from, and the way
/// to the original.
class DeeperSource extends StatelessWidget {
  const DeeperSource({
    super.key,
    required this.look,
    required this.source,
    required this.kind,
    required this.draw,
    required this.open,
    this.watchBy,
    this.watch,
  });

  final DeeperLook look;
  final String source;

  /// What kind of thing the source is, in words, when the card says.
  final String? kind;
  final Animation<double> draw;

  /// Opens the original; null where there is no link to it.
  final VoidCallback? open;

  /// Who made the video the card's story is told in at more length, and
  /// where; with [watch], which opens it, offered as Watch more under the
  /// source. Both null where the card has none.
  final String? watchBy;
  final VoidCallback? watch;

  @override
  Widget build(BuildContext context) {
    if (deeperEditorial) {
      return EdSource(
        look: look,
        source: source,
        kind: kind,
        open: open,
        watchBy: watchBy,
        watch: watch,
      );
    }
    final l = context.l10n;
    final Palette p = context.p;
    final DeeperTone tone = look.tone(DeeperPart.source);
    final String eyebrow = [
      l.deeperSource,
      if (kind case final String k) k,
    ].join('  ·  ').toUpperCase();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Ornament(colour: tone.accent),
        const SizedBox(height: 22),
        Row(
          children: [
            DeeperMedallion(
              art: DeeperArt.book,
              vivid: tone.vivid,
              accent: look.sideB.fill,
              second: look.sideA.fill,
              progress: draw,
              size: 46,
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Text(
                eyebrow,
                style: AppText.label(
                  size: 11.5,
                  weight: FontWeight.w800,
                  spacing: 1.7,
                  color: tone.title,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          source,
          style: AppText.display(
            size: 18,
            weight: FontWeight.w500,
            height: 1.38,
            spacing: -0.2,
            color: p.ink,
          ),
        ),
        if (open case final VoidCallback go) ...[
          const SizedBox(height: 18),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: _Original(look: look, onTap: go),
          ),
        ],
        if (watch case final VoidCallback see) ...[
          SizedBox(height: open == null ? 14 : 8),
          DeeperWatch(by: watchBy, onTap: see, ink: p.ink, muted: p.inkMuted),
        ],
      ],
    );
  }
}

/// A hairline with a small diamond on it, in the subject's colour.
class _Ornament extends StatelessWidget {
  const _Ornament({required this.colour});

  final Color colour;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox(
      height: 12,
      child: CustomPaint(painter: _OrnamentPainter(colour)),
    ),
  );
}

class _OrnamentPainter extends CustomPainter {
  _OrnamentPainter(this.colour);

  final Color colour;

  @override
  void paint(Canvas canvas, Size size) {
    final double y = size.height / 2;
    final double mid = size.width / 2;
    final Paint line = Paint()
      ..strokeWidth = 1
      ..shader = LinearGradient(
        colors: [
          colour.withValues(alpha: 0),
          colour.withValues(alpha: 0.55),
          colour.withValues(alpha: 0),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawLine(Offset(0, y), Offset(mid - 12, y), line);
    canvas.drawLine(Offset(mid + 12, y), Offset(size.width, y), line);
    canvas.drawPath(
      Path()
        ..moveTo(mid, y - 5)
        ..lineTo(mid + 5, y)
        ..lineTo(mid, y + 5)
        ..lineTo(mid - 5, y)
        ..close(),
      Paint()..color = colour,
    );
  }

  @override
  bool shouldRepaint(_OrnamentPainter old) => old.colour != colour;
}

/// Open the original: the card's own colour, the way out of the app.
class _Original extends StatefulWidget {
  const _Original({required this.look, required this.onTap});

  final DeeperLook look;
  final VoidCallback onTap;

  @override
  State<_Original> createState() => _OriginalState();
}

class _OriginalState extends State<_Original> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final Palette p = context.p;
    final DeeperLook look = widget.look;
    // Thinking's paper would vanish on the page: its ink instead.
    final Color fill = look.pearl ? p.inverse : look.world;
    final Color ink = look.pearl ? p.onInverse : look.worldInk;
    return Semantics(
      button: true,
      link: true,
      child: GestureDetector(
        key: const ValueKey('deeper-open-source'),
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _down = true),
        onTapUp: (_) => setState(() => _down = false),
        onTapCancel: () => setState(() => _down = false),
        onTap: () {
          HapticFeedback.selectionClick();
          widget.onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 70),
          padding: EdgeInsets.only(top: _down ? 4 : 0, bottom: _down ? 0 : 4),
          decoration: BoxDecoration(
            color: chunkyEdge(fill, 0.14),
            borderRadius: BorderRadius.circular(99),
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 16, 12),
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(99),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    context.l10n.deeperOpenSource,
                    style: AppText.body(
                      size: 15.5,
                      weight: FontWeight.w700,
                      color: ink,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.arrow_outward_rounded, size: 19, color: ink),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The line at the very foot: the answers are an AI's, and can be wrong.
class DeeperAiNote extends StatelessWidget {
  const DeeperAiNote({super.key});

  @override
  Widget build(BuildContext context) {
    final Palette p = context.p;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(Icons.auto_awesome_rounded, size: 14, color: p.inkFaint),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            context.l10n.deeperAiNote,
            style: AppText.body(size: 12.5, height: 1.4, color: p.inkFaint),
          ),
        ),
      ],
    );
  }
}
