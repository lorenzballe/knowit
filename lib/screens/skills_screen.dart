import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../analytics.dart';
import '../data/skills.dart';
import '../l10n/l10n.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/chunky.dart';
import '../widgets/ui.dart' show BackCircle, ScreenView;

/// What the reader wants to learn, picked from the profile: twelve skills
/// in two columns, each a card of the page's ground with a badge of two
/// hues, lit up and ringed when picked: never tiles of one colour, which are
/// the subjects' look. All twelve are on the screen at
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
        math.max(2 * scaler.scale(14.5) * 1.22, 36) + 2 * _Tile.padY + 4;
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

/// A skill: a badge of its two hues carrying its mark, and its name, on a
/// card of the page's own ground, never a tile of one colour as a subject's
/// is. Picked, the badge lights up in full, a ring of the same two hues runs
/// round the card with their glow under it, and a tick fills in. Tall
/// enough, the badge sits above the name; in a short row, beside it, the
/// tick then on the badge's corner so the name keeps the room.
class _Tile extends StatefulWidget {
  const _Tile({required this.skill, required this.on, required this.onTap});

  final Skill skill;
  final bool on;
  final VoidCallback onTap;

  /// The room above and below what a short tile shows.
  static const double padY = 9;

  @override
  State<_Tile> createState() => _TileState();
}

class _TileState extends State<_Tile> {
  bool _down = false;

  LinearGradient get _hues => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: widget.skill.hues,
  );

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final Skill skill = widget.skill;
    final bool on = widget.on;
    final String name = context.l10n.skillName(skill.name);
    // The card itself: the page's raised ground, a hairline round it; picked,
    // a ring of the skill's two hues instead, and their glow under it.
    final Color ground = p.isDark
        ? Color.alphaBlend(Colors.white.withValues(alpha: 0.055), p.surface)
        : Colors.white;
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
        child: AnimatedScale(
          scale: _down ? 0.97 : 1,
          duration: const Duration(milliseconds: 110),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            padding: EdgeInsets.all(on ? 2 : 1),
            decoration: BoxDecoration(
              gradient: on ? _hues : null,
              color: on ? null : p.line,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: skill.hues.last.withValues(
                    alpha: on ? (p.isDark ? 0.34 : 0.26) : 0,
                  ),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Container(
              decoration: BoxDecoration(
                color: ground,
                borderRadius: BorderRadius.circular(on ? 20 : 21),
              ),
              child: LayoutBuilder(
                // Tall where the badge, a gap and two lines of the name at the
                // reader's text size stand one above the other; beside it if not.
                builder: (context, box) =>
                    box.maxHeight >=
                        54 +
                            2 * MediaQuery.textScalerOf(context).scale(15) * 1.2
                    ? _tall(box, name)
                    : _row(box, name),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// The badge: the skill's two hues and its mark, lit in full once picked;
  /// before, a soft wash of them with the mark in the first.
  Widget _badge(double size) {
    final p = context.p;
    final Skill skill = widget.skill;
    final bool on = widget.on;
    final Color soft = p.isDark ? p.surface : Colors.white;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.3),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: on
              ? skill.hues
              : [
                  for (final Color c in skill.hues)
                    Color.alphaBlend(
                      c.withValues(alpha: p.isDark ? 0.24 : 0.16),
                      soft,
                    ),
                ],
        ),
      ),
      alignment: Alignment.center,
      child: CustomPaint(
        size: Size.square(size * 0.62),
        painter: SkillGlyph(
          skill,
          on ? skill.onHues : (p.isDark ? skill.hues.first : skill.onPaper),
        ),
      ),
    );
  }

  /// The tick: a ring, filled with the skill's hues once picked.
  Widget _tick(double size) {
    final p = context.p;
    final bool on = widget.on;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: on ? _hues : null,
        border: on
            ? null
            : Border.all(color: p.ink.withValues(alpha: 0.22), width: 1.6),
      ),
      child: AnimatedScale(
        scale: on ? 1 : 0,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutBack,
        child: Icon(
          Icons.check_rounded,
          size: size * 0.68,
          color: widget.skill.onHues,
        ),
      ),
    );
  }

  /// The name, on up to three lines in [width], never broken inside a
  /// word: where its longest word is wider than that, the whole name is set
  /// smaller instead.
  Widget _name(String name, double size, double width, Alignment at) {
    final p = context.p;
    // Measured as it is drawn: with what the page's own text style lends it.
    final TextStyle style = DefaultTextStyle.of(context).style.merge(
      AppText.body(
        size: size,
        weight: FontWeight.w700,
        height: 1.2,
        color: p.ink,
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

  /// Tall: the badge and the tick above, the name at the foot.
  Widget _tall(BoxConstraints box, String name) {
    final double badge = (box.maxHeight * 0.34).clamp(30.0, 42.0);
    return Padding(
      padding: const EdgeInsets.fromLTRB(13, 12, 12, 11),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [_badge(badge), const Spacer(), _tick(22)],
          ),
          const Spacer(),
          Flexible(
            flex: 0,
            child: _name(name, 15, box.maxWidth - 25, Alignment.bottomLeft),
          ),
        ],
      ),
    );
  }

  /// Short: the badge, the name beside it taking the rest of the row; the
  /// tick, once picked, on the badge's corner.
  Widget _row(BoxConstraints box, String name) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, _Tile.padY, 10, _Tile.padY),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            height: 36,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(left: 0, top: 2, child: _badge(32)),
                Positioned(
                  right: -3,
                  bottom: -3,
                  child: AnimatedScale(
                    scale: widget.on ? 1 : 0,
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeOutBack,
                    child: Container(
                      padding: const EdgeInsets.all(1.5),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: context.p.isDark
                            ? Color.alphaBlend(
                                Colors.white.withValues(alpha: 0.055),
                                context.p.surface,
                              )
                            : Colors.white,
                      ),
                      child: _tick(15),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: LayoutBuilder(
              builder: (context, room) =>
                  _name(name, 14.5, room.maxWidth, Alignment.centerLeft),
            ),
          ),
        ],
      ),
    );
  }
}
