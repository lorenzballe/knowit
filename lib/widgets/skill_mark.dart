/// The bar of a skill's level, and the sheet a card's line about a skill in
/// focus opens (lib/data/skill_levels.dart): the skill the card trains, the
/// reader's level in it, and the way to What to learn.
library;

import 'package:flutter/material.dart';

import '../analytics.dart';
import '../data/skill_levels.dart';
import '../data/skills.dart';
import '../l10n/l10n.dart';
import '../screens/skills_screen.dart';
import '../state/app_state.dart';
import '../theme.dart';
import 'chunky.dart';

/// A skill's level as a bar of five, one a level: those climbed full, the one
/// being climbed filled as far as the next level comes nearer, all five full
/// at the top; in the skill's two hues.
class SkillBar extends StatelessWidget {
  const SkillBar({
    super.key,
    required this.skill,
    required this.level,
    this.height = 5,
  });

  final Skill skill;
  final SkillLevel level;
  final double height;

  /// How full the [i]th of the five is.
  double fillOf(int i) {
    if (level.level >= SkillLevel.top || i < level.level - 1) return 1;
    if (i == level.level - 1) return level.toNext.clamp(0.0, 1.0);
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final Color track = p.ink.withValues(alpha: p.isDark ? 0.14 : 0.1);
    final LinearGradient hues = LinearGradient(colors: skill.hues);
    return SizedBox(
      height: height,
      child: Row(
        children: [
          for (int i = 0; i < SkillLevel.top; i++) ...[
            if (i > 0) const SizedBox(width: 3),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(height),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ColoredBox(color: track),
                    FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: fillOf(i),
                      child: DecoratedBox(
                        decoration: BoxDecoration(gradient: hues),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Puts the sheet a card's line about a skill in focus opens: the skill the
/// card trains, that
/// it is one the reader put in focus, their level in it, and the way to What
/// to learn.
Future<void> showSkillMarkSheet(
  BuildContext context,
  AppState app,
  Skill skill, {
  String? cardId,
}) {
  Analytics.capture('skill line opened', {
    'skill': skill.name,
    if (cardId != null) ...app.cardFacts(cardId),
  });
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x8C141416),
    builder: (_) => SkillMarkSheet(app: app, skill: skill),
  );
}

/// The sheet. Public so a test can lay it out in every language.
class SkillMarkSheet extends StatelessWidget {
  const SkillMarkSheet({super.key, required this.app, required this.skill});

  final AppState app;
  final Skill skill;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final Palette p = context.p;
    final SkillLevel level = SkillLevel.of(
      cardsTrainingEach(app.seenIds)[skill] ?? 0,
    );
    return Container(
      key: const ValueKey('skill-mark-sheet'),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      padding: EdgeInsets.fromLTRB(
        22,
        14,
        22,
        MediaQuery.paddingOf(context).bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: p.lineStrong,
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: skill.hues,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: skill.hues.last.withValues(alpha: 0.3),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: CustomPaint(
                    size: const Size.square(32),
                    painter: SkillGlyph(skill, skill.onHues),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.skillMarkKicker,
                        style: AppText.label(
                          size: 11,
                          spacing: 1.2,
                          color: p.ink.withValues(alpha: 0.55),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Semantics(
                        header: true,
                        child: Text(
                          l.skillName(skill.name),
                          style: AppText.display(
                            size: 25,
                            weight: FontWeight.w600,
                            height: 1.1,
                            spacing: -0.5,
                            color: p.ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              l.skillMarkBody,
              style: AppText.body(
                size: 15,
                height: 1.38,
                color: p.ink.withValues(alpha: 0.72),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '${l.skillLevel(level.level)} · ${l.nCards(level.cards)}',
              key: const ValueKey('skill-mark-level'),
              style: AppText.body(
                size: 14,
                weight: FontWeight.w700,
                color: p.ink,
              ),
            ),
            const SizedBox(height: 9),
            SkillBar(skill: skill, level: level, height: 7),
            const SizedBox(height: 24),
            ChunkyButton(
              key: const ValueKey('skill-mark-open'),
              label: l.skillMarkOpen,
              fill: p.inverse,
              ink: p.onInverse,
              height: 56,
              onPressed: () {
                final NavigatorState nav = Navigator.of(context);
                nav.pop();
                nav.push(
                  MaterialPageRoute<void>(
                    builder: (_) => SkillsScreen(app: app),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
