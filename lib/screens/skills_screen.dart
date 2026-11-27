import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../analytics.dart';
import '../data/skill_scores.dart';
import '../data/skills.dart';
import '../l10n/l10n.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/chunky.dart';
import '../widgets/skill_score.dart';
import '../widgets/top_edge.dart' show SoftTop;
import '../widgets/ui.dart' show BackCircle, ScreenView;

/// What the reader wants to learn, picked from the profile, and how far they
/// have come in each: twelve skills in two columns, each a card of the
/// page's ground with a badge of two hues and its score, a number with no top
/// that every answer on a card training it moves (lib/data/skill_scores.dart),
/// with how far it moved this week;
/// the picked ones ringed in their hues and marked in focus, never tiles of
/// one colour, which are the subjects' look. Picked, a skill's area leans the
/// cards picked for the reader, and a card that trains it carries its mark
/// (lib/widgets/skill_mark.dart). All twelve are on the screen at once, the
/// rows sharing the height the phone has; only a text too large for that lets
/// the grid scroll.
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

  /// The reader's scores: nothing is answered on this screen, so worked out
  /// once, as it opens.
  late final ScoreBook _book;

  @override
  void initState() {
    super.initState();
    _before = List.of(widget.app.skills);
    _book = scoreBookOf(widget.app);
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
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
                  child: LayoutBuilder(
                    builder: (context, box) => _grid(
                      context,
                      box,
                      all,
                      picked,
                      line: l.skillsLine,
                      lineStyle: AppText.body(
                        size: 15,
                        height: 1.38,
                        color: p.ink.withValues(alpha: 0.62),
                      ),
                    ),
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

  /// The line saying what the picks do, then the twelve in two columns.
  /// Each row takes its share of the height left, no taller than a tile
  /// wants; where even the least a tile needs, its name on two lines at the
  /// reader's text size, does not fit six times, the rows keep that least
  /// and the line and the grid scroll together.
  Widget _grid(
    BuildContext context,
    BoxConstraints box,
    List<Skill> all,
    Set<String> picked, {
    required String line,
    required TextStyle lineStyle,
  }) {
    const double gap = 10, under = 16;
    final int rows = (all.length / 2).ceil();
    final TextScaler scaler = MediaQuery.textScalerOf(context);
    final TextStyle style = DefaultTextStyle.of(context).style.merge(lineStyle);
    final TextPainter measure = TextPainter(
      text: TextSpan(text: line, style: style),
      textDirection: Directionality.of(context),
      textScaler: scaler,
      locale: Localizations.maybeLocaleOf(context),
    )..layout(maxWidth: box.maxWidth);
    final double lineHeight = measure.height;
    measure.dispose();
    final double least = _Tile.least(scaler);
    final double share =
        (box.maxHeight - lineHeight - under - gap * (rows - 1)) / rows;
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
                      score: _book.of(all[k]),
                      onTap: () => _toggle(all[k]),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ],
      ),
    );
    final Widget page = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(line, style: lineStyle),
        const SizedBox(height: under),
        for (int i = 0; i < all.length; i += 2) ...[
          if (i > 0) const SizedBox(height: gap),
          row(i),
        ],
      ],
    );
    if (fits) return Align(alignment: Alignment.topCenter, child: page);
    return SoftTop(child: SingleChildScrollView(child: page));
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

/// A skill: a badge of its two hues carrying its mark, its name, and its
/// score under them with how far it moved this week, on a card of the page's
/// own ground, never a tile of one colour as a subject's is. Picked, a ring of
/// the same two hues runs round the card with their glow under it, and a pill
/// of them on its top edge says the skill is in focus. Tall enough, the score
/// has a line of its own under the badge; in a short row it sits under the
/// name.
class _Tile extends StatefulWidget {
  const _Tile({
    required this.skill,
    required this.on,
    required this.score,
    required this.onTap,
  });

  final Skill skill;
  final bool on;
  final SkillScore score;
  final VoidCallback onTap;

  /// The room above and below what a short tile shows.
  static const double padY = 7;

  /// The least a short tile needs at the reader's text size: its name on two
  /// lines, then the score under it.
  static double least(TextScaler scaler) =>
      2 * padY +
      math.max(2 * scaler.scale(13.5) * 1.12, 28) +
      5 +
      math.max(scaler.scale(10.5) * 1.25, 5) +
      2;

  /// The height from which a tile stands tall: the badge and the name on two
  /// lines, and the score on a line of its own.
  static double tallFrom(TextScaler scaler) =>
      2 * 9 +
      math.max(2 * scaler.scale(14.5) * 1.12, 32) +
      7 +
      5 +
      5 +
      scaler.scale(11.5) * 1.25 +
      1;

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
    final l = context.l10n;
    final Skill skill = widget.skill;
    final bool on = widget.on;
    final String name = l.skillName(skill.name);
    final String level = scoreNumber(context, widget.score.now);
    final String cards = widget.score.answers == 0
        ? l.scoreStart
        : l.scoreWeek(signedNumber(context, widget.score.week));
    final TextScaler scaler = MediaQuery.textScalerOf(context);
    // The card itself: the page's raised ground, a hairline round it; picked,
    // a ring of the skill's two hues instead, and their glow under it.
    final Color ground = p.isDark
        ? Color.alphaBlend(Colors.white.withValues(alpha: 0.055), p.surface)
        : Colors.white;
    return Semantics(
      key: ValueKey('skill-${skill.name}-${on ? 'on' : 'off'}'),
      button: true,
      toggled: on,
      label: on
          ? '$name, ${l.skillsFocus}, $level, $cards'
          : '$name, $level, $cards',
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
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
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
                      builder: (context, box) =>
                          box.maxHeight >= _Tile.tallFrom(scaler)
                          ? _tall(name)
                          : _short(name),
                    ),
                  ),
                ),
              ),
              // In focus: a pill of the skill's hues on the card's top edge,
              // in the gap above it.
              Positioned(
                top: -8,
                right: 12,
                child: IgnorePointer(
                  child: AnimatedScale(
                    scale: on ? 1 : 0,
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeOutBack,
                    child: _focus(l.skillsFocus),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// The badge: the skill's two hues and its mark, the one a card that
  /// trains the skill carries in its head (skill_mark.dart).
  Widget _badge(double size) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(size * 0.3),
      gradient: _hues,
    ),
    alignment: Alignment.center,
    child: CustomPaint(
      size: Size.square(size * 0.62),
      painter: SkillGlyph(widget.skill, widget.skill.onHues),
    ),
  );

  /// "In focus", in small capitals on the skill's hues.
  Widget _focus(String text) => Container(
    key: ValueKey('skill-focus-${widget.skill.name}'),
    padding: const EdgeInsets.fromLTRB(8, 3, 8, 3),
    decoration: BoxDecoration(
      gradient: _hues,
      borderRadius: BorderRadius.circular(99),
      boxShadow: [
        BoxShadow(
          color: widget.skill.hues.last.withValues(alpha: 0.3),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Text(
      text,
      maxLines: 1,
      textScaler: MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.3),
      style: AppText.label(size: 9, spacing: 0.9, color: widget.skill.onHues),
    ),
  );

  /// The score and how far it moved this week, set small, made smaller
  /// rather than cut where a language runs long.
  Widget _score(double size) {
    final p = context.p;
    final l = context.l10n;
    final SkillScore score = widget.score;
    return FittedBox(
      key: ValueKey('skill-score-${widget.skill.name}'),
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: scoreNumber(context, score.now),
              style: TextStyle(color: p.ink, fontWeight: FontWeight.w800),
            ),
            const TextSpan(text: '  '),
            TextSpan(
              text: score.answers == 0
                  ? l.scoreStart
                  : l.scoreWeek(signedNumber(context, score.week)),
              style: TextStyle(
                color: score.answers == 0
                    ? p.ink.withValues(alpha: 0.5)
                    : moveColour(context, score.week),
              ),
            ),
          ],
        ),
        maxLines: 1,
        softWrap: false,
        style: AppText.body(size: size, weight: FontWeight.w600),
      ),
    );
  }

  /// The name, on up to two lines in the room it has, never broken inside a
  /// word: where its longest word is wider than that, or the lines taller,
  /// the whole name is set smaller instead.
  Widget _name(String name, double size) {
    final p = context.p;
    // Measured as it is drawn: with what the page's own text style lends it.
    final TextStyle style = DefaultTextStyle.of(context).style.merge(
      AppText.body(
        size: size,
        weight: FontWeight.w700,
        height: 1.12,
        color: p.ink,
      ),
    );
    final TextScaler scaler = MediaQuery.textScalerOf(context);
    return LayoutBuilder(
      builder: (context, room) {
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
        return Align(
          alignment: Alignment.centerLeft,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: math.max(room.maxWidth, widest + 1),
              child: Text(name, maxLines: 2, style: style),
            ),
          ),
        );
      },
    );
  }

  /// Tall: the badge and the name, and under them the score with its week
  /// on a line of its own.
  Widget _tall(String name) {
    final TextScaler scaler = MediaQuery.textScalerOf(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 9, 12, 9),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: math.max(2 * scaler.scale(14.5) * 1.12, 32),
            child: Row(
              children: [
                _badge(32),
                const SizedBox(width: 10),
                Expanded(child: _name(name, 14.5)),
              ],
            ),
          ),
          const SizedBox(height: 17),
          _score(11.5),
        ],
      ),
    );
  }

  /// Short: the badge beside the name, the score with its week on the line
  /// under the name.
  Widget _short(String name) {
    final TextScaler scaler = MediaQuery.textScalerOf(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, _Tile.padY, 10, _Tile.padY),
      child: Row(
        children: [
          _badge(28),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Flexible(
                  child: SizedBox(
                    height: math.max(2 * scaler.scale(13.5) * 1.12, 28),
                    child: _name(name, 13.5),
                  ),
                ),
                const SizedBox(height: 5),
                _score(10.5),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
