/// What to learn the way the owner picked it, "un mix": the twelve skills as
/// they are, each with its score, but behind a tap, in a sheet drawn like
/// the goal's (lib/widgets/aim_picker.dart), and with the reading of the
/// reader's answers at its head: where they see clearly, and their blind
/// spot.
///
/// The profile's box of the skills picked (ProfileTraining) opens it; a tap
/// on a tile picks or lets go of a skill, at once, as What to learn's own
/// screen does (lib/screens/skills_screen.dart), which stays where the rest
/// of the app opens it from.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../analytics.dart';
import '../data/learn_reading.dart' show SkillTally, skillTallies;
import '../data/skill_scores.dart';
import '../data/skills.dart';
import '../data/topics.dart' show inkOn;
import '../l10n/l10n.dart';
import '../state/app_state.dart';
import '../theme.dart';
import 'fit_text.dart';
import 'skill_score.dart' show scoreBookOf, scoreNumber;
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
            final ScoreBook book = scoreBookOf(app);
            final List<SkillTally> ranked = [
              for (final SkillTally t in skillTallies(app))
                if (t.ranked) t,
            ];
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
                SkillsReading(
                  best: ranked.isEmpty ? null : ranked.first,
                  blind: ranked.length > 1 ? ranked.last : null,
                ),
                const SizedBox(height: 28),
                Semantics(
                  header: true,
                  child: Text(
                    l.trainingTitle,
                    style: AppText.display(
                      size: 21,
                      weight: FontWeight.w600,
                      height: 1.15,
                      color: p.ink,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l.trainingEmpty,
                  style: AppText.body(
                    size: 13.5,
                    height: 1.4,
                    color: p.inkMuted,
                  ),
                ),
                const SizedBox(height: 16),
                SkillTiles(picked: app.skills, book: book, onTap: _toggle),
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

/// The twelve, two to a row where their words fit there, one to a row
/// where they do not, names at one size, the largest at which every word of
/// the twelve fits a line of its own.
class SkillTiles extends StatelessWidget {
  const SkillTiles({
    super.key,
    required this.picked,
    required this.book,
    required this.onTap,
  });

  final List<String> picked;
  final ScoreBook book;
  final ValueChanged<Skill> onTap;

  static const double gap = 10;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final l = context.l10n;
      final TextScaler scaler = MediaQuery.textScalerOf(context);
      final TextDirection direction = Directionality.of(context);
      // Measured as drawn: the page's own text style under the tile's.
      final TextStyle base = DefaultTextStyle.of(context).style;
      final List<String> names = [
        for (final Skill s in Skill.values) l.skillName(s.name),
      ];
      final double half = (box.maxWidth - gap) / 2 - 2 * SkillTile.inset;
      final double? two = FitText.oneSize(
        names,
        (size) => base.merge(SkillTile.nameStyle(size)),
        half,
        from: SkillTile.largestName,
        least: SkillTile.largestName * 0.8,
        scaler: scaler,
        direction: direction,
      );
      final bool pairs = two != null;
      final double size =
          two ??
          FitText.oneSize(
            names,
            (size) => base.merge(SkillTile.nameStyle(size)),
            box.maxWidth - 2 * SkillTile.inset,
            from: SkillTile.largestName,
            least: 9,
            scaler: scaler,
            direction: direction,
          ) ??
          9;
      Widget tile(Skill s) => SkillTile(
        key: ValueKey('profile-skills-${s.name}'),
        skill: s,
        score: book.of(s),
        on: picked.contains(s.name),
        nameSize: size,
        onTap: () => onTap(s),
      );
      const List<Skill> all = Skill.values;
      if (!pairs) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (int i, Skill s) in all.indexed) ...[
              if (i > 0) const SizedBox(height: gap),
              tile(s),
            ],
          ],
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (int i = 0; i < all.length; i += 2) ...[
            if (i > 0) const SizedBox(height: gap),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: tile(all[i])),
                  const SizedBox(width: gap),
                  Expanded(
                    child: i + 1 < all.length
                        ? tile(all[i + 1])
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ],
        ],
      );
    },
  );
}

/// One skill: its badge and the ring over the corner, its name, its score
/// and how far this week moved it. Edged in its colour; picked, edged in it
/// whole, lit by it from under, and ticked.
class SkillTile extends StatelessWidget {
  const SkillTile({
    super.key,
    required this.skill,
    required this.score,
    required this.on,
    required this.onTap,
    this.nameSize = largestName,
  });

  final Skill skill;
  final SkillScore score;
  final bool on;
  final VoidCallback onTap;
  final double nameSize;

  static const double largestName = 16;
  static const double inset = 14;

  static TextStyle nameStyle(double size) =>
      AppText.display(size: size, weight: FontWeight.w600, height: 1.14);

  static const Duration _turn = Duration(milliseconds: 180);

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final p = context.p;
    final Color tone = skill.mark(p.isDark);
    final double edge = on ? 1.6 : 1;
    final int week = score.week;
    return Semantics(
      button: true,
      selected: on,
      label: '${l.skillName(skill.name)}, ${scoreNumber(context, score.now)}',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: _turn,
          padding: EdgeInsets.all(inset - edge),
          decoration: BoxDecoration(
            color: p.surfaceRaised,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: on ? tone : tone.withValues(alpha: p.isDark ? 0.34 : 0.4),
              width: edge,
            ),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  SkillBadge(skill: skill, size: 34),
                  const Spacer(),
                  AnimatedContainer(
                    duration: _turn,
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: on ? tone : Colors.transparent,
                      border: Border.all(
                        color: on ? tone : p.lineStrong,
                        width: 1.5,
                      ),
                    ),
                    child: on
                        ? Icon(
                            Icons.check_rounded,
                            size: 15,
                            color: inkOn(tone),
                          )
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                l.skillName(skill.name),
                style: nameStyle(nameSize).copyWith(color: p.ink),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    scoreNumber(context, score.now),
                    style: AppText.display(
                      size: 22,
                      weight: FontWeight.w600,
                      height: 1,
                      color: p.ink,
                    ),
                  ),
                  if (week > 0) ...[
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        '+${scoreNumber(context, week)}',
                        style: AppText.body(
                          size: 12.5,
                          weight: FontWeight.w700,
                          color: tone,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
