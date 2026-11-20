import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../analytics.dart';
import '../data/skills.dart';
import '../data/topics.dart' show inkOn;
import '../l10n/l10n.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/chunky.dart';
import '../widgets/ui.dart' show BackCircle, ScreenView;

/// What the reader wants to learn, picked from the profile: twelve skills
/// in two columns, each a tile with its mark that fills with its colour,
/// raised on its own edge, when picked. All twelve are on the screen at
/// once, the rows sharing the height the phone has; only a text too large
/// for that lets the grid scroll. Nothing in the app changes with them; they
/// are kept, and told to the reader's profile in analytics, for the people
/// who write the cards to know what to write next. The screen says so.
class SkillsScreen extends StatefulWidget {
  const SkillsScreen({super.key, required this.app});

  final AppState app;

  @override
  State<SkillsScreen> createState() => _SkillsScreenState();
}

class _SkillsScreenState extends State<SkillsScreen> {
  /// What was picked when the screen opened, to say on the way out what
  /// changed. Read here, not lazily: read on the way out, it would already
  /// be what was changed to.
  late final List<String> _before;

  @override
  void initState() {
    super.initState();
    _before = List.of(widget.app.skills);
  }

  @override
  void dispose() {
    // Said once, on the way out, and only when something changed.
    final List<String> now = widget.app.skills;
    if (now.join(',') != _before.join(',')) {
      Analytics.capture('skills saved', {
        'skills': now.join(','),
        'count': now.length,
        'added': now.where((k) => !_before.contains(k)).length,
        'removed': _before.where((k) => !now.contains(k)).length,
      });
    }
    super.dispose();
  }

  void _toggle(Skill s) {
    HapticFeedback.selectionClick();
    final List<String> next = List.of(widget.app.skills);
    if (!next.remove(s.name)) next.add(s.name);
    widget.app.setSkills(next);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final p = context.p;
    final double foot = MediaQuery.paddingOf(context).bottom;
    final Set<String> picked = widget.app.skills.toSet();
    const List<Skill> all = Skill.values;
    return ScreenView(
      name: 'skills',
      child: Scaffold(
        backgroundColor: p.surface,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // The way back stays put above what scrolls: on iOS 26 it is
              // Apple's own glass button, a native view, and one inside a
              // scrolling list is drawn away from its place.
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
                child: Row(
                  children: [
                    BackCircle(
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: _Headline(
                          text: l.skillsTitle,
                          mark: l.skillsTitleMark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    l.skillsLine,
                    style: AppText.body(
                      size: 15,
                      height: 1.38,
                      color: p.ink.withValues(alpha: 0.62),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                  child: LayoutBuilder(
                    builder: (context, box) => _grid(context, box, all, picked),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(20, 8, 20, foot > 0 ? foot : 16),
                child: ChunkyButton(
                  key: const ValueKey('skills-done'),
                  label: l.skillsDone,
                  fill: p.inverse,
                  ink: p.onInverse,
                  height: 58,
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// The twelve in two columns. Each row takes its share of the height
  /// there is, no taller than a tile wants; where even the least a tile
  /// needs, its name on two lines at the reader's text size, does not fit
  /// six times, the rows keep that least and the grid scrolls.
  Widget _grid(
    BuildContext context,
    BoxConstraints box,
    List<Skill> all,
    Set<String> picked,
  ) {
    const double gap = 10;
    final int rows = (all.length / 2).ceil();
    final TextScaler scaler = MediaQuery.textScalerOf(context);
    final double least =
        math.max(2 * scaler.scale(14.5) * 1.22, 26) +
        2 * _Tile.padY +
        kTileDepth;
    final double share = (box.maxHeight - gap * (rows - 1)) / rows;
    final bool fits = share >= least;
    final double height = fits ? math.min(share, 136) : least;
    Widget row(int i) => SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final int k in [i, i + 1]) ...[
            if (k == i + 1) const SizedBox(width: gap),
            Expanded(
              child: k < all.length
                  ? _Tile(
                      skill: all[k],
                      on: picked.contains(all[k].name),
                      onTap: () => _toggle(all[k]),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ],
      ),
    );
    final Widget grid = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < all.length; i += 2) ...[
          if (i > 0) const SizedBox(height: gap),
          row(i),
        ],
      ],
    );
    if (fits) return Align(alignment: Alignment.topCenter, child: grid);
    return SingleChildScrollView(child: grid);
  }
}

/// The headline, its one word painted in the lights, as the paywall paints
/// its own.
class _Headline extends StatelessWidget {
  const _Headline({required this.text, required this.mark});

  final String text;
  final String mark;

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final TextStyle style = AppText.display(
      size: 32,
      weight: FontWeight.w600,
      height: 1.1,
      color: p.ink,
    );
    final List<Color> lights = p.isDark
        ? const [Color(0xFFFFE14D), Color(0xFF2DE0D2), Color(0xFF8B6CFF)]
        : const [Color(0xFFD9A300), Color(0xFF00A99C), Color(0xFF6E3AFF)];
    final int at = text.indexOf(mark);
    if (mark.isEmpty || at < 0) return Text(text, style: style);
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: text.substring(0, at)),
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (r) => ui.Gradient.linear(
                r.topLeft,
                r.topRight,
                lights,
                const [0, 0.55, 1],
              ),
              child: Text(mark, style: style),
            ),
          ),
          TextSpan(text: text.substring(at + mark.length)),
        ],
      ),
      key: const ValueKey('skills-headline'),
      style: style,
    );
  }
}

/// How far a picked tile stands on its edge.
const double kTileDepth = 4;

/// A skill: its mark and its name, on the page's quiet ground, or filled
/// with its colour and raised on its edge, a tick in the corner, once
/// picked. Tall enough, the mark sits above the name; in a short row, beside
/// it.
class _Tile extends StatefulWidget {
  const _Tile({required this.skill, required this.on, required this.onTap});

  final Skill skill;
  final bool on;
  final VoidCallback onTap;

  /// The room above and below what a tile shows.
  static const double padY = 10;

  @override
  State<_Tile> createState() => _TileState();
}

class _TileState extends State<_Tile> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final Skill skill = widget.skill;
    final bool on = widget.on;
    // Not picked, the page's quiet ground with a wash of the skill's own
    // colour, so the grid reads as twelve different things before any is
    // chosen; picked, the colour itself.
    final Color face = on
        ? skill.colour
        : Color.alphaBlend(
            skill.colour.withValues(alpha: p.isDark ? 0.12 : 0.09),
            p.ink.withValues(alpha: p.isDark ? 0.04 : 0.03),
          );
    final Color ink = on ? inkOn(skill.colour) : p.ink;
    final Color mark = on ? ink : skill.mark(p.isDark);
    final String name = context.l10n.skillName(skill.name);
    final bool raised = on && !_down;
    return Semantics(
      key: ValueKey('skill-${skill.name}-${on ? 'on' : 'off'}'),
      button: true,
      toggled: on,
      label: name,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _down = true),
        onTapUp: (_) => setState(() => _down = false),
        onTapCancel: () => setState(() => _down = false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 90),
          curve: Curves.easeOut,
          // The edge under a picked tile; under one not picked, nothing, so
          // the faces line up row by row either way.
          decoration: BoxDecoration(
            color: on ? chunkyEdge(skill.colour) : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          padding: EdgeInsets.only(
            top: raised ? 0 : kTileDepth,
            bottom: raised ? kTileDepth : 0,
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              color: face,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: on
                    ? skill.colour
                    : skill.colour.withValues(alpha: p.isDark ? 0.3 : 0.34),
                width: 1.2,
              ),
            ),
            child: LayoutBuilder(
              // Tall where the mark, a gap and two lines of the name at the
              // reader's text size stand one above the other; beside it if not.
              builder: (context, box) =>
                  box.maxHeight >=
                      49 +
                          2 * MediaQuery.textScalerOf(context).scale(15.5) * 1.2
                  ? _tall(box, name, ink, mark)
                  : _row(box, name, ink, mark),
            ),
          ),
        ),
      ),
    );
  }

  /// The tick in the corner: a ring, filled once picked.
  Widget _tick(Color ink, double size) {
    final p = context.p;
    final bool on = widget.on;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: on ? ink : Colors.transparent,
        border: Border.all(
          color: on ? ink : p.ink.withValues(alpha: 0.24),
          width: 1.6,
        ),
      ),
      child: AnimatedScale(
        scale: on ? 1 : 0,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutBack,
        child: Icon(
          Icons.check_rounded,
          size: size * 0.7,
          color: widget.skill.colour,
        ),
      ),
    );
  }

  /// The name, on up to three lines in [width], never broken inside a
  /// word: where its longest word is wider than that, or the lines taller
  /// than [height], the whole name is set smaller instead.
  Widget _name(
    String name,
    Color ink,
    double size,
    double width,
    Alignment at,
  ) {
    // Measured as it is drawn: with what the page's own text style lends it.
    final TextStyle style = DefaultTextStyle.of(context).style.merge(
      AppText.body(
        size: size,
        weight: FontWeight.w700,
        height: 1.2,
        color: ink,
      ),
    );
    final TextScaler scaler = MediaQuery.textScalerOf(context);
    double widest = 0;
    for (final String word in name.split(RegExp(r'\s+'))) {
      final TextPainter t = TextPainter(
        text: TextSpan(text: word, style: style),
        textDirection: Directionality.of(context),
        textScaler: scaler,
        maxLines: 1,
      )..layout();
      widest = math.max(widest, t.width);
      t.dispose();
    }
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: at,
      child: SizedBox(
        width: math.max(width, widest + 1),
        child: Text(name, maxLines: 3, style: style),
      ),
    );
  }

  /// Tall: the mark and the tick above, the name at the foot.
  Widget _tall(BoxConstraints box, String name, Color ink, Color mark) {
    final double glyph = (box.maxHeight * 0.26).clamp(22.0, 34.0);
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 11, 11, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomPaint(
                size: Size.square(glyph),
                painter: SkillGlyph(widget.skill, mark),
              ),
              const Spacer(),
              _tick(ink, 22),
            ],
          ),
          const Spacer(),
          // Smaller rather than cut, where a long name meets a large text.
          Flexible(
            flex: 0,
            child: _name(
              name,
              ink,
              15.5,
              box.maxWidth - 26,
              Alignment.bottomLeft,
            ),
          ),
        ],
      ),
    );
  }

  /// Short: the mark, the name beside it taking the rest of the row; the
  /// tick, once picked, a small badge on the mark's corner, so the name
  /// keeps the room.
  Widget _row(BoxConstraints box, String name, Color ink, Color mark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, _Tile.padY, 10, _Tile.padY),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            height: 30,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: 0,
                  top: 3,
                  child: CustomPaint(
                    size: const Size.square(24),
                    painter: SkillGlyph(widget.skill, mark),
                  ),
                ),
                Positioned(right: -2, bottom: -2, child: _badge(ink)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: LayoutBuilder(
              builder: (context, room) =>
                  _name(name, ink, 14.5, room.maxWidth, Alignment.centerLeft),
            ),
          ),
        ],
      ),
    );
  }

  /// The tick of a short tile: a badge that grows in once picked, nothing
  /// before.
  Widget _badge(Color ink) => AnimatedScale(
    scale: widget.on ? 1 : 0,
    duration: const Duration(milliseconds: 220),
    curve: Curves.easeOutBack,
    child: Container(
      width: 15,
      height: 15,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: ink,
        border: Border.all(color: widget.skill.colour, width: 1.5),
      ),
      child: Icon(Icons.check_rounded, size: 11, color: widget.skill.colour),
    ),
  );
}
