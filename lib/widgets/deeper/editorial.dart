/// Go deeper's parts set as a serious reading app sets them, under the
/// card's coloured head (header.dart), which stays as it is.
///
/// Three ways, for the owner to choose between ([deeperStyle]):
///
///   column    one clean column: a hairline over each part, its name in
///             small capitals, the words in Figtree; the two views one under
///             the other, each under a small label.
///   panels    each part on a quiet panel lit faintly from its top corner
///             with the head's own lights, as if the head's gradient went on
///             down the page; the two views on two faintly different grounds.
///   magazine  a magazine page: the idea said simply as a large lead in
///             Fraunces under a short rule, the two views as a debate in two
///             columns either side of a hairline, the rest in small capitals
///             and Figtree.
///
/// No drawings: a part is known by its name. Colour is only an echo of the
/// head, in the names and the few marks.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;

import '../../l10n/l10n.dart';
import '../../theme.dart';
import 'app_style.dart';
import 'look.dart';
import 'pieces.dart' show deeperStill;

/// How Go deeper's parts are set.
enum DeeperStyle {
  /// Each part its own colour and drawing (pieces.dart, art.dart).
  playful,

  /// The app's own language: its black (or paper) ground, its raised
  /// rounded cards, its pill buttons and chips (app_style.dart).
  app,
  column,
  panels,
  magazine,
}

/// The way the parts are set: a prototype switch, moved by the screenshot
/// tool (tool/deeper_shots.dart, DEEPER_STYLE) and by nothing in the app.
DeeperStyle deeperStyle = DeeperStyle.app;

/// Whether the parts are set in one of the editorial ways.
bool get deeperEditorial => deeperStyle != DeeperStyle.playful;

/// The room between one part and the next.
double get deeperGap => switch (deeperStyle) {
  DeeperStyle.playful => 14,
  DeeperStyle.app => 14,
  DeeperStyle.column => 34,
  DeeperStyle.panels => 12,
  DeeperStyle.magazine => 42,
};

/// The few colours the editorial parts use: the page's inks, hairlines, and
/// one quiet accent in the subject's hue.
class EdInk {
  EdInk._({
    required this.ink,
    required this.text,
    required this.muted,
    required this.rule,
    required this.ruleStrong,
    required this.accent,
    required this.panel,
    required this.panelLit,
    required this.panelEdge,
    required this.sideA,
    required this.sideB,
  });

  factory EdInk.of(BuildContext context, DeeperLook look) {
    final Palette p = context.p;
    final bool dark = p.isDark;
    final double h = look.hue;
    final double c = look.pearl ? 0.02 : 0.085;
    Color tint(double l, double chroma, double hue) =>
        Oklch(l, chroma, hue % 360).toColour();
    final Color panel = dark
        ? tint(0.205, c * 0.22, h)
        : Color.alphaBlend(
            tint(0.97, c * 0.12, h).withValues(alpha: 0.7),
            Colors.white,
          );
    return EdInk._(
      ink: p.ink,
      text: p.ink.withValues(alpha: dark ? 0.86 : 0.84),
      muted: p.inkMuted,
      rule: dark ? const Color(0x24FFFFFF) : const Color(0x1C000000),
      ruleStrong: dark ? const Color(0x52FFFFFF) : const Color(0x45000000),
      accent: look.pearl
          ? p.inkMuted
          : dark
          ? tint(0.80, c, h)
          : tint(0.48, c * 1.15, h),
      panel: panel,
      panelLit: Color.alphaBlend(
        look.glow[1].withValues(alpha: dark ? 0.16 : 0.22),
        panel,
      ),
      panelEdge: dark ? const Color(0x14FFFFFF) : const Color(0x12000000),
      sideA: dark
          ? Color.alphaBlend(
              tint(0.5, c * 0.6, look.sideA.hue).withValues(alpha: 0.16),
              panel,
            )
          : Color.alphaBlend(
              tint(0.9, c * 0.5, look.sideA.hue).withValues(alpha: 0.4),
              panel,
            ),
      sideB: dark
          ? Color.alphaBlend(
              tint(0.5, c * 0.6, look.sideB.hue).withValues(alpha: 0.16),
              panel,
            )
          : Color.alphaBlend(
              tint(0.9, c * 0.5, look.sideB.hue).withValues(alpha: 0.4),
              panel,
            ),
    );
  }

  final Color ink;

  /// Running text: the ink a step back, as print is grey beside its heads.
  final Color text;
  final Color muted;
  final Color rule;
  final Color ruleStrong;
  final Color accent;

  /// The panels' ground, and the light in their top corner.
  final Color panel;
  final Color panelLit;
  final Color panelEdge;

  /// The two views' grounds, in the panels.
  final Color sideA;
  final Color sideB;
}

/// A name in small capitals.
TextStyle edLabel(Color colour, {double size = 11.5}) => AppText.label(
  size: size,
  weight: FontWeight.w700,
  spacing: 1.9,
  height: 1.3,
  color: colour,
);

/// The words of a part.
TextStyle edBody(BuildContext context) => deeperStyle == DeeperStyle.app
    ? appBody(context)
    : AppText.body(
        size: 16.5,
        height: 1.6,
        color: context.p.ink.withValues(alpha: context.p.isDark ? 0.88 : 0.86),
      );

/// The idea said simply, the lead of the page.
TextStyle edSimply(BuildContext context) => switch (deeperStyle) {
  DeeperStyle.app => appSimply(context),
  DeeperStyle.magazine => AppText.display(
    size: 23.5,
    weight: FontWeight.w400,
    height: 1.36,
    spacing: -0.3,
    color: context.p.ink,
  ),
  DeeperStyle.panels => AppText.body(
    size: 18.5,
    weight: FontWeight.w500,
    height: 1.55,
    spacing: -0.1,
    color: context.p.ink,
  ),
  _ => AppText.body(
    size: 19,
    weight: FontWeight.w400,
    height: 1.56,
    spacing: -0.15,
    color: context.p.ink,
  ),
};

/// Marks the first part of the sheet, which in the column needs no rule
/// over it: the head's end is its rule.
class EdFirst extends InheritedWidget {
  const EdFirst({super.key, required this.first, required super.child});

  final bool first;

  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<EdFirst>()?.first ?? false;

  @override
  bool updateShouldNotify(EdFirst old) => old.first != first;
}

/// A full-width hairline.
class EdRule extends StatelessWidget {
  const EdRule({super.key, required this.colour, this.thickness = 1});

  final Color colour;
  final double thickness;

  @override
  Widget build(BuildContext context) =>
      Container(height: thickness, color: colour);
}

/// A part, set editorially: its name in small capitals, the line on what
/// it gives when it gives it only when asked, then what it says.
class EdSection extends StatelessWidget {
  const EdSection({
    super.key,
    required this.look,
    required this.title,
    required this.child,
    this.lead,
    this.badge,
  });

  final DeeperLook look;
  final String title;
  final String? lead;
  final Widget? badge;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (deeperStyle == DeeperStyle.app) {
      return AppSection(
        look: look,
        title: title,
        lead: lead,
        badge: badge,
        child: child,
      );
    }
    final EdInk ed = EdInk.of(context, look);
    final Widget name = Semantics(
      header: true,
      child: Text(
        title.toUpperCase(),
        style: deeperStyle == DeeperStyle.magazine
            ? edLabel(ed.ink, size: 11).copyWith(letterSpacing: 2.1)
            : edLabel(ed.accent),
      ),
    );
    final List<Widget> under = [
      if (lead case final String said) ...[
        const SizedBox(height: 7),
        Text(
          said,
          style: AppText.body(size: 14.5, height: 1.48, color: ed.muted),
        ),
      ],
      SizedBox(height: deeperStyle == DeeperStyle.magazine ? 18 : 16),
      child,
    ];
    Widget withBadge(Widget head) => badge == null
        ? head
        : Row(
            children: [
              Flexible(child: head),
              const SizedBox(width: 10),
              badge!,
            ],
          );
    switch (deeperStyle) {
      case DeeperStyle.panels:
        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: ed.panelEdge),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: const Alignment(0.6, 1),
              colors: [ed.panelLit, ed.panel],
              stops: const [0, 0.55],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LayoutBuilder(
                  builder: (context, box) => Row(
                    children: [
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: box.maxWidth * (badge == null ? 0.8 : 0.6),
                        ),
                        child: name,
                      ),
                      const SizedBox(width: 14),
                      Expanded(child: EdRule(colour: ed.rule)),
                      if (badge case final Widget b) ...[
                        const SizedBox(width: 10),
                        b,
                      ],
                    ],
                  ),
                ),
                ...under,
              ],
            ),
          ),
        );
      case DeeperStyle.magazine:
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 2,
                child: Stack(
                  children: [
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 0.5,
                      child: EdRule(colour: ed.rule),
                    ),
                    PositionedDirectional(
                      start: 0,
                      top: 0,
                      child: Container(width: 24, height: 2, color: ed.accent),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              withBadge(name),
              ...under,
            ],
          ),
        );
      case DeeperStyle.column:
      case DeeperStyle.playful:
      case DeeperStyle.app:
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!EdFirst.of(context)) ...[
                EdRule(colour: ed.rule),
                const SizedBox(height: 18),
              ] else
                const SizedBox(height: 6),
              withBadge(name),
              ...under,
            ],
          ),
        );
    }
  }
}

/// One view: its small label, its name, its words.
class _EdView extends StatelessWidget {
  const _EdView({
    required this.side,
    required this.label,
    required this.text,
    required this.ed,
    this.compact = false,
  });

  final String side;
  final String label;
  final String text;
  final EdInk ed;

  /// In a column of the debate: a size down.
  final bool compact;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (side != label) ...[
        ExcludeSemantics(
          child: Text(side.toUpperCase(), style: edLabel(ed.accent, size: 10)),
        ),
        const SizedBox(height: 8),
      ],
      Semantics(
        header: true,
        child: Text(
          label,
          style: deeperStyle == DeeperStyle.magazine
              ? AppText.display(
                  size: compact ? 17.5 : 19,
                  weight: FontWeight.w500,
                  height: 1.24,
                  spacing: -0.25,
                  color: ed.ink,
                )
              : AppText.body(
                  size: compact ? 15.5 : 17,
                  weight: FontWeight.w700,
                  height: 1.3,
                  spacing: -0.1,
                  color: ed.ink,
                ),
        ),
      ),
      SizedBox(height: compact ? 9 : 8),
      Text(
        text,
        style: AppText.body(
          size: compact ? 14.5 : 16,
          height: compact ? 1.56 : 1.6,
          color: ed.text,
        ),
      ),
    ],
  );
}

/// The two views, set editorially: one under the other with a hairline
/// between, on two faint grounds in the panels, or as a debate in two
/// columns on the magazine's page where there is room.
class EdVersus extends StatelessWidget {
  const EdVersus({
    super.key,
    required this.look,
    required this.a,
    required this.b,
  });

  final DeeperLook look;
  final (String, String) a;
  final (String, String)? b;

  @override
  Widget build(BuildContext context) {
    if (deeperStyle == DeeperStyle.app) {
      return AppVersus(look: look, a: a, b: b);
    }
    final l = context.l10n;
    final EdInk ed = EdInk.of(context, look);
    final (String, String)? other = b;
    final Widget first = _EdView(
      side: other == null ? l.deeperSideB : l.deeperSideA,
      label: a.$1,
      text: a.$2,
      ed: ed,
    );
    if (other == null) return first;
    final Widget second = _EdView(
      side: l.deeperSideB,
      label: other.$1,
      text: other.$2,
      ed: ed,
    );
    switch (deeperStyle) {
      case DeeperStyle.panels:
        Widget ground(Color c, Widget child) => DecoratedBox(
          decoration: BoxDecoration(
            color: c,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
            child: child,
          ),
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ground(ed.sideA, first),
            const SizedBox(height: 8),
            ground(ed.sideB, second),
          ],
        );
      case DeeperStyle.magazine:
        final double scale = MediaQuery.textScalerOf(context).scale(1);
        return LayoutBuilder(
          builder: (context, box) {
            if (box.maxWidth / scale < 300) {
              return _stacked(first, second, ed);
            }
            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _EdView(
                      side: l.deeperSideA,
                      label: a.$1,
                      text: a.$2,
                      ed: ed,
                      compact: true,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(width: 1, color: ed.rule),
                  ),
                  Expanded(
                    child: _EdView(
                      side: l.deeperSideB,
                      label: other.$1,
                      text: other.$2,
                      ed: ed,
                      compact: true,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      case DeeperStyle.column:
      case DeeperStyle.playful:
      case DeeperStyle.app:
        return _stacked(first, second, ed);
    }
  }

  Widget _stacked(Widget first, Widget second, EdInk ed) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      first,
      const SizedBox(height: 20),
      Align(
        alignment: AlignmentDirectional.centerStart,
        child: Container(width: 36, height: 1, color: ed.ruleStrong),
      ),
      const SizedBox(height: 20),
      second,
    ],
  );
}

/// The button that asks Claude, set as a page sets a link it means: a
/// hairline box with square corners, the words in Figtree and a fine arrow
/// in the subject's colour. While the answer comes it says so, and a short
/// stroke travels slowly along its foot; nothing bounces or shines.
class EdAskButton extends StatefulWidget {
  const EdAskButton({
    super.key,
    required this.look,
    required this.label,
    required this.onPressed,
    this.locked = false,
    this.busy = false,
  });

  final DeeperLook look;
  final String label;
  final VoidCallback? onPressed;
  final bool locked;
  final bool busy;

  @override
  State<EdAskButton> createState() => _EdAskButtonState();
}

class _EdAskButtonState extends State<EdAskButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    if (deeperStyle == DeeperStyle.app) {
      return AppAskButton(
        label: widget.label,
        onPressed: widget.onPressed,
        locked: widget.locked,
        busy: widget.busy,
      );
    }
    final Palette p = context.p;
    final EdInk ed = EdInk.of(context, widget.look);
    final bool on = widget.onPressed != null && !widget.busy;
    final bool busy = widget.busy;
    final Color ink = on
        ? ed.ink
        : busy
        ? ed.muted
        : p.inkFaint;
    final bool still = deeperStill(context);
    final Widget words = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.locked) ...[
          Icon(Icons.lock_outline_rounded, size: 14, color: ed.muted),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: AnimatedSwitcher(
            duration: still ? Duration.zero : const Duration(milliseconds: 260),
            child: Text(
              busy ? context.l10n.deeperBusy : widget.label,
              key: ValueKey(busy),
              style: AppText.body(
                size: 14.5,
                weight: FontWeight.w600,
                height: 1.3,
                spacing: 0.15,
                color: ink,
              ),
            ),
          ),
        ),
        AnimatedOpacity(
          duration: still ? Duration.zero : const Duration(milliseconds: 200),
          opacity: busy ? 0 : 1,
          child: Padding(
            padding: const EdgeInsetsDirectional.only(start: 14),
            child: ExcludeSemantics(
              child: Text(
                '→',
                style: AppText.body(
                  size: 15,
                  height: 1.3,
                  color: on ? ed.accent : ink,
                ),
              ),
            ),
          ),
        ),
      ],
    );
    final Widget face = AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      decoration: BoxDecoration(
        color: _down && on ? ed.ink.withValues(alpha: 0.06) : null,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: on ? ed.ruleStrong : ed.rule),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 16, 12),
            child: words,
          ),
          if (busy)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: EdLoadingLine(colour: ed.accent, height: 2),
            ),
        ],
      ),
    );
    return Semantics(
      button: true,
      enabled: on,
      liveRegion: busy,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: on ? (_) => setState(() => _down = true) : null,
        onTapUp: on ? (_) => setState(() => _down = false) : null,
        onTapCancel: on ? () => setState(() => _down = false) : null,
        onTap: on
            ? () {
                HapticFeedback.selectionClick();
                widget.onPressed!();
              }
            : null,
        child: face,
      ),
    );
  }
}

/// Something is on its way: a short stroke that crosses a hairline slowly,
/// at an even pace, again and again. Still, at its start, for a reader who
/// asked for less motion.
class EdLoadingLine extends StatefulWidget {
  const EdLoadingLine({super.key, required this.colour, this.height = 1});

  final Color colour;
  final double height;

  @override
  State<EdLoadingLine> createState() => _EdLoadingLineState();
}

class _EdLoadingLineState extends State<EdLoadingLine>
    with SingleTickerProviderStateMixin {
  late final AnimationController _run = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1900),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (deeperStill(context)) {
      _run.stop();
      _run.value = 0.3;
    } else if (!_run.isAnimating) {
      _run.repeat();
    }
  }

  @override
  void dispose() {
    _run.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox(
      height: widget.height,
      width: double.infinity,
      child: CustomPaint(painter: _Stroke(_run, widget.colour)),
    ),
  );
}

class _Stroke extends CustomPainter {
  _Stroke(this.run, this.colour) : super(repaint: run);

  final Animation<double> run;
  final Color colour;

  @override
  void paint(Canvas canvas, Size size) {
    final double part = size.width * 0.45;
    final double x = -part + (size.width + part) * run.value;
    final Rect r = Rect.fromLTWH(x, 0, part, size.height);
    canvas.drawRect(
      r,
      Paint()
        ..shader = LinearGradient(
          colors: [
            colour.withValues(alpha: 0),
            colour,
            colour.withValues(alpha: 0),
          ],
        ).createShader(r),
    );
  }

  @override
  bool shouldRepaint(_Stroke old) => old.colour != colour;
}

/// The source at the foot, set editorially: a hairline, its name, and the
/// way to the original as a line of text.
class EdSource extends StatelessWidget {
  const EdSource({
    super.key,
    required this.look,
    required this.source,
    required this.kind,
    required this.open,
  });

  final DeeperLook look;
  final String source;
  final String? kind;
  final VoidCallback? open;

  @override
  Widget build(BuildContext context) {
    if (deeperStyle == DeeperStyle.app) {
      return AppSource(look: look, source: source, kind: kind, open: open);
    }
    final l = context.l10n;
    final EdInk ed = EdInk.of(context, look);
    final String eyebrow = [
      l.deeperSource,
      if (kind case final String k) k,
    ].join('  ·  ').toUpperCase();
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: deeperStyle == DeeperStyle.panels ? 0 : 2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          EdRule(
            colour: deeperStyle == DeeperStyle.magazine
                ? ed.ruleStrong
                : ed.rule,
          ),
          const SizedBox(height: 18),
          Text(eyebrow, style: edLabel(ed.muted, size: 10.5)),
          const SizedBox(height: 10),
          Text(
            source,
            style: deeperStyle == DeeperStyle.magazine
                ? AppText.display(
                    size: 17,
                    weight: FontWeight.w400,
                    height: 1.4,
                    spacing: -0.15,
                    color: ed.ink,
                  )
                : AppText.body(
                    size: 15.5,
                    weight: FontWeight.w500,
                    height: 1.5,
                    color: ed.ink,
                  ),
          ),
          if (open case final VoidCallback go) ...[
            const SizedBox(height: 14),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Semantics(
                button: true,
                link: true,
                child: GestureDetector(
                  key: const ValueKey('deeper-open-source'),
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    go();
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Text(
                      '${l.deeperOpenSource}  ↗',
                      style: AppText.body(
                        size: 15,
                        weight: FontWeight.w600,
                        color: ed.accent,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The mark beside a part's name on the free plan, set quietly.
class EdPlusBadge extends StatelessWidget {
  const EdPlusBadge({super.key});

  @override
  Widget build(BuildContext context) {
    if (deeperStyle == DeeperStyle.app) return const AppPlusBadge();
    final Palette p = context.p;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: p.inkFaint),
      ),
      child: Text('ASTUTE+', style: edLabel(p.inkMuted, size: 9.5)),
    );
  }
}
