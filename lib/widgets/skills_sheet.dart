/// What to learn the way the owner picked it, "un mix": a page like the
/// goal's question, one row under another, each skill with its badge, its
/// name and a line on what it covers, but more than one may be picked; in a
/// sheet that scrolls, behind a tap on the profile's box of the skills
/// picked. The scores stay in Your journey, as they are, with the reading
/// of the answers under them: where the reader sees clearly, and their
/// blind spot (SkillsReading).
///
/// A tap on a row picks or lets go of a skill at once, as What to learn's
/// own screen does (lib/screens/skills_screen.dart), which stays where the
/// rest of the app opens it from.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../analytics.dart';
import '../data/learn_reading.dart' show SkillTally;
import '../data/skills.dart';
import '../data/topics.dart' show inkOn;
import '../l10n/l10n.dart';
import '../state/app_state.dart';
import '../theme.dart';
import 'fit_text.dart';
import 'training.dart' show SkillBadge;

/// Raises the sheet over [context]'s page, and says once, as it goes down,
/// what changed, as What to learn's screen says on its way out.
Future<void> showSkillsSheet(BuildContext context, AppState app) {
  HapticFeedback.selectionClick();
  Analytics.capture('skills opened', {'from': 'profile'});
  final List<String> before = List.of(app.skills);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x8C141416),
    builder: (_) => SkillsSheet(app: app),
  ).whenComplete(() {
    final List<String> now = app.skills;
    if (now.join(',') == before.join(',')) return;
    Analytics.capture('skills saved', {
      'skills': now.join(','),
      'count': now.length,
      'added': now.where((k) => !before.contains(k)).length,
      'removed': before.where((k) => !now.contains(k)).length,
    });
  });
}

/// The sheet: the reading of the answers, then the question and the twelve.
class SkillsSheet extends StatelessWidget {
  const SkillsSheet({super.key, required this.app});

  final AppState app;

  void _toggle(Skill s) {
    HapticFeedback.selectionClick();
    final List<String> next = List.of(app.skills);
    if (!next.remove(s.name)) next.add(s.name);
    app.setSkills(next);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final p = context.p;
    return Container(
      key: const ValueKey('profile-skills-sheet'),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      padding: EdgeInsets.fromLTRB(
        18,
        12,
        18,
        MediaQuery.paddingOf(context).bottom + 18,
      ),
      child: SingleChildScrollView(
        child: ListenableBuilder(
          listenable: app,
          builder: (context, _) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: p.inkMuted.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(9),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Semantics(
                  header: true,
                  child: Text(
                    l.trainingTitle,
                    style: AppText.display(
                      size: 25,
                      weight: FontWeight.w600,
                      height: 1.15,
                      color: p.ink,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l.trainingEmpty,
                  style: AppText.body(
                    size: 13.5,
                    height: 1.4,
                    color: p.inkMuted,
                  ),
                ),
                const SizedBox(height: 16),
                SkillRows(picked: app.skills, onTap: _toggle),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// The head of the sheet: the reader's answers read, the skill they answer
/// best and the one they slip on most, each with its badge and its count;
/// before there are answers enough, what will be here.
class SkillsReading extends StatelessWidget {
  const SkillsReading({super.key, this.best, this.blind});

  final SkillTally? best;
  final SkillTally? blind;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final p = context.p;
    final SkillTally? b = best;
    final Color glow = b == null ? p.inkMuted : b.skill.hues.first;
    Widget row(String label, SkillTally t) => Row(
      children: [
        SkillBadge(skill: t.skill, size: 40),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: AppText.label(
                  size: 10.5,
                  weight: FontWeight.w700,
                  spacing: 1.1,
                  color: p.inkMuted,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                l.skillName(t.skill.name),
                style: AppText.display(
                  size: 19,
                  weight: FontWeight.w600,
                  height: 1.12,
                  color: p.ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                l.answersRightOf(t.right, t.answers),
                style: AppText.body(size: 13, color: p.inkMuted),
              ),
            ],
          ),
        ),
      ],
    );
    return Container(
      key: const ValueKey('profile-skills-reading'),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: p.surfaceRaised,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: glow.withValues(alpha: 0.45), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: glow.withValues(alpha: p.isDark ? 0.22 : 0.16),
            blurRadius: 28,
            spreadRadius: -6,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: DecoratedBox(
        // The best skill's own light from the corner, under the words.
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(-1, -1),
            radius: 1.4,
            colors: [
              glow.withValues(alpha: p.isDark ? 0.20 : 0.12),
              glow.withValues(alpha: 0),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l.readTitle.toUpperCase(),
                style: AppText.label(
                  size: 11,
                  weight: FontWeight.w700,
                  spacing: 1.3,
                  color: p.ink.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 14),
              if (b == null)
                Text(
                  l.readEmpty,
                  style: AppText.body(size: 14, height: 1.4, color: p.inkMuted),
                )
              else ...[
                row(l.strengthsBest, b),
                if (blind case final SkillTally w) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Container(height: 1, color: p.line),
                  ),
                  row(l.readBlind, w),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// The twelve, one under another as the goal's six are, names at one size
/// and lines at one, the largest at which every word of the twelve fits a
/// line of its own beside the badge and the ring; where they would have to
/// go below four fifths of it, under them instead, the row's whole width
/// theirs.
class SkillRows extends StatelessWidget {
  const SkillRows({super.key, required this.picked, required this.onTap});

  final List<String> picked;
  final ValueChanged<Skill> onTap;

  static const double gap = 8;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final l = context.l10n;
      final TextScaler scaler = MediaQuery.textScalerOf(context);
      final TextDirection direction = Directionality.of(context);
      // Measured as drawn: the page's own style under the row's.
      final TextStyle base = DefaultTextStyle.of(context).style;
      final List<String> names = [
        for (final Skill s in Skill.values) l.skillName(s.name),
      ];
      final List<String> lines = [
        for (final Skill s in Skill.values) l.skillLine(s.name),
      ];
      double? fit(
        List<String> texts,
        TextStyle Function(double) style,
        double room,
        double from,
        double least,
      ) => FitText.oneSize(
        texts,
        (size) => base.merge(style(size)),
        room,
        from: from,
        least: least,
        scaler: scaler,
        direction: direction,
      );
      final double beside = box.maxWidth - SkillRow.around;
      final double? name = fit(
        names,
        SkillRow.nameStyle,
        beside,
        SkillRow.largestName,
        SkillRow.largestName * 0.8,
      );
      final double? line = fit(
        lines,
        SkillRow.lineStyle,
        beside,
        SkillRow.largestLine,
        SkillRow.largestLine * 0.8,
      );
      final bool stacked = name == null || line == null;
      final double under = box.maxWidth - 2 * SkillRow.inset;
      final double nameSize = stacked
          ? fit(names, SkillRow.nameStyle, under, SkillRow.largestName, 8) ?? 8
          : name;
      final double lineSize = stacked
          ? fit(lines, SkillRow.lineStyle, under, SkillRow.largestLine, 7) ?? 7
          : line;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (int i, Skill s) in Skill.values.indexed) ...[
            if (i > 0) const SizedBox(height: gap),
            SkillRow(
              key: ValueKey('profile-skills-${s.name}'),
              skill: s,
              on: picked.contains(s.name),
              onTap: () => onTap(s),
              nameSize: nameSize,
              lineSize: lineSize,
              stacked: stacked,
            ),
          ],
        ],
      );
    },
  );
}

/// One skill: its badge, its name in the display face, its line, and a ring
/// that fills with its colour when it is picked. Edged in its colour;
/// picked, edged in it whole, lit by it from under, and ticked.
class SkillRow extends StatelessWidget {
  const SkillRow({
    super.key,
    required this.skill,
    required this.on,
    required this.onTap,
    this.nameSize = largestName,
    this.lineSize = largestLine,
    this.stacked = false,
  });

  final Skill skill;
  final bool on;
  final VoidCallback onTap;
  final double nameSize;
  final double lineSize;

  /// The words under the badge and the ring rather than between them.
  final bool stacked;

  static const double largestName = 17;
  static const double largestLine = 13;

  /// The edge and the room inside it, the same picked or not: picked, the
  /// words do not move.
  static const double inset = 13.5;
  static const double _badge = 38;
  static const double _ring = 24;

  /// The room a row keeps around its words, across.
  static const double around = 2 * inset + _badge + 12 + 10 + _ring;

  static TextStyle nameStyle(double size) =>
      AppText.display(size: size, weight: FontWeight.w600, height: 1.15);

  static TextStyle lineStyle(double size) =>
      AppText.body(size: size, height: 1.33);

  static const Duration _turn = Duration(milliseconds: 180);

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final p = context.p;
    final Color tone = skill.mark(p.isDark);
    final double edge = on ? 1.6 : 1;
    final String name = l.skillName(skill.name);
    final String line = l.skillLine(skill.name);
    final Widget ring = AnimatedContainer(
      duration: _turn,
      width: _ring,
      height: _ring,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: on ? tone : Colors.transparent,
        border: Border.all(color: on ? tone : p.lineStrong, width: 1.5),
      ),
      child: on
          ? Icon(Icons.check_rounded, size: 16, color: inkOn(tone))
          : null,
    );
    final Widget words = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(name, style: nameStyle(nameSize).copyWith(color: p.ink)),
        const SizedBox(height: 3),
        Text(
          line,
          style: lineStyle(lineSize)
              .copyWith(color: p.ink.withValues(alpha: 0.6)),
        ),
      ],
    );
    final Widget badge = SkillBadge(skill: skill, size: _badge);
    return Semantics(
      button: true,
      selected: on,
      label: '$name. $line',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: _turn,
          padding: EdgeInsets.all(inset - edge),
          decoration: BoxDecoration(
            color: p.surfaceRaised,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: on ? tone : tone.withValues(alpha: p.isDark ? 0.34 : 0.4),
              width: edge,
            ),
            // Lit from under in its colour rather than washed in it: a
            // yellow laid faint on the night is olive, a glow of it is
            // still yellow.
            boxShadow: [
              BoxShadow(
                color: tone.withValues(
                  alpha: on ? (p.isDark ? 0.34 : 0.26) : 0,
                ),
                blurRadius: 20,
                spreadRadius: -3,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: stacked
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(children: [badge, const Spacer(), ring]),
                    const SizedBox(height: 10),
                    words,
                  ],
                )
              : Row(
                  children: [
                    badge,
                    const SizedBox(width: 12),
                    Expanded(child: words),
                    const SizedBox(width: 10),
                    ring,
                  ],
                ),
        ),
      ),
    );
  }
}
