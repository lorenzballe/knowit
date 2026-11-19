import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../analytics.dart';
import '../data/skills.dart';
import '../data/topics.dart' show inkOn;
import '../l10n/l10n.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/chunky.dart';
import '../widgets/ui.dart' show BackCircle, ScreenView;

/// What the reader wants to learn, picked from the profile: twelve skills
/// in two columns, each a tile with its mark that fills with its colour
/// when picked. Nothing in the app changes with them; they are kept, and
/// told to the reader's profile in analytics, for the people who write the
/// cards to know what to write next. The screen says so.
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
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 6, 20, 16),
                  children: [
                    // The way back and the title on one line.
                    Row(
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
                    const SizedBox(height: 12),
                    Text(
                      l.skillsLine,
                      style: AppText.body(
                        size: 15,
                        height: 1.38,
                        color: p.ink.withValues(alpha: 0.62),
                      ),
                    ),
                    const SizedBox(height: 22),
                    for (int i = 0; i < all.length; i += 2) ...[
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: _Tile(
                                skill: all[i],
                                on: picked.contains(all[i].name),
                                onTap: () => _toggle(all[i]),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: i + 1 < all.length
                                  ? _Tile(
                                      skill: all[i + 1],
                                      on: picked.contains(all[i + 1].name),
                                      onTap: () => _toggle(all[i + 1]),
                                    )
                                  : const SizedBox.shrink(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ],
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

/// A skill: its mark and its name, on the page's quiet ground, or filled
/// with its colour, a tick in the corner, once picked.
class _Tile extends StatelessWidget {
  const _Tile({required this.skill, required this.on, required this.onTap});

  final Skill skill;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    // Not picked, the page's quiet ground with a wash of the skill's own
    // colour, so the grid reads as twelve different things before any is
    // chosen; picked, the colour itself.
    final Color ground = on
        ? skill.colour
        : Color.alphaBlend(
            skill.colour.withValues(alpha: p.isDark ? 0.1 : 0.08),
            p.ink.withValues(alpha: p.isDark ? 0.04 : 0.03),
          );
    final Color ink = on ? inkOn(skill.colour) : p.ink;
    final String name = context.l10n.skillName(skill.name);
    return Semantics(
      key: ValueKey('skill-${skill.name}-${on ? 'on' : 'off'}'),
      button: true,
      toggled: on,
      label: name,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          constraints: const BoxConstraints(minHeight: 112),
          decoration: BoxDecoration(
            color: ground,
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.fromLTRB(14, 14, 12, 13),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomPaint(
                    size: const Size.square(28),
                    painter: SkillGlyph(skill, on ? ink : skill.mark(p.isDark)),
                  ),
                  const Spacer(),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: on ? ink : Colors.transparent,
                      border: Border.all(
                        color: on ? ink : p.ink.withValues(alpha: 0.22),
                        width: 1.6,
                      ),
                    ),
                    child: on
                        ? Icon(
                            Icons.check_rounded,
                            size: 15,
                            color: skill.colour,
                          )
                        : null,
                  ),
                ],
              ),
              const Spacer(),
              const SizedBox(height: 18),
              Text(
                name,
                style: AppText.body(
                  size: 15.5,
                  weight: FontWeight.w700,
                  height: 1.2,
                  color: ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
